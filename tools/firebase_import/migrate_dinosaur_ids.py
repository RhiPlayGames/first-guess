import argparse
import sys
from pathlib import Path

import firebase_admin
from firebase_admin import credentials, firestore


FIREBASE_KEY_DIR = Path(r"C:\RhiPlay\firebase_keys")

CHALLENGES_COLLECTION = "challenges"
PLAYERS_COLLECTION = "players"

CATEGORY = "animals"
SUBCATEGORY = "dinosaurs"

OLD_PREFIX = "animals_dinosaurs_"
QUESTION_COUNT = 10


def stop(message):
    print("\nMIGRATION STOPPED")
    print("=" * 72)
    print(f"ERROR: {message}")
    sys.exit(1)


def find_service_account_key() -> Path:
    if not FIREBASE_KEY_DIR.exists():
        stop(
            f"Firebase key folder not found: "
            f"{FIREBASE_KEY_DIR}"
        )

    matches = sorted(
        FIREBASE_KEY_DIR.glob("*.json")
    )

    if not matches:
        stop(
            f"No Firebase service-account JSON key found in "
            f"{FIREBASE_KEY_DIR}"
        )

    if len(matches) > 1:
        print(
            "Multiple Firebase service-account keys found:"
        )

        for item in matches:
            print(f" - {item.name}")

        stop(
            "Please leave only the correct Firebase "
            "service-account JSON key in the folder."
        )

    return matches[0]


def init_firebase(key_path: Path):
    if not firebase_admin._apps:
        cred = credentials.Certificate(
            str(key_path)
        )

        firebase_admin.initialize_app(cred)

    return firestore.client()


def old_question_id(number: int) -> str:
    return f"{OLD_PREFIX}{number:03d}"


def new_question_id(number: int) -> str:
    return f"{OLD_PREFIX}{number:04d}"


def build_id_map():
    return {
        old_question_id(number):
            new_question_id(number)
        for number in range(
            1,
            QUESTION_COUNT + 1,
        )
    }


def validate_old_document(
    document_id,
    data,
):
    question_id = str(
        data.get("questionId", "")
    ).strip()

    category = str(
        data.get("category", "")
    ).strip().lower()

    subcategory = str(
        data.get("subcategory", "")
    ).strip().lower()

    status = str(
        data.get("status", "")
    ).strip().lower()

    errors = []

    if question_id != document_id:
        errors.append(
            f"{document_id}: questionId field is "
            f"'{question_id}'"
        )

    if category != CATEGORY:
        errors.append(
            f"{document_id}: category is "
            f"'{category}' instead of '{CATEGORY}'"
        )

    if subcategory != SUBCATEGORY:
        errors.append(
            f"{document_id}: subcategory is "
            f"'{subcategory}' instead of "
            f"'{SUBCATEGORY}'"
        )

    if status != "live":
        errors.append(
            f"{document_id}: expected status 'live', "
            f"found '{status}'"
        )

    return errors


def load_and_validate_questions(
    db,
    id_map,
):
    print("Checking Dinosaur challenge documents...")
    print("-" * 72)

    migrations = []
    errors = []

    for old_id, new_id in id_map.items():
        old_ref = db.collection(
            CHALLENGES_COLLECTION
        ).document(old_id)

        new_ref = db.collection(
            CHALLENGES_COLLECTION
        ).document(new_id)

        old_snapshot = old_ref.get()
        new_snapshot = new_ref.get()

        if not old_snapshot.exists:
            errors.append(
                f"Missing old live document: {old_id}"
            )
            continue

        old_data = old_snapshot.to_dict() or {}

        errors.extend(
            validate_old_document(
                old_id,
                old_data,
            )
        )

        if new_snapshot.exists:
            new_data = new_snapshot.to_dict() or {}

            new_answer = str(
                new_data.get("answer", "")
            ).strip()

            old_answer = str(
                old_data.get("answer", "")
            ).strip()

            errors.append(
                f"{new_id} already exists "
                f"(old answer='{old_answer}', "
                f"new answer='{new_answer}'). "
                f"Migration will not overwrite it."
            )
            continue

        print(
            f"{old_id} -> {new_id} "
            f"answer='{old_data.get('answer', '')}'"
        )

        migrations.append(
            {
                "old_id": old_id,
                "new_id": new_id,
                "old_ref": old_ref,
                "new_ref": new_ref,
                "old_data": old_data,
            }
        )

    if errors:
        print()
        print("VALIDATION ERRORS")
        print("=" * 72)

        for error in errors:
            print(f"ERROR: {error}")

        stop(
            "Dinosaur documents did not pass "
            "pre-migration validation."
        )

    if len(migrations) != QUESTION_COUNT:
        stop(
            f"Expected {QUESTION_COUNT} Dinosaur "
            f"migrations; found {len(migrations)}."
        )

    print("-" * 72)
    print(
        f"Dinosaur challenge validation: PASSED "
        f"({len(migrations)} documents)"
    )

    return migrations


