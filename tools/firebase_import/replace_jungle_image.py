from pathlib import Path

import firebase_admin
from firebase_admin import credentials, storage

FIREBASE_KEY_DIR = Path(r"C:\RhiPlay\firebase_keys")
LOCAL_FILE = Path(
    r"C:\RhiPlay\first_guess\assets\images\categories"
    r"\books_authors\fictional_literary_locations\0020_the_jungle.webp"
)
STORAGE_BUCKET = "first-guess-a18b1.firebasestorage.app"
STORAGE_PATH = (
    "challenge_images/books_authors/"
    "fictional_literary_locations/0020_the_jungle.webp"
)


def find_service_account_key() -> Path:
    keys = sorted(FIREBASE_KEY_DIR.glob("*.json"))
    if len(keys) != 1:
        raise RuntimeError(
            f"Expected exactly one Firebase service-account JSON in "
            f"{FIREBASE_KEY_DIR}, found {len(keys)}"
        )
    return keys[0]


def main():
    if not LOCAL_FILE.exists():
        raise RuntimeError(f"Local image not found: {LOCAL_FILE}")

    if not firebase_admin._apps:
        firebase_admin.initialize_app(
            credentials.Certificate(str(find_service_account_key())),
            {"storageBucket": STORAGE_BUCKET},
        )

    bucket = storage.bucket()
    blob = bucket.blob(STORAGE_PATH)

    print("FIRST GUESS SINGLE IMAGE REPLACE")
    print("=" * 72)
    print(f"Local file : {LOCAL_FILE}")
    print(f"Storage    : {STORAGE_PATH}")
    print(f"Size       : {LOCAL_FILE.stat().st_size:,} bytes")
    print()

    blob.upload_from_filename(
        str(LOCAL_FILE),
        content_type="image/webp",
    )

    print("UPLOAD COMPLETE")
    print("The existing Firebase Storage object was replaced at the same path.")
    print("Firestore was not changed.")


if __name__ == "__main__":
    main()
