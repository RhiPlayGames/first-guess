import 'package:flutter/material.dart';

import '../../theme/app_text_styles.dart';
import '../../widgets/app_home_button.dart';
import '../models/case_progress.dart';
import '../services/case_path_service.dart';
import 'taste_and_treats_mission_screen.dart';

class TasteAndTreatsCasePathScreen extends StatefulWidget {
  const TasteAndTreatsCasePathScreen({super.key});

  static const String _assetBase =
      'assets/images/case_paths/taste_and_treats';

  @override
  State<TasteAndTreatsCasePathScreen> createState() =>
      _TasteAndTreatsCasePathScreenState();
}

class _TasteAndTreatsCasePathScreenState
    extends State<TasteAndTreatsCasePathScreen> {
  CaseProgress? _progress;
  bool _isLoading = true;
  bool _loadFailed = false;

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _loadFailed = false;
      });
    }

    try {
      final CaseProgress progress =
          await CasePathService.loadTasteAndTreatsProgress();

      if (!mounted) {
        return;
      }

      setState(() {
        _progress = progress;
        _isLoading = false;
        _loadFailed = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
        _loadFailed = true;
      });
    }
  }

  Future<void> _openMission(int stage) async {
    final CaseProgress? progress = _progress;

    if (progress == null ||
        progress.isCompleted ||
        stage != progress.currentStage) {
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) =>
            const TasteAndTreatsMissionScreen(),
      ),
    );

    if (!mounted) {
      return;
    }

    await _loadProgress();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Center(
            child: CircularProgressIndicator(
              color: Color(0xFFFE5E02),
            ),
          ),
        ),
      );
    }

    if (_loadFailed || _progress == null) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'CASE FILE COULD NOT BE LOADED',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.category.copyWith(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 18),
                ElevatedButton(
                  onPressed: _loadProgress,
                  child: const Text('TRY AGAIN'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final CaseProgress progress = _progress!;
    final int currentStage = progress.currentStage;
    final stageProgress = progress.currentStageProgress;
    final bool currentStageHasProgress =
        stageProgress.correctCount > 0 ||
        stageProgress.clueThresholdCount > 0 ||
        stageProgress.firstGuessCount > 0;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            // The map uses a fixed design canvas and scales to the phone width.
            const designWidth = 430.0;
            const designHeight = 1900.0;

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
                          const Positioned(
                            left: 0,
                            right: 0,
                            top: 88,
                            bottom: 0,
                            child: _MapBackground(),
                          ),

                          Positioned(
                            left: 12,
                            top: 8,
                            child: _BackButton(
                              onPressed: () =>
                                  Navigator.of(context).pop(),
                            ),
                          ),

                          const Positioned(
                            right: 26,
                            top: 14,
                            child: FirstGuessHomeButton(),
                          ),

                          const Positioned(
                            left: 54,
                            right: 54,
                            top: 22,
                            child: _MapTitle(),
                          ),

                          const Positioned(
                            left: 72,
                            right: 72,
                            top: 118,
                            height: 88,
                            child: _TasteAndTreatsHeader(),
                          ),

                          const Positioned.fill(
                            child: IgnorePointer(
                              child: CustomPaint(
                                painter: _CasePathPainter(),
                              ),
                            ),
                          ),

                          _CaseNode(number: 1, left: 118, top: 278, currentStage: currentStage, currentStageHasProgress: currentStageHasProgress, onTap: () => _openMission(1)),
                          _CaseNode(number: 2, left: 278, top: 356, currentStage: currentStage, currentStageHasProgress: currentStageHasProgress, onTap: () => _openMission(2)),
                          _CaseNode(number: 3, left: 148, top: 438, currentStage: currentStage, currentStageHasProgress: currentStageHasProgress, onTap: () => _openMission(3)),
                          _CaseNode(number: 4, left: 294, top: 520, currentStage: currentStage, currentStageHasProgress: currentStageHasProgress, onTap: () => _openMission(4)),
                          _CaseNode(number: 5, left: 122, top: 602, currentStage: currentStage, currentStageHasProgress: currentStageHasProgress, onTap: () => _openMission(5)),
                          _CaseNode(number: 6, left: 282, top: 684, currentStage: currentStage, currentStageHasProgress: currentStageHasProgress, onTap: () => _openMission(6)),
                          _CaseNode(number: 7, left: 142, top: 766, currentStage: currentStage, currentStageHasProgress: currentStageHasProgress, onTap: () => _openMission(7)),
                          _CaseNode(number: 8, left: 296, top: 848, currentStage: currentStage, currentStageHasProgress: currentStageHasProgress, onTap: () => _openMission(8)),
                          _CaseNode(number: 9, left: 124, top: 930, currentStage: currentStage, currentStageHasProgress: currentStageHasProgress, onTap: () => _openMission(9)),
                          _CaseNode(number: 10, left: 284, top: 1012, currentStage: currentStage, currentStageHasProgress: currentStageHasProgress, onTap: () => _openMission(10)),
                          _CaseNode(number: 11, left: 144, top: 1094, currentStage: currentStage, currentStageHasProgress: currentStageHasProgress, onTap: () => _openMission(11)),
                          _CaseNode(number: 12, left: 298, top: 1176, currentStage: currentStage, currentStageHasProgress: currentStageHasProgress, onTap: () => _openMission(12)),
                          _CaseNode(number: 13, left: 122, top: 1258, currentStage: currentStage, currentStageHasProgress: currentStageHasProgress, onTap: () => _openMission(13)),
                          _CaseNode(number: 14, left: 282, top: 1340, currentStage: currentStage, currentStageHasProgress: currentStageHasProgress, onTap: () => _openMission(14)),
                          _CaseNode(number: 15, left: 142, top: 1422, currentStage: currentStage, currentStageHasProgress: currentStageHasProgress, onTap: () => _openMission(15)),
                          _CaseNode(number: 16, left: 296, top: 1504, currentStage: currentStage, currentStageHasProgress: currentStageHasProgress, onTap: () => _openMission(16)),
                          _CaseNode(number: 17, left: 124, top: 1586, currentStage: currentStage, currentStageHasProgress: currentStageHasProgress, onTap: () => _openMission(17)),
                          _CaseNode(number: 18, left: 282, top: 1668, currentStage: currentStage, currentStageHasProgress: currentStageHasProgress, onTap: () => _openMission(18)),
                          _CaseNode(number: 19, left: 142, top: 1750, currentStage: currentStage, currentStageHasProgress: currentStageHasProgress, onTap: () => _openMission(19)),
                          _CaseNode(number: 20, left: 278, top: 1828, currentStage: currentStage, currentStageHasProgress: currentStageHasProgress, onTap: () => _openMission(20)),
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
      '${TasteAndTreatsCasePathScreen._assetBase}/tastes_and_treats_map.webp',
      fit: BoxFit.fill,
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

class _MapTitle extends StatelessWidget {
  const _MapTitle();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'A TASTE OF MYSTERY',
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

      ],
    );
  }
}

