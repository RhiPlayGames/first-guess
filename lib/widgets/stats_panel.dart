import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

String _formatNumber(int value) {
  final String digits = value.abs().toString();
  final StringBuffer buffer = StringBuffer();

  for (int index = 0; index < digits.length; index++) {
    if (index > 0 && (digits.length - index) % 3 == 0) {
      buffer.write(',');
    }

    buffer.write(digits[index]);
  }

  return value < 0 ? '-${buffer.toString()}' : buffer.toString();
}

class StatsPanel extends StatelessWidget {
  final int totalScore;
  final int currentStreak;
  final int firstGuesses;
  final int gamesPlayed;

  const StatsPanel({
    super.key,
    required this.totalScore,
    required this.currentStreak,
    required this.firstGuesses,
    required this.gamesPlayed,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatBadge(
            imagePath: 'assets/images/stats/stat_score.png',
            value: _formatNumber(totalScore),
            semanticsLabel: 'Score',
          ),
        ),
        Expanded(
          child: _StatBadge(
            imagePath: 'assets/images/stats/stat_streak.png',
            value: _formatNumber(currentStreak),
            semanticsLabel: 'Streak',
          ),
        ),
        Expanded(
          child: _StatBadge(
            imagePath: 'assets/images/stats/stat_first_guess.png',
            value: _formatNumber(firstGuesses),
            semanticsLabel: 'First guesses',
          ),
        ),
        Expanded(
          child: _StatBadge(
            imagePath: 'assets/images/stats/stat_played.png',
            value: _formatNumber(gamesPlayed),
            semanticsLabel: 'Games played',
          ),
        ),
      ],
    );
  }
}

class _StatBadge extends StatelessWidget {
  final String imagePath;
  final String value;
  final String semanticsLabel;

  const _StatBadge({
    required this.imagePath,
    required this.value,
    required this.semanticsLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$semanticsLabel $value',
      child: SizedBox(
        height: 33,
        child: Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 31,
                  height: 31,
                  child: Image.asset(
                    imagePath,
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.high,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  value,
                  maxLines: 1,
                  style: const TextStyle(
                    fontFamily: 'Oswald',
                    color: AppColors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}