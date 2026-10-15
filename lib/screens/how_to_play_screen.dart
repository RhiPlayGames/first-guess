import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class HowToPlayScreen extends StatelessWidget {
  const HowToPlayScreen({super.key});

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
          'HOW TO PLAY',
          style: TextStyle(
            fontFamily: 'Oswald',
            fontWeight: FontWeight.w600,
            letterSpacing: 0.6,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 30),
          children: const [
            _IntroCard(),
            SizedBox(height: 14),
            _RuleCard(
              title: 'CLASSIC FIRST GUESS',
              text:
                  'Can you crack the answer before the clues give it away? Work your way through ten clues, from tricky to easy. You have three lives, one guess per clue, and the option to skip if you are unsure.\n\n'
                  'SCORING: Earn 100 XP for solving on Clue One, dropping by 10 XP with each new clue. Get it right on your very first guess at Clue One and bag an extra 50 XP First Guess bonus — that’s 150 XP!',
            ),
            SizedBox(height: 12),
            _RuleCard(
              title: 'FIRST WORD',
              text:
                  'Five clues. One mystery word. Can you solve it before the letters give it away? You have just three guesses across the entire challenge, with more letters revealed as you progress.\n\n'
                  'SCORING: Earn 100, 80, 60, 40 or 20 XP depending on which clue you solve it on. Crack the word with your first guess at Clue One and collect an extra 50 XP First Guess bonus — 150 XP in total!',
            ),
            SizedBox(height: 12),
            _RuleCard(
              title: 'FIRST DATE',
              text:
                  'Travel through time and connect the dots! Ten events all share one year or month. Study the clues and work out the date that links them together.\n\n'
                  'SCORING: Start with 100 XP on Clue One, losing 10 XP with each additional clue. Solve it on your first guess at Clue One for an extra 50 XP First Guess bonus — a maximum of 150 XP!',
            ),
            SizedBox(height: 12),
            _RuleCard(
              title: 'FIRST MATCH',
              text:
                  'Think you can find the perfect pairs? Match six items with their correct partners and submit your answers. Keep trying to complete the board before you run out of lives.\n\n'
                  'SCORING: Earn 100, 80, 60, 40 or 20 XP depending on which submission completes the board. Match all six pairs correctly on your first submission for an extra 50 XP First Guess bonus — 150 XP in total!',
            ),
            SizedBox(height: 12),
            _RuleCard(
              title: 'FIRST PICK',
              text:
                  'Six possible answers. Only one is right! Choose your answer carefully — you have three picks to find the correct one. Each incorrect pick brings you closer to running out of chances.\n\n'
                  'SCORING: Earn 50 XP for a correct first pick, 30 XP for your second or 20 XP for your third. Get it right on your very first pick and claim an extra 25 XP First Guess bonus — 75 XP in total!',
            ),
            SizedBox(height: 12),
            _RuleCard(
              title: 'FIRST ORDER',
              text:
                  'Does everything fall into place? Put five items in the correct order, using your knowledge and logic to work out the perfect sequence. Aim to get everything right in as few attempts as possible.\n\n'
                  'SCORING: Earn 100, 80, 60, 40 or 20 XP depending on which attempt you succeed on. Get the entire sequence correct on your first attempt for an extra 50 XP First Guess bonus — a maximum of 150 XP!',
            ),
            SizedBox(height: 12),
            _RuleCard(
              title: 'NO TIMER',
              text:
                  'Take your time and think it through! There’s no countdown, so you can focus on finding the right answer.',
            ),
            SizedBox(height: 12),
            _HighlightCard(
              title: 'DAILY FLASH 5',
              text:
                  'Five NEW questions each game, every day! Put your knowledge to the test and earn DOUBLE XP, including your First Guess bonuses.',
            ),
          ],
        ),
      ),
    );
  }
}

class _IntroCard extends StatelessWidget {
  const _IntroCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
      decoration: BoxDecoration(
        color: AppColors.panel,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.border,
          width: 1,
        ),
      ),
      child: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'CAN YOU GET IT RIGHT FIRST TIME?',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Oswald',
              color: AppColors.white,
              fontSize: 20,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Every game tests your knowledge in a different way. The earlier you solve the challenge, the more XP you’ll earn.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Inter',
              color: AppColors.white,
              fontSize: 14.5,
              fontWeight: FontWeight.w400,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _RuleCard extends StatelessWidget {
  final String title;
  final String text;

  const _RuleCard({
    required this.title,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return _BaseRuleCard(
      title: title,
      text: text,
      highlighted: false,
    );
  }
}

class _HighlightCard extends StatelessWidget {
  final String title;
  final String text;

  const _HighlightCard({
    required this.title,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return _BaseRuleCard(
      title: title,
      text: text,
      highlighted: true,
    );
  }
}

class _BaseRuleCard extends StatelessWidget {
  final String title;
  final String text;
  final bool highlighted;

  const _BaseRuleCard({
    required this.title,
    required this.text,
    required this.highlighted,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
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
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'Oswald',
              color: AppColors.white,
              fontSize: 17,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            text,
            style: const TextStyle(
              fontFamily: 'Inter',
              color: AppColors.white,
              fontSize: 14.5,
              fontWeight: FontWeight.w400,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
