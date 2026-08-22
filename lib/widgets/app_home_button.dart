import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

void goToFirstGuessHome(BuildContext context) {
  Navigator.of(context).popUntil((route) => route.isFirst);
}

class FirstGuessHomeButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String tooltip;

  const FirstGuessHomeButton({
    super.key,
    this.onPressed,
    this.tooltip = 'Home',
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 50,
      height: 50,
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Material(
          color: AppColors.panel,
          shape: CircleBorder(
            side: BorderSide(
              color: AppColors.orange.withValues(alpha: 0.9),
              width: 1.3,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onPressed ?? () => goToFirstGuessHome(context),
            child: const Tooltip(
              message: 'Home',
              child: Center(
                child: Icon(
                  Icons.home_outlined,
                  color: AppColors.white,
                  size: 23,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
