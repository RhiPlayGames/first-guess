from __future__ import annotations

import argparse
import os
from pathlib import Path

import firebase_admin
from firebase_admin import credentials, firestore

COLLECTION = "challenges"

# Explicit answer variants only. These are intentionally conservative:
# they accept a clearly correct common answer without turning the matcher
# into a broad "contains" or keyword matcher.
HISTORICAL_BY_ID = {
    "past_present_historical_events_001": [
        "great fire of london",
        "great fire",
    ],
    "past_present_historical_events_004": [
        "wright brothers",
        "wright brothers flight",
        "first flight",
        "first powered flight",
    ],
    "past_present_historical_events_005": [
        "titanic",
        "the titanic",
        "titanic sinking",
        "sinking of titanic",
    ],
    "past_present_historical_events_007": [
        "moon landing",
        "the moon landing",
        "apollo 11",
        "apollo 11 moon landing",
    ],
    "past_present_historical_events_008": [
        "berlin wall",
        "the berlin wall",
        "fall of berlin wall",
    ],
    "past_present_historical_events_009": [
        "mount vesuvius",
        "vesuvius",
        "eruption of mount vesuvius",
        "vesuvius eruption",
        "pompeii",
    ],
    "past_present_historical_events_010": [
        "bastille",
        "the bastille",
        "storming of bastille",
    ],
}

# These are matched by the stored primary answer because the older
# Insects & Spiders content may not use the same permanent-ID convention.
INSECT_BY_ANSWER = {
    "western honey bee": ["honey bee", "bee"],
    "seven-spot ladybird": ["ladybird", "seven spot ladybird"],
    "emperor dragonfly": ["dragonfly"],
    "european mantis": ["mantis", "praying mantis"],
    "european stag beetle": ["stag beetle"],
    "common field grasshopper": ["grasshopper", "field grasshopper"],
    "common glow-worm": ["glow worm", "glow-worm"],
    "indian stick insect": ["stick insect"],
    "southern black widow": ["black widow", "black widow spider"],
    "regal jumping spider": ["jumping spider"],
    "european garden spider": ["garden spider", "cross spider"],
}


def norm(value: object) -> str:
    return " ".join(str(value or "").strip().lower().split())


def find_service_account() -> Path:
    candidates = []

    env_path = os.environ.get("GOOGLE_APPLICATION_CREDENTIALS")
    if env_path:
        candidates.append(Path(env_path))

    here = Path(__file__).resolve().parent
    candidates.extend([
        here / "serviceAccountKey.json",
        here / "service-account-key.json",
        here / "firebase-service-account.json",
        here.parent / "serviceAccountKey.json",
        here.parent / "service-account-key.json",
        Path.cwd() / "serviceAccountKey.json",
        Path.cwd() / "service-account-key.json",
    ])

    for path in candidates:
        if path.exists() and path.is_file():
            return path

    raise SystemExit(
        "No Firebase service-account JSON found.\n"
        "Put the key beside this script or set GOOGLE_APPLICATION_CREDENTIALS."
    )


def init_firestore():
    key_path = find_service_account()
    if not firebase_admin._apps:
        firebase_admin.initialize_app(credentials.Certificate(str(key_path)))
    return firestore.client()


def merge_answers(existing: object, additions: list[str]) -> list[str]:
    values = []
    seen = set()

    if isinstance(existing, list):
        source = [x for x in existing if isinstance(x, str)]
    else:
        source = []

    for value in [*source, *additions]:
        cleaned = value.strip()
        key = norm(cleaned)
        if cleaned and key not in seen:
            seen.add(key)
            values.append(cleaned)

    return values


def patch_document(doc_ref, data: dict, additions: list[str], write: bool) -> bool:
    before = data.get("acceptedAnswers", [])
    after = merge_answers(before, additions)

    if after == before:
        print(f"UNCHANGED  {doc_ref.id}: {after}")
        return False

    print(f"{'UPDATE' if write else 'WOULD UPDATE'} {doc_ref.id}")
    print(f"  answer: {data.get('answer', '')}")
    print(f"  acceptedAnswers: {after}")

    if write:
        doc_ref.update({
            "acceptedAnswers": after,
            "updatedAt": firestore.SERVER_TIMESTAMP,
        })

    return True


def main():
    parser = argparse.ArgumentParser(
        description="Add agreed First Guess accepted-answer variants to Firestore."
    )
    parser.add_argument(
        "--write",
        action="store_true",
        help="Actually update Firestore. Without this flag the script is a dry run.",
    )
    args = parser.parse_args()

    db = init_firestore()
    changed = 0
    found = 0

    print("FIRST GUESS — ACCEPTED ANSWER PATCH")
    print("=" * 72)
    print("Mode:", "WRITE" if args.write else "DRY RUN — NO CHANGES")
    print()

    # Historical Events: patch by stable permanent document/question ID.
    print("PAST & PRESENT · HISTORICAL EVENTS")
    print("-" * 72)
    for question_id, aliases in HISTORICAL_BY_ID.items():
        ref = db.collection(COLLECTION).document(question_id)
        snapshot = ref.get()

        if not snapshot.exists:
            print(f"NOT FOUND  {question_id}")
            continue

        found += 1
        data = snapshot.to_dict() or {}
        if patch_document(ref, data, aliases, args.write):
            changed += 1

    # Insects & Spiders: scan Animals challenges and patch only exact
    # primary-answer matches from the approved map.
    print()
    print("ANIMALS · INSECTS & SPIDERS")
    print("-" * 72)

    animal_docs = (
        db.collection(COLLECTION)
        .where("category", "==", "animals")
        .stream()
    )

    matched_insect_answers = set()

    for snapshot in animal_docs:
        data = snapshot.to_dict() or {}
        answer_key = norm(data.get("answer"))

        aliases = INSECT_BY_ANSWER.get(answer_key)
        if aliases is None:
            continue

        matched_insect_answers.add(answer_key)
        found += 1
        if patch_document(snapshot.reference, data, aliases, args.write):
            changed += 1

    for answer_key in INSECT_BY_ANSWER:
        if answer_key not in matched_insect_answers:
            print(f"NOT FOUND  answer='{answer_key}'")

    print()
    print("=" * 72)
    print(f"Matched documents: {found}")
    print(f"{'Updated' if args.write else 'Would update'}: {changed}")

    if not args.write:
        print()
        print("Dry run complete. If everything above is correct, run:")
        print("  python patch_accepted_answers.py --write")


if __name__ == "__main__":
    main()
