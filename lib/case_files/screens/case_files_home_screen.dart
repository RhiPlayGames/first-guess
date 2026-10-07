import 'package:flutter/material.dart';

import '../../services/analytics_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_home_button.dart';
import '../models/case_progress.dart';
import '../services/case_path_service.dart';
import 'animal_kingdom_case_path_screen.dart';
import 'round_the_world_case_path_screen.dart';
import 'secrets_of_the_past_case_path_screen.dart';
import 'taste_and_treats_case_path_screen.dart';
import 'nature_of_discovery_case_path_screen.dart';
import 'the_written_word_case_path_screen.dart';
import 'the_creative_code_case_path_screen.dart';

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
  CaseProgress? _natureOfDiscoveryProgress;
  CaseProgress? _theWrittenWordProgress;
  CaseProgress? _theCreativeCodeProgress;

  @override
  void initState() {
    super.initState();
    _loadAnimalKingdomProgress();
    _loadRoundTheWorldProgress();
    _loadSecretsOfThePastProgress();
    _loadTasteAndTreatsProgress();
    _loadNatureOfDiscoveryProgress();
    _loadTheWrittenWordProgress();
    _loadTheCreativeCodeProgress();
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
    await AnalyticsService.logCaseFileStarted(
      caseKey: 'around_the_world',
      caseName: 'Around the World',
      resume: _roundTheWorldStarted,
    );

    if (!mounted) {
      return;
    }

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
    await AnalyticsService.logCaseFileStarted(
      caseKey: 'animal_kingdom',
      caseName: 'Animal Kingdom',
      resume: _animalKingdomStarted,
    );

    if (!mounted) {
      return;
    }

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
    await AnalyticsService.logCaseFileStarted(
      caseKey: 'secrets_of_the_past',
      caseName: 'Secrets of the Past',
      resume: _secretsOfThePastStarted,
    );

    if (!mounted) {
      return;
    }

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
    await AnalyticsService.logCaseFileStarted(
      caseKey: 'taste_and_treats',
      caseName: 'Tastes & Treats',
      resume: _tasteAndTreatsStarted,
    );

    if (!mounted) {
      return;
    }

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

  Future<void> _loadNatureOfDiscoveryProgress() async {
    try {
      final CaseProgress progress =
          await CasePathService.loadNatureOfDiscoveryProgress();

      if (!mounted) {
        return;
      }

      setState(() {
        _natureOfDiscoveryProgress = progress;
      });
    } catch (_) {
      // Keep the card usable if progress cannot be loaded.
    }
  }

  bool get _natureOfDiscoveryStarted {
    final CaseProgress? progress = _natureOfDiscoveryProgress;

    if (progress == null) {
      return false;
    }

    final stage = progress.currentStageProgress;

    return progress.completedStageCount > 0 ||
        stage.correctCount > 0 ||
        stage.clueThresholdCount > 0 ||
        stage.firstGuessCount > 0;
  }

  String get _natureOfDiscoveryStatus {
    final CaseProgress? progress = _natureOfDiscoveryProgress;

    if (progress == null) {
      return 'CASE 1';
    }

    if (progress.isCompleted) {
      return '';
    }

    return 'CASE ${progress.currentStage}';
  }

  String get _natureOfDiscoveryButtonLabel {
    final CaseProgress? progress = _natureOfDiscoveryProgress;

    if (progress?.isCompleted ?? false) {
      return 'COMPLETED';
    }

    return _natureOfDiscoveryStarted
        ? 'IN PROGRESS'
        : 'VIEW CASE';
  }

  Future<void> _openNatureOfDiscoveryCase() async {
    await AnalyticsService.logCaseFileStarted(
      caseKey: 'nature_of_discovery',
      caseName: 'Nature of Discovery',
      resume: _natureOfDiscoveryStarted,
    );

    if (!mounted) {
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) =>
            const NatureOfDiscoveryCasePathScreen(),
      ),
    );

    if (!mounted) {
      return;
    }

    await _loadNatureOfDiscoveryProgress();
  }

  Future<void> _loadTheWrittenWordProgress() async {
    try {
      final CaseProgress progress =
          await CasePathService.loadTheWrittenWordProgress();

      if (!mounted) {
        return;
      }

      setState(() {
        _theWrittenWordProgress = progress;
      });
    } catch (_) {
      // Keep the card usable if progress cannot be loaded.
    }
  }

  bool get _theWrittenWordStarted {
    final CaseProgress? progress = _theWrittenWordProgress;

    if (progress == null) {
      return false;
    }

    final stage = progress.currentStageProgress;

    return progress.completedStageCount > 0 ||
        stage.correctCount > 0 ||
        stage.clueThresholdCount > 0 ||
        stage.firstGuessCount > 0;
  }

  String get _theWrittenWordStatus {
    final CaseProgress? progress = _theWrittenWordProgress;

    if (progress == null) {
      return 'CASE 1';
    }

    if (progress.isCompleted) {
      return '';
    }

    return 'CASE ${progress.currentStage}';
  }

  String get _theWrittenWordButtonLabel {
    final CaseProgress? progress = _theWrittenWordProgress;

    if (progress?.isCompleted ?? false) {
      return 'COMPLETED';
    }

    return _theWrittenWordStarted
        ? 'IN PROGRESS'
        : 'VIEW CASE';
  }

  Future<void> _openTheWrittenWordCase() async {
    await AnalyticsService.logCaseFileStarted(
      caseKey: 'the_written_word',
      caseName: 'The Written Word',
      resume: _theWrittenWordStarted,
    );

    if (!mounted) {
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) =>
            const TheWrittenWordCasePathScreen(),
      ),
    );

    if (!mounted) {
      return;
    }

    await _loadTheWrittenWordProgress();
  }

  Future<void> _loadTheCreativeCodeProgress() async {
    try {
      final CaseProgress progress =
          await CasePathService.loadTheCreativeCodeProgress();

      if (!mounted) {
        return;
      }

      setState(() {
        _theCreativeCodeProgress = progress;
      });
    } catch (_) {
      // Keep the card usable if progress cannot be loaded.
    }
  }

  bool get _theCreativeCodeStarted {
    final CaseProgress? progress = _theCreativeCodeProgress;

    if (progress == null) {
      return false;
    }

    final stage = progress.currentStageProgress;

    return progress.completedStageCount > 0 ||
        stage.correctCount > 0 ||
        stage.clueThresholdCount > 0 ||
        stage.firstGuessCount > 0;
  }

  String get _theCreativeCodeStatus {
    final CaseProgress? progress = _theCreativeCodeProgress;

    if (progress == null) {
      return 'CASE 1';
    }

    if (progress.isCompleted) {
      return '';
    }

    return 'CASE ${progress.currentStage}';
  }

  String get _theCreativeCodeButtonLabel {
    final CaseProgress? progress = _theCreativeCodeProgress;

    if (progress?.isCompleted ?? false) {
      return 'COMPLETED';
    }

    return _theCreativeCodeStarted
        ? 'IN PROGRESS'
        : 'VIEW CASE';
  }

  Future<void> _openTheCreativeCodeCase() async {
    await AnalyticsService.logCaseFileStarted(
      caseKey: 'the_creative_code',
      caseName: 'The Creative Code',
      resume: _theCreativeCodeStarted,
    );

    if (!mounted) {
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) =>
            const TheCreativeCodeCasePathScreen(),
      ),
    );

    if (!mounted) {
      return;
    }

    await _loadTheCreativeCodeProgress();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDesktop =
        MediaQuery.sizeOf(context).width >= 1200;

    final Widget animalKingdomCard = _CaseFileCard(
      imagePath:
          (_animalKingdomProgress?.isCompleted ?? false)
              ? 'assets/images/case_files/New folder/animalkingdom_completed.webp'
              : _animalKingdomStarted
                  ? 'assets/images/case_files/New folder/animalkingdom_inprogress.webp'
                  : 'assets/images/case_files/New folder/animalkingdom_start.webp',
      status: _animalKingdomStatus,
      buttonLabel: _animalKingdomButtonLabel,
      onTap: _openAnimalKingdomCase,
    );

    final Widget roundTheWorldCard = _CaseFileCard(
      imagePath:
          (_roundTheWorldProgress?.isCompleted ?? false)
              ? 'assets/images/case_files/New folder/aroundtheworld_completed.webp'
              : _roundTheWorldStarted
                  ? 'assets/images/case_files/New folder/aroundtheworld_progress.webp'
                  : 'assets/images/case_files/New folder/aroundtheworld_start.webp',
      status: _roundTheWorldStatus,
      buttonLabel: _roundTheWorldButtonLabel,
      onTap: _openRoundTheWorldCase,
    );

    final Widget secretsOfThePastCard = _CaseFileCard(
      imagePath:
          (_secretsOfThePastProgress?.isCompleted ?? false)
              ? 'assets/images/case_files/New folder/tasteofmysterycompleted.webp'
              : _secretsOfThePastStarted
                  ? 'assets/images/case_files/New folder/tasteofmysteryprogress.webp'
                  : 'assets/images/case_files/New folder/tasteofmysterystart.webp',
      status: _secretsOfThePastStatus,
      buttonLabel: _secretsOfThePastButtonLabel,
      onTap: _openSecretsOfThePastCase,
    );

    final Widget tasteAndTreatsCard = _CaseFileCard(
      imagePath:
          (_tasteAndTreatsProgress?.isCompleted ?? false)
              ? 'assets/images/case_files/New folder/tasteofmystery_completed.webp'
              : _tasteAndTreatsStarted
                  ? 'assets/images/case_files/New folder/tasteofmystery_progress.webp'
                  : 'assets/images/case_files/New folder/tasteofmystery_start.webp',
      status: _tasteAndTreatsStatus,
      buttonLabel: _tasteAndTreatsButtonLabel,
      onTap: _openTasteAndTreatsCase,
      imageScale: 0.95,
    );

    final Widget natureOfDiscoveryCard = _CaseFileCard(
      imagePath:
          (_natureOfDiscoveryProgress?.isCompleted ?? false)
              ? 'assets/images/case_files/New folder/the_nature_of_discovery_completed_transparent.webp'
              : _natureOfDiscoveryStarted
                  ? 'assets/images/case_files/New folder/the_nature_of_discovery_in_progress_transparent.webp'
                  : 'assets/images/case_files/New folder/the_nature_of_discovery_start_transparent.webp',
      status: _natureOfDiscoveryStatus,
      buttonLabel: _natureOfDiscoveryButtonLabel,
      onTap: _openNatureOfDiscoveryCase,
    );

    final Widget theWrittenWordCard = _CaseFileCard(
      imagePath:
          (_theWrittenWordProgress?.isCompleted ?? false)
              ? 'assets/images/case_files/New folder/the_written_word_completed_transparent.webp'
              : _theWrittenWordStarted
                  ? 'assets/images/case_files/New folder/the_written_word_in_progress_transparent.webp'
                  : 'assets/images/case_files/New folder/the_written_word_start_transparent.webp',
      status: _theWrittenWordStatus,
      buttonLabel: _theWrittenWordButtonLabel,
      onTap: _openTheWrittenWordCase,
    );

    final Widget theCreativeCodeCard = _CaseFileCard(
      imagePath:
          (_theCreativeCodeProgress?.isCompleted ?? false)
              ? 'assets/images/case_files/New folder/creativecode_completed.webp'
              : _theCreativeCodeStarted
                  ? 'assets/images/case_files/New folder/creativecode_inprogress.webp'
                  : 'assets/images/case_files/New folder/creativecode_start.webp',
      status: _theCreativeCodeStatus,
      buttonLabel: _theCreativeCodeButtonLabel,
      onTap: _openTheCreativeCodeCase,
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            isDesktop ? 24 : 6,
            8,
            isDesktop ? 24 : 6,
            18,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _CaseFilesHeader(
                onBackPressed: () => Navigator.of(context).pop(),
              ),
              SizedBox(height: isDesktop ? 18 : 8),
              if (isDesktop)
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: 1400,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: animalKingdomCard),
                            const SizedBox(width: 18),
                            Expanded(child: roundTheWorldCard),
                            const SizedBox(width: 18),
                            Expanded(child: secretsOfThePastCard),
                            const SizedBox(width: 18),
                            Expanded(child: tasteAndTreatsCard),
                          ],
                        ),
                        const SizedBox(height: 18),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: (1400 - (18 * 3)) / 4,
                              child: natureOfDiscoveryCard,
                            ),
                            const SizedBox(width: 18),
                            SizedBox(
                              width: (1400 - (18 * 3)) / 4,
                              child: theWrittenWordCard,
                            ),
                            const SizedBox(width: 18),
                            SizedBox(
                              width: (1400 - (18 * 3)) / 4,
                              child: theCreativeCodeCard,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                )
              else ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: animalKingdomCard),
                    const SizedBox(width: 6),
                    Expanded(child: roundTheWorldCard),
                  ],
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: secretsOfThePastCard),
                    const SizedBox(width: 6),
                    Expanded(child: tasteAndTreatsCard),
                  ],
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: natureOfDiscoveryCard),
                    const SizedBox(width: 6),
                    Expanded(child: theWrittenWordCard),
                  ],
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: theCreativeCodeCard),
                    const SizedBox(width: 6),
                    const Expanded(child: SizedBox.shrink()),
                  ],
                ),
              ],
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
              'assets/images/categories/category_headers/classic_first_guess_logo.webp',
              height: 64,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
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

class _CaseFileCard extends StatelessWidget {
  final String imagePath;
  final String status;
  final String buttonLabel;
  final VoidCallback? onTap;
  final double imageScale;

  const _CaseFileCard({
    required this.imagePath,
    required this.status,
    this.buttonLabel = 'VIEW CASE',
    this.onTap,
    this.imageScale = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDesktop =
        MediaQuery.sizeOf(context).width >= 1200;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: AspectRatio(
          aspectRatio: isDesktop ? 0.92 : 1,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Transform.scale(
                scale: imageScale,
                child: Image.asset(
                  imagePath,
                  width: double.infinity,
                  height: double.infinity,
                  fit: BoxFit.contain,
                  alignment: Alignment.center,
                  filterQuality: FilterQuality.high,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
