class GameplayResultEvent {
  final String attemptId;

  final String questionId;
  final String category;
  final String subcategory;

  final bool correct;

  /// The clue number on which the question was solved.
  ///
  /// 1 = First Guess
  /// 2 = solved on Clue 2
  /// ...
  /// 10 = solved on Clue 10
  ///
  /// If the answer was not solved correctly, this can still contain
  /// the final clue reached, but [correct] will be false.
  final int clueNumberSolved;

  /// True when the correct answer was given on Clue 1.
  final bool firstGuess;

  /// True when the result came from Practice mode.
  ///
  /// Case Files currently allow both normal and Practice gameplay
  /// to contribute once the relevant stage is active.
  final bool practiceMode;

  final DateTime completedAt;

  const GameplayResultEvent({
    required this.attemptId,
    required this.questionId,
    required this.category,
    required this.subcategory,
    required this.correct,
    required this.clueNumberSolved,
    required this.firstGuess,
    required this.practiceMode,
    required this.completedAt,
  });

  bool get solvedByClue1 => correct && clueNumberSolved <= 1;

  bool get solvedByClue2 => correct && clueNumberSolved <= 2;

  bool get solvedByClue3 => correct && clueNumberSolved <= 3;

  bool get solvedByClue4 => correct && clueNumberSolved <= 4;

  bool get solvedByClue5 => correct && clueNumberSolved <= 5;

  bool solvedByClue(int clueNumber) {
    if (!correct) {
      return false;
    }

    if (clueNumber < 1 || clueNumber > 10) {
      return false;
    }

    return clueNumberSolved <= clueNumber;
  }
}