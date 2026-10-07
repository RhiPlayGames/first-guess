import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../widgets/app_home_button.dart';
import 'support_screen.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  void _contactSupport(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => const SupportScreen(),
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
          'PRIVACY POLICY',
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
            const Text(
              'Last updated: 12 August 2026',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Inter',
                color: AppColors.orange,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 18),
            const _PolicyCard(
              children: [
                _PolicyParagraph(
                  'This Privacy Policy explains how RhiPlay handles '
                  'information in connection with the First Guess app and '
                  'the RhiPlay website.',
                ),
              ],
            ),
            const SizedBox(height: 14),
            const _PolicySection(
              title: 'INFORMATION WE COLLECT',
              paragraphs: [
                'The current pre-launch website does not intentionally ask '
                    'visitors to submit personal information through forms or '
                    'create website accounts. Technical information such as IP '
                    'address, browser type, device information and access logs '
                    'may be processed automatically by hosting and '
                    'infrastructure providers when you visit the website.',
                'First Guess is still in development. If account registration, '
                    'cloud saves, analytics, leaderboards, notifications, '
                    'purchases or other online features are enabled in the '
                    'production app, this policy will be updated before public '
                    'launch to describe the information collected and how it '
                    'is used.',
              ],
            ),
            const SizedBox(height: 14),
            const _PolicySection(
              title: 'HOW INFORMATION MAY BE USED',
              paragraphs: [
                'Information may be used to provide and operate RhiPlay '
                    'services, maintain security, diagnose technical problems, '
                    'improve performance, respond to support requests and '
                    'comply with legal obligations.',
              ],
            ),
            const SizedBox(height: 14),
            const _PolicySection(
              title: 'THIRD-PARTY SERVICES',
              paragraphs: [
                'RhiPlay may use third-party hosting, app-store, analytics, '
                    'authentication, database or infrastructure providers. '
                    'Those providers may process information according to '
                    'their own privacy terms. The final production privacy '
                    'disclosures will identify material services used by '
                    'First Guess.',
              ],
            ),
            const SizedBox(height: 14),
            const _PolicySection(
              title: 'DATA RETENTION',
              paragraphs: [
                'We aim to keep personal information only for as long as '
                    'necessary for the purpose for which it was collected, '
                    'unless a longer period is required for legal, security '
                    'or fraud-prevention reasons.',
              ],
            ),
            const SizedBox(height: 14),
            const _PolicySection(
              title: 'YOUR CHOICES AND RIGHTS',
              paragraphs: [
                'Depending on where you live, you may have rights relating to '
                    'your personal information, including rights to request '
                    'access, correction or deletion. Where First Guess offers '
                    'account creation, users will also be provided with a way '
                    'to request account deletion.',
              ],
            ),
            const SizedBox(height: 14),
            const _PolicySection(
              title: 'CHILDREN',
              paragraphs: [
                'First Guess is not intended to knowingly collect personal '
                    'information from children in a way that would require '
                    'parental consent without providing the appropriate '
                    'protections.',
              ],
            ),
            const SizedBox(height: 14),
            const _PolicySection(
              title: 'CHANGES TO THIS POLICY',
              paragraphs: [
                'We may update this policy as First Guess develops, including '
                    'when new features or service providers are introduced.',
              ],
            ),
            const SizedBox(height: 18),
            Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(18),
              child: InkWell(
                onTap: () => _contactSupport(context),
                borderRadius: BorderRadius.circular(18),
                child: Ink(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 15,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.panel,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: AppColors.orange,
                      width: 1.3,
                    ),
                  ),
                  child: const Row(
                    children: [
                      Expanded(
                        child: Text(
                          'CONTACT SUPPORT',
                          textAlign: TextAlign.left,
                          style: TextStyle(
                            fontFamily: 'Oswald',
                            color: AppColors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: AppColors.orange,
                        size: 27,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PolicySection extends StatelessWidget {
  final String title;
  final List<String> paragraphs;

  const _PolicySection({
    required this.title,
    required this.paragraphs,
  });

  @override
  Widget build(BuildContext context) {
    return _PolicyCard(
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
          _PolicyParagraph(paragraphs[index]),
          if (index < paragraphs.length - 1)
            const SizedBox(height: 13),
        ],
      ],
    );
  }
}

class _PolicyCard extends StatelessWidget {
  final List<Widget> children;

  const _PolicyCard({
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

class _PolicyParagraph extends StatelessWidget {
  final String text;

  const _PolicyParagraph(this.text);

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
