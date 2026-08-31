import '../models/case_mission.dart';
import '../models/case_progress.dart';
import '../models/gameplay_result_event.dart';

class CaseTrackingService {
  const CaseTrackingService();

  CaseStageProgress applyResult({
    required CaseMission mission,
    required CaseStageProgress progress,
    required GameplayResultEvent event,
  }) {
    if (progress.stage != mission.stage) {
      return progress;
    }

    if (event.attemptId == progress.lastProcessedAttemptId) {
      return progress;
    }

    if (!_qualifiesForMission(
      mission: mission,
      event: event,
    )) {
      return progress;
    }

    final int updatedCorrectCount = progress.correctCount + 1;

    int updatedClueThresholdCount = progress.clueThresholdCount;
    if (_countsTowardsClueThreshold(
      mission: mission,
      event: event,
    )) {
      updatedClueThresholdCount++;
    }

    int updatedFirstGuessCount = progress.firstGuessCount;
    if (_countsAsFirstGuess(
      mission: mission,
      event: event,
    )) {
      updatedFirstGuessCount++;
    }

    return progress.copyWith(
      correctCount: updatedCorrectCount,
      clueThresholdCount: updatedClueThresholdCount,
      firstGuessCount: updatedFirstGuessCount,
      lastProcessedAttemptId: event.attemptId,
      startedAt: progress.startedAt ?? event.completedAt,
    );
  }

  bool isMissionComplete({
    required CaseMission mission,
    required CaseStageProgress progress,
  }) {
    if (progress.stage != mission.stage) {
      return false;
    }

    if (progress.correctCount < mission.correctRequired) {
      return false;
    }

    if (mission.hasClueRequirement &&
        progress.clueThresholdCount < mission.clueThresholdRequired) {
      return false;
    }

    if (mission.hasFirstGuessRequirement &&
        progress.firstGuessCount < mission.firstGuessesRequired) {
      return false;
    }

    return true;
  }

  bool qualifiesForMission({
    required CaseMission mission,
    required GameplayResultEvent event,
  }) {
    return _qualifiesForMission(
      mission: mission,
      event: event,
    );
  }

  bool _qualifiesForMission({
    required CaseMission mission,
    required GameplayResultEvent event,
  }) {
    if (!event.correct) {
      return false;
    }

    if (!_hasValidClueNumber(event.clueNumberSolved)) {
      return false;
    }

    if (event.category != mission.category) {
      return false;
    }

    if (mission.hasSubcategoryRequirement &&
        event.subcategory != mission.subcategory) {
      return false;
    }

    return true;
  }

  bool _countsTowardsClueThreshold({
    required CaseMission mission,
    required GameplayResultEvent event,
  }) {
    if (!mission.hasClueRequirement) {
      return false;
    }

    if (!_hasValidClueNumber(event.clueNumberSolved)) {
      return false;
    }

    return event.clueNumberSolved <= mission.clueThreshold!;
  }

  bool _countsAsFirstGuess({
    required CaseMission mission,
    required GameplayResultEvent event,
  }) {
    if (!mission.hasFirstGuessRequirement) {
      return false;
    }

    if (!event.correct) {
      return false;
    }

    if (!_hasValidClueNumber(event.clueNumberSolved)) {
      return false;
    }

    return event.firstGuess && event.clueNumberSolved == 1;
  }

  bool _hasValidClueNumber(int clueNumber) {
    return clueNumber >= 1 && clueNumber <= 10;
  }
}