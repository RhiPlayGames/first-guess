import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../theme/app_colors.dart';
import '../widgets/app_home_button.dart';

/// The website is the canonical source of the Privacy Policy.
class PrivacyPolicyScreen extends StatefulWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  State<PrivacyPolicyScreen> createState() => _PrivacyPolicyScreenState();
}

class _PrivacyPolicyScreenState extends State<PrivacyPolicyScreen> {
  static final Uri _policy = Uri.parse('https://rhiplaygames.com/privacy.html');
  bool _opening = false;

  Future<void> _openPolicy() async {
    if (_opening) return;
    setState(() => _opening = true);
    try {
      final bool opened = await launchUrl(_policy, mode: LaunchMode.externalApplication);
      if (!opened) throw StateError('Browser could not open the privacy policy');
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Could not open the Privacy Policy. Visit ${_policy.toString()} in your browser.'),
        ));
      }
    } finally {
      if (mounted) setState(() => _opening = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.background,
    appBar: AppBar(
      backgroundColor: AppColors.background,
      foregroundColor: AppColors.white,
      title: const Text('PRIVACY POLICY', style: TextStyle(fontFamily: 'Oswald')),
      centerTitle: true,
      actions: const [Padding(padding: EdgeInsets.only(right: 16), child: Center(child: FirstGuessHomeButton()))],
    ),
    body: SafeArea(child: Center(child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Text('The current RhiPlay Privacy Policy is published on our website.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.white, fontFamily: 'Inter', fontSize: 16)),
        const SizedBox(height: 24),
        FilledButton(onPressed: _opening ? null : _openPolicy,
          style: FilledButton.styleFrom(backgroundColor: AppColors.orange),
          child: Text(_opening ? 'OPENING…' : 'READ PRIVACY POLICY')),
        const SizedBox(height: 12),
        SelectableText(_policy.toString(), textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.white)),
      ]),
    ))),
  );
}
