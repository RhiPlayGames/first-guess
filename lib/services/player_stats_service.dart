import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';


enum PlayerRankRole {
  clueSeeker,
  investigator,
  detective,
  sleuth,
  superSleuth,
}

enum PlayerRankTier {
  rookie,
  senior,
  expert,
  master,
  elite,
}

class PlayerRankProgress {
  static const int xpPerLevel = 1000;
  static const int maximumLevel = 25;

  final int totalXp;
  final int level;
  final PlayerRankRole role;
  final PlayerRankTier tier;
  final int currentLevelStartXp;
  final int nextLevelStartXp;

  const PlayerRankProgress({
    required this.totalXp,
    required this.level,
    required this.role,
    required this.tier,
    required this.currentLevelStartXp,
    required this.nextLevelStartXp,
  });

  factory PlayerRankProgress.fromXp(int xp) {
    final int safeXp = xp < 0 ? 0 : xp;
    final int calculatedLevel =
        (safeXp ~/ xpPerLevel) + 1;
    final int level = calculatedLevel.clamp(
      1,
      maximumLevel,
    );

    final int zeroBasedLevel = level - 1;
    final int roleIndex = zeroBasedLevel ~/ 5;
    final int tierIndex = zeroBasedLevel % 5;

    final int currentStart =
        zeroBasedLevel * xpPerLevel;

    final int nextStart = level >= maximumLevel
        ? currentStart
        : level * xpPerLevel;

    return PlayerRankProgress(
      totalXp: safeXp,
      level: level,
      role: PlayerRankRole.values[roleIndex],
      tier: PlayerRankTier.values[tierIndex],
      currentLevelStartXp: currentStart,
      nextLevelStartXp: nextStart,
    );
  }

  String get roleName {
    switch (role) {
      case PlayerRankRole.clueSeeker:
        return 'Clue Seeker';
      case PlayerRankRole.investigator:
        return 'Investigator';
      case PlayerRankRole.detective:
        return 'Detective';
      case PlayerRankRole.sleuth:
        return 'Sleuth';
      case PlayerRankRole.superSleuth:
        return 'Super Sleuth';
    }
  }

  String get tierName {
    switch (tier) {
      case PlayerRankTier.rookie:
        return 'Rookie';
      case PlayerRankTier.senior:
        return 'Senior';
      case PlayerRankTier.expert:
        return 'Expert';
      case PlayerRankTier.master:
        return 'Master';
      case PlayerRankTier.elite:
        return 'Elite';
    }
  }

  String get fullTitle => '$tierName $roleName';

  String get roleEmoji {
    switch (role) {
      case PlayerRankRole.clueSeeker:
        return '🔎';
      case PlayerRankRole.investigator:
        return '🧩';
      case PlayerRankRole.detective:
        return '🕵️';
      case PlayerRankRole.sleuth:
        return '🧐';
      case PlayerRankRole.superSleuth:
        return '⭐';
    }
  }

  bool get isMaximumLevel =>
      level >= maximumLevel;

  int get xpInsideCurrentLevel {
    if (isMaximumLevel) {
      return xpPerLevel;
    }

    return totalXp - currentLevelStartXp;
  }

  int get xpNeededForNextLevel {
    if (isMaximumLevel) {
      return 0;
    }

    return nextLevelStartXp - totalXp;
  }

  double get progress {
    if (isMaximumLevel) {
      return 1;
    }

    return (xpInsideCurrentLevel / xpPerLevel)
        .clamp(0.0, 1.0);
  }

  bool isPromotionFrom(
    PlayerRankProgress previous,
  ) {
    return level > previous.level &&
        role != previous.role;
  }

  bool isLevelUpFrom(
    PlayerRankProgress previous,
  ) {
    return level > previous.level;
  }
}

enum GameCategory {
  countries,
  capitalCities,
  flags,
  authors,
  animals,
  foodDrink,
  other,
}

class PlayerStats {
  final int profileVersion;

  final int totalScore;
  final int totalXp;
  final int gamesPlayed;
  final int firstGuesses;

  final int currentStreak;
  final int longestStreak;
  final int highestScore;

  final int totalCluesUsed;
  final int correctlySolvedGames;
  final int totalPlayTimeSeconds;

  final int countriesCompleted;
  final int capitalCitiesCompleted;
  final int flagsCompleted;
  final int authorsCompleted;
  final int moviesCompleted;
  final int booksCompleted;
  final int periodicTableCompleted;
  final int historicalFiguresCompleted;
  final int animalsCompleted;
  final int footballTeamsCompleted;