def find_player_history_updates(
    db,
    id_map,
):
    print()
    print("Checking player question histories...")
    print("-" * 72)

    updates = []

    player_snapshots = list(
        db.collection(
            PLAYERS_COLLECTION
        ).stream()
    )

    print(
        f"Player documents found: "
        f"{len(player_snapshots)}"
    )

    for player_snapshot in player_snapshots:
        player_id = player_snapshot.id

        history_ref = (
            db.collection(PLAYERS_COLLECTION)
            .document(player_id)
            .collection("progress")
            .document("question_history")
        )

        history_snapshot = history_ref.get()

        if not history_snapshot.exists:
            continue

        data = history_snapshot.to_dict() or {}

        raw_ids = data.get(
            "playedQuestionIds",
            [],
        )

        if not isinstance(raw_ids, list):
            print(
                f"WARNING: {player_id}: "
                f"playedQuestionIds is not a list; "
                f"history skipped."
            )
            continue

        existing_ids = {
            str(item)
            for item in raw_ids
            if isinstance(item, str)
            and item
        }

        ids_to_add = set()

        for old_id, new_id in id_map.items():
            if (
                old_id in existing_ids
                and new_id not in existing_ids
            ):
                ids_to_add.add(new_id)

        if not ids_to_add:
            continue

        print(
            f"{player_id}: add "
            f"{len(ids_to_add)} migrated "
            f"history ID(s)"
        )

        for new_id in sorted(ids_to_add):
            print(f"  + {new_id}")

        updates.append(
            {
                "player_id": player_id,
                "history_ref": history_ref,
                "ids_to_add": sorted(ids_to_add),
            }
        )

    if not updates:
        print(
            "No player histories require Dinosaur "
            "ID migration."
        )

    return updates


def build_new_question_payload(
    old_data,
    old_id,
    new_id,
):
    payload = dict(old_data)

    payload["questionId"] = new_id
    payload["status"] = "live"

    payload["migratedFrom"] = old_id
    payload["updatedAt"] = (
        firestore.SERVER_TIMESTAMP
    )

    return payload


def write_challenge_migration(
    db,
    migrations,
):
    print()
    print("Writing challenge migration...")
    print("-" * 72)

    batch = db.batch()
    write_count = 0

    for item in migrations:
        old_id = item["old_id"]
        new_id = item["new_id"]
        old_ref = item["old_ref"]
        new_ref = item["new_ref"]
        old_data = item["old_data"]

        new_payload = (
            build_new_question_payload(
                old_data,
                old_id,
                new_id,
            )
        )

        batch.set(
            new_ref,
            new_payload,
        )

        batch.set(
            old_ref,
            {
                "status": "retired",
                "migratedTo": new_id,
                "updatedAt":
                    firestore.SERVER_TIMESTAMP,
            },
            merge=True,
        )

        write_count += 2

    batch.commit()

    print(
        f"Challenge write operations: "
        f"{write_count}"
    )


def write_player_history_updates(
    db,
    updates,
):
    print()
    print("Writing player-history migration...")
    print("-" * 72)

    history_write_count = 0

    for update in updates:
        update["history_ref"].set(
            {
                "playedQuestionIds":
                    firestore.ArrayUnion(
                        update["ids_to_add"]
                    ),
                "schemaVersion": 1,
                "updatedAt":
                    firestore.SERVER_TIMESTAMP,
            },
            merge=True,
        )

        history_write_count += 1

        print(
            f"UPDATED HISTORY: "
            f"{update['player_id']} "
            f"(+{len(update['ids_to_add'])})"
        )

    print(
        f"Player history documents updated: "
        f"{history_write_count}"
    )


