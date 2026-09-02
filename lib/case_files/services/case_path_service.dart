import '../data/animal_kingdom_case_data.dart';
import '../data/round_the_world_missions.dart';
import '../data/secrets_of_the_past_missions.dart';
import '../data/taste_and_treats_missions.dart';
import '../models/case_mission.dart';
import '../models/case_progress.dart';
import '../models/gameplay_result_event.dart';
import 'case_progress_service.dart';
import 'case_progress_storage_service.dart';
import 'case_tracking_service.dart';

class CasePathService {
  CasePathService._();

  static const String animalKingdomCasePathId =
      'animal_kingdom';

  static const int animalKingdomTotalStages = 20;


  static const String roundTheWorldCasePathId =
      'round_the_world';

  static const int roundTheWorldTotalStages = 20;

  static const String secretsOfThePastCasePathId =
      'secrets_of_the_past';

  static const int secretsOfThePastTotalStages = 20;

  static const String tasteAndTreatsCasePathId =
      'taste_and_treats';

  static const int tasteAndTreatsTotalStages = 20;

  static const CaseTrackingService _trackingService =
      CaseTrackingService();

  static const CaseProgressService _progressService =
      CaseProgressService(
    trackingService: _trackingService,
  );

  static Future<CaseProgress>
      loadAnimalKingdomProgress() async {
    final CaseProgress? savedProgress =
        await CaseProgressStorageService.loadProgress(
      casePathId: animalKingdomCasePathId,
    );

    if (savedProgress != null) {
      return savedProgress;
    }

    final CaseProgress initialProgress =
        _progressService.createInitialProgress(
      casePathId: animalKingdomCasePathId,
      totalStages: animalKingdomTotalStages,
    );

    await CaseProgressStorageService.saveProgress(
      initialProgress,
    );

    return initialProgress;
  }

  static CaseMission? animalKingdomMissionForStage(
    int stage,
  ) {
    if (stage < 1 ||
        stage > animalKingdomCaseMissions.length) {
      return null;
    }

    return animalKingdomCaseMissions[stage - 1];
  }

  static CaseMission?
      currentAnimalKingdomMission(
    CaseProgress progress,
  ) {
    if (progress.isCompleted) {
      return null;
    }

    return animalKingdomMissionForStage(
      progress.currentStage,
    );
  }

  static Future<CaseProgress>
      recordAnimalKingdomResult({
    required GameplayResultEvent event,
  }) async {
    final CaseProgress currentProgress =
        await loadAnimalKingdomProgress();

    if (currentProgress.isCompleted) {
      return currentProgress;
    }

    final CaseMission? mission =
        currentAnimalKingdomMission(
      currentProgress,
    );

    if (mission == null) {
      return currentProgress;
    }

    final CaseStageProgress updatedStageProgress =
        _trackingService.applyResult(
      mission: mission,
      progress:
          currentProgress.currentStageProgress,
      event: event,
    );

    if (_sameStageProgress(
      currentProgress.currentStageProgress,
      updatedStageProgress,
    )) {
      return currentProgress;
    }

    final CaseProgress updatedCaseProgress =
        _progressService.applyStageProgress(
      caseProgress: currentProgress,
      mission: mission,
      updatedStageProgress:
          updatedStageProgress,
      updatedAt: event.completedAt,
    );

    await CaseProgressStorageService.saveProgress(
      updatedCaseProgress,
    );

    return updatedCaseProgress;
  }

  static bool isAnimalKingdomStageCompleted({
    required CaseProgress progress,
    required int stage,
  }) {
    return _progressService.isStageCompleted(
      caseProgress: progress,
      stage: stage,
    );
  }

  static bool isAnimalKingdomStageCurrent({
    required CaseProgress progress,
    required int stage,
  }) {
    return _progressService.isStageCurrent(
      caseProgress: progress,
      stage: stage,
    );
  }

  static bool isAnimalKingdomStageLocked({
    required CaseProgress progress,
    required int stage,
  }) {
    return _progressService.isStageLocked(
      caseProgress: progress,
      stage: stage,
    );
  }

  static Future<void>
      resetAnimalKingdomProgress() async {
    await CaseProgressStorageService.clearProgress(
      casePathId: animalKingdomCasePathId,
    );
  }

