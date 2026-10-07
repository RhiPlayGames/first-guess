import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/app_home_button.dart';

class DailyFlashGameHeader extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback onBack;
  final VoidCallback onHome;

  const DailyFlashGameHeader({
    super.key,
    required this.onBack,
    required this.onHome,
  });

  @override
  Size get preferredSize => const Size.fromHeight(62);

  @override
  Widget build(BuildContext context) {
    final bool isSmall = MediaQuery.sizeOf(context).width < 600;

    return Material(
      color: AppColors.background,
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: isSmall ? 53 : 62,
          child: Stack(
            alignment: Alignment.center,
            children: <Widget>[
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  tooltip: 'Back',
                  onPressed: onBack,
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                  icon: Icon(
                    Icons.arrow_back_rounded,
                    color: AppColors.white,
                    size: isSmall ? 28 : 32,
                  ),
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.only(right: 14),
                  child: FirstGuessHomeButton(
                    onPressed: onHome,
                  ),
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Icon(
                    Icons.bolt_rounded,
                    color: AppColors.orange,
                    size: isSmall ? 28 : 34,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    'DAILY FLASH 5',
                    maxLines: 1,
                    style: AppTextStyles.category.copyWith(
                      color: AppColors.white,
                      fontSize: isSmall ? 25 : 30,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.55,
                      height: 1,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Icon(
                    Icons.bolt_rounded,
                    color: AppColors.orange,
                    size: isSmall ? 28 : 34,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
