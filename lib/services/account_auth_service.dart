import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'guest_progress_merge_service.dart';

enum AccountLinkStatus { linked, alreadyLinked }

class AccountLinkResult {
  final AccountLinkStatus status;
  final User user;

  const AccountLinkResult({required this.status, required this.user});
}

class AccountAuthException implements Exception {
  final String code;
  final String message;

  const AccountAuthException({required this.code, required this.message});

  @override
  String toString() => message;
}

class AccountAuthService {
  AccountAuthService._();

  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  static Future<void>? _googleInitialisation;
  static OAuthCredential? _pendingExistingGoogleCredential;

  static User? get currentUser => _auth.currentUser;

  static bool get isGuest => _auth.currentUser?.isAnonymous ?? false;

  static bool get isGoogleLinked {
    final User? user = _auth.currentUser;

    if (user == null) {
      return false;
    }

    return user.providerData.any(
      (UserInfo provider) => provider.providerId == 'google.com',
    );
  }

  static bool get isAppleLinked =>
      _auth.currentUser?.providerData.any(
        (provider) => provider.providerId == 'apple.com',
      ) ??
      false;

  static String? get email => _auth.currentUser?.email;

  /// Verify the currently signed-in account without signing it out.
  /// Never use signInWithCredential here: it can switch Firebase users.
  static Future<void> reauthenticateCurrentUserForDeletion() async {
    final User? user = _auth.currentUser;
    if (user == null) {
      throw const AccountAuthException(
        code: 'not-signed-in',
        message: 'Please sign in before deleting your account.',
      );
    }
    final Set<String> providers = user.providerData
        .map((info) => info.providerId)
        .toSet();
    try {
      if (providers.contains('google.com')) {
        if (kIsWeb) {
          await user.reauthenticateWithPopup(GoogleAuthProvider());
        } else {
          await _initialiseGoogleSignIn();
          if (!_googleSignIn.supportsAuthenticate()) {
            throw const AccountAuthException(
              code: 'unsupported',
              message: 'Google verification is unavailable on this device.',
            );
          }
          final account = await _googleSignIn.authenticate();
          final token = account.authentication.idToken;
          if (token == null || token.isEmpty) {
            throw const AccountAuthException(
              code: 'missing-google-token',
              message: 'Google could not verify your identity.',
            );
          }
          await user.reauthenticateWithCredential(
            GoogleAuthProvider.credential(idToken: token),
          );
        }
      } else if (providers.contains('apple.com')) {
        final provider = AppleAuthProvider();
        if (kIsWeb) {
          await user.reauthenticateWithPopup(provider);
        } else {
          await user.reauthenticateWithProvider(provider);
        }
      } else if (user.isAnonymous) {
        throw const AccountAuthException(
          code: 'guest-reauthentication-unavailable',
          message:
              'This guest session is too old to verify securely. Guest accounts cannot reauthenticate with Google or Apple unless they are linked first.',
        );
      } else {
        throw const AccountAuthException(
          code: 'unsupported-provider',
          message: 'This sign-in method cannot be verified in the app yet.',
        );
      }
      if (_auth.currentUser?.uid != user.uid) {
        throw const AccountAuthException(
          code: 'account-changed',
          message:
              'Verification returned a different account. Your deletion request has not been submitted.',
        );
      }
    } on AccountAuthException {
      rethrow;
    } on FirebaseAuthException catch (error) {
      throw AccountAuthException(
        code: error.code,
        message:
            error.message ?? 'Identity verification failed. Please try again.',
      );
    } on GoogleSignInException catch (error) {
      throw AccountAuthException(
        code: 'google-verification-failed',
        message:
            error.description ?? 'Google verification was cancelled or failed.',
      );
    }
  }

  static Future<User> ensureSignedInUser() async {
    final User? existingUser = _auth.currentUser;

    if (existingUser != null) {
      return existingUser;
    }

    final UserCredential credential = await _auth.signInAnonymously();
    final User? user = credential.user;

    if (user == null) {
      throw const AccountAuthException(
        code: 'anonymous-sign-in-failed',
        message: 'First Guess could not create a guest session.',
      );
    }

    return user;
  }

