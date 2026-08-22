import re
import sys
from collections import Counter, defaultdict
from pathlib import Path

import firebase_admin
from firebase_admin import credentials, firestore


FIREBASE_KEY_DIR = Path(r"C:\RhiPlay\firebase_keys")
COLLECTION_NAME = "challenges"

FOUR_DIGIT_ID_PATTERN = re.compile(r"^.+_\d{4}$")
THREE_DIGIT_ID_PATTERN = re.compile(r"^.+_\d{3}$")


def stop(message):
    print("\nAUDIT STOPPED")
    print("=" * 72)
    print(f"ERROR: {message}")
    sys.exit(1)


def find_service_account_key() -> Path:
    if not FIREBASE_KEY_DIR.exists():
        stop(
            f"Firebase key folder not found: "
            f"{FIREBASE_KEY_DIR}"
        )

    matches = sorted(FIREBASE_KEY_DIR.glob("*.json"))

    if not matches:
        stop(
            f"No Firebase service-account JSON key found in "
            f"{FIREBASE_KEY_DIR}"
        )

    if len(matches) > 1:
        print("Multiple Firebase service-account keys found:")
        for item in matches:
            print(f" - {item.name}")

        stop(
            "Please leave only the correct Firebase "
            "service-account JSON key in the folder."
        )

    return matches[0]


def init_firebase(key_path: Path):
    if not firebase_admin._apps:
        cred = credentials.Certificate(str(key_path))
        firebase_admin.initialize_app(cred)

    return firestore.client()


def classify_id(question_id: str) -> str:
    if FOUR_DIGIT_ID_PATTERN.fullmatch(question_id):
        return "4-digit"

    if THREE_DIGIT_ID_PATTERN.fullmatch(question_id):
        return "3-digit"

    return "other"


