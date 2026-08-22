import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'pixelated_image.dart';

class SilhouettePanel extends StatelessWidget {
  final String imagePath;
  final int clueIndex;

  const SilhouettePanel({
    super.key,
    required this.imagePath,
    required this.clueIndex,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (
        BuildContext context,
        BoxConstraints constraints,
      ) {
        final double imageSize =
            constraints.biggest.shortestSide * 0.90;

        return Container(
          width: double.infinity,
          height: double.infinity,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.silhouetteBackground,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: AppColors.orange,
              width: 1.3,
            ),
          ),
          child: Center(
            child: PixelatedImage(
              imagePath: imagePath,
              clueIndex: clueIndex,
              width: imageSize,
              height: imageSize,
            ),
          ),
        );
      },
    );
  }
}