def verify_after_write(
    db,
    id_map,
):
    print()
    print("Verifying migration...")
    print("-" * 72)

    errors = []

    for old_id, new_id in id_map.items():
        old_snapshot = (
            db.collection(
                CHALLENGES_COLLECTION
            )
            .document(old_id)
            .get()
        )

        new_snapshot = (
            db.collection(
                CHALLENGES_COLLECTION
            )
            .document(new_id)
            .get()
        )

        if not old_snapshot.exists:
            errors.append(
                f"{old_id}: old document missing"
            )
            continue

        if not new_snapshot.exists:
            errors.append(
                f"{new_id}: new document missing"
            )
            continue

        old_data = (
            old_snapshot.to_dict() or {}
        )

        new_data = (
            new_snapshot.to_dict() or {}
        )

        old_status = str(
            old_data.get("status", "")
        ).lower()

        new_status = str(
            new_data.get("status", "")
        ).lower()

        new_question_id = str(
            new_data.get("questionId", "")
        )

        if old_status != "retired":
            errors.append(
                f"{old_id}: expected retired, "
                f"found '{old_status}'"
            )

        if new_status != "live":
            errors.append(
                f"{new_id}: expected live, "
                f"found '{new_status}'"
            )

        if new_question_id != new_id:
            errors.append(
                f"{new_id}: questionId field "
                f"is '{new_question_id}'"
            )

    if errors:
        print("VERIFICATION FAILED")
        print("=" * 72)

        for error in errors:
            print(f"ERROR: {error}")

        stop(
            "Post-write verification found "
            "migration errors."
        )

    print(
        "Verification PASSED:"
    )
    print(
        " - old three-digit Dinosaur IDs "
        "are retired"
    )
    print(
        " - new four-digit Dinosaur IDs "
        "are live"
    )
    print(
        " - new questionId fields match "
        "their document IDs"
    )


def main():
    parser = argparse.ArgumentParser(
        description=(
            "One-off First Guess Dinosaur "
            "Question ID migration. "
            "Dry-run by default."
        )
    )

    parser.add_argument(
        "--write",
        action="store_true",
        help=(
            "Actually create four-digit Dinosaur "
            "documents, retire old documents, and "
            "migrate matching player history."
        ),
    )

    args = parser.parse_args()

    print(
        "FIRST GUESS DINOSAUR ID MIGRATION"
    )
    print("=" * 72)

    print(
        f"Mode: "
        f"{'WRITE' if args.write else 'DRY RUN (NO CHANGES)'}"
    )

    print(
        f"Migration: "
        f"{OLD_PREFIX}001-010 "
        f"-> "
        f"{OLD_PREFIX}0001-0010"
    )

    print()

    key_path = find_service_account_key()

    print(
        f"Firebase key: "
        f"{key_path.name}"
    )

    db = init_firebase(key_path)

    id_map = build_id_map()

    migrations = (
        load_and_validate_questions(
            db,
            id_map,
        )
    )

    history_updates = (
        find_player_history_updates(
            db,
            id_map,
        )
    )

    print()
    print("=" * 72)
    print("MIGRATION PLAN")
    print("=" * 72)

    print(
        f"New four-digit challenge "
        f"documents to create: "
        f"{len(migrations)}"
    )

    print(
        f"Old three-digit challenge "
        f"documents to retire: "
        f"{len(migrations)}"
    )

    print(
        f"Player history documents "
        f"to update: "
        f"{len(history_updates)}"
    )

    print(
        "Firebase Storage images to change: 0"
    )

    if not args.write:
        print()
        print(
            "DRY RUN COMPLETE — "
            "NO FIREBASE DATA WAS CHANGED."
        )

        print()
        print(
            "If the migration plan above "
            "is correct, run:"
        )

        print(
            "    python "
            "migrate_dinosaur_ids.py "
            "--write"
        )

        return

    print()
    print("WRITE MODE STARTING")
    print("=" * 72)

    write_challenge_migration(
        db,
        migrations,
    )

    write_player_history_updates(
        db,
        history_updates,
    )

    verify_after_write(
        db,
        id_map,
    )

    print()
    print("=" * 72)
    print("MIGRATION COMPLETE")
    print("=" * 72)

    print(
        "Created live Dinosaur IDs:"
    )

    for new_id in id_map.values():
        print(f" - {new_id}")

    print()
    print(
        "Retired old three-digit "
        "Dinosaur documents."
    )

    print(
        "Existing player history was "
        "preserved and mapped to the "
        "new four-digit IDs."
    )

    print(
        "No Firebase Storage images "
        "were changed."
    )

    print()
    print(
        "NEXT: run "
        "python audit_question_ids.py"
    )


if __name__ == "__main__":
    main()