  static Future<CaseProgress>
      loadRoundTheWorldProgress() async {
    final CaseProgress? savedProgress =
        await CaseProgressStorageService.loadProgress(
      casePathId: roundTheWorldCasePathId,
    );

    if (savedProgress != null) {
      return savedProgress;
    }

    final CaseProgress initialProgress =
        _progressService.createInitialProgress(
      casePathId: roundTheWorldCasePathId,
      totalStages: roundTheWorldTotalStages,
    );

    await CaseProgressStorageService.saveProgress(
      initialProgress,
    );

    return initialProgress;
  }

  static CaseMission? roundTheWorldMissionForStage(
    int stage,
  ) {
    if (stage < 1 ||
        stage > roundTheWorldCaseMissions.length) {
      return null;
    }

    return roundTheWorldCaseMissions[stage - 1];
  }

  static CaseMission? currentRoundTheWorldMission(
    CaseProgress progress,
  ) {
    if (progress.isCompleted) {
      return null;
    }

    return roundTheWorldMissionForStage(
      progress.currentStage,
    );
  }

  static Future<CaseProgress>
      recordRoundTheWorldResult({
    required GameplayResultEvent event,
  }) async {
    final CaseProgress currentProgress =
        await loadRoundTheWorldProgress();

    if (currentProgress.isCompleted) {
      return currentProgress;
    }

    final CaseMission? mission =
        currentRoundTheWorldMission(
      currentProgress,
    );

    if (mission == null) {
      return currentProgress;
    }

    final CaseStageProgress updatedStageProgress =
        _trackingService.applyResult(
      mission: mission,
      progress:
          currentProgress.currentStageProgress,
      event: event,
    );

    if (_sameStageProgress(
      currentProgress.currentStageProgress,
      updatedStageProgress,
    )) {
      return currentProgress;
    }

    final CaseProgress updatedCaseProgress =
        _progressService.applyStageProgress(
      caseProgress: currentProgress,
      mission: mission,
      updatedStageProgress:
          updatedStageProgress,
      updatedAt: event.completedAt,
    );

    await CaseProgressStorageService.saveProgress(
      updatedCaseProgress,
    );

    return updatedCaseProgress;
  }

  static bool isRoundTheWorldStageCompleted({
    required CaseProgress progress,
    required int stage,
  }) {
    return _progressService.isStageCompleted(
      caseProgress: progress,
      stage: stage,
    );
  }

  static bool isRoundTheWorldStageCurrent({
    required CaseProgress progress,
    required int stage,
  }) {
    return _progressService.isStageCurrent(
      caseProgress: progress,
      stage: stage,
    );
  }

  static bool isRoundTheWorldStageLocked({
    required CaseProgress progress,
    required int stage,
  }) {
    return _progressService.isStageLocked(
      caseProgress: progress,
      stage: stage,
    );
  }

  static Future<void>
      resetRoundTheWorldProgress() async {
    await CaseProgressStorageService.clearProgress(
      casePathId: roundTheWorldCasePathId,
    );
  }

  static Future<CaseProgress>
      loadSecretsOfThePastProgress() async {
    final CaseProgress? savedProgress =
        await CaseProgressStorageService.loadProgress(
      casePathId: secretsOfThePastCasePathId,
    );

    if (savedProgress != null) {
      return savedProgress;
    }

    final CaseProgress initialProgress =
        _progressService.createInitialProgress(
      casePathId: secretsOfThePastCasePathId,
      totalStages: secretsOfThePastTotalStages,
    );

    await CaseProgressStorageService.saveProgress(
      initialProgress,
    );

    return initialProgress;
  }

  static CaseMission? secretsOfThePastMissionForStage(
    int stage,
  ) {
    if (stage < 1 ||
        stage > secretsOfThePastCaseMissions.length) {
      return null;
    }

    return secretsOfThePastCaseMissions[stage - 1];
  }

  static CaseMission? currentSecretsOfThePastMission(
    CaseProgress progress,
  ) {
    if (progress.isCompleted) {
      return null;
    }

    return secretsOfThePastMissionForStage(
      progress.currentStage,
    );
  }

