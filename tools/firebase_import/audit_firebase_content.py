import re
import sys
from collections import Counter, defaultdict
from pathlib import Path

import firebase_admin
from firebase_admin import credentials, firestore, storage

PROJECT_ROOT = Path(r"C:\RhiPlay\first_guess")
FIREBASE_KEY_DIR = Path(r"C:\RhiPlay\firebase_keys")
STORAGE_BUCKET = "first-guess-a18b1.firebasestorage.app"
COLLECTION_NAME = "challenges"
LOCAL_CATEGORY_IMAGE_ROOT = PROJECT_ROOT / "assets" / "images" / "categories"
REPORT_PATH = PROJECT_ROOT / "tools" / "firebase_import" / "firebase_content_audit_report.txt"

VALID_STATUSES = {"draft", "scheduled", "live", "retired"}
QUESTION_ID_PATTERN = re.compile(r"^.+_\d{4}$")


def find_service_account_key() -> Path:
    keys = sorted(FIREBASE_KEY_DIR.glob("*.json"))
    if not keys:
        raise RuntimeError(f"No Firebase service-account JSON found in {FIREBASE_KEY_DIR}")
    if len(keys) > 1:
        raise RuntimeError(
            "Multiple Firebase service-account JSON files found:\n"
            + "\n".join(f" - {p}" for p in keys)
        )
    return keys[0]


def init_firebase():
    key_path = find_service_account_key()
    if not firebase_admin._apps:
        cred = credentials.Certificate(str(key_path))
        firebase_admin.initialize_app(cred, {"storageBucket": STORAGE_BUCKET})
    return firestore.client(), storage.bucket()


def is_probable_gameplay_local_image(path: Path) -> bool:
    try:
        rel = path.relative_to(LOCAL_CATEGORY_IMAGE_ROOT)
    except ValueError:
        return False

    parts = rel.parts
    if not parts:
        return False

    # UI/category/subcategory icon locations are intentionally local Flutter assets.
    if parts[0] == "subcategories":
        return False
    if len(parts) >= 2 and parts[1] == "icons":
        return False

    # Numbered challenge images are definitely gameplay source copies.
    if re.match(r"^\d{4}_.*\.webp$", path.name, re.IGNORECASE):
        return True

    # Nested category/subcategory images are likely gameplay source copies.
    return len(parts) >= 3


def scan_hardcoded_content():
    findings = []
    lib_root = PROJECT_ROOT / "lib"

    patterns = [
        ("QuizItem constructor", re.compile(r"\bQuizItem\s*\(")),
        ("Country constructor", re.compile(r"\bCountry\s*\(")),
        ("DailyFlashQuestion constructor", re.compile(r"\bDailyFlashQuestion\s*\(")),
        ("legacy country asset", re.compile(r"assets/images/countries/")),
    ]

    ignored_names = {
        "quiz_item.dart",
        "country.dart",
        "daily_flash_question.dart",
    }

    for dart_file in sorted(lib_root.rglob("*.dart")):
        if dart_file.name in ignored_names:
            continue

        try:
            text = dart_file.read_text(encoding="utf-8")
        except UnicodeDecodeError:
            text = dart_file.read_text(encoding="utf-8", errors="replace")

        hits = []
        for label, pattern in patterns:
            count = len(pattern.findall(text))
            if count:
                hits.append(f"{label}: {count}")

        if hits:
            rel = dart_file.relative_to(PROJECT_ROOT)
            classification = (
                "DAILY FLASH (separate/special system)"
                if "daily_flash" in rel.parts
                else "REVIEW: possible hard-coded/legacy gameplay content"
            )
            findings.append((str(rel), classification, hits))

    return findings