class _TasteAndTreatsHeader extends StatelessWidget {
  const _TasteAndTreatsHeader();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Image.asset(
        '${TasteAndTreatsCasePathScreen._assetBase}/tastes_and_treats_mission_file.webp',
        fit: BoxFit.contain,
        alignment: Alignment.center,
        filterQuality: FilterQuality.high,
      ),
    );
  }
}

class _CasePathPainter extends CustomPainter {
  const _CasePathPainter();

  static const List<Offset> _points = [
    Offset(147, 307),
    Offset(307, 385),
    Offset(177, 467),
    Offset(323, 549),
    Offset(151, 631),
    Offset(311, 713),
    Offset(171, 795),
    Offset(325, 877),
    Offset(153, 959),
    Offset(313, 1041),
    Offset(173, 1123),
    Offset(327, 1205),
    Offset(151, 1287),
    Offset(311, 1369),
    Offset(171, 1451),
    Offset(325, 1533),
    Offset(153, 1615),
    Offset(311, 1697),
    Offset(171, 1779),
    Offset(314, 1864),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final Paint trailPaint = Paint()
      ..color = const Color(0xD9FFFFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.2
      ..strokeCap = StrokeCap.round;

    const double dashLength = 8.0;
    const double gapLength = 8.0;

    for (var i = 0; i < _points.length - 1; i++) {
      final Offset start = _points[i];
      final Offset end = _points[i + 1];
      final Offset delta = end - start;
      final double distance = delta.distance;

      if (distance == 0) {
        continue;
      }

      final Offset direction = delta / distance;

      for (double d = 10; d < distance - 8; d += dashLength + gapLength) {
        final Offset dashStart = start + direction * d;
        final Offset dashEnd = start +
            direction * (d + dashLength).clamp(0.0, distance - 8);

        canvas.drawLine(
          dashStart,
          dashEnd,
          trailPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _CasePathPainter oldDelegate) => false;
}

class _CaseNode extends StatelessWidget {
  final int number;
  final double left;
  final double top;
  final int currentStage;
  final bool currentStageHasProgress;
  final VoidCallback onTap;

  const _CaseNode({
    required this.number,
    required this.left,
    required this.top,
    required this.currentStage,
    required this.currentStageHasProgress,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isCurrent = number == currentStage;
    final isComplete = number < currentStage;
    final isLocked = number > currentStage;
    final isFinal = number == 20;

    final nodeSize = isFinal
        ? 72.0
        : isCurrent
            ? 68.0
            : 58.0;

    const labelWidth = 110.0;

    return Positioned(
      left: left - ((labelWidth - nodeSize) / 2),
      top: top,
      width: labelWidth,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: GestureDetector(
            onTap: isCurrent ? onTap : null,
            child: Container(
              width: nodeSize,
              height: nodeSize,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isComplete
                      ? const [
                          Color(0xFF75C84A),
                          Color(0xFF3E9B35),
                          Color(0xFF246E28),
                        ]
                      : isCurrent
                          ? const [
                              Color(0xFFFE5E02),
                              Color(0xFFFE5E02),
                              Color(0xFFFE5E02),
                            ]
                          : isFinal
                              ? const [
                                  Color(0xFFFFC45C),
                                  Color(0xFFD96519),
                                  Color(0xFF6A2B10),
                                ]
                              : const [
                                  Color(0xFF6B5B48),
                                  Color(0xFF3E352B),
                                ],
                ),
                border: Border.all(
                  color: isCurrent || isFinal
                      ? const Color(0xFFFFE6A5)
                      : const Color(0xFFD9B98A),
                  width: isCurrent || isFinal ? 3.5 : 2.5,
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
              child: isComplete
                  ? const Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 30,
                    )
                  : isLocked && !isFinal
                      ? const Icon(
                          Icons.lock_rounded,
                          color: Color(0xFFD4C5AE),
                          size: 24,
                        )
                      : isFinal && isLocked
                          ? const Icon(
                              Icons.workspace_premium_rounded,
                              color: Color(0xFFD4C5AE),
                              size: 32,
                            )
                          : Text(
                              '$number',
                              style: AppTextStyles.label.copyWith(
                                color: Colors.white,
                                fontSize: isFinal ? 25 : isCurrent ? 27 : 23,
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
          ),
          if (isCurrent) ...[
            const SizedBox(height: 4),
            Text(
              currentStageHasProgress
                  ? 'CONTINUE MISSION'
                  : 'TAP TO START',
              maxLines: 1,
              style: AppTextStyles.category.copyWith(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.3,
                shadows: const [
                  Shadow(
                    color: Colors.black,
                    blurRadius: 2,
                    offset: Offset(-1, 0),
                  ),
                  Shadow(
                    color: Colors.black,
                    blurRadius: 2,
                    offset: Offset(1, 0),
                  ),
                  Shadow(
                    color: Colors.black,
                    blurRadius: 2,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
            ),
          ],
          if (isFinal) ...[
            const SizedBox(height: 3),
            Text(
              'FINAL CASE',
              maxLines: 1,
              style: AppTextStyles.label.copyWith(
                color: const Color(0xFF342719),
                fontSize: 8.5,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
