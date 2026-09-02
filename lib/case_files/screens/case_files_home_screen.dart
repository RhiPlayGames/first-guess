import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../widgets/app_home_button.dart';
import '../models/case_progress.dart';
import '../services/case_path_service.dart';
import 'animal_kingdom_case_path_screen.dart';
import 'round_the_world_case_path_screen.dart';
import 'secrets_of_the_past_case_path_screen.dart';
import 'taste_and_treats_case_path_screen.dart';

class CaseFilesHomeScreen extends StatefulWidget {
  const CaseFilesHomeScreen({super.key});

  @override
  State<CaseFilesHomeScreen> createState() =>
      _CaseFilesHomeScreenState();
}

class _CaseFilesHomeScreenState
    extends State<CaseFilesHomeScreen> {
  CaseProgress? _animalKingdomProgress;
  CaseProgress? _roundTheWorldProgress;
  CaseProgress? _secretsOfThePastProgress;
  CaseProgress? _tasteAndTreatsProgress;

  @override
  void initState() {
    super.initState();
    _loadAnimalKingdomProgress();
    _loadRoundTheWorldProgress();
    _loadSecretsOfThePastProgress();
    _loadTasteAndTreatsProgress();
  }

  Future<void> _loadAnimalKingdomProgress() async {
    try {
      final CaseProgress progress =
          await CasePathService.loadAnimalKingdomProgress();

      if (!mounted) {
        return;
      }

      setState(() {
        _animalKingdomProgress = progress;
      });
    } catch (_) {
      // Keep the card usable if progress cannot be loaded.
    }
  }

  bool get _animalKingdomStarted {
    final CaseProgress? progress = _animalKingdomProgress;

    if (progress == null) {
      return false;
    }

    final stage = progress.currentStageProgress;

    return progress.completedStageCount > 0 ||
        stage.correctCount > 0 ||
        stage.clueThresholdCount > 0 ||
        stage.firstGuessCount > 0;
  }

  String get _animalKingdomStatus {
    final CaseProgress? progress = _animalKingdomProgress;

    if (progress == null) {
      return 'CASE 1';
    }

    if (progress.isCompleted) {
      return '';
    }

    return 'CASE ${progress.currentStage}';
  }

  String get _animalKingdomButtonLabel {
    final CaseProgress? progress = _animalKingdomProgress;

    if (progress?.isCompleted ?? false) {
      return 'COMPLETED';
    }

    return _animalKingdomStarted
        ? 'IN PROGRESS'
        : 'VIEW CASE';
  }

  Future<void> _loadRoundTheWorldProgress() async {
    try {
      final CaseProgress progress =
          await CasePathService.loadRoundTheWorldProgress();

      if (!mounted) {
        return;
      }

      setState(() {
        _roundTheWorldProgress = progress;
      });
    } catch (_) {
      // Keep the card usable if progress cannot be loaded.
    }
  }

  bool get _roundTheWorldStarted {
    final CaseProgress? progress = _roundTheWorldProgress;

    if (progress == null) {
      return false;
    }

    final stage = progress.currentStageProgress;

    return progress.completedStageCount > 0 ||
        stage.correctCount > 0 ||
        stage.clueThresholdCount > 0 ||
        stage.firstGuessCount > 0;
  }

  String get _roundTheWorldStatus {
    final CaseProgress? progress = _roundTheWorldProgress;

    if (progress == null) {
      return 'CASE 1';
    }

    if (progress.isCompleted) {
      return '';
    }

    return 'CASE ${progress.currentStage}';
  }

  String get _roundTheWorldButtonLabel {
    final CaseProgress? progress = _roundTheWorldProgress;

    if (progress?.isCompleted ?? false) {
      return 'COMPLETED';
    }

    return _roundTheWorldStarted
        ? 'IN PROGRESS'
        : 'VIEW CASE';
  }

  Future<void> _openRoundTheWorldCase() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) =>
            const RoundTheWorldCasePathScreen(),
      ),
    );

    if (!mounted) {
      return;
    }

    await _loadRoundTheWorldProgress();
  }

  Future<void> _openAnimalKingdomCase() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) =>
            const AnimalKingdomCasePathScreen(),
      ),
    );

    if (!mounted) {
      return;
    }

    await _loadAnimalKingdomProgress();
  }

  Future<void> _loadSecretsOfThePastProgress() async {
    try {
      final CaseProgress progress =
          await CasePathService.loadSecretsOfThePastProgress();

      if (!mounted) {
        return;
      }

      setState(() {
        _secretsOfThePastProgress = progress;
      });
    } catch (_) {
      // Keep the card usable if progress cannot be loaded.
    }
  }

  bool get _secretsOfThePastStarted {
    final CaseProgress? progress = _secretsOfThePastProgress;

    if (progress == null) {
      return false;
    }

    final stage = progress.currentStageProgress;

    return progress.completedStageCount > 0 ||
        stage.correctCount > 0 ||
        stage.clueThresholdCount > 0 ||
        stage.firstGuessCount > 0;
  }

  String get _secretsOfThePastStatus {
    final CaseProgress? progress = _secretsOfThePastProgress;

    if (progress == null) {
      return 'CASE 1';
    }

    if (progress.isCompleted) {
      return '';
    }

    return 'CASE ${progress.currentStage}';
  }

  String get _secretsOfThePastButtonLabel {
    final CaseProgress? progress = _secretsOfThePastProgress;

    if (progress?.isCompleted ?? false) {
      return 'COMPLETED';
    }

    return _secretsOfThePastStarted
        ? 'IN PROGRESS'
        : 'VIEW CASE';
  }

  Future<void> _openSecretsOfThePastCase() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) =>
            const SecretsOfThePastCasePathScreen(),
      ),
    );

    if (!mounted) {
      return;
    }

    await _loadSecretsOfThePastProgress();
  }

  Future<void> _loadTasteAndTreatsProgress() async {
    try {
      final CaseProgress progress =
          await CasePathService.loadTasteAndTreatsProgress();

      if (!mounted) {
        return;
      }

      setState(() {
        _tasteAndTreatsProgress = progress;
      });
    } catch (_) {
      // Keep the card usable if progress cannot be loaded.
    }
  }

  bool get _tasteAndTreatsStarted {
    final CaseProgress? progress = _tasteAndTreatsProgress;

    if (progress == null) {
      return false;
    }

    final stage = progress.currentStageProgress;

    return progress.completedStageCount > 0 ||
        stage.correctCount > 0 ||
        stage.clueThresholdCount > 0 ||
        stage.firstGuessCount > 0;
  }

  String get _tasteAndTreatsStatus {
    final CaseProgress? progress = _tasteAndTreatsProgress;

    if (progress == null) {
      return 'CASE 1';
    }

    if (progress.isCompleted) {
      return '';
    }

    return 'CASE ${progress.currentStage}';
  }

  String get _tasteAndTreatsButtonLabel {
    final CaseProgress? progress = _tasteAndTreatsProgress;

    if (progress?.isCompleted ?? false) {
      return 'COMPLETED';
    }

    return _tasteAndTreatsStarted
        ? 'IN PROGRESS'
        : 'VIEW CASE';
  }

  Future<void> _openTasteAndTreatsCase() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) =>
            const TasteAndTreatsCasePathScreen(),
      ),
    );

    if (!mounted) {
      return;
    }

    await _loadTasteAndTreatsProgress();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(6, 8, 6, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _CaseFilesHeader(
                onBackPressed: () => Navigator.of(context).pop(),
              ),
              const SizedBox(height: 3),
              const _CaseFilesHero(),
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _CaseFileCard(
                      imagePath:
                          (_animalKingdomProgress?.isCompleted ?? false)
                              ? 'assets/images/case_files/topics/animal_world_completed.webp'
                              : _animalKingdomStarted
                                  ? 'assets/images/case_files/topics/animal_world_inprogress.webp'
                                  : 'assets/images/case_files/topics/animal_world_final.webp',
                      status: _animalKingdomStatus,
                      buttonLabel: _animalKingdomButtonLabel,
                      onTap: _openAnimalKingdomCase,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: _CaseFileCard(
                      imagePath:
                          (_roundTheWorldProgress?.isCompleted ?? false)
                              ? 'assets/images/case_files/topics/amazing_world_complete.webp'
                              : _roundTheWorldStarted
                                  ? 'assets/images/case_files/topics/amazing_world_inprogress.webp'
                                  : 'assets/images/case_files/topics/amazing_world_final.webp',
                      status: _roundTheWorldStatus,
                      buttonLabel: _roundTheWorldButtonLabel,
                      onTap: _openRoundTheWorldCase,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 0),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _CaseFileCard(
                      imagePath:
                          (_secretsOfThePastProgress?.isCompleted ?? false)
                              ? 'assets/images/case_files/topics/mysteries_legends_complete.webp'
                              : _secretsOfThePastStarted
                                  ? 'assets/images/case_files/topics/mysteries_legends_inprogress.webp'
                                  : 'assets/images/case_files/topics/mysteries_legends_final.webp',
                      status: _secretsOfThePastStatus,
                      buttonLabel: _secretsOfThePastButtonLabel,
                      onTap: _openSecretsOfThePastCase,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: _CaseFileCard(
                      imagePath:
                          (_tasteAndTreatsProgress?.isCompleted ?? false)
                              ? 'assets/images/case_files/topics/tastes_and_treats_complete.webp'
                              : _tasteAndTreatsStarted
                                  ? 'assets/images/case_files/topics/tastes_and_treats_inprogress.webp'
                                  : 'assets/images/case_files/topics/tastes_and_treats_final.webp',
                      status: _tasteAndTreatsStatus,
                      buttonLabel: _tasteAndTreatsButtonLabel,
                      onTap: _openTasteAndTreatsCase,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

}

class _CaseFilesHeader extends StatelessWidget {
  final VoidCallback onBackPressed;

  const _CaseFilesHeader({
    required this.onBackPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 76,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              onPressed: onBackPressed,
              icon: const Icon(
                Icons.arrow_back_rounded,
                color: AppColors.white,
                size: 26,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 64,
            ),
            child: Image.asset(
              'assets/images/first_guess_header.png',
              height: 52,
              fit: BoxFit.contain,
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

class _CaseFilesHero extends StatelessWidget {
  const _CaseFilesHero();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Image.asset(
        'assets/images/case_files/case_file_explore_discover_solve.webp',
        width: double.infinity,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
      ),
    );
  }
}

class _CaseFileCard extends StatelessWidget {
  final String imagePath;
  final String status;
  final String buttonLabel;
  final VoidCallback? onTap;

  const _CaseFileCard({
    required this.imagePath,
    required this.status,
    this.buttonLabel = 'VIEW CASE',
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: AspectRatio(
          aspectRatio: 4 / 5,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(
                imagePath,
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.contain,
                alignment: Alignment.center,
                filterQuality: FilterQuality.high,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
