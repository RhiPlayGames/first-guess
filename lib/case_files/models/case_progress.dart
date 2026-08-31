class CaseProgress {
  final String casePathId;

  final int currentStage;
  final int totalStages;

  final List<int> completedStages;

  final bool isCompleted;

  final CaseStageProgress currentStageProgress;

  final DateTime? startedAt;
  final DateTime? updatedAt;
  final DateTime? completedAt;

  const CaseProgress({
    required this.casePathId,
    required this.currentStage,
    required this.totalStages,
    required this.completedStages,
    required this.isCompleted,
    required this.currentStageProgress,
    this.startedAt,
    this.updatedAt,
    this.completedAt,
  });

  int get completedStageCount => completedStages.length;

  double get overallProgress {
    if (totalStages <= 0) {
      return 0;
    }

    return (completedStageCount / totalStages).clamp(0.0, 1.0);
  }

  CaseProgress copyWith({
    String? casePathId,
    int? currentStage,
    int? totalStages,
    List<int>? completedStages,
    bool? isCompleted,
    CaseStageProgress? currentStageProgress,
    DateTime? startedAt,
    DateTime? updatedAt,
    DateTime? completedAt,
  }) {
    return CaseProgress(
      casePathId: casePathId ?? this.casePathId,
      currentStage: currentStage ?? this.currentStage,
      totalStages: totalStages ?? this.totalStages,
      completedStages: completedStages ?? this.completedStages,
      isCompleted: isCompleted ?? this.isCompleted,
      currentStageProgress:
          currentStageProgress ?? this.currentStageProgress,
      startedAt: startedAt ?? this.startedAt,
      updatedAt: updatedAt ?? this.updatedAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }
}

class CaseStageProgress {
  final int stage;

  final int correctCount;
  final int clueThresholdCount;
  final int firstGuessCount;

  final String? lastProcessedAttemptId;

  final DateTime? startedAt;
  final DateTime? completedAt;

  const CaseStageProgress({
    required this.stage,
    this.correctCount = 0,
    this.clueThresholdCount = 0,
    this.firstGuessCount = 0,
    this.lastProcessedAttemptId,
    this.startedAt,
    this.completedAt,
  });

  CaseStageProgress copyWith({
    int? stage,
    int? correctCount,
    int? clueThresholdCount,
    int? firstGuessCount,
    String? lastProcessedAttemptId,
    DateTime? startedAt,
    DateTime? completedAt,
  }) {
    return CaseStageProgress(
      stage: stage ?? this.stage,
      correctCount: correctCount ?? this.correctCount,
      clueThresholdCount:
          clueThresholdCount ?? this.clueThresholdCount,
      firstGuessCount: firstGuessCount ?? this.firstGuessCount,
      lastProcessedAttemptId:
          lastProcessedAttemptId ?? this.lastProcessedAttemptId,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }
}