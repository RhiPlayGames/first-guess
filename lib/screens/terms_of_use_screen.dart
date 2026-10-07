import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../widgets/app_home_button.dart';
import 'support_screen.dart';

class TermsOfUseScreen extends StatelessWidget {
  const TermsOfUseScreen({super.key});

  void _openSupport(BuildContext context) {
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
          'TERMS OF USE',
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
            const _TermsCard(
              children: [
                _TermsParagraph(
                  'These Terms of Use apply to the RhiPlay website, the First '
                  'Guess game and related RhiPlay services.',
                ),
              ],
            ),
            const SizedBox(height: 14),
            const _TermsSection(
              title: 'USING RHIPLAY',
              paragraphs: [
                'You may use RhiPlay services for personal, lawful purposes. '
                    'You must not misuse the service, attempt to interfere '
                    'with its operation, gain unauthorised access, abuse other '
                    'users or use the service in a way that violates '
                    'applicable law.',
              ],
            ),
            const SizedBox(height: 14),
            const _TermsSection(
              title: 'FIRST GUESS',
              paragraphs: [
                'First Guess is a clue-driven knowledge game. Features, '
                    'scoring, categories, rewards and availability may change '
                    'as the game develops. We may add, modify or remove '
                    'features where reasonably necessary to improve or '
                    'operate the service.',
              ],
            ),
            const SizedBox(height: 14),
            const _TermsSection(
              title: 'ACCOUNTS',
              paragraphs: [
                'If accounts are introduced, you are responsible for keeping '
                    'your login details secure and for activity carried out '
                    'through your account. You should provide accurate '
                    'information and notify us if you believe your account '
                    'has been compromised.',
              ],
            ),
            const SizedBox(height: 14),
            const _TermsSection(
              title: 'INTELLECTUAL PROPERTY',
              paragraphs: [
                'RhiPlay, First Guess, the game design, branding, graphics, '
                    'text, software and other original content are owned by or '
                    'licensed to RhiPlay and are protected by applicable '
                    'intellectual-property laws. These Terms do not transfer '
                    'ownership of that material to users.',
              ],
            ),
            const SizedBox(height: 14),
            const _TermsSection(
              title: 'AVAILABILITY',
              paragraphs: [
                'We aim to provide a reliable service but cannot guarantee '
                    'that the website or game will always be available, '
                    'uninterrupted or error-free. Maintenance, updates or '
                    'circumstances outside our control may affect '
                    'availability.',
              ],
            ),
            const SizedBox(height: 14),
            const _TermsSection(
              title: 'LIABILITY',
              paragraphs: [
                'Nothing in these Terms excludes liability that cannot '
                    'legally be excluded. To the extent permitted by law, '
                    'RhiPlay is not responsible for indirect or consequential '
                    'losses arising from use of, or inability to use, the '
                    'service.',
              ],
            ),
            const SizedBox(height: 14),
            const _TermsSection(
              title: 'CHANGES',
              paragraphs: [
                'We may update these Terms as the service develops. The '
                    'latest version will be published on this page with its '
                    'revision date.',
              ],
            ),
            const SizedBox(height: 14),
            _TermsSection(
              title: 'CONTACT SUPPORT',
              paragraphs: const [
                'If you have any questions about these Terms of Use, contact '
                    'RhiPlay Support.',
              ],
              extra: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  onTap: () => _openSupport(context),
                  borderRadius: BorderRadius.circular(14),
                  child: Ink(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 13,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: AppColors.orange,
                        width: 1.1,
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
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                        Icon(
                          Icons.chevron_right_rounded,
                          color: AppColors.orange,
                          size: 25,
                        ),
                      ],
                    ),
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

class _TermsSection extends StatelessWidget {
  final String title;
  final List<String> paragraphs;
  final Widget? extra;

  const _TermsSection({
    required this.title,
    required this.paragraphs,
    this.extra,
  });

  @override
  Widget build(BuildContext context) {
    return _TermsCard(
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
          _TermsParagraph(paragraphs[index]),
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

class _TermsCard extends StatelessWidget {
  final List<Widget> children;

  const _TermsCard({
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

class _TermsParagraph extends StatelessWidget {
  final String text;

  const _TermsParagraph(this.text);

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
