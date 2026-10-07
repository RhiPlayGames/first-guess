import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../case_files/models/case_mission.dart';
import '../case_files/models/case_progress.dart';
import '../case_files/services/case_path_service.dart';
import '../case_files/services/case_progress_service.dart';
import '../daily_flash/services/daily_flash_progress_service.dart';
import 'avatar_preferences_service.dart';
import 'player_stats_service.dart';

class GuestProgressMergeException implements Exception {
  final String message;

  const GuestProgressMergeException(this.message);

  @override
  String toString() => message;
}

class GuestProgressSnapshot {
  final String guestUid;
  final Map<String, dynamic> playerStats;
  final String? playerStatsUpdatedAt;
  final List<String> playedQuestionIds;
  final Map<String, dynamic> dailyFlash;
  final String? avatarPath;
  final Map<String, Map<String, dynamic>> casePaths;

  const GuestProgressSnapshot({
    required this.guestUid,
    required this.playerStats,
    required this.playerStatsUpdatedAt,
    required this.playedQuestionIds,
    required this.dailyFlash,
    required this.avatarPath,
    required this.casePaths,
  });

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'guestUid': guestUid,
      'playerStats': playerStats,
      'playerStatsUpdatedAt': playerStatsUpdatedAt,
      'playedQuestionIds': playedQuestionIds,
      'dailyFlash': dailyFlash,
      'avatarPath': avatarPath,
      'casePaths': casePaths,
    };
  }

  factory GuestProgressSnapshot.fromJson(
    Map<String, dynamic> json,
  ) {
    final Map<String, Map<String, dynamic>> casePaths =
        <String, Map<String, dynamic>>{};

    final dynamic rawCasePaths = json['casePaths'];
    if (rawCasePaths is Map) {
      rawCasePaths.forEach((dynamic key, dynamic value) {
        if (key is String && value is Map) {
          casePaths[key] =
              Map<String, dynamic>.from(value);
        }
      });
    }

    return GuestProgressSnapshot(
      guestUid: json['guestUid'] as String? ?? '',
      playerStats: json['playerStats'] is Map
          ? Map<String, dynamic>.from(
              json['playerStats'] as Map,
            )
          : <String, dynamic>{},
      playerStatsUpdatedAt:
          json['playerStatsUpdatedAt'] as String?,
      playedQuestionIds:
          (json['playedQuestionIds'] as List<dynamic>? ??
                  <dynamic>[])
              .whereType<String>()
              .toList(),
      dailyFlash: json['dailyFlash'] is Map
          ? Map<String, dynamic>.from(
              json['dailyFlash'] as Map,
            )
          : <String, dynamic>{},
      avatarPath: json['avatarPath'] as String?,
      casePaths: casePaths,
    );
  }
}

class GuestProgressMergeService {
  GuestProgressMergeService._();

  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  static const String _pendingMergePreference =
      'pending_guest_progress_merge_v1';

  static const List<String> _casePathIds = <String>[
    CasePathService.animalKingdomCasePathId,
    CasePathService.roundTheWorldCasePathId,
    CasePathService.secretsOfThePastCasePathId,
    CasePathService.tasteAndTreatsCasePathId,
  ];

  static const CaseProgressService _caseProgressService =
      CaseProgressService();

