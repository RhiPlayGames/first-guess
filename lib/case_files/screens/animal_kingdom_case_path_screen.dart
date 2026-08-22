import 'package:flutter/material.dart';

import '../../theme/app_text_styles.dart';
import '../../widgets/app_home_button.dart';

class AnimalKingdomCasePathScreen extends StatelessWidget {
  const AnimalKingdomCasePathScreen({super.key});

  static const String _assetBase =
      'assets/images/case_paths/animal_kingdom';

  // Temporary values until we connect these to saved user progress.
  static const int _currentCase = 12;
  static const int _currentXp = 320;
  static const int _targetXp = 500;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            // The map uses a fixed design canvas and scales to the phone width.
            const designWidth = 430.0;
            const designHeight = 1340.0;

            final availableWidth = constraints.maxWidth;
            final scale = availableWidth / designWidth;

            return SingleChildScrollView(
              child: Center(
                child: SizedBox(
                  width: availableWidth,
                  height: designHeight * scale,
                  child: FittedBox(
                    alignment: Alignment.topCenter,
                    fit: BoxFit.fitWidth,
                    child: SizedBox(
                      width: designWidth,
                      height: designHeight,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          const Positioned.fill(
                            child: _MapBackground(),
                          ),

                          // Header
                          Positioned(
                            left: 12,
                            top: 8,
                            child: _BackButton(
                              onPressed: () =>
                                  Navigator.of(context).pop(),
                            ),
                          ),

                          const Positioned(
                            left: 116,
                            right: 116,
                            top: 8,
                            height: 55,
                            child: _FirstGuessLogo(),
                          ),

                          const Positioned(
                            right: 26,
                            top: 14,
                            child: FirstGuessHomeButton(),
                          ),

                          // Title
                          const Positioned(
                            left: 54,
                            right: 54,
                            top: 70,
                            child: _MapTitle(),
                          ),

                          // Progress panel
                          const Positioned(
                            left: 83,
                            right: 83,
                            top: 154,
                            height: 72,
                            child: _CaseProgressPanel(
                              currentCase: _currentCase,
                              currentXp: _currentXp,
                              targetXp: _targetXp,
                            ),
                          ),

                          // Case Start
                          const Positioned(
                            left: 12,
                            top: 230,
                            width: 78,
                            child: _DecorativeImage(
                              path: '$_assetBase/case_start.webp',
                              angle: -0.08,
                            ),
                          ),

                          // Winding dotted trail behind the case nodes.
                          const Positioned(
                            left: 0,
                            top: 0,
                            right: 0,
                            bottom: 0,
                            child: IgnorePointer(
                              child: CustomPaint(
                                painter: _CasePathPainter(),
                              ),
                            ),
                          ),

                          // Consistent winding path from top to bottom.
                          const _CaseNode(
                            number: 1,
                            left: 108,
                            top: 255,
                            currentCase: _currentCase,
                          ),
                          const _CaseNode(
                            number: 2,
                            left: 260,
                            top: 305,
                            currentCase: _currentCase,
                          ),

                          const Positioned(
                            right: 12,
                            top: 330,
                            width: 82,
                            child: _DecorativeImage(
                              path: '$_assetBase/polaroid_zebra.webp',
                              angle: 0.12,
                              whiteBacking: true,
                              cropBlackCanvas: true,
                            ),
                          ),

                          const _CaseNode(
                            number: 3,
                            left: 158,
                            top: 360,
                            currentCase: _currentCase,
                          ),
                          const _CaseNode(
                            number: 4,
                            left: 282,
                            top: 415,
                            currentCase: _currentCase,
                          ),

                          const Positioned(
                            left: 12,
                            top: 430,
                            width: 82,
                            child: _DecorativeImage(
                              path: '$_assetBase/animal_facts.webp',
                              angle: -0.06,
                            ),
                          ),

                          const _CaseNode(
                            number: 5,
                            left: 118,
                            top: 470,
                            currentCase: _currentCase,
                          ),
                          const _CaseNode(
                            number: 6,
                            left: 260,
                            top: 525,
                            currentCase: _currentCase,
                          ),
                          const _CaseNode(
                            number: 7,
                            left: 135,
                            top: 580,
                            currentCase: _currentCase,
                          ),
                          const _CaseNode(
                            number: 8,
                            left: 275,
                            top: 635,
                            currentCase: _currentCase,
                          ),

                          // Detective dog moved to the right-hand side.
                          const Positioned(
                            right: 4,
                            top: 590,
                            width: 92,
                            child: _DecorativeImage(
                              path: '$_assetBase/detective_dog.webp',
                            ),
                          ),

                          const _CaseNode(
                            number: 9,
                            left: 110,
                            top: 690,
                            currentCase: _currentCase,
                          ),

                          const Positioned(
                            left: 14,
                            top: 655,
                            width: 82,
                            child: _DecorativeImage(
                              path: '$_assetBase/polaroid_lion.webp',
                              angle: -0.11,
                              whiteBacking: true,
                              cropBlackCanvas: true,
                            ),
                          ),
                          const _CaseNode(
                            number: 10,
                            left: 270,
                            top: 745,
                            currentCase: _currentCase,
                          ),

                          const Positioned(
                            right: 14,
                            top: 775,
                            width: 82,
                            child: _DecorativeImage(
                              path: '$_assetBase/polaroid_elephant.webp',
                              angle: -0.10,
                              whiteBacking: true,
                              cropBlackCanvas: true,
                            ),
                          ),
                          const _CaseNode(
                            number: 11,
                            left: 125,
                            top: 800,
                            currentCase: _currentCase,
                          ),
                          const _CaseNode(
                            number: 12,
                            left: 280,
                            top: 855,
                            currentCase: _currentCase,
                          ),
                          const _CaseNode(
                            number: 13,
                            left: 115,
                            top: 910,
                            currentCase: _currentCase,
                          ),
                          const _CaseNode(
                            number: 14,
                            left: 270,
                            top: 965,
                            currentCase: _currentCase,
                          ),
                          const _CaseNode(
                            number: 15,
                            left: 125,
                            top: 1020,
                            currentCase: _currentCase,
                          ),
                          const _CaseNode(
                            number: 16,
                            left: 280,
                            top: 1075,
                            currentCase: _currentCase,
                          ),
                          const _CaseNode(
                            number: 17,
                            left: 120,
                            top: 1130,
                            currentCase: _currentCase,
                          ),
                          const _CaseNode(
                            number: 18,
                            left: 260,
                            top: 1175,
                            currentCase: _currentCase,
                          ),
                          const _CaseNode(
                            number: 19,
                            left: 115,
                            top: 1220,
                            currentCase: _currentCase,
                          ),
                          const _CaseNode(
                            number: 20,
                            left: 235,
                            top: 1270,
                            currentCase: _currentCase,
                          ),

                          // Tiger Polaroid positioned beside Case 13.
                          const Positioned(
                            left: 14,
                            top: 875,
                            width: 84,
                            child: _DecorativeImage(
                              path: '$_assetBase/polaroid_tiger.webp',
                              angle: -0.11,
                              whiteBacking: true,
                              cropBlackCanvas: true,
                            ),
                          ),

                          const Positioned(
                            right: 12,
                            top: 1110,
                            width: 84,
                            child: _DecorativeImage(
                              path: '$_assetBase/polaroid_giraffe.webp',
                              angle: 0.11,
                              whiteBacking: true,
                              cropBlackCanvas: true,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _MapBackground extends StatelessWidget {
  const _MapBackground();

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      '${AnimalKingdomCasePathScreen._assetBase}/animal_kingdom_map.webp',
      fit: BoxFit.cover,
      alignment: Alignment.topCenter,
      filterQuality: FilterQuality.high,
    );
  }
}

class _BackButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _BackButton({
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 46,
      height: 46,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(23),
          child: const Icon(
            Icons.arrow_back_rounded,
            color: Colors.white,
            size: 28,
            shadows: [
              Shadow(
                color: Colors.black,
                blurRadius: 5,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FirstGuessLogo extends StatelessWidget {
  const _FirstGuessLogo();

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/first_guess_header.png',
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
    );
  }
}

class _MapTitle extends StatelessWidget {
  const _MapTitle();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'ANIMAL KINGDOM',
          textAlign: TextAlign.center,
          style: AppTextStyles.category.copyWith(
            color: Colors.white,
            fontSize: 29,
            fontWeight: FontWeight.w900,
            height: 0.95,
            letterSpacing: 0.4,
            shadows: const [
              Shadow(
                color: Colors.black,
                blurRadius: 5,
                offset: Offset(0, 2),
              ),
            ],
          ),
        ),
        const SizedBox(height: 7),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: Text(
                'Solve games. Earn XP. Crack the next case',
                maxLines: 1,
                textAlign: TextAlign.center,
                style: AppTextStyles.body.copyWith(
                  color: Colors.white,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.15,
                  shadows: const [
                    Shadow(
                      color: Colors.black,
                      blurRadius: 4,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 7),
            const Icon(
              Icons.pets,
              color: Colors.white,
              size: 15,
            ),
          ],
        ),
      ],
    );
  }
}

class _CaseProgressPanel extends StatelessWidget {
  final int currentCase;
  final int currentXp;
  final int targetXp;

  const _CaseProgressPanel({
    required this.currentCase,
    required this.currentXp,
    required this.targetXp,
  });

  @override
  Widget build(BuildContext context) {
    final progress =
        targetXp <= 0 ? 0.0 : (currentXp / targetXp).clamp(0.0, 1.0);

    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          '${AnimalKingdomCasePathScreen._assetBase}/case_progress_panel.webp',
          fit: BoxFit.fill,
          filterQuality: FilterQuality.high,
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(29, 14, 23, 12),
          child: Row(
            children: [
              SizedBox(
                width: 77,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'CASE $currentCase',
                      maxLines: 1,
                      style: AppTextStyles.category.copyWith(
                        color: const Color(0xFF342719),
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '$currentXp / $targetXp XP',
                      maxLines: 1,
                      style: AppTextStyles.label.copyWith(
                        color: const Color(0xFF7D4D24),
                        fontSize: 9.5,
                        fontWeight: FontWeight.w900,
                        height: 1,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Container(
                  height: 13,
                  decoration: BoxDecoration(
                    color: const Color(0xFF28261D),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFF4B412C),
                      width: 1.2,
                    ),
                  ),
                  padding: const EdgeInsets.all(2),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: FractionallySizedBox(
                        widthFactor: progress,
                        child: Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Color(0xFFFE5E02),
                                Color(0xFFD96519),
                                Color(0xFFB85A1A),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 40,
                height: 40,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: const Color(0xFF191711),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFD96519),
                      width: 2,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x66000000),
                        blurRadius: 5,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.pets,
                    color: Colors.white,
                    size: 23,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CasePathPainter extends CustomPainter {
  const _CasePathPainter();

  static const List<Offset> _points = [
    Offset(137, 284),
    Offset(289, 334),
    Offset(187, 389),
    Offset(311, 444),
    Offset(147, 499),
    Offset(289, 554),
    Offset(164, 609),
    Offset(304, 664),
    Offset(139, 719),
    Offset(299, 774),
    Offset(154, 829),
    Offset(314, 889),
    Offset(144, 939),
    Offset(299, 994),
    Offset(154, 1049),
    Offset(309, 1104),
    Offset(149, 1159),
    Offset(289, 1204),
    Offset(144, 1249),
    Offset(264, 1299),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final pawPaint = Paint()
      ..color = const Color(0xD9FFFFFF)
      ..style = PaintingStyle.fill;

    const spacing = 18.0;

    for (var i = 0; i < _points.length - 1; i++) {
      final start = _points[i];
      final end = _points[i + 1];
      final delta = end - start;
      final distance = delta.distance;

      if (distance == 0) {
        continue;
      }

      final direction = delta / distance;

      for (double d = 10; d < distance - 6; d += spacing) {
        _drawPaw(
          canvas,
          start + direction * d,
          pawPaint,
        );
      }
    }
  }

  void _drawPaw(
    Canvas canvas,
    Offset centre,
    Paint paint,
  ) {
    canvas.drawOval(
      Rect.fromCenter(
        center: centre.translate(0, 2.2),
        width: 6.2,
        height: 5.0,
      ),
      paint,
    );

    canvas.drawCircle(
      centre.translate(-3.4, -2.0),
      1.4,
      paint,
    );
    canvas.drawCircle(
      centre.translate(-1.15, -3.7),
      1.4,
      paint,
    );
    canvas.drawCircle(
      centre.translate(1.15, -3.7),
      1.4,
      paint,
    );
    canvas.drawCircle(
      centre.translate(3.4, -2.0),
      1.4,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _CasePathPainter oldDelegate) => false;
}

class _CaseNode extends StatelessWidget {
  final int number;
  final double left;
  final double top;
  final int currentCase;

  const _CaseNode({
    required this.number,
    required this.left,
    required this.top,
    required this.currentCase,
  });

  @override
  Widget build(BuildContext context) {
    final isCurrent = number == currentCase;
    final isComplete = number < currentCase;
    final isLocked = number > currentCase;

    return Positioned(
      left: left,
      top: top,
      width: isCurrent ? 68 : 58,
      height: isCurrent ? 68 : 58,
      child: GestureDetector(
        onTap: isLocked
            ? null
            : () {
                // Individual case gameplay will be connected later.
              },
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isCurrent
                  ? const [
                      Color(0xFFFFC45C),
                      Color(0xFFD96519),
                      Color(0xFF7A3514),
                    ]
                  : isComplete
                      ? const [
                          Color(0xFFA9683C),
                          Color(0xFF6D3F27),
                        ]
                      : const [
                          Color(0xFF6B5B48),
                          Color(0xFF3E352B),
                        ],
            ),
            border: Border.all(
              color: isCurrent
                  ? const Color(0xFFFFE6A5)
                  : const Color(0xFFD9B98A),
              width: isCurrent ? 3.5 : 2.5,
            ),
            boxShadow: [
              const BoxShadow(
                color: Color(0x99000000),
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
              if (isCurrent)
                const BoxShadow(
                  color: Color(0xAAFFB229),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
            ],
          ),
          child: Text(
            '$number',
            style: AppTextStyles.label.copyWith(
              color: isLocked
                  ? const Color(0xFFD4C5AE)
                  : Colors.white,
              fontSize: isCurrent ? 27 : 23,
              fontWeight: FontWeight.w900,
              height: 1,
              shadows: const [
                Shadow(
                  color: Colors.black,
                  blurRadius: 2,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DecorativeImage extends StatelessWidget {
  final String path;
  final double angle;
  final bool whiteBacking;
  final bool cropBlackCanvas;

  const _DecorativeImage({
    required this.path,
    this.angle = 0,
    this.whiteBacking = false,
    this.cropBlackCanvas = false,
  });

  @override
  Widget build(BuildContext context) {
    final Widget image = Image.asset(
      path,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
    );

    if (!whiteBacking) {
      return Transform.rotate(
        angle: angle,
        child: image,
      );
    }

    return Transform.rotate(
      angle: angle,
      child: Container(
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(2),
          border: Border.all(
            color: Colors.white,
            width: 1.2,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x66000000),
              blurRadius: 7,
              offset: Offset(2, 4),
            ),
          ],
        ),
        child: ClipRect(
          child: cropBlackCanvas
              ? Transform.scale(
                  scale: 1.13,
                  child: image,
                )
              : image,
        ),
      ),
    );
  }
}
