import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/avatar_preferences_service.dart';
import '../services/player_profile_service.dart';
import '../widgets/app_home_button.dart';
import 'my_leagues_screen.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  static const Color _orange = Color(0xFFFE5E02);
  static const Color _gold = Color(0xFFFFB21A);
  static const Color _background = Color(0xFF050505);
  static const Color _panel = Color(0xFF111111);
  static const Color _border = Color(0xFF343434);
  static const Color _grey = Color(0xFFAAAAAA);
  static const Color _green = Color(0xFF5DD66F);
  static const Color _red = Color(0xFFFF5145);

  int _mainTab = 0;
  int _periodTab = 0;

  Timer? _countdownTimer;
  Duration _timeUntilReset = Duration.zero;

  bool _isLoading = true;
  List<_LeaderboardPlayer> _players = <_LeaderboardPlayer>[];
  _LeaderboardPlayer? _currentPlayer;

  static const List<_SeededPlayer> _seededPlayers = <_SeededPlayer>[
    _SeededPlayer('seed_01', 'Quiz Lover', 'assets/images/avatars/Final/optimized/15_fox.webp', 15550, 84, 1250, 8, 4230, 27),
    _SeededPlayer('seed_02', 'Milo', 'assets/images/avatars/Final/optimized/owl.webp', 14920, 79, 1180, 7, 3980, 25),
    _SeededPlayer('seed_03', 'Puzzle Panda', 'assets/images/avatars/Final/optimized/13_panda.webp', 14180, 73, 1110, 7, 3760, 23),
    _SeededPlayer('seed_04', 'Luna', 'assets/images/avatars/Final/optimized/raccoon_blocky.webp', 13240, 69, 1030, 6, 3510, 21),
    _SeededPlayer('seed_05', 'Trivia Otter', 'assets/images/avatars/Final/optimized/07_otter.webp', 12460, 64, 960, 6, 3290, 20),
    _SeededPlayer('seed_06', 'Fact Finder', 'assets/images/avatars/Final/optimized/21_astronaut.webp', 11690, 59, 890, 5, 3060, 18),
    _SeededPlayer('seed_07', 'Dexter', 'assets/images/avatars/Final/optimized/knight.webp', 10820, 55, 820, 5, 2840, 17),
    _SeededPlayer('seed_08', 'Clue Cat', 'assets/images/avatars/Final/optimized/10_black_white_cat.webp', 9960, 49, 750, 4, 2610, 15),
    _SeededPlayer('seed_09', 'Poppy', 'assets/images/avatars/Final/optimized/05_pig.webp', 9140, 45, 680, 4, 2380, 14),
    _SeededPlayer('seed_10', 'Puzzle Parrot', 'assets/images/avatars/Final/optimized/08_parrot.webp', 8360, 41, 610, 4, 2160, 13),
    _SeededPlayer('seed_11', 'Merlin', 'assets/images/avatars/Final/optimized/wizard.webp', 7580, 37, 540, 3, 1940, 11),
    _SeededPlayer('seed_12', 'Clue Chaser', 'assets/images/avatars/Final/optimized/16_giraffe.webp', 6810, 33, 470, 3, 1720, 10),
    _SeededPlayer('seed_13', 'Nova', 'assets/images/avatars/Final/optimized/robot.webp', 6090, 29, 410, 2, 1510, 9),
    _SeededPlayer('seed_14', 'Brain Box', 'assets/images/avatars/Final/optimized/scientist.webp', 5380, 25, 350, 2, 1310, 8),
    _SeededPlayer('seed_15', 'Finn', 'assets/images/avatars/Final/optimized/pirate.webp', 4670, 22, 300, 2, 1120, 7),
    _SeededPlayer('seed_16', 'Guess Again', 'assets/images/avatars/Final/optimized/ghost.webp', 3970, 18, 250, 1, 940, 5),
    _SeededPlayer('seed_17', 'Pip', 'assets/images/avatars/Final/optimized/penguin.webp', 3290, 15, 200, 1, 770, 4),
    _SeededPlayer('seed_18', 'Trivia Star', 'assets/images/avatars/Final/optimized/12_zebra.webp', 2630, 12, 150, 1, 610, 3),
    _SeededPlayer('seed_19', 'Ziggy', 'assets/images/avatars/Final/optimized/alien.webp', 1980, 9, 100, 1, 450, 2),
    _SeededPlayer('seed_20', 'Clue Hunter', 'assets/images/avatars/Final/optimized/04_hedgehog.webp', 1360, 6, 60, 0, 290, 1),
  ];

  @override
  void initState() {
    super.initState();
    _updateCountdown();
    _loadLeaderboard();
    _countdownTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _updateCountdown(),
    );
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  String _periodId() {
    final DateTime now = DateTime.now();
    final String month = now.month.toString().padLeft(2, '0');
    final String day = now.day.toString().padLeft(2, '0');
    if (_periodTab == 1) return 'daily_${now.year}-$month-$day';
    if (_periodTab == 2) return 'monthly_${now.year}-$month';
    return 'all_time';
  }

  Future<_LeaderboardPlayer> _loadCurrentPlayerFallback(
    String currentUid,
    String periodId,
  ) async {
    int score = 0;
    int firstGuesses = 0;

    try {
      final String legacyDocumentId = periodId == 'all_time'
          ? 'public_stats'
          : periodId;
      final DocumentSnapshot<Map<String, dynamic>> legacySnapshot =
          await FirebaseFirestore.instance
              .collection('players')
              .doc(currentUid)
              .collection('leaderboard')
              .doc(legacyDocumentId)
              .get();

      final Map<String, dynamic>? legacyData = legacySnapshot.data();
      if (legacyData != null) {
        final String scoreField = periodId == 'all_time'
            ? 'totalScore'
            : 'score';
        score = (legacyData[scoreField] as num?)?.toInt() ?? 0;
        firstGuesses =
            (legacyData['firstGuesses'] as num?)?.toInt() ?? 0;
      }
    } on FirebaseException {
      // A missing legacy period record simply means a zero score.
    }

    final String? savedDisplayName =
        await PlayerProfileService.loadDisplayName();
    final String displayName =
        savedDisplayName?.trim().isNotEmpty == true
            ? savedDisplayName!.trim()
            : 'Player';

    final String avatarPath =
        await AvatarPreferencesService.loadSelectedAvatarPath() ??
            'assets/images/avatars/Final/optimized/default_avatar.webp';

    return _LeaderboardPlayer(
      id: currentUid,
      rank: 0,
      name: displayName,
      score: score,
      firstGuesses: firstGuesses,
      movement: 0,
      avatarPath: avatarPath,
      isCurrentPlayer: true,
    );
  }

  Future<_GlobalRankSnapshot> _loadRankSnapshot(
    String periodId,
  ) async {
    try {
      final DocumentSnapshot<Map<String, dynamic>> snapshot =
          await FirebaseFirestore.instance
              .collection('global_leaderboards')
              .doc(periodId)
              .collection('rank_snapshots')
              .doc('current')
              .get();

      final Map<String, dynamic>? data = snapshot.data();
      if (data == null) {
        return const _GlobalRankSnapshot();
      }

      return _GlobalRankSnapshot.fromData(data);
    } on FirebaseException {
      return const _GlobalRankSnapshot();
    }
  }

  Future<void> _saveRankSnapshot(
    String periodId, {
    required Map<String, int> ranks,
    required Map<String, int> movements,
  }) async {
    try {
      await FirebaseFirestore.instance
          .collection('global_leaderboards')
          .doc(periodId)
          .collection('rank_snapshots')
          .doc('current')
          .set(
        <String, dynamic>{
          'ranks': ranks,
          'movements': movements,
          'schemaVersion': 1,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    } on FirebaseException {
      // Movement tracking must never block the Global leaderboard.
    }
  }

  Map<String, int> _movementValues({
    required Map<String, int> previousRanks,
    required Map<String, int> previousMovements,
    required Map<String, int> currentRanks,
  }) {
    final Map<String, int> movements = <String, int>{};

    currentRanks.forEach((String playerId, int currentRank) {
      final int? previousRank = previousRanks[playerId];
      final int previousMovement = previousMovements[playerId] ?? 0;

      if (previousRank == null) {
        movements[playerId] = previousMovement;
        return;
      }

      final int rankMovement = previousRank - currentRank;
      movements[playerId] =
          rankMovement == 0 ? previousMovement : rankMovement;
    });

    return movements;
  }

  Future<void> _loadLeaderboard() async {
    if (mounted) setState(() => _isLoading = true);
    final String periodId = _periodId();
    final String? currentUid = FirebaseAuth.instance.currentUser?.uid;

    final List<_LeaderboardPlayer> combined = _seededPlayers.map((seed) {
      return seed.toLeaderboardPlayer(_periodTab);
    }).toList();

    try {
      final CollectionReference<Map<String, dynamic>> collection =
          FirebaseFirestore.instance
              .collection('global_leaderboards')
              .doc(periodId)
              .collection('players');

      final QuerySnapshot<Map<String, dynamic>> snapshot = await collection
          .orderBy('score', descending: true)
          .limit(100)
          .get();

      final Map<String, _LeaderboardPlayer> realPlayers =
          <String, _LeaderboardPlayer>{};

      for (final QueryDocumentSnapshot<Map<String, dynamic>> doc
          in snapshot.docs) {
        final Map<String, dynamic> data = doc.data();
        realPlayers[doc.id] = _LeaderboardPlayer(
          id: doc.id,
          rank: 0,
          name: (data['displayName'] as String?)?.trim().isNotEmpty == true
              ? (data['displayName'] as String).trim()
              : 'Player',
          score: (data['score'] as num?)?.toInt() ?? 0,
          firstGuesses: (data['firstGuesses'] as num?)?.toInt() ?? 0,
          movement: 0,
          avatarPath: (data['avatarPath'] as String?)?.isNotEmpty == true
              ? data['avatarPath'] as String
              : 'assets/images/avatars/Final/optimized/default_avatar.webp',
          isCurrentPlayer: doc.id == currentUid,
        );
      }

      if (currentUid != null && !realPlayers.containsKey(currentUid)) {
        final _LeaderboardPlayer fallbackPlayer =
            await _loadCurrentPlayerFallback(
          currentUid,
          periodId,
        );
        realPlayers[currentUid] = fallbackPlayer;
      }

      combined.addAll(realPlayers.values);
    } on FirebaseException {
      // Seeded players keep the Global leaderboard usable if Firestore is unavailable.
    }

    combined.sort((a, b) {
      final int byScore = b.score.compareTo(a.score);
      if (byScore != 0) return byScore;
      final int byFirstGuess = b.firstGuesses.compareTo(a.firstGuesses);
      if (byFirstGuess != 0) return byFirstGuess;
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });

    final List<_LeaderboardPlayer> rankedWithoutMovement =
        <_LeaderboardPlayer>[];
    for (int index = 0; index < combined.length; index++) {
      rankedWithoutMovement.add(
        combined[index].copyWith(rank: index + 1),
      );
    }

    final Map<String, int> currentRanks = <String, int>{
      for (final _LeaderboardPlayer player in rankedWithoutMovement)
        player.id: player.rank,
    };

    final _GlobalRankSnapshot previousSnapshot =
        await _loadRankSnapshot(periodId);
    final Map<String, int> movements = _movementValues(
      previousRanks: previousSnapshot.ranks,
      previousMovements: previousSnapshot.movements,
      currentRanks: currentRanks,
    );

    final List<_LeaderboardPlayer> ranked = rankedWithoutMovement
        .map(
          (_LeaderboardPlayer player) => player.copyWith(
            movement: movements[player.id] ?? 0,
          ),
        )
        .toList();

    await _saveRankSnapshot(
      periodId,
      ranks: currentRanks,
      movements: movements,
    );

    _LeaderboardPlayer? currentPlayer;
    if (currentUid != null) {
      for (final _LeaderboardPlayer player in ranked) {
        if (player.id == currentUid) {
          currentPlayer = player.copyWith(isCurrentPlayer: true);
          break;
        }
      }
    }

    if (!mounted) return;
    setState(() {
      _players = ranked.take(10).toList();
      _currentPlayer = currentPlayer;
      _isLoading = false;
    });
  }

  void _updateCountdown() {
    if (_periodTab == 0) {
      if (!mounted) return;
      setState(() => _timeUntilReset = Duration.zero);
      return;
    }

    final DateTime now = DateTime.now();
    final DateTime resetTime = _periodTab == 1
        ? DateTime(now.year, now.month, now.day + 1)
        : DateTime(now.year, now.month + 1, 1);

    if (!mounted) return;
    setState(() => _timeUntilReset = resetTime.difference(now));
  }

  String get _countdownText {
    final int days = _timeUntilReset.inDays;
    final int totalHours = _timeUntilReset.inHours;
    final int remainingHours = totalHours.remainder(24);
    final int minutes = _timeUntilReset.inMinutes.remainder(60);

    if (_periodTab == 2) {
      if (days > 0) {
        final String dayLabel = days == 1 ? 'DAY' : 'DAYS';
        final String hourLabel = remainingHours == 1 ? 'HOUR' : 'HOURS';
        return '$days $dayLabel $remainingHours $hourLabel';
      }
      final String hourLabel = totalHours == 1 ? 'HOUR' : 'HOURS';
      return '$totalHours $hourLabel';
    }

    final String hourLabel = totalHours == 1 ? 'HOUR' : 'HOURS';
    final String minuteLabel = minutes == 1 ? 'MINUTE' : 'MINUTES';
    return '$totalHours $hourLabel $minutes $minuteLabel';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: _mainTab == 0
                  ? _buildGlobalLeaderboard()
                  : MyLeaguesScreen(
                      onGlobalPressed: () {
                        setState(() {
                          _mainTab = 0;
                        });
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return SizedBox(
      height: 82,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          12,
          8,
          26,
          6,
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: SizedBox(
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
            ),
            const Padding(
              padding: EdgeInsets.only(top: 14),
              child: Text(
                'MY LEADERBOARD',
                style: TextStyle(
                  fontFamily: 'Oswald',
                  color: Colors.white,
                  fontSize: 27,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.4,
                ),
              ),
            ),
            const Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: EdgeInsets.only(top: 14),
                child: FirstGuessHomeButton(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGlobalLeaderboard() {
    final bool isDesktop = MediaQuery.sizeOf(context).width >= 1200;

    if (_isLoading || _players.length < 3) {
      return Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
              isDesktop ? 24 : 14,
              8,
              isDesktop ? 24 : 14,
              0,
            ),
            child: Column(
              children: [
                _buildMainTabs(),
                const SizedBox(height: 12),
                _buildPeriodTabs(),
              ],
            ),
          ),
          const Expanded(
            child: Center(
              child: CircularProgressIndicator(color: _orange),
            ),
          ),
        ],
      );
    }

    final bool currentInTopTen = _currentPlayer != null &&
        _players.any((player) => player.id == _currentPlayer!.id);

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        isDesktop ? 24 : 14,
        8,
        isDesktop ? 24 : 14,
        26,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: isDesktop ? 1320 : double.infinity,
          ),
          child: Column(
            children: [
              _buildMainTabs(),
              const SizedBox(height: 12),
              _buildPeriodTabs(),
              if (_periodTab != 0) ...[
                const SizedBox(height: 10),
                _buildResetCountdown(),
              ],
              SizedBox(height: isDesktop ? 18 : 14),
              _buildPodium(),
              SizedBox(height: isDesktop ? 16 : 10),
              if (isDesktop)
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1080),
                  child: Column(
                    children: [
                      _buildTableHeader(),
                      const SizedBox(height: 8),
                      ..._players.skip(3).map(
                            (player) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: _buildPlayerRow(player),
                            ),
                          ),
                      if (_currentPlayer != null && !currentInTopTen) ...[
                        const SizedBox(height: 4),
                        _buildPinnedPlayer(),
                      ],
                      const SizedBox(height: 12),
                      _buildLegend(),
                    ],
                  ),
                )
              else ...[
                _buildTableHeader(),
                const SizedBox(height: 6),
                ..._players.skip(3).map(
                      (player) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: _buildPlayerRow(player),
                      ),
                    ),
                if (_currentPlayer != null && !currentInTopTen) ...[
                  const SizedBox(height: 8),
                  _buildPinnedPlayer(),
                ],
                const SizedBox(height: 12),
                _buildLegend(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainTabs() {
    return Container(
      height: 54,
      decoration: BoxDecoration(
        color: _panel,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _border,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildMainTab(
              index: 0,
              label: 'GLOBAL',
              imagePath:
                  'assets/images/leaderboard/global.webp',
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: _border,
          ),
          Expanded(
            child: _buildMainTab(
              index: 1,
              label: 'MY LEAGUES',
              imagePath:
                  'assets/images/leaderboard/my_leagues.webp',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainTab({
    required int index,
    required String label,
    required String imagePath,
  }) {
    final bool selected = _mainTab == index;
    final bool isDesktop =
        MediaQuery.sizeOf(context).width >= 1200;

    return GestureDetector(
      onTap: () {
        setState(() {
          _mainTab = index;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(
          milliseconds: 180,
        ),
        height: double.infinity,
        decoration: BoxDecoration(
          color: selected
              ? Colors.black
              : Colors.transparent,
          borderRadius: BorderRadius.circular(15),
          border: selected
              ? Border.all(
                  color: _orange,
                  width: 1.5,
                )
              : null,
          boxShadow: selected
              ? const [
                  BoxShadow(
                    color: Color(0x33FE5E02),
                    blurRadius: 8,
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              imagePath,
              width: 32,
              height: 32,
              fit: BoxFit.contain,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Oswald',
                color: selected
                    ? Colors.white
                    : _grey,
                fontSize: isDesktop ? 19 : 16,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
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
          final bool selected = _periodTab == index;

          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                right: index < labels.length - 1
                    ? 7
                    : 0,
              ),
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _periodTab = index;
                  });

                  _updateCountdown();
                  _loadLeaderboard();
                },
                child: AnimatedContainer(
                  duration: const Duration(
                    milliseconds: 180,
                  ),
                  height: 42,
                  decoration: BoxDecoration(
                    color: selected
                        ? const Color(
                            0xFF18110D,
                          )
                        : _panel,
                    borderRadius: BorderRadius.circular(
                      18,
                    ),
                    border: Border.all(
                      color: selected
                          ? _orange
                          : _border,
                      width: selected ? 1.5 : 1,
                    ),
                  ),
                  child: Center(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                        ),
                        child: Text(
                          labels[index],
                          style: TextStyle(
                            fontFamily: 'Oswald',
                            color: selected
                                ? _orange
                                : _grey,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
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
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 7,
        ),
        decoration: BoxDecoration(
          color: _panel,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: const Color(0xFF8A4B11),
            width: 1,
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
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPodium() {
    final bool isDesktop =
        MediaQuery.sizeOf(context).width >= 1200;

    final Widget podium = SizedBox(
      height: isDesktop ? 258 : 252,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: _buildPodiumPlayer(
              _players[1],
              position: 2,
              crownPath:
                  'assets/images/leaderboard/crown_silver.webp',
              height: isDesktop ? 226 : 220,
              avatarSize: isDesktop ? 58 : 62,
            ),
          ),
          Expanded(
            child: _buildPodiumPlayer(
              _players[0],
              position: 1,
              crownPath:
                  'assets/images/leaderboard/crown_gold.webp',
              height: isDesktop ? 246 : 250,
              avatarSize: isDesktop ? 70 : 76,
            ),
          ),
          Expanded(
            child: _buildPodiumPlayer(
              _players[2],
              position: 3,
              crownPath:
                  'assets/images/leaderboard/crown_bronze.webp',
              height: isDesktop ? 222 : 214,
              avatarSize: isDesktop ? 56 : 60,
            ),
          ),
        ],
      ),
    );

    if (!isDesktop) {
      return podium;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 14),
      decoration: BoxDecoration(
        color: _panel,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: _border,
        ),
      ),
      child: podium,
    );
  }

  Widget _buildPodiumPlayer(
    _LeaderboardPlayer player, {
    required int position,
    required String crownPath,
    required double height,
    required double avatarSize,
  }) {
    final Color accent = switch (position) {
      1 => _gold,
      2 => const Color(0xFFC8CDD4),
      _ => const Color(0xFFC87946),
    };

    return SizedBox(
      height: height,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Image.asset(
            crownPath,
            width: position == 1 ? 54 : 44,
            height: position == 1 ? 54 : 44,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: 2),
          Container(
            width: avatarSize,
            height: avatarSize,
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: accent,
                width: position == 1 ? 3 : 2,
              ),
              boxShadow: position == 1
                  ? const [
                      BoxShadow(
                        color: Color(0x66FFB21A),
                        blurRadius: 12,
                      ),
                    ]
                  : null,
            ),
            child: ClipOval(
              child: Image.asset(
                player.avatarPath,
                fit: BoxFit.cover,
              ),
            ),
          ),
          Transform.translate(
            offset: const Offset(0, -4),
            child: Container(
              width: position == 1 ? 39 : 34,
              height: position == 1 ? 39 : 34,
              alignment: Alignment.center,
              decoration: BoxDecoration(
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
                  fontSize: position == 1 ? 22 : 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: 1),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              player.name,
              maxLines: 1,
              style: const TextStyle(
                fontFamily: 'Oswald',
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            _formatScore(player.score),
            style: TextStyle(
              fontFamily: 'Oswald',
              color: accent,
              fontSize: position == 1 ? 19 : 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.star_rounded,
                color: _gold,
                size: 15,
              ),
              const SizedBox(width: 3),
              Text(
                '${player.firstGuesses}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTableHeader() {
    final bool isDesktop =
        MediaQuery.sizeOf(context).width >= 1200;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: 10,
      ),
      child: Row(
        children: [
          SizedBox(width: isDesktop ? 48 : 38),
          Expanded(
            child: Text(
              'PLAYER',
              style: TextStyle(
                fontFamily: 'Oswald',
                color: Colors.white,
                fontSize: isDesktop ? 12.5 : 10.5,
                letterSpacing: 0.5,
              ),
            ),
          ),
          SizedBox(
            width: isDesktop ? 90 : 61,
            child: Text(
              'SCORE',
              textAlign: TextAlign.right,
              style: TextStyle(
                fontFamily: 'Oswald',
                color: Colors.white,
                fontSize: isDesktop ? 12.5 : 10.5,
                letterSpacing: 0.5,
              ),
            ),
          ),
          SizedBox(
            width: isDesktop ? 100 : 49,
            child: Text(
              isDesktop ? 'FIRST GUESS' : 'FG',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Oswald',
                color: Colors.white,
                fontSize: isDesktop ? 11.5 : 9.5,
                letterSpacing: 0.2,
              ),
            ),
          ),
          SizedBox(
            width: isDesktop ? 70 : 43,
            child: Text(
              'CHANGE',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Oswald',
                color: Colors.white,
                fontSize: isDesktop ? 11.5 : 9.5,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerRow(
    _LeaderboardPlayer player,
  ) {
    final bool isDesktop =
        MediaQuery.sizeOf(context).width >= 1200;

    return Container(
      height: isDesktop ? 60 : 50,
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 16 : 10,
      ),
      decoration: BoxDecoration(
        color: player.isCurrentPlayer
            ? const Color(0xFF17110D)
            : _panel,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(
          color: player.isCurrentPlayer ? _orange : _border,
          width: player.isCurrentPlayer ? 1.5 : 1,
        ),
        boxShadow: player.isCurrentPlayer
            ? const [
                BoxShadow(
                  color: Color(0x44FE5E02),
                  blurRadius: 10,
                ),
              ]
            : null,
      ),
      child: Row(
        children: [
          SizedBox(
            width: isDesktop ? 36 : 28,
            child: Text(
              '${player.rank}',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Oswald',
                color: Colors.white,
                fontSize: isDesktop ? 19 : 16,
              ),
            ),
          ),
          SizedBox(width: isDesktop ? 8 : 6),
          _buildSmallAvatar(player),
          SizedBox(width: isDesktop ? 12 : 8),
          Expanded(
            child: isDesktop
                ? Text(
                    player.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16.5,
                      fontWeight: FontWeight.w500,
                    ),
                  )
                : FittedBox(
                    alignment: Alignment.centerLeft,
                    fit: BoxFit.scaleDown,
                    child: Text(
                      player.name,
                      maxLines: 1,
                      softWrap: false,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
          ),
          SizedBox(
            width: isDesktop ? 90 : 61,
            child: Text(
              _formatScore(
                player.score,
              ),
              textAlign: TextAlign.right,
              style: TextStyle(
                fontFamily: 'Oswald',
                color: _gold,
                fontSize: isDesktop ? 18 : 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          SizedBox(
            width: isDesktop ? 100 : 49,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.star_rounded,
                  color: _gold,
                  size: 14,
                ),
                const SizedBox(width: 3),
                Text(
                  '${player.firstGuesses}',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isDesktop ? 14 : 11.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: isDesktop ? 70 : 43,
            child: _buildMovement(
              player.movement,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSmallAvatar(
    _LeaderboardPlayer player,
  ) {
    final bool isDesktop =
        MediaQuery.sizeOf(context).width >= 1200;

    return Container(
      width: isDesktop ? 38 : 32,
      height: isDesktop ? 38 : 32,
      padding: const EdgeInsets.all(1),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: _orange,
          width: 1,
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
    int movement,
  ) {
    final bool isDesktop =
        MediaQuery.sizeOf(context).width >= 1200;

    if (movement > 0) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.arrow_upward_rounded,
            color: _green,
            size: isDesktop ? 22 : 19,
          ),
          const SizedBox(width: 2),
          Text(
            '$movement',
            style: TextStyle(
              color: _green,
              fontSize: isDesktop ? 14 : 11.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      );
    }

    if (movement < 0) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.arrow_downward_rounded,
            color: _red,
            size: isDesktop ? 22 : 19,
          ),
          const SizedBox(width: 2),
          Text(
            '${movement.abs()}',
            style: TextStyle(
              color: _red,
              fontSize: isDesktop ? 14 : 11.5,
              fontWeight: FontWeight.w700,
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
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildPinnedPlayer() {
    final _LeaderboardPlayer? player = _currentPlayer;
    if (player == null) return const SizedBox.shrink();

    final bool isDesktop = MediaQuery.sizeOf(context).width >= 1200;

    return Container(
      height: isDesktop ? 60 : 50,
      padding: EdgeInsets.symmetric(horizontal: isDesktop ? 16 : 10),
      decoration: BoxDecoration(
        color: const Color(0xFF17110D),
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: _orange, width: 1.5),
        boxShadow: const [
          BoxShadow(color: Color(0x44FE5E02), blurRadius: 10),
        ],
      ),
      child: Row(
        children: [
          SizedBox(
            width: isDesktop ? 36 : 28,
            child: Text(
              '${player.rank}',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Oswald',
                color: Colors.white,
                fontSize: isDesktop ? 19 : 16,
              ),
            ),
          ),
          SizedBox(width: isDesktop ? 8 : 6),
          _buildSmallAvatar(player),
          SizedBox(width: isDesktop ? 12 : 8),
          Expanded(
            child: isDesktop
                ? Text(
                    'You: ${player.name}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16.5,
                      fontWeight: FontWeight.w500,
                    ),
                  )
                : FittedBox(
                    alignment: Alignment.centerLeft,
                    fit: BoxFit.scaleDown,
                    child: Text(
                      'You: ${player.name}',
                      maxLines: 1,
                      softWrap: false,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
          ),
          SizedBox(
            width: isDesktop ? 90 : 61,
            child: Text(
              _formatScore(player.score),
              textAlign: TextAlign.right,
              style: TextStyle(
                fontFamily: 'Oswald',
                color: _orange,
                fontSize: isDesktop ? 18 : 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          SizedBox(
            width: isDesktop ? 100 : 49,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.star_rounded, color: _gold, size: isDesktop ? 17 : 14),
                const SizedBox(width: 3),
                Text(
                  '${player.firstGuesses}',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isDesktop ? 14 : 11.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: isDesktop ? 70 : 43,
            child: _buildMovement(player.movement),
          ),
        ],
      ),
    );
  }

  Widget _buildLegend() {
    final bool isDesktop =
        MediaQuery.sizeOf(context).width >= 1200;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 18 : 14,
        vertical: isDesktop ? 16 : 13,
      ),
      decoration: BoxDecoration(
        color: _panel,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _border,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(
                  Icons.star_rounded,
                  color: _gold,
                  size: isDesktop ? 28 : 23,
                ),
                SizedBox(width: isDesktop ? 12 : 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'FIRST GUESS',
                        style: TextStyle(
                          fontFamily: 'Oswald',
                          color: Colors.white,
                          fontSize: isDesktop ? 16 : 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: isDesktop ? 4 : 3),
                      Text(
                        isDesktop
                            ? 'Times answered correctly on the first clue.'
                            : 'Correct on your first guess.',
                        maxLines: isDesktop ? 1 : 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: isDesktop ? 13.5 : 10,
                          height: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 1,
            height: isDesktop ? 64 : 54,
            margin: EdgeInsets.symmetric(
              horizontal: isDesktop ? 18 : 10,
            ),
            color: _border,
          ),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.arrow_upward_rounded,
                      color: _green,
                      size: isDesktop ? 25 : 20,
                    ),
                    Icon(
                      Icons.arrow_downward_rounded,
                      color: _red,
                      size: isDesktop ? 25 : 20,
                    ),
                  ],
                ),
                SizedBox(width: isDesktop ? 11 : 7),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'CHANGE',
                        style: TextStyle(
                          fontFamily: 'Oswald',
                          color: Colors.white,
                          fontSize: isDesktop ? 16 : 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: isDesktop ? 4 : 3),
                      Text(
                        isDesktop
                            ? 'How many leaderboard places the player moved.'
                            : 'Places moved up or down.',
                        maxLines: isDesktop ? 1 : 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: isDesktop ? 13.5 : 10,
                          height: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatScore(int value) {
    final String raw = value.toString();
    final StringBuffer result = StringBuffer();

    for (int i = 0; i < raw.length; i++) {
      final int remaining = raw.length - i;

      result.write(raw[i]);

      if (remaining > 1 &&
          remaining % 3 == 1) {
        result.write(',');
      }
    }

    return result.toString();
  }
}

class _LeaderboardPlayer {
  final String id;
  final int rank;
  final String name;
  final int score;
  final int firstGuesses;
  final int movement;
  final String avatarPath;
  final bool isCurrentPlayer;

  const _LeaderboardPlayer({
    required this.id,
    required this.rank,
    required this.name,
    required this.score,
    required this.firstGuesses,
    required this.movement,
    required this.avatarPath,
    this.isCurrentPlayer = false,
  });

  _LeaderboardPlayer copyWith({
    int? rank,
    int? movement,
    bool? isCurrentPlayer,
  }) {
    return _LeaderboardPlayer(
      id: id,
      rank: rank ?? this.rank,
      name: name,
      score: score,
      firstGuesses: firstGuesses,
      movement: movement ?? this.movement,
      avatarPath: avatarPath,
      isCurrentPlayer: isCurrentPlayer ?? this.isCurrentPlayer,
    );
  }
}

class _GlobalRankSnapshot {
  final Map<String, int> ranks;
  final Map<String, int> movements;

  const _GlobalRankSnapshot({
    this.ranks = const <String, int>{},
    this.movements = const <String, int>{},
  });

  factory _GlobalRankSnapshot.fromData(
    Map<String, dynamic> data,
  ) {
    Map<String, int> intMap(dynamic raw) {
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

    return _GlobalRankSnapshot(
      ranks: intMap(data['ranks']),
      movements: intMap(data['movements']),
    );
  }
}

class _SeededPlayer {
  final String id;
  final String name;
  final String avatarPath;
  final int allTimeScore;
  final int allTimeFirstGuesses;
  final int dailyScore;
  final int dailyFirstGuesses;
  final int monthlyScore;
  final int monthlyFirstGuesses;

  const _SeededPlayer(
    this.id,
    this.name,
    this.avatarPath,
    this.allTimeScore,
    this.allTimeFirstGuesses,
    this.dailyScore,
    this.dailyFirstGuesses,
    this.monthlyScore,
    this.monthlyFirstGuesses,
  );

  _LeaderboardPlayer toLeaderboardPlayer(int periodTab) {
    final int score = switch (periodTab) {
      1 => dailyScore,
      2 => monthlyScore,
      _ => allTimeScore,
    };
    final int firstGuesses = switch (periodTab) {
      1 => dailyFirstGuesses,
      2 => monthlyFirstGuesses,
      _ => allTimeFirstGuesses,
    };

    return _LeaderboardPlayer(
      id: id,
      rank: 0,
      name: name,
      score: score,
      firstGuesses: firstGuesses,
      movement: 0,
      avatarPath: avatarPath,
    );
  }
}