  static Future<GuestProgressSnapshot>
      captureAndPersistCurrentGuestProgress() async {
    final User? guest = _auth.currentUser;

    if (guest == null || !guest.isAnonymous) {
      throw const GuestProgressMergeException(
        'A guest session could not be found to merge.',
      );
    }

    final PlayerStats stats =
        await PlayerStatsService.loadStats();

    final Set<String> playedIds =
        await QuestionHistoryService.loadPlayedQuestionIds();

    final DailyFlashProgress dailyFlash =
        await DailyFlashProgressService.loadToday();

    final String? avatarPath =
        await AvatarPreferencesService.loadSelectedAvatarPath();

    final Map<String, Map<String, dynamic>> casePaths =
        <String, Map<String, dynamic>>{};

    final List<CaseProgress?> caseProgress = <CaseProgress?>[
      await CasePathService.loadAnimalKingdomProgress(),
      await CasePathService.loadRoundTheWorldProgress(),
      await CasePathService.loadSecretsOfThePastProgress(),
      await CasePathService.loadTasteAndTreatsProgress(),
    ];

    for (final CaseProgress? progress in caseProgress) {
      if (progress != null) {
        casePaths[progress.casePathId] =
            _caseProgressToMap(progress);
      }
    }

    String? statsUpdatedAt;
    try {
      final DocumentSnapshot<Map<String, dynamic>> statsSnapshot =
          await _firestore
              .collection('players')
              .doc(guest.uid)
              .collection('progress')
              .doc('player_stats')
              .get();

      final dynamic rawUpdatedAt =
          statsSnapshot.data()?['updatedAt'];

      if (rawUpdatedAt is Timestamp) {
        statsUpdatedAt =
            rawUpdatedAt.toDate().toUtc().toIso8601String();
      } else if (rawUpdatedAt is String) {
        statsUpdatedAt = rawUpdatedAt;
      }
    } on FirebaseException {
      // The merge can still proceed without a source timestamp.
    }

    final GuestProgressSnapshot snapshot =
        GuestProgressSnapshot(
      guestUid: guest.uid,
      playerStats: _playerStatsToMap(stats),
      playerStatsUpdatedAt: statsUpdatedAt,
      playedQuestionIds:
          playedIds.toList()..sort(),
      dailyFlash: _dailyFlashToMap(dailyFlash),
      avatarPath: avatarPath,
      casePaths: casePaths,
    );

    final SharedPreferences preferences =
        await SharedPreferences.getInstance();

    await preferences.setString(
      _pendingMergePreference,
      jsonEncode(snapshot.toJson()),
    );

    return snapshot;
  }

  static Future<bool> hasPendingMerge() async {
    final SharedPreferences preferences =
        await SharedPreferences.getInstance();

    final String? raw =
        preferences.getString(_pendingMergePreference);

    return raw != null && raw.isNotEmpty;
  }

  static Future<GuestProgressSnapshot?>
      loadPendingMerge() async {
    final SharedPreferences preferences =
        await SharedPreferences.getInstance();

    final String? raw =
        preferences.getString(_pendingMergePreference);

    if (raw == null || raw.isEmpty) {
      return null;
    }

    try {
      final dynamic decoded = jsonDecode(raw);

      if (decoded is! Map) {
        return null;
      }

      final GuestProgressSnapshot snapshot =
          GuestProgressSnapshot.fromJson(
        Map<String, dynamic>.from(decoded),
      );

      if (snapshot.guestUid.isEmpty) {
        return null;
      }

      return snapshot;
    } on FormatException {
      return null;
    }
  }

  static Future<void> mergePendingIntoCurrentAccount() async {
    final GuestProgressSnapshot? pending =
        await loadPendingMerge();

    if (pending == null) {
      return;
    }

    await mergeIntoCurrentAccount(pending);
  }

