import '../data/animal_kingdom_case_data.dart';
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

  /// DEBUG / QA ONLY.
  ///
  /// Clears Animal Kingdom locally and in the cloud, then completes
  /// Cases 1-19 through the normal Case tracking pipeline. The result
  /// is a fresh, incomplete Case 20 so the final completion and badge
  /// award experience can be tested again.
  static Future<CaseProgress>
      qaResetAnimalKingdomTo19Of20() async {
    await resetAnimalKingdomProgress();

    CaseProgress progress =
        await loadAnimalKingdomProgress();

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

      for (int answer = 0;
          answer < mission.correctRequired;
          answer++) {
        eventNumber++;

        progress = await recordAnimalKingdomResult(
          event: GameplayResultEvent(
            attemptId:
                'qa_case_${mission.stage}_$eventNumber',
            questionId:
                'qa_case_${mission.stage}_question_$answer',
            category: 'animals',
            subcategory: qaSubcategory,
            correct: true,
            clueNumberSolved: 1,
            firstGuess: true,
            practiceMode: true,
            completedAt: DateTime.now().add(
              Duration(milliseconds: eventNumber),
            ),
          ),
        );

        if (progress.isCompleted ||
            progress.currentStage !=
                stageBeingCompleted) {
          break;
        }
      }

      if (!progress.isCompleted &&
          progress.currentStage ==
              stageBeingCompleted) {
        throw StateError(
          'QA reset stalled while completing '
          'Animal Kingdom Case $stageBeingCompleted.',
        );
      }
    }

    if (progress.isCompleted ||
        progress.currentStage !=
            animalKingdomTotalStages ||
        progress.completedStageCount != 19) {
      throw StateError(
        'QA reset expected Animal Kingdom at '
        '19/20 with Case 20 active, but got '
        '${progress.completedStageCount}/'
        '${progress.totalStages}, '
        'Case ${progress.currentStage}.',
      );
    }

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