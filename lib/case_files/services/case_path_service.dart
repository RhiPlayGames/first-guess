import '../data/animal_kingdom_case_data.dart';
import '../data/round_the_world_missions.dart';
import '../data/secrets_of_the_past_missions.dart';
import '../data/taste_and_treats_missions.dart';
import '../data/nature_of_discovery_missions.dart';
import '../data/the_written_word_missions.dart';
import '../data/the_creative_code_missions.dart';
import '../models/case_mission.dart';
import '../models/case_progress.dart';
import '../models/gameplay_result_event.dart';
import 'case_progress_service.dart';
import 'case_progress_storage_service.dart';
import 'case_tracking_service.dart';

class CasePathService {
  CasePathService._();

  // TEMPORARY TEST MODE.
  // Set to false after Case Files testing is complete.
  // When true, progress is only PRESENTED as completed in memory so every
  // stage can be opened for testing. Saved local/cloud progress is not changed
  // by this unlock override.
  static const bool caseFileTestMode = true;

  static CaseProgress _applyCaseFileTestUnlock(
    CaseProgress progress,
  ) {
    if (!caseFileTestMode) {
      return progress;
    }

    return CaseProgress(
      casePathId: progress.casePathId,
      currentStage: progress.currentStage,
      totalStages: progress.totalStages,
      completedStages: List<int>.generate(
        progress.totalStages,
        (int index) => index + 1,
      ),
      isCompleted: true,
      currentStageProgress: progress.currentStageProgress,
      startedAt: progress.startedAt,
      updatedAt: progress.updatedAt,
      completedAt: progress.completedAt ?? DateTime.now(),
    );
  }

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

  static const String natureOfDiscoveryCasePathId =
      'nature_of_discovery';

  static const int natureOfDiscoveryTotalStages = 20;

  static const String theWrittenWordCasePathId =
      'the_written_word';

  static const int theWrittenWordTotalStages = 20;

  static const String theCreativeCodeCasePathId =
      'the_creative_code';

