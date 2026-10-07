import 'dart:convert';
import 'dart:developer' as developer;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'avatar_preferences_service.dart';
import 'player_profile_service.dart';


class PlayerRankProgress {
  static const int maximumLevel = 150;

  static const List<String> _rankNames = <String>[
    'Clue Champion',
    'Clue Legend',
    'Clue Master',
    'Clue Grandmaster',
    'Clue Genius',
    'Clue Elite',
    'Puzzle Champion',
    'Puzzle Legend',
    'Puzzle Master',
    'Puzzle Grandmaster',
    'Puzzle Genius',
    'Puzzle Elite',
    'Trivia Champion',
    'Trivia Legend',
    'Trivia Master',
    'Trivia Grandmaster',
    'Trivia Genius',
    'Trivia Elite',
    'Knowledge Champion',
    'Knowledge Legend',
    'Knowledge Master',
    'Knowledge Grandmaster',
    'Knowledge Genius',
    'Knowledge Elite',
    'Quiz Champion',
    'Quiz Legend',
    'Quiz Master',
    'Quiz Grandmaster',
    'Quiz Genius',
    'Quiz Elite',
  ];

  static const List<String> _stageNames = <String>[
    'I',
    'II',
    'III',
    'IV',
    'V',
  ];

  static const List<String> _tierNames = <String>[
    'Starter Tier',
    'Advanced Tier',
    'Expert Tier',
    'Master Tier',
    'Elite Tier',
  ];

  // Authoritative XP requirements from the 150-level progression workbook.
  // Each value is the XP needed to reach that level from the previous level.
  static const List<int> _xpNeededByLevel = <int>[
    1000, 1500, 2000, 2500, 3000, 4000, 4500, 5000, 5500, 6000,
    7000, 7500, 8000, 8500, 9000, 10000, 10500, 11000, 11500, 12000,
    13000, 13500, 14000, 14500, 15000, 16000, 16500, 17000, 17500, 18000,
    20000, 20500, 21000, 21500, 22000, 23000, 23500, 24000, 24500, 25000,
    26000, 26500, 27000, 27500, 28000, 29000, 29500, 30000, 30500, 31000,
    32000, 32500, 33000, 33500, 34000, 35000, 35500, 36000, 36500, 37000,
    39000, 39500, 40000, 40500, 41000, 42000, 42500, 43000, 43500, 44000,
    45000, 45500, 46000, 46500, 47000, 48000, 48500, 49000, 49500, 50000,
    51000, 51500, 52000, 52500, 53000, 54000, 54500, 55000, 55500, 56000,
    58000, 58500, 59000, 59500, 60000, 61000, 61500, 62000, 62500, 63000,
    64000, 64500, 65000, 65500, 66000, 67000, 67500, 68000, 68500, 69000,
    70000, 70500, 71000, 71500, 72000, 73000, 73500, 74000, 74500, 75000,
    77000, 77500, 78000, 78500, 79000, 80000, 80500, 81000, 81500, 82000,
    83000, 83500, 84000, 84500, 85000, 86000, 86500, 87000, 87500, 88000,
    89000, 89500, 90000, 90500, 91000, 93000, 93500, 94000, 94500, 95000,
  ];

  final int totalXp;
  final int level;
  final int currentLevelStartXp;
  final int nextLevelStartXp;

  const PlayerRankProgress._({
    required this.totalXp,
    required this.level,
    required this.currentLevelStartXp,
    required this.nextLevelStartXp,
  });

  factory PlayerRankProgress.fromXp(int xp) {
    final int safeXp = xp < 0 ? 0 : xp;

    int runningTotal = 0;
    int achievedLevel = 0;

    for (int index = 0; index < _xpNeededByLevel.length; index++) {
      runningTotal += _xpNeededByLevel[index];

      if (safeXp >= runningTotal) {
        achievedLevel = index + 1;
      } else {
        break;
      }
    }

    // Clue Champion I is shown from the beginning. Its Starter Tier badge is
    // earned when the player reaches the first 1,000 XP threshold.
    final int displayLevel = achievedLevel == 0 ? 1 : achievedLevel;

    final int currentStart;
    final int nextStart;

    if (achievedLevel == 0) {
      currentStart = 0;
      nextStart = cumulativeXpForLevel(1);
    } else {
      currentStart = cumulativeXpForLevel(displayLevel);
      nextStart = displayLevel >= maximumLevel
          ? currentStart
          : cumulativeXpForLevel(displayLevel + 1);
    }

    return PlayerRankProgress._(
      totalXp: safeXp,
      level: displayLevel,
      currentLevelStartXp: currentStart,
      nextLevelStartXp: nextStart,
    );
  }


  static int cumulativeXpForLevel(int targetLevel) {
    if (targetLevel <= 0) {
      return 0;
    }

    final int safeLevel = targetLevel.clamp(1, maximumLevel);

    int total = 0;
    for (int index = 0; index < safeLevel; index++) {
      total += _xpNeededByLevel[index];
    }

    return total;
  }

  static int xpRequiredForLevel(int targetLevel) {
    if (targetLevel < 1 || targetLevel > maximumLevel) {
      return 0;
    }

    return _xpNeededByLevel[targetLevel - 1];
  }

  static String fullTitleForLevel(int targetLevel) {
    final int safeLevel = targetLevel.clamp(1, maximumLevel);
    final int zeroBased = safeLevel - 1;
    final String rank = _rankNames[zeroBased ~/ 5];
    final String stage = _stageNames[zeroBased % 5];

    return '$rank $stage';
  }

