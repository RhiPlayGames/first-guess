import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'analytics_service.dart';
import 'avatar_preferences_service.dart';
import 'player_profile_service.dart';

class LeagueService {
  LeagueService._();

  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final Random _random = Random.secure();

  static const int _schemaVersion = 1;
  static const String _inviteAlphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  static const int _inviteCodeLength = 8;
  static const int _maximumInviteGenerationAttempts = 12;

  static String? get currentUserId => _auth.currentUser?.uid;

  static User _requireUser() {
    final User? user = _auth.currentUser;

    if (user == null) {
      throw const LeagueServiceException(
        'A First Guess account is required to use leagues.',
      );
    }

    return user;
  }

  static Future<LeagueRecord> createLeague({
    required String name,
    required String badgePath,
    required int accentColorValue,
  }) async {
    final User user = _requireUser();
    final String cleanedName = name.trim();

    if (cleanedName.isEmpty) {
      throw const LeagueServiceException(
        'Enter a league name first.',
      );
    }

    if (cleanedName.length > 28) {
      throw const LeagueServiceException(
        'League names can be up to 28 characters.',
      );
    }

    final String? displayName =
        await PlayerProfileService.loadDisplayName();

    if (displayName == null || displayName.trim().isEmpty) {
      throw const LeagueServiceException(
        'Choose a player name in My Profile before creating a league.',
      );
    }

    final String avatarPath =
        await AvatarPreferencesService.loadSelectedAvatarPath() ??
            'assets/images/avatars/Final/optimized/default_avatar.webp';

    final String inviteCode = await _generateUniqueInviteCode();
    final DocumentReference<Map<String, dynamic>> leagueDocument =
        _firestore.collection('leagues').doc();

    final DocumentReference<Map<String, dynamic>> inviteDocument =
        _firestore.collection('league_invites').doc(inviteCode);

    final DocumentReference<Map<String, dynamic>> memberDocument =
        leagueDocument.collection('members').doc(user.uid);

    await _firestore.runTransaction<void>(
      (Transaction transaction) async {
        final DocumentSnapshot<Map<String, dynamic>> inviteSnapshot =
            await transaction.get(inviteDocument);

        if (inviteSnapshot.exists) {
          throw const LeagueServiceException(
            'Could not create a unique invite code. Please try again.',
          );
        }

        transaction.set(
          leagueDocument,
          <String, dynamic>{
            'name': cleanedName,
            'ownerId': user.uid,
            'badgePath': badgePath,
            'accentColor': accentColorValue,
            'inviteCode': inviteCode,
            'memberCount': 1,
            'memberIds': <String>[user.uid],
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
            'schemaVersion': _schemaVersion,
          },
        );

        transaction.set(
          memberDocument,
          <String, dynamic>{
            'userId': user.uid,
            'displayName': displayName.trim(),
            'avatarPath': avatarPath,
            'role': 'owner',
            'joinedAt': FieldValue.serverTimestamp(),
            'schemaVersion': _schemaVersion,
          },
        );

        transaction.set(
          inviteDocument,
          <String, dynamic>{
            'leagueId': leagueDocument.id,
            'inviteCode': inviteCode,
            'leagueName': cleanedName,
            'ownerId': user.uid,
            'badgePath': badgePath,
            'accentColor': accentColorValue,
            'memberCount': 1,
            'createdBy': user.uid,
            'createdAt': FieldValue.serverTimestamp(),
            'schemaVersion': _schemaVersion,
          },
        );
      },
    );

    await AnalyticsService.logLeagueCreated(
      memberCount: 1,
    );

    return LeagueRecord(
      id: leagueDocument.id,
      name: cleanedName,
      ownerId: user.uid,
      badgePath: badgePath,
      accentColorValue: accentColorValue,
      inviteCode: inviteCode,
      memberCount: 1,
    );
  }

