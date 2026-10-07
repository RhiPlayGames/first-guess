import 'dart:async';

import 'package:flutter/material.dart';

import '../services/league_service.dart';
import 'invite_members_screen.dart';
import 'league_settings_screen.dart';

class LeagueDetailScreen extends StatefulWidget {
  const LeagueDetailScreen({
    super.key,
    required this.leagueName,
    required this.badgePath,
    required this.memberCount,
    required this.inviteCode,
  });

  final String leagueName;
  final String badgePath;
  final int memberCount;
  final String inviteCode;

  @override
  State<LeagueDetailScreen> createState() =>
      _LeagueDetailScreenState();
}

class _LeagueDetailScreenState extends State<LeagueDetailScreen> {
  static const Color _orange = Color(0xFFFE5E02);
  static const Color _gold = Color(0xFFFFB21A);
  static const Color _background = Color(0xFF050505);
  static const Color _panel = Color(0xFF111111);
  static const Color _border = Color(0xFF343434);
  static const Color _grey = Color(0xFFAAAAAA);
  static const Color _green = Color(0xFF5DD66F);
  static const Color _red = Color(0xFFFF5145);

  int _periodTab = 0;

  Timer? _countdownTimer;
  Duration _timeUntilReset = Duration.zero;

  List<_LeaguePlayer> _players = <_LeaguePlayer>[];
  List<_LeaguePlayer> _dailyPlayers = <_LeaguePlayer>[];
  List<_LeaguePlayer> _monthlyPlayers = <_LeaguePlayer>[];
  bool _isLoadingMembers = true;
  String? _memberLoadError;
  late int _memberCount;


