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
                  'Work out the answer from 10 clues, starting difficult and getting easier. You have 3 lives and can make one guess per clue — or skip if you are unsure.',
            ),
            SizedBox(height: 12),
            _RuleCard(
              title: 'FIRST WORD',
              text:
                  'Solve the hidden word across 5 clues. You have 3 guesses for the whole challenge, with more letters revealed as you progress.',
            ),
            SizedBox(height: 12),
            _RuleCard(
              title: 'FIRST CONNECTION',
              text:
                  'Six clues share one hidden connection. Work out what links them together and solve it in as few clues as possible.',
            ),
            SizedBox(height: 12),
            _RuleCard(
              title: 'FIRST DATE',
              text:
                  'Ten events point to one year or one month. Use the clues to work out the date they all have in common.',
            ),
            SizedBox(height: 12),
            _RuleCard(
              title: 'FIRST MATCH',
              text:
                  'Match 6 items with their correct partners. Submit your matches and try to complete the whole board before you run out of lives.',
            ),
            SizedBox(height: 12),
            _RuleCard(
              title: 'FIRST ORDER',
              text:
                  'Put 5 items into the correct order. Arrange them carefully and solve the sequence in as few attempts as possible.',
            ),
            SizedBox(height: 12),
            _RuleCard(
              title: 'SCORING',
              text:
                  'The earlier you solve a challenge, the more XP you earn. Different games have their own scoring structure, with the highest rewards for getting it right first time.',
            ),
            SizedBox(height: 12),
            _HighlightCard(
              title: 'FIRST GUESS BONUS',
              text:
                  'Solve a challenge on your first attempt to earn extra XP. In Classic First Guess, getting Clue 1 correct earns 100 XP plus a 50 XP First Guess bonus.',
            ),
            SizedBox(height: 12),
            _RuleCard(
              title: 'NO TIMER',
              text:
                  'All games, including Daily Flash 5, are not timed, so you can think before you answer.',
            ),
            SizedBox(height: 12),
            _HighlightCard(
              title: 'DAILY FLASH 5',
              text:
                  'Choose from the five live games and take on 5 new questions every day. Daily Flash 5 awards 2× XP.',
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
            'Six different games. Each one tests you in a different way. Solve the challenge as early as you can to earn the most points.',
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