  static const int theCreativeCodeTotalStages = 20;

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
      return _applyCaseFileTestUnlock(savedProgress);
    }

    final CaseProgress initialProgress =
        _progressService.createInitialProgress(
      casePathId: animalKingdomCasePathId,
      totalStages: animalKingdomTotalStages,
    );

    await CaseProgressStorageService.saveProgress(
      initialProgress,
    );

    return _applyCaseFileTestUnlock(initialProgress);
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
    final CaseProgress fallbackProgress =
        await loadAnimalKingdomProgress();

    return CaseProgressStorageService
        .updateProgressTransactionally(
      casePathId: animalKingdomCasePathId,
      attemptId: event.attemptId,
      fallbackProgress: fallbackProgress,
      update: (CaseProgress currentProgress) {
        if (currentProgress.isCompleted) {
          return currentProgress;
        }

        final CaseMission? mission =
            animalKingdomMissionForStage(
          currentProgress.currentStage,
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

        return _progressService.applyStageProgress(
          caseProgress: currentProgress,
          mission: mission,
          updatedStageProgress: updatedStageProgress,
          updatedAt: event.completedAt,
        );
      },
    );
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
      return _applyCaseFileTestUnlock(savedProgress);
    }

    final CaseProgress initialProgress =
        _progressService.createInitialProgress(
      casePathId: roundTheWorldCasePathId,
      totalStages: roundTheWorldTotalStages,
    );

    await CaseProgressStorageService.saveProgress(
      initialProgress,
    );

    return _applyCaseFileTestUnlock(initialProgress);
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
    final CaseProgress fallbackProgress =
        await loadRoundTheWorldProgress();

    return CaseProgressStorageService
        .updateProgressTransactionally(
      casePathId: roundTheWorldCasePathId,
      attemptId: event.attemptId,
      fallbackProgress: fallbackProgress,
      update: (CaseProgress currentProgress) {
        if (currentProgress.isCompleted) {
          return currentProgress;
        }

        final CaseMission? mission =
            roundTheWorldMissionForStage(
          currentProgress.currentStage,
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

        return _progressService.applyStageProgress(
          caseProgress: currentProgress,
          mission: mission,
          updatedStageProgress: updatedStageProgress,
          updatedAt: event.completedAt,
        );
      },
    );
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
      return _applyCaseFileTestUnlock(savedProgress);
    }

    final CaseProgress initialProgress =
        _progressService.createInitialProgress(
      casePathId: secretsOfThePastCasePathId,
      totalStages: secretsOfThePastTotalStages,
    );

    await CaseProgressStorageService.saveProgress(
      initialProgress,
    );

    return _applyCaseFileTestUnlock(initialProgress);
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
    final CaseProgress fallbackProgress =
        await loadSecretsOfThePastProgress();

    return CaseProgressStorageService
        .updateProgressTransactionally(
      casePathId: secretsOfThePastCasePathId,
      attemptId: event.attemptId,
      fallbackProgress: fallbackProgress,
      update: (CaseProgress currentProgress) {
        if (currentProgress.isCompleted) {
          return currentProgress;
        }

        final CaseMission? mission =
            secretsOfThePastMissionForStage(
          currentProgress.currentStage,
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

        return _progressService.applyStageProgress(
          caseProgress: currentProgress,
          mission: mission,
          updatedStageProgress: updatedStageProgress,
          updatedAt: event.completedAt,
        );
      },
    );
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
      return _applyCaseFileTestUnlock(savedProgress);
    }

    final CaseProgress initialProgress =
        _progressService.createInitialProgress(
      casePathId: tasteAndTreatsCasePathId,
      totalStages: tasteAndTreatsTotalStages,
    );

    await CaseProgressStorageService.saveProgress(
      initialProgress,
    );

    return _applyCaseFileTestUnlock(initialProgress);
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
    final CaseProgress fallbackProgress =
        await loadTasteAndTreatsProgress();

    return CaseProgressStorageService
        .updateProgressTransactionally(
      casePathId: tasteAndTreatsCasePathId,
      attemptId: event.attemptId,
      fallbackProgress: fallbackProgress,
      update: (CaseProgress currentProgress) {
        if (currentProgress.isCompleted) {
          return currentProgress;
        }

        final CaseMission? mission =
            tasteAndTreatsMissionForStage(
          currentProgress.currentStage,
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

        return _progressService.applyStageProgress(
          caseProgress: currentProgress,
          mission: mission,
          updatedStageProgress: updatedStageProgress,
          updatedAt: event.completedAt,
        );
      },
    );
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

  static Future<CaseProgress>
      loadNatureOfDiscoveryProgress() async {
    final CaseProgress? savedProgress =
        await CaseProgressStorageService.loadProgress(
      casePathId: natureOfDiscoveryCasePathId,
    );

    if (savedProgress != null) {
      return _applyCaseFileTestUnlock(savedProgress);
    }

    final CaseProgress initialProgress =
        _progressService.createInitialProgress(
      casePathId: natureOfDiscoveryCasePathId,
      totalStages: natureOfDiscoveryTotalStages,
    );

    await CaseProgressStorageService.saveProgress(
      initialProgress,
    );

    return _applyCaseFileTestUnlock(initialProgress);
  }

  static CaseMission? natureOfDiscoveryMissionForStage(
    int stage,
  ) {
    if (stage < 1 ||
        stage > natureOfDiscoveryCaseMissions.length) {
      return null;
    }

    return natureOfDiscoveryCaseMissions[stage - 1];
  }

  static CaseMission? currentNatureOfDiscoveryMission(
    CaseProgress progress,
  ) {
    if (progress.isCompleted) {
      return null;
    }

    return natureOfDiscoveryMissionForStage(
      progress.currentStage,
    );
  }

  static Future<CaseProgress>
      recordNatureOfDiscoveryResult({
    required GameplayResultEvent event,
  }) async {
    final CaseProgress fallbackProgress =
        await loadNatureOfDiscoveryProgress();

    return CaseProgressStorageService
        .updateProgressTransactionally(
      casePathId: natureOfDiscoveryCasePathId,
      attemptId: event.attemptId,
      fallbackProgress: fallbackProgress,
      update: (CaseProgress currentProgress) {
        if (currentProgress.isCompleted) {
          return currentProgress;
        }

        final CaseMission? mission =
            natureOfDiscoveryMissionForStage(
          currentProgress.currentStage,
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

        return _progressService.applyStageProgress(
          caseProgress: currentProgress,
          mission: mission,
          updatedStageProgress: updatedStageProgress,
          updatedAt: event.completedAt,
        );
      },
    );
  }

  static bool isNatureOfDiscoveryStageCompleted({
    required CaseProgress progress,
    required int stage,
  }) {
    return _progressService.isStageCompleted(
      caseProgress: progress,
      stage: stage,
    );
  }

  static bool isNatureOfDiscoveryStageCurrent({
    required CaseProgress progress,
    required int stage,
  }) {
    return _progressService.isStageCurrent(
      caseProgress: progress,
      stage: stage,
    );
  }

  static bool isNatureOfDiscoveryStageLocked({
    required CaseProgress progress,
    required int stage,
  }) {
    return _progressService.isStageLocked(
      caseProgress: progress,
      stage: stage,
    );
  }

  static Future<void>
      resetNatureOfDiscoveryProgress() async {
    await CaseProgressStorageService.clearProgress(
      casePathId: natureOfDiscoveryCasePathId,
    );
  }

  static Future<CaseProgress>
      loadTheWrittenWordProgress() async {
    final CaseProgress? savedProgress =
        await CaseProgressStorageService.loadProgress(
      casePathId: theWrittenWordCasePathId,
    );

    if (savedProgress != null) {
      return _applyCaseFileTestUnlock(savedProgress);
    }

    final CaseProgress initialProgress =
        _progressService.createInitialProgress(
      casePathId: theWrittenWordCasePathId,
      totalStages: theWrittenWordTotalStages,
    );

    await CaseProgressStorageService.saveProgress(
      initialProgress,
    );

    return _applyCaseFileTestUnlock(initialProgress);
  }

  static CaseMission? theWrittenWordMissionForStage(
    int stage,
  ) {
    if (stage < 1 ||
        stage > theWrittenWordCaseMissions.length) {
      return null;
    }

    return theWrittenWordCaseMissions[stage - 1];
  }

  static CaseMission? currentTheWrittenWordMission(
    CaseProgress progress,
  ) {
    if (progress.isCompleted) {
      return null;
    }

    return theWrittenWordMissionForStage(
      progress.currentStage,
    );
  }

  static Future<CaseProgress>
      recordTheWrittenWordResult({
    required GameplayResultEvent event,
  }) async {
    final CaseProgress fallbackProgress =
        await loadTheWrittenWordProgress();

    return CaseProgressStorageService
        .updateProgressTransactionally(
      casePathId: theWrittenWordCasePathId,
      attemptId: event.attemptId,
      fallbackProgress: fallbackProgress,
      update: (CaseProgress currentProgress) {
        if (currentProgress.isCompleted) {
          return currentProgress;
        }

        final CaseMission? mission =
            theWrittenWordMissionForStage(
          currentProgress.currentStage,
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

        return _progressService.applyStageProgress(
          caseProgress: currentProgress,
          mission: mission,
          updatedStageProgress: updatedStageProgress,
          updatedAt: event.completedAt,
        );
      },
    );
  }

  static bool isTheWrittenWordStageCompleted({
    required CaseProgress progress,
    required int stage,
  }) {
    return _progressService.isStageCompleted(
      caseProgress: progress,
      stage: stage,
    );
  }

  static bool isTheWrittenWordStageCurrent({
    required CaseProgress progress,
    required int stage,
  }) {
    return _progressService.isStageCurrent(
      caseProgress: progress,
      stage: stage,
    );
  }

  static bool isTheWrittenWordStageLocked({
    required CaseProgress progress,
    required int stage,
  }) {
    return _progressService.isStageLocked(
      caseProgress: progress,
      stage: stage,
    );
  }

  static Future<void>
      resetTheWrittenWordProgress() async {
    await CaseProgressStorageService.clearProgress(
      casePathId: theWrittenWordCasePathId,
    );
  }


  static Future<CaseProgress>
      loadTheCreativeCodeProgress() async {
    final CaseProgress? savedProgress =
        await CaseProgressStorageService.loadProgress(
      casePathId: theCreativeCodeCasePathId,
    );

    if (savedProgress != null) {
      return _applyCaseFileTestUnlock(savedProgress);
    }

    final CaseProgress initialProgress =
        _progressService.createInitialProgress(
      casePathId: theCreativeCodeCasePathId,
      totalStages: theCreativeCodeTotalStages,
    );

    await CaseProgressStorageService.saveProgress(
      initialProgress,
    );

    return _applyCaseFileTestUnlock(initialProgress);
  }

  static CaseMission? theCreativeCodeMissionForStage(
    int stage,
  ) {
    if (stage < 1 ||
        stage > theCreativeCodeCaseMissions.length) {
      return null;
    }

    return theCreativeCodeCaseMissions[stage - 1];
  }

  static CaseMission? currentTheCreativeCodeMission(
    CaseProgress progress,
  ) {
    if (progress.isCompleted) {
      return null;
    }

    return theCreativeCodeMissionForStage(
      progress.currentStage,
    );
  }

  static Future<CaseProgress>
      recordTheCreativeCodeResult({
    required GameplayResultEvent event,
  }) async {
    final CaseProgress fallbackProgress =
        await loadTheCreativeCodeProgress();

    return CaseProgressStorageService
        .updateProgressTransactionally(
      casePathId: theCreativeCodeCasePathId,
      attemptId: event.attemptId,
      fallbackProgress: fallbackProgress,
      update: (CaseProgress currentProgress) {
        if (currentProgress.isCompleted) {
          return currentProgress;
        }

        final CaseMission? mission =
            theCreativeCodeMissionForStage(
          currentProgress.currentStage,
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

        return _progressService.applyStageProgress(
          caseProgress: currentProgress,
          mission: mission,
          updatedStageProgress: updatedStageProgress,
          updatedAt: event.completedAt,
        );
      },
    );
  }

  static bool isTheCreativeCodeStageCompleted({
    required CaseProgress progress,
    required int stage,
  }) {
    return _progressService.isStageCompleted(
      caseProgress: progress,
      stage: stage,
    );
  }

  static bool isTheCreativeCodeStageCurrent({
    required CaseProgress progress,
    required int stage,
  }) {
    return _progressService.isStageCurrent(
      caseProgress: progress,
      stage: stage,
    );
  }

  static bool isTheCreativeCodeStageLocked({
    required CaseProgress progress,
    required int stage,
  }) {
    return _progressService.isStageLocked(
      caseProgress: progress,
      stage: stage,
    );
  }

  static Future<void>
      resetTheCreativeCodeProgress() async {
    await CaseProgressStorageService.clearProgress(
      casePathId: theCreativeCodeCasePathId,
    );
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
