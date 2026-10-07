import 'package:flutter/foundation.dart';
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
  final bool showWebBorder;

  const StatsPanel({
    super.key,
    required this.totalScore,
    required this.currentStreak,
    required this.firstGuesses,
    required this.gamesPlayed,
    this.showWebBorder = true,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDesktopWeb =
        kIsWeb && MediaQuery.sizeOf(context).width >= 1200;

    if (isDesktopWeb) {
      return Row(
        children: [
          Expanded(
            child: _StatBadge(
              imagePath: 'assets/images/stats/stat_score.png',
              value: _formatNumber(totalScore),
              semanticsLabel: 'Score',
              isWebCard: true,
              showWebBorder: showWebBorder,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _StatBadge(
              imagePath: 'assets/images/stats/stat_streak.png',
              value: _formatNumber(currentStreak),
              semanticsLabel: 'Streak',
              isWebCard: true,
              showWebBorder: showWebBorder,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _StatBadge(
              imagePath: 'assets/images/stats/stat_first_guess.png',
              value: _formatNumber(firstGuesses),
              semanticsLabel: 'First guesses',
              isWebCard: true,
              showWebBorder: showWebBorder,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _StatBadge(
              imagePath: 'assets/images/stats/stat_played.png',
              value: _formatNumber(gamesPlayed),
              semanticsLabel: 'Games played',
              isWebCard: true,
              showWebBorder: showWebBorder,
            ),
          ),
        ],
      );
    }

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
  final bool isWebCard;
  final bool showWebBorder;

  const _StatBadge({
    required this.imagePath,
    required this.value,
    required this.semanticsLabel,
    this.isWebCard = false,
    this.showWebBorder = true,
  });

  @override
  Widget build(BuildContext context) {
    if (isWebCard) {
      return Semantics(
        label: '$semanticsLabel $value',
        child: Container(
          height: 64,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: const Color(0xFF111111),
            borderRadius: BorderRadius.circular(12),
            border: showWebBorder
                ? Border.all(
                    color: const Color(0xFFD96519),
                    width: 1.5,
                  )
                : null,
          ),
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 40,
                    height: 40,
                    child: Image.asset(
                      imagePath,
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.high,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '$value ${semanticsLabel.toUpperCase()}',
                    maxLines: 1,
                    style: const TextStyle(
                      fontFamily: 'Oswald',
                      color: AppColors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final double screenWidth = MediaQuery.sizeOf(context).width;
    final bool isDesktop = screenWidth >= 1200;

    final double badgeHeight = isDesktop ? 46 : 33;
    final double iconSize = isDesktop ? 42 : 31;
    final double gap = isDesktop ? 7 : 4;
    final double valueFontSize = isDesktop ? 17 : 13;

    return Semantics(
      label: '$semanticsLabel $value',
      child: SizedBox(
        height: badgeHeight,
        child: Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: iconSize,
                  height: iconSize,
                  child: Image.asset(
                    imagePath,
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.high,
                  ),
                ),
                SizedBox(width: gap),
                Text(
                  value,
                  maxLines: 1,
                  style: TextStyle(
                    fontFamily: 'Oswald',
                    color: AppColors.white,
                    fontSize: valueFontSize,
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