  static Future<LeagueRecord?> findLeagueByInviteCode(
    String rawInviteCode,
  ) async {
    _requireUser();

    final String inviteCode = _normaliseInviteCode(rawInviteCode);

    if (inviteCode.isEmpty) {
      return null;
    }

    final DocumentSnapshot<Map<String, dynamic>> inviteSnapshot =
        await _firestore
            .collection('league_invites')
            .doc(inviteCode)
            .get();

    if (!inviteSnapshot.exists || inviteSnapshot.data() == null) {
      return null;
    }

    final Map<String, dynamic> inviteData = inviteSnapshot.data()!;
    final String? leagueId = inviteData['leagueId'] as String?;

    if (leagueId == null || leagueId.isEmpty) {
      return null;
    }

    return LeagueRecord(
      id: leagueId,
      name: inviteData['leagueName'] is String
          ? inviteData['leagueName'] as String
          : 'League',
      ownerId: inviteData['ownerId'] is String
          ? inviteData['ownerId'] as String
          : '',
      badgePath: inviteData['badgePath'] is String
          ? inviteData['badgePath'] as String
          : 'assets/images/leaderboard/league_badges/league_people.webp',
      accentColorValue: inviteData['accentColor'] is num
          ? (inviteData['accentColor'] as num).toInt()
          : 0xFFFE5E02,
      inviteCode: inviteCode,
      memberCount: inviteData['memberCount'] is num
          ? (inviteData['memberCount'] as num).toInt()
          : 0,
    );
  }

  static Future<LeagueRecord> joinLeagueByInviteCode(
    String rawInviteCode,
  ) async {
    final User user = _requireUser();
    final String inviteCode = _normaliseInviteCode(rawInviteCode);

    if (inviteCode.isEmpty) {
      throw const LeagueServiceException(
        'Enter an invite code first.',
      );
    }

    final String? displayName =
        await PlayerProfileService.loadDisplayName();

    if (displayName == null || displayName.trim().isEmpty) {
      throw const LeagueServiceException(
        'Choose a player name in My Profile before joining a league.',
      );
    }

    final String avatarPath =
        await AvatarPreferencesService.loadSelectedAvatarPath() ??
            'assets/images/avatars/Final/optimized/default_avatar.webp';

    final DocumentReference<Map<String, dynamic>> inviteDocument =
        _firestore.collection('league_invites').doc(inviteCode);

    final DocumentSnapshot<Map<String, dynamic>> inviteSnapshot =
        await inviteDocument.get();

    if (!inviteSnapshot.exists || inviteSnapshot.data() == null) {
      throw const LeagueServiceException(
        'That invite code was not found.',
      );
    }

    final Map<String, dynamic> inviteData = inviteSnapshot.data()!;
    final String? leagueId = inviteData['leagueId'] as String?;

    if (leagueId == null || leagueId.isEmpty) {
      throw const LeagueServiceException(
        'That invite code is no longer valid.',
      );
    }

    final DocumentReference<Map<String, dynamic>> leagueDocument =
        _firestore.collection('leagues').doc(leagueId);

    final DocumentReference<Map<String, dynamic>> memberDocument =
        leagueDocument.collection('members').doc(user.uid);

    final DocumentSnapshot<Map<String, dynamic>> memberSnapshot =
        await memberDocument.get();

    final int previewMemberCount =
        inviteData['memberCount'] is num
            ? (inviteData['memberCount'] as num).toInt()
            : 0;

    if (memberSnapshot.exists) {
      await memberDocument.set(
        <String, dynamic>{
          'displayName': displayName.trim(),
          'avatarPath': avatarPath,
          'schemaVersion': _schemaVersion,
        },
        SetOptions(merge: true),
      );

      return LeagueRecord(
        id: leagueId,
        name: inviteData['leagueName'] is String
            ? inviteData['leagueName'] as String
            : 'League',
        ownerId: inviteData['ownerId'] is String
            ? inviteData['ownerId'] as String
            : '',
        badgePath: inviteData['badgePath'] is String
            ? inviteData['badgePath'] as String
            : 'assets/images/leaderboard/league_badges/league_people.webp',
        accentColorValue: inviteData['accentColor'] is num
            ? (inviteData['accentColor'] as num).toInt()
            : 0xFFFE5E02,
        inviteCode: inviteCode,
        memberCount: previewMemberCount,
        memberIds: <String>[user.uid],
      );
    }

    final WriteBatch batch = _firestore.batch();

    batch.update(
      leagueDocument,
      <String, dynamic>{
        'memberIds': FieldValue.arrayUnion(<String>[user.uid]),
        'memberCount': FieldValue.increment(1),
        'lastJoinCode': inviteCode,
        'updatedAt': FieldValue.serverTimestamp(),
      },
    );

    batch.set(
      memberDocument,
      <String, dynamic>{
        'userId': user.uid,
        'displayName': displayName.trim(),
        'avatarPath': avatarPath,
        'role': 'member',
        'joinedAt': FieldValue.serverTimestamp(),
        'schemaVersion': _schemaVersion,
      },
    );

    batch.update(
      inviteDocument,
      <String, dynamic>{
        'memberCount': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      },
    );

    await batch.commit();

    await AnalyticsService.logLeagueJoined(
      memberCount: previewMemberCount + 1,
    );

    return LeagueRecord(
      id: leagueId,
      name: inviteData['leagueName'] is String
          ? inviteData['leagueName'] as String
          : 'League',
      ownerId: inviteData['ownerId'] is String
          ? inviteData['ownerId'] as String
          : '',
      badgePath: inviteData['badgePath'] is String
          ? inviteData['badgePath'] as String
          : 'assets/images/leaderboard/league_badges/league_people.webp',
      accentColorValue: inviteData['accentColor'] is num
          ? (inviteData['accentColor'] as num).toInt()
          : 0xFFFE5E02,
      inviteCode: inviteCode,
      memberCount: previewMemberCount + 1,
      memberIds: <String>[user.uid],
    );
  }

