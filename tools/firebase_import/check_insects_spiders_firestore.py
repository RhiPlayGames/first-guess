import sys
from pathlib import Path

import firebase_admin
from firebase_admin import credentials, firestore

FIREBASE_KEY_DIR = Path(r"C:\RhiPlay\firebase_keys")
COLLECTION_NAME = "challenges"
TARGET_CATEGORY = "animals"
TARGET_SUBCATEGORY = "insects_spiders"


def stop(message):
    print("\nCHECK STOPPED")
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
    print("FIRST GUESS — INSECTS & SPIDERS FIRESTORE CHECK")
    print("=" * 72)
    print("READ-ONLY CHECK — NOTHING WILL BE CHANGED")
    print(f"Collection: {COLLECTION_NAME}")
    print(f"Category: {TARGET_CATEGORY}")
    print(f"Subcategory: {TARGET_SUBCATEGORY}")

    key_path = find_service_account_key()
    db = init_firestore(key_path)

    query = (
        db.collection(COLLECTION_NAME)
        .where("category", "==", TARGET_CATEGORY)
        .where("subcategory", "==", TARGET_SUBCATEGORY)
    )

    docs = list(query.stream())
    docs.sort(key=lambda doc: doc.id)

    print("\nEXISTING FIRESTORE DOCUMENTS")
    print("-" * 72)

    if not docs:
        print("No matching documents found.")
    else:
        for index, doc in enumerate(docs, start=1):
            data = doc.to_dict() or {}
            print(
                f"{index:02d}. {doc.id} | "
                f"answer={data.get('answer', '')!r} | "
                f"status={data.get('status', '')!r}"
            )

    print("-" * 72)
    print(f"TOTAL MATCHING DOCUMENTS: {len(docs)}")
    print("\nCHECK COMPLETE — NO FIREBASE DATA WAS CHANGED.")


if __name__ == "__main__":
    main()
