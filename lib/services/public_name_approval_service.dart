import 'package:cloud_functions/cloud_functions.dart';

/// Server-side moderation. Firestore rules require a recent approval matching
/// the exact name and scope before allowing initial profile/league creation.
class PublicNameApprovalService {
  PublicNameApprovalService._();

  static Future<void> approve({
    required String name,
    required String scope,
  }) async {
    try {
      await FirebaseFunctions.instance.httpsCallable('approvePublicName').call(
        <String, dynamic>{'name': name.trim(), 'scope': scope},
      );
    } on FirebaseFunctionsException catch (error) {
      if (error.code == 'invalid-argument' || error.code == 'permission-denied') {
        throw PublicNameApprovalException('This name isn\'t permitted. Please choose another.');
      }
      throw PublicNameApprovalException('Couldn\'t check this name. Please try again.');
    }
  }
}

class PublicNameApprovalException implements Exception {
  const PublicNameApprovalException(this.message);
  final String message;
  @override
  String toString() => message;
}