  static String tierNameForLevel(int targetLevel) {
    final int safeLevel = targetLevel.clamp(1, maximumLevel);
    return _tierNames[(safeLevel - 1) ~/ 30];
  }

  String get rankName => _rankNames[(level - 1) ~/ 5];

  String get stageName => _stageNames[(level - 1) % 5];

  // Kept as a text alias because some existing UI refers to roleName.
  String get roleName => rankName;

  String get tierName => _tierNames[(level - 1) ~/ 30];

  String get fullTitle => '$rankName $stageName';

  bool get isBeforeFirstMilestone =>
      level == 1 && totalXp < cumulativeXpForLevel(1);

  String get nextFullTitle {
    if (isMaximumLevel) {
      return fullTitle;
    }

    if (isBeforeFirstMilestone) {
      return fullTitle;
    }

    return fullTitleForLevel(level + 1);
  }

  int get nextLevelXpRequirement {
    if (isMaximumLevel) {
      return 0;
    }

    if (isBeforeFirstMilestone) {
      return xpRequiredForLevel(1);
    }

    return xpRequiredForLevel(level + 1);
  }

  int get xpInsideCurrentLevel {
    if (isMaximumLevel) {
      return 0;
    }

    return (totalXp - currentLevelStartXp).clamp(
      0,
      nextLevelXpRequirement,
    );
  }

  int get xpNeededForNextLevel {
    if (isMaximumLevel) {
      return 0;
    }

    return (nextLevelStartXp - totalXp).clamp(
      0,
      nextLevelXpRequirement,
    );
  }

  double get progress {
    if (isMaximumLevel) {
      return 1;
    }

    final int requirement = nextLevelXpRequirement;
    if (requirement <= 0) {
      return 0;
    }

    return (xpInsideCurrentLevel / requirement).clamp(
      0.0,
      1.0,
    );
  }

  String get roleEmoji => '⭐';

  bool get isMaximumLevel => level >= maximumLevel;

  bool isPromotionFrom(
    PlayerRankProgress previous,
  ) {
    return level > previous.level &&
        tierName != previous.tierName;
  }

