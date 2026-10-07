import 'package:flutter/material.dart';

import '../../models/quiz_item.dart';
import '../../screens/game_screen.dart';
import '../../services/analytics_service.dart';
import '../../services/firebase_challenge_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/app_home_button.dart';
import '../models/case_mission.dart';
import '../models/case_progress.dart';
import '../services/case_path_service.dart';

class TasteAndTreatsMissionScreen extends StatefulWidget {
  final int? replayStage;

  const TasteAndTreatsMissionScreen({
    super.key,
    this.replayStage,
  });

  static const String _mapAsset =
      'assets/images/case_paths/taste_and_treats/tastes_and_treats_map.webp';

  static const String _missionCardAsset =
      'assets/images/case_files/New folder/screenbg.webp';

  static const String _startMissionCtaAsset =
      'assets/images/case_files/New folder/startmissionCTA.webp';

  static const String _inProgressCtaAsset =
      'assets/images/case_files/New folder/continueCTA.webp';

  static const String _completedCtaAsset =
      'assets/images/case_files/New folder/completedCTA.webp';

  static const String _titleAsset =
      'assets/images/case_files/New folder/tasteofmysterytext.webp';

  static const String _iconAsset =
      'assets/images/case_files/New folder/tasteofmysteryicon.webp';

  @override
  State<TasteAndTreatsMissionScreen> createState() =>
      _TasteAndTreatsMissionScreenState();
}

