import 'dart:async';

import 'package:flutter/material.dart';

import 'invite_members_screen.dart';
import 'league_settings_screen.dart';

class LeagueDetailScreen extends StatefulWidget {
  const LeagueDetailScreen({
    super.key,
    required this.leagueName,
    required this.badgePath,
    required this.memberCount,
  });

  final String leagueName;
  final String badgePath;
  final int memberCount;

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

  final List<_LeaguePlayer> _players = const [
    _LeaguePlayer(
      rank: 1,
      name: 'QuizQueen',
      score: 5420,
      firstGuesses: 18,
      movement: 2,
      avatarPath:
          'assets/images/leaderboard/default_profile.webp',
    ),
    _LeaguePlayer(
      rank: 2,
      name: 'ClueMaster',
      score: 4980,
      firstGuesses: 16,
      movement: 1,
      avatarPath:
          'assets/images/leaderboard/default_profile.webp',
    ),
    _LeaguePlayer(
      rank: 3,
      name: 'Brainiac',
      score: 4650,
      firstGuesses: 14,
      movement: -1,
      avatarPath:
          'assets/images/leaderboard/default_profile.webp',
    ),
    _LeaguePlayer(
      rank: 4,
      name: 'WordWizard',
      score: 4210,
      firstGuesses: 13,
      movement: 1,
      avatarPath:
          'assets/images/leaderboard/default_profile.webp',
    ),
    _LeaguePlayer(
      rank: 5,
      name: 'TriviaTitan',
      score: 3870,
      firstGuesses: 11,
      movement: -1,
      avatarPath:
          'assets/images/leaderboard/default_profile.webp',
    ),
    _LeaguePlayer(
      rank: 6,
      name: 'GuessGenius',
      score: 3510,
      firstGuesses: 10,
      movement: 2,
      avatarPath:
          'assets/images/leaderboard/default_profile.webp',
    ),
    _LeaguePlayer(
      rank: 7,
      name: 'YOU',
      score: 3240,
      firstGuesses: 9,
      movement: 1,
      avatarPath:
          'assets/images/leaderboard/default_profile.webp',
      isCurrentPlayer: true,
    ),
    _LeaguePlayer(
      rank: 8,
      name: 'PuzzlePro',
      score: 2980,
      firstGuesses: 8,
      movement: -2,
      avatarPath:
          'assets/images/leaderboard/default_profile.webp',
    ),
  ];

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
    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  14,
                  8,
                  14,
                  28,
                ),
                child: Column(
                  children: [
                    _buildLeagueIdentity(),
                    const SizedBox(height: 16),
                    _buildPeriodTabs(),
                    if (_periodTab != 0) ...[
                      const SizedBox(height: 10),
                      _buildResetCountdown(),
                    ],
                    const SizedBox(height: 18),
                    _buildPodium(),
                    const SizedBox(height: 12),
                    _buildTableHeader(),
                    const SizedBox(height: 6),
                    ..._players.skip(3).map(
                          (player) => Padding(
                            padding:
                                const EdgeInsets.only(
                              bottom: 6,
                            ),
                            child:
                                _buildPlayerRow(
                              player,
                            ),
                          ),
                        ),
                    const SizedBox(height: 12),
                    _buildInviteButton(context),
                    const SizedBox(height: 12),
                    _buildLegend(),
                  ],
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        14,
        14,
        14,
        14,
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
            width: 122,
            height: 122,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(26),
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
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.leagueName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Oswald',
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w600,
                    height: 1,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 5),
                const Text(
                  'LEAGUE',
                  style: TextStyle(
                    fontFamily: 'Oswald',
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 1.4,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(
                      Icons.people_alt_rounded,
                      color: Colors.white,
                      size: 17,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${widget.memberCount} MEMBERS',
                      style: const TextStyle(
                        fontFamily: 'Oswald',
                        color: Colors.white,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Text(
                  'Better clues. Tougher guesses.\nA smarter pack.',
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

  Widget _buildPodium() {
    return SizedBox(
      height: 245,
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.end,
        children: [
          Expanded(
            child: _buildPodiumPlayer(
              _players[1],
              position: 2,
              crownPath:
                  'assets/images/leaderboard/crown_silver.webp',
              height: 214,
              avatarSize: 62,
            ),
          ),
          Expanded(
            child: _buildPodiumPlayer(
              _players[0],
              position: 1,
              crownPath:
                  'assets/images/leaderboard/crown_gold.webp',
              height: 243,
              avatarSize: 76,
            ),
          ),
          Expanded(
            child: _buildPodiumPlayer(
              _players[2],
              position: 3,
              crownPath:
                  'assets/images/leaderboard/crown_bronze.webp',
              height: 208,
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
              player.score,
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
                '${player.firstGuesses}',
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
              '${player.rank}',
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
              _formatScore(
                player.score,
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
                  '${player.firstGuesses}',
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
    int movement,
  ) {
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

  Widget _buildInviteButton(
    BuildContext context,
  ) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (context) {
                return InviteMembersScreen(
                  leagueName: widget.leagueName,
                  badgePath: widget.badgePath,
                  memberCount: widget.memberCount,
                );
              },
            ),
          );
        },
        icon: const Icon(
          Icons.person_add_alt_1_rounded,
          size: 21,
        ),
        label: const Text(
          'INVITE MEMBERS',
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: _orange,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          textStyle: const TextStyle(
            fontFamily: 'Oswald',
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.25,
          ),
        ),
      ),
    );
  }

  Widget _buildLegend() {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: _panel,
        borderRadius:
            BorderRadius.circular(14),
        border: Border.all(
          color: _border,
        ),
      ),
      child: const Text(
        '⭐ First Guess = answered correctly on the first clue   •   ↑↓ Change = leaderboard places moved',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Colors.white,
          fontSize: 10.5,
          height: 1.4,
        ),
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

class _LeaguePlayer {
  const _LeaguePlayer({
    required this.rank,
    required this.name,
    required this.score,
    required this.firstGuesses,
    required this.movement,
    required this.avatarPath,
    this.isCurrentPlayer = false,
  });

  final int rank;
  final String name;
  final int score;
  final int firstGuesses;
  final int movement;
  final String avatarPath;
  final bool isCurrentPlayer;
}
