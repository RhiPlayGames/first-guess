import 'package:flutter/material.dart';

import '../../screens/game_screen.dart';
import '../../services/firebase_challenge_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/app_home_button.dart';

class AnimalKingdomMissionScreen extends StatelessWidget {
  const AnimalKingdomMissionScreen({super.key});

  Future<void> _startMission(BuildContext context) async {
    final items = await FirebaseChallengeService.loadLiveSubcategory(
      category: 'animals',
      subcategory: 'dinosaurs',
    );

    if (!context.mounted) {
      return;
    }

    if (items.isEmpty) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            backgroundColor: AppColors.panel,
            behavior: SnackBarBehavior.floating,
            content: Text(
              'No live Dinosaurs questions were found.',
              style: AppTextStyles.body.copyWith(
                color: AppColors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        );
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => GameScreen.dinosaurs(
          items: items,
        ),
      ),
    );
  }

  static const String _mapAsset =
      'assets/images/case_paths/animal_kingdom/animal_kingdom_map.webp';

  static const String _progressPanelAsset =
      'assets/images/case_paths/animal_kingdom/case_progress_panel.webp';

  static const String _missionCardAsset =
      'assets/images/case_paths/animal_kingdom/animal_kingdom_mission_card.webp';

  static const String _animalsImage =
      'assets/images/case_paths/animal_kingdom/animal_kingdom_main.webp';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                _mapAsset,
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
            SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                16,
                8,
                16,
                24,
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
                    'CASE 2',
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
                  const _MissionProgressPanel(),
                  const SizedBox(height: 8),
                  _MissionCard(
                    onStartMission: () => _startMission(context),
                  ),
                ],
              ),
            ),
          ],
        ),
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
  const _MissionProgressPanel();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 72,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            AnimalKingdomMissionScreen._progressPanelAsset,
            fit: BoxFit.fill,
            filterQuality: FilterQuality.high,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              30,
              12,
              18,
              10,
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 104,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        'CASE PROGRESS',
                        style:
                            AppTextStyles.category.copyWith(
                          color: Colors.white,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w900,
                          height: 1,
                          letterSpacing: -0.2,
                          shadows: const [
                            Shadow(
                              color: Colors.black,
                              blurRadius: 1.2,
                              offset: Offset(-0.8, 0),
                            ),
                            Shadow(
                              color: Colors.black,
                              blurRadius: 1.2,
                              offset: Offset(0.8, 0),
                            ),
                            Shadow(
                              color: Colors.black,
                              blurRadius: 1.2,
                              offset: Offset(0, -0.8),
                            ),
                            Shadow(
                              color: Colors.black,
                              blurRadius: 1.2,
                              offset: Offset(0, 0.8),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '0 / 20',
                        style:
                            AppTextStyles.label.copyWith(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          height: 1,
                          shadows: const [
                            Shadow(
                              color: Colors.black,
                              offset: Offset(-1, 0),
                            ),
                            Shadow(
                              color: Colors.black,
                              offset: Offset(1, 0),
                            ),
                            Shadow(
                              color: Colors.black,
                              offset: Offset(0, -1),
                            ),
                            Shadow(
                              color: Colors.black,
                              offset: Offset(0, 1),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Container(
                    height: 13,
                    decoration: BoxDecoration(
                      color: const Color(0xFF28261D),
                      borderRadius:
                          BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFF4B412C),
                        width: 1.2,
                      ),
                    ),
                    padding: const EdgeInsets.all(2),
                  ),
                ),
                const SizedBox(width: 4),
                Container(
                  width: 34,
                  height: 34,
                  margin: const EdgeInsets.only(right: 7),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFE5E02),
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
                    size: 20,
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
  final VoidCallback onStartMission;

  const _MissionCard({
    required this.onStartMission,
  });

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1008 / 1254,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final height = constraints.maxHeight;

          return Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(
                AnimalKingdomMissionScreen._missionCardAsset,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.high,
              ),

              // Shared high-resolution Animal Kingdom image.
              Positioned(
                left: width * 0.095,
                right: width * 0.095,
                top: height * 0.145,
                height: height * 0.305,
                child: Image.asset(
                  AnimalKingdomMissionScreen._animalsImage,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.high,
                ),
              ),

              // Mission wording fits entirely inside the parchment panel.
              Positioned(
                left: width * 0.10,
                right: width * 0.10,
                top: height * 0.535,
                height: height * 0.155,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'YOUR MISSION',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.category.copyWith(
                        color: const Color(0xFFFE5E02),
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.35,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'GET 10 DINOSAURS QUESTIONS CORRECT',
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

              // Clickable text placed over the built-in orange button.
              Positioned(
                left: width * 0.17,
                right: width * 0.17,
                top: height * 0.718,
                height: height * 0.092,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: onStartMission,
                    borderRadius: BorderRadius.circular(16),
                    child: Center(
                      child: Text(
                        'START MISSION',
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

              // HOW IT WORKS is centred on the same axis as START MISSION.
              Positioned(
                left: width * 0.17,
                right: width * 0.17,
                top: height * 0.835,
                height: height * 0.110,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment:
                      CrossAxisAlignment.center,
                  children: [
                    Text(
                      'HOW IT WORKS',
                      maxLines: 1,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.category.copyWith(
                        color: Colors.white,
                        fontSize: 15.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.2,
                        height: 1,
                        shadows: const [
                          Shadow(
                            color: Colors.black,
                            blurRadius: 2,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Get correct answers in the Animals category\n'
                      'to complete this mission.',
                      maxLines: 2,
                      softWrap: true,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.body.copyWith(
                        color: Colors.white,
                        fontSize: 12.2,
                        fontWeight: FontWeight.w800,
                        height: 1.08,
                        letterSpacing: -0.05,
                        shadows: const [
                          Shadow(
                            color: Colors.black,
                            blurRadius: 2,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}