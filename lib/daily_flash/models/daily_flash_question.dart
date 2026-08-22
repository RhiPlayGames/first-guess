class DailyFlashQuestion {
  final String answer;
  final String imagePath;
  final List<String> clues;

  const DailyFlashQuestion({
    required this.answer,
    required this.imagePath,
    required this.clues,
  });

  int get maxBaseXp => 100;

  int baseXpForClue(int clueIndex) {
    switch (clueIndex) {
      case 0:
        return 100;
      case 1:
        return 80;
      case 2:
        return 60;
      case 3:
        return 40;
      case 4:
        return 20;
      default:
        return 0;
    }
  }

  int bonusXpForClue(int clueIndex) {
    return baseXpForClue(clueIndex);
  }

  int totalXpForClue(int clueIndex) {
    return baseXpForClue(clueIndex) +
        bonusXpForClue(clueIndex);
  }
}