import 'dart:async';

import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../services/daily_flash_schedule_service.dart';

String _formatDailyFlashNumber(int value) {
  final String digits = value.abs().toString();
  final StringBuffer buffer = StringBuffer();

  for (int i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) {
      buffer.write(',');
    }
    buffer.write(digits[i]);
  }

  return value < 0 ? '-$buffer' : buffer.toString();
}

class DailyFlashResultsDialog extends StatefulWidget {
  final bool perfect;
  final int score;
  final int baseXp;
  final int bonusXp;
  final int totalXp;
  final bool hasMilestone;
  final VoidCallback onContinue;

  const DailyFlashResultsDialog({
    super.key,
    required this.perfect,
    required this.score,
    required this.baseXp,
    required this.bonusXp,
    required this.totalXp,
    required this.hasMilestone,
    required this.onContinue,
  });

  @override
  State<DailyFlashResultsDialog> createState() =>
      _DailyFlashResultsDialogState();
}

class _DailyFlashResultsDialogState
    extends State<DailyFlashResultsDialog> {
  Timer? _countdownTimer;
  Duration _remaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    _updateCountdown();
    _countdownTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _updateCountdown(),
    );
  }

  void _updateCountdown() {
    final Duration remaining =
        DailyFlashScheduleService.timeUntilNextRelease();

    if (mounted) {
      setState(() => _remaining = remaining);
    }
  }

  String _two(int value) => value.toString().padLeft(2, '0');

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final int hours = _remaining.inHours;
    final int minutes = _remaining.inMinutes.remainder(60);
    final int seconds = _remaining.inSeconds.remainder(60);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 18,
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 430),
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
          decoration: BoxDecoration(
            color: AppColors.panel,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: AppColors.orange,
              width: 2,
            ),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: AppColors.orange.withValues(alpha: 0.22),
                blurRadius: 22,
                spreadRadius: 2,
              ),
            ],
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                SizedBox(
                  width: 96,
                  height: 96,
                  child: Image.asset(
                    'assets/images/ui/popups/daily_flash.webp',
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.high,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.orange,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'DAILY FLASH 5',
                    style: TextStyle(
                      fontFamily: 'Oswald',
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  widget.perfect ? 'PERFECT!' : 'FLASH COMPLETE!',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'Oswald',
                    color: Colors.white,
                    fontSize: 34,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 2),
                Text.rich(
                  TextSpan(
                    children: <InlineSpan>[
                      TextSpan(text: '${widget.score}'),
                      const TextSpan(
                        text: ' / ',
                        style: TextStyle(color: AppColors.orange),
                      ),
                      const TextSpan(text: '5'),
                    ],
                  ),
                  style: const TextStyle(
                    fontFamily: 'Oswald',
                    color: Colors.white,
                    fontSize: 42,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Column(
                    children: <Widget>[
                      _DailyFlashXpRow(
                        icon: Icons.star_rounded,
                        label: 'XP EARNED',
                        value:
                            '${_formatDailyFlashNumber(widget.baseXp)} XP',
                      ),
                      const Divider(
                        color: Colors.white24,
                        height: 18,
                      ),
                      _DailyFlashXpRow(
                        badge: '2×',
                        label: 'DAILY FLASH BONUS',
                        value:
                            '+${_formatDailyFlashNumber(widget.bonusXp)} XP',
                        highlight: true,
                      ),
                      const Divider(
                        color: Colors.white24,
                        height: 18,
                      ),
                      _DailyFlashXpRow(
                        icon: Icons.emoji_events_rounded,
                        label: 'TOTAL XP EARNED',
                        value:
                            '${_formatDailyFlashNumber(widget.totalXp)} XP',
                        highlight: true,
                        large: true,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'NEXT DAILY FLASH 5 IN',
                  style: TextStyle(
                    fontFamily: 'Oswald',
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.7,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '${_two(hours)} : ${_two(minutes)} : ${_two(seconds)}',
                  style: const TextStyle(
                    fontFamily: 'Oswald',
                    color: AppColors.orange,
                    fontSize: 31,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.5,
                  ),
                ),
                const Text(
                  'HRS          MINS          SECS',
                  style: TextStyle(
                    fontFamily: 'Oswald',
                    color: Colors.white54,
                    fontSize: 10,
                    letterSpacing: 0.7,
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton.icon(
                    onPressed: widget.onContinue,
                    icon: Icon(
                      widget.hasMilestone
                          ? Icons.arrow_forward_rounded
                          : Icons.home_rounded,
                    ),
                    label: Text(
                      widget.hasMilestone
                          ? 'CONTINUE'
                          : 'BACK TO HOME',
                      style: const TextStyle(
                        fontFamily: 'Oswald',
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.6,
                      ),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.orange,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
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
  }
}

class _DailyFlashXpRow extends StatelessWidget {
  final IconData? icon;
  final String? badge;
  final String label;
  final String value;
  final bool highlight;
  final bool large;

  const _DailyFlashXpRow({
    this.icon,
    this.badge,
    required this.label,
    required this.value,
    this.highlight = false,
    this.large = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        SizedBox(
          width: 38,
          child: badge != null
              ? Container(
                  width: 34,
                  height: 34,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.orange,
                      width: 2,
                    ),
                  ),
                  child: Text(
                    badge!,
                    style: const TextStyle(
                      fontFamily: 'Oswald',
                      color: AppColors.orange,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                )
              : Icon(
                  icon,
                  color: AppColors.orange,
                  size: 30,
                ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontFamily: 'Oswald',
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'Oswald',
            color: highlight ? AppColors.orange : Colors.white,
            fontSize: large ? 22 : 17,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
