import 'package:flutter/material.dart';

import '../../models/quiz_item.dart';
import '../../screens/game_screen.dart';
import '../../services/firebase_challenge_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/app_home_button.dart';
import '../models/case_mission.dart';
import '../models/case_progress.dart';
import '../services/case_path_service.dart';

class AnimalKingdomMissionScreen extends StatefulWidget {
  const AnimalKingdomMissionScreen({super.key});

  static const String _mapAsset =
      'assets/images/case_paths/animal_kingdom/animal_kingdom_map.webp';

  static const String _progressPanelAsset =
      'assets/images/case_paths/animal_kingdom/case_progress_panel_black.webp';

  static const String _missionCardAsset =
      'assets/images/case_paths/animal_kingdom/animal_kingdom_mission_cardV2.webp';

  @override
  State<AnimalKingdomMissionScreen> createState() =>
      _AnimalKingdomMissionScreenState();
}

class _AnimalKingdomMissionScreenState
    extends State<AnimalKingdomMissionScreen> {
  CaseProgress? _progress;
  CaseMission? _mission;
  bool _isLoading = true;
  bool _loadFailed = false;
  bool _isStartingMission = false;

  static const List<String> _animalSubcategories = <String>[
    'birds',
    'dinosaurs',
    'habitats_animal_groups',
    'insects_spiders',
    'jungle_safari_animals',
    'mammals',
    'reptiles_amphibians',
    'sea_creatures',
    'tracks_footprints',
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
          await CasePathService.loadAnimalKingdomProgress();

      final CaseMission? mission =
          CasePathService.currentAnimalKingdomMission(
        progress,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _progress = progress;
        _mission = mission;
        _isLoading = false;
        _loadFailed = mission == null && !progress.isCompleted;
      });
    } catch (error, stackTrace) {
      debugPrint(
        'ANIMAL KINGDOM MISSION LOAD ERROR: $error',
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
          : await _loadAllAnimalQuestions();

      if (!mounted) {
        return;
      }

      if (items.isEmpty) {
        _showNoQuestionsMessage(mission);
        return;
      }

      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (context) {
            if (mission.subcategory == 'birds') {
              return GameScreen.birds(
                items: items,
                launchedFromCaseFile: true,
              );
            }

            if (mission.subcategory == 'dinosaurs') {
              return GameScreen.dinosaurs(
                items: items,
                launchedFromCaseFile: true,
              );
            }

            return GameScreen.firebaseDynamic(
              items: items,
              launchedFromSurpriseMe: false,
              showSurpriseToast: false,
              launchedFromCaseFile: true,
            );
          },
        ),
      );

      if (!mounted) {
        return;
      }

      await _loadMission();
    } catch (error, stackTrace) {
      debugPrint(
        'ANIMAL KINGDOM START MISSION ERROR: $error',
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

  Future<List<QuizItem>> _loadAllAnimalQuestions() async {
    final results = await Future.wait(
      _animalSubcategories.map(
        (String subcategory) =>
            FirebaseChallengeService.loadLiveSubcategory(
          category: 'animals',
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
        : 'Animals';

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
            'Animal Kingdom questions could not be loaded from Firebase.',
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
      case 'birds':
        return 'Birds';
      case 'dinosaurs':
        return 'Dinosaurs';
      case 'habitats_animal_groups':
        return 'Habitats & Animal Groups';
      case 'insects_spiders':
        return 'Insects & Spiders';
      case 'jungle_safari_animals':
        return 'Jungle & Safari Animals';
      case 'mammals':
        return 'Mammals';
      case 'reptiles_amphibians':
        return 'Reptiles & Amphibians';
      case 'sea_creatures':
        return 'Sea Creatures';
      case 'tracks_footprints':
        return 'Tracks & Footprints';
      default:
        return 'Animals';
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

    if (progress.isCompleted) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Stack(
            children: [
              Positioned.fill(
                child: Image.asset(
                  AnimalKingdomMissionScreen._mapAsset,
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
                    'ANIMAL KINGDOM',
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

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              AnimalKingdomMissionScreen._mapAsset,
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
              filterQuality: FilterQuality.high,
            ),
          ),
          Positioned.fill(
            child: Container(
              color: Colors.black.withValues(alpha: 0.20),
            ),
          ),
          SafeArea(
            bottom: false,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                16,
                8,
                16,
                0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _MissionHeader(
                    onBackPressed: () =>
                        Navigator.of(context).pop(),
                  ),
                  const SizedBox(height: 2),
                  const _MissionTitle(),
                  const SizedBox(height: 7),
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
                  const SizedBox(height: 8),
                  _MissionProgressPanel(
                    mission: mission,
                    progress: progress.currentStageProgress,
                  ),
                  const SizedBox(height: 8),
                  _MissionCard(
                    mission: mission,
                    progress: progress.currentStageProgress,
                    isStarting: _isStartingMission,
                    onStartMission: _startMission,
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

class _MissionTitle extends StatelessWidget {
  const _MissionTitle();

  @override
  Widget build(BuildContext context) {
    return Text(
      'ANIMAL KINGDOM',
      textAlign: TextAlign.center,
      style: AppTextStyles.category.copyWith(
        color: Colors.white,
        fontSize: 31,
        fontWeight: FontWeight.w900,
        letterSpacing: 0.4,
        height: 1,
        shadows: const [
          Shadow(
            color: Colors.black,
            blurRadius: 5,
            offset: Offset(0, 2),
          ),
        ],
      ),
    );
  }
}

class _MissionProgressPanel extends StatelessWidget {
  final CaseMission mission;
  final CaseStageProgress progress;

  const _MissionProgressPanel({
    required this.mission,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    final double progressValue = mission.correctRequired <= 0
        ? 0
        : (progress.correctCount / mission.correctRequired).clamp(0.0, 1.0);

    return SizedBox(
      height: 104,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            AnimalKingdomMissionScreen._progressPanelAsset,
            fit: BoxFit.fill,
            filterQuality: FilterQuality.high,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(46, 12, 20, 12),
            child: Row(
              children: [
                SizedBox(
                  width: 112,
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
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${progress.correctCount} / ${mission.correctRequired}',
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
                const SizedBox(width: 4),
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
          ),
        ],
      ),
    );
  }
}

class _MissionCard extends StatelessWidget {
  final CaseMission mission;
  final CaseStageProgress progress;
  final bool isStarting;
  final VoidCallback onStartMission;

  const _MissionCard({
    required this.mission,
    required this.progress,
    required this.isStarting,
    required this.onStartMission,
  });

  bool get hasStarted =>
      progress.correctCount > 0 ||
      progress.clueThresholdCount > 0 ||
      progress.firstGuessCount > 0;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1122 / 1402,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final originalHeight = width * (1402 / 1122);

          return Stack(
            fit: StackFit.expand,
            children: [
              ClipRect(
                child: OverflowBox(
                  alignment: Alignment.topCenter,
                  minWidth: width,
                  maxWidth: width,
                  minHeight: width * (1402 / 1122),
                  maxHeight: width * (1402 / 1122),
                  child: Image.asset(
                    AnimalKingdomMissionScreen._missionCardAsset,
                    width: width,
                    height: width * (1402 / 1122),
                    fit: BoxFit.fill,
                    filterQuality: FilterQuality.high,
                  ),
                ),
              ),

              // Dynamic mission wording sits inside the blank parchment area in V2.
              Positioned(
                left: width * 0.10,
                right: width * 0.10,
                top: originalHeight * 0.690,
                height: originalHeight * 0.155,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      mission.missionText,
                      maxLines: 2,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.category.copyWith(
                        color: const Color(0xFF2F2117),
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.1,
                        height: 1.05,
                      ),
                    ),
                  ],
                ),
              ),

              // Clickable dynamic text placed over the blank orange CTA in V2.
              Positioned(
                left: width * 0.14,
                right: width * 0.14,
                top: originalHeight * 0.850,
                height: originalHeight * 0.090,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: isStarting ? null : onStartMission,
                    borderRadius: BorderRadius.circular(16),
                    child: Center(
                      child: Text(
                        isStarting
                            ? 'LOADING...'
                            : hasStarted
                                ? 'CONTINUE MISSION'
                                : 'START MISSION',
                        maxLines: 1,
                        style: AppTextStyles.category.copyWith(
                          color: AppColors.white,
                          fontSize: 21,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.3,
                          height: 1,
                          shadows: const [
                            Shadow(
                              color: Colors.black,
                              blurRadius: 2,
                              offset: Offset(0, 1),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

            ],
          );
        },
      ),
    );
  }
}