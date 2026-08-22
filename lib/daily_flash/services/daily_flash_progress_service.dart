import 'package:shared_preferences/shared_preferences.dart';

class DailyFlashProgress {
  final String dateKey;

  /// The next Daily Flash question that has NOT yet been attempted.
  ///
  /// 0 = Question 1 can be played
  /// 1 = Question 2 can be played
  /// 2 = Question 3 can be played
  /// 3 = Question 4 can be played
  /// 4 = Question 5 can be played
  /// 5 = all five questions have been attempted
  final int nextQuestionIndex;

  final int totalXp;
  final int questionsCorrect;
  final int firstGuesses;

  const DailyFlashProgress({
    required this.dateKey,
    required this.nextQuestionIndex,
    required this.totalXp,
    required this.questionsCorrect,
    required this.firstGuesses,
  });

  bool get allQuestionsAttempted =>
      nextQuestionIndex >= 5;

  factory DailyFlashProgress.newDay(
    String dateKey,
  ) {
    return DailyFlashProgress(
      dateKey: dateKey,
      nextQuestionIndex: 0,
      totalXp: 0,
      questionsCorrect: 0,
      firstGuesses: 0,
    );
  }

  DailyFlashProgress copyWith({
    String? dateKey,
    int? nextQuestionIndex,
    int? totalXp,
    int? questionsCorrect,
    int? firstGuesses,
  }) {
    return DailyFlashProgress(
      dateKey: dateKey ?? this.dateKey,
      nextQuestionIndex:
          nextQuestionIndex ??
          this.nextQuestionIndex,
      totalXp:
          totalXp ?? this.totalXp,
      questionsCorrect:
          questionsCorrect ??
          this.questionsCorrect,
      firstGuesses:
          firstGuesses ??
          this.firstGuesses,
    );
  }
}

class DailyFlashProgressService {
  // =========================================================
  // QA SWITCH
  // =========================================================

  /// TRUE while we are testing Daily Flash 5.
  ///
  /// In testing mode:
  /// - Daily Flash 5 can be replayed as many times as needed.
  /// - Daily progress/lockout is NOT persisted between runs.
  /// - The loading screen is still remembered separately,
  ///   so it only appears once per day.
  ///
  /// BEFORE GOING LIVE, CHANGE THIS ONE LINE TO:
  ///
  /// static const bool testingMode = false;
static const bool testingMode = true;

  static const String _datePreference =
      'daily_flash_5_date';

  static const String _nextQuestionPreference =
      'daily_flash_5_next_question';

  static const String _totalXpPreference =
      'daily_flash_5_total_xp';

  static const String _correctPreference =
      'daily_flash_5_questions_correct';

  static const String _firstGuessPreference =
      'daily_flash_5_first_guesses';

  // Loading screen is tracked separately from play progress.
  static const String _loadingSeenDatePreference =
      'daily_flash_5_loading_seen_date';

  // =========================================================
  // TODAY
  // =========================================================

  static String todayKey() {
    final DateTime now = DateTime.now();

    final String month =
        now.month.toString().padLeft(2, '0');

    final String day =
        now.day.toString().padLeft(2, '0');

    return '${now.year}-$month-$day';
  }

  // =========================================================
  // LOADING SCREEN
  // =========================================================

  static Future<bool> hasSeenLoadingToday() async {
    final SharedPreferences preferences =
        await SharedPreferences.getInstance();

    return preferences.getString(
          _loadingSeenDatePreference,
        ) ==
        todayKey();
  }

  static Future<void> markLoadingSeenToday() async {
    final SharedPreferences preferences =
        await SharedPreferences.getInstance();

    await preferences.setString(
      _loadingSeenDatePreference,
      todayKey(),
    );
  }

  // =========================================================
  // LOAD TODAY'S PROGRESS
  // =========================================================

  static Future<DailyFlashProgress>
      loadToday() async {
    final String today = todayKey();

    // QA MODE:
    // Always return a fresh Daily Flash when the player
    // opens it again, so we can test repeatedly.
    if (testingMode) {
      return DailyFlashProgress.newDay(today);
    }

    final SharedPreferences preferences =
        await SharedPreferences.getInstance();

    final String? savedDate =
        preferences.getString(
      _datePreference,
    );

    if (savedDate != today) {
      final DailyFlashProgress progress =
          DailyFlashProgress.newDay(
        today,
      );

      await _save(progress);

      return progress;
    }

    return DailyFlashProgress(
      dateKey: today,
      nextQuestionIndex:
          preferences.getInt(
            _nextQuestionPreference,
          ) ??
          0,
      totalXp:
          preferences.getInt(
            _totalXpPreference,
          ) ??
          0,
      questionsCorrect:
          preferences.getInt(
            _correctPreference,
          ) ??
          0,
      firstGuesses:
          preferences.getInt(
            _firstGuessPreference,
          ) ??
          0,
    );
  }

  // =========================================================
  // CONSUME QUESTION
  // =========================================================

  static Future<DailyFlashProgress>
      consumeQuestion({
    required DailyFlashProgress progress,
    required int questionIndex,
  }) async {
    int nextQuestionIndex =
        questionIndex + 1;

    if (nextQuestionIndex > 5) {
      nextQuestionIndex = 5;
    }

    if (nextQuestionIndex <
        progress.nextQuestionIndex) {
      nextQuestionIndex =
          progress.nextQuestionIndex;
    }

    final DailyFlashProgress updated =
        progress.copyWith(
      nextQuestionIndex:
          nextQuestionIndex,
    );

    // During QA we keep progress only for the current run.
    if (!testingMode) {
      await _save(updated);
    }

    return updated;
  }

  // =========================================================
  // SAVE A CORRECT RESULT
  // =========================================================

  static Future<DailyFlashProgress>
      recordCorrectAnswer({
    required DailyFlashProgress progress,
    required int xpEarned,
    required bool wasFirstGuess,
  }) async {
    final DailyFlashProgress updated =
        progress.copyWith(
      totalXp:
          progress.totalXp + xpEarned,
      questionsCorrect:
          progress.questionsCorrect + 1,
      firstGuesses:
          progress.firstGuesses +
              (wasFirstGuess ? 1 : 0),
    );

    if (!testingMode) {
      await _save(updated);
    }

    return updated;
  }

  // =========================================================
  // SAVE
  // =========================================================

  static Future<void> _save(
    DailyFlashProgress progress,
  ) async {
    final SharedPreferences preferences =
        await SharedPreferences.getInstance();

    await preferences.setString(
      _datePreference,
      progress.dateKey,
    );

    await preferences.setInt(
      _nextQuestionPreference,
      progress.nextQuestionIndex,
    );

    await preferences.setInt(
      _totalXpPreference,
      progress.totalXp,
    );

    await preferences.setInt(
      _correctPreference,
      progress.questionsCorrect,
    );

    await preferences.setInt(
      _firstGuessPreference,
      progress.firstGuesses,
    );
  }

  // =========================================================
  // TESTING ONLY
  // =========================================================

  static Future<void> resetForTesting() async {
    final SharedPreferences preferences =
        await SharedPreferences.getInstance();

    await preferences.remove(
      _datePreference,
    );

    await preferences.remove(
      _nextQuestionPreference,
    );

    await preferences.remove(
      _totalXpPreference,
    );

    await preferences.remove(
      _correctPreference,
    );

    await preferences.remove(
      _firstGuessPreference,
    );

    await preferences.remove(
      _loadingSeenDatePreference,
    );
  }
}
