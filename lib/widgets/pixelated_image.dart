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

  @override
  Widget build(BuildContext context) {
    final Uri? uri = Uri.tryParse(imagePath);
    final bool isNetworkImage =
        uri != null &&
        (uri.scheme == 'http' || uri.scheme == 'https');

    final ImageProvider<Object> imageProvider =
        isNetworkImage
            ? NetworkImage(imagePath)
            : AssetImage(imagePath);

    return SizedBox(
      width: width,
      height: height,
      child: Image(
        image: imageProvider,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
        isAntiAlias: true,
        gaplessPlayback: true,
        frameBuilder: (
          BuildContext context,
          Widget child,
          int? frame,
          bool wasSynchronouslyLoaded,
        ) {
          if (wasSynchronouslyLoaded || frame != null) {
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
    );
  }
}