  static Future<CaseProgress>
      recordSecretsOfThePastResult({
    required GameplayResultEvent event,
  }) async {
    final CaseProgress currentProgress =
        await loadSecretsOfThePastProgress();

    if (currentProgress.isCompleted) {
      return currentProgress;
    }

    final CaseMission? mission =
        currentSecretsOfThePastMission(
      currentProgress,
    );

    if (mission == null) {
      return currentProgress;
    }

    final CaseStageProgress updatedStageProgress =
        _trackingService.applyResult(
      mission: mission,
      progress: currentProgress.currentStageProgress,
      event: event,
    );

    if (_sameStageProgress(
      currentProgress.currentStageProgress,
      updatedStageProgress,
    )) {
      return currentProgress;
    }

    final CaseProgress updatedCaseProgress =
        _progressService.applyStageProgress(
      caseProgress: currentProgress,
      mission: mission,
      updatedStageProgress: updatedStageProgress,
      updatedAt: event.completedAt,
    );

    await CaseProgressStorageService.saveProgress(
      updatedCaseProgress,
    );

    return updatedCaseProgress;
  }

  static bool isSecretsOfThePastStageCompleted({
    required CaseProgress progress,
    required int stage,
  }) {
    return _progressService.isStageCompleted(
      caseProgress: progress,
      stage: stage,
    );
  }

  static bool isSecretsOfThePastStageCurrent({
    required CaseProgress progress,
    required int stage,
  }) {
    return _progressService.isStageCurrent(
      caseProgress: progress,
      stage: stage,
    );
  }

  static bool isSecretsOfThePastStageLocked({
    required CaseProgress progress,
    required int stage,
  }) {
    return _progressService.isStageLocked(
      caseProgress: progress,
      stage: stage,
    );
  }

  static Future<void>
      resetSecretsOfThePastProgress() async {
    await CaseProgressStorageService.clearProgress(
      casePathId: secretsOfThePastCasePathId,
    );
  }

  static Future<CaseProgress>
      loadTasteAndTreatsProgress() async {
    final CaseProgress? savedProgress =
        await CaseProgressStorageService.loadProgress(
      casePathId: tasteAndTreatsCasePathId,
    );

    if (savedProgress != null) {
      return savedProgress;
    }

    final CaseProgress initialProgress =
        _progressService.createInitialProgress(
      casePathId: tasteAndTreatsCasePathId,
      totalStages: tasteAndTreatsTotalStages,
    );

    await CaseProgressStorageService.saveProgress(
      initialProgress,
    );

    return initialProgress;
  }

  static CaseMission? tasteAndTreatsMissionForStage(
    int stage,
  ) {
    if (stage < 1 ||
        stage > tasteAndTreatsCaseMissions.length) {
      return null;
    }

    return tasteAndTreatsCaseMissions[stage - 1];
  }

  static CaseMission? currentTasteAndTreatsMission(
    CaseProgress progress,
  ) {
    if (progress.isCompleted) {
      return null;
    }

    return tasteAndTreatsMissionForStage(
      progress.currentStage,
    );
  }

  static Future<CaseProgress>
      recordTasteAndTreatsResult({
    required GameplayResultEvent event,
  }) async {
    final CaseProgress currentProgress =
        await loadTasteAndTreatsProgress();

    if (currentProgress.isCompleted) {
      return currentProgress;
    }

    final CaseMission? mission =
        currentTasteAndTreatsMission(
      currentProgress,
    );

    if (mission == null) {
      return currentProgress;
    }

    final CaseStageProgress updatedStageProgress =
        _trackingService.applyResult(
      mission: mission,
      progress: currentProgress.currentStageProgress,
      event: event,
    );

    if (_sameStageProgress(
      currentProgress.currentStageProgress,
      updatedStageProgress,
    )) {
      return currentProgress;
    }

    final CaseProgress updatedCaseProgress =
        _progressService.applyStageProgress(
      caseProgress: currentProgress,
      mission: mission,
      updatedStageProgress: updatedStageProgress,
      updatedAt: event.completedAt,
    );

    await CaseProgressStorageService.saveProgress(
      updatedCaseProgress,
    );

    return updatedCaseProgress;
  }

  static bool isTasteAndTreatsStageCompleted({
    required CaseProgress progress,
    required int stage,
  }) {
    return _progressService.isStageCompleted(
      caseProgress: progress,
      stage: stage,
    );
  }

  static bool isTasteAndTreatsStageCurrent({
    required CaseProgress progress,
    required int stage,
  }) {
    return _progressService.isStageCurrent(
      caseProgress: progress,
      stage: stage,
    );
  }

  static bool isTasteAndTreatsStageLocked({
    required CaseProgress progress,
    required int stage,
  }) {
    return _progressService.isStageLocked(
      caseProgress: progress,
      stage: stage,
    );
  }

