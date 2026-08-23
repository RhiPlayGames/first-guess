from pathlib import Path
import argparse

import firebase_admin
from firebase_admin import credentials, firestore, storage


FIREBASE_KEY_DIR = Path(r"C:\RhiPlay\firebase_keys")
LOCAL_IMAGE_DIR = Path(
    r"C:\RhiPlay\first_guess\assets\images\categories"
    r"\books_authors\fictional_literary_locations"
)

STORAGE_BUCKET = "first-guess-a18b1.firebasestorage.app"
STORAGE_BASE = "challenge_images/books_authors/fictional_literary_locations"


CHALLENGES = [
    {
        "questionId": "books_authors_fictional_locations_0022",
        "answer": "the wild wood",
        "acceptedAnswers": [
            "wild wood",
            "the wild wood",
        ],
        "category": "books_authors",
        "subcategory": "fictional_literary_locations",
        "status": "live",
        "schemaVersion": 1,
        "imageFile": "0022_the_wild_wood.webp",
        "clues": [
            "Its atmosphere contrasts sharply with the gentler riverbank.",
            "Badger has a substantial underground home within it.",
            "Mole becomes lost there during winter.",
            "Stoats and weasels are associated with its more dangerous inhabitants.",
            "Rat later helps search for his missing friend there.",
            "It is part of the countryside explored by several talking animals.",
            "Kenneth Grahame created it.",
            "Mr Badger is one of the important characters living there.",
            "It appears in The Wind in the Willows.",
            "This woodland has 'Wild' in its name.",
        ],
    },
    {
        "questionId": "books_authors_fictional_locations_0023",
        "answer": "baker street",
        "acceptedAnswers": [
            "baker street",
            "221b baker street",
            "221b",
        ],
        "category": "books_authors",
        "subcategory": "fictional_literary_locations",
        "status": "live",
        "schemaVersion": 1,
        "imageFile": "0023_baker_street.webp",
        "clues": [
            "A landlady named Mrs Hudson manages lodgings at its most famous fictional address.",
            "Clients arrive here with mysteries involving crimes, disappearances and strange events.",
            "Dr John Watson shares rooms here with an exceptionally observant companion.",
            "Scotland Yard detectives frequently consult the resident of these lodgings.",
            "A violin, chemical experiments and tobacco are associated with the famous rooms.",
            "The address is in London.",
            "Sir Arthur Conan Doyle made this street internationally famous through detective fiction.",
            "Sherlock Holmes receives many of his clients here.",
            "The best-known fictional address on the street is 221B.",
            "Sherlock Holmes and Dr Watson famously live at 221B on what London street?",
        ],
    },
    {
        "questionId": "books_authors_fictional_locations_0024",
        "answer": "castle dracula",
        "acceptedAnswers": [
            "castle dracula",
            "count dracula",
            "dracula",
            "dracula's castle",
            "dracula castle",
        ],
        "category": "books_authors",
        "subcategory": "fictional_literary_locations",
        "status": "live",
        "schemaVersion": 1,
        "imageFile": "0024_castle_dracula.webp",
        "clues": [
            "A solicitor travels through the Carpathians to reach this remote residence.",
            "Local people react with fear when they learn where the traveller is heading.",
            "Its owner initially appears courteous but behaves increasingly strangely after nightfall.",
            "The visitor discovers that doors are locked and escape from the building is difficult.",
            "Wolves and an isolated mountain landscape contribute to its threatening atmosphere.",
            "Jonathan Harker is effectively imprisoned here early in the story.",
            "The castle stands in Transylvania.",
            "Bram Stoker created the aristocratic vampire who owns it.",
            "Its master is Count Dracula.",
            "What is the name commonly given to Count Dracula's Transylvanian castle?",
        ],
    },
    {
        "questionId": "books_authors_fictional_locations_0025",
        "answer": "the lost world",
        "acceptedAnswers": [
            "the lost world",
            "lost world",
        ],
        "category": "books_authors",
        "subcategory": "fictional_literary_locations",
        "status": "live",
        "schemaVersion": 1,
        "imageFile": "0025_lost_world.webp",
        "clues": [
            "This isolated place is reached after an expedition travels deep into South America.",
            "Its sheer cliffs make reaching the land above extremely difficult.",
            "Professor Summerlee initially doubts claims about what survives there.",
            "Lord John Roxton accompanies the expedition.",
            "Professor Challenger is determined to prove that extraordinary creatures still exist there.",
            "The explorers become trapped after reaching a remote plateau.",
            "Prehistoric plants and animals have survived there, cut off from the outside world.",
            "Dinosaurs are among the creatures encountered by the expedition.",
            "Arthur Conan Doyle created this location in a 1912 novel.",
            "The novel containing this prehistoric plateau is itself called The Lost World.",
        ],
    },
]


