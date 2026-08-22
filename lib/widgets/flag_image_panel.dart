import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class FlagImagePanel extends StatelessWidget {
  final String imagePath;

  const FlagImagePanel({
    super.key,
    required this.imagePath,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 310,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.silhouetteBackground,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: AppColors.orange,
          width: 1.8,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x44FE5E02),
            blurRadius: 24,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(
            maxWidth: 320,
            maxHeight: 210,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            boxShadow: const [
              BoxShadow(
                color: Colors.black38,
                blurRadius: 14,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.asset(
              imagePath,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
              gaplessPlayback: true,
              errorBuilder: (
                BuildContext context,
                Object error,
                StackTrace? stackTrace,
              ) {
                return Container(
                  width: 280,
                  height: 180,
                  alignment: Alignment.center,
                  color: AppColors.panel,
                  child: const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.flag_outlined,
                        color: AppColors.orange,
                        size: 46,
                      ),
                      SizedBox(height: 10),
                      Text(
                        'FLAG IMAGE NOT FOUND',
                        style: TextStyle(
                          color: AppColors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}