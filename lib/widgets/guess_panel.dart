import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class GuessPanel extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool enabled;
  final bool isLastClue;
  final VoidCallback onGuess;
  final VoidCallback onNextClue;
  final VoidCallback onGiveUp;

  const GuessPanel({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.enabled,
    required this.isLastClue,
    required this.onGuess,
    required this.onNextClue,
    required this.onGiveUp,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 48,
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            enabled: enabled,
            onSubmitted: (_) {
              if (enabled) {
                onGuess();
              }
            },
            textCapitalization: TextCapitalization.words,
            textAlignVertical: TextAlignVertical.center,
            style: const TextStyle(
              fontFamily: 'Inter',
              color: AppColors.white,
              fontSize: 15,
              fontWeight: FontWeight.w400,
            ),
            decoration: const InputDecoration(
              hintText: 'Type your guess...',
              hintStyle: TextStyle(
                fontFamily: 'Inter',
                color: AppColors.white,
                fontSize: 15,
                fontWeight: FontWeight.w400,
              ),
              filled: true,
              fillColor: AppColors.background,
              isDense: true,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 15,
                vertical: 13,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(14)),
                borderSide: BorderSide(color: Color(0xFF444444), width: 1),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(14)),
                borderSide: BorderSide(color: AppColors.orange, width: 1.5),
              ),
              disabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(14)),
                borderSide: BorderSide(color: AppColors.darkGrey, width: 1),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 48,
                child: FilledButton(
                  onPressed: enabled ? onGuess : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.orange,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: AppColors.darkGrey,
                    disabledForegroundColor: const Color(0xFF8C8C8C),
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      'GUESS',
                      maxLines: 1,
                      style: TextStyle(
                        fontFamily: 'Oswald',
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: SizedBox(
                height: 48,
                child: OutlinedButton(
                  onPressed: enabled && !isLastClue ? onNextClue : null,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.orange,
                    disabledForegroundColor: AppColors.darkGrey,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    side: BorderSide(
                      color: enabled && !isLastClue
                          ? AppColors.orange
                          : AppColors.darkGrey,
                      width: 1.5,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      'NEXT CLUE',
                      maxLines: 1,
                      style: TextStyle(
                        fontFamily: 'Oswald',
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: FilledButton(
            onPressed: enabled ? onGiveUp : null,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFD32F2F),
              foregroundColor: AppColors.white,
              disabledBackgroundColor: AppColors.darkGrey,
              disabledForegroundColor: const Color(0xFF8C8C8C),
              padding: const EdgeInsets.symmetric(horizontal: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                'GIVE UP',
                maxLines: 1,
                style: TextStyle(
                  fontFamily: 'Oswald',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
