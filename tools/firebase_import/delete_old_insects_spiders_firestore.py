import argparse
import sys
from pathlib import Path

import firebase_admin
from firebase_admin import credentials, firestore

FIREBASE_KEY_DIR = Path(r"C:\RhiPlay\firebase_keys")
COLLECTION_NAME = "challenges"
TARGET_CATEGORY = "animals"
TARGET_SUBCATEGORY = "insects_spiders"

OLD_DOCUMENT_IDS = [
    f"animals_insects_spiders_{i:04d}"
    for i in range(1, 16)
]


def stop(message):
    print("\nDELETE STOPPED")
    print("=" * 72)
    print(f"ERROR: {message}")
    sys.exit(1)


def find_service_account_key():
    if not FIREBASE_KEY_DIR.exists():
        stop(f"Firebase key folder not found: {FIREBASE_KEY_DIR}")

    matches = sorted(FIREBASE_KEY_DIR.glob("*.json"))
    if not matches:
        stop(f"No Firebase service-account JSON key found in {FIREBASE_KEY_DIR}")
    if len(matches) > 1:
        print("Multiple Firebase service-account JSON keys found:")
        for item in matches:
            print(f" - {item.name}")
        stop("Please leave only the service-account key you use for First Guess.")
    return matches[0]


def init_firestore(key_path):
    if not firebase_admin._apps:
        cred = credentials.Certificate(str(key_path))
        firebase_admin.initialize_app(cred)
    return firestore.client()


def main():
    parser = argparse.ArgumentParser(
        description=(
            "Safely remove only the 15 old Animals -> Insects & Spiders "
            "Firestore challenge documents. Dry-run by default."
        )
    )
    parser.add_argument(
        "--write",
        action="store_true",
        help="Actually delete the verified 15 old Firestore documents.",
    )
    args = parser.parse_args()

    print("FIRST GUESS — REMOVE OLD INSECTS & SPIDERS FIRESTORE QUESTIONS")
    print("=" * 72)
    print(f"Mode: {'DELETE' if args.write else 'DRY RUN (NO CHANGES)'}")
    print(f"Collection: {COLLECTION_NAME}")
    print(f"Expected category: {TARGET_CATEGORY}")
    print(f"Expected subcategory: {TARGET_SUBCATEGORY}")

    key_path = find_service_account_key()
    db = init_firestore(key_path)

    verified = []

    print("\nVERIFYING EXACT OLD DOCUMENT IDs")
    print("-" * 72)

    for doc_id in OLD_DOCUMENT_IDS:
        doc_ref = db.collection(COLLECTION_NAME).document(doc_id)
        snapshot = doc_ref.get()

        if not snapshot.exists:
            stop(f"Expected old document is missing: {doc_id}")

        data = snapshot.to_dict() or {}
        category = str(data.get("category", "")).strip().lower()
        subcategory = str(data.get("subcategory", "")).strip().lower()
        answer = data.get("answer", "")

        if category != TARGET_CATEGORY:
            stop(
                f"{doc_id}: category mismatch. "
                f"Expected '{TARGET_CATEGORY}', found '{category}'."
            )

        if subcategory != TARGET_SUBCATEGORY:
            stop(
                f"{doc_id}: subcategory mismatch. "
                f"Expected '{TARGET_SUBCATEGORY}', found '{subcategory}'."
            )

        verified.append((doc_id, doc_ref, answer))
        print(f"VERIFIED: {doc_id} | answer={answer!r}")

    if len(verified) != 15:
        stop(f"Safety check failed: expected 15 verified documents, found {len(verified)}.")

    print("-" * 72)
    print(f"VERIFIED DOCUMENTS TO DELETE: {len(verified)}")

    if not args.write:
        print("\nDRY RUN COMPLETE — NO FIREBASE DATA WAS CHANGED.")
        print("If the 15 verified documents above are correct, run:")
        print("    python delete_old_insects_spiders_firestore.py --write")
        return

    print("\nDELETE MODE STARTING")
    print("=" * 72)

    batch = db.batch()
    for _, doc_ref, _ in verified:
        batch.delete(doc_ref)
    batch.commit()

    print("\nDELETE COMPLETE")
    print("=" * 72)
    print(f"Old Firestore documents deleted: {len(verified)}")
    print("Firebase Storage images were NOT touched.")
    print("No other Firestore documents were touched.")


if __name__ == "__main__":
    main()