  static Future<void>
      resetTasteAndTreatsProgress() async {
    await CaseProgressStorageService.clearProgress(
      casePathId: tasteAndTreatsCasePathId,
    );
  }

  /// DEBUG / QA ONLY.
  ///
  /// Rebuilds Animal Kingdom entirely in memory to 19/20, then saves
  /// that single final QA state. This avoids repeatedly reloading an
  /// older completed cloud copy while the reset is being rebuilt.
  ///
  /// Result: Cases 1-19 completed, Case 20 active and fresh at 0.
  static Future<CaseProgress>
      qaResetAnimalKingdomTo19Of20() async {
    await resetAnimalKingdomProgress();

    CaseProgress progress =
        _progressService.createInitialProgress(
      casePathId: animalKingdomCasePathId,
      totalStages: animalKingdomTotalStages,
    );

    int eventNumber = 0;

    while (!progress.isCompleted &&
        progress.currentStage <
            animalKingdomTotalStages) {
      final CaseMission? mission =
          currentAnimalKingdomMission(progress);

      if (mission == null) {
        throw StateError(
          'QA reset could not load Animal Kingdom '
          'Case ${progress.currentStage}.',
        );
      }

      final int stageBeingCompleted = mission.stage;
      final String qaSubcategory =
          mission.subcategory ?? 'mammals';

      while (!progress.isCompleted &&
          progress.currentStage ==
              stageBeingCompleted) {
        eventNumber++;

        final DateTime completedAt =
            DateTime.now().add(
          Duration(milliseconds: eventNumber),
        );

        final GameplayResultEvent event =
            GameplayResultEvent(
          attemptId:
              'qa_case_${mission.stage}_$eventNumber',
          questionId:
              'qa_case_${mission.stage}_question_$eventNumber',
          category: 'animals',
          subcategory: qaSubcategory,
          correct: true,
          clueNumberSolved: 1,
          firstGuess: true,
          practiceMode: true,
          completedAt: completedAt,
        );

        final CaseStageProgress
            updatedStageProgress =
            _trackingService.applyResult(
          mission: mission,
          progress:
              progress.currentStageProgress,
          event: event,
        );

        if (_sameStageProgress(
          progress.currentStageProgress,
          updatedStageProgress,
        )) {
          throw StateError(
            'QA reset made no progress on '
            'Animal Kingdom Case $stageBeingCompleted.',
          );
        }

        progress =
            _progressService.applyStageProgress(
          caseProgress: progress,
          mission: mission,
          updatedStageProgress:
              updatedStageProgress,
          updatedAt: completedAt,
        );

        if (eventNumber > 1000) {
          throw StateError(
            'QA reset exceeded its safety limit.',
          );
        }
      }
    }

    if (progress.isCompleted ||
        progress.currentStage != 20 ||
        progress.completedStageCount != 19 ||
        progress.currentStageProgress.stage != 20 ||
        progress.currentStageProgress.correctCount != 0 ||
        progress.currentStageProgress
                .clueThresholdCount !=
            0 ||
        progress.currentStageProgress.firstGuessCount !=
            0) {
      throw StateError(
        'QA reset expected 19/20 with Case 20 '
        'fresh and active, but got '
        '${progress.completedStageCount}/'
        '${progress.totalStages}, '
        'Case ${progress.currentStage}, '
        '${progress.currentStageProgress.correctCount} correct.',
      );
    }

    await CaseProgressStorageService.saveProgress(
      progress,
    );

    return progress;
  }

  static bool _sameStageProgress(
    CaseStageProgress first,
    CaseStageProgress second,
  ) {
    return first.stage == second.stage &&
        first.correctCount ==
            second.correctCount &&
        first.clueThresholdCount ==
            second.clueThresholdCount &&
        first.firstGuessCount ==
            second.firstGuessCount &&
        first.lastProcessedAttemptId ==
            second.lastProcessedAttemptId &&
        _sameDate(
          first.startedAt,
          second.startedAt,
        ) &&
        _sameDate(
          first.completedAt,
          second.completedAt,
        );
  }

  static bool _sameDate(
    DateTime? first,
    DateTime? second,
  ) {
    if (first == null && second == null) {
      return true;
    }

    if (first == null || second == null) {
      return false;
    }

    return first.toUtc() == second.toUtc();
  }
}