  bool isLevelUpFrom(
    PlayerRankProgress previous,
  ) {
    final bool crossedStarterMilestone =
        previous.isBeforeFirstMilestone &&
        !isBeforeFirstMilestone;

    return crossedStarterMilestone ||
        level > previous.level;
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
  final int firstWordCurrentStreak;
  final int firstWordLongestStreak;
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

  final Map<String, int> categoryCorrectCounts;
  final Map<String, int> categoryFirstGuessCounts;
  final Map<String, int> categoryCurrentStreakCounts;
  final Map<String, int> categoryLongestStreakCounts;

  const PlayerStats({
    this.profileVersion = 1,
    this.totalScore = 0,
    this.totalXp = 0,
    this.gamesPlayed = 0,
    this.firstGuesses = 0,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.firstWordCurrentStreak = 0,
    this.firstWordLongestStreak = 0,
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
    this.categoryCorrectCounts = const <String, int>{},
    this.categoryFirstGuessCounts = const <String, int>{},
    this.categoryCurrentStreakCounts = const <String, int>{},
    this.categoryLongestStreakCounts = const <String, int>{},
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
    int? firstWordCurrentStreak,
    int? firstWordLongestStreak,
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
    Map<String, int>? categoryCorrectCounts,
    Map<String, int>? categoryFirstGuessCounts,
    Map<String, int>? categoryCurrentStreakCounts,
    Map<String, int>? categoryLongestStreakCounts,
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
      firstWordCurrentStreak:
          firstWordCurrentStreak ?? this.firstWordCurrentStreak,
      firstWordLongestStreak:
          firstWordLongestStreak ?? this.firstWordLongestStreak,
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
      categoryCorrectCounts:
          categoryCorrectCounts ??
          this.categoryCorrectCounts,
      categoryFirstGuessCounts:
          categoryFirstGuessCounts ??
          this.categoryFirstGuessCounts,
      categoryCurrentStreakCounts:
          categoryCurrentStreakCounts ??
          this.categoryCurrentStreakCounts,
      categoryLongestStreakCounts:
          categoryLongestStreakCounts ??
          this.categoryLongestStreakCounts,
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

  static const String _gameCompletionCountsKey =
      'daily_flash_game_completion_counts_v1';

  static const String _gamePerfectCountsKey =
      'daily_flash_game_perfect_counts_v1';

  static const String _gameLastCountedDatesKey =
      'daily_flash_game_last_counted_dates_v1';

  static const String _gameStatsMigratedKey =
      'daily_flash_game_stats_migrated_v1';

  static const Set<String> supportedGameKeys = <String>{
    'classic',
    'first_word',
    'first_connection',
    'first_date',
    'first_match',
    'first_order',
  };

  static const String _awardedKeyPrefix =
      'daily_flash_milestone_awarded_';

  static const List<int> targets = <int>[
    1,
    10,
    50,
    100,
    250,
    365,
  ];

  // Milestones are progress-only. They do not award bonus XP.
  static const Map<int, int> milestoneBonusXp = <int, int>{};

  static String _normaliseGameKey(String gameKey) {
    final String cleaned = gameKey.trim().toLowerCase();
    return supportedGameKeys.contains(cleaned) ? cleaned : 'classic';
  }

  static Map<String, int> _decodeGameCounts(String? raw) {
    if (raw == null || raw.isEmpty) return <String, int>{};

    try {
      final dynamic decoded = jsonDecode(raw);
      if (decoded is! Map) return <String, int>{};

      final Map<String, int> result = <String, int>{};
      decoded.forEach((dynamic key, dynamic value) {
        if (key is String && value is num) {
          result[key] = value.toInt();
        }
      });
      return result;
    } catch (_) {
      return <String, int>{};
    }
  }

  static Map<String, String> _decodeGameDates(String? raw) {
    if (raw == null || raw.isEmpty) return <String, String>{};

    try {
      final dynamic decoded = jsonDecode(raw);
      if (decoded is! Map) return <String, String>{};

      final Map<String, String> result = <String, String>{};
      decoded.forEach((dynamic key, dynamic value) {
        if (key is String && value is String) {
          result[key] = value;
        }
      });
      return result;
    } catch (_) {
      return <String, String>{};
    }
  }

  static Future<void> _migrateLegacyDailyFlashStatsIfNeeded() async {
    final bool migrated =
        await _preferences.getBool(_gameStatsMigratedKey) ?? false;
    if (migrated) return;

    final int legacyCompleted =
        await _preferences.getInt(_completionKey) ?? 0;
    final int legacyPerfect =
        await _preferences.getInt(_perfectCompletionKey) ?? 0;

    final Map<String, int> completions = _decodeGameCounts(
      await _preferences.getString(_gameCompletionCountsKey),
    );
    final Map<String, int> perfects = _decodeGameCounts(
      await _preferences.getString(_gamePerfectCountsKey),
    );

    if ((completions['classic'] ?? 0) < legacyCompleted) {
      completions['classic'] = legacyCompleted;
    }
    if ((perfects['classic'] ?? 0) < legacyPerfect) {
      perfects['classic'] = legacyPerfect;
    }

    await _preferences.setString(
      _gameCompletionCountsKey,
      jsonEncode(completions),
    );
    await _preferences.setString(
      _gamePerfectCountsKey,
      jsonEncode(perfects),
    );
    await _preferences.setBool(_gameStatsMigratedKey, true);
  }

  static Future<Map<String, int>> loadGameCompletions() async {
    await _migrateLegacyDailyFlashStatsIfNeeded();
    return _decodeGameCounts(
      await _preferences.getString(_gameCompletionCountsKey),
    );
  }

  static Future<Map<String, int>> loadGamePerfect5s() async {
    await _migrateLegacyDailyFlashStatsIfNeeded();
    return _decodeGameCounts(
      await _preferences.getString(_gamePerfectCountsKey),
    );
  }

  static Future<int> loadGameCompletionCount(String gameKey) async {
    final Map<String, int> counts = await loadGameCompletions();
    return counts[_normaliseGameKey(gameKey)] ?? 0;
  }

  static Future<int> loadGamePerfect5Count(String gameKey) async {
    final Map<String, int> counts = await loadGamePerfect5s();
    return counts[_normaliseGameKey(gameKey)] ?? 0;
  }

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
    String gameKey = 'classic',
  }) async {
    final String today = _todayKey();
    final String safeGameKey = _normaliseGameKey(gameKey);

    await _migrateLegacyDailyFlashStatsIfNeeded();

    // Each of the six Daily Flash games can count once per day.
    final Map<String, String> gameLastCountedDates = _decodeGameDates(
      await _preferences.getString(_gameLastCountedDatesKey),
    );

    if (gameLastCountedDates[safeGameKey] == today) {
      return null;
    }

    final Map<String, int> gameCompletions = _decodeGameCounts(
      await _preferences.getString(_gameCompletionCountsKey),
    );
    gameCompletions[safeGameKey] =
        (gameCompletions[safeGameKey] ?? 0) + 1;

    await _preferences.setString(
      _gameCompletionCountsKey,
      jsonEncode(gameCompletions),
    );

    if (perfect) {
      final Map<String, int> gamePerfects = _decodeGameCounts(
        await _preferences.getString(_gamePerfectCountsKey),
      );
      gamePerfects[safeGameKey] =
          (gamePerfects[safeGameKey] ?? 0) + 1;

      await _preferences.setString(
        _gamePerfectCountsKey,
        jsonEncode(gamePerfects),
      );
    }

    gameLastCountedDates[safeGameKey] = today;
    await _preferences.setString(
      _gameLastCountedDatesKey,
      jsonEncode(gameLastCountedDates),
    );

    // The overall Daily Flash achievement series remains day-based:
    // completing several game types on the same calendar day advances
    // the lifetime Daily Flash count only once.
    final String? lastOverallCountedDate =
        await _preferences.getString(_lastCountedDateKey);

    if (lastOverallCountedDate == today) {
      return null;
    }

    final int previous =
        await _preferences.getInt(_completionKey) ?? 0;
    final int completed = previous + 1;

    await _preferences.setInt(_completionKey, completed);
    await _preferences.setString(_lastCountedDateKey, today);

    if (perfect) {
      final int previousPerfect =
          await _preferences.getInt(_perfectCompletionKey) ?? 0;
      await _preferences.setInt(
        _perfectCompletionKey,
        previousPerfect + 1,
      );
    }

    if (!targets.contains(completed)) {
      return null;
    }

    final String awardedKey = '$_awardedKeyPrefix$completed';
    final bool alreadyAwarded =
        await _preferences.getBool(awardedKey) ?? false;

    if (alreadyAwarded) {
      return null;
    }

    await _preferences.setBool(awardedKey, true);

    return DailyFlashMilestone(
      completions: completed,
      bonusXp: 0,
      nextTarget: _nextTargetFor(completed),
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
  static const Duration _memoryCacheLifetime = Duration(seconds: 30);

  static Set<String>? _memoryPlayedIds;
  static String? _memoryCacheUserId;
  static DateTime? _memoryCacheLoadedAt;

  static String? get _currentUserId => _auth.currentUser?.uid;

  static bool get _hasFreshMemoryCache {
    final Set<String>? cached = _memoryPlayedIds;
    final DateTime? loadedAt = _memoryCacheLoadedAt;

    if (cached == null || loadedAt == null) {
      return false;
    }

    if (_memoryCacheUserId != _currentUserId) {
      return false;
    }

    return DateTime.now().difference(loadedAt) < _memoryCacheLifetime;
  }

  static void _storeMemoryCache(Set<String> ids) {
    _memoryPlayedIds = Set<String>.from(ids);
    _memoryCacheUserId = _currentUserId;
    _memoryCacheLoadedAt = DateTime.now();
  }

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
    if (_hasFreshMemoryCache) {
      return Set<String>.from(_memoryPlayedIds!);
    }

    final Set<String> localIds =
        await _loadLocalPlayedQuestionIds();

    final DocumentReference<Map<String, dynamic>>?
        cloudDocument = _cloudHistoryDocument;

    if (cloudDocument == null) {
      _storeMemoryCache(localIds);
      return Set<String>.from(localIds);
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

      final Set<String> missingCloudIds =
          mergedIds.difference(cloudIds);

      if (!snapshot.exists || missingCloudIds.isNotEmpty) {
        await cloudDocument.set(
          <String, dynamic>{
            if (missingCloudIds.isNotEmpty)
              'playedQuestionIds': FieldValue.arrayUnion(
                missingCloudIds.toList(),
              ),
            'schemaVersion': _cloudSchemaVersion,
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
      }

      _storeMemoryCache(mergedIds);
      return Set<String>.from(mergedIds);
    } on FirebaseException {
      // Local history remains the gameplay fallback if cloud sync
      // is temporarily unavailable or Firestore rules are not ready.
      _storeMemoryCache(localIds);
      return Set<String>.from(localIds);
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

    _storeMemoryCache(playedIds);

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

  static Future<void> clearHistory() async {
    await _preferences.remove(storageKey);
    _memoryPlayedIds = <String>{};
    _memoryCacheUserId = _currentUserId;
    _memoryCacheLoadedAt = DateTime.now();

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

  static const Duration _statsMemoryCacheLifetime = Duration(seconds: 15);
  static PlayerStats? _statsMemoryCache;
  static String? _statsMemoryCacheUserId;
  static DateTime? _statsMemoryCacheLoadedAt;

  static String? get _statsCurrentUserId => _auth.currentUser?.uid;

  static bool get _hasFreshStatsMemoryCache {
    final PlayerStats? cached = _statsMemoryCache;
    final DateTime? loadedAt = _statsMemoryCacheLoadedAt;

    if (cached == null || loadedAt == null) {
      return false;
    }

    if (_statsMemoryCacheUserId != _statsCurrentUserId) {
      return false;
    }

    return DateTime.now().difference(loadedAt) < _statsMemoryCacheLifetime;
  }

  static void _storeStatsMemoryCache(PlayerStats stats) {
    _statsMemoryCache = stats;
    _statsMemoryCacheUserId = _statsCurrentUserId;
    _statsMemoryCacheLoadedAt = DateTime.now();
  }

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

  static const String _firstWordCurrentStreakKey =
      'first_word_current_streak';

  static const String _firstWordLongestStreakKey =
      'first_word_longest_streak';

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

  static const String _categoryCorrectCountsKey =
      'category_correct_counts_v1';

  static const String _categoryFirstGuessCountsKey =
      'category_first_guess_counts_v1';

  static const String _categoryCurrentStreakCountsKey =
      'category_current_streak_counts_v1';

  static const String _categoryLongestStreakCountsKey =
      'category_longest_streak_counts_v1';


  static const Set<String> _classicMainCategoryKeys = <String>{
    'animals',
    'books_authors',
    'countries',
    'creative_world',
    'famous_words',
    'food_drink',
    'music',
    'past_present',
    'science_nature',
    'sports',
    'watch_play',
    'famous_people',
  };

  static const String _classicStreakKey = 'classic_first_guess';


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

  static DocumentReference<Map<String, dynamic>>?
      get _publicLeaderboardStatsDocument {
    final User? user = _auth.currentUser;

    if (user == null) {
      return null;
    }

    return _firestore
        .collection('players')
        .doc(user.uid)
        .collection('leaderboard')
        .doc('public_stats');
  }

  static const String _globalLeaderboardRootCollection =
      'global_leaderboards';

  static const String _globalLeaderboardPlayersCollection =
      'players';

  static const String _globalAllTimePeriodId = 'all_time';

  static String _dailyGlobalLeaderboardPeriodId() {
    final DateTime now = DateTime.now();
    final String month = now.month.toString().padLeft(2, '0');
    final String day = now.day.toString().padLeft(2, '0');

    return 'daily_${now.year}-$month-$day';
  }

  static String _monthlyGlobalLeaderboardPeriodId() {
    final DateTime now = DateTime.now();
    final String month = now.month.toString().padLeft(2, '0');

    return 'monthly_${now.year}-$month';
  }

  static DocumentReference<Map<String, dynamic>>?
      _globalLeaderboardPlayerDocument(
    String periodId,
  ) {
    final User? user = _auth.currentUser;

    if (user == null) {
      return null;
    }

    return _firestore
        .collection(_globalLeaderboardRootCollection)
        .doc(periodId)
        .collection(_globalLeaderboardPlayersCollection)
        .doc(user.uid);
  }

  static Future<Map<String, dynamic>>
      _globalLeaderboardIdentityData() async {
    final User? user = _auth.currentUser;

    if (user == null) {
      return <String, dynamic>{};
    }

    final String? savedDisplayName =
        await PlayerProfileService.loadDisplayName();

    final String displayName =
        savedDisplayName != null && savedDisplayName.trim().isNotEmpty
            ? savedDisplayName.trim()
            : 'Player';

    final String avatarPath =
        await AvatarPreferencesService.loadSelectedAvatarPath() ??
            'assets/images/avatars/Final/optimized/default_avatar.webp';

    return <String, dynamic>{
      'userId': user.uid,
      'displayName': displayName,
      'avatarPath': avatarPath,
    };
  }


  static String _dailyLeaderboardDocumentId() {
    final DateTime now = DateTime.now();
    final String month = now.month.toString().padLeft(2, '0');
    final String day = now.day.toString().padLeft(2, '0');

    return 'daily_${now.year}-$month-$day';
  }

  static String _monthlyLeaderboardDocumentId() {
    final DateTime now = DateTime.now();
    final String month = now.month.toString().padLeft(2, '0');

    return 'monthly_${now.year}-$month';
  }

  static DocumentReference<Map<String, dynamic>>?
      _leaderboardPeriodDocument(
    String documentId,
  ) {
    final User? user = _auth.currentUser;

    if (user == null) {
      return null;
    }

    return _firestore
        .collection('players')
        .doc(user.uid)
        .collection('leaderboard')
        .doc(documentId);
  }

  static Future<void> _recordLeaderboardPeriodDelta({
    required int scoreDelta,
    required int firstGuessDelta,
  }) async {
    if (scoreDelta == 0 && firstGuessDelta == 0) {
      return;
    }

    final DocumentReference<Map<String, dynamic>>? dailyDocument =
        _leaderboardPeriodDocument(
      _dailyLeaderboardDocumentId(),
    );

    final DocumentReference<Map<String, dynamic>>? monthlyDocument =
        _leaderboardPeriodDocument(
      _monthlyLeaderboardDocumentId(),
    );

    if (dailyDocument == null || monthlyDocument == null) {
      return;
    }

    try {
      final WriteBatch batch = _firestore.batch();

      batch.set(
        dailyDocument,
        <String, dynamic>{
          'score': FieldValue.increment(scoreDelta),
          'firstGuesses': FieldValue.increment(firstGuessDelta),
          'schemaVersion': _cloudSchemaVersion,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      batch.set(
        monthlyDocument,
        <String, dynamic>{
          'score': FieldValue.increment(scoreDelta),
          'firstGuesses': FieldValue.increment(firstGuessDelta),
          'schemaVersion': _cloudSchemaVersion,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      await batch.commit();
    } on FirebaseException catch (error, stackTrace) {
      developer.log(
        'Period leaderboard sync failed: '
        '${error.code} - ${error.message}',
        name: 'PlayerStatsService',
        error: error,
        stackTrace: stackTrace,
      );
      // Period leaderboard sync must never block gameplay.
    }

    final DocumentReference<Map<String, dynamic>>?
        globalDailyDocument = _globalLeaderboardPlayerDocument(
      _dailyGlobalLeaderboardPeriodId(),
    );

    final DocumentReference<Map<String, dynamic>>?
        globalMonthlyDocument = _globalLeaderboardPlayerDocument(
      _monthlyGlobalLeaderboardPeriodId(),
    );

    if (globalDailyDocument == null || globalMonthlyDocument == null) {
      return;
    }

    try {
      final Map<String, dynamic> identity =
          await _globalLeaderboardIdentityData();

      final WriteBatch globalBatch = _firestore.batch();

      globalBatch.set(
        globalDailyDocument,
        <String, dynamic>{
          ...identity,
          'score': FieldValue.increment(scoreDelta),
          'firstGuesses': FieldValue.increment(firstGuessDelta),
          'schemaVersion': _cloudSchemaVersion,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      globalBatch.set(
        globalMonthlyDocument,
        <String, dynamic>{
          ...identity,
          'score': FieldValue.increment(scoreDelta),
          'firstGuesses': FieldValue.increment(firstGuessDelta),
          'schemaVersion': _cloudSchemaVersion,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      await globalBatch.commit();
    } on FirebaseException catch (error, stackTrace) {
      developer.log(
        'Global period leaderboard sync failed: '
        '${error.code} - ${error.message}',
        name: 'PlayerStatsService',
        error: error,
        stackTrace: stackTrace,
      );
      // Global leaderboard sync must never block gameplay or league stats.
    }
  }

  static Future<void> _syncPublicLeaderboardStats(
    PlayerStats stats,
  ) async {
    final DocumentReference<Map<String, dynamic>>?
        publicDocument = _publicLeaderboardStatsDocument;

    if (publicDocument == null) {
      return;
    }

    try {
      await publicDocument.set(
        <String, dynamic>{
          'totalScore': stats.totalScore,
          'firstGuesses': stats.firstGuesses,
          'schemaVersion': _cloudSchemaVersion,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    } on FirebaseException {
      // Public leaderboard sync must never block gameplay.
    }

    final DocumentReference<Map<String, dynamic>>?
        globalAllTimeDocument = _globalLeaderboardPlayerDocument(
      _globalAllTimePeriodId,
    );

    if (globalAllTimeDocument == null) {
      return;
    }

    try {
      final Map<String, dynamic> identity =
          await _globalLeaderboardIdentityData();

      await globalAllTimeDocument.set(
        <String, dynamic>{
          ...identity,
          'score': stats.totalScore,
          'firstGuesses': stats.firstGuesses,
          'schemaVersion': _cloudSchemaVersion,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    } on FirebaseException catch (error, stackTrace) {
      developer.log(
        'Global all-time leaderboard sync failed: '
        '${error.code} - ${error.message}',
        name: 'PlayerStatsService',
        error: error,
        stackTrace: stackTrace,
      );
      // Global leaderboard sync must never block gameplay or league stats.
    }
  }

  static Map<String, int> _decodeCategoryCounts(
    String? raw,
  ) {
    if (raw == null || raw.isEmpty) {
      return <String, int>{};
    }

    try {
      final dynamic decoded = jsonDecode(raw);

      if (decoded is! Map) {
        return <String, int>{};
      }

      final Map<String, int> result = <String, int>{};

      decoded.forEach((dynamic key, dynamic value) {
        if (key is String && value is num) {
          result[key] = value.toInt();
        }
      });

      return result;
    } catch (_) {
      return <String, int>{};
    }
  }

  static Map<String, int> _cloudCategoryCounts(
    dynamic raw,
    Map<String, int> fallback,
  ) {
    if (raw is! Map) {
      return Map<String, int>.from(fallback);
    }

    final Map<String, int> result = <String, int>{};

    raw.forEach((dynamic key, dynamic value) {
      if (key is String && value is num) {
        result[key] = value.toInt();
      }
    });

    return result;
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
      firstWordCurrentStreak:
          await _preferences.getInt(
            _firstWordCurrentStreakKey,
          ) ??
          0,
      firstWordLongestStreak:
          await _preferences.getInt(
            _firstWordLongestStreakKey,
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
      categoryCorrectCounts:
          _decodeCategoryCounts(
        await _preferences.getString(
          _categoryCorrectCountsKey,
        ),
      ),
      categoryFirstGuessCounts:
          _decodeCategoryCounts(
        await _preferences.getString(
          _categoryFirstGuessCountsKey,
        ),
      ),
      categoryCurrentStreakCounts:
          _decodeCategoryCounts(
        await _preferences.getString(
          _categoryCurrentStreakCountsKey,
        ),
      ),
      categoryLongestStreakCounts:
          _decodeCategoryCounts(
        await _preferences.getString(
          _categoryLongestStreakCountsKey,
        ),
      ),
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
      firstWordCurrentStreak: _cloudInt(
        data,
        'firstWordCurrentStreak',
        fallback.firstWordCurrentStreak,
      ),
      firstWordLongestStreak: _cloudInt(
        data,
        'firstWordLongestStreak',
        fallback.firstWordLongestStreak,
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
      categoryCorrectCounts: _cloudCategoryCounts(
        data['categoryCorrectCounts'],
        fallback.categoryCorrectCounts,
      ),
      categoryFirstGuessCounts: _cloudCategoryCounts(
        data['categoryFirstGuessCounts'],
        fallback.categoryFirstGuessCounts,
      ),
      categoryCurrentStreakCounts: _cloudCategoryCounts(
        data['categoryCurrentStreakCounts'],
        fallback.categoryCurrentStreakCounts,
      ),
      categoryLongestStreakCounts: _cloudCategoryCounts(
        data['categoryLongestStreakCounts'],
        fallback.categoryLongestStreakCounts,
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
      'firstWordCurrentStreak': stats.firstWordCurrentStreak,
      'firstWordLongestStreak': stats.firstWordLongestStreak,
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
      'categoryCorrectCounts':
          stats.categoryCorrectCounts,
      'categoryFirstGuessCounts':
          stats.categoryFirstGuessCounts,
      'categoryCurrentStreakCounts':
          stats.categoryCurrentStreakCounts,
      'categoryLongestStreakCounts':
          stats.categoryLongestStreakCounts,
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
        _firstWordCurrentStreakKey,
        stats.firstWordCurrentStreak,
      ),
      _preferences.setInt(
        _firstWordLongestStreakKey,
        stats.firstWordLongestStreak,
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
      _preferences.setString(
        _categoryCorrectCountsKey,
        jsonEncode(stats.categoryCorrectCounts),
      ),
      _preferences.setString(
        _categoryFirstGuessCountsKey,
        jsonEncode(stats.categoryFirstGuessCounts),
      ),
      _preferences.setString(
        _categoryCurrentStreakCountsKey,
        jsonEncode(stats.categoryCurrentStreakCounts),
      ),
      _preferences.setString(
        _categoryLongestStreakCountsKey,
        jsonEncode(stats.categoryLongestStreakCounts),
      ),
    ]);
  }

  static PlayerStats _applyBonusXp(
    PlayerStats baseStats, {
    required int xp,
  }) {
    return baseStats.copyWith(
      totalXp: baseStats.totalXp + xp,
    );
  }

  static PlayerStats _applyCorrectGame(
    PlayerStats baseStats, {
    required GameCategory category,
    required int pointsWon,
    required int clueNumber,
    required bool wasFirstGuess,
    required int playTimeSeconds,
    String? mainCategoryKey,
  }) {
    final int newCurrentStreak =
        baseStats.currentStreak + 1;

    final int newCountriesCompleted =
        category == GameCategory.countries
            ? baseStats.countriesCompleted + 1
            : baseStats.countriesCompleted;

    final int newCapitalCitiesCompleted =
        category == GameCategory.capitalCities
            ? baseStats.capitalCitiesCompleted + 1
            : baseStats.capitalCitiesCompleted;

    final int newFlagsCompleted =
        category == GameCategory.flags
            ? baseStats.flagsCompleted + 1
            : baseStats.flagsCompleted;

    final int newAuthorsCompleted =
        category == GameCategory.authors
            ? baseStats.authorsCompleted + 1
            : baseStats.authorsCompleted;

    final int newAnimalsCompleted =
        category == GameCategory.animals
            ? baseStats.animalsCompleted + 1
            : baseStats.animalsCompleted;

    final Map<String, int> newCategoryCorrectCounts =
        Map<String, int>.from(
      baseStats.categoryCorrectCounts,
    );

    final Map<String, int> newCategoryFirstGuessCounts =
        Map<String, int>.from(
      baseStats.categoryFirstGuessCounts,
    );

    final Map<String, int> newCategoryCurrentStreakCounts =
        Map<String, int>.from(
      baseStats.categoryCurrentStreakCounts,
    );

    final Map<String, int> newCategoryLongestStreakCounts =
        Map<String, int>.from(
      baseStats.categoryLongestStreakCounts,
    );

    if (mainCategoryKey != null &&
        mainCategoryKey.isNotEmpty) {
      newCategoryCorrectCounts[mainCategoryKey] =
          (newCategoryCorrectCounts[mainCategoryKey] ?? 0) + 1;

      if (wasFirstGuess) {
        newCategoryFirstGuessCounts[mainCategoryKey] =
            (newCategoryFirstGuessCounts[mainCategoryKey] ?? 0) + 1;
      }

      final int newGameStreak =
          (newCategoryCurrentStreakCounts[mainCategoryKey] ?? 0) + 1;
      newCategoryCurrentStreakCounts[mainCategoryKey] = newGameStreak;

      if (newGameStreak >
          (newCategoryLongestStreakCounts[mainCategoryKey] ?? 0)) {
        newCategoryLongestStreakCounts[mainCategoryKey] = newGameStreak;
      }

      if (_classicMainCategoryKeys.contains(mainCategoryKey)) {
        final int newClassicStreak =
            (newCategoryCurrentStreakCounts[_classicStreakKey] ?? 0) + 1;
        newCategoryCurrentStreakCounts[_classicStreakKey] = newClassicStreak;

        if (newClassicStreak >
            (newCategoryLongestStreakCounts[_classicStreakKey] ?? 0)) {
          newCategoryLongestStreakCounts[_classicStreakKey] = newClassicStreak;
        }
      }
    }

    final bool isFirstWord = mainCategoryKey == 'first_word';
    final int newFirstWordCurrentStreak = isFirstWord
        ? baseStats.firstWordCurrentStreak + 1
        : baseStats.firstWordCurrentStreak;
    final int newFirstWordLongestStreak = isFirstWord &&
            newFirstWordCurrentStreak > baseStats.firstWordLongestStreak
        ? newFirstWordCurrentStreak
        : baseStats.firstWordLongestStreak;

    return baseStats.copyWith(
      totalScore:
          baseStats.totalScore + pointsWon,
      totalXp:
          baseStats.totalXp + pointsWon,
      gamesPlayed:
          baseStats.gamesPlayed + 1,
      firstGuesses:
          baseStats.firstGuesses +
          (wasFirstGuess ? 1 : 0),
      currentStreak:
          newCurrentStreak,
      longestStreak:
          newCurrentStreak >
                  baseStats.longestStreak
              ? newCurrentStreak
              : baseStats.longestStreak,
      firstWordCurrentStreak: newFirstWordCurrentStreak,
      firstWordLongestStreak: newFirstWordLongestStreak,
      highestScore:
          pointsWon > baseStats.highestScore
              ? pointsWon
              : baseStats.highestScore,
      totalCluesUsed:
          baseStats.totalCluesUsed +
          clueNumber,
      correctlySolvedGames:
          baseStats.correctlySolvedGames + 1,
      totalPlayTimeSeconds:
          baseStats.totalPlayTimeSeconds +
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
      categoryCorrectCounts:
          newCategoryCorrectCounts,
      categoryFirstGuessCounts:
          newCategoryFirstGuessCounts,
      categoryCurrentStreakCounts:
          newCategoryCurrentStreakCounts,
      categoryLongestStreakCounts:
          newCategoryLongestStreakCounts,
    );
  }

  static PlayerStats _applyFailedGame(
    PlayerStats baseStats, {
    required int playTimeSeconds,
    String? mainCategoryKey,
  }) {
    final Map<String, int> newCategoryCurrentStreakCounts =
        Map<String, int>.from(
      baseStats.categoryCurrentStreakCounts,
    );

    if (mainCategoryKey != null &&
        mainCategoryKey.isNotEmpty) {
      newCategoryCurrentStreakCounts[mainCategoryKey] = 0;

      if (_classicMainCategoryKeys.contains(mainCategoryKey)) {
        newCategoryCurrentStreakCounts[_classicStreakKey] = 0;
      }
    }

    return baseStats.copyWith(
      gamesPlayed:
          baseStats.gamesPlayed + 1,
      currentStreak: 0,
      firstWordCurrentStreak: mainCategoryKey == 'first_word'
          ? 0
          : baseStats.firstWordCurrentStreak,
      categoryCurrentStreakCounts:
          newCategoryCurrentStreakCounts,
      totalPlayTimeSeconds:
          baseStats.totalPlayTimeSeconds +
          playTimeSeconds,
    );
  }

  static Future<PlayerStats> _updateStatsSafely({
    required PlayerStats fallbackStats,
    required PlayerStats Function(PlayerStats baseStats) update,
  }) async {
    final DocumentReference<Map<String, dynamic>>?
        cloudDocument = _cloudStatsDocument;

    if (cloudDocument == null) {
      final PlayerStats updated = update(fallbackStats);
      await _saveLocalStats(updated);
      _storeStatsMemoryCache(updated);
      return updated;
    }

    try {
      final PlayerStats updated =
          await _firestore.runTransaction<PlayerStats>(
        (Transaction transaction) async {
          final DocumentSnapshot<Map<String, dynamic>> snapshot =
              await transaction.get(cloudDocument);

          final PlayerStats baseStats;

          if (snapshot.exists && snapshot.data() != null) {
            baseStats = _statsFromCloudData(
              snapshot.data()!,
              fallbackStats,
            );
          } else {
            baseStats = fallbackStats;
          }

          final PlayerStats transactionUpdated =
              update(baseStats);

          transaction.set(
            cloudDocument,
            _statsToCloudData(transactionUpdated),
            SetOptions(merge: true),
          );

          return transactionUpdated;
        },
      );

      await _saveLocalStats(updated);
      await _syncPublicLeaderboardStats(updated);
      _storeStatsMemoryCache(updated);
      return updated;
    } on FirebaseException {
      // Keep gameplay usable if Firestore is temporarily unavailable.
      // Do not write an absolute stale snapshot back to cloud here,
      // because that could overwrite progress from another device.
      final PlayerStats updated = update(fallbackStats);
      await _saveLocalStats(updated);
      _storeStatsMemoryCache(updated);
      return updated;
    }
  }

  static Future<PlayerStats> loadStats() async {
    if (_hasFreshStatsMemoryCache) {
      return _statsMemoryCache!;
    }

    final PlayerStats localStats =
        await _loadLocalStats();

    final DocumentReference<Map<String, dynamic>>?
        cloudDocument = _cloudStatsDocument;

    if (cloudDocument == null) {
      _storeStatsMemoryCache(localStats);
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
        await _syncPublicLeaderboardStats(localStats);
        _storeStatsMemoryCache(localStats);

        return localStats;
      }

      final Map<String, dynamic>? cloudData =
          snapshot.data();

      if (cloudData == null) {
        _storeStatsMemoryCache(localStats);
        return localStats;
      }

      final PlayerStats cloudStats =
          _statsFromCloudData(
        cloudData,
        localStats,
      );

      await _saveLocalStats(cloudStats);
      await _syncPublicLeaderboardStats(cloudStats);
      _storeStatsMemoryCache(cloudStats);

      return cloudStats;
    } on FirebaseException {
      // Local stats remain the gameplay fallback if cloud sync
      // is temporarily unavailable.
      _storeStatsMemoryCache(localStats);
      return localStats;
    }
  }

  static Future<void> saveStats(
    PlayerStats stats,
  ) async {
    await _saveLocalStats(stats);
    _storeStatsMemoryCache(stats);

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
      await _syncPublicLeaderboardStats(stats);
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

    return _updateStatsSafely(
      fallbackStats: currentStats,
      update: (PlayerStats baseStats) =>
          _applyBonusXp(
        baseStats,
        xp: xp,
      ),
    );
  }

  static Future<PlayerStats> recordCorrectGame({
    required PlayerStats currentStats,
    required GameCategory category,
    required int pointsWon,
    required int clueNumber,
    required bool wasFirstGuess,
    required int playTimeSeconds,
    String? mainCategoryKey,
  }) async {
    final PlayerStats updated = await _updateStatsSafely(
      fallbackStats: currentStats,
      update: (PlayerStats baseStats) =>
          _applyCorrectGame(
        baseStats,
        category: category,
        pointsWon: pointsWon,
        clueNumber: clueNumber,
        wasFirstGuess: wasFirstGuess,
        playTimeSeconds: playTimeSeconds,
        mainCategoryKey: mainCategoryKey,
      ),
    );

    await _recordLeaderboardPeriodDelta(
      scoreDelta: pointsWon,
      firstGuessDelta: wasFirstGuess ? 1 : 0,
    );

    return updated;
  }

  static Future<PlayerStats> recordFailedGame({
    required PlayerStats currentStats,
    required int playTimeSeconds,
    String? mainCategoryKey,
  }) async {
    return _updateStatsSafely(
      fallbackStats: currentStats,
      update: (PlayerStats baseStats) =>
          _applyFailedGame(
        baseStats,
        playTimeSeconds: playTimeSeconds,
        mainCategoryKey: mainCategoryKey,
      ),
    );
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
    _statsMemoryCache = null;
    _statsMemoryCacheUserId = null;
    _statsMemoryCacheLoadedAt = null;

    await _preferences.clear(
      allowList: {
        _profileVersionKey,
        _totalScoreKey,
        _totalXpKey,
        _gamesPlayedKey,
        _firstGuessesKey,
        _currentStreakKey,
        _longestStreakKey,
        _firstWordCurrentStreakKey,
        _firstWordLongestStreakKey,
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
        _categoryCorrectCountsKey,
        _categoryFirstGuessCountsKey,
        _categoryCurrentStreakCountsKey,
        _categoryLongestStreakCountsKey,
        QuestionHistoryService.storageKey,
      },
    );
  }
}
