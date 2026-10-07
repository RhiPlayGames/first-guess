import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../widgets/app_home_button.dart';

class AboutFirstGuessScreen extends StatelessWidget {
  const AboutFirstGuessScreen({super.key});

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
          'ABOUT FIRST GUESS',
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
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
          children: [
            Center(
              child: Container(
                width: 88,
                height: 88,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.panel,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: AppColors.orange,
                    width: 1.4,
                  ),
                ),
                child: const Icon(
                  Icons.info_outline_rounded,
                  color: AppColors.orange,
                  size: 48,
                ),
              ),
            ),
            const SizedBox(height: 22),
            const Text(
              'FIRST GUESS',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Oswald',
                color: AppColors.white,
                fontSize: 30,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Can you get it right first time?',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Inter',
                color: AppColors.orange,
                fontSize: 16,
                fontWeight: FontWeight.w600,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 26),
            Container(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
              decoration: BoxDecoration(
                color: AppColors.panel,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.border,
                  width: 1,
                ),
              ),
              child: const Text(
                'First Guess is a clue-based quiz game that rewards you for '
                'solving answers as early as possible.\n\n'
                'Each challenge gives you up to 10 clues, starting difficult '
                'and getting easier as you go. The fewer clues you need, the '
                'more points you score.\n\n'
                'Test your knowledge across a wide range of categories, build '
                'your score, collect achievements and see how far you can '
                'progress.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Inter',
                  color: AppColors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                  height: 1.55,
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Created by RhiPlay Games',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Oswald',
                color: AppColors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '© 2026 RhiPlay Games. All rights reserved.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Inter',
                color: AppColors.white,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