  const PlayerStats({
    this.profileVersion = 1,
    this.totalScore = 0,
    this.totalXp = 0,
    this.gamesPlayed = 0,
    this.firstGuesses = 0,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.highestScore = 0,
    this.totalCluesUsed = 0,
    this.correctlySolvedGames = 0,
    this.totalPlayTimeSeconds = 0,
    this.countriesCompleted = 0,
    this.capitalCitiesCompleted = 0,
    this.flagsCompleted = 0,
    this.authorsCompleted = 0,
    this.moviesCompleted = 0,
    this.booksCompleted = 0,
    this.periodicTableCompleted = 0,
    this.historicalFiguresCompleted = 0,
    this.animalsCompleted = 0,
    this.footballTeamsCompleted = 0,
  });

  double get firstGuessPercentage {
    if (gamesPlayed == 0) {
      return 0;
    }

    return (firstGuesses / gamesPlayed) * 100;
  }

  double get averageClueNeeded {
    if (correctlySolvedGames == 0) {
      return 0;
    }

    return totalCluesUsed / correctlySolvedGames;
  }

  PlayerStats copyWith({
    int? profileVersion,
    int? totalScore,
    int? totalXp,
    int? gamesPlayed,
    int? firstGuesses,
    int? currentStreak,
    int? longestStreak,
    int? highestScore,
    int? totalCluesUsed,
    int? correctlySolvedGames,
    int? totalPlayTimeSeconds,
    int? countriesCompleted,
    int? capitalCitiesCompleted,
    int? flagsCompleted,
    int? authorsCompleted,
    int? moviesCompleted,
    int? booksCompleted,
    int? periodicTableCompleted,
    int? historicalFiguresCompleted,
    int? animalsCompleted,
    int? footballTeamsCompleted,
  }) {
    return PlayerStats(
      profileVersion:
          profileVersion ?? this.profileVersion,
      totalScore:
          totalScore ?? this.totalScore,
      totalXp:
          totalXp ?? this.totalXp,
      gamesPlayed:
          gamesPlayed ?? this.gamesPlayed,
      firstGuesses:
          firstGuesses ?? this.firstGuesses,
      currentStreak:
          currentStreak ?? this.currentStreak,
      longestStreak:
          longestStreak ?? this.longestStreak,
      highestScore:
          highestScore ?? this.highestScore,
      totalCluesUsed:
          totalCluesUsed ?? this.totalCluesUsed,
      correctlySolvedGames:
          correctlySolvedGames ??
          this.correctlySolvedGames,
      totalPlayTimeSeconds:
          totalPlayTimeSeconds ??
          this.totalPlayTimeSeconds,
      countriesCompleted:
          countriesCompleted ??
          this.countriesCompleted,
      capitalCitiesCompleted:
          capitalCitiesCompleted ??
          this.capitalCitiesCompleted,
      flagsCompleted:
          flagsCompleted ?? this.flagsCompleted,
      authorsCompleted:
          authorsCompleted ?? this.authorsCompleted,
      moviesCompleted:
          moviesCompleted ?? this.moviesCompleted,
      booksCompleted:
          booksCompleted ?? this.booksCompleted,
      periodicTableCompleted:
          periodicTableCompleted ??
          this.periodicTableCompleted,
      historicalFiguresCompleted:
          historicalFiguresCompleted ??
          this.historicalFiguresCompleted,
      animalsCompleted:
          animalsCompleted ?? this.animalsCompleted,
      footballTeamsCompleted:
          footballTeamsCompleted ??
          this.footballTeamsCompleted,
    );
  }
}


class DailyFlashMilestone {
  final int completions;
  final int bonusXp;
  final int? nextTarget;

  const DailyFlashMilestone({
    required this.completions,
    required this.bonusXp,
    required this.nextTarget,
  });
}

class DailyFlashMilestoneService {
  DailyFlashMilestoneService._();

  static final SharedPreferencesAsync _preferences =
      SharedPreferencesAsync();

  static const String _completionKey =
      'daily_flash_lifetime_completions';

  static const String _lastCountedDateKey =
      'daily_flash_last_counted_date';

  static const String _perfectCompletionKey =
      'daily_flash_perfect_5s';

  static const String _awardedKeyPrefix =
      'daily_flash_milestone_awarded_';

  static const List<int> targets = <int>[
    10,
    25,
    50,
    100,
    150,
    200,
    250,
    300,
    400,
    500,
  ];

  // Easy to rebalance later.
  static const Map<int, int> milestoneBonusXp = <int, int>{
    10: 1000,
    25: 250,
    50: 500,
    100: 1000,
    150: 1500,
    200: 2000,
    250: 2500,
    300: 3000,
    400: 4000,
    500: 5000,
  };

  static String _todayKey() {
    final DateTime now = DateTime.now();
    final String month =
        now.month.toString().padLeft(2, '0');
    final String day =
        now.day.toString().padLeft(2, '0');

    return '${now.year}-$month-$day';
  }

  static int? _nextTargetFor(int completions) {
    final int index = targets.indexOf(completions);

    if (index < 0 || index + 1 >= targets.length) {
      return null;
    }

    return targets[index + 1];
  }