def main():
    db, bucket = init_firebase()

    lines = []
    def out(text=""):
        print(text)
        lines.append(text)

    out("FIRST GUESS FIREBASE CONTENT AUDIT")
    out("=" * 78)
    out("READ-ONLY AUDIT — this script does not change Firebase or local files.")
    out()

    docs = list(db.collection(COLLECTION_NAME).stream())
    out(f"Firestore challenge documents: {len(docs)}")

    by_category = Counter()
    by_subcategory = Counter()
    by_status = Counter()
    referenced_images = set()

    errors = []
    warnings = []
    local_missing = []

    for snap in docs:
        data = snap.to_dict() or {}
        doc_id = snap.id

        qid = str(data.get("questionId", "")).strip()
        category = str(data.get("category", "")).strip()
        subcategory = str(data.get("subcategory", "")).strip()
        status = str(data.get("status", "")).strip()
        answer = str(data.get("answer", "")).strip()
        image_path = str(data.get("imagePath", "")).strip().replace("\\", "/")
        clues = data.get("clues")
        accepted = data.get("acceptedAnswers")

        by_category[category or "<blank>"] += 1
        by_subcategory[f"{category or '<blank>'}/{subcategory or '<blank>'}"] += 1
        by_status[status or "<blank>"] += 1

        if not qid:
            errors.append(f"{doc_id}: missing questionId")
        elif qid != doc_id:
            errors.append(f"{doc_id}: questionId field '{qid}' does not match document ID")
        elif status == "live" and not QUESTION_ID_PATTERN.fullmatch(qid):
            errors.append(
                f"{doc_id}: live questionId does not end in exactly four digits"
            )
        elif status == "retired" and not QUESTION_ID_PATTERN.fullmatch(qid):
            # Expected migration history: retired legacy IDs are informational only.
            pass

        if not category:
            errors.append(f"{doc_id}: missing category")
        if not subcategory:
            errors.append(f"{doc_id}: missing subcategory")
        if status not in VALID_STATUSES:
            errors.append(f"{doc_id}: invalid status '{status}'")
        if not answer:
            errors.append(f"{doc_id}: missing answer")

        if not isinstance(clues, list) or len(clues) != 10 or any(not str(c).strip() for c in clues):
            actual = len(clues) if isinstance(clues, list) else "not a list"
            errors.append(f"{doc_id}: clues must be 10 non-empty strings (found {actual})")

        if accepted is not None and not isinstance(accepted, list):
            errors.append(f"{doc_id}: acceptedAnswers is not a list")

        if not image_path:
            errors.append(f"{doc_id}: missing imagePath")
        else:
            referenced_images.add(image_path)

            if not image_path.startswith("challenge_images/"):
                warnings.append(f"{doc_id}: imagePath is outside challenge_images/: {image_path}")
            if not image_path.lower().endswith(".webp"):
                warnings.append(f"{doc_id}: imagePath is not .webp: {image_path}")

            blob = bucket.blob(image_path)
            if not blob.exists():
                errors.append(f"{doc_id}: Storage image MISSING: {image_path}")

            if image_path.startswith("challenge_images/"):
                rel = image_path[len("challenge_images/"):]
                local_path = LOCAL_CATEGORY_IMAGE_ROOT.joinpath(*Path(rel).parts)
                if not local_path.exists():
                    local_missing.append((doc_id, str(local_path), image_path))
                    warnings.append(
                        f"{doc_id}: no local source image copy (Firebase Storage image exists)"
                    )

    out()
    out("FIRESTORE COUNTS BY CATEGORY")
    out("-" * 78)
    for category, count in sorted(by_category.items()):
        out(f"{category:<28} {count:>5}")

    out()
    out("FIRESTORE COUNTS BY STATUS")
    out("-" * 78)
    for status, count in sorted(by_status.items()):
        out(f"{status:<28} {count:>5}")

    # Storage audit
    all_storage_images = {
        blob.name
        for blob in bucket.list_blobs(prefix="challenge_images/")
        if not blob.name.endswith("/")
    }
    orphan_storage = sorted(all_storage_images - referenced_images)
    referenced_missing_storage = sorted(referenced_images - all_storage_images)

    out()
    out("FIREBASE STORAGE")
    out("-" * 78)
    out(f"Files under challenge_images/:          {len(all_storage_images)}")
    out(f"Unique imagePaths referenced by Firestore: {len(referenced_images)}")
    out(f"Orphan Storage files (not referenced):  {len(orphan_storage)}")
    out(f"Referenced paths missing in Storage:     {len(referenced_missing_storage)}")

    if orphan_storage:
        out()
        out("ORPHAN STORAGE FILES")
        for path in orphan_storage:
            out(f"  {path}")

    if referenced_missing_storage:
        out()
        out("FIRESTORE IMAGE PATHS MISSING IN STORAGE")
        for path in referenced_missing_storage:
            out(f"  {path}")

    # Local source copy audit
    probable_local_gameplay = set()
    if LOCAL_CATEGORY_IMAGE_ROOT.exists():
        for p in LOCAL_CATEGORY_IMAGE_ROOT.rglob("*.webp"):
            if is_probable_gameplay_local_image(p):
                probable_local_gameplay.add(p)

    out()
    out("LOCAL SOURCE IMAGE COPIES")
    out("-" * 78)
    out(f"Probable local gameplay/source WebPs:    {len(probable_local_gameplay)}")
    out(f"Firestore images with no local source copy: {len(local_missing)}")
    out("Note: local source copies are okay; Firebase Storage remains the live source.")

    if local_missing:
        out()
        out("NO LOCAL SOURCE COPY FOUND")
        for qid, local_path, firebase_path in local_missing:
            out(f"  {qid}")
            out(f"    Firebase: {firebase_path}")
            out(f"    Local expected: {local_path}")

    # Hard-coded source audit
    hardcoded = scan_hardcoded_content()
    out()
    out("DART SOURCE AUDIT")
    out("-" * 78)
    if not hardcoded:
        out("No obvious hard-coded gameplay constructors/assets found.")
    else:
        for file_path, classification, hits in hardcoded:
            out(f"{file_path}")
            out(f"  {classification}")
            for hit in hits:
                out(f"  - {hit}")

    out()
    out("SUBCATEGORY COUNTS")
    out("-" * 78)
    for key, count in sorted(by_subcategory.items()):
        out(f"{key:<56} {count:>5}")

    out()
    out("VALIDATION SUMMARY")
    out("-" * 78)
    out(f"Errors:   {len(errors)}")
    out(f"Warnings: {len(warnings)}")

    if errors:
        out()
        out("ERRORS")
        for item in errors:
            out(f"  ERROR: {item}")

    if warnings:
        out()
        out("WARNINGS")
        for item in warnings:
            out(f"  WARNING: {item}")

    out()
    if errors:
        out("RESULT: ISSUES FOUND — review errors before treating Firebase as clean.")
    else:
        out("RESULT: CORE FIREBASE INTEGRITY PASSED.")
        if orphan_storage or hardcoded or warnings:
            out("There are still cleanup/review items listed above.")

    REPORT_PATH.parent.mkdir(parents=True, exist_ok=True)
    REPORT_PATH.write_text("\n".join(lines) + "\n", encoding="utf-8")
    out(f"Report saved to: {REPORT_PATH}")


if __name__ == "__main__":
    try:
        main()
    except Exception as exc:
        print(f"\nAUDIT FAILED: {exc}")
        sys.exit(1)
