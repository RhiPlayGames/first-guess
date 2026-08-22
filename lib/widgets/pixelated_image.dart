import 'package:flutter/material.dart';

class PixelatedImage extends StatelessWidget {
  final String imagePath;
  final int clueIndex;
  final double width;
  final double height;

  const PixelatedImage({
    super.key,
    required this.imagePath,
    required this.clueIndex,
    this.width = 240,
    this.height = 240,
  });

  static const List<int> _resolutionLevels = [
    32,
    40,
    52,
    68,
    88,
    116,
    150,
    200,
    280,
    512,
  ];

  @override
  Widget build(BuildContext context) {
    final int safeIndex = clueIndex
        .clamp(
          0,
          _resolutionLevels.length - 1,
        )
        .toInt();

    final int resolution =
        _resolutionLevels[safeIndex];

    final bool isFinalClue =
        safeIndex == _resolutionLevels.length - 1;

    final Uri? uri = Uri.tryParse(imagePath);
    final bool isNetworkImage =
        uri != null &&
        (uri.scheme == 'http' || uri.scheme == 'https');

    final ImageProvider<Object> baseImageProvider =
        isNetworkImage
            ? NetworkImage(imagePath)
            : AssetImage(imagePath);

    final ImageProvider<Object> imageProvider =
        isFinalClue
            ? baseImageProvider
            : ResizeImage(
                baseImageProvider,
                width: resolution,
              );

    return AnimatedSwitcher(
      duration: const Duration(
        milliseconds: 350,
      ),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (
        Widget child,
        Animation<double> animation,
      ) {
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(
              begin: 0.97,
              end: 1,
            ).animate(animation),
            child: child,
          ),
        );
      },
      child: SizedBox(
        key: ValueKey(
          '$imagePath-$safeIndex',
        ),
        width: width,
        height: height,
        child: Image(
          image: imageProvider,
          fit: BoxFit.contain,
          filterQuality: isFinalClue
              ? FilterQuality.high
              : FilterQuality.none,
          isAntiAlias: isFinalClue,
          gaplessPlayback: true,
          frameBuilder: (
            BuildContext context,
            Widget child,
            int? frame,
            bool wasSynchronouslyLoaded,
          ) {
            if (wasSynchronouslyLoaded ||
                frame != null) {
              return child;
            }

            return const Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                ),
              ),
            );
          },
          errorBuilder: (
            BuildContext context,
            Object error,
            StackTrace? stackTrace,
          ) {
            return const Center(
              child: Icon(
                Icons.image_not_supported_outlined,
                size: 42,
              ),
            );
          },
        ),
      ),
    );
  }
}