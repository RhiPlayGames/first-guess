import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class ClueProgress extends StatelessWidget {
  final int currentClueIndex;
  final int clueCount;

  const ClueProgress({
    super.key,
    required this.currentClueIndex,
    required this.clueCount,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 34,
      child: Column(
        children: List.generate(clueCount, (index) {
          final bool isCurrent = index == currentClueIndex;
          final bool isPassed = index < currentClueIndex;

          return Padding(
            padding: const EdgeInsets.only(bottom: 11),
            child: Container(
              width: isCurrent ? 34 : 16,
              height: isCurrent ? 34 : 16,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isCurrent || isPassed
                    ? AppColors.orange
                    : AppColors.darkGrey,
              ),
              child: isCurrent
                  ? Text(
                      '${index + 1}',
                      style: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.w900,
                      ),
                    )
                  : null,
            ),
          );
        }),
      ),
    );
  }
}