  static Future<List<LeagueRecord>> loadMyLeagues() async {
    final User user = _requireUser();

    final QuerySnapshot<Map<String, dynamic>> snapshot =
        await _firestore
            .collection('leagues')
            .where('memberIds', arrayContains: user.uid)
            .get();

    final List<LeagueRecord> leagues = snapshot.docs
        .map(LeagueRecord.fromSnapshot)
        .toList();

    leagues.sort(
      (LeagueRecord a, LeagueRecord b) =>
          a.name.toLowerCase().compareTo(b.name.toLowerCase()),
    );

    return leagues;
  }

  static Future<List<LeagueMemberRecord>> loadMembers(
    String leagueId,
  ) async {
    _requireUser();

    final QuerySnapshot<Map<String, dynamic>> snapshot =
        await _firestore
            .collection('leagues')
            .doc(leagueId)
            .collection('members')
            .get();

    return snapshot.docs
        .map(LeagueMemberRecord.fromSnapshot)
        .toList();
  }


  static Future<Map<String, PublicLeaderboardStatsRecord>>
      loadPublicLeaderboardStats(
    Iterable<String> userIds,
  ) {
    return _loadLeaderboardStats(
      userIds,
      documentId: 'public_stats',
      scoreField: 'totalScore',
    );
  }

  static Future<Map<String, PublicLeaderboardStatsRecord>>
      loadDailyLeaderboardStats(
    Iterable<String> userIds,
  ) {
    final DateTime now = DateTime.now();
    final String month = now.month.toString().padLeft(2, '0');
    final String day = now.day.toString().padLeft(2, '0');

    return _loadLeaderboardStats(
      userIds,
      documentId: 'daily_${now.year}-$month-$day',
      scoreField: 'score',
    );
  }


  static const String _allTimeRankSnapshotDocumentId = 'all_time';

  static String _dailyRankSnapshotDocumentId() {
    final DateTime now = DateTime.now();
    final String month = now.month.toString().padLeft(2, '0');
    final String day = now.day.toString().padLeft(2, '0');

    return 'daily_${now.year}-$month-$day';
  }

  static String _monthlyRankSnapshotDocumentId() {
    final DateTime now = DateTime.now();
    final String month = now.month.toString().padLeft(2, '0');

    return 'monthly_${now.year}-$month';
  }

  static Future<LeagueRankSnapshotRecord> _loadRankSnapshot(
    String leagueId,
    String documentId,
  ) async {
    _requireUser();

    final DocumentSnapshot<Map<String, dynamic>> snapshot =
        await _firestore
            .collection('leagues')
            .doc(leagueId)
            .collection('rank_snapshots')
            .doc(documentId)
            .get();

    if (!snapshot.exists || snapshot.data() == null) {
      return const LeagueRankSnapshotRecord();
    }

    return LeagueRankSnapshotRecord.fromData(snapshot.data()!);
  }

