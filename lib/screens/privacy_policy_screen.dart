import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../widgets/app_home_button.dart';
import 'support_screen.dart';

/// In-app copy of the official RhiPlay Privacy Policy, 13 October 2026.
class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.background,
    appBar: AppBar(
      backgroundColor: AppColors.background,
      foregroundColor: AppColors.white,
      centerTitle: true,
      title: const Text('PRIVACY POLICY', style: TextStyle(fontFamily: 'Oswald')),
      actions: const [Padding(padding: EdgeInsets.only(right: 16), child: Center(child: FirstGuessHomeButton()))],
    ),
    body: SafeArea(child: ListView(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 30),
      children: [
        const Text('Last updated: 13 October 2026', textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.orange, fontFamily: 'Inter', fontSize: 14)),
        const SizedBox(height: 16),
        const _PolicySection('ABOUT THIS POLICY',
          'This policy explains how RhiPlay handles personal information when you play First Guess in the app or online and when you visit our website.'),
        const _PolicySection('INFORMATION WE COLLECT',
          'We may process your player name, avatar, account identifier, details from your sign-in provider, gameplay progress, XP, achievements, scores, leagues and leaderboard activity. We also process technical and diagnostic information, including device, browser and network details, to maintain the service. Support requests can contain information you provide.'),
        const _PolicySection('HOW INFORMATION IS USED',
          'Information is used to operate First Guess, synchronise progress, manage accounts and leagues, show rankings, provide support, prevent misuse, investigate problems and keep the service secure.'),
        const _PolicySection('THIRD-PARTY SERVICES',
          'We use Google Firebase for authentication, storage and other services. You may sign in using Google or Apple. Our hosting, platform and infrastructure providers may also handle technical data needed to deliver the game. Their own privacy terms may apply.'),
        const _PolicySection('DATA RETENTION',
          'We keep account and gameplay data while necessary to provide the service. Account deletion requests aim to remove associated personal gameplay data, subject to lawful retention obligations. Processing a request may take time.'),
        const _PolicySection('YOUR CHOICES AND RIGHTS',
          'Your privacy rights may include access, correction and deletion, depending on where you live. Signed-in players can request account deletion in account settings, or contact support for help.'),
        const _PolicySection('CHILDREN',
          'We do not intend to collect children’s personal information where parental consent is required without suitable safeguards. Contact support if you have concerns.'),
        const _PolicySection('CHANGES',
          'We may revise this policy as First Guess changes. The current policy and its revision date are also published at rhiplaygames.com/privacy.html.'),
        const SizedBox(height: 14),
        OutlinedButton(onPressed: () => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const SupportScreen())),
          child: const Text('CONTACT SUPPORT')),
      ],
    )),
  );
}

class _PolicySection extends StatelessWidget {
  const _PolicySection(this.title, this.body);
  final String title;
  final String body;
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(17),
    decoration: BoxDecoration(color: AppColors.panel,
      border: Border.all(color: AppColors.border), borderRadius: BorderRadius.circular(14)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: const TextStyle(fontFamily: 'Oswald', fontSize: 18,
        fontWeight: FontWeight.w600, color: AppColors.orange)),
      const SizedBox(height: 9),
      Text(body, style: const TextStyle(fontFamily: 'Inter', color: AppColors.white, height: 1.5)),
    ]),
  );
}