  static Future<void> mergeIntoCurrentAccount(
    GuestProgressSnapshot snapshot,
  ) async {
    final User? targetUser = _auth.currentUser;

    if (targetUser == null || targetUser.isAnonymous) {
      throw const GuestProgressMergeException(
        'The existing First Guess account is not signed in.',
      );
    }

    if (targetUser.uid == snapshot.guestUid) {
      throw const GuestProgressMergeException(
        'The guest account and destination account are the same.',
      );
    }

    final DocumentReference<Map<String, dynamic>> statsDocument =
        _progressDocument(targetUser.uid, 'player_stats');

    final DocumentReference<Map<String, dynamic>> historyDocument =
        _progressDocument(targetUser.uid, 'question_history');

    final DocumentReference<Map<String, dynamic>> dailyDocument =
        _progressDocument(targetUser.uid, 'daily_flash');

    final DocumentReference<Map<String, dynamic>> avatarDocument =
        _progressDocument(targetUser.uid, 'avatar_preferences');

    final DocumentReference<Map<String, dynamic>> mergeDocument =
        _progressDocument(targetUser.uid, 'account_merge');

    final Map<String,
            DocumentReference<Map<String, dynamic>>>
        caseDocuments =
        <String, DocumentReference<Map<String, dynamic>>>{
      for (final String casePathId in _casePathIds)
        casePathId: _firestore
            .collection('players')
            .doc(targetUser.uid)
            .collection('case_paths')
            .doc(casePathId),
    };

    try {
      await _firestore.runTransaction<void>(
        (Transaction transaction) async {
          final DocumentSnapshot<Map<String, dynamic>>
              mergeSnapshot =
              await transaction.get(mergeDocument);

          final List<String> mergedGuestUids =
              _stringList(
            mergeSnapshot.data()?['mergedGuestUids'],
          );

          if (mergedGuestUids.contains(snapshot.guestUid)) {
            return;
          }

          final DocumentSnapshot<Map<String, dynamic>>
              statsSnapshot =
              await transaction.get(statsDocument);

          final DocumentSnapshot<Map<String, dynamic>>
              historySnapshot =
              await transaction.get(historyDocument);

          final DocumentSnapshot<Map<String, dynamic>>
              dailySnapshot =
              await transaction.get(dailyDocument);

          final DocumentSnapshot<Map<String, dynamic>>
              avatarSnapshot =
              await transaction.get(avatarDocument);

          final Map<String,
                  DocumentSnapshot<Map<String, dynamic>>>
              targetCaseSnapshots =
              <String,
                  DocumentSnapshot<Map<String, dynamic>>>{};

          for (final MapEntry<String,
                  DocumentReference<Map<String, dynamic>>>
              entry in caseDocuments.entries) {
            targetCaseSnapshots[entry.key] =
                await transaction.get(entry.value);
          }

          final Map<String, dynamic> mergedStats =
              _mergePlayerStats(
            snapshot.playerStats,
            snapshot.playerStatsUpdatedAt,
            statsSnapshot.data(),
          );

          final Set<String> mergedHistory = <String>{
            ..._stringList(
              historySnapshot.data()?['playedQuestionIds'],
            ),
            ...snapshot.playedQuestionIds,
          };

          final Map<String, dynamic> mergedDaily =
              _mergeDailyFlash(
            snapshot.dailyFlash,
            dailySnapshot.data(),
          );

          final Map<String, dynamic>? targetAvatar =
              avatarSnapshot.data();

          final String? targetAvatarPath =
              targetAvatar?['selectedAvatarPath'] as String?;

          final String? mergedAvatarPath =
              targetAvatarPath?.isNotEmpty == true
                  ? targetAvatarPath
                  : snapshot.avatarPath;

          transaction.set(
            statsDocument,
            <String, dynamic>{
              ...mergedStats,
              'schemaVersion': 1,
              'updatedAt': FieldValue.serverTimestamp(),
            },
            SetOptions(merge: true),
          );

          transaction.set(
            historyDocument,
            <String, dynamic>{
              'playedQuestionIds':
                  mergedHistory.toList()..sort(),
              'schemaVersion': 1,
              'updatedAt': FieldValue.serverTimestamp(),
            },
            SetOptions(merge: true),
          );

          if (mergedDaily.isNotEmpty) {
            transaction.set(
              dailyDocument,
              <String, dynamic>{
                ...mergedDaily,
                'schemaVersion': 1,
                'updatedAt': FieldValue.serverTimestamp(),
              },
              SetOptions(merge: true),
            );
          }

          if (mergedAvatarPath != null &&
              mergedAvatarPath.isNotEmpty) {
            transaction.set(
              avatarDocument,
              <String, dynamic>{
                'selectedAvatarPath': mergedAvatarPath,
                'schemaVersion': 1,
                'updatedAt': FieldValue.serverTimestamp(),
              },
              SetOptions(merge: true),
            );
          }

          for (final String casePathId in _casePathIds) {
            final Map<String, dynamic>? guestMap =
                snapshot.casePaths[casePathId];

            final Map<String, dynamic>? targetMap =
                targetCaseSnapshots[casePathId]?.data();

            final Map<String, dynamic>? mergedCase =
                _mergeCaseProgress(
              casePathId: casePathId,
              guestMap: guestMap,
              targetMap: targetMap,
            );

            if (mergedCase == null) {
              continue;
            }

            transaction.set(
              caseDocuments[casePathId]!,
              <String, dynamic>{
                ...mergedCase,
                'schemaVersion': 1,
                'serverUpdatedAt':
                    FieldValue.serverTimestamp(),
              },
              SetOptions(merge: true),
            );
          }

          transaction.set(
            mergeDocument,
            <String, dynamic>{
              'mergedGuestUids': <String>[
                ...mergedGuestUids,
                snapshot.guestUid,
              ],
              'lastMergedGuestUid': snapshot.guestUid,
              'lastMergedAt': FieldValue.serverTimestamp(),
              'schemaVersion': 1,
            },
            SetOptions(merge: true),
          );
        },
      );

      await _clearPendingMerge();
      await _refreshLocalCaches();
    } on FirebaseException catch (error) {
      throw GuestProgressMergeException(
        error.message ??
            'Guest progress could not be merged into the existing account.',
      );
    }
  }

