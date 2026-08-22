import 'package:shared_preferences/shared_preferences.dart';

enum SubcategoryProgressState {
  comingSoon,
  play,
  newQuestions,
  playAgain,
}

class SubcategoryProgressStatus {
  const SubcategoryProgressStatus._({
    required this.state,
    required this.ctaLabel,
  });

  final SubcategoryProgressState state;
  final String ctaLabel;

  static const SubcategoryProgressStatus comingSoon =
      SubcategoryProgressStatus._(
    state: SubcategoryProgressState.comingSoon,
    ctaLabel: 'COMING SOON',
  );

  static const SubcategoryProgressStatus play =
      SubcategoryProgressStatus._(
    state: SubcategoryProgressState.play,
    ctaLabel: 'PLAY',
  );

  static const SubcategoryProgressStatus newQuestions =
      SubcategoryProgressStatus._(
    state: SubcategoryProgressState.newQuestions,
    ctaLabel: 'NEW QUESTIONS',
  );

  static const SubcategoryProgressStatus playAgain =
      SubcategoryProgressStatus._(
    state: SubcategoryProgressState.playAgain,
    ctaLabel: 'PLAY AGAIN',
  );

  static SubcategoryProgressStatus resolve({
    required bool isAvailable,
    required int playedQuestions,
    required int totalQuestions,
    bool hadPreviouslyCompleted = false,
  }) {
    if (!isAvailable || totalQuestions <= 0) {
      return comingSoon;
    }

    if (playedQuestions >= totalQuestions) {
      return playAgain;
    }

    if (hadPreviouslyCompleted) {
      return newQuestions;
    }

    return play;
  }
}

class SubcategoryCompletionHistoryService {
  SubcategoryCompletionHistoryService._();

  static final SharedPreferencesAsync _preferences =
      SharedPreferencesAsync();

  static const String _keyPrefix =
      'subcategory_completed_total_v1_';

  static String _storageKey({
    required String category,
    required String subcategory,
  }) {
    return '$_keyPrefix${category}_$subcategory';
  }

  static Future<int> loadCompletedTotal({
    required String category,
    required String subcategory,
  }) async {
    return await _preferences.getInt(
          _storageKey(
            category: category,
            subcategory: subcategory,
          ),
        ) ??
        0;
  }

  static Future<Map<String, int>> loadCompletedTotals({
    required String category,
    required Iterable<String> subcategories,
  }) async {
    final Map<String, int> totals = <String, int>{};

    for (final String subcategory in subcategories) {
      totals[subcategory] = await loadCompletedTotal(
        category: category,
        subcategory: subcategory,
      );
    }

    return totals;
  }

  static Future<void> recordCompletion({
    required String category,
    required String subcategory,
    required int totalQuestions,
  }) async {
    if (totalQuestions <= 0) {
      return;
    }

    await _preferences.setInt(
      _storageKey(
        category: category,
        subcategory: subcategory,
      ),
      totalQuestions,
    );
  }

  static bool hasNewQuestionsSinceCompletion({
    required int completedTotal,
    required int playedQuestions,
    required int totalQuestions,
  }) {
    return completedTotal > 0 &&
        totalQuestions > completedTotal &&
        playedQuestions < totalQuestions;
  }
}
