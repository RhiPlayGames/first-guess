import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

enum RevealEffect {
  pixelate,
  blur,
  none,
}

class RevealImagePanel extends StatelessWidget {
  final String imagePath;
  final int clueIndex;
  final RevealEffect effect;
  final double height;
  final BoxFit fit;
  final bool showShadow;
  final double imageScale;

  const RevealImagePanel({
    super.key,
    required this.imagePath,
    required this.clueIndex,
    required this.effect,
    this.height = 310,
    this.fit = BoxFit.contain,
    this.showShadow = true,
    this.imageScale = 1.0,
  });

  static const List<double> _blurLevels = [
    30,
    26,
    22,
    18,
    14,
    10,
    7,
    4,
    2,
    0,
  ];

  static const List<int> _pixelWidths = [
    12,
    18,
    26,
    38,
    54,
    76,
    110,
    160,
    240,
    600,
  ];

  int get _safeClueIndex {
    return clueIndex.clamp(0, 9);
  }

  double get _currentBlur {
    return _blurLevels[_safeClueIndex];
  }

  int get _currentPixelWidth {
    return _pixelWidths[_safeClueIndex];
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: AppColors.orange,
          width: 1.8,
        ),
        boxShadow: showShadow
            ? const [
                BoxShadow(
                  color: Color(0x44FE5E02),
                  blurRadius: 24,
                  spreadRadius: 2,
                ),
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Center(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 350),
            switchInCurve: Curves.easeOut,
            switchOutCurve: Curves.easeIn,
            child: _buildRevealImage(),
          ),
        ),
      ),
    );
  }

  Widget _buildRevealImage() {
    switch (effect) {
      case RevealEffect.pixelate:
        return _buildPixelatedImage();

      case RevealEffect.blur:
        return _buildBlurredImage();

      case RevealEffect.none:
        return _buildClearImage();
    }
  }

  Widget _applyImageScale(Widget image) {
    if (imageScale == 1.0) {
      return image;
    }

    return Transform.scale(
      scale: imageScale,
      child: image,
    );
  }

  bool get _isNetworkImage {
    final Uri? uri = Uri.tryParse(imagePath);
    return uri != null &&
        (uri.scheme == 'http' || uri.scheme == 'https');
  }

  ImageProvider<Object> _imageProvider() {
    if (_isNetworkImage) {
      return NetworkImage(imagePath);
    }

    return AssetImage(imagePath);
  }

  Widget _buildPixelatedImage() {
    return _applyImageScale(
      Image(
        key: ValueKey(
          'pixelate-$imagePath-$_safeClueIndex',
        ),
        image: ResizeImage(
          _imageProvider(),
          width: _currentPixelWidth,
        ),
        fit: fit,
        filterQuality: FilterQuality.none,
        gaplessPlayback: true,
        errorBuilder: _buildError,
      ),
    );
  }

  Widget _buildBlurredImage() {
    return ClipRect(
      key: ValueKey(
        'blur-$imagePath-$_safeClueIndex',
      ),
      child: ImageFiltered(
        imageFilter: ImageFilter.blur(
          sigmaX: _currentBlur,
          sigmaY: _currentBlur,
          tileMode: TileMode.decal,
        ),
        child: _applyImageScale(
          Image(
            image: _imageProvider(),
            fit: fit,
            filterQuality: FilterQuality.high,
            gaplessPlayback: true,
            errorBuilder: _buildError,
          ),
        ),
      ),
    );
  }

  Widget _buildClearImage() {
    return _applyImageScale(
      Image(
        image: _imageProvider(),
        key: ValueKey('clear-$imagePath'),
        fit: fit,
        filterQuality: FilterQuality.high,
        gaplessPlayback: true,
        errorBuilder: _buildError,
      ),
    );
  }

  Widget _buildError(
    BuildContext context,
    Object error,
    StackTrace? stackTrace,
  ) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.panel,
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.image_not_supported_outlined,
            color: AppColors.orange,
            size: 46,
          ),
          SizedBox(height: 10),
          Text(
            'IMAGE NOT FOUND',
            style: TextStyle(
              color: AppColors.white,
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}