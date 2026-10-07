import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'daily_flash_schedule_service.dart';

class DailyFlashGameProgress {
  final String dateKey;
  final int nextQuestionIndex;
  final int totalXp;
  final int questionsCorrect;
  final int firstGuesses;

  const DailyFlashGameProgress({
    required this.dateKey,
    required this.nextQuestionIndex,
    required this.totalXp,
    required this.questionsCorrect,
    required this.firstGuesses,
  });

  bool get allQuestionsAttempted => nextQuestionIndex >= 5;

  factory DailyFlashGameProgress.newDay(String dateKey) {
    return DailyFlashGameProgress(
      dateKey: dateKey,
      nextQuestionIndex: 0,
      totalXp: 0,
      questionsCorrect: 0,
      firstGuesses: 0,
    );
  }

  DailyFlashGameProgress copyWith({
    String? dateKey,
    int? nextQuestionIndex,
    int? totalXp,
    int? questionsCorrect,
    int? firstGuesses,
  }) {
    return DailyFlashGameProgress(
      dateKey: dateKey ?? this.dateKey,
      nextQuestionIndex: nextQuestionIndex ?? this.nextQuestionIndex,
      totalXp: totalXp ?? this.totalXp,
      questionsCorrect: questionsCorrect ?? this.questionsCorrect,
      firstGuesses: firstGuesses ?? this.firstGuesses,
    );
  }
}

class DailyFlashGameProgressService {
  DailyFlashGameProgressService._();

  static const int _cloudSchemaVersion = 1;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const Set<String> supportedGameKeys = <String>{
    'first_word',
    'first_connection',
    'first_date',
    'first_match',
    'first_order',
  };

  static String todayKey() {
    return DailyFlashScheduleService.activeDateKey();
  }

  static String _safeGameKey(String gameKey) {
    final String cleaned = gameKey.trim().toLowerCase();
    if (!supportedGameKeys.contains(cleaned)) {
      throw ArgumentError.value(gameKey, 'gameKey', 'Unsupported Daily Flash game');
    }
    return cleaned;
  }

  static String _pref(String gameKey, String field) =>
      'daily_flash_5_${_safeGameKey(gameKey)}_$field';

  static DocumentReference<Map<String, dynamic>>? _cloudDocument(
    String gameKey,
  ) {
    final User? user = _auth.currentUser;
    if (user == null) return null;

    return _firestore
        .collection('players')
        .doc(user.uid)
        .collection('progress')
        .doc('daily_flash_${_safeGameKey(gameKey)}');
  }

  static Future<DailyFlashGameProgress> _loadLocal(
    SharedPreferences preferences,
    String gameKey,
    String today,
  ) async {
    final String? savedDate = preferences.getString(_pref(gameKey, 'date'));

    if (savedDate != today) {
      return DailyFlashGameProgress.newDay(today);
    }

    return DailyFlashGameProgress(
      dateKey: today,
      nextQuestionIndex:
          (preferences.getInt(_pref(gameKey, 'next_question')) ?? 0).clamp(0, 5),
      totalXp: preferences.getInt(_pref(gameKey, 'total_xp')) ?? 0,
      questionsCorrect:
          (preferences.getInt(_pref(gameKey, 'questions_correct')) ?? 0)
              .clamp(0, 5),
      firstGuesses:
          (preferences.getInt(_pref(gameKey, 'first_guesses')) ?? 0).clamp(0, 5),
    );
  }

  static DailyFlashGameProgress? _fromCloud(
    Map<String, dynamic>? data,
    String today,
  ) {
    if (data == null || data['dateKey'] != today) return null;

    int readInt(String key) {
      final dynamic value = data[key];
      if (value is int) return value;
      if (value is num) return value.toInt();
      return 0;
    }

    return DailyFlashGameProgress(
      dateKey: today,
      nextQuestionIndex: readInt('nextQuestionIndex').clamp(0, 5),
      totalXp: readInt('totalXp').clamp(0, 1 << 31),
      questionsCorrect: readInt('questionsCorrect').clamp(0, 5),
      firstGuesses: readInt('firstGuesses').clamp(0, 5),
    );
  }

  static DailyFlashGameProgress _merge(
    DailyFlashGameProgress local,
    DailyFlashGameProgress cloud,
  ) {
    int maxInt(int a, int b) => a > b ? a : b;

    return DailyFlashGameProgress(
      dateKey: local.dateKey,
      nextQuestionIndex:
          maxInt(local.nextQuestionIndex, cloud.nextQuestionIndex),
      totalXp: maxInt(local.totalXp, cloud.totalXp),
      questionsCorrect:
          maxInt(local.questionsCorrect, cloud.questionsCorrect),
      firstGuesses: maxInt(local.firstGuesses, cloud.firstGuesses),
    );
  }