  @override
  void initState() {
    super.initState();

    _memberCount = widget.memberCount;
    _loadMembers();
    _updateCountdown();

    _countdownTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _updateCountdown(),
    );
  }

  Future<void> _loadMembers() async {
    if (mounted) {
      setState(() {
        _isLoadingMembers = true;
        _memberLoadError = null;
      });
    }

    try {
      final LeagueRecord? league =
          await LeagueService.findLeagueByInviteCode(widget.inviteCode);

      if (league == null) {
        throw const LeagueServiceException(
          'This league could not be loaded.',
        );
      }

      final List<LeagueMemberRecord> members =
          await LeagueService.loadMembers(league.id);

      final Iterable<String> memberIds = members.map(
        (LeagueMemberRecord member) => member.userId,
      );

      final List<Map<String, PublicLeaderboardStatsRecord>> periodStats =
          await Future.wait(
        <Future<Map<String, PublicLeaderboardStatsRecord>>>[
          LeagueService.loadPublicLeaderboardStats(memberIds),
          LeagueService.loadDailyLeaderboardStats(memberIds),
          LeagueService.loadMonthlyLeaderboardStats(memberIds),
        ],
      );

      final String? currentUserId = LeagueService.currentUserId;

      final List<_LeaguePlayer> allTimePlayers = _buildRankedPlayers(
        members: members,
        stats: periodStats[0],
        currentUserId: currentUserId,
      );

      final List<_LeaguePlayer> dailyPlayers = _buildRankedPlayers(
        members: members,
        stats: periodStats[1],
        currentUserId: currentUserId,
      );

      final List<_LeaguePlayer> monthlyPlayers = _buildRankedPlayers(
        members: members,
        stats: periodStats[2],
        currentUserId: currentUserId,
      );

      final LeagueRankSnapshotRecord previousAllTimeSnapshot =
          await LeagueService.loadAllTimeRankSnapshot(league.id);

      final LeagueRankSnapshotRecord previousDailySnapshot =
          await LeagueService.loadDailyRankSnapshot(league.id);

      final LeagueRankSnapshotRecord previousMonthlySnapshot =
          await LeagueService.loadMonthlyRankSnapshot(league.id);

      final Map<String, int> currentAllTimePositions =
          _movementPositions(allTimePlayers);

      final Map<String, int> currentDailyPositions =
          _movementPositions(dailyPlayers);

      final Map<String, int> currentMonthlyPositions =
          _movementPositions(monthlyPlayers);

      final Map<String, int> allTimeMovements = _movementValues(
        previousPositions: previousAllTimeSnapshot.ranks,
        previousMovements: previousAllTimeSnapshot.movements,
        currentPositions: currentAllTimePositions,
      );

      final Map<String, int> dailyMovements = _movementValues(
        previousPositions: previousDailySnapshot.ranks,
        previousMovements: previousDailySnapshot.movements,
        currentPositions: currentDailyPositions,
      );

      final Map<String, int> monthlyMovements = _movementValues(
        previousPositions: previousMonthlySnapshot.ranks,
        previousMovements: previousMonthlySnapshot.movements,
        currentPositions: currentMonthlyPositions,
      );

      final List<_LeaguePlayer> allTimePlayersWithMovement =
          _applyMovementValues(
        allTimePlayers,
        allTimeMovements,
      );

      final List<_LeaguePlayer> dailyPlayersWithMovement =
          _applyMovementValues(
        dailyPlayers,
        dailyMovements,
      );

      final List<_LeaguePlayer> monthlyPlayersWithMovement =
          _applyMovementValues(
        monthlyPlayers,
        monthlyMovements,
      );

      await Future.wait(<Future<void>>[
        LeagueService.saveAllTimeRankSnapshot(
          league.id,
          ranks: currentAllTimePositions,
          movements: allTimeMovements,
        ),
        LeagueService.saveDailyRankSnapshot(
          league.id,
          ranks: currentDailyPositions,
          movements: dailyMovements,
        ),
        LeagueService.saveMonthlyRankSnapshot(
          league.id,
          ranks: currentMonthlyPositions,
          movements: monthlyMovements,
        ),
      ]);

      if (!mounted) {
        return;
      }

      setState(() {
        _players = allTimePlayersWithMovement;
        _dailyPlayers = dailyPlayersWithMovement;
        _monthlyPlayers = monthlyPlayersWithMovement;
        _memberCount = members.length;
        _isLoadingMembers = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _memberLoadError = 'League members could not be loaded.';
        _isLoadingMembers = false;
      });
    }
  }

  List<_LeaguePlayer> _buildRankedPlayers({
    required List<LeagueMemberRecord> members,
    required Map<String, PublicLeaderboardStatsRecord> stats,
    required String? currentUserId,
  }) {
    final List<_LeaguePlayer> players = members.map(
      (LeagueMemberRecord member) {
        final PublicLeaderboardStatsRecord? memberStats =
            stats[member.userId];

        return _LeaguePlayer(
          userId: member.userId,
          rank: 0,
          name: member.displayName,
          score: memberStats?.totalScore,
          firstGuesses: memberStats?.firstGuesses,
          movement: null,
          avatarPath: member.avatarPath,
          isCurrentPlayer: member.userId == currentUserId,
        );
      },
    ).toList();

    players.sort((_LeaguePlayer a, _LeaguePlayer b) {
      final int? aScore = a.score;
      final int? bScore = b.score;

      if (aScore == null && bScore == null) {
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      }
      if (aScore == null) {
        return 1;
      }
      if (bScore == null) {
        return -1;
      }

      final int scoreComparison = bScore.compareTo(aScore);
      if (scoreComparison != 0) {
        return scoreComparison;
      }

      final int firstGuessComparison =
          (b.firstGuesses ?? 0).compareTo(a.firstGuesses ?? 0);
      if (firstGuessComparison != 0) {
        return firstGuessComparison;
      }

      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });

    int nextRank = 1;

    return players.map(
      (_LeaguePlayer player) {
        final int rank = player.score == null ? 0 : nextRank++;
        return player.copyWith(rank: rank);
      },
    ).toList();
  }

  Map<String, int> _movementPositions(
    List<_LeaguePlayer> players,
  ) {
    return <String, int>{
      for (int index = 0; index < players.length; index++)
        players[index].userId: index + 1,
    };
  }

  Map<String, int> _movementValues({
    required Map<String, int> previousPositions,
    required Map<String, int> previousMovements,
    required Map<String, int> currentPositions,
  }) {
    final Map<String, int> movements = <String, int>{};

    currentPositions.forEach((String userId, int currentPosition) {
      final int? previousPosition = previousPositions[userId];

      if (previousPosition == null) {
        final int? previousMovement = previousMovements[userId];
        if (previousMovement != null) {
          movements[userId] = previousMovement;
        }
        return;
      }

      final int difference = previousPosition - currentPosition;

      if (difference != 0) {
        movements[userId] = difference;
        return;
      }

      final int? previousMovement = previousMovements[userId];
      if (previousMovement != null && previousMovement != 0) {
        movements[userId] = previousMovement;
      }
    });

    return movements;
  }

  List<_LeaguePlayer> _applyMovementValues(
    List<_LeaguePlayer> players,
    Map<String, int> movements,
  ) {
    return players.map(
      (_LeaguePlayer player) => player.copyWith(
        movement: movements[player.userId],
      ),
    ).toList();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _updateCountdown() {
    if (_periodTab == 0) {
      if (!mounted) {
        return;
      }

      setState(() {
        _timeUntilReset = Duration.zero;
      });

      return;
    }

    final DateTime now = DateTime.now();

    late final DateTime resetTime;

    if (_periodTab == 1) {
      resetTime = DateTime(
        now.year,
        now.month,
        now.day + 1,
      );
    } else {
      resetTime = DateTime(
        now.year,
        now.month + 1,
        1,
      );
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _timeUntilReset =
          resetTime.difference(now);
    });
  }

  String get _countdownText {
    final int days = _timeUntilReset.inDays;
    final int totalHours = _timeUntilReset.inHours;
    final int remainingHours = totalHours.remainder(24);
    final int minutes = _timeUntilReset.inMinutes.remainder(60);

    if (_periodTab == 2) {
      if (days > 0) {
        final String dayLabel = days == 1 ? 'DAY' : 'DAYS';
        final String hourLabel =
            remainingHours == 1 ? 'HOUR' : 'HOURS';
        return '$days $dayLabel $remainingHours $hourLabel';
      }

      final String hourLabel =
          totalHours == 1 ? 'HOUR' : 'HOURS';
      return '$totalHours $hourLabel';
    }

    final String hourLabel =
        totalHours == 1 ? 'HOUR' : 'HOURS';
    final String minuteLabel =
        minutes == 1 ? 'MINUTE' : 'MINUTES';

    return '$totalHours $hourLabel $minutes $minuteLabel';
  }

  @override
  Widget build(BuildContext context) {
    final bool isDesktop =
        MediaQuery.sizeOf(context).width >= 1200;

    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  isDesktop ? 24 : 14,
                  8,
                  isDesktop ? 24 : 14,
                  28,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth:
                          isDesktop ? 1200 : double.infinity,
                    ),
                    child: Column(
                      children: [
                    _buildLeagueIdentity(),
                    SizedBox(height: isDesktop ? 10 : 16),
                    _buildPeriodTabs(),
                    if (_periodTab != 0) ...[
                      SizedBox(height: isDesktop ? 8 : 10),
                      _buildResetCountdown(),
                    ],
                    SizedBox(height: isDesktop ? 10 : 18),
                    if (_isLoadingMembers)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 38),
                        child: Center(
                          child: CircularProgressIndicator(
                            color: _orange,
                          ),
                        ),
                      )
                    else if (_memberLoadError != null)
                      _buildMemberLoadError()
                    else if (_players.isEmpty)
                      _buildEmptyMembers()
                    else ...[
                      if (_hasLiveScores) ...[
                        _buildPodium(),
                        SizedBox(height: isDesktop ? 8 : 12),
                      ],
                      _buildTableHeader(),
                      const SizedBox(height: 6),
                      ..._visiblePlayers.map(
                        (player) => Padding(
                          padding: const EdgeInsets.only(
                            bottom: 6,
                          ),
                          child: _buildPlayerRow(
                            player,
                          ),
                        ),
                      ),
                    ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        12,
        8,
        12,
        6,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 44,
            height: 44,
            child: IconButton(
              padding: EdgeInsets.zero,
              onPressed: () {
                Navigator.of(context).pop();
              },
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
          const Spacer(),
          SizedBox(
            width: 44,
            height: 44,
            child: IconButton(
              padding: EdgeInsets.zero,
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (context) {
                      return LeagueSettingsScreen(
                        leagueName: widget.leagueName,
                        badgePath: widget.badgePath,
                        memberCount: widget.memberCount,
                      );
                    },
                  ),
                );
              },
              icon: const Icon(
                Icons.settings_rounded,
                color: Colors.white,
                size: 23,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeagueIdentity() {
    final bool isDesktop =
        MediaQuery.sizeOf(context).width >= 1200;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        isDesktop ? 12 : 14,
        isDesktop ? 10 : 14,
        isDesktop ? 12 : 14,
        isDesktop ? 10 : 14,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF0D0A09),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _border,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22FE5E02),
            blurRadius: 14,
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: isDesktop ? 86 : 122,
            height: isDesktop ? 86 : 122,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(
                isDesktop ? 20 : 26,
              ),
              border: Border.all(
                color: _orange,
                width: 1.4,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x44FE5E02),
                  blurRadius: 14,
                ),
              ],
            ),
            child: Image.asset(
              widget.badgePath,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
            ),
          ),
          SizedBox(width: isDesktop ? 12 : 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.leagueName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Oswald',
                    color: Colors.white,
                    fontSize: isDesktop ? 24 : 28,
                    fontWeight: FontWeight.w600,
                    height: 1,
                    letterSpacing: 0.2,
                  ),
                ),
                SizedBox(height: isDesktop ? 3 : 5),
                Text(
                  'LEAGUE',
                  style: TextStyle(
                    fontFamily: 'Oswald',
                    color: Colors.white,
                    fontSize: isDesktop ? 13 : 16,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 1.4,
                  ),
                ),
                SizedBox(height: isDesktop ? 6 : 10),
                Row(
                  children: [
                    const Icon(
                      Icons.people_alt_rounded,
                      color: Colors.white,
                      size: 17,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '$_memberCount ${_memberCount == 1 ? 'MEMBER' : 'MEMBERS'}',
                      style: const TextStyle(
                        fontFamily: 'Oswald',
                        color: Colors.white,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      height: 30,
                      child: OutlinedButton.icon(
                        onPressed: () => _openInviteMembers(context),
                        icon: const Icon(
                          Icons.person_add_alt_1_rounded,
                          size: 15,
                        ),
                        label: const Text('INVITE'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _orange,
                          side: const BorderSide(
                            color: _orange,
                            width: 1.2,
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 0,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          textStyle: const TextStyle(
                            fontFamily: 'Oswald',
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.25,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: isDesktop ? 6 : 10),
                const Text(
                  'Better clues. Tougher guesses. A smarter pack.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11.5,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodTabs() {
    final List<String> labels = [
      'ALL TIME',
      'DAILY',
      'MONTHLY',
    ];

    return Row(
      children: List.generate(
        labels.length,
        (index) {
          final bool selected =
              _periodTab == index;

          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                right:
                    index < labels.length - 1
                        ? 7
                        : 0,
              ),
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _periodTab = index;
                  });

                  _updateCountdown();
                },
                child:
                    AnimatedContainer(
                  duration:
                      const Duration(
                    milliseconds: 180,
                  ),
                  height: 42,
                  decoration:
                      BoxDecoration(
                    color: selected
                        ? const Color(
                            0xFF18110D,
                          )
                        : _panel,
                    borderRadius:
                        BorderRadius
                            .circular(18),
                    border: Border.all(
                      color: selected
                          ? _orange
                          : _border,
                      width: selected
                          ? 1.5
                          : 1,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      labels[index],
                      style: TextStyle(
                        fontFamily:
                            'Oswald',
                        color: selected
                            ? _orange
                            : _grey,
                        fontSize: 14,
                        fontWeight:
                            FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildResetCountdown() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: _panel,
        borderRadius:
            BorderRadius.circular(18),
        border: Border.all(
          color: const Color(
            0xFF8A4B11,
          ),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.access_time_rounded,
            color: _gold,
            size: 17,
          ),
          const SizedBox(width: 6),
          Text(
            'RESETS IN $_countdownText',
            style: const TextStyle(
              fontFamily: 'Oswald',
              color: Colors.white,
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  List<_LeaguePlayer> get _playersForSelectedPeriod {
    switch (_periodTab) {
      case 1:
        return _dailyPlayers;
      case 2:
        return _monthlyPlayers;
      default:
        return _players;
    }
  }

  bool get _hasLiveScores =>
      _playersForSelectedPeriod.length >= 3 &&
      _playersForSelectedPeriod.take(3).every(
        (_LeaguePlayer player) => player.score != null,
      );

  List<_LeaguePlayer> get _visiblePlayers => _hasLiveScores
      ? _playersForSelectedPeriod.skip(3).toList()
      : _playersForSelectedPeriod;

  Widget _buildPodium() {
    final bool isDesktop =
        MediaQuery.sizeOf(context).width >= 1200;

    return SizedBox(
      height: isDesktop ? 258 : 245,
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.end,
        children: [
          Expanded(
            child: _buildPodiumPlayer(
              _playersForSelectedPeriod[1],
              position: 2,
              crownPath:
                  'assets/images/leaderboard/crown_silver.webp',
              height: isDesktop ? 224 : 214,
              avatarSize: 62,
            ),
          ),
          Expanded(
            child: _buildPodiumPlayer(
              _playersForSelectedPeriod[0],
              position: 1,
              crownPath:
                  'assets/images/leaderboard/crown_gold.webp',
              height: isDesktop ? 253 : 243,
              avatarSize: 76,
            ),
          ),
          Expanded(
            child: _buildPodiumPlayer(
              _playersForSelectedPeriod[2],
              position: 3,
              crownPath:
                  'assets/images/leaderboard/crown_bronze.webp',
              height: isDesktop ? 218 : 208,
              avatarSize: 60,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPodiumPlayer(
    _LeaguePlayer player, {
    required int position,
    required String crownPath,
    required double height,
    required double avatarSize,
  }) {
    final Color accent =
        switch (position) {
      1 => _gold,
      2 => const Color(
          0xFFC8CDD4,
        ),
      _ => const Color(
          0xFFC87946,
        ),
    };

    return SizedBox(
      height: height,
      child: Column(
        mainAxisAlignment:
            MainAxisAlignment.end,
        children: [
          Image.asset(
            crownPath,
            width:
                position == 1 ? 54 : 44,
            height:
                position == 1 ? 54 : 44,
          ),
          const SizedBox(height: 2),
          Container(
            width: avatarSize,
            height: avatarSize,
            padding:
                const EdgeInsets.all(2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: accent,
                width:
                    position == 1 ? 3 : 2,
              ),
            ),
            child: ClipOval(
              child: Image.asset(
                player.avatarPath,
                fit: BoxFit.cover,
              ),
            ),
          ),
          Transform.translate(
            offset:
                const Offset(0, -4),
            child: Container(
              width:
                  position == 1
                      ? 39
                      : 34,
              height:
                  position == 1
                      ? 39
                      : 34,
              alignment:
                  Alignment.center,
              decoration:
                  BoxDecoration(
                shape: BoxShape.circle,
                color: accent,
                border: Border.all(
                  color: Colors.black,
                  width: 2,
                ),
              ),
              child: Text(
                '$position',
                style: TextStyle(
                  fontFamily: 'Oswald',
                  color: Colors.black,
                  fontSize:
                      position == 1
                          ? 22
                          : 18,
                  fontWeight:
                      FontWeight.w600,
                ),
              ),
            ),
          ),
          Text(
            player.name,
            maxLines: 1,
            overflow:
                TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'Oswald',
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            _formatScore(
              player.score ?? 0,
            ),
            style: TextStyle(
              fontFamily: 'Oswald',
              color: accent,
              fontSize:
                  position == 1
                      ? 19
                      : 16,
              fontWeight:
                  FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Row(
            mainAxisAlignment:
                MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.star_rounded,
                color: _gold,
                size: 15,
              ),
              const SizedBox(width: 3),
              Text(
                '${player.firstGuesses ?? 0}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11.5,
                  fontWeight:
                      FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTableHeader() {
    return const Padding(
      padding:
          EdgeInsets.symmetric(
        horizontal: 10,
      ),
      child: Row(
        children: [
          SizedBox(width: 38),
          Expanded(
            child: Text(
              'PLAYER',
              style: TextStyle(
                fontFamily: 'Oswald',
                color: Colors.white,
                fontSize: 10.5,
              ),
            ),
          ),
          SizedBox(
            width: 68,
            child: Text(
              'SCORE',
              textAlign:
                  TextAlign.right,
              style: TextStyle(
                fontFamily: 'Oswald',
                color: Colors.white,
                fontSize: 10.5,
              ),
            ),
          ),
          SizedBox(
            width: 78,
            child: Text(
              'FIRST GUESS',
              textAlign:
                  TextAlign.center,
              style: TextStyle(
                fontFamily: 'Oswald',
                color: Colors.white,
                fontSize: 9.5,
              ),
            ),
          ),
          SizedBox(
            width: 50,
            child: Text(
              'CHANGE',
              textAlign:
                  TextAlign.center,
              style: TextStyle(
                fontFamily: 'Oswald',
                color: Colors.white,
                fontSize: 9.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerRow(
    _LeaguePlayer player,
  ) {
    final bool isYou =
        player.isCurrentPlayer;

    return Container(
      height: 50,
      padding:
          const EdgeInsets.symmetric(
        horizontal: 10,
      ),
      decoration: BoxDecoration(
        color: isYou
            ? const Color(
                0xFF17110D,
              )
            : _panel,
        borderRadius:
            BorderRadius.circular(11),
        border: Border.all(
          color: isYou
              ? _orange
              : _border,
          width: isYou ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Text(
              player.rank <= 0 || player.score == null ? '—' : '${player.rank}',
              textAlign:
                  TextAlign.center,
              style: TextStyle(
                fontFamily: 'Oswald',
                color: isYou
                    ? _orange
                    : Colors.white,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(width: 6),
          _buildSmallAvatar(
            player,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              player.name,
              maxLines: 1,
              overflow:
                  TextOverflow.ellipsis,
              style: TextStyle(
                color: isYou
                    ? _orange
                    : Colors.white,
                fontSize: 13.5,
                fontWeight:
                    FontWeight.w500,
              ),
            ),
          ),
          SizedBox(
            width: 68,
            child: Text(
              player.score == null
                  ? '—'
                  : _formatScore(
                      player.score!,
                    ),
              textAlign:
                  TextAlign.right,
              style: const TextStyle(
                fontFamily: 'Oswald',
                color: _gold,
                fontSize: 15,
                fontWeight:
                    FontWeight.w600,
              ),
            ),
          ),
          SizedBox(
            width: 78,
            child: Row(
              mainAxisAlignment:
                  MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.star_rounded,
                  color: _gold,
                  size: 14,
                ),
                const SizedBox(width: 3),
                Text(
                  player.firstGuesses == null
                      ? '—'
                      : '${player.firstGuesses}',
                  style:
                      const TextStyle(
                    color: Colors.white,
                    fontSize: 11.5,
                    fontWeight:
                        FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 50,
            child: _buildMovement(
              player.movement,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSmallAvatar(
    _LeaguePlayer player,
  ) {
    return Container(
      width: 32,
      height: 32,
      padding:
          const EdgeInsets.all(1),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: _orange,
        ),
      ),
      child: ClipOval(
        child: Image.asset(
          player.avatarPath,
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Widget _buildMovement(
    int? movement,
  ) {
    if (movement == null) {
      return const Center(
        child: Text(
          '—',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
          ),
        ),
      );
    }
    if (movement > 0) {
      return Row(
        mainAxisAlignment:
            MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.arrow_upward_rounded,
            color: _green,
            size: 19,
          ),
          const SizedBox(width: 2),
          Text(
            '$movement',
            style: const TextStyle(
              color: _green,
              fontSize: 11.5,
              fontWeight:
                  FontWeight.w700,
            ),
          ),
        ],
      );
    }

    if (movement < 0) {
      return Row(
        mainAxisAlignment:
            MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.arrow_downward_rounded,
            color: _red,
            size: 19,
          ),
          const SizedBox(width: 2),
          Text(
            '${movement.abs()}',
            style: const TextStyle(
              color: _red,
              fontSize: 11.5,
              fontWeight:
                  FontWeight.w700,
            ),
          ),
        ],
      );
    }

    return const Center(
      child: Text(
        '—',
        style: TextStyle(
          color: Colors.white,
          fontSize: 18,
        ),
      ),
    );
  }

  Widget _buildMemberLoadError() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 20),
      decoration: BoxDecoration(
        color: _panel,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _border,
        ),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: _orange,
            size: 30,
          ),
          const SizedBox(height: 8),
          Text(
            _memberLoadError ?? 'League members could not be loaded.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12.5,
            ),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: _loadMembers,
            icon: const Icon(
              Icons.refresh_rounded,
              size: 18,
            ),
            label: const Text('TRY AGAIN'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: const BorderSide(
                color: _orange,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyMembers() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 20),
      decoration: BoxDecoration(
        color: _panel,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _border,
        ),
      ),
      child: const Text(
        'No league members found.',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Colors.white,
          fontSize: 12.5,
        ),
      ),
    );
  }

  void _openInviteMembers(
    BuildContext context,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) {
          return InviteMembersScreen(
            leagueName: widget.leagueName,
            badgePath: widget.badgePath,
            memberCount: _memberCount,
            inviteCode: widget.inviteCode,
          );
        },
      ),
    );
  }


  String _formatScore(
    int value,
  ) {
    final String raw =
        value.toString();

    final StringBuffer result =
        StringBuffer();

    for (int i = 0;
        i < raw.length;
        i++) {
      final int remaining =
          raw.length - i;

      result.write(raw[i]);

      if (remaining > 1 &&
          remaining % 3 == 1) {
        result.write(',');
      }
    }

    return result.toString();
  }
}

const Object _unsetLeaguePlayerValue = Object();

class _LeaguePlayer {
  const _LeaguePlayer({
    required this.userId,
    required this.rank,
    required this.name,
    required this.score,
    required this.firstGuesses,
    required this.movement,
    required this.avatarPath,
    this.isCurrentPlayer = false,
  });


  _LeaguePlayer copyWith({
    String? userId,
    int? rank,
    String? name,
    Object? score = _unsetLeaguePlayerValue,
    Object? firstGuesses = _unsetLeaguePlayerValue,
    Object? movement = _unsetLeaguePlayerValue,
    String? avatarPath,
    bool? isCurrentPlayer,
  }) {
    return _LeaguePlayer(
      userId: userId ?? this.userId,
      rank: rank ?? this.rank,
      name: name ?? this.name,
      score: identical(score, _unsetLeaguePlayerValue)
          ? this.score
          : score as int?,
      firstGuesses: identical(
        firstGuesses,
        _unsetLeaguePlayerValue,
      )
          ? this.firstGuesses
          : firstGuesses as int?,
      movement: identical(movement, _unsetLeaguePlayerValue)
          ? this.movement
          : movement as int?,
      avatarPath: avatarPath ?? this.avatarPath,
      isCurrentPlayer:
          isCurrentPlayer ?? this.isCurrentPlayer,
    );
  }

  final String userId;
  final int rank;
  final String name;
  final int? score;
  final int? firstGuesses;
  final int? movement;
  final String avatarPath;
  final bool isCurrentPlayer;
}