class _TasteAndTreatsMissionScreenState
    extends State<TasteAndTreatsMissionScreen> {
  CaseProgress? _progress;
  CaseMission? _mission;
  bool _isLoading = true;
  bool _loadFailed = false;
  bool _isStartingMission = false;

  static const List<String> _tasteAndTreatsSubcategories = <String>[
    'breakfast',
    'desserts',
    'dishes_world_cuisine',
    'fruit_vegs',
    'herbs_spices',
    'snacks_street_food',
    'drinks',
  ];

  @override
  void initState() {
    super.initState();
    _loadMission();
  }

  Future<void> _loadMission() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _loadFailed = false;
      });
    }

    try {
      final CaseProgress progress =
          await CasePathService.loadTasteAndTreatsProgress();

      final CaseMission? mission = progress.isCompleted &&
              widget.replayStage != null
          ? CasePathService.tasteAndTreatsMissionForStage(
              widget.replayStage!,
            )
          : CasePathService.currentTasteAndTreatsMission(
              progress,
            );

      if (!mounted) {
        return;
      }

      setState(() {
        _progress = progress;
        _mission = mission;
        _isLoading = false;
        _loadFailed = mission == null &&
            !(progress.isCompleted && widget.replayStage == null);
      });
    } catch (error, stackTrace) {
      debugPrint(
        'TASTES & TREATS MISSION LOAD ERROR: $error',
      );
      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
        _loadFailed = true;
      });
    }
  }

  Future<void> _startMission() async {
    final CaseMission? mission = _mission;

    if (mission == null || _isStartingMission) {
      return;
    }

    setState(() {
      _isStartingMission = true;
    });

    try {
      final items = mission.hasSubcategoryRequirement
          ? await FirebaseChallengeService.loadLiveSubcategory(
              category: mission.category,
              subcategory: mission.subcategory!,
            )
          : await _loadAllTasteAndTreatsQuestions();

      if (!mounted) {
        return;
      }

      if (items.isEmpty) {
        _showNoQuestionsMessage(mission);
        return;
      }

      final CaseProgress? progressBefore = _progress;
      final bool isReplay =
          (progressBefore?.isCompleted ?? false) &&
          widget.replayStage != null;
      final int stageNumber = mission.stage;
      final DateTime analyticsSessionStartedAt = DateTime.now();

      if (!isReplay) {
        final CaseStageProgress? stageProgress =
            progressBefore?.currentStageProgress;
        final bool resume = stageProgress != null &&
            stageProgress.stage == stageNumber &&
            (stageProgress.correctCount > 0 ||
                stageProgress.clueThresholdCount > 0 ||
                stageProgress.firstGuessCount > 0);

        await AnalyticsService.logCaseFileStageStarted(
          caseKey: 'taste_and_treats',
          caseName: 'A TASTE OF MYSTERY',
          stageNumber: stageNumber,
          totalStages: CasePathService.tasteAndTreatsTotalStages,
          resume: resume,
        );

        if (!mounted) {
          return;
        }
      }

      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (context) {
            return GameScreen.firebaseDynamic(
              items: items,
              launchedFromSurpriseMe: false,
              showSurpriseToast: false,
              launchedFromCaseFile: true,
                caseFileReplay:
                    (_progress?.isCompleted ?? false) &&
                    widget.replayStage != null,
            );
          },
        ),
      );

      if (!mounted) {
        return;
      }

      await _loadMission();

      if (!isReplay) {
        final CaseProgress? progressAfter = _progress;
        final bool stageCompleted =
            progressAfter?.completedStages.contains(stageNumber) ?? false;

        if (!stageCompleted) {
          await AnalyticsService.logCaseFileAbandoned(
            caseKey: 'taste_and_treats',
            caseName: 'A TASTE OF MYSTERY',
            currentStage: stageNumber,
            totalStages: CasePathService.tasteAndTreatsTotalStages,
            playTimeSeconds: DateTime.now()
                .difference(analyticsSessionStartedAt)
                .inSeconds,
          );
        }
      }
    } catch (error, stackTrace) {
      debugPrint(
        'TASTES & TREATS START MISSION ERROR: $error',
      );
      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) {
        return;
      }

      _showLoadErrorMessage();
    } finally {
      if (mounted) {
        setState(() {
          _isStartingMission = false;
        });
      }
    }
  }

  Future<List<QuizItem>> _loadAllTasteAndTreatsQuestions() async {
    final results = await Future.wait(
      _tasteAndTreatsSubcategories.map(
        (String subcategory) =>
            FirebaseChallengeService.loadLiveSubcategory(
          category: 'food_drink',
          subcategory: subcategory,
        ),
      ),
    );

    return results.expand((items) => items).toList();
  }

  void _showNoQuestionsMessage(
    CaseMission mission,
  ) {
    final String label = mission.hasSubcategoryRequirement
        ? _subcategoryLabel(mission.subcategory!)
        : 'Tastes & Treats';

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          backgroundColor: AppColors.panel,
          behavior: SnackBarBehavior.floating,
          content: Text(
            'No live $label questions were found.',
            style: AppTextStyles.body.copyWith(
              color: AppColors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
  }

  void _showLoadErrorMessage() {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          backgroundColor: AppColors.panel,
          behavior: SnackBarBehavior.floating,
          content: Text(
            'Tastes & Treats questions could not be loaded from Firebase.',
            style: AppTextStyles.body.copyWith(
              color: AppColors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
  }

  String _subcategoryLabel(String key) {
    switch (key) {
      case 'breakfast':
        return 'Breakfast Foods';
      case 'desserts':
        return 'Desserts, Cakes & Sweets';
      case 'dishes_world_cuisine':
        return 'Dishes & World Cuisines';
      case 'fruit_vegs':
        return 'Fruit & Vegetables';
      case 'herbs_spices':
        return 'Herbs & Spices';
      case 'snacks_street_food':
        return 'Snacks';
      case 'drinks':
        return 'World Drinks';
      default:
        return 'Tastes & Treats';
    }
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
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'CASE FILE COULD NOT BE LOADED',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.category.copyWith(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadMission,
                    child: const Text('TRY AGAIN'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final CaseProgress progress = _progress!;

    if (progress.isCompleted && widget.replayStage == null) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Stack(
            children: [
              Positioned.fill(
                child: Image.asset(
                  TasteAndTreatsMissionScreen._mapAsset,
                  fit: BoxFit.cover,
                  alignment: Alignment.topCenter,
                  filterQuality: FilterQuality.high,
                ),
              ),
              Positioned.fill(
                child: Container(
                  color: Colors.black.withValues(alpha: 0.35),
                ),
              ),
              Column(
                children: [
                  _MissionHeader(
                    onBackPressed: () =>
                        Navigator.of(context).pop(),
                  ),
                  const Spacer(),
                  Text(
                    'A TASTE OF MYSTERY',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.category.copyWith(
                      color: Colors.white,
                      fontSize: 31,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'CASE SOLVED',
                    style: AppTextStyles.category.copyWith(
                      color: const Color(0xFFFE5E02),
                      fontSize: 25,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const Spacer(),
                ],
              ),
            ],
          ),
        ),
      );
    }

    final CaseMission? mission = _mission;

    if (mission == null) {
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

    final double screenWidth =
        MediaQuery.sizeOf(context).width;
    final bool isDesktop = screenWidth >= 1200;
    final double horizontalPadding = isDesktop
        ? ((screenWidth - 760) / 2).clamp(16.0, double.infinity)
        : 16.0;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          SafeArea(
            bottom: false,
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                8,
                horizontalPadding,
                0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _MissionHeader(
                    onBackPressed: () =>
                        Navigator.of(context).pop(),
                  ),
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: _isStartingMission ? null : _startMission,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 2),
                        Text(
                          'A TASTE OF MYSTERY',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.category.copyWith(
                            color: Colors.white,
                            fontSize: 19,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.4,
                            height: 1,
                            shadows: const [
                              Shadow(
                                color: Colors.black,
                                blurRadius: 1,
                                offset: Offset(-1, 0),
                              ),
                              Shadow(
                                color: Colors.black,
                                blurRadius: 1,
                                offset: Offset(1, 0),
                              ),
                              Shadow(
                                color: Colors.black,
                                blurRadius: 1,
                                offset: Offset(0, -1),
                              ),
                              Shadow(
                                color: Colors.black,
                                blurRadius: 1,
                                offset: Offset(0, 1),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'CASE ${mission.stage}',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.category.copyWith(
                            color: Colors.white,
                            fontSize: 21,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.3,
                            height: 1,
                            shadows: const [
                              Shadow(
                                color: Colors.black,
                                blurRadius: 1,
                                offset: Offset(-1, 0),
                              ),
                              Shadow(
                                color: Colors.black,
                                blurRadius: 1,
                                offset: Offset(1, 0),
                              ),
                              Shadow(
                                color: Colors.black,
                                blurRadius: 1,
                                offset: Offset(0, -1),
                              ),
                              Shadow(
                                color: Colors.black,
                                blurRadius: 1,
                                offset: Offset(0, 1),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        _MissionProgressPanel(
                          mission: mission,
                          progress: progress.currentStageProgress,
                    replayMode:
                        progress.isCompleted && widget.replayStage != null,
                        ),
                        const SizedBox(height: 2),
                        _MissionCard(
                          mission: mission,
                          progress: progress.currentStageProgress,
                    replayMode:
                        progress.isCompleted && widget.replayStage != null,
                          isStarting: _isStartingMission,
                          onStartMission: _startMission,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          ],
        ),
    );
  }
}

class _MissionHeader extends StatelessWidget {
  final VoidCallback onBackPressed;

  const _MissionHeader({
    required this.onBackPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              onPressed: onBackPressed,
              icon: const Icon(
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
          const Align(
            alignment: Alignment.centerRight,
            child: FirstGuessHomeButton(),
          ),
        ],
      ),
    );
  }
}

class _MissionProgressPanel extends StatelessWidget {
  final CaseMission mission;
  final CaseStageProgress progress;
  final bool replayMode;

  const _MissionProgressPanel({
    required this.mission,
    required this.progress,
    this.replayMode = false,
  });

  @override
  Widget build(BuildContext context) {
    final int displayedCorrectCount =
        replayMode ? 0 : progress.correctCount;

    final double progressValue = mission.correctRequired <= 0
        ? 0
        : (displayedCorrectCount / mission.correctRequired)
            .clamp(0.0, 1.0);

    return Container(
      height: 104,
      padding: const EdgeInsets.fromLTRB(20, 13, 20, 13),
      decoration: BoxDecoration(
        color: const Color(0xE61C1C1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF8F7A55),
          width: 1.4,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x88000000),
            blurRadius: 7,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          SizedBox(
            width: 126,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'MISSION PROGRESS',
                  style: AppTextStyles.category.copyWith(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '$displayedCorrectCount / ${mission.correctRequired}',
                  style: AppTextStyles.label.copyWith(
                    color: const Color(0xFFFE5E02),
                    fontSize: 23,
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              height: 20,
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
                    widthFactor: progressValue,
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
        ],
      ),
    );
  }
}

class _MissionCard extends StatelessWidget {
  final CaseMission mission;
  final CaseStageProgress progress;
  final bool replayMode;
  final bool isStarting;
  final VoidCallback onStartMission;

  const _MissionCard({
    required this.mission,
    required this.progress,
    this.replayMode = false,
    required this.isStarting,
    required this.onStartMission,
  });

  bool get hasStarted =>
      progress.correctCount > 0 ||
      progress.clueThresholdCount > 0 ||
      progress.firstGuessCount > 0;

  @override
  Widget build(BuildContext context) {
    final bool isDesktop =
        MediaQuery.sizeOf(context).width >= 1200;

    final bool missionCompleted =
        !replayMode &&
        progress.correctCount >= mission.correctRequired;

    final bool missionStarted =
        !replayMode && hasStarted && !missionCompleted;

    final String ctaAsset = missionCompleted
        ? TasteAndTreatsMissionScreen._completedCtaAsset
        : missionStarted
            ? TasteAndTreatsMissionScreen._inProgressCtaAsset
            : TasteAndTreatsMissionScreen._startMissionCtaAsset;

    if (isDesktop) {
      return Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: Container(
            margin: const EdgeInsets.only(top: 14),
            padding: const EdgeInsets.fromLTRB(28, 24, 28, 24),
            decoration: BoxDecoration(
              color: const Color(0xFF050505),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: const Color(0xFF262626),
                width: 1.4,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x66000000),
                  blurRadius: 14,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  width: 132,
                  height: 132,
                  child: Image.asset(
                    TasteAndTreatsMissionScreen._iconAsset,
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.high,
                  ),
                ),
                const SizedBox(width: 26),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        height: 52,
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Image.asset(
                            TasteAndTreatsMissionScreen._titleAsset,
                            fit: BoxFit.contain,
                            alignment: Alignment.centerLeft,
                            filterQuality: FilterQuality.high,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        mission.missionText,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.left,
                        style: AppTextStyles.category.copyWith(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.1,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 22),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: SizedBox(
                          width: 330,
                          child: Image.asset(
                            ctaAsset,
                            fit: BoxFit.contain,
                            filterQuality: FilterQuality.high,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return AspectRatio(
      aspectRatio: 1122 / 1402,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final double width = constraints.maxWidth;
          final double originalHeight = width * (1402 / 1122);

          const double missionTextTopFactor = 0.57;
          const double missionTextHeightFactor = 0.15;

          return Stack(
            fit: StackFit.expand,
            children: [
              Positioned.fill(
                child: Image.asset(
                  TasteAndTreatsMissionScreen._missionCardAsset,
                  fit: BoxFit.contain,
                  alignment: Alignment.topCenter,
                  filterQuality: FilterQuality.high,
                ),
              ),

              Positioned(
                left: width * 0.33,
                right: width * 0.33,
                top: originalHeight * 0.17,
                child: Image.asset(
                  TasteAndTreatsMissionScreen._iconAsset,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.high,
                ),
              ),

              Positioned(
                left: width * 0.18,
                right: width * 0.18,
                top: originalHeight * 0.40,
                child: Image.asset(
                  TasteAndTreatsMissionScreen._titleAsset,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.high,
                ),
              ),

              // Dynamic mission wording: white and positioned high enough
              // to allow two lines without crowding the CTA.
              Positioned(
                left: width * 0.08,
                right: width * 0.08,
                top: originalHeight * missionTextTopFactor,
                height: originalHeight * missionTextHeightFactor,
                child: Center(
                  child: Text(
                    mission.missionText,
                    maxLines: 3,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.category.copyWith(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.1,
                      height: 1.22,
                    ),
                  ),
                ),
              ),

              Positioned(
                left: width * 0.08,
                right: width * 0.08,
                bottom: originalHeight * 0.045,
                child: Image.asset(
                  ctaAsset,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.high,
                ),
              ),

            ],
          );
        },
      ),
    );
  }
}
