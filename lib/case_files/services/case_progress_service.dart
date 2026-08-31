import '../models/case_mission.dart';
import '../models/case_progress.dart';
import 'case_tracking_service.dart';

class CaseProgressService {
  final CaseTrackingService trackingService;

  const CaseProgressService({
    this.trackingService = const CaseTrackingService(),
  });

  CaseProgress createInitialProgress({
    required String casePathId,
    required int totalStages,
    DateTime? startedAt,
  }) {
    final DateTime now = startedAt ?? DateTime.now();

    return CaseProgress(
      casePathId: casePathId,
      currentStage: 1,
      totalStages: totalStages,
      completedStages: const [],
      isCompleted: false,
      currentStageProgress: CaseStageProgress(
        stage: 1,
        startedAt: now,
      ),
      startedAt: now,
      updatedAt: now,
    );
  }

  CaseProgress applyStageProgress({
    required CaseProgress caseProgress,
    required CaseMission mission,
    required CaseStageProgress updatedStageProgress,
    DateTime? updatedAt,
  }) {
    if (caseProgress.isCompleted) {
      return caseProgress;
    }

    if (caseProgress.currentStage != mission.stage) {
      return caseProgress;
    }

    if (updatedStageProgress.stage != mission.stage) {
      return caseProgress;
    }

    final DateTime now = updatedAt ?? DateTime.now();

    final bool missionComplete = trackingService.isMissionComplete(
      mission: mission,
      progress: updatedStageProgress,
    );

    if (!missionComplete) {
      return caseProgress.copyWith(
        currentStageProgress: updatedStageProgress,
        updatedAt: now,
      );
    }

    final List<int> completedStages = <int>[
      ...caseProgress.completedStages,
    ];

    if (!completedStages.contains(mission.stage)) {
      completedStages.add(mission.stage);
      completedStages.sort();
    }

    final CaseStageProgress completedStageProgress =
        updatedStageProgress.copyWith(
      completedAt: now,
    );

    final bool isFinalStage =
        mission.isFinal || mission.stage >= caseProgress.totalStages;

    if (isFinalStage) {
      return CaseProgress(
        casePathId: caseProgress.casePathId,
        currentStage: mission.stage,
        totalStages: caseProgress.totalStages,
        completedStages: completedStages,
        isCompleted: true,
        currentStageProgress: completedStageProgress,
        startedAt: caseProgress.startedAt,
        updatedAt: now,
        completedAt: now,
      );
    }

    final int nextStage = mission.stage + 1;

    return CaseProgress(
      casePathId: caseProgress.casePathId,
      currentStage: nextStage,
      totalStages: caseProgress.totalStages,
      completedStages: completedStages,
      isCompleted: false,
      currentStageProgress: CaseStageProgress(
        stage: nextStage,
        startedAt: now,
      ),
      startedAt: caseProgress.startedAt,
      updatedAt: now,
      completedAt: caseProgress.completedAt,
    );
  }

  bool isStageCompleted({
    required CaseProgress caseProgress,
    required int stage,
  }) {
    return caseProgress.completedStages.contains(stage);
  }

  bool isStageCurrent({
    required CaseProgress caseProgress,
    required int stage,
  }) {
    return !caseProgress.isCompleted &&
        caseProgress.currentStage == stage;
  }

  bool isStageLocked({
    required CaseProgress caseProgress,
    required int stage,
  }) {
    if (stage < 1 || stage > caseProgress.totalStages) {
      return true;
    }

    if (caseProgress.isCompleted) {
      return false;
    }

    return stage > caseProgress.currentStage;
  }
}