import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';

import '../theme/app_colors.dart';
import '../services/account_auth_service.dart';
import 'account_deletion_progress_screen.dart';
import '../widgets/app_home_button.dart';

/// Delete Account information and review screen.
///
/// The destructive action must remain disabled until a secure server-side
/// account-deletion endpoint has been deployed and verified. Do not call
/// FirebaseAuth.currentUser!.delete() directly: that would leave Firestore
/// profile, league and leaderboard records behind.
class DeleteAccountScreen extends StatefulWidget {
  const DeleteAccountScreen({super.key});

  @override
  State<DeleteAccountScreen> createState() => _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends State<DeleteAccountScreen> {
  // Only set this when the deployed callable and recovery worker are verified.
  static const bool _serverDeletionReady = bool.fromEnvironment(
    'FIRST_GUESS_ACCOUNT_DELETION_ENABLED', defaultValue: false);
  bool _busy = false;

  Future<bool> _verifyIdentity() async {
    final verify = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.panel,
        title: const Text('VERIFY YOUR IDENTITY', style: TextStyle(color: AppColors.white, fontFamily: 'Oswald')),
        content: const Text('For your security, please verify with your existing Google or Apple account. You will stay signed in to First Guess.', style: TextStyle(color: AppColors.white)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('CANCEL')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('VERIFY IDENTITY')),
        ],
      ),
    );
    if (verify != true || !mounted) return false;
    try {
      await AccountAuthService.reauthenticateCurrentUserForDeletion();
      return mounted;
    } on AccountAuthException catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.message)));
      return false;
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Identity verification did not complete. No deletion request was submitted.')));
      return false;
    }
  }

  Future<void> _submitDeletionRequest() async {
    final response = await FirebaseFunctions.instanceFor(region: 'us-central1')
        .httpsCallable('requestAccountDeletion').call(<String, dynamic>{
      'confirm': 'DELETE MY ACCOUNT',
    });
    if (response.data is! Map || (response.data as Map)['accepted'] != true) {
      throw StateError('The server did not accept the deletion request.');
    }
  }

  Future<void> _requestDeletion() async {
    if (_busy || !_serverDeletionReady || FirebaseAuth.instance.currentUser == null) return;
    final controller = TextEditingController();
    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => StatefulBuilder(
          builder: (dialogContext, refresh) => AlertDialog(
            backgroundColor: AppColors.panel,
            title: const Text('PERMANENTLY DELETE ACCOUNT?',
              style: TextStyle(fontFamily: 'Oswald', color: AppColors.white)),
            content: Column(mainAxisSize: MainAxisSize.min, children: [
              const Text('This cannot be undone. Type DELETE MY ACCOUNT to confirm.',
                style: TextStyle(color: AppColors.white)),
              const SizedBox(height: 14),
              TextField(
                controller: controller,
                autocorrect: false,
                textCapitalization: TextCapitalization.characters,
                style: const TextStyle(color: AppColors.white),
                decoration: const InputDecoration(hintText: 'DELETE MY ACCOUNT'),
                onChanged: (_) => refresh(() {}),
              ),
            ]),
            actions: [
              TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('CANCEL')),
              FilledButton(
                onPressed: controller.text.trim() == 'DELETE MY ACCOUNT'
                    ? () => Navigator.pop(dialogContext, true) : null,
                child: const Text('DELETE MY ACCOUNT'),
              ),
            ],
          ),
        ),
      );
      if (confirmed != true || !mounted) return;
      setState(() => _busy = true);
      // This endpoint queues a durable deletion job. It does NOT signal completion.
      // The user's auth session is retained until the server finishes deletion.
      try {
        await _submitDeletionRequest();
      } on FirebaseFunctionsException catch (error) {
        if (error.code != 'failed-precondition') rethrow;
        if (!mounted) return;
        final verified = await _verifyIdentity();
        if (!verified || !mounted) return;
        // Retry once only, after verified reauthentication of the same user.
        await _submitDeletionRequest();
      }
      if (!mounted) return;
      final deletionUid = FirebaseAuth.instance.currentUser?.uid;
      if (deletionUid == null) return;
      await AccountDeletionState.markPending(deletionUid);
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(
          builder: (_) => const AccountDeletionProgressScreen(),
        ),
        (_) => false,
      );
    } on FirebaseFunctionsException catch (error) {
      if (!mounted) return;
      final message = error.code == 'failed-precondition'
          ? 'The server could not complete the security check. Please try again or contact support.'
          : (error.message ?? 'Unable to request deletion. Please try again later.');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(
              'Unable to request deletion. Please try again later.')),
        );
      }
    } finally {
      controller.dispose();
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    const bodyStyle = TextStyle(color: AppColors.white, height: 1.5);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'DELETE ACCOUNT',
          style: TextStyle(
            fontFamily: 'Oswald',
            fontWeight: FontWeight.w600,
            letterSpacing: 0.6,
          ),
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: Center(child: FirstGuessHomeButton()),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
              children: [
                const Icon(
                  Icons.delete_outline_rounded,
                  color: AppColors.orange,
                  size: 48,
                ),
                const SizedBox(height: 12),
                const Text(
                  'DELETE YOUR FIRST GUESS ACCOUNT',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.white,
                    fontFamily: 'Oswald',
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'You can request permanent deletion of your account from here. '
                  'Please read the information below before continuing.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.grey, height: 1.5),
                ),
                const SizedBox(height: 20),
                _section(
                  heading: 'HOW TO DELETE YOUR ACCOUNT',
                  children: const [
                    _NumberedStep(
                      number: '1',
                      text: 'Make sure you are signed in to the First Guess account you want to delete.',
                    ),
                    SizedBox(height: 12),
                    _NumberedStep(
                      number: '2',
                      text: 'Select DELETE MY ACCOUNT below.',
                    ),
                    SizedBox(height: 12),
                    _NumberedStep(
                      number: '3',
                      text: 'Type DELETE MY ACCOUNT to confirm. For security, you may need to sign in again.',
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _section(
                  heading: 'WHAT WILL BE DELETED?',
                  children: const [
                    Text(
                      'Your account, profile, saved progress, XP, achievements '
                      'and personal leaderboard entries will be permanently '
                      'removed. This cannot be undone.',
                      style: bodyStyle,
                    ),
                    SizedBox(height: 12),
                    Text(
                      'You will be removed from your leagues. If you own a league '
                      'with other members, ownership will transfer to an existing '
                      'member. An empty league will be removed.',
                      style: bodyStyle,
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Account deletion applies across all your devices, including '
                      'the First Guess website. It will not delete other players\' '
                      'accounts or progress.',
                      style: bodyStyle,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (user == null)
                  const Text(
                    'No signed-in First Guess account was found.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.orangeAccent),
                  )
                else if (!_serverDeletionReady)
                  const Text(
                    'Account deletion is not available in this preview build. '
                    'The secure deletion service must be connected and tested first.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.grey, height: 1.5),
                  ),
                const SizedBox(height: 14),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    // Intentionally disabled until the server-side deletion
                    // workflow, including recovery and recent sign-in, is live.
                    onPressed: !_busy && _serverDeletionReady && user != null
                        ? _requestDeletion
                        : null,
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.red.shade700,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(_busy ? 'REQUESTING DELETION...' : 'DELETE MY ACCOUNT'),
                  ),
                ),
                const SizedBox(height: 6),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('CANCEL'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static Widget _section({
    required String heading,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.panel,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            heading,
            style: const TextStyle(
              fontFamily: 'Oswald',
              fontSize: 19,
              color: AppColors.orange,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

class _NumberedStep extends StatelessWidget {
  const _NumberedStep({required this.number, required this.text});

  final String number;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 27,
          height: 27,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.orange.withValues(alpha: 0.12),
            border: Border.all(color: AppColors.orange),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            number,
            style: const TextStyle(
              color: AppColors.orange,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(color: AppColors.white, height: 1.5),
          ),
        ),
      ],
    );
  }
}
