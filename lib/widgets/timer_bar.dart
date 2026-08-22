import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class TimerBar extends StatelessWidget {
  final double progress;

  const TimerBar({
    super.key,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    final double safeProgress = progress.clamp(0.0, 1.0);
    final bool isRunningLow = safeProgress <= 0.3;

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(end: safeProgress),
      duration: const Duration(milliseconds: 100),
      builder: (context, value, child) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: isRunningLow
                ? const [
                    BoxShadow(
                      color: Color(0x55FE5E02),
                      blurRadius: 12,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              value: value,
              minHeight: 12,
              backgroundColor: AppColors.border,
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.orange,
              ),
            ),
          ),
        );
      },
    );
  }
}