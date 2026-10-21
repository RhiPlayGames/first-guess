import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'public_name_approval_service.dart';
import 'public_name_filter.dart';

class PlayerProfileService {
  PlayerProfileService._();

  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const int _cloudSchemaVersion = 1;

  static DocumentReference<Map<String, dynamic>>?
      get _publicProfileDocument {
    final User? user = _auth.currentUser;

    if (user == null) {
      return null;
    }

    return _firestore
        .collection('players')
        .doc(user.uid)
        .collection('profile')
        .doc('public_profile');
  }

  static Future<String?> loadDisplayName() async {
    final DocumentReference<Map<String, dynamic>>? profileDocument =
        _publicProfileDocument;

    if (profileDocument == null) {
      return null;
    }

    try {
      final DocumentSnapshot<Map<String, dynamic>> snapshot =
          await profileDocument.get();

      final dynamic rawDisplayName = snapshot.data()?['displayName'];

      if (rawDisplayName is String) {
        final String displayName = rawDisplayName.trim();

        if (displayName.isNotEmpty) {
          return displayName;
        }
      }
    } on FirebaseException {
      // Keep profile loading non-blocking if Firestore is unavailable.
    }

    return null;
  }

  static String _normaliseForUniqueness(
    String value,
  ) {
    return value
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '');
  }

  static DocumentReference<Map<String, dynamic>> _playerNameDocument(
    String normalisedName,
  ) {
    return _firestore
        .collection('player_names')
        .doc(normalisedName);
  }

  static Future<void> saveDisplayName(
    String displayName,
  ) async {
    final String cleanedDisplayName = displayName.trim();

    if (cleanedDisplayName.isEmpty) {
      throw const PlayerProfileException(
        'Enter a player name first.',
      );
    }

    if (cleanedDisplayName.length > 20) {
      throw const PlayerProfileException(
        'Player names can be up to 20 characters.',
      );
    }

    if (PublicNameFilter.isBlocked(cleanedDisplayName)) {
      throw const PlayerProfileException(
        'Please choose another player name.',
      );
    }

    final String normalisedName =
        _normaliseForUniqueness(cleanedDisplayName);

    if (normalisedName.isEmpty) {
      throw const PlayerProfileException(
        'Please choose a name containing letters or numbers.',
      );
    }

    final User? user = _auth.currentUser;
    final DocumentReference<Map<String, dynamic>>? profileDocument =
        _publicProfileDocument;

    if (user == null || profileDocument == null) {
      throw const PlayerProfileException(
        'A First Guess account is required to save your player name.',
      );
    }

    // Approval is stored by a trusted Cloud Function. Do not attempt a
    // direct Firestore write if moderation is unavailable.
    try {
      await PublicNameApprovalService.approve(
        name: cleanedDisplayName,
        scope: 'player',
      );
    } on PublicNameApprovalException catch (error) {
      throw PlayerProfileException(error.message);
    }

    final DocumentReference<Map<String, dynamic>> newNameDocument =
        _playerNameDocument(normalisedName);

    try {
      await _firestore.runTransaction<void>(
        (Transaction transaction) async {
          final DocumentSnapshot<Map<String, dynamic>> profileSnapshot =
              await transaction.get(profileDocument);

          final String currentDisplayName =
              profileSnapshot.data()?['displayName'] is String
                  ? (profileSnapshot.data()!['displayName'] as String).trim()
                  : '';

          if (currentDisplayName.isNotEmpty &&
              currentDisplayName != cleanedDisplayName) {
            throw const PlayerProfileException(
              'Your player name cannot be changed after it is saved.',
            );
          }

          final String currentNormalisedName =
              _normaliseForUniqueness(currentDisplayName);

          final DocumentSnapshot<Map<String, dynamic>> newNameSnapshot =
              await transaction.get(newNameDocument);

          DocumentReference<Map<String, dynamic>>? oldNameDocument;
          DocumentSnapshot<Map<String, dynamic>>? oldNameSnapshot;

          if (currentNormalisedName.isNotEmpty &&
              currentNormalisedName != normalisedName) {
            oldNameDocument =
                _playerNameDocument(currentNormalisedName);
            oldNameSnapshot =
                await transaction.get(oldNameDocument);
          }

          if (newNameSnapshot.exists) {
            final String? ownerUserId =
                newNameSnapshot.data()?['userId'] as String?;

            if (ownerUserId != user.uid) {
              throw const PlayerProfileException(
                'Sorry, this name is already taken. Try another.',
              );
            }
          }

          transaction.set(
            newNameDocument,
            <String, dynamic>{
              'userId': user.uid,
              'displayName': cleanedDisplayName,
              'normalisedName': normalisedName,
              'schemaVersion': _cloudSchemaVersion,
              if (!newNameSnapshot.exists)
                'createdAt': FieldValue.serverTimestamp(),
              'updatedAt': FieldValue.serverTimestamp(),
            },
            SetOptions(merge: true),
          );

          transaction.set(
            profileDocument,
            <String, dynamic>{
              'displayName': cleanedDisplayName,
              'schemaVersion': _cloudSchemaVersion,
              'updatedAt': FieldValue.serverTimestamp(),
            },
            SetOptions(merge: true),
          );

          if (oldNameDocument != null &&
              oldNameSnapshot != null &&
              oldNameSnapshot.exists &&
              oldNameSnapshot.data()?['userId'] == user.uid) {
            transaction.delete(oldNameDocument);
          }
        },
      );
    } on PlayerProfileException {
      rethrow;
    } on FirebaseException {
      throw const PlayerProfileException(
        'Your player name could not be saved. Please try again.',
      );
    }
  }


}

class PlayerProfileException implements Exception {
  const PlayerProfileException(
    this.message,
  );

  final String message;

  @override
  String toString() => message;
}