  static Future<AccountLinkResult> linkCurrentGuestToGoogle() async {
    final User user = await ensureSignedInUser();

    if (_hasGoogleProvider(user)) {
      return AccountLinkResult(
        status: AccountLinkStatus.alreadyLinked,
        user: user,
      );
    }

    try {
      final UserCredential linkedCredential;

      if (kIsWeb) {
        final GoogleAuthProvider provider = GoogleAuthProvider();

        linkedCredential = await user.linkWithPopup(provider);
      } else {
        await _initialiseGoogleSignIn();

        if (!_googleSignIn.supportsAuthenticate()) {
          throw const AccountAuthException(
            code: 'google-sign-in-not-supported',
            message: 'Google sign-in is not supported on this device.',
          );
        }

        final GoogleSignInAccount googleAccount = await _googleSignIn
            .authenticate();

        final GoogleSignInAuthentication googleAuthentication =
            googleAccount.authentication;

        final String? idToken = googleAuthentication.idToken;

        if (idToken == null || idToken.isEmpty) {
          throw const AccountAuthException(
            code: 'missing-google-id-token',
            message: 'Google did not return a valid sign-in token.',
          );
        }

        final OAuthCredential googleCredential = GoogleAuthProvider.credential(
          idToken: idToken,
        );

        // Keep this credential temporarily. If Firebase reports that the
        // Google account already belongs to an existing First Guess
        // account, the restore flow can reuse the same authentication
        // instead of showing the Android account chooser a second time.
        _pendingExistingGoogleCredential = googleCredential;

        linkedCredential = await user.linkWithCredential(googleCredential);
      }

      final User? linkedUser = linkedCredential.user;

      _pendingExistingGoogleCredential = null;

      if (linkedUser == null) {
        throw const AccountAuthException(
          code: 'google-link-failed',
          message: 'First Guess could not link the Google account.',
        );
      }

      return AccountLinkResult(
        status: AccountLinkStatus.linked,
        user: linkedUser,
      );
    } on FirebaseAuthException catch (error) {
      switch (error.code) {
        case 'provider-already-linked':
          _pendingExistingGoogleCredential = null;
          final User? refreshedUser = _auth.currentUser;

          if (refreshedUser != null) {
            return AccountLinkResult(
              status: AccountLinkStatus.alreadyLinked,
              user: refreshedUser,
            );
          }

          throw const AccountAuthException(
            code: 'provider-already-linked',
            message: 'Google is already linked to this First Guess account.',
          );

        case 'credential-already-in-use':
        case 'account-exists-with-different-credential':
          throw const AccountAuthException(
            code: 'existing-first-guess-account',
            message:
                'That Google account is already connected to another '
                'First Guess account. Your guest progress has not been changed.',
          );

        case 'popup-closed-by-user':
        case 'cancelled-popup-request':
          throw const AccountAuthException(
            code: 'google-sign-in-cancelled',
            message: 'Google sign-in was cancelled.',
          );

        case 'popup-blocked':
          throw const AccountAuthException(
            code: 'popup-blocked',
            message: 'The Google sign-in window was blocked by the browser.',
          );

        case 'network-request-failed':
          throw const AccountAuthException(
            code: 'network-request-failed',
            message:
                'Google sign-in could not connect. Check your internet connection.',
          );

        default:
          throw AccountAuthException(
            code: error.code,
            message: error.message ?? 'Google sign-in could not be completed.',
          );
      }
    } on GoogleSignInException catch (error) {
      throw AccountAuthException(
        code: 'google-sign-in-error',
        message: error.description ?? 'Google sign-in could not be completed.',
      );
    } on AccountAuthException {
      rethrow;
    } catch (_) {
      throw const AccountAuthException(
        code: 'google-sign-in-error',
        message: 'Google sign-in could not be completed.',
      );
    }
  }

  static Future<User> signInToExistingGoogleAccount() async {
    GuestProgressSnapshot guestSnapshot;

    try {
      guestSnapshot =
          await GuestProgressMergeService.captureAndPersistCurrentGuestProgress();
    } on GuestProgressMergeException catch (error) {
      throw AccountAuthException(
        code: 'guest-progress-capture-failed',
        message: error.message,
      );
    }

    try {
      final UserCredential signedInCredential;

      if (kIsWeb) {
        final GoogleAuthProvider provider = GoogleAuthProvider();
        signedInCredential = await _auth.signInWithPopup(provider);
      } else {
        OAuthCredential? googleCredential = _pendingExistingGoogleCredential;

        if (googleCredential == null) {
          await _initialiseGoogleSignIn();

          if (!_googleSignIn.supportsAuthenticate()) {
            throw const AccountAuthException(
              code: 'google-sign-in-not-supported',
              message: 'Google sign-in is not supported on this device.',
            );
          }

          final GoogleSignInAccount googleAccount = await _googleSignIn
              .authenticate();

          final GoogleSignInAuthentication googleAuthentication =
              googleAccount.authentication;

          final String? idToken = googleAuthentication.idToken;

          if (idToken == null || idToken.isEmpty) {
            throw const AccountAuthException(
              code: 'missing-google-id-token',
              message: 'Google did not return a valid sign-in token.',
            );
          }

          googleCredential = GoogleAuthProvider.credential(idToken: idToken);
        }

        signedInCredential = await _auth.signInWithCredential(googleCredential);

        _pendingExistingGoogleCredential = null;
      }

      final User? signedInUser = signedInCredential.user;

      if (signedInUser == null) {
        throw const AccountAuthException(
          code: 'google-recovery-failed',
          message: 'First Guess could not recover the existing Google account.',
        );
      }

      try {
        await GuestProgressMergeService.mergeIntoCurrentAccount(guestSnapshot);
      } on GuestProgressMergeException catch (error) {
        throw AccountAuthException(
          code: 'guest-merge-pending',
          message:
              'Your account was restored, but the guest progress merge '
              'still needs to finish. ${error.message}',
        );
      }

      _pendingExistingGoogleCredential = null;
      return signedInUser;
    } on FirebaseAuthException catch (error) {
      switch (error.code) {
        case 'popup-closed-by-user':
        case 'cancelled-popup-request':
          throw const AccountAuthException(
            code: 'google-sign-in-cancelled',
            message: 'Google sign-in was cancelled.',
          );

        case 'popup-blocked':
          throw const AccountAuthException(
            code: 'popup-blocked',
            message: 'The Google sign-in window was blocked by the browser.',
          );

        case 'network-request-failed':
          throw const AccountAuthException(
            code: 'network-request-failed',
            message:
                'Google sign-in could not connect. Check your internet connection.',
          );

        default:
          throw AccountAuthException(
            code: error.code,
            message:
                error.message ??
                'Google account recovery could not be completed.',
          );
      }
    } on GoogleSignInException catch (error) {
      throw AccountAuthException(
        code: 'google-sign-in-error',
        message:
            error.description ??
            'Google account recovery could not be completed.',
      );
    } on AccountAuthException {
      rethrow;
    } catch (_) {
      throw const AccountAuthException(
        code: 'google-recovery-error',
        message: 'Google account recovery could not be completed.',
      );
    }
  }

