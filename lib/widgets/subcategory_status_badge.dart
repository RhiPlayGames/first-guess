import 'package:flutter/material.dart';

import '../theme/app_text_styles.dart';

class SubcategoryStatusBadge extends StatelessWidget {
  const SubcategoryStatusBadge({
    super.key,
    required this.text,
    required this.color,
    this.filled = false,
    this.compact = false,
  });

  final String text;
  final Color color;
  final bool filled;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final bool isDesktop = MediaQuery.sizeOf(context).width >= 1200;

    // Desktop/web: match the homepage CTA exactly.
    if (isDesktop) {
      return Container(
        width: 118,
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: filled ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color,
            width: 1.2,
          ),
        ),
        child: Text(
          text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: AppTextStyles.label.copyWith(
            color: filled ? Colors.white : color,
            fontSize: text == 'NEW QUESTIONS' ? 10 : 12.5,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.1,
          ),
        ),
      );
    }

    // App/mobile: preserve the existing subcategory CTA styling.
    return Container(
      constraints: BoxConstraints(
        minWidth: compact ? 96 : 112,
        maxWidth: compact ? 130 : 150,
      ),
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 10 : 14,
        vertical: compact ? 8 : 10,
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
          fontSize: compact ? 11 : 12,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.15,
          height: 1.05,
        ),
      ),
    );
  }
}
