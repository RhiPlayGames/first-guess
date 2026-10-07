import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';
import '../widgets/app_home_button.dart';
import 'privacy_policy_screen.dart';
import 'terms_of_use_screen.dart';

class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

  static const String _supportEmail = 'developer@rhiplaygames.com';

  Future<void> _copyEmail(BuildContext context) async {
    await Clipboard.setData(
      const ClipboardData(text: _supportEmail),
    );

    if (!context.mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text(
            'Support email copied to clipboard.',
          ),
        ),
      );
  }

  void _openPrivacyPolicy(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => const PrivacyPolicyScreen(),
      ),
    );
  }

  void _openTerms(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => const TermsOfUseScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'SUPPORT',
          style: TextStyle(
            fontFamily: 'Oswald',
            fontWeight: FontWeight.w600,
            letterSpacing: 0.6,
          ),
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: Center(
              child: FirstGuessHomeButton(),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 32),
          children: [
            const _SupportCard(
              children: [
                _SupportParagraph(
                  'Need help with First Guess? This is the official RhiPlay '
                  'support page.',
                ),
              ],
            ),
            const SizedBox(height: 14),
            const _SupportSection(
              title: 'BEFORE CONTACTING US',
              paragraphs: [
                'If something is not working correctly, try closing and '
                    'reopening the app, checking your internet connection and '
                    'making sure you are using the latest available version.',
              ],
            ),
            const SizedBox(height: 14),
            _SupportSection(
              title: 'ACCOUNT HELP',
              paragraphs: const [
                'For account access, profile or account-deletion questions, '
                    'please contact us using the support email below.',
              ],
              extra: _EmailCard(
                email: _supportEmail,
                onCopy: () => _copyEmail(context),
              ),
            ),
            const SizedBox(height: 14),
            _SupportSection(
              title: 'REPORT A PROBLEM',
              paragraphs: const [
                'When reporting a technical issue, it helps to include your '
                    'device model, operating-system version, app version and a '
                    'short description of what happened. Screenshots can also '
                    'be useful.',
              ],
              extra: _EmailCard(
                email: _supportEmail,
                onCopy: () => _copyEmail(context),
              ),
            ),
            const SizedBox(height: 14),
            _SupportSection(
              title: 'PRIVACY AND LEGAL',
              paragraphs: const [
                'Read our Privacy Policy or Terms of Use.',
              ],
              extra: Column(
                children: [
                  _SupportLinkTile(
                    title: 'PRIVACY POLICY',
                    onTap: () => _openPrivacyPolicy(context),
                  ),
                  const SizedBox(height: 10),
                  _SupportLinkTile(
                    title: 'TERMS OF USE',
                    onTap: () => _openTerms(context),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _SupportCard(
              children: [
                const _SupportParagraph(
                  'For First Guess support, contact:',
                ),
                const SizedBox(height: 10),
                _EmailCard(
                  email: _supportEmail,
                  onCopy: () => _copyEmail(context),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SupportSection extends StatelessWidget {
  final String title;
  final List<String> paragraphs;
  final Widget? extra;

  const _SupportSection({
    required this.title,
    required this.paragraphs,
    this.extra,
  });

  @override
  Widget build(BuildContext context) {
    return _SupportCard(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontFamily: 'Oswald',
            color: AppColors.orange,
            fontSize: 18,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(height: 10),
        for (int index = 0; index < paragraphs.length; index++) ...[
          _SupportParagraph(paragraphs[index]),
          if (index < paragraphs.length - 1)
            const SizedBox(height: 12),
        ],
        if (extra != null) ...[
          const SizedBox(height: 14),
          extra!,
        ],
      ],
    );
  }
}

class _SupportCard extends StatelessWidget {
  final List<Widget> children;

  const _SupportCard({
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 17, 18, 17),
      decoration: BoxDecoration(
        color: AppColors.panel,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.border,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}

class _SupportParagraph extends StatelessWidget {
  final String text;

  const _SupportParagraph(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontFamily: 'Inter',
        color: AppColors.white,
        fontSize: 14.5,
        fontWeight: FontWeight.w400,
        height: 1.55,
      ),
    );
  }
}

class _EmailCard extends StatelessWidget {
  final String email;
  final VoidCallback onCopy;

  const _EmailCard({
    required this.email,
    required this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.orange,
          width: 1.1,
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.email_outlined,
            color: AppColors.orange,
            size: 22,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: SelectableText(
              email,
              style: const TextStyle(
                fontFamily: 'Inter',
                color: AppColors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Copy email',
            onPressed: onCopy,
            icon: const Icon(
              Icons.copy_rounded,
              color: AppColors.orange,
              size: 21,
            ),
          ),
        ],
      ),
    );
  }
}

class _SupportLinkTile extends StatelessWidget {
  final String title;
  final VoidCallback onTap;

  const _SupportLinkTile({
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.background,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 13,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: AppColors.orange,
              width: 1.1,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Oswald',
                    color: AppColors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.orange,
                size: 25,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
