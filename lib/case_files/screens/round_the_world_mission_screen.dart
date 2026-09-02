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

class RoundTheWorldMissionScreen extends StatefulWidget {
  const RoundTheWorldMissionScreen({super.key});

  static const String _mapAsset =
      'assets/images/case_paths/round_the_world/round_the_world_map.webp';

  static const String _missionCardAsset =
      'assets/images/case_paths/round_the_world/round_the_world_mission_file.webp';

  @override
  State<RoundTheWorldMissionScreen> createState() =>
      _RoundTheWorldMissionScreenState();
}

class _RoundTheWorldMissionScreenState
    extends State<RoundTheWorldMissionScreen> {
  CaseProgress? _progress;
  CaseMission? _mission;
  bool _isLoading = true;
  bool _loadFailed = false;
  bool _isStartingMission = false;

  static const List<String> _countrySubcategories = <String>[
    'country_silhouettes',
    'flags',
    'capitals',
    'major_cities',
    'states_regions',
    'maps_borders',
    'landmarks_world_wonders',
    'currencies_languages',
    'national_symbols',
    'islands_mountains_rivers',
    'national_foods',
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
          await CasePathService.loadRoundTheWorldProgress();

      final CaseMission? mission =
          CasePathService.currentRoundTheWorldMission(
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
        'AROUND THE WORLD MISSION LOAD ERROR: $error',
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
          : await _loadAllCountryQuestions();

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
        'AROUND THE WORLD START MISSION ERROR: $error',
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

  Future<List<QuizItem>> _loadAllCountryQuestions() async {
    final results = await Future.wait(
      _countrySubcategories.map(
        (String subcategory) =>
            FirebaseChallengeService.loadLiveSubcategory(
          category: 'countries',
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
        : 'Countries';

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
            'Around the World questions could not be loaded from Firebase.',
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
      case 'country_silhouettes':
        return 'Country Silhouettes';
      case 'flags':
        return 'Flags';
      case 'capitals':
        return 'Capitals';
      case 'major_cities':
        return 'Major Cities';
      case 'states_regions':
        return 'States & Regions';
      case 'maps_borders':
        return 'Maps & Borders';
      case 'landmarks_world_wonders':
        return 'Landmarks & World Wonders';
      case 'currencies_languages':
        return 'Currencies & Languages';
      case 'national_symbols':
        return 'National Symbols';
      case 'islands_mountains_rivers':
        return 'Islands, Mountains & Rivers';
      case 'national_foods':
        return 'National Foods';
      default:
        return 'Countries';
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
                  RoundTheWorldMissionScreen._mapAsset,
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
                    'AROUND THE WORLD',
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
              RoundTheWorldMissionScreen._mapAsset,
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
      'AROUND THE WORLD',
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
        : (progress.correctCount / mission.correctRequired)
            .clamp(0.0, 1.0);

    return Container(
      height: 96,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF151815),
            Color(0xFF24251F),
          ],
        ),
        border: Border.all(
          color: const Color(0xFF9B8150),
          width: 1.4,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x99000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            left: 10,
            right: 10,
            top: 7,
            child: Container(
              height: 1,
              color: const Color(0x337E6C48),
            ),
          ),
          Positioned(
            left: 10,
            right: 10,
            bottom: 7,
            child: Container(
              height: 1,
              color: const Color(0x337E6C48),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              19,
              13,
              19,
              13,
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 128,
                  child: Column(
                    mainAxisAlignment:
                        MainAxisAlignment.center,
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        'MISSION PROGRESS',
                        style:
                            AppTextStyles.category.copyWith(
                          color:
                              const Color(0xFFF6F0DF),
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          height: 1,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        '${progress.correctCount} / ${mission.correctRequired}',
                        style: AppTextStyles.label.copyWith(
                          color:
                              const Color(0xFFFE6A0A),
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          height: 1,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    height: 18,
                    decoration: BoxDecoration(
                      color:
                          const Color(0xFF2A2A22),
                      borderRadius:
                          BorderRadius.circular(20),
                      border: Border.all(
                        color:
                            const Color(0xFF66593B),
                        width: 1.2,
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color:
                              Color(0x66000000),
                          blurRadius: 3,
                          offset: Offset(0, 1),
                        ),
                      ],
                    ),
                    padding:
                        const EdgeInsets.all(2),
                    child: ClipRRect(
                      borderRadius:
                          BorderRadius.circular(20),
                      child: Align(
                        alignment:
                            Alignment.centerLeft,
                        child:
                            FractionallySizedBox(
                          widthFactor:
                              progressValue,
                          child: Container(
                            decoration:
                                const BoxDecoration(
                              gradient:
                                  LinearGradient(
                                begin: Alignment
                                    .centerLeft,
                                end: Alignment
                                    .centerRight,
                                colors: [
                                  Color(
                                      0xFFFE5E02),
                                  Color(
                                      0xFFE77A20),
                                  Color(
                                      0xFFFFA13A),
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
      aspectRatio: 1136 / 1408,
      child: LayoutBuilder(
        builder: (
          BuildContext context,
          BoxConstraints constraints,
        ) {
          final double width = constraints.maxWidth;
          final double height = constraints.maxHeight;

          return Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(
                RoundTheWorldMissionScreen
                    ._missionCardAsset,
                fit: BoxFit.fill,
                filterQuality: FilterQuality.high,
              ),

              // Dynamic mission objective.
              // The artwork intentionally leaves
              // this parchment area blank.
              Positioned(
                left: width * 0.08,
                right: width * 0.08,
                top: height * 0.705,
                height: height * 0.115,
                child: Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: width * 0.80,
                      ),
                      child: Text(
                        mission.missionText
                            .toUpperCase(),
                        maxLines: 2,
                        overflow:
                            TextOverflow.ellipsis,
                        textAlign:
                            TextAlign.center,
                        style: AppTextStyles.category
                            .copyWith(
                          color:
                              const Color(0xFF2E2117),
                          fontSize: 20,
                          fontWeight:
                              FontWeight.w900,
                          letterSpacing: 0.05,
                          height: 1.08,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // The orange CTA is baked into
              // round_the_world_mission_file.webp.
              // Flutter adds only its dynamic
              // label and tap target.
              Positioned(
                left: width * 0.075,
                right: width * 0.075,
                top: height * 0.855,
                height: height * 0.095,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: isStarting
                        ? null
                        : onStartMission,
                    borderRadius:
                        BorderRadius.circular(18),
                    child: Align(
                      alignment: const Alignment(0, 0.38),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          isStarting
                              ? 'LOADING...'
                              : hasStarted
                                  ? 'CONTINUE MISSION'
                                  : 'START MISSION',
                          textAlign:
                              TextAlign.center,
                          style: AppTextStyles.category
                              .copyWith(
                            color: AppColors.white,
                            fontSize: 21,
                            fontWeight:
                                FontWeight.w900,
                            letterSpacing: 0.3,
                            shadows: const [
                              Shadow(
                                color:
                                    Color(0x99000000),
                                blurRadius: 2,
                                offset:
                                    Offset(0, 1),
                              ),
                            ],
                          ),
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
