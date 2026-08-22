import 'dart:async';

import 'package:flutter/material.dart';

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

  final List<_LeaderboardPlayer> _players = const [
    _LeaderboardPlayer(
      rank: 1,
      name: 'QuizQueen',
      score: 15230,
      firstGuesses: 24,
      movement: 2,
      avatarPath: 'assets/images/leaderboard/default_profile.webp',
    ),
    _LeaderboardPlayer(
      rank: 2,
      name: 'ClueMaster',
      score: 12450,
      firstGuesses: 18,
      movement: 1,
      avatarPath: 'assets/images/leaderboard/default_profile.webp',
    ),
    _LeaderboardPlayer(
      rank: 3,
      name: 'Brainiac',
      score: 11200,
      firstGuesses: 17,
      movement: -1,
      avatarPath: 'assets/images/leaderboard/default_profile.webp',
    ),
    _LeaderboardPlayer(
      rank: 4,
      name: 'WordWizard',
      score: 9850,
      firstGuesses: 16,
      movement: 2,
      avatarPath: 'assets/images/leaderboard/default_profile.webp',
    ),
    _LeaderboardPlayer(
      rank: 5,
      name: 'TriviaTitan',
      score: 8920,
      firstGuesses: 14,
      movement: -1,
      avatarPath: 'assets/images/leaderboard/default_profile.webp',
    ),
    _LeaderboardPlayer(
      rank: 6,
      name: 'GuessGenius',
      score: 8410,
      firstGuesses: 13,
      movement: 3,
      avatarPath: 'assets/images/leaderboard/default_profile.webp',
    ),
    _LeaderboardPlayer(
      rank: 7,
      name: 'LogicLion',
      score: 7620,
      firstGuesses: 12,
      movement: 1,
      avatarPath: 'assets/images/leaderboard/default_profile.webp',
    ),
    _LeaderboardPlayer(
      rank: 8,
      name: 'PuzzlePro',
      score: 6980,
      firstGuesses: 10,
      movement: -2,
      avatarPath: 'assets/images/leaderboard/default_profile.webp',
    ),
    _LeaderboardPlayer(
      rank: 9,
      name: 'MindMap',
      score: 6250,
      firstGuesses: 9,
      movement: 0,
      avatarPath: 'assets/images/leaderboard/default_profile.webp',
    ),
    _LeaderboardPlayer(
      rank: 10,
      name: 'FactFinder',
      score: 5830,
      firstGuesses: 8,
      movement: 1,
      avatarPath: 'assets/images/leaderboard/default_profile.webp',
    ),
  ];

  final _LeaderboardPlayer _currentPlayer = const _LeaderboardPlayer(
    rank: 27,
    name: 'YOU',
    score: 3420,
    firstGuesses: 5,
    movement: 4,
    isCurrentPlayer: true,
    avatarPath: 'assets/images/leaderboard/default_profile.webp',
  );

  @override
  void initState() {
    super.initState();

    _updateCountdown();

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
      _timeUntilReset = resetTime.difference(now);
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
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        14,
        8,
        14,
        26,
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
          const SizedBox(height: 14),
          _buildPodium(),
          const SizedBox(height: 10),
          _buildTableHeader(),
          const SizedBox(height: 6),
          ..._players.skip(3).map(
                (player) => Padding(
                  padding: const EdgeInsets.only(
                    bottom: 6,
                  ),
                  child: _buildPlayerRow(player),
                ),
              ),
          const SizedBox(height: 8),
          _buildPinnedPlayer(),
          const SizedBox(height: 12),
          _buildLegend(),
        ],
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
                fontSize: 16,
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
    return SizedBox(
      height: 252,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: _buildPodiumPlayer(
              _players[1],
              position: 2,
              crownPath:
                  'assets/images/leaderboard/crown_silver.webp',
              height: 220,
              avatarSize: 62,
            ),
          ),
          Expanded(
            child: _buildPodiumPlayer(
              _players[0],
              position: 1,
              crownPath:
                  'assets/images/leaderboard/crown_gold.webp',
              height: 250,
              avatarSize: 76,
            ),
          ),
          Expanded(
            child: _buildPodiumPlayer(
              _players[2],
              position: 3,
              crownPath:
                  'assets/images/leaderboard/crown_bronze.webp',
              height: 214,
              avatarSize: 60,
            ),
          ),
        ],
      ),
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
    return const Padding(
      padding: EdgeInsets.symmetric(
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
                letterSpacing: 0.5,
              ),
            ),
          ),
          SizedBox(
            width: 68,
            child: Text(
              'SCORE',
              textAlign: TextAlign.right,
              style: TextStyle(
                fontFamily: 'Oswald',
                color: Colors.white,
                fontSize: 10.5,
                letterSpacing: 0.5,
              ),
            ),
          ),
          SizedBox(
            width: 78,
            child: Text(
              'FIRST GUESS',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Oswald',
                color: Colors.white,
                fontSize: 9.5,
                letterSpacing: 0.2,
              ),
            ),
          ),
          SizedBox(
            width: 50,
            child: Text(
              'CHANGE',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Oswald',
                color: Colors.white,
                fontSize: 9.5,
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
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
      ),
      decoration: BoxDecoration(
        color: _panel,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(
          color: _border,
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Text(
              '${player.rank}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Oswald',
                color: Colors.white,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(width: 6),
          _buildSmallAvatar(player),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              player.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          SizedBox(
            width: 68,
            child: Text(
              _formatScore(
                player.score,
              ),
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontFamily: 'Oswald',
                color: _gold,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          SizedBox(
            width: 78,
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
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
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
    _LeaderboardPlayer player,
  ) {
    return Container(
      width: 32,
      height: 32,
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
    if (movement > 0) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
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
    return Container(
      constraints: const BoxConstraints(
        minHeight: 62,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: 11,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: const Color(
          0xFF17110D,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _orange,
          width: 1.5,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x44FE5E02),
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: _orange,
              borderRadius: BorderRadius.circular(
                7,
              ),
            ),
            child: const Text(
              'YOU',
              style: TextStyle(
                fontFamily: 'Oswald',
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 9),
          _buildSmallAvatar(
            _currentPlayer,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              '#${_currentPlayer.rank} You',
              style: const TextStyle(
                fontFamily: 'Oswald',
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          SizedBox(
            width: 68,
            child: Text(
              _formatScore(
                _currentPlayer.score,
              ),
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontFamily: 'Oswald',
                color: _orange,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          SizedBox(
            width: 78,
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
                  '${_currentPlayer.firstGuesses}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 50,
            child: _buildMovement(
              _currentPlayer.movement,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegend() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 13,
      ),
      decoration: BoxDecoration(
        color: _panel,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _border,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.star_rounded,
                  color: _gold,
                  size: 23,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'FIRST GUESS',
                        style: TextStyle(
                          fontFamily: 'Oswald',
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(
                        height: 3,
                      ),
                      Text(
                        'Times answered correctly on the first clue.',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10.5,
                          height: 1.3,
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
            height: 58,
            margin: const EdgeInsets.symmetric(
              horizontal: 10,
            ),
            color: _border,
          ),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.arrow_upward_rounded,
                      color: _green,
                      size: 20,
                    ),
                    Icon(
                      Icons.arrow_downward_rounded,
                      color: _red,
                      size: 20,
                    ),
                  ],
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'CHANGE',
                        style: TextStyle(
                          fontFamily: 'Oswald',
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(
                        height: 3,
                      ),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'How many leaderboard\nplaces the player moved.',
                          maxLines: 2,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10.5,
                            height: 1.3,
                          ),
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
  final int rank;
  final String name;
  final int score;
  final int firstGuesses;
  final int movement;
  final String avatarPath;
  final bool isCurrentPlayer;

  const _LeaderboardPlayer({
    required this.rank,
    required this.name,
    required this.score,
    required this.firstGuesses,
    required this.movement,
    required this.avatarPath,
    this.isCurrentPlayer = false,
  });
}
