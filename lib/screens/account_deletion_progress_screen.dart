import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/player_stats_service.dart';
import '../theme/app_colors.dart';
import 'home_screen.dart';

/// Persists the pending deletion across app restarts. The authenticated user
/// must remain in place while the server-side deletion worker finishes.
class AccountDeletionState {
  static const String pendingUidKey = 'account_deletion_pending_uid_v1';
  static const String pendingReceiptKey = 'account_deletion_receipt_v1';
  static final SharedPreferencesAsync _prefs = SharedPreferencesAsync();

  static Future<String?> pendingUid() => _prefs.getString(pendingUidKey);

  static Future<void> markPending(String uid, {required String receipt}) async {
    await _prefs.setString(pendingReceiptKey, receipt);
    await _prefs.setString(pendingUidKey, uid);
  }

  static Future<String?> pendingReceipt() =>
      _prefs.getString(pendingReceiptKey);

  /// Only use this when the server has definitely rejected the request.
  /// A timeout is ambiguous: the request may already have been accepted.
  static Future<void> clearRejectedRequest() async {
    await _prefs.remove(pendingUidKey);
    await _prefs.remove(pendingReceiptKey);
  }

  static Future<void> clearDeletedAccount() async {
    // Remove all legacy shared player-data preferences as well as async prefs.
    // Clear old account data before a new anonymous account can be created.
    await PlayerStatsService.resetStats();
    await _prefs.clear();
    final legacy = await SharedPreferences.getInstance();
    await legacy.clear();
    await FirebaseAuth.instance.signOut();
  }
}

/// Used both for an in-app request and when reopening while deletion is pending.
/// Never claims success until the server confirms completion (or the legacy
/// Firebase Auth check confirms the old account no longer exists).
class AccountDeletionProgressScreen extends StatefulWidget {
  const AccountDeletionProgressScreen({
    super.key,
    this.alreadyCompleted = false,
  });
  final bool alreadyCompleted;

  @override
  State<AccountDeletionProgressScreen> createState() =>
      _AccountDeletionProgressScreenState();
}