  static DocumentReference<Map<String, dynamic>>
      _progressDocument(
    String uid,
    String documentId,
  ) {
    return _firestore
        .collection('players')
        .doc(uid)
        .collection('progress')
        .doc(documentId);
  }

  static Map<String, dynamic> _playerStatsToMap(
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
      'correctlySolvedGames': stats.correctlySolvedGames,
      'totalPlayTimeSeconds': stats.totalPlayTimeSeconds,
      'countriesCompleted': stats.countriesCompleted,
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
    };
  }

  static Map<String, dynamic> _mergePlayerStats(
    Map<String, dynamic> guest,
    String? guestUpdatedAt,
    Map<String, dynamic>? target,
  ) {
    final Map<String, dynamic> existing =
        target ?? <String, dynamic>{};

    final DateTime? guestUpdated =
        guestUpdatedAt == null
            ? null
            : DateTime.tryParse(guestUpdatedAt);

    final DateTime? targetUpdated =
        _asDate(existing['updatedAt']);

    final bool useGuestCurrentStreak =
        guestUpdated != null &&
        (targetUpdated == null ||
            guestUpdated.isAfter(targetUpdated));

    return <String, dynamic>{
      'profileVersion': _max(
        _asInt(guest['profileVersion']),
        _asInt(existing['profileVersion']),
      ),
      'totalScore':
          _asInt(guest['totalScore']) +
          _asInt(existing['totalScore']),
      'totalXp':
          _asInt(guest['totalXp']) +
          _asInt(existing['totalXp']),
      'gamesPlayed':
          _asInt(guest['gamesPlayed']) +
          _asInt(existing['gamesPlayed']),
      'firstGuesses':
          _asInt(guest['firstGuesses']) +
          _asInt(existing['firstGuesses']),
      'currentStreak': useGuestCurrentStreak
          ? _asInt(guest['currentStreak'])
          : _asInt(existing['currentStreak']),
      'longestStreak': _max(
        _asInt(guest['longestStreak']),
        _asInt(existing['longestStreak']),
      ),
      'highestScore': _max(
        _asInt(guest['highestScore']),
        _asInt(existing['highestScore']),
      ),
      'totalCluesUsed':
          _asInt(guest['totalCluesUsed']) +
          _asInt(existing['totalCluesUsed']),
      'correctlySolvedGames':
          _asInt(guest['correctlySolvedGames']) +
          _asInt(existing['correctlySolvedGames']),
      'totalPlayTimeSeconds':
          _asInt(guest['totalPlayTimeSeconds']) +
          _asInt(existing['totalPlayTimeSeconds']),
      'countriesCompleted':
          _asInt(guest['countriesCompleted']) +
          _asInt(existing['countriesCompleted']),
      'capitalCitiesCompleted':
          _asInt(guest['capitalCitiesCompleted']) +
          _asInt(existing['capitalCitiesCompleted']),
      'flagsCompleted':
          _asInt(guest['flagsCompleted']) +
          _asInt(existing['flagsCompleted']),
      'authorsCompleted':
          _asInt(guest['authorsCompleted']) +
          _asInt(existing['authorsCompleted']),
      'moviesCompleted':
          _asInt(guest['moviesCompleted']) +
          _asInt(existing['moviesCompleted']),
      'booksCompleted':
          _asInt(guest['booksCompleted']) +
          _asInt(existing['booksCompleted']),
      'periodicTableCompleted':
          _asInt(guest['periodicTableCompleted']) +
          _asInt(existing['periodicTableCompleted']),
      'historicalFiguresCompleted':
          _asInt(guest['historicalFiguresCompleted']) +
          _asInt(existing['historicalFiguresCompleted']),
      'animalsCompleted':
          _asInt(guest['animalsCompleted']) +
          _asInt(existing['animalsCompleted']),
      'footballTeamsCompleted':
          _asInt(guest['footballTeamsCompleted']) +
          _asInt(existing['footballTeamsCompleted']),
      'categoryCorrectCounts': _sumCountMaps(
        guest['categoryCorrectCounts'],
        existing['categoryCorrectCounts'],
      ),
      'categoryFirstGuessCounts': _sumCountMaps(
        guest['categoryFirstGuessCounts'],
        existing['categoryFirstGuessCounts'],
      ),
    };
  }

  static Map<String, int> _sumCountMaps(
    dynamic first,
    dynamic second,
  ) {
    final Map<String, int> result = <String, int>{};

    void addValues(dynamic raw) {
      if (raw is! Map) {
        return;
      }

      raw.forEach((dynamic key, dynamic value) {
        if (key is String && value is num) {
          result[key] =
              (result[key] ?? 0) + value.toInt();
        }
      });
    }

    addValues(first);
    addValues(second);

    return result;
  }

  static Map<String, dynamic> _dailyFlashToMap(
    DailyFlashProgress progress,
  ) {
    return <String, dynamic>{
      'dateKey': progress.dateKey,
      'nextQuestionIndex': progress.nextQuestionIndex,
      'totalXp': progress.totalXp,
      'questionsCorrect': progress.questionsCorrect,
      'firstGuesses': progress.firstGuesses,
    };
  }

  static Map<String, dynamic> _mergeDailyFlash(
    Map<String, dynamic> guest,
    Map<String, dynamic>? target,
  ) {
    if (guest.isEmpty && target == null) {
      return <String, dynamic>{};
    }

    if (guest.isEmpty) {
      return Map<String, dynamic>.from(target!);
    }

    if (target == null || target.isEmpty) {
      return Map<String, dynamic>.from(guest);
    }

    final String guestDate =
        guest['dateKey'] as String? ?? '';
    final String targetDate =
        target['dateKey'] as String? ?? '';

    if (guestDate != targetDate) {
      return guestDate.compareTo(targetDate) > 0
          ? Map<String, dynamic>.from(guest)
          : Map<String, dynamic>.from(target);
    }

    final int guestNext =
        _asInt(guest['nextQuestionIndex']);
    final int targetNext =
        _asInt(target['nextQuestionIndex']);

    if (guestNext > targetNext) {
      return Map<String, dynamic>.from(guest);
    }

    if (targetNext > guestNext) {
      return Map<String, dynamic>.from(target);
    }

    return <String, dynamic>{
      'dateKey': guestDate,
      'nextQuestionIndex': guestNext,
      'totalXp': _max(
        _asInt(guest['totalXp']),
        _asInt(target['totalXp']),
      ),
      'questionsCorrect': _max(
        _asInt(guest['questionsCorrect']),
        _asInt(target['questionsCorrect']),
      ),
      'firstGuesses': _max(
        _asInt(guest['firstGuesses']),
        _asInt(target['firstGuesses']),
      ),
    };
  }

  static Map<String, dynamic> _caseProgressToMap(
    CaseProgress progress,
  ) {
    final CaseStageProgress stage =
        progress.currentStageProgress;

    return <String, dynamic>{
      'casePathId': progress.casePathId,
      'currentStage': progress.currentStage,
      'totalStages': progress.totalStages,
      'completedStages': progress.completedStages,
      'isCompleted': progress.isCompleted,
      'currentStageProgress': <String, dynamic>{
        'stage': stage.stage,
        'correctCount': stage.correctCount,
        'clueThresholdCount': stage.clueThresholdCount,
        'firstGuessCount': stage.firstGuessCount,
        'lastProcessedAttemptId':
            stage.lastProcessedAttemptId,
        'startedAt': _dateToString(stage.startedAt),
        'completedAt': _dateToString(stage.completedAt),
      },
      'startedAt': _dateToString(progress.startedAt),
      'updatedAt': _dateToString(progress.updatedAt),
      'completedAt': _dateToString(progress.completedAt),
    };
  }

  static Map<String, dynamic>? _mergeCaseProgress({
    required String casePathId,
    required Map<String, dynamic>? guestMap,
    required Map<String, dynamic>? targetMap,
  }) {
    final CaseProgress? guest =
        _caseProgressFromMap(guestMap);
    final CaseProgress? target =
        _caseProgressFromMap(targetMap);

    if (guest == null) {
      return target == null
          ? null
          : _caseProgressToMap(target);
    }

    if (target == null) {
      return _caseProgressToMap(guest);
    }

    CaseProgress merged;

    if (guest.isCompleted && !target.isCompleted) {
      merged = guest;
    } else if (target.isCompleted && !guest.isCompleted) {
      merged = target;
    } else if (guest.currentStage != target.currentStage) {
      merged = guest.currentStage > target.currentStage
          ? guest
          : target;
    } else {
      final Set<int> completedStages = <int>{
        ...guest.completedStages,
        ...target.completedStages,
      };

      final DateTime? updatedAt =
          _latestDate(guest.updatedAt, target.updatedAt);

      final DateTime? startedAt =
          _earliestDate(guest.startedAt, target.startedAt);

      final CaseStageProgress combinedStage =
          CaseStageProgress(
        stage: guest.currentStage,
        correctCount:
            guest.currentStageProgress.correctCount +
            target.currentStageProgress.correctCount,
        clueThresholdCount:
            guest.currentStageProgress.clueThresholdCount +
            target.currentStageProgress.clueThresholdCount,
        firstGuessCount:
            guest.currentStageProgress.firstGuessCount +
            target.currentStageProgress.firstGuessCount,
        lastProcessedAttemptId:
            _latestAttemptId(guest, target),
        startedAt: _earliestDate(
          guest.currentStageProgress.startedAt,
          target.currentStageProgress.startedAt,
        ),
        completedAt: _latestDate(
          guest.currentStageProgress.completedAt,
          target.currentStageProgress.completedAt,
        ),
      );

      merged = CaseProgress(
        casePathId: casePathId,
        currentStage: guest.currentStage,
        totalStages: _max(
          guest.totalStages,
          target.totalStages,
        ),
        completedStages:
            completedStages.toList()..sort(),
        isCompleted:
            guest.isCompleted || target.isCompleted,
        currentStageProgress: combinedStage,
        startedAt: startedAt,
        updatedAt: updatedAt,
        completedAt: _latestDate(
          guest.completedAt,
          target.completedAt,
        ),
      );

      final CaseMission? mission =
          _missionForCaseStage(
        casePathId,
        merged.currentStage,
      );

      if (mission != null && !merged.isCompleted) {
        merged = _caseProgressService.applyStageProgress(
          caseProgress: merged,
          mission: mission,
          updatedStageProgress: combinedStage,
          updatedAt: updatedAt ?? DateTime.now(),
        );
      }
    }

    return _caseProgressToMap(merged);
  }

  static CaseProgress? _caseProgressFromMap(
    Map<String, dynamic>? data,
  ) {
    if (data == null) {
      return null;
    }

    final String? casePathId =
        data['casePathId'] as String?;

    final int currentStage =
        _asInt(data['currentStage']);

    final int totalStages =
        _asInt(data['totalStages']);

    final dynamic rawStage =
        data['currentStageProgress'];

    if (casePathId == null ||
        casePathId.isEmpty ||
        currentStage <= 0 ||
        totalStages <= 0 ||
        rawStage is! Map) {
      return null;
    }

    final Map<String, dynamic> stage =
        Map<String, dynamic>.from(rawStage);

    final int stageNumber =
        _asInt(stage['stage']);

    if (stageNumber <= 0) {
      return null;
    }

    return CaseProgress(
      casePathId: casePathId,
      currentStage: currentStage,
      totalStages: totalStages,
      completedStages:
          _intList(data['completedStages']),
      isCompleted:
          data['isCompleted'] as bool? ?? false,
      currentStageProgress: CaseStageProgress(
        stage: stageNumber,
        correctCount:
            _asInt(stage['correctCount']),
        clueThresholdCount:
            _asInt(stage['clueThresholdCount']),
        firstGuessCount:
            _asInt(stage['firstGuessCount']),
        lastProcessedAttemptId:
            stage['lastProcessedAttemptId'] as String?,
        startedAt: _asDate(stage['startedAt']),
        completedAt: _asDate(stage['completedAt']),
      ),
      startedAt: _asDate(data['startedAt']),
      updatedAt: _asDate(data['updatedAt']),
      completedAt: _asDate(data['completedAt']),
    );
  }

  static CaseMission? _missionForCaseStage(
    String casePathId,
    int stage,
  ) {
    switch (casePathId) {
      case CasePathService.animalKingdomCasePathId:
        return CasePathService.animalKingdomMissionForStage(stage);
      case CasePathService.roundTheWorldCasePathId:
        return CasePathService.roundTheWorldMissionForStage(stage);
      case CasePathService.secretsOfThePastCasePathId:
        return CasePathService.secretsOfThePastMissionForStage(stage);
      case CasePathService.tasteAndTreatsCasePathId:
        return CasePathService.tasteAndTreatsMissionForStage(stage);
      default:
        return null;
    }
  }

  static String? _latestAttemptId(
    CaseProgress first,
    CaseProgress second,
  ) {
    final DateTime firstUpdated =
        first.updatedAt ??
        DateTime.fromMillisecondsSinceEpoch(0);

    final DateTime secondUpdated =
        second.updatedAt ??
        DateTime.fromMillisecondsSinceEpoch(0);

    return firstUpdated.isAfter(secondUpdated)
        ? first.currentStageProgress.lastProcessedAttemptId
        : second.currentStageProgress.lastProcessedAttemptId;
  }

  static Future<void> _refreshLocalCaches() async {
    await PlayerStatsService.loadStats();
    await QuestionHistoryService.loadPlayedQuestionIds();
    await DailyFlashProgressService.loadToday();
    await AvatarPreferencesService.loadSelectedAvatarPath();

    await CasePathService.loadAnimalKingdomProgress();
    await CasePathService.loadRoundTheWorldProgress();
    await CasePathService.loadSecretsOfThePastProgress();
    await CasePathService.loadTasteAndTreatsProgress();
  }

  static Future<void> _clearPendingMerge() async {
    final SharedPreferences preferences =
        await SharedPreferences.getInstance();

    await preferences.remove(_pendingMergePreference);
  }

  static List<String> _stringList(dynamic value) {
    if (value is! List) {
      return <String>[];
    }

    return value.whereType<String>().toList();
  }

  static List<int> _intList(dynamic value) {
    if (value is! List) {
      return <int>[];
    }

    return value
        .whereType<num>()
        .map((num item) => item.toInt())
        .toList()
      ..sort();
  }

  static int _asInt(dynamic value) {
    if (value is num) {
      return value.toInt();
    }

    return 0;
  }

  static int _max(int first, int second) {
    return first > second ? first : second;
  }

  static String? _dateToString(DateTime? value) {
    return value?.toUtc().toIso8601String();
  }

  static DateTime? _asDate(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is String) {
      return DateTime.tryParse(value);
    }

    return null;
  }

  static DateTime? _latestDate(
    DateTime? first,
    DateTime? second,
  ) {
    if (first == null) {
      return second;
    }

    if (second == null) {
      return first;
    }

    return first.isAfter(second) ? first : second;
  }

  static DateTime? _earliestDate(
    DateTime? first,
    DateTime? second,
  ) {
    if (first == null) {
      return second;
    }

    if (second == null) {
      return first;
    }

    return first.isBefore(second) ? first : second;
  }
}