  static Future<void> _saveRankSnapshot(
    String leagueId,
    String documentId, {
    required Map<String, int> ranks,
    required Map<String, int> movements,
  }) async {
    _requireUser();

    await _firestore
        .collection('leagues')
        .doc(leagueId)
        .collection('rank_snapshots')
        .doc(documentId)
        .set(
      <String, dynamic>{
        'ranks': ranks,
        'movements': movements,
        'schemaVersion': _schemaVersion,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  static Future<LeagueRankSnapshotRecord> loadAllTimeRankSnapshot(
    String leagueId,
  ) {
    return _loadRankSnapshot(
      leagueId,
      _allTimeRankSnapshotDocumentId,
    );
  }

  static Future<void> saveAllTimeRankSnapshot(
    String leagueId, {
    required Map<String, int> ranks,
    required Map<String, int> movements,
  }) {
    return _saveRankSnapshot(
      leagueId,
      _allTimeRankSnapshotDocumentId,
      ranks: ranks,
      movements: movements,
    );
  }

  static Future<LeagueRankSnapshotRecord> loadDailyRankSnapshot(
    String leagueId,
  ) {
    return _loadRankSnapshot(
      leagueId,
      _dailyRankSnapshotDocumentId(),
    );
  }

  static Future<void> saveDailyRankSnapshot(
    String leagueId, {
    required Map<String, int> ranks,
    required Map<String, int> movements,
  }) {
    return _saveRankSnapshot(
      leagueId,
      _dailyRankSnapshotDocumentId(),
      ranks: ranks,
      movements: movements,
    );
  }

  static Future<LeagueRankSnapshotRecord> loadMonthlyRankSnapshot(
    String leagueId,
  ) {
    return _loadRankSnapshot(
      leagueId,
      _monthlyRankSnapshotDocumentId(),
    );
  }

  static Future<void> saveMonthlyRankSnapshot(
    String leagueId, {
    required Map<String, int> ranks,
    required Map<String, int> movements,
  }) {
    return _saveRankSnapshot(
      leagueId,
      _monthlyRankSnapshotDocumentId(),
      ranks: ranks,
      movements: movements,
    );
  }


  static Future<Map<String, PublicLeaderboardStatsRecord>>
      loadMonthlyLeaderboardStats(
    Iterable<String> userIds,
  ) {
    final DateTime now = DateTime.now();
    final String month = now.month.toString().padLeft(2, '0');

    return _loadLeaderboardStats(
      userIds,
      documentId: 'monthly_${now.year}-$month',
      scoreField: 'score',
    );
  }

  static Future<Map<String, PublicLeaderboardStatsRecord>>
      _loadLeaderboardStats(
    Iterable<String> userIds, {
    required String documentId,
    required String scoreField,
  }) async {
    _requireUser();

    final List<String> ids = userIds
        .where((String userId) => userId.trim().isNotEmpty)
        .toSet()
        .toList();

    if (ids.isEmpty) {
      return <String, PublicLeaderboardStatsRecord>{};
    }

    final List<MapEntry<String, PublicLeaderboardStatsRecord>?> results =
        await Future.wait(
      ids.map(
        (String userId) async {
          final DocumentSnapshot<Map<String, dynamic>> snapshot =
              await _firestore
                  .collection('players')
                  .doc(userId)
                  .collection('leaderboard')
                  .doc(documentId)
                  .get();

          if (!snapshot.exists || snapshot.data() == null) {
            return null;
          }

          return MapEntry<String, PublicLeaderboardStatsRecord>(
            userId,
            PublicLeaderboardStatsRecord.fromData(
              snapshot.data()!,
              scoreField: scoreField,
            ),
          );
        },
      ),
    );

    final Map<String, PublicLeaderboardStatsRecord> stats =
        <String, PublicLeaderboardStatsRecord>{};

    for (final MapEntry<String, PublicLeaderboardStatsRecord>? entry
        in results) {
      if (entry != null) {
        stats[entry.key] = entry.value;
      }
    }

    return stats;
  }

  static Future<String> _generateUniqueInviteCode() async {
    for (int attempt = 0;
        attempt < _maximumInviteGenerationAttempts;
        attempt++) {
      final String code = List<String>.generate(
        _inviteCodeLength,
        (_) => _inviteAlphabet[
            _random.nextInt(_inviteAlphabet.length)],
      ).join();

      final DocumentSnapshot<Map<String, dynamic>> snapshot =
          await _firestore
              .collection('league_invites')
              .doc(code)
              .get();

      if (!snapshot.exists) {
        return code;
      }
    }

    throw const LeagueServiceException(
      'Could not create an invite code. Please try again.',
    );
  }

  static String _normaliseInviteCode(
    String value,
  ) {
    return value
        .toUpperCase()
        .replaceAll(RegExp(r'[^A-Z0-9]'), '');
  }
}

class LeagueRecord {
  const LeagueRecord({
    required this.id,
    required this.name,
    required this.ownerId,
    required this.badgePath,
    required this.accentColorValue,
    required this.inviteCode,
    required this.memberCount,
    this.memberIds = const <String>[],
  });

  final String id;
  final String name;
  final String ownerId;
  final String badgePath;
  final int accentColorValue;
  final String inviteCode;
  final int memberCount;
  final List<String> memberIds;

  bool isOwner(String userId) => ownerId == userId;

  factory LeagueRecord.fromSnapshot(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    return LeagueRecord.fromData(
      id: snapshot.id,
      data: snapshot.data() ?? <String, dynamic>{},
    );
  }

  factory LeagueRecord.fromData({
    required String id,
    required Map<String, dynamic> data,
  }) {
    final dynamic rawAccentColor = data['accentColor'];
    final dynamic rawMemberCount = data['memberCount'];
    final dynamic rawMemberIds = data['memberIds'];

    return LeagueRecord(
      id: id,
      name: data['name'] is String
          ? data['name'] as String
          : 'League',
      ownerId: data['ownerId'] is String
          ? data['ownerId'] as String
          : '',
      badgePath: data['badgePath'] is String
          ? data['badgePath'] as String
          : 'assets/images/leaderboard/league_badges/league_people.webp',
      accentColorValue: rawAccentColor is num
          ? rawAccentColor.toInt()
          : 0xFFFE5E02,
      inviteCode: data['inviteCode'] is String
          ? data['inviteCode'] as String
          : '',
      memberCount: rawMemberCount is num
          ? rawMemberCount.toInt()
          : 0,
      memberIds: rawMemberIds is List
          ? rawMemberIds.whereType<String>().toList()
          : <String>[],
    );
  }

  LeagueRecord copyWith({
    int? memberCount,
    List<String>? memberIds,
  }) {
    return LeagueRecord(
      id: id,
      name: name,
      ownerId: ownerId,
      badgePath: badgePath,
      accentColorValue: accentColorValue,
      inviteCode: inviteCode,
      memberCount: memberCount ?? this.memberCount,
      memberIds: memberIds ?? this.memberIds,
    );
  }
}

class LeagueMemberRecord {
  const LeagueMemberRecord({
    required this.userId,
    required this.displayName,
    required this.avatarPath,
    required this.role,
  });

  final String userId;
  final String displayName;
  final String avatarPath;
  final String role;

  factory LeagueMemberRecord.fromSnapshot(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final Map<String, dynamic> data =
        snapshot.data() ?? <String, dynamic>{};

    return LeagueMemberRecord(
      userId: data['userId'] is String
          ? data['userId'] as String
          : snapshot.id,
      displayName: data['displayName'] is String
          ? data['displayName'] as String
          : 'Player',
      avatarPath: data['avatarPath'] is String
          ? data['avatarPath'] as String
          : 'assets/images/avatars/Final/optimized/default_avatar.webp',
      role: data['role'] is String
          ? data['role'] as String
          : 'member',
    );
  }
}


class PublicLeaderboardStatsRecord {
  const PublicLeaderboardStatsRecord({
    required this.totalScore,
    required this.firstGuesses,
  });

  final int totalScore;
  final int firstGuesses;

  factory PublicLeaderboardStatsRecord.fromData(
    Map<String, dynamic> data, {
    String scoreField = 'totalScore',
  }) {
    final dynamic rawTotalScore = data[scoreField];
    final dynamic rawFirstGuesses = data['firstGuesses'];

    return PublicLeaderboardStatsRecord(
      totalScore: rawTotalScore is num ? rawTotalScore.toInt() : 0,
      firstGuesses:
          rawFirstGuesses is num ? rawFirstGuesses.toInt() : 0,
    );
  }
}

class LeagueRankSnapshotRecord {
  const LeagueRankSnapshotRecord({
    this.ranks = const <String, int>{},
    this.movements = const <String, int>{},
  });

  final Map<String, int> ranks;
  final Map<String, int> movements;

  factory LeagueRankSnapshotRecord.fromData(
    Map<String, dynamic> data,
  ) {
    return LeagueRankSnapshotRecord(
      ranks: _intMap(data['ranks']),
      movements: _intMap(data['movements']),
    );
  }

  static Map<String, int> _intMap(dynamic raw) {
    if (raw is! Map) {
      return <String, int>{};
    }

    final Map<String, int> result = <String, int>{};

    raw.forEach((dynamic key, dynamic value) {
      if (key is String && value is num) {
        result[key] = value.toInt();
      }
    });

    return result;
  }
}


class LeagueServiceException implements Exception {
  const LeagueServiceException(
    this.message,
  );

  final String message;

  @override
  String toString() => message;
}
