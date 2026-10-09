import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'daily_flash_schedule_service.dart';

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
          nextQuestionIndex ?? this.nextQuestionIndex,
      totalXp: totalXp ?? this.totalXp,
      questionsCorrect:
          questionsCorrect ?? this.questionsCorrect,
      firstGuesses:
          firstGuesses ?? this.firstGuesses,
    );
  }
}

class DailyFlashProgressService {
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

  static const int _cloudSchemaVersion = 1;

  static final FirebaseAuth _auth =
      FirebaseAuth.instance;

  static final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  // Reuse today's already-synchronised progress in this app session.
  // Classic First Guess loads Daily Flash status when it opens, so
  // PLAY NOW can reuse that result instead of immediately repeating
  // the same local + Firestore read.
  static DailyFlashProgress? _cachedTodayProgress;
  static String? _cachedTodayUserId;
  static Future<DailyFlashProgress>? _loadTodayInFlight;
  static String? _loadTodayInFlightDate;
  static String? _loadTodayInFlightUserId;

  static String get _currentCacheUserId =>
      _auth.currentUser?.uid ?? '__signed_out__';

  static DailyFlashProgress? _cachedProgressFor(
    String today,
  ) {
    final DailyFlashProgress? cached = _cachedTodayProgress;

    if (cached == null ||
        cached.dateKey != today ||
        _cachedTodayUserId != _currentCacheUserId) {
      return null;
    }

    return cached;
  }

  static void _cacheProgress(
    DailyFlashProgress progress,
  ) {
    _cachedTodayProgress = progress;
    _cachedTodayUserId = _currentCacheUserId;
  }

  static DocumentReference<Map<String, dynamic>>?
      get _cloudProgressDocument {
    final User? user = _auth.currentUser;

    if (user == null) {
      return null;
    }

    return _firestore
        .collection('players')
        .doc(user.uid)
        .collection('progress')
        .doc('daily_flash');
  }

  // =========================================================
  // TODAY
  // =========================================================

