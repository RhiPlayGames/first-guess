import argparse
from pathlib import Path

import firebase_admin
from firebase_admin import credentials, firestore, storage

PROJECT_ROOT = Path(r"C:\RhiPlay\first_guess")
FIREBASE_KEY_DIR = Path(r"C:\RhiPlay\firebase_keys")
STORAGE_BUCKET = "first-guess-a18b1.firebasestorage.app"
COLLECTION_NAME = "challenges"
LOCAL_CATEGORY_IMAGE_ROOT = PROJECT_ROOT / "assets" / "images" / "categories"


def find_service_account_key() -> Path:
    keys = sorted(FIREBASE_KEY_DIR.glob("*.json"))
    if not keys:
        raise RuntimeError(
            f"No Firebase service-account JSON found in {FIREBASE_KEY_DIR}"
        )
    if len(keys) > 1:
        raise RuntimeError(
            "Multiple Firebase service-account JSON files found:\n"
            + "\n".join(f" - {p}" for p in keys)
        )
    return keys[0]


def init_firebase():
    if not firebase_admin._apps:
        cred = credentials.Certificate(str(find_service_account_key()))
        firebase_admin.initialize_app(
            cred,
            {"storageBucket": STORAGE_BUCKET},
        )
    return firestore.client(), storage.bucket()


def local_path_for_storage_path(storage_path: str) -> Path:
    prefix = "challenge_images/"
    if not storage_path.startswith(prefix):
        raise ValueError(f"Unsupported image path: {storage_path}")
    relative = storage_path[len(prefix):]
    return LOCAL_CATEGORY_IMAGE_ROOT.joinpath(*Path(relative).parts)


def main():
    parser = argparse.ArgumentParser(
        description=(
            "Restore missing local source copies from Firebase Storage. "
            "Dry-run by default."
        )
    )
    parser.add_argument(
        "--write",
        action="store_true",
        help="Download missing local source copies. Firebase is never modified.",
    )
    args = parser.parse_args()

    db, bucket = init_firebase()

    docs = list(db.collection(COLLECTION_NAME).stream())

    referenced_paths = set()
    for snap in docs:
        data = snap.to_dict() or {}
        image_path = str(data.get("imagePath", "")).strip().replace("\\", "/")
        if image_path.startswith("challenge_images/") and image_path.lower().endswith(".webp"):
            referenced_paths.add(image_path)

    missing = []
    for image_path in sorted(referenced_paths):
        local_path = local_path_for_storage_path(image_path)
        if not local_path.exists():
            missing.append((image_path, local_path))

    print("FIRST GUESS LOCAL SOURCE COPY SYNC")
    print("=" * 78)
    print("Mode:", "WRITE" if args.write else "DRY RUN (NO LOCAL CHANGES)")
    print(f"Unique Firebase gameplay images referenced: {len(referenced_paths)}")
    print(f"Missing local source copies: {len(missing)}")
    print()

    if not missing:
        print("Nothing to do. Local source copies already match Firebase references.")
        return

    for image_path, local_path in missing:
        print(image_path)
        print(f"  -> {local_path}")

    if not args.write:
        print()
        print("DRY RUN COMPLETE — NO LOCAL FILES WERE CHANGED.")
        print("If the plan above is correct, run:")
        print("    python sync_local_source_images.py --write")
        return

    downloaded = 0

    for image_path, local_path in missing:
        blob = bucket.blob(image_path)

        if not blob.exists():
            raise RuntimeError(
                f"Firebase Storage image is missing unexpectedly: {image_path}"
            )

        local_path.parent.mkdir(parents=True, exist_ok=True)
        blob.download_to_filename(str(local_path))
        downloaded += 1
        print(f"DOWNLOADED: {image_path}")

    print()
    print("SYNC COMPLETE")
    print(f"Local source copies downloaded: {downloaded}")
    print("Firebase was not modified.")


if __name__ == "__main__":
    main()
