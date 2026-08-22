import 'package:flutter/material.dart';

import '../theme/app_text_styles.dart';

class SubcategoryStatusBadge extends StatelessWidget {
  const SubcategoryStatusBadge({
    super.key,
    required this.text,
    required this.color,
    this.filled = false,
  });

  final String text;
  final Color color;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(
        minWidth: 112,
        maxWidth: 150,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: filled
            ? color
            : color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color,
          width: 1,
        ),
      ),
      child: Text(
        text,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
        style: AppTextStyles.label.copyWith(
          color: filled ? Colors.white : color,
          fontSize: 12,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.15,
          height: 1.05,
        ),
      ),
    );
  }
}