def find_service_account_key() -> Path:
    keys = sorted(FIREBASE_KEY_DIR.glob("*.json"))

    if len(keys) != 1:
        raise RuntimeError(
            f"Expected exactly one Firebase service-account JSON in "
            f"{FIREBASE_KEY_DIR}, found {len(keys)}"
        )

    return keys[0]


def init_firebase():
    if not firebase_admin._apps:
        firebase_admin.initialize_app(
            credentials.Certificate(str(find_service_account_key())),
            {
                "storageBucket": STORAGE_BUCKET,
            },
        )

    return firestore.client(), storage.bucket()


def validate_local_files():
    missing = []

    for item in CHALLENGES:
        local_path = LOCAL_IMAGE_DIR / item["imageFile"]

        if not local_path.exists():
            missing.append(local_path)

    if missing:
        print("ERROR — MISSING LOCAL IMAGE FILES")
        print("=" * 80)

        for path in missing:
            print(path)

        raise SystemExit(1)


def build_firestore_data(item):
    storage_path = f"{STORAGE_BASE}/{item['imageFile']}"

    return {
        "questionId": item["questionId"],
        "answer": item["answer"],
        "acceptedAnswers": item["acceptedAnswers"],
        "category": item["category"],
        "subcategory": item["subcategory"],
        "status": item["status"],
        "schemaVersion": item["schemaVersion"],
        "clues": item["clues"],
        "imagePath": storage_path,
        "updatedAt": firestore.SERVER_TIMESTAMP,
    }


def main():
    parser = argparse.ArgumentParser()

    parser.add_argument(
        "--write",
        action="store_true",
        help="Actually write to Firebase. Without this flag the script is dry-run only.",
    )

    args = parser.parse_args()

    print("FIRST GUESS FICTIONAL LOCATIONS 0022–0025 UPDATE")
    print("=" * 80)

    if args.write:
        print("Mode: WRITE")
    else:
        print("Mode: DRY RUN (NO CHANGES)")

    print()

    validate_local_files()

    db, bucket = init_firebase()

    print("LOCAL IMAGE DIRECTORY")
    print(LOCAL_IMAGE_DIR)
    print()

    for item in CHALLENGES:
        question_id = item["questionId"]
        local_path = LOCAL_IMAGE_DIR / item["imageFile"]
        storage_path = f"{STORAGE_BASE}/{item['imageFile']}"

        doc_ref = db.collection("challenges").document(question_id)
        existing = doc_ref.get()

        print(question_id)
        print(f"  ANSWER   : {item['answer']}")
        print(f"  IMAGE    : {item['imageFile']}")
        print(f"  STORAGE  : {storage_path}")
        print(f"  LOCAL    : {local_path}")
        print(f"  SIZE     : {local_path.stat().st_size:,} bytes")
        print(f"  FIRESTORE: {'UPDATE EXISTING' if existing.exists else 'CREATE NEW'}")
        print(f"  CLUES    : {len(item['clues'])}")
        print(f"  ACCEPTED : {item['acceptedAnswers']}")

        if args.write:
            firestore_data = build_firestore_data(item)

            if not existing.exists:
                firestore_data["createdAt"] = firestore.SERVER_TIMESTAMP

            doc_ref.set(
                firestore_data,
                merge=True,
            )

            blob = bucket.blob(storage_path)

            blob.upload_from_filename(
                str(local_path),
                content_type="image/webp",
            )

            print("  RESULT   : FIRESTORE + STORAGE UPDATED")

        print()

    print("-" * 80)
    print(f"Challenges checked: {len(CHALLENGES)}")
    print(f"Images checked:     {len(CHALLENGES)}")

    if args.write:
        print()
        print("WRITE COMPLETE")
        print("Only questions 0022–0025 were updated.")
        print("Only the four matching Storage images were uploaded.")
        print("No other Firestore documents were deleted.")
        print("No other Storage files were deleted.")
    else:
        print()
        print("DRY RUN COMPLETE — NOTHING WAS CHANGED.")
        print()
        print("If the plan above is correct, run:")
        print("    python update_fictional_locations_22_25.py --write")


if __name__ == "__main__":
    main()
