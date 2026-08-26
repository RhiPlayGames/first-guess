import 'package:flutter/material.dart';

import '../services/player_stats_service.dart';
import '../theme/app_colors.dart';

enum GameMessageType {
  info,
  success,
  warning,
  error,
}

Future<void> showGameResultDialog({
  required BuildContext context,
  required String title,
  required String message,
  IconData? icon,
  String? imageAsset,
  required VoidCallback onPlayAgain,
  required VoidCallback onHome,
  String? primaryButtonLabel,
  String? secondaryButtonLabel,
}) {
  final bool isGameOver = title == 'GAME OVER';
  final bool isCorrect = title == 'CORRECT!';
  final bool isFirstGuess = title == 'FIRST GUESS!';
  final bool useFeatureLayout =
      isGameOver || isCorrect || isFirstGuess;

  String gameOverAnswer = message;

  if (message.startsWith('The answer was ')) {
    gameOverAnswer = message.substring('The answer was '.length);

    while (gameOverAnswer.endsWith('.')) {
      gameOverAnswer = gameOverAnswer.substring(
        0,
        gameOverAnswer.length - 1,
      );
    }
  }

  final String mainButtonText =
      primaryButtonLabel ??
      (useFeatureLayout ? 'NEXT QUESTION' : 'NEXT CHALLENGE');

  final String secondButtonText =
      secondaryButtonLabel ?? 'HOME';

  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      return AlertDialog(
        backgroundColor: AppColors.panel,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: const BorderSide(
            color: AppColors.orange,
            width: 2,
          ),
        ),
        icon: useFeatureLayout
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    isGameOver
                        ? 'GAME OVER'
                        : isFirstGuess
                            ? 'FIRST GUESS!'
                            : 'CORRECT!',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'Oswald',
                      color: AppColors.orange,
                      fontSize: 32,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 1.4,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: isFirstGuess ? 120 : 96,
                    height: isFirstGuess ? 120 : 96,
                    child: Image.asset(
                      isGameOver
                          ? 'assets/images/stats/game_over.png'
                          : isFirstGuess
                              ? 'assets/images/stats/popup_first_guess.png'
                              : 'assets/images/stats/correct.png',
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.high,
                    ),
                  ),
                ],
              )
            : imageAsset != null
                ? SizedBox(
                    width: 96,
                    height: 96,
                    child: Image.asset(
                      imageAsset,
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.high,
                    ),
                  )
                : icon != null
                    ? Icon(
                        icon,
                        color: AppColors.orange,
                        size: 54,
                      )
                    : null,
        title: useFeatureLayout
            ? null
            : Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: title == 'YOU GAVE UP!'
                      ? AppColors.white
                      : AppColors.orange,
                  fontFamily: 'Oswald',
                  fontSize: 22,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.5,
                ),
              ),
        content: message.startsWith('The answer was ')
            ? Text.rich(
                TextSpan(
                  children: [
                    const TextSpan(
                      text: 'The answer was ',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        color: AppColors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    TextSpan(
                      text: gameOverAnswer.toUpperCase(),
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        color: AppColors.orange,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
              )
            : Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  color: AppColors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  height: 1.8,
                ),
              ),
        actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 22),
        actions: [
          SizedBox(
            width: double.infinity,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 210,
                  height: 50,
                  child: FilledButton(
                    onPressed: onPlayAgain,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.orange,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      mainButtonText,
                      style: const TextStyle(
                        fontSize: 15,
                        fontFamily: 'Oswald',
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.35,
                      ),
                    ),
                  ),
                ),
                if (useFeatureLayout ||
                    secondaryButtonLabel != null) ...[
                  const SizedBox(height: 8),
                  SizedBox(
                    width: 210,
                    height: 46,
                    child: OutlinedButton(
                      onPressed: onHome,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(
                          color: AppColors.orange,
                          width: 1.5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        secondButtonText,
                        style: const TextStyle(
                          fontSize: 15,
                          fontFamily: 'Oswald',
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.35,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      );
    },
  );
}


Future<bool?> showPracticeModeDialog({
  required BuildContext context,
  required String categoryLabel,
}) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      return AlertDialog(
        backgroundColor: AppColors.panel,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: const BorderSide(
            color: AppColors.orange,
            width: 2,
          ),
        ),
        icon: SizedBox(
          width: 96,
          height: 96,
          child: Image.asset(
            'assets/images/ui/popups/challenges_complete.webp',
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
          ),
        ),
        title: const Text(
          'ALL CURRENT CHALLENGES PLAYED!',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Oswald',
            color: AppColors.orange,
            fontSize: 24,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.5,
          ),
        ),
        content: const Text(
          'Great job — you’ve completed all the challenges currently available here.\n\n'
          'More challenges coming soon!\n\n'
          'You can keep playing in PRACTICE MODE, but replayed challenges '
          'won’t earn XP or affect your leaderboard position.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Inter',
            color: AppColors.white,
            fontSize: 15,
            fontWeight: FontWeight.w500,
            height: 1.55,
          ),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 22),
        actions: [
          SizedBox(
            width: double.infinity,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 210,
                  height: 50,
                  child: FilledButton(
                    onPressed: () =>
                        Navigator.of(dialogContext).pop(true),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.orange,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'CONTINUE PLAYING',
                      style: TextStyle(
                        fontSize: 15,
                        fontFamily: 'Oswald',
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.35,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: 210,
                  height: 46,
                  child: OutlinedButton(
                    onPressed: () =>
                        Navigator.of(dialogContext).pop(false),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(
                        color: AppColors.orange,
                        width: 1.5,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'BACK TO HOME',
                      style: TextStyle(
                        fontSize: 15,
                        fontFamily: 'Oswald',
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.35,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    },
  );
}



Future<void> showRankProgressDialog({
  required BuildContext context,
  required PlayerRankProgress previous,
  required PlayerRankProgress current,
  required int xpEarned,
}) {
  final bool isPromotion = current.isPromotionFrom(previous);

  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      return AlertDialog(
        backgroundColor: AppColors.panel,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: const BorderSide(
            color: AppColors.orange,
            width: 2,
          ),
        ),
        icon: isPromotion
            ? null
            : SizedBox(
                width: 96,
                height: 96,
                child: Image.asset(
                  'assets/images/stats/level_up.png',
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.high,
                ),
              ),
        title: Text(
          isPromotion ? 'PROMOTION!' : 'LEVEL UP!',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.orange,
            fontWeight: FontWeight.w900,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'assets/images/stats/puzzle_piece.png',
                  width: 24,
                  height: 24,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.high,
                ),
                const SizedBox(width: 7),
                Text(
                  previous.fullTitle,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Icon(
                Icons.arrow_downward_rounded,
                color: AppColors.orange,
                size: 28,
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'assets/images/stats/puzzle_piece.png',
                  width: 32,
                  height: 32,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.high,
                ),
                const SizedBox(width: 8),
                Text(
                  current.fullTitle,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '+$xpEarned XP',
              style: const TextStyle(
                color: AppColors.orange,
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.orange,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text(
              'CONTINUE',
              style: TextStyle(
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      );
    },
  );
}

class SmallTimeUpOverlay extends StatelessWidget {
  const SmallTimeUpOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 210,
      padding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 16,
      ),
      decoration: BoxDecoration(
        color: AppColors.panel,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.orange,
          width: 2,
        ),
        boxShadow: const [
          BoxShadow(
            color: Colors.black54,
            blurRadius: 18,
            spreadRadius: 4,
          ),
        ],
      ),
      child: Image.asset(
        'assets/images/stats/times_up.png',
        width: 170,
        height: 170,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
      ),
    );
  }
}

class GameMessagePanel extends StatelessWidget {
  final String message;
  final GameMessageType type;

  const GameMessagePanel({
    super.key,
    required this.message,
    this.type = GameMessageType.info,
  });

  Color get _messageColor {
    switch (type) {
      case GameMessageType.info:
        return AppColors.orange;
      case GameMessageType.success:
        return const Color(0xFF35C46A);
      case GameMessageType.warning:
        return AppColors.orange;
      case GameMessageType.error:
        return const Color(0xFFE84C4C);
    }
  }

  IconData get _messageIcon {
    switch (type) {
      case GameMessageType.info:
        return Icons.info_outline;
      case GameMessageType.success:
        return Icons.check_circle_outline_rounded;
      case GameMessageType.warning:
        return Icons.warning_amber_rounded;
      case GameMessageType.error:
        return Icons.cancel_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color messageColor = _messageColor;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 14,
      ),
      decoration: BoxDecoration(
        color: AppColors.panel,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: messageColor,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: messageColor.withValues(alpha: 0.18),
            blurRadius: 12,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            _messageIcon,
            color: messageColor,
            size: 27,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: messageColor,
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
