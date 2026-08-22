import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class CluePanel extends StatelessWidget {
  final String clue;

  const CluePanel({
    super.key,
    required this.clue,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.04, 0),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        );
      },
      child: Container(
        key: ValueKey(clue),
        width: double.infinity,
        height: 54,
        padding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 7,
        ),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: const Color(0xFF444444),
            width: 1,
          ),
        ),
        alignment: Alignment.center,
        child: AutoSizeText(
          clue,
          textAlign: TextAlign.center,
          maxLines: 2,
          minFontSize: 12,
          stepGranularity: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.body.copyWith(
            color: AppColors.white,
            fontSize: 15,
            fontWeight: FontWeight.w500,
            height: 1.15,
          ),
        ),
      ),
    );
  }
}
