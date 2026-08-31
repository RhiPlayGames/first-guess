enum CaseDifficulty {
  easy,
  moderate,
  hard,
  expert,
  finalChallenge,
}

class CaseMission {
  final int stage;
  final CaseDifficulty difficulty;

  final String title;
  final String missionText;

  final String category;
  final String? subcategory;

  final int correctRequired;

  /// Example:
  /// clueThreshold = 4 means:
  /// answers solved on Clues 1, 2, 3 or 4 qualify.
  final int? clueThreshold;

  /// Number of qualifying answers that must be solved
  /// within [clueThreshold].
  final int clueThresholdRequired;

  /// Number of answers that must be solved on Clue 1.
  final int firstGuessesRequired;

  const CaseMission({
    required this.stage,
    required this.difficulty,
    required this.title,
    required this.missionText,
    required this.category,
    this.subcategory,
    required this.correctRequired,
    this.clueThreshold,
    this.clueThresholdRequired = 0,
    this.firstGuessesRequired = 0,
  });

  bool get hasSubcategoryRequirement =>
      subcategory != null && subcategory!.isNotEmpty;

  bool get hasClueRequirement =>
      clueThreshold != null && clueThresholdRequired > 0;

  bool get hasFirstGuessRequirement => firstGuessesRequired > 0;

  bool get isFinal => difficulty == CaseDifficulty.finalChallenge;

  String get difficultyLabel {
    switch (difficulty) {
      case CaseDifficulty.easy:
        return 'EASY';
      case CaseDifficulty.moderate:
        return 'MODERATE';
      case CaseDifficulty.hard:
        return 'HARD';
      case CaseDifficulty.expert:
        return 'EXPERT';
      case CaseDifficulty.finalChallenge:
        return 'FINAL';
    }
  }
}