class _AccountDeletionProgressScreenState
    extends State<AccountDeletionProgressScreen> {
  Timer? _timer;
  bool _checking = false;
  bool _completed = false;
  bool _legacyUnverifiable = false;
  bool _recovering = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.alreadyCompleted) {
      _completed = true;
    } else {
      _check();
      _timer = Timer.periodic(const Duration(seconds: 15), (_) => _check());
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _check() async {
    if (_checking || _completed) return;
    _checking = true;
    try {
      final expectedUid = await AccountDeletionState.pendingUid();
      if (expectedUid == null) return;
      final receipt = await AccountDeletionState.pendingReceipt();
      if (receipt != null && receipt.isNotEmpty) {
        final result =
            await FirebaseFunctions.instanceFor(
              region: 'us-central1',
            ).httpsCallable('getAccountDeletionStatus').call(<String, dynamic>{
              'uid': expectedUid,
              'receipt': receipt,
            });
        if (result.data is Map &&
            (result.data as Map)['status'] == 'completed') {
          await AccountDeletionState.clearDeletedAccount();
          _timer?.cancel();
          if (mounted) {
            setState(() {
              _completed = true;
              _legacyUnverifiable = false;
              _error = null;
            });
          }
        } else if (mounted) {
          setState(() => _error = null);
        }
        return;
      }
      // Legacy requests were submitted without a receipt. Never infer
      // completion merely because the login session disappeared.
      final user = FirebaseAuth.instance.currentUser;
      if (user == null || user.uid != expectedUid) {
        // The previous Firebase session was invalidated or signed out.
        // This is NOT, on its own, proof of successful deletion.
        if (mounted) {
          setState(() {
            _legacyUnverifiable = true;
            _error = 'This older deletion request cannot be verified automatically. '
                'You can contact support about the previous account, or start '
                'a separate guest session on this device.';
          });
        }
        return;
      }
      try {
        await user.reload();
        if (mounted) setState(() { _legacyUnverifiable = false; _error = null; });
      } on FirebaseAuthException catch (error) {
        if (error.code == 'user-not-found') {
          await AccountDeletionState.clearDeletedAccount();
          _timer?.cancel();
          if (mounted) {
            setState(() {
              _completed = true;
              _legacyUnverifiable = false;
              _error = null;
            });
          }
        } else if (mounted) {
          setState(
            () =>
                _error = 'Checking deletion status. Please try again shortly.',
          );
        }
      }
    } on FirebaseFunctionsException catch (error) {
      if (mounted) {
        setState(
          () => _error = error.code == 'permission-denied'
              ? 'This deletion request cannot be verified automatically. Please contact support to confirm completion.'
              : 'Unable to verify the deletion request. Please try again shortly or contact support.',
        );
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _error =
              'Unable to verify the deletion request. Please try again shortly or contact support.',
        );
      }
    } finally {
      _checking = false;
    }
  }

  /// Recovery only for a receipt-less, unverifiable legacy request after the
  /// original Firebase session has gone. Does not cancel or complete the
  /// server-side deletion request and cannot restore the previous account.
  Future<void> _startFreshGuest() async {
    if (_recovering || !_legacyUnverifiable || _completed) return;

    // Recheck all security conditions in case the auth state changed.
    final pendingUid = await AccountDeletionState.pendingUid();
    final receipt = await AccountDeletionState.pendingReceipt();
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    if (pendingUid == null ||
        (receipt != null && receipt.isNotEmpty) ||
        currentUid == pendingUid) {
      if (mounted) await _check();
      return;
    }

    if (!mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.panel,
        title: const Text('START A NEW GUEST SESSION?',
            style: TextStyle(color: AppColors.white, fontFamily: 'Oswald')),
        content: const Text(
          'Your previous deletion request has NOT been confirmed as complete. '
          'Continuing will clear saved app data on this device and create a '
          'new guest account. It will not cancel the earlier deletion request '
          'or recover your previous account or progress. Contact support '
          'if you need confirmation about the old account.',
          style: TextStyle(color: AppColors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('CANCEL'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('START AS GUEST'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _recovering = true);
    try {
      // Safeguard against a receipt being created during confirmation.
      final latestUid = await AccountDeletionState.pendingUid();
      final latestReceipt = await AccountDeletionState.pendingReceipt();
      if (latestUid != pendingUid ||
          (latestReceipt != null && latestReceipt.isNotEmpty) ||
          FirebaseAuth.instance.currentUser?.uid == pendingUid) {
        throw StateError('The account state changed. Check status again.');
      }
      // This clears only device-local state and signs out; it makes no
      // statement about deletion completion on Firebase.
      await AccountDeletionState.clearDeletedAccount();
      await FirebaseAuth.instance.signInAnonymously();
      _timer?.cancel();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(builder: (_) => const HomeScreen()),
        (_) => false,
      );
    } catch (error) {
      if (mounted) {
        setState(() => _error =
            'Unable to start a new guest session. Please try again. ($error)');
      }
    } finally {
      if (mounted) setState(() => _recovering = false);
    }
  }

  Future<void> _continue() async {
    if (!_completed) return;
    // No new guest account is created until the person explicitly continues.
    await FirebaseAuth.instance.signInAnonymously();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const HomeScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.background,
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _completed
                    ? Icons.check_circle_outline
                    : Icons.hourglass_bottom,
                color: AppColors.orange,
                size: 58,
              ),
              const SizedBox(height: 18),
              Text(
                _completed
                    ? 'YOUR ACCOUNT HAS BEEN DELETED'
                    : 'ACCOUNT DELETION IN PROGRESS',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Oswald',
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                  color: AppColors.white,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                _completed
                    ? 'Your previous account has been deleted. Its saved progress has been cleared from this device.'
                    : 'Checking your account-deletion request. If it was accepted, your account and associated data are being securely deleted. You can close the app while this finishes.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.white, height: 1.5),
              ),
              if (_error != null && !_completed) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.orangeAccent),
                ),
              ],
              const SizedBox(height: 20),
              if (_completed)
                FilledButton(
                  onPressed: _continue,
                  child: const Text('CONTINUE'),
                )
              else ...[
                OutlinedButton(
                  onPressed: _checking || _recovering ? null : _check,
                  child: const Text('CHECK STATUS'),
                ),
                if (_legacyUnverifiable) ...[
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: _recovering ? null : _startFreshGuest,
                    child: Text(_recovering
                        ? 'STARTING GUEST SESSION...'
                        : 'START AS NEW GUEST'),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    ),
  );
}

/// Startup gate prevents the home screen from loading deleted account data.
class AccountDeletionStartupGate extends StatefulWidget {
  const AccountDeletionStartupGate({super.key});
  @override
  State<AccountDeletionStartupGate> createState() =>
      _AccountDeletionStartupGateState();
}

class _AccountDeletionStartupGateState
    extends State<AccountDeletionStartupGate> {
  bool? _pending;
  bool _legacyDeletionDetected = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final pending = await AccountDeletionState.pendingUid();
    if (pending == null) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Migration for deletion requests submitted by the earlier TestFlight
        // build, before the app tracked deletion requests on-device.
        try {
          await user.reload();
        } on FirebaseAuthException catch (error) {
          if (error.code == 'user-not-found') {
            await AccountDeletionState.clearDeletedAccount();
            _legacyDeletionDetected = true;
          }
          // A transient network error does not prove deletion; avoid clearing.
        }
      }
      if (!_legacyDeletionDetected &&
          FirebaseAuth.instance.currentUser == null) {
        await FirebaseAuth.instance.signInAnonymously();
      }
    }
    if (mounted) setState(() => _pending = pending != null);
  }

  @override
  Widget build(BuildContext context) {
    if (_pending == null) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (_legacyDeletionDetected) {
      return const AccountDeletionProgressScreen(alreadyCompleted: true);
    }
    return _pending!
        ? const AccountDeletionProgressScreen()
        : const HomeScreen();
  }
}