  static Map<String, dynamic> _toCloud(DailyFlashGameProgress progress) {
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

  static Future<void> _saveLocal(
    SharedPreferences preferences,
    String gameKey,
    DailyFlashGameProgress progress,
  ) async {
    await Future.wait(<Future<bool>>[
      preferences.setString(_pref(gameKey, 'date'), progress.dateKey),
      preferences.setInt(
        _pref(gameKey, 'next_question'),
        progress.nextQuestionIndex,
      ),
      preferences.setInt(_pref(gameKey, 'total_xp'), progress.totalXp),
      preferences.setInt(
        _pref(gameKey, 'questions_correct'),
        progress.questionsCorrect,
      ),
      preferences.setInt(
        _pref(gameKey, 'first_guesses'),
        progress.firstGuesses,
      ),
    ]);
  }

  static Future<DailyFlashGameProgress> loadToday({
    required String gameKey,
  }) async {
    final String safeKey = _safeGameKey(gameKey);
    final String today = todayKey();
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    final DailyFlashGameProgress local =
        await _loadLocal(preferences, safeKey, today);
    final DocumentReference<Map<String, dynamic>>? cloud =
        _cloudDocument(safeKey);

    if (cloud == null) {
      await _saveLocal(preferences, safeKey, local);
      return local;
    }

    try {
      final DocumentSnapshot<Map<String, dynamic>> snapshot = await cloud.get();
      final DailyFlashGameProgress? cloudProgress =
          _fromCloud(snapshot.data(), today);
      final DailyFlashGameProgress merged =
          cloudProgress == null ? local : _merge(local, cloudProgress);

      await _saveLocal(preferences, safeKey, merged);

      if (cloudProgress == null ||
          cloudProgress.nextQuestionIndex != merged.nextQuestionIndex ||
          cloudProgress.totalXp != merged.totalXp ||
          cloudProgress.questionsCorrect != merged.questionsCorrect ||
          cloudProgress.firstGuesses != merged.firstGuesses) {
        await cloud.set(_toCloud(merged), SetOptions(merge: true));
      }

      return merged;
    } on FirebaseException {
      await _saveLocal(preferences, safeKey, local);
      return local;
    }
  }

  static Future<DailyFlashGameProgress> recordResult({
    required String gameKey,
    required DailyFlashGameProgress progress,
    required int questionIndex,
    required bool correct,
    required int xpEarned,
    required bool wasFirstGuess,
  }) async {
    final String safeKey = _safeGameKey(gameKey);
    final String today = todayKey();
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    final DocumentReference<Map<String, dynamic>>? cloud =
        _cloudDocument(safeKey);

    DailyFlashGameProgress apply(DailyFlashGameProgress base) {
      if (questionIndex < base.nextQuestionIndex) return base;
      if (questionIndex > base.nextQuestionIndex) return base;

      return base.copyWith(
        nextQuestionIndex: (questionIndex + 1).clamp(0, 5),
        totalXp: base.totalXp + (correct ? xpEarned : 0),
        questionsCorrect:
            base.questionsCorrect + (correct ? 1 : 0),
        firstGuesses:
            base.firstGuesses + (correct && wasFirstGuess ? 1 : 0),
      );
    }

    if (cloud == null) {
      final DailyFlashGameProgress updated = apply(progress);
      await _saveLocal(preferences, safeKey, updated);
      return updated;
    }

    final String resultId = '${today}_question_$questionIndex';
    final DocumentReference<Map<String, dynamic>> resultDocument =
        cloud.collection('processed_results').doc(resultId);

    try {
      final DailyFlashGameProgress updated =
          await _firestore.runTransaction<DailyFlashGameProgress>(
        (Transaction transaction) async {
          final DocumentSnapshot<Map<String, dynamic>> resultSnapshot =
              await transaction.get(resultDocument);
          final DocumentSnapshot<Map<String, dynamic>> progressSnapshot =
              await transaction.get(cloud);

          final DailyFlashGameProgress cloudProgress =
              _fromCloud(progressSnapshot.data(), today) ??
                  DailyFlashGameProgress.newDay(today);

          if (resultSnapshot.exists) return cloudProgress;

          final DailyFlashGameProgress next = apply(cloudProgress);

          transaction.set(cloud, _toCloud(next), SetOptions(merge: true));
          transaction.set(
            resultDocument,
            <String, dynamic>{
              'dateKey': today,
              'questionIndex': questionIndex,
              'correct': correct,
              'xpEarned': correct ? xpEarned : 0,
              'wasFirstGuess': correct && wasFirstGuess,
              'processedAt': FieldValue.serverTimestamp(),
              'schemaVersion': _cloudSchemaVersion,
            },
            SetOptions(merge: true),
          );

          return next;
        },
      );

      await _saveLocal(preferences, safeKey, updated);
      return updated;
    } on FirebaseException {
      final DailyFlashGameProgress updated = apply(progress);
      await _saveLocal(preferences, safeKey, updated);
      return updated;
    }
  }

  /// Clears today's non-Classic Daily Flash progress for every supported game.
  /// Intended for debug builds only.
  static Future<void> resetAllForTesting() async {
    final SharedPreferences preferences =
        await SharedPreferences.getInstance();

    for (final String gameKey in supportedGameKeys) {
      await Future.wait(<Future<bool>>[
        preferences.remove(_pref(gameKey, 'date')),
        preferences.remove(_pref(gameKey, 'next_question')),
        preferences.remove(_pref(gameKey, 'total_xp')),
        preferences.remove(_pref(gameKey, 'questions_correct')),
        preferences.remove(_pref(gameKey, 'first_guesses')),
      ]);

      final DocumentReference<Map<String, dynamic>>? cloud =
          _cloudDocument(gameKey);

      if (cloud == null) {
        continue;
      }

      try {
        final QuerySnapshot<Map<String, dynamic>> processedResults =
            await cloud.collection('processed_results').get();

        final WriteBatch batch = _firestore.batch();

        for (final QueryDocumentSnapshot<Map<String, dynamic>> document
            in processedResults.docs) {
          batch.delete(document.reference);
        }

        batch.delete(cloud);
        await batch.commit();
      } on FirebaseException {
        // Local reset still succeeds if Firestore is temporarily unavailable.
      }
    }
  }

}
