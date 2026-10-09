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
  final bool isFinalCaseComplete =
      title == 'AROUND THE WORLD COMPLETE!' ||
      title == 'ANIMAL KINGDOM COMPLETE!' ||
      title == 'SECRETS OF THE PAST COMPLETE!' ||
      title == 'A TASTE OF MYSTERY COMPLETE!';

  final bool isGameOver = title == 'GAME OVER';
  final bool isCorrect = title == 'CORRECT!';
  final bool isFirstGuess = title == 'FIRST GUESS!';
  final bool isCaseComplete =
      title.startsWith('CASE ') && title.endsWith(' COMPLETE!');
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
                    width: isFinalCaseComplete ? 150 : 96,
                    height: isFinalCaseComplete ? 150 : 96,
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
            : isCaseComplete
                ? Builder(
                    builder: (context) {
                      final List<String> lines =
                          message.split('\n');
                      final String identifiedLabel =
                          lines.isNotEmpty
                              ? lines.first
                              : 'You\'ve correctly identified:';
                      final String answer =
                          lines.length > 1 ? lines[1] : '';
                      final String unlocked =
                          lines.length > 2 ? lines[2] : '';

                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            identifiedLabel,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontFamily: 'Oswald',
                              color: AppColors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.5,
                              height: 1.0,
                            ),
                          ),
                          const SizedBox(height: 7),
                          Text(
                            answer,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontFamily: 'Oswald',
                              color: AppColors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.5,
                              height: 1.0,
                            ),
                          ),
                          if (unlocked.isNotEmpty) ...[
                            const SizedBox(height: 14),
                            Text(
                              unlocked,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontFamily: 'Oswald',
                                color: Color(0xFF63D44A),
                                fontSize: 22,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 0.5,
                                height: 1.0,
                              ),
                            ),
                          ],
                        ],
                      );
                    },
                  )
                : Text(
                    message,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Oswald',
                      color: AppColors.white,
                      fontSize: isFinalCaseComplete ? 20 : 18,
                      fontWeight: FontWeight.w500,
                      height: 1.35,
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
      final double screenWidth =
          MediaQuery.sizeOf(dialogContext).width;
      final double dialogWidth =
          screenWidth < 460 ? screenWidth - 32 : 400;

      return AlertDialog(
        insetPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 24,
        ),
        constraints: BoxConstraints.tightFor(
          width: dialogWidth,
        ),
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




const Color _rankProgressOrange = Color(0xFFFE5E02);
const Color _rankProgressGold = Color(0xFFD6A83B);
const Color _rankProgressBrightGold = Color(0xFFFFD65A);

String _formatRankXp(int value) {
  final String digits = value.abs().toString();
  final StringBuffer buffer = StringBuffer();

  for (int index = 0; index < digits.length; index++) {
    if (index > 0 && (digits.length - index) % 3 == 0) {
      buffer.write(',');
    }
    buffer.write(digits[index]);
  }

  return value < 0 ? '-$buffer' : buffer.toString();
}

TextStyle _rankProgressTextStyle({
  required double size,
  Color color = Colors.white,
  double letterSpacing = 0,
  FontWeight fontWeight = FontWeight.w600,
  double height = 1.05,
}) {
  return TextStyle(
    fontFamily: 'Oswald',
    fontSize: size,
    fontWeight: fontWeight,
    color: color,
    letterSpacing: letterSpacing,
    height: height,
  );
}

Widget _rankProgressInfoCard({
  required String assetPath,
  required String title,
  required String value,
  String? detail,
}) {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(
      horizontal: 14,
      vertical: 12,
    ),
    decoration: BoxDecoration(
      color: Colors.black.withValues(alpha: 0.18),
      borderRadius: BorderRadius.circular(15),
      border: Border.all(
        color: Colors.white24,
      ),
    ),
    child: Row(
      children: <Widget>[
        SizedBox(
          width: 46,
          height: 46,
          child: Image.asset(
            assetPath,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                title,
                style: _rankProgressTextStyle(
                  size: 14,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: _rankProgressTextStyle(
                  size: 18,
                  color: _rankProgressOrange,
                  letterSpacing: 0.3,
                ),
              ),
              if (detail != null) ...<Widget>[
                const SizedBox(height: 2),
                Text(
                  detail,
                  style: _rankProgressTextStyle(
                    size: 14,
                    color: Colors.white,
                    letterSpacing: 0.2,
                    fontWeight: FontWeight.w500,
                    height: 1.2,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    ),
  );
}

Future<void> showRankProgressDialog({
  required BuildContext context,
  required PlayerRankProgress previous,
  required PlayerRankProgress current,
  required int xpEarned,
}) {
  final bool isPromotion =
      current.isPromotionFrom(previous);

  final bool isMaximumLevel = current.isMaximumLevel;

  final String nextLevelName = isMaximumLevel
      ? 'MAX LEVEL'
      : current.nextFullTitle;

  final String nextLevelDetail = isMaximumLevel
      ? 'YOU REACHED THE HIGHEST LEVEL'
      : '${_formatRankXp(current.nextLevelStartXp)} TOTAL XP NEEDED';

  final bool earnedStarterBadge =
      previous.isBeforeFirstMilestone &&
      !current.isBeforeFirstMilestone;

  final String imageAsset;
  if (earnedStarterBadge) {
    imageAsset = 'assets/images/badges/clue_starter.webp';
  } else if (isPromotion) {
    if (current.tierName == 'Advanced Tier') {
      imageAsset = 'assets/images/badges/clue_advanced.webp';
    } else if (current.tierName == 'Expert Tier') {
      imageAsset = 'assets/images/badges/clue_expert.webp';
    } else if (current.tierName == 'Master Tier') {
      imageAsset = 'assets/images/badges/clue_master.webp';
    } else if (current.tierName == 'Elite Tier') {
      imageAsset = 'assets/images/badges/clue_elite.webp';
    } else {
      imageAsset = 'assets/images/ui/popups/levelup_crown.webp';
    }
  } else {
    imageAsset = 'assets/images/ui/popups/levelup_star.webp';
  }

  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black54,
    builder: (dialogContext) {
      final Size screenSize = MediaQuery.sizeOf(dialogContext);
      final double maxDialogHeight = screenSize.height * 0.90;

      return Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 18,
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 410,
            maxHeight: maxDialogHeight,
          ),
          child: Container(
            padding: const EdgeInsets.fromLTRB(
              18,
              16,
              18,
              18,
            ),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: <Color>[
                  Color(0xFF11100C),
                  Color(0xFF090909),
                ],
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: _rankProgressBrightGold,
                width: 2,
              ),
              boxShadow: const <BoxShadow>[
                BoxShadow(
                  color: Color(0x554D3707),
                  blurRadius: 24,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Stack(
                    alignment: Alignment.center,
                    children: <Widget>[
                      const SizedBox(
                        width: double.infinity,
                        height: 74,
                      ),
                      SizedBox(
                        width: earnedStarterBadge || isPromotion ? 74 : 64,
                        height: earnedStarterBadge || isPromotion ? 74 : 64,
                        child: Image.asset(
                          imageAsset,
                          fit: BoxFit.contain,
                          filterQuality: FilterQuality.high,
                        ),
                      ),
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Material(
                          color: AppColors.orange,
                          shape: const CircleBorder(),
                          child: InkWell(
                            onTap: () {
                              Navigator.of(dialogContext).pop();
                            },
                            customBorder: const CircleBorder(),
                            child: const SizedBox(
                              width: 44,
                              height: 44,
                              child: Icon(
                                Icons.close_rounded,
                                color: Colors.white,
                                size: 29,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isPromotion ? 'PROMOTION!' : 'LEVEL UP!',
                    textAlign: TextAlign.center,
                    style: _rankProgressTextStyle(
                      size: 27,
                      color: _rankProgressBrightGold,
                      letterSpacing: 0.7,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (isPromotion) ...<Widget>[
                    const SizedBox(height: 4),
                    Text(
                      'NEW TIER UNLOCKED',
                      textAlign: TextAlign.center,
                      style: _rankProgressTextStyle(
                        size: 16,
                        color: Colors.white,
                        letterSpacing: 0.35,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                  const SizedBox(height: 14),
                  Container(
                    width: 260,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.30),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _rankProgressGold,
                        width: 1.6,
                      ),
                      boxShadow: const <BoxShadow>[
                        BoxShadow(
                          color: Color(0x334F3907),
                          blurRadius: 14,
                        ),
                      ],
                    ),
                    child: Column(
                      children: <Widget>[
                        Text(
                          isPromotion
                              ? current.tierName
                              : current.fullTitle,
                          textAlign: TextAlign.center,
                          style: _rankProgressTextStyle(
                            size: 27,
                            color: _rankProgressBrightGold,
                            letterSpacing: 0.25,
                            fontWeight: FontWeight.w700,
                            height: 1.1,
                          ),
                        ),
                        if (isPromotion) ...<Widget>[
                          const SizedBox(height: 5),
                          Text(
                            current.fullTitle,
                            textAlign: TextAlign.center,
                            style: _rankProgressTextStyle(
                              size: 17,
                              color: Colors.white,
                              letterSpacing: 0.2,
                              fontWeight: FontWeight.w500,
                              height: 1.15,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  _rankProgressInfoCard(
                    assetPath: 'assets/images/stats/gold_lightning_bolt_badge.png',
                    title: 'BONUS',
                    value: '+${_formatRankXp(xpEarned)} XP',
                  ),
                  const SizedBox(height: 10),
                  _rankProgressInfoCard(
                    assetPath: 'assets/images/stats/level_up.png',
                    title: isMaximumLevel ? 'ACHIEVEMENT' : 'NEXT LEVEL',
                    value: nextLevelName,
                    detail: nextLevelDetail,
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: SizedBox(
                      width: 290,
                      height: 52,
                      child: FilledButton(
                        onPressed: () {
                          Navigator.of(dialogContext).pop();
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.orange,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          'CONTINUE',
                          style: _rankProgressTextStyle(
                            size: 18,
                            color: Colors.white,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
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
                fontFamily: 'Inter',
                color: messageColor,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
