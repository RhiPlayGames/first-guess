import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'app_home_button.dart';

class ClassicCategoryHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback? onBack;
  final VoidCallback? onHome;

  const ClassicCategoryHeader({
    super.key,
    required this.title,
    this.subtitle = 'Choose a category to start playing',
    this.onBack,
    this.onHome,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
      child: Column(
        children: <Widget>[
          SizedBox(
            width: double.infinity,
            height: 74,
            child: Stack(
              alignment: Alignment.center,
              children: <Widget>[
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    tooltip: 'Back',
                    padding: EdgeInsets.zero,
                    icon: const Icon(
                      Icons.arrow_back_rounded,
                      color: AppColors.white,
                      size: 34,
                    ),
                    onPressed:
                        onBack ?? () => Navigator.of(context).maybePop(),
                  ),
                ),
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 70),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        title.toUpperCase(),
                        maxLines: 1,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.category.copyWith(
                          color: AppColors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.45,
                        ),
                      ),
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: FirstGuessHomeButton(
                    onPressed: onHome ??
                        () => Navigator.of(context).popUntil(
                              (Route<dynamic> route) => route.isFirst,
                            ),
                  ),
                ),
              ],
            ),
          ),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: AppTextStyles.body.copyWith(
              color: AppColors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