  static String todayKey() {
    return DailyFlashScheduleService.activeDateKey();
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
  // LOCAL HELPERS
  // =========================================================

  static Future<DailyFlashProgress> _loadLocalToday(
    SharedPreferences preferences,
    String today,
  ) async {
    final String? savedDate =
        preferences.getString(_datePreference);

    if (savedDate != today) {
      return DailyFlashProgress.newDay(today);
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

  static DailyFlashProgress? _progressFromCloudData(
    Map<String, dynamic>? data,
    String today,
  ) {
    if (data == null || data['dateKey'] != today) {
      return null;
    }

    int readInt(String key) {
      final dynamic value = data[key];

      if (value is int) {
        return value;
      }

      if (value is num) {
        return value.toInt();
      }

      return 0;
    }

    return DailyFlashProgress(
      dateKey: today,
      nextQuestionIndex:
          readInt('nextQuestionIndex').clamp(0, 5),
      totalXp: readInt('totalXp').clamp(0, 1 << 31),
      questionsCorrect:
          readInt('questionsCorrect').clamp(0, 5),
      firstGuesses:
          readInt('firstGuesses').clamp(0, 5),
    );
  }

  static DailyFlashProgress _mergeProgress(
    DailyFlashProgress local,
    DailyFlashProgress cloud,
  ) {
    return DailyFlashProgress(
      dateKey: local.dateKey,
      nextQuestionIndex:
          local.nextQuestionIndex > cloud.nextQuestionIndex
              ? local.nextQuestionIndex
              : cloud.nextQuestionIndex,
      totalXp:
          local.totalXp > cloud.totalXp
              ? local.totalXp
              : cloud.totalXp,
      questionsCorrect:
          local.questionsCorrect > cloud.questionsCorrect
              ? local.questionsCorrect
              : cloud.questionsCorrect,
      firstGuesses:
          local.firstGuesses > cloud.firstGuesses
              ? local.firstGuesses
              : cloud.firstGuesses,
    );
  }

  static Map<String, dynamic> _toCloudData(
    DailyFlashProgress progress,
  ) {
    return <String, dynamic>{
      'dateKey': progress.dateKey,
      'nextQuestionIndex': progress.nextQuestionIndex,
      'totalXp': progress.totalXp,
      'questionsCorrect': progress.questionsCorrect,
      'firstGuesses': progress.firstGuesses,
      'schemaVersion': _cloudSchemaVersion,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  // =========================================================
  // LOAD TODAY'S PROGRESS
  // =========================================================

  static Future<DailyFlashProgress>
      loadToday({
    bool forceRefresh = false,
  }) async {
    final String today = todayKey();
    final String userId = _currentCacheUserId;

    if (!forceRefresh) {
      final DailyFlashProgress? cached =
          _cachedProgressFor(today);

      if (cached != null) {
        return cached;
      }

      final Future<DailyFlashProgress>? inFlight =
          _loadTodayInFlight;

      if (inFlight != null &&
          _loadTodayInFlightDate == today &&
          _loadTodayInFlightUserId == userId) {
        return inFlight;
      }
    }

    final Future<DailyFlashProgress> request =
        _loadTodayFresh(today);

    _loadTodayInFlight = request;
    _loadTodayInFlightDate = today;
    _loadTodayInFlightUserId = userId;

    try {
      final DailyFlashProgress progress = await request;
      _cacheProgress(progress);
      return progress;
    } finally {
      if (identical(_loadTodayInFlight, request)) {
        _loadTodayInFlight = null;
        _loadTodayInFlightDate = null;
        _loadTodayInFlightUserId = null;
      }
    }
  }

  static Future<DailyFlashProgress> _loadTodayFresh(
    String today,
  ) async {
    final SharedPreferences preferences =
        await SharedPreferences.getInstance();

    final DailyFlashProgress localProgress =
        await _loadLocalToday(
      preferences,
      today,
    );

    final DocumentReference<Map<String, dynamic>>?
        cloudDocument = _cloudProgressDocument;

    if (cloudDocument == null) {
      await _saveLocal(localProgress, preferences);
      return localProgress;
    }

    try {
      final DocumentSnapshot<Map<String, dynamic>>
          snapshot = await cloudDocument.get();

      final DailyFlashProgress? cloudProgress =
          _progressFromCloudData(
        snapshot.data(),
        today,
      );

      final DailyFlashProgress mergedProgress =
          cloudProgress == null
              ? localProgress
              : _mergeProgress(
                  localProgress,
                  cloudProgress,
                );

      await _saveLocal(
        mergedProgress,
        preferences,
      );

      final bool cloudNeedsUpdate =
          cloudProgress == null ||
          cloudProgress.nextQuestionIndex !=
              mergedProgress.nextQuestionIndex ||
          cloudProgress.totalXp !=
              mergedProgress.totalXp ||
          cloudProgress.questionsCorrect !=
              mergedProgress.questionsCorrect ||
          cloudProgress.firstGuesses !=
              mergedProgress.firstGuesses;

      if (cloudNeedsUpdate) {
        await _firestore.runTransaction<void>(
          (Transaction transaction) async {
            final DocumentSnapshot<Map<String, dynamic>>
                latestSnapshot =
                await transaction.get(cloudDocument);

            final DailyFlashProgress? latestCloud =
                _progressFromCloudData(
              latestSnapshot.data(),
              today,
            );

            final DailyFlashProgress safeMerged =
                latestCloud == null
                    ? mergedProgress
                    : _mergeProgress(
                        mergedProgress,
                        latestCloud,
                      );

            transaction.set(
              cloudDocument,
              _toCloudData(safeMerged),
              SetOptions(merge: true),
            );
          },
        );
      }

      return mergedProgress;
    } on FirebaseException {
      await _saveLocal(localProgress, preferences);
      return localProgress;
    }
  }

  // =========================================================
  // CONSUME QUESTION
  // =========================================================

  static Future<DailyFlashProgress>
      consumeQuestion({
    required DailyFlashProgress progress,
    required int questionIndex,
  }) async {
    final String today = todayKey();
    final SharedPreferences preferences =
        await SharedPreferences.getInstance();

    final DocumentReference<Map<String, dynamic>>?
        cloudDocument = _cloudProgressDocument;

    if (cloudDocument == null) {
      int nextQuestionIndex = questionIndex + 1;

      if (nextQuestionIndex > 5) {
        nextQuestionIndex = 5;
      }

      if (nextQuestionIndex < progress.nextQuestionIndex) {
        nextQuestionIndex = progress.nextQuestionIndex;
      }

      final DailyFlashProgress updated =
          progress.copyWith(
        nextQuestionIndex: nextQuestionIndex,
      );

      await _saveLocal(updated, preferences);
      return updated;
    }

    try {
      final DailyFlashProgress updated =
          await _firestore.runTransaction<DailyFlashProgress>(
        (Transaction transaction) async {
          final DocumentSnapshot<Map<String, dynamic>> snapshot =
              await transaction.get(cloudDocument);

          final DailyFlashProgress cloudProgress =
              _progressFromCloudData(
                snapshot.data(),
                today,
              ) ??
              DailyFlashProgress.newDay(today);

          if (questionIndex != cloudProgress.nextQuestionIndex) {
            return cloudProgress;
          }

          final int nextQuestionIndex =
              (questionIndex + 1).clamp(0, 5);

          final DailyFlashProgress transactionUpdated =
              cloudProgress.copyWith(
            nextQuestionIndex: nextQuestionIndex,
          );

          transaction.set(
            cloudDocument,
            _toCloudData(transactionUpdated),
            SetOptions(merge: true),
          );

          return transactionUpdated;
        },
      );

      await _saveLocal(updated, preferences);
      return updated;
    } on FirebaseException {
      // Keep local Daily Flash playable if cloud access is temporarily
      // unavailable, without overwriting a newer cloud snapshot.
      int nextQuestionIndex = questionIndex + 1;

      if (nextQuestionIndex > 5) {
        nextQuestionIndex = 5;
      }

      if (nextQuestionIndex < progress.nextQuestionIndex) {
        nextQuestionIndex = progress.nextQuestionIndex;
      }

      final DailyFlashProgress updated =
          progress.copyWith(
        nextQuestionIndex: nextQuestionIndex,
      );

      await _saveLocal(updated, preferences);
      return updated;
    }
  }

  // =========================================================
  // SAVE A CORRECT RESULT
  // =========================================================

  static Future<DailyFlashProgress>
      recordCorrectAnswer({
    required DailyFlashProgress progress,
    required int questionIndex,
    required int xpEarned,
    required bool wasFirstGuess,
  }) async {
    final String today = todayKey();
    final SharedPreferences preferences =
        await SharedPreferences.getInstance();

    final DocumentReference<Map<String, dynamic>>?
        cloudDocument = _cloudProgressDocument;

    if (cloudDocument == null) {
      // Only the currently unattempted question can be completed. This keeps
      // retries/idempotency safe and means merely opening a question never
      // advances Daily Flash progress.
      if (questionIndex != progress.nextQuestionIndex) {
        return progress;
      }

      final DailyFlashProgress updated =
          progress.copyWith(
        nextQuestionIndex: (questionIndex + 1).clamp(0, 5),
        totalXp: progress.totalXp + xpEarned,
        questionsCorrect: progress.questionsCorrect + 1,
        firstGuesses:
            progress.firstGuesses +
            (wasFirstGuess ? 1 : 0),
      );

      await _saveLocal(updated, preferences);
      return updated;
    }

    final String resultId =
        '${today}_question_$questionIndex';

    final DocumentReference<Map<String, dynamic>> resultDocument =
        cloudDocument
            .collection('processed_results')
            .doc(resultId);

    try {
      final DailyFlashProgress updated =
          await _firestore.runTransaction<DailyFlashProgress>(
        (Transaction transaction) async {
          final DocumentSnapshot<Map<String, dynamic>> resultSnapshot =
              await transaction.get(resultDocument);

          final DocumentSnapshot<Map<String, dynamic>> progressSnapshot =
              await transaction.get(cloudDocument);

          final DailyFlashProgress cloudProgress =
              _progressFromCloudData(
                progressSnapshot.data(),
                today,
              ) ??
              DailyFlashProgress.newDay(today);

          if (resultSnapshot.exists) {
            return cloudProgress;
          }

          if (questionIndex != cloudProgress.nextQuestionIndex) {
            return cloudProgress;
          }

          final DailyFlashProgress transactionUpdated =
              cloudProgress.copyWith(
            nextQuestionIndex: (questionIndex + 1).clamp(0, 5),
            totalXp: cloudProgress.totalXp + xpEarned,
            questionsCorrect:
                cloudProgress.questionsCorrect + 1,
            firstGuesses:
                cloudProgress.firstGuesses +
                (wasFirstGuess ? 1 : 0),
          );

          transaction.set(
            cloudDocument,
            _toCloudData(transactionUpdated),
            SetOptions(merge: true),
          );

          transaction.set(
            resultDocument,
            <String, dynamic>{
              'dateKey': today,
              'questionIndex': questionIndex,
              'xpEarned': xpEarned,
              'wasFirstGuess': wasFirstGuess,
              'correct': true,
              'processedAt': FieldValue.serverTimestamp(),
              'schemaVersion': _cloudSchemaVersion,
            },
            SetOptions(merge: true),
          );

          return transactionUpdated;
        },
      );

      await _saveLocal(updated, preferences);
      return updated;
    } on FirebaseException {
      // Keep local gameplay working if Firestore is unavailable.
      // Avoid writing a potentially stale aggregate snapshot to cloud.
      if (questionIndex != progress.nextQuestionIndex) {
        return progress;
      }

      final DailyFlashProgress updated =
          progress.copyWith(
        nextQuestionIndex: (questionIndex + 1).clamp(0, 5),
        totalXp: progress.totalXp + xpEarned,
        questionsCorrect: progress.questionsCorrect + 1,
        firstGuesses:
            progress.firstGuesses +
            (wasFirstGuess ? 1 : 0),
      );

      await _saveLocal(updated, preferences);
      return updated;
    }
  }

  // =========================================================
  // SAVE
  // =========================================================

  static Future<void> _saveLocal(
    DailyFlashProgress progress,
    SharedPreferences preferences,
  ) async {
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

    _cacheProgress(progress);
  }

  // =========================================================
  // DEBUG / TESTING RESET
  // =========================================================

  /// Clears today's Classic Daily Flash play progress locally and in Firestore.
  /// Intended for debug builds only.
  static Future<void> resetForTesting() async {
    final SharedPreferences preferences =
        await SharedPreferences.getInstance();

    await Future.wait(<Future<bool>>[
      preferences.remove(_datePreference),
      preferences.remove(_nextQuestionPreference),
      preferences.remove(_totalXpPreference),
      preferences.remove(_correctPreference),
      preferences.remove(_firstGuessPreference),
      preferences.remove(_loadingSeenDatePreference),
    ]);

    _cachedTodayProgress = null;
    _cachedTodayUserId = null;
    _loadTodayInFlight = null;
    _loadTodayInFlightDate = null;
    _loadTodayInFlightUserId = null;

    final DocumentReference<Map<String, dynamic>>? cloudDocument =
        _cloudProgressDocument;

    if (cloudDocument == null) {
      return;
    }

    try {
      final QuerySnapshot<Map<String, dynamic>> processedResults =
          await cloudDocument.collection('processed_results').get();

      final WriteBatch batch = _firestore.batch();

      for (final QueryDocumentSnapshot<Map<String, dynamic>> document
          in processedResults.docs) {
        batch.delete(document.reference);
      }

      batch.delete(cloudDocument);
      await batch.commit();
    } on FirebaseException {
      // Local reset still succeeds if Firestore is temporarily unavailable.
    }
  }

}
