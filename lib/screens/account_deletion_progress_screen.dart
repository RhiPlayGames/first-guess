import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/player_stats_service.dart';
import '../theme/app_colors.dart';
import 'home_screen.dart';

/// Persists the pending deletion across app restarts. The authenticated user
/// must remain in place while the server-side deletion worker finishes.
class AccountDeletionState {
  static const String pendingUidKey = 'account_deletion_pending_uid_v1';
  static final SharedPreferencesAsync _prefs = SharedPreferencesAsync();

  static Future<String?> pendingUid() => _prefs.getString(pendingUidKey);

  static Future<void> markPending(String uid) async {
    await _prefs.setString(pendingUidKey, uid);
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
/// Never claims success until Firebase Auth reports that the old user is gone.
class AccountDeletionProgressScreen extends StatefulWidget {
  const AccountDeletionProgressScreen({super.key, this.alreadyCompleted = false});
  final bool alreadyCompleted;

  @override
  State<AccountDeletionProgressScreen> createState() =>
      _AccountDeletionProgressScreenState();
}

class _AccountDeletionProgressScreenState extends State<AccountDeletionProgressScreen> {
  Timer? _timer;
  bool _checking = false;
  bool _completed = false;
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
      final user = FirebaseAuth.instance.currentUser;
      if (user == null || user.uid != expectedUid) {
        // The previous Firebase session was invalidated or signed out.
        // This is NOT, on its own, proof of successful deletion.
        if (mounted) {
          setState(() => _error =
          'Unable to verify completion. Please check your connection or contact support.');
        }
        return;
      }
      try {
        await user.reload();
        if (mounted) setState(() => _error = null);
      } on FirebaseAuthException catch (error) {
        if (error.code == 'user-not-found') {
          await AccountDeletionState.clearDeletedAccount();
          _timer?.cancel();
          if (mounted) setState(() { _completed = true; _error = null; });
        } else if (mounted) {
          setState(() => _error = 'Checking deletion status. Please try again shortly.');
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() => _error =
        'Unable to check deletion status. Please try again shortly.');
      }
    } finally {
      _checking = false;
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
    body: Center(child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 420),
      child: Padding(padding: const EdgeInsets.all(24), child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_completed ? Icons.check_circle_outline : Icons.hourglass_bottom,
              color: AppColors.orange, size: 58),
          const SizedBox(height: 18),
          Text(_completed ? 'YOUR ACCOUNT HAS BEEN DELETED' : 'ACCOUNT DELETION IN PROGRESS',
            textAlign: TextAlign.center,
            style: const TextStyle(fontFamily: 'Oswald', fontSize: 25,
              fontWeight: FontWeight.bold, color: AppColors.white)),
          const SizedBox(height: 18),
          Text(_completed
              ? 'Your previous account has been deleted. Its saved progress has been cleared from this device.'
              : 'Your request has been accepted. We are securely deleting your account and associated data. You can close the app while this finishes.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.white, height: 1.5)),
          if (_error != null && !_completed) ...[
            const SizedBox(height: 12),
            Text(_error!, textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.orangeAccent)),
          ],
          const SizedBox(height: 20),
          if (_completed)
            FilledButton(onPressed: _continue, child: const Text('CONTINUE'))
          else
            OutlinedButton(onPressed: _check, child: const Text('CHECK STATUS')),
        ],
      )),
    )),
  );
}

/// Startup gate prevents the home screen from loading deleted account data.
class AccountDeletionStartupGate extends StatefulWidget {
  const AccountDeletionStartupGate({super.key});
  @override
  State<AccountDeletionStartupGate> createState() => _AccountDeletionStartupGateState();
}

class _AccountDeletionStartupGateState extends State<AccountDeletionStartupGate> {
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
      if (!_legacyDeletionDetected && FirebaseAuth.instance.currentUser == null) {
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
      body: Center(child: CircularProgressIndicator()));
    }
    if (_legacyDeletionDetected) {
      return const AccountDeletionProgressScreen(alreadyCompleted: true);
    }
    return _pending! ? const AccountDeletionProgressScreen() : const HomeScreen();
  }
}
