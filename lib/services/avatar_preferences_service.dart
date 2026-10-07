import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AvatarPreferencesService {
  static const String _selectedAvatarKey = 'selected_avatar_path';
  static const int _cloudSchemaVersion = 1;

  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static DocumentReference<Map<String, dynamic>>?
      get _cloudAvatarDocument {
    final User? user = _auth.currentUser;

    if (user == null) {
      return null;
    }

    return _firestore
        .collection('players')
        .doc(user.uid)
        .collection('progress')
        .doc('avatar_preferences');
  }

  static Future<String?> loadSelectedAvatarPath() async {
    final SharedPreferences preferences =
        await SharedPreferences.getInstance();

    final String? localAvatarPath =
        preferences.getString(_selectedAvatarKey);

    final DocumentReference<Map<String, dynamic>>?
        cloudDocument = _cloudAvatarDocument;

    if (cloudDocument == null) {
      return localAvatarPath;
    }

    try {
      final DocumentSnapshot<Map<String, dynamic>> snapshot =
          await cloudDocument.get();

      if (!snapshot.exists) {
        if (localAvatarPath != null && localAvatarPath.isNotEmpty) {
          await cloudDocument.set(
            <String, dynamic>{
              'selectedAvatarPath': localAvatarPath,
              'schemaVersion': _cloudSchemaVersion,
              'updatedAt': FieldValue.serverTimestamp(),
            },
            SetOptions(merge: true),
          );
        }

        return localAvatarPath;
      }

      final dynamic rawCloudAvatarPath =
          snapshot.data()?['selectedAvatarPath'];

      if (rawCloudAvatarPath is String &&
          rawCloudAvatarPath.isNotEmpty) {
        if (rawCloudAvatarPath != localAvatarPath) {
          await preferences.setString(
            _selectedAvatarKey,
            rawCloudAvatarPath,
          );
        }

        return rawCloudAvatarPath;
      }

      if (localAvatarPath != null && localAvatarPath.isNotEmpty) {
        await cloudDocument.set(
          <String, dynamic>{
            'selectedAvatarPath': localAvatarPath,
            'schemaVersion': _cloudSchemaVersion,
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
      }

      return localAvatarPath;
    } on FirebaseException {
      return localAvatarPath;
    }
  }

  static Future<void> saveSelectedAvatarPath(
    String avatarPath,
  ) async {
    final SharedPreferences preferences =
        await SharedPreferences.getInstance();

    await preferences.setString(
      _selectedAvatarKey,
      avatarPath,
    );

    final DocumentReference<Map<String, dynamic>>?
        cloudDocument = _cloudAvatarDocument;

    if (cloudDocument == null) {
      return;
    }

    try {
      await cloudDocument.set(
        <String, dynamic>{
          'selectedAvatarPath': avatarPath,
          'schemaVersion': _cloudSchemaVersion,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    } on FirebaseException {
      // Keep the local avatar even if cloud sync temporarily fails.
    }
  }
}