  /// Production completion counter.
  ///
  /// A Daily Flash can only count once per calendar day.
  /// Returns a milestone only when the NEW lifetime total
  /// exactly matches one of the milestone targets.
  static Future<DailyFlashMilestone?>
      recordCompletionAndAwardIfEarned({
    required bool perfect,
  }) async {
    final String today = _todayKey();

    final String? lastCountedDate =
        await _preferences.getString(
      _lastCountedDateKey,
    );

    if (lastCountedDate == today) {
      return null;
    }

    final int previous =
        await _preferences.getInt(
          _completionKey,
        ) ??
        0;

    final int completed = previous + 1;

    await _preferences.setInt(
      _completionKey,
      completed,
    );

    await _preferences.setString(
      _lastCountedDateKey,
      today,
    );

    if (perfect) {
      final int previousPerfect =
          await _preferences.getInt(
            _perfectCompletionKey,
          ) ??
          0;

      await _preferences.setInt(
        _perfectCompletionKey,
        previousPerfect + 1,
      );
    }

    if (!targets.contains(completed)) {
      return null;
    }

    final String awardedKey =
        '$_awardedKeyPrefix$completed';

    final bool alreadyAwarded =
        await _preferences.getBool(
          awardedKey,
        ) ??
        false;

    if (alreadyAwarded) {
      return null;
    }

    await _preferences.setBool(
      awardedKey,
      true,
    );

    return DailyFlashMilestone(
      completions: completed,
      bonusXp:
          milestoneBonusXp[completed] ?? 0,
      nextTarget:
          _nextTargetFor(completed),
    );
  }

  static Future<int> loadLifetimeCompletions() async {
    return await _preferences.getInt(
          _completionKey,
        ) ??
        0;
  }

  static Future<int> loadPerfect5s() async {
    return await _preferences.getInt(
          _perfectCompletionKey,
        ) ??
        0;
  }

  /// QA helper only.
  ///
  /// Lets us force a milestone screen without changing
  /// lifetime completion totals or awarding real XP.
  static DailyFlashMilestone previewForTesting(
    int completions,
  ) {
    return DailyFlashMilestone(
      completions: completions,
      bonusXp:
          milestoneBonusXp[completions] ?? 0,
      nextTarget:
          _nextTargetFor(completions),
    );
  }
}

class QuestionHistoryService {
  QuestionHistoryService._();

  static final SharedPreferencesAsync _preferences =
      SharedPreferencesAsync();

  static final FirebaseAuth _auth =
      FirebaseAuth.instance;

  static final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  static const String storageKey =
      'played_question_ids_v1';

  static const int _cloudSchemaVersion = 1;

  static DocumentReference<Map<String, dynamic>>?
      get _cloudHistoryDocument {
    final User? user = _auth.currentUser;

    if (user == null) {
      return null;
    }

    return _firestore
        .collection('players')
        .doc(user.uid)
        .collection('progress')
        .doc('question_history');
  }

  static Future<Set<String>> _loadLocalPlayedQuestionIds() async {
    final List<String> savedIds =
        await _preferences.getStringList(storageKey) ??
        <String>[];

    return savedIds.toSet();
  }

  static Future<void> _saveLocalPlayedQuestionIds(
    Set<String> playedIds,
  ) async {
    final List<String> sortedIds =
        playedIds.toList()..sort();

    await _preferences.setStringList(
      storageKey,
      sortedIds,
    );
  }

  static Set<String> _playedIdsFromCloudData(
    Map<String, dynamic>? data,
  ) {
    final dynamic rawIds = data?['playedQuestionIds'];

    if (rawIds is! List) {
      return <String>{};
    }

    return rawIds
        .whereType<String>()
        .where((String id) => id.isNotEmpty)
        .toSet();
  }

