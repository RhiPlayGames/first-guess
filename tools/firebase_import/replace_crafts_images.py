from pathlib import Path

import firebase_admin
from firebase_admin import credentials, storage

from import_to_firebase import (
    find_service_account_key,
    STORAGE_BUCKET,
)

LOCAL_FOLDER = Path(
    r"C:\RhiPlay\first_guess\assets\images\categories"
    r"\creative_world\crafts_pottery_ceramics"
)

STORAGE_FOLDER = "challenge_images/creative_world/crafts_pottery_ceramics"

key_path = find_service_account_key()

if not firebase_admin._apps:
    cred = credentials.Certificate(str(key_path))
    firebase_admin.initialize_app(
        cred,
        {"storageBucket": STORAGE_BUCKET},
    )

bucket = storage.bucket()

print()
print("CRAFTS IMAGE REPLACEMENT")
print("=" * 72)

for i in range(1, 11):
    filename = f"{i:04d}.webp"

    local_file = LOCAL_FOLDER / filename
    remote_path = f"{STORAGE_FOLDER}/{filename}"

    if not local_file.exists():
        raise FileNotFoundError(
            f"Missing local image: {local_file}"
        )

    blob = bucket.blob(remote_path)

    blob.upload_from_filename(
        str(local_file),
        content_type="image/webp",
    )

    print(f"REPLACED: {filename}")
    print(f"  -> {remote_path}")

print()
print("=" * 72)
print("COMPLETE")
print("Replaced all 10 Crafts, Pottery & Ceramics images.")