def main():
    print("FIRST GUESS QUESTION ID AUDIT")
    print("=" * 72)
    print("READ ONLY — THIS SCRIPT DOES NOT CHANGE FIREBASE")
    print()

    key_path = find_service_account_key()

    print(f"Firebase key: {key_path.name}")
    print(f"Firestore collection: {COLLECTION_NAME}")
    print()

    db = init_firebase(key_path)

    print("Reading Firebase challenges...")
    documents = list(
        db.collection(COLLECTION_NAME).stream()
    )

    if not documents:
        stop(
            f"No documents found in Firestore collection "
            f"'{COLLECTION_NAME}'."
        )

    print(f"Challenges found: {len(documents)}")
    print()

    live_four_digit = []
    live_bad_format = []
    retired_three_digit = []
    retired_four_digit = []
    retired_other_format = []
    other_status = []
    id_field_mismatches = []
    missing_question_id_fields = []

    status_counts = Counter()
    category_counts = Counter()
    subcategory_counts = Counter()

    live_by_subcategory = defaultdict(list)

    for snapshot in documents:
        document_id = snapshot.id
        data = snapshot.to_dict() or {}

        question_id = str(
            data.get("questionId", "")
        ).strip()

        status = str(
            data.get("status", "")
        ).strip().lower()

        category = str(
            data.get("category", "")
        ).strip().lower()

        subcategory = str(
            data.get("subcategory", "")
        ).strip().lower()

        status_counts[status or "<blank>"] += 1

        if category:
            category_counts[category] += 1

        if category and subcategory:
            subcategory_counts[
                f"{category}/{subcategory}"
            ] += 1

        if not question_id:
            missing_question_id_fields.append(
                document_id
            )
        elif question_id != document_id:
            id_field_mismatches.append(
                (
                    document_id,
                    question_id,
                    status,
                )
            )

        id_format = classify_id(document_id)

        if status == "live":
            if id_format == "4-digit":
                live_four_digit.append(document_id)

                if category and subcategory:
                    live_by_subcategory[
                        f"{category}/{subcategory}"
                    ].append(document_id)
            else:
                live_bad_format.append(
                    (
                        document_id,
                        status,
                        id_format,
                    )
                )

        elif status == "retired":
            if id_format == "3-digit":
                retired_three_digit.append(
                    document_id
                )
            elif id_format == "4-digit":
                retired_four_digit.append(
                    document_id
                )
            else:
                retired_other_format.append(
                    document_id
                )

        else:
            other_status.append(
                (
                    document_id,
                    status or "<blank>",
                    id_format,
                )
            )

    print("=" * 72)
    print("SUMMARY")
    print("=" * 72)
    print(
        f"Total challenge documents: "
        f"{len(documents)}"
    )
    print(
        f"Live + four-digit ID: "
        f"{len(live_four_digit)}"
    )
    print(
        f"Live + INVALID ID format: "
        f"{len(live_bad_format)}"
    )
    print(
        f"Retired + historical three-digit ID: "
        f"{len(retired_three_digit)}"
    )
    print(
        f"Retired + four-digit ID: "
        f"{len(retired_four_digit)}"
    )
    print(
        f"Retired + other ID format: "
        f"{len(retired_other_format)}"
    )
    print(
        f"Other/blank statuses: "
        f"{len(other_status)}"
    )
    print(
        f"Document ID/questionId mismatches: "
        f"{len(id_field_mismatches)}"
    )
    print(
        f"Missing questionId fields: "
        f"{len(missing_question_id_fields)}"
    )

    print()
    print("=" * 72)
    print("STATUS COUNTS")
    print("=" * 72)

    for status, count in sorted(
        status_counts.items()
    ):
        print(f"{status}: {count}")

    print()
    print("=" * 72)
    print("LIVE QUESTIONS BY SUBCATEGORY")
    print("=" * 72)

    if live_by_subcategory:
        for key in sorted(live_by_subcategory):
            ids = sorted(
                live_by_subcategory[key]
            )
            print(
                f"{key}: {len(ids)} live question(s)"
            )
            print(
                f"  {ids[0]} -> {ids[-1]}"
            )
    else:
        print("No valid live questions found.")

    print()
    print("=" * 72)
    print("LIVE QUESTIONS WITH INVALID IDs")
    print("=" * 72)

    if live_bad_format:
        for document_id, status, id_format in sorted(
            live_bad_format
        ):
            print(
                f"ERROR: {document_id} "
                f"[status={status}, format={id_format}]"
            )
    else:
        print(
            "NONE — all live questions use "
            "four-digit IDs."
        )

    print()
    print("=" * 72)
    print("DOCUMENT ID / questionId MISMATCHES")
    print("=" * 72)

    if id_field_mismatches:
        for (
            document_id,
            question_id,
            status,
        ) in sorted(id_field_mismatches):
            print(
                f"ERROR: document='{document_id}' "
                f"questionId='{question_id}' "
                f"status='{status}'"
            )
    else:
        print(
            "NONE — every populated questionId "
            "matches its Firestore document ID."
        )

    print()
    print("=" * 72)
    print("MISSING questionId FIELDS")
    print("=" * 72)

    if missing_question_id_fields:
        for document_id in sorted(
            missing_question_id_fields
        ):
            print(
                f"ERROR: {document_id}"
            )
    else:
        print("NONE")

    print()
    print("=" * 72)
    print("RETIRED HISTORICAL THREE-DIGIT IDs")
    print("=" * 72)

    if retired_three_digit:
        for document_id in sorted(
            retired_three_digit
        ):
            print(
                f"OK HISTORICAL: {document_id}"
            )
    else:
        print("NONE")

    print()
    print("=" * 72)
    print("FINAL RESULT")
    print("=" * 72)

    critical_errors = (
        len(live_bad_format)
        + len(id_field_mismatches)
        + len(missing_question_id_fields)
    )

    if critical_errors == 0:
        print("PASS")
        print()
        print(
            "All LIVE First Guess questions use "
            "four-digit permanent IDs."
        )
        print(
            "All populated questionId fields match "
            "their Firestore document IDs."
        )
        print(
            "Historical three-digit RETIRED IDs "
            "can remain in Firebase."
        )
    else:
        print("ATTENTION REQUIRED")
        print()
        print(
            f"{critical_errors} critical ID issue(s) "
            "were found."
        )
        print(
            "DO NOT delete or rename anything yet."
        )
        print(
            "Review the errors above before making "
            "Firebase changes."
        )

    print()
    print(
        "AUDIT COMPLETE — NO FIREBASE DATA WAS CHANGED."
    )


if __name__ == "__main__":
    main()