  static Future<Set<String>> loadPlayedQuestionIds() async {
    final Set<String> localIds =
        await _loadLocalPlayedQuestionIds();

    final DocumentReference<Map<String, dynamic>>?
        cloudDocument = _cloudHistoryDocument;

    if (cloudDocument == null) {
      return localIds;
    }

    try {
      final DocumentSnapshot<Map<String, dynamic>>
          snapshot = await cloudDocument.get();

      final Set<String> cloudIds =
          _playedIdsFromCloudData(snapshot.data());

      final Set<String> mergedIds = <String>{
        ...localIds,
        ...cloudIds,
      };

      if (mergedIds.length != localIds.length ||
          !localIds.containsAll(mergedIds)) {
        await _saveLocalPlayedQuestionIds(mergedIds);
      }

      final bool cloudNeedsUpdate =
          !snapshot.exists ||
          cloudIds.length != mergedIds.length ||
          !cloudIds.containsAll(mergedIds);

      if (cloudNeedsUpdate) {
        final List<String> sortedMergedIds =
            mergedIds.toList()..sort();

        await cloudDocument.set(
          <String, dynamic>{
            'playedQuestionIds': sortedMergedIds,
            'schemaVersion': _cloudSchemaVersion,
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
      }

      return mergedIds;
    } on FirebaseException {
      // Local history remains the gameplay fallback if cloud sync
      // is temporarily unavailable or Firestore rules are not ready.
      return localIds;
    }
  }

  static Future<int> countPlayedQuestionsByPrefix(
    String questionIdPrefix,
  ) async {
    if (questionIdPrefix.isEmpty) {
      return 0;
    }

    final Set<String> playedIds =
        await loadPlayedQuestionIds();

    return playedIds
        .where(
          (String id) => id.startsWith(questionIdPrefix),
        )
        .length;
  }

  static Future<Map<String, int>>
      countPlayedQuestionsByPrefixes(
    Iterable<String> questionIdPrefixes,
  ) async {
    final Set<String> playedIds =
        await loadPlayedQuestionIds();

    final Map<String, int> counts = <String, int>{};

    for (final String prefix in questionIdPrefixes) {
      if (prefix.isEmpty) {
        continue;
      }

      counts[prefix] = playedIds
          .where((String id) => id.startsWith(prefix))
          .length;
    }

    return counts;
  }

  static Future<bool> hasPlayedQuestion(
    String questionId,
  ) async {
    if (questionId.isEmpty) {
      return false;
    }

    final Set<String> playedIds =
        await loadPlayedQuestionIds();

    return playedIds.contains(questionId);
  }

  static Future<void> recordPlayedQuestion(
    String questionId,
  ) async {
    if (questionId.isEmpty) {
      return;
    }

    final Set<String> playedIds =
        await loadPlayedQuestionIds();

    final bool wasNewLocalId =
        playedIds.add(questionId);

    if (wasNewLocalId) {
      await _saveLocalPlayedQuestionIds(playedIds);
    }

    final DocumentReference<Map<String, dynamic>>?
        cloudDocument = _cloudHistoryDocument;

    if (cloudDocument == null) {
      return;
    }

    try {
      await cloudDocument.set(
        <String, dynamic>{
          'playedQuestionIds':
              FieldValue.arrayUnion(<String>[questionId]),
          'schemaVersion': _cloudSchemaVersion,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    } on FirebaseException {
      // Keep the local record even if cloud sync temporarily fails.
      // The next load will merge local history back into Firebase.
    }
  }

  /// QA helper only.
  ///
  /// Removes played-question history for one subcategory prefix
  /// without changing any other question history.
  ///
  /// When signed in, the same filtered history is written to
  /// Firebase so the removed IDs are not restored on the next load.
  static Future<int> clearHistoryByPrefix(
    String questionIdPrefix,
  ) async {
    if (questionIdPrefix.isEmpty) {
      return 0;
    }

    final Set<String> localIds =
        await _loadLocalPlayedQuestionIds();

    final DocumentReference<Map<String, dynamic>>?
        cloudDocument = _cloudHistoryDocument;

    if (cloudDocument == null) {
      final int removedCount = localIds
          .where(
            (String id) =>
                id.startsWith(questionIdPrefix),
          )
          .length;

      localIds.removeWhere(
        (String id) =>
            id.startsWith(questionIdPrefix),
      );

      await _saveLocalPlayedQuestionIds(localIds);

      return removedCount;
    }

    try {
      final DocumentSnapshot<Map<String, dynamic>>
          snapshot = await cloudDocument.get();

      final Set<String> cloudIds =
          _playedIdsFromCloudData(snapshot.data());

      final Set<String> mergedIds = <String>{
        ...localIds,
        ...cloudIds,
      };

      final int removedCount = mergedIds
          .where(
            (String id) =>
                id.startsWith(questionIdPrefix),
          )
          .length;

      mergedIds.removeWhere(
        (String id) =>
            id.startsWith(questionIdPrefix),
      );

      final List<String> sortedRemainingIds =
          mergedIds.toList()..sort();

      await cloudDocument.set(
        <String, dynamic>{
          'playedQuestionIds': sortedRemainingIds,
          'schemaVersion': _cloudSchemaVersion,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      await _saveLocalPlayedQuestionIds(mergedIds);

      return removedCount;
    } on FirebaseException {
      // Do not partially clear local history if the matching
      // Firebase history could not also be updated.
      rethrow;
    }
  }

  static Future<void> clearHistory() async {
    await _preferences.remove(storageKey);

    final DocumentReference<Map<String, dynamic>>?
        cloudDocument = _cloudHistoryDocument;

    if (cloudDocument == null) {
      return;
    }

    try {
      await cloudDocument.delete();
    } on FirebaseException {
      // Local history is still cleared even if cloud deletion fails.
    }
  }
}

class PlayerStatsService {
  PlayerStatsService._();

  static final SharedPreferencesAsync _preferences =
      SharedPreferencesAsync();

  static final FirebaseAuth _auth =
      FirebaseAuth.instance;

  static final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  static const int _cloudSchemaVersion = 1;

  static const String _profileVersionKey =
      'profile_version';

  static const String _totalScoreKey =
      'total_score';

  static const String _totalXpKey =
      'total_xp';

  static const String _gamesPlayedKey =
      'games_played';

  static const String _firstGuessesKey =
      'first_guesses';

  static const String _currentStreakKey =
      'current_streak';

  static const String _longestStreakKey =
      'longest_streak';

  static const String _highestScoreKey =
      'highest_score';

  static const String _totalCluesUsedKey =
      'total_clues_used';

  static const String _correctlySolvedGamesKey =
      'correctly_solved_games';

  static const String _totalPlayTimeSecondsKey =
      'total_play_time_seconds';

  static const String _countriesCompletedKey =
      'countries_completed';

  static const String _capitalCitiesCompletedKey =
      'capital_cities_completed';

  static const String _flagsCompletedKey =
      'flags_completed';

  static const String _authorsCompletedKey =
      'authors_completed';

  static const String _moviesCompletedKey =
      'movies_completed';

  static const String _booksCompletedKey =
      'books_completed';

  static const String _periodicTableCompletedKey =
      'periodic_table_completed';

  static const String _historicalFiguresCompletedKey =
      'historical_figures_completed';

  static const String _animalsCompletedKey =
      'animals_completed';

  static const String _footballTeamsCompletedKey =
      'football_teams_completed';

  static DocumentReference<Map<String, dynamic>>?
      get _cloudStatsDocument {
    final User? user = _auth.currentUser;

    if (user == null) {
      return null;
    }

    return _firestore
        .collection('players')
        .doc(user.uid)
        .collection('progress')
        .doc('player_stats');
  }

  static Future<PlayerStats> _loadLocalStats() async {
    final int totalScore =
        await _preferences.getInt(
          _totalScoreKey,
        ) ??
        0;

    final int? savedXp =
        await _preferences.getInt(
          _totalXpKey,
        );

    final int totalXp = savedXp ?? totalScore;

    if (savedXp == null) {
      await _preferences.setInt(
        _totalXpKey,
        totalXp,
      );
    }

    return PlayerStats(
      profileVersion:
          await _preferences.getInt(
            _profileVersionKey,
          ) ??
          1,
      totalScore: totalScore,
      totalXp: totalXp,
      gamesPlayed:
          await _preferences.getInt(
            _gamesPlayedKey,
          ) ??
          0,
      firstGuesses:
          await _preferences.getInt(
            _firstGuessesKey,
          ) ??
          0,
      currentStreak:
          await _preferences.getInt(
            _currentStreakKey,
          ) ??
          0,
      longestStreak:
          await _preferences.getInt(
            _longestStreakKey,
          ) ??
          0,
      highestScore:
          await _preferences.getInt(
            _highestScoreKey,
          ) ??
          0,
      totalCluesUsed:
          await _preferences.getInt(
            _totalCluesUsedKey,
          ) ??
          0,
      correctlySolvedGames:
          await _preferences.getInt(
            _correctlySolvedGamesKey,
          ) ??
          0,
      totalPlayTimeSeconds:
          await _preferences.getInt(
            _totalPlayTimeSecondsKey,
          ) ??
          0,
      countriesCompleted:
          await _preferences.getInt(
            _countriesCompletedKey,
          ) ??
          0,
      capitalCitiesCompleted:
          await _preferences.getInt(
            _capitalCitiesCompletedKey,
          ) ??
          0,
      flagsCompleted:
          await _preferences.getInt(
            _flagsCompletedKey,
          ) ??
          0,
      authorsCompleted:
          await _preferences.getInt(
            _authorsCompletedKey,
          ) ??
          0,
      moviesCompleted:
          await _preferences.getInt(
            _moviesCompletedKey,
          ) ??
          0,
      booksCompleted:
          await _preferences.getInt(
            _booksCompletedKey,
          ) ??
          0,
      periodicTableCompleted:
          await _preferences.getInt(
            _periodicTableCompletedKey,
          ) ??
          0,
      historicalFiguresCompleted:
          await _preferences.getInt(
            _historicalFiguresCompletedKey,
          ) ??
          0,
      animalsCompleted:
          await _preferences.getInt(
            _animalsCompletedKey,
          ) ??
          0,
      footballTeamsCompleted:
          await _preferences.getInt(
            _footballTeamsCompletedKey,
          ) ??
          0,
    );
  }

  static int _cloudInt(
    Map<String, dynamic> data,
    String key,
    int fallback,
  ) {
    final dynamic value = data[key];

    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return fallback;
  }

  static PlayerStats _statsFromCloudData(
    Map<String, dynamic> data,
    PlayerStats fallback,
  ) {
    return PlayerStats(
      profileVersion: _cloudInt(
        data,
        'profileVersion',
        fallback.profileVersion,
      ),
      totalScore: _cloudInt(
        data,
        'totalScore',
        fallback.totalScore,
      ),
      totalXp: _cloudInt(
        data,
        'totalXp',
        fallback.totalXp,
      ),
      gamesPlayed: _cloudInt(
        data,
        'gamesPlayed',
        fallback.gamesPlayed,
      ),
      firstGuesses: _cloudInt(
        data,
        'firstGuesses',
        fallback.firstGuesses,
      ),
      currentStreak: _cloudInt(
        data,
        'currentStreak',
        fallback.currentStreak,
      ),
      longestStreak: _cloudInt(
        data,
        'longestStreak',
        fallback.longestStreak,
      ),
      highestScore: _cloudInt(
        data,
        'highestScore',
        fallback.highestScore,
      ),
      totalCluesUsed: _cloudInt(
        data,
        'totalCluesUsed',
        fallback.totalCluesUsed,
      ),
      correctlySolvedGames: _cloudInt(
        data,
        'correctlySolvedGames',
        fallback.correctlySolvedGames,
      ),
      totalPlayTimeSeconds: _cloudInt(
        data,
        'totalPlayTimeSeconds',
        fallback.totalPlayTimeSeconds,
      ),
      countriesCompleted: _cloudInt(
        data,
        'countriesCompleted',
        fallback.countriesCompleted,
      ),
      capitalCitiesCompleted: _cloudInt(
        data,
        'capitalCitiesCompleted',
        fallback.capitalCitiesCompleted,
      ),
      flagsCompleted: _cloudInt(
        data,
        'flagsCompleted',
        fallback.flagsCompleted,
      ),
      authorsCompleted: _cloudInt(
        data,
        'authorsCompleted',
        fallback.authorsCompleted,
      ),
      moviesCompleted: _cloudInt(
        data,
        'moviesCompleted',
        fallback.moviesCompleted,
      ),
      booksCompleted: _cloudInt(
        data,
        'booksCompleted',
        fallback.booksCompleted,
      ),
      periodicTableCompleted: _cloudInt(
        data,
        'periodicTableCompleted',
        fallback.periodicTableCompleted,
      ),
      historicalFiguresCompleted: _cloudInt(
        data,
        'historicalFiguresCompleted',
        fallback.historicalFiguresCompleted,
      ),
      animalsCompleted: _cloudInt(
        data,
        'animalsCompleted',
        fallback.animalsCompleted,
      ),
      footballTeamsCompleted: _cloudInt(
        data,
        'footballTeamsCompleted',
        fallback.footballTeamsCompleted,
      ),
    );
  }

  static Map<String, dynamic> _statsToCloudData(
    PlayerStats stats,
  ) {
    return <String, dynamic>{
      'profileVersion': stats.profileVersion,
      'totalScore': stats.totalScore,
      'totalXp': stats.totalXp,
      'gamesPlayed': stats.gamesPlayed,
      'firstGuesses': stats.firstGuesses,
      'currentStreak': stats.currentStreak,
      'longestStreak': stats.longestStreak,
      'highestScore': stats.highestScore,
      'totalCluesUsed': stats.totalCluesUsed,
      'correctlySolvedGames':
          stats.correctlySolvedGames,
      'totalPlayTimeSeconds':
          stats.totalPlayTimeSeconds,
      'countriesCompleted':
          stats.countriesCompleted,
      'capitalCitiesCompleted':
          stats.capitalCitiesCompleted,
      'flagsCompleted': stats.flagsCompleted,
      'authorsCompleted': stats.authorsCompleted,
      'moviesCompleted': stats.moviesCompleted,
      'booksCompleted': stats.booksCompleted,
      'periodicTableCompleted':
          stats.periodicTableCompleted,
      'historicalFiguresCompleted':
          stats.historicalFiguresCompleted,
      'animalsCompleted': stats.animalsCompleted,
      'footballTeamsCompleted':
          stats.footballTeamsCompleted,
      'schemaVersion': _cloudSchemaVersion,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  static Future<void> _saveLocalStats(
    PlayerStats stats,
  ) async {
    await Future.wait([
      _preferences.setInt(
        _profileVersionKey,
        stats.profileVersion,
      ),
      _preferences.setInt(
        _totalScoreKey,
        stats.totalScore,
      ),
      _preferences.setInt(
        _totalXpKey,
        stats.totalXp,
      ),
      _preferences.setInt(
        _gamesPlayedKey,
        stats.gamesPlayed,
      ),
      _preferences.setInt(
        _firstGuessesKey,
        stats.firstGuesses,
      ),
      _preferences.setInt(
        _currentStreakKey,
        stats.currentStreak,
      ),
      _preferences.setInt(
        _longestStreakKey,
        stats.longestStreak,
      ),
      _preferences.setInt(
        _highestScoreKey,
        stats.highestScore,
      ),
      _preferences.setInt(
        _totalCluesUsedKey,
        stats.totalCluesUsed,
      ),
      _preferences.setInt(
        _correctlySolvedGamesKey,
        stats.correctlySolvedGames,
      ),
      _preferences.setInt(
        _totalPlayTimeSecondsKey,
        stats.totalPlayTimeSeconds,
      ),
      _preferences.setInt(
        _countriesCompletedKey,
        stats.countriesCompleted,
      ),
      _preferences.setInt(
        _capitalCitiesCompletedKey,
        stats.capitalCitiesCompleted,
      ),
      _preferences.setInt(
        _flagsCompletedKey,
        stats.flagsCompleted,
      ),
      _preferences.setInt(
        _authorsCompletedKey,
        stats.authorsCompleted,
      ),
      _preferences.setInt(
        _moviesCompletedKey,
        stats.moviesCompleted,
      ),
      _preferences.setInt(
        _booksCompletedKey,
        stats.booksCompleted,
      ),
      _preferences.setInt(
        _periodicTableCompletedKey,
        stats.periodicTableCompleted,
      ),
      _preferences.setInt(
        _historicalFiguresCompletedKey,
        stats.historicalFiguresCompleted,
      ),
      _preferences.setInt(
        _animalsCompletedKey,
        stats.animalsCompleted,
      ),
      _preferences.setInt(
        _footballTeamsCompletedKey,
        stats.footballTeamsCompleted,
      ),
    ]);
  }

  static Future<PlayerStats> loadStats() async {
    final PlayerStats localStats =
        await _loadLocalStats();

    final DocumentReference<Map<String, dynamic>>?
        cloudDocument = _cloudStatsDocument;

    if (cloudDocument == null) {
      return localStats;
    }

    try {
      final DocumentSnapshot<Map<String, dynamic>>
          snapshot = await cloudDocument.get();

      if (!snapshot.exists) {
        await cloudDocument.set(
          _statsToCloudData(localStats),
          SetOptions(merge: true),
        );

        return localStats;
      }

      final Map<String, dynamic>? cloudData =
          snapshot.data();

      if (cloudData == null) {
        return localStats;
      }

      final PlayerStats cloudStats =
          _statsFromCloudData(
        cloudData,
        localStats,
      );

      await _saveLocalStats(cloudStats);

      return cloudStats;
    } on FirebaseException {
      // Local stats remain the gameplay fallback if cloud sync
      // is temporarily unavailable.
      return localStats;
    }
  }

  static Future<void> saveStats(
    PlayerStats stats,
  ) async {
    await _saveLocalStats(stats);

    final DocumentReference<Map<String, dynamic>>?
        cloudDocument = _cloudStatsDocument;

    if (cloudDocument == null) {
      return;
    }

    try {
      await cloudDocument.set(
        _statsToCloudData(stats),
        SetOptions(merge: true),
      );
    } on FirebaseException {
      // Keep the local stats even if cloud sync temporarily fails.
    }
  }

  /// Adds bonus XP without changing games played, score,
  /// streaks, clues, or category completion counts.
  static Future<PlayerStats> addBonusXp({
    required int xp,
  }) async {
    final PlayerStats currentStats =
        await loadStats();

    final PlayerStats updatedStats =
        currentStats.copyWith(
      totalXp: currentStats.totalXp + xp,
    );

    await saveStats(updatedStats);

    return updatedStats;
  }

  static Future<PlayerStats> recordCorrectGame({
    required PlayerStats currentStats,
    required GameCategory category,
    required int pointsWon,
    required int clueNumber,
    required bool wasFirstGuess,
    required int playTimeSeconds,
  }) async {
    final int newCurrentStreak =
        currentStats.currentStreak + 1;

    final int newCountriesCompleted =
        category == GameCategory.countries
            ? currentStats.countriesCompleted + 1
            : currentStats.countriesCompleted;

    final int newCapitalCitiesCompleted =
        category == GameCategory.capitalCities
            ? currentStats.capitalCitiesCompleted + 1
            : currentStats.capitalCitiesCompleted;

    final int newFlagsCompleted =
        category == GameCategory.flags
            ? currentStats.flagsCompleted + 1
            : currentStats.flagsCompleted;

    final int newAuthorsCompleted =
        category == GameCategory.authors
            ? currentStats.authorsCompleted + 1
            : currentStats.authorsCompleted;

    final int newAnimalsCompleted =
        category == GameCategory.animals
            ? currentStats.animalsCompleted + 1
            : currentStats.animalsCompleted;

    final PlayerStats updatedStats =
        currentStats.copyWith(
      totalScore:
          currentStats.totalScore + pointsWon,
      totalXp:
          currentStats.totalXp + pointsWon,
      gamesPlayed:
          currentStats.gamesPlayed + 1,
      firstGuesses:
          currentStats.firstGuesses +
          (wasFirstGuess ? 1 : 0),
      currentStreak:
          newCurrentStreak,
      longestStreak:
          newCurrentStreak >
                  currentStats.longestStreak
              ? newCurrentStreak
              : currentStats.longestStreak,
      highestScore:
          pointsWon > currentStats.highestScore
              ? pointsWon
              : currentStats.highestScore,
      totalCluesUsed:
          currentStats.totalCluesUsed +
          clueNumber,
      correctlySolvedGames:
          currentStats.correctlySolvedGames + 1,
      totalPlayTimeSeconds:
          currentStats.totalPlayTimeSeconds +
          playTimeSeconds,
      countriesCompleted:
          newCountriesCompleted,
      capitalCitiesCompleted:
          newCapitalCitiesCompleted,
      flagsCompleted:
          newFlagsCompleted,
      authorsCompleted:
          newAuthorsCompleted,
      animalsCompleted:
          newAnimalsCompleted,
    );

    await saveStats(updatedStats);

    return updatedStats;
  }

  static Future<PlayerStats> recordFailedGame({
    required PlayerStats currentStats,
    required int playTimeSeconds,
  }) async {
    final PlayerStats updatedStats =
        currentStats.copyWith(
      gamesPlayed:
          currentStats.gamesPlayed + 1,
      currentStreak: 0,
      totalPlayTimeSeconds:
          currentStats.totalPlayTimeSeconds +
          playTimeSeconds,
    );

    await saveStats(updatedStats);

    return updatedStats;
  }

  static Future<PlayerStats> recordCorrectCountry({
    required PlayerStats currentStats,
    required int pointsWon,
    required int clueNumber,
    required bool wasFirstGuess,
    required int playTimeSeconds,
  }) {
    return recordCorrectGame(
      currentStats: currentStats,
      category: GameCategory.countries,
      pointsWon: pointsWon,
      clueNumber: clueNumber,
      wasFirstGuess: wasFirstGuess,
      playTimeSeconds: playTimeSeconds,
    );
  }

  static Future<PlayerStats> recordCorrectCapitalCity({
    required PlayerStats currentStats,
    required int pointsWon,
    required int clueNumber,
    required bool wasFirstGuess,
    required int playTimeSeconds,
  }) {
    return recordCorrectGame(
      currentStats: currentStats,
      category: GameCategory.capitalCities,
      pointsWon: pointsWon,
      clueNumber: clueNumber,
      wasFirstGuess: wasFirstGuess,
      playTimeSeconds: playTimeSeconds,
    );
  }

  static Future<PlayerStats> recordCorrectFlag({
    required PlayerStats currentStats,
    required int pointsWon,
    required int clueNumber,
    required bool wasFirstGuess,
    required int playTimeSeconds,
  }) {
    return recordCorrectGame(
      currentStats: currentStats,
      category: GameCategory.flags,
      pointsWon: pointsWon,
      clueNumber: clueNumber,
      wasFirstGuess: wasFirstGuess,
      playTimeSeconds: playTimeSeconds,
    );
  }

  static Future<PlayerStats> recordCorrectAuthor({
    required PlayerStats currentStats,
    required int pointsWon,
    required int clueNumber,
    required bool wasFirstGuess,
    required int playTimeSeconds,
  }) {
    return recordCorrectGame(
      currentStats: currentStats,
      category: GameCategory.authors,
      pointsWon: pointsWon,
      clueNumber: clueNumber,
      wasFirstGuess: wasFirstGuess,
      playTimeSeconds: playTimeSeconds,
    );
  }

  static Future<PlayerStats> recordFailedCountry({
    required PlayerStats currentStats,
    required int playTimeSeconds,
  }) {
    return recordFailedGame(
      currentStats: currentStats,
      playTimeSeconds: playTimeSeconds,
    );
  }

  static Future<void> resetStats() async {
    await _preferences.clear(
      allowList: {
        _profileVersionKey,
        _totalScoreKey,
        _totalXpKey,
        _gamesPlayedKey,
        _firstGuessesKey,
        _currentStreakKey,
        _longestStreakKey,
        _highestScoreKey,
        _totalCluesUsedKey,
        _correctlySolvedGamesKey,
        _totalPlayTimeSecondsKey,
        _countriesCompletedKey,
        _capitalCitiesCompletedKey,
        _flagsCompletedKey,
        _authorsCompletedKey,
        _moviesCompletedKey,
        _booksCompletedKey,
        _periodicTableCompletedKey,
        _historicalFiguresCompletedKey,
        _animalsCompletedKey,
        _footballTeamsCompletedKey,
        QuestionHistoryService.storageKey,
      },
    );
  }
}