  /// Link an Apple ID to the current Firebase account without changing its UID.
  /// Never sign in as a replacement user here: that could strand guest data.
  static Future<AccountLinkResult> linkCurrentAccountToApple() async {
    final User user = await ensureSignedInUser();
    if (isAppleLinked) {
      return AccountLinkResult(
        status: AccountLinkStatus.alreadyLinked,
        user: user,
      );
    }
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.iOS) {
      throw const AccountAuthException(
        code: 'apple-platform-unsupported',
        message: 'Apple account connection is available in the iPhone app.',
      );
    }
    try {
      final UserCredential result = await user.linkWithProvider(
        AppleAuthProvider(),
      );
      if (result.user == null || result.user!.uid != user.uid) {
        throw const AccountAuthException(
          code: 'apple-account-changed',
          message:
              'Apple sign-in did not preserve your First Guess account. Please contact support.',
        );
      }
      return AccountLinkResult(
        status: AccountLinkStatus.linked,
        user: result.user!,
      );
    } on FirebaseAuthException catch (error) {
      if (error.code == 'provider-already-linked') {
        return AccountLinkResult(
          status: AccountLinkStatus.alreadyLinked,
          user: user,
        );
      }
      if (error.code == 'credential-already-in-use' ||
          error.code == 'account-exists-with-different-credential') {
        throw const AccountAuthException(
          code: 'existing-apple-account',
          message:
              'This Apple ID already belongs to an existing First Guess account. Your current progress is unchanged.',
        );
      }
      throw AccountAuthException(
        code: error.code,
        message:
            error.message ??
            'Apple account connection failed or was cancelled.',
      );
    }
  }

  /// Restore an Apple-backed First Guess account only after user confirmation.
  /// Capture local guest progress first, then use the existing protected merge.
  static Future<User> signInToExistingAppleAccount() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.iOS) {
      throw const AccountAuthException(
        code: 'apple-platform-unsupported',
        message: 'Apple account recovery is available in the iPhone app.',
      );
    }
    final GuestProgressSnapshot snapshot;
    try {
      snapshot =
          await GuestProgressMergeService.captureAndPersistCurrentGuestProgress();
    } on GuestProgressMergeException catch (error) {
      throw AccountAuthException(
        code: 'guest-progress-capture-failed',
        message: error.message,
      );
    }
    try {
      final result = await _auth.signInWithProvider(AppleAuthProvider());
      final user = result.user;
      if (user == null) {
        throw const AccountAuthException(
          code: 'apple-recovery-failed',
          message: 'Could not restore your Apple account.',
        );
      }
      try {
        await GuestProgressMergeService.mergeIntoCurrentAccount(snapshot);
      } on GuestProgressMergeException catch (error) {
        throw AccountAuthException(
          code: 'guest-merge-pending',
          message:
              'Your Apple account was restored, but merging local progress still needs to finish. ${error.message}',
        );
      }
      return user;
    } on FirebaseAuthException catch (error) {
      throw AccountAuthException(
        code: error.code,
        message:
            error.message ?? 'Apple account recovery failed or was cancelled.',
      );
    }
  }

  static Future<void> retryPendingGuestProgressMerge() async {
    try {
      await GuestProgressMergeService.mergePendingIntoCurrentAccount();
    } on GuestProgressMergeException catch (error) {
      throw AccountAuthException(
        code: 'guest-merge-pending',
        message: error.message,
      );
    }
  }

  static Future<bool> hasPendingGuestProgressMerge() {
    return GuestProgressMergeService.hasPendingMerge();
  }

  static Future<void> _initialiseGoogleSignIn() {
    return _googleInitialisation ??= _googleSignIn.initialize();
  }

  static bool _hasGoogleProvider(User user) {
    return user.providerData.any(
      (UserInfo provider) => provider.providerId == 'google.com',
    );
  }
}
