import 'package:flutter/material.dart';

import 'create_league_screen.dart';
import 'join_league_screen.dart';
import 'league_detail_screen.dart';

class MyLeaguesScreen extends StatelessWidget {
  const MyLeaguesScreen({
    super.key,
    required this.onGlobalPressed,
  });

  final VoidCallback onGlobalPressed;

  static const Color _orange = Color(0xFFFE5E02);
  static const Color _panel = Color(0xFF111111);
  static const Color _panelLight = Color(0xFF181818);
  static const Color _border = Color(0xFF343434);
  static const Color _gold = Color(0xFFFFB21A);

  static const List<_LeagueData> _leagues = [
    _LeagueData(
      name: 'Scrappy',
      members: 12,
      rank: 3,
      badgePath:
          'assets/images/leaderboard/league_badges/league_dog.webp',
    ),
    _LeagueData(
      name: 'Shitten',
      members: 8,
      rank: 1,
      badgePath:
          'assets/images/leaderboard/league_badges/league_cat.webp',
    ),
    _LeagueData(
      name: 'Tatty',
      members: 15,
      rank: 7,
      badgePath:
          'assets/images/leaderboard/league_badges/league_otter.webp',
    ),
  ];

  void _openLeague(
    BuildContext context,
    _LeagueData league,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) {
          return LeagueDetailScreen(
            leagueName: league.name,
            badgePath: league.badgePath,
            memberCount: league.members,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        14,
        8,
        14,
        28,
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.stretch,
        children: [
          _buildMainTabs(),
          const SizedBox(height: 22),
          _buildIntro(),
          const SizedBox(height: 22),
          ..._leagues.map(
            (league) => Padding(
              padding: const EdgeInsets.only(
                bottom: 12,
              ),
              child: _buildLeagueCard(
                context,
                league,
              ),
            ),
          ),
          const SizedBox(height: 8),
          _buildActions(context),
          const SizedBox(height: 18),
          _buildInfoPanel(),
        ],
      ),
    );
  }

  Widget _buildMainTabs() {
    return Container(
      height: 54,
      decoration: BoxDecoration(
        color: _panel,
        borderRadius:
            BorderRadius.circular(16),
        border: Border.all(
          color: _border,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onGlobalPressed,
                borderRadius:
                    BorderRadius.circular(
                  15,
                ),
                child: Row(
                  mainAxisAlignment:
                      MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/images/leaderboard/global.webp',
                      width: 32,
                      height: 32,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(
                      width: 8,
                    ),
                    const Text(
                      'GLOBAL',
                      style: TextStyle(
                        fontFamily: 'Oswald',
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight:
                            FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: _border,
          ),
          Expanded(
            child: Container(
              height: double.infinity,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius:
                    BorderRadius.circular(
                  15,
                ),
                border: Border.all(
                  color: _orange,
                  width: 1.5,
                ),
                boxShadow: const [
                  BoxShadow(
                    color:
                        Color(0x33FE5E02),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment:
                    MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/images/leaderboard/my_leagues.webp',
                    width: 32,
                    height: 32,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(
                    width: 8,
                  ),
                  const Text(
                    'MY LEAGUES',
                    style: TextStyle(
                      fontFamily: 'Oswald',
                      color:
                          Colors.white,
                      fontSize: 16,
                      fontWeight:
                          FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIntro() {
    return Column(
      children: [
        Image.asset(
          'assets/images/leaderboard/my_leagues.webp',
          width: 92,
          height: 92,
          fit: BoxFit.contain,
        ),
        const SizedBox(height: 8),
        const Text(
          'Compete with friends, family and your favourite rivals.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontSize: 13,
            height: 1.35,
          ),
        ),
      ],
    );
  }

  Widget _buildLeagueCard(
    BuildContext context,
    _LeagueData league,
  ) {
    return Material(
      color: Colors.transparent,
      borderRadius:
          BorderRadius.circular(18),
      child: InkWell(
        onTap: () {
          _openLeague(
            context,
            league,
          );
        },
        borderRadius:
            BorderRadius.circular(18),
        child: Container(
          constraints:
              const BoxConstraints(
            minHeight: 118,
          ),
          padding:
              const EdgeInsets.fromLTRB(
            14,
            12,
            12,
            12,
          ),
          decoration: BoxDecoration(
            color: _panelLight,
            borderRadius:
                BorderRadius.circular(
              18,
            ),
            border: Border.all(
              color: _border,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 88,
                height: 88,
                padding:
                    const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius:
                      BorderRadius.circular(
                    20,
                  ),
                  border: Border.all(
                    color: _orange,
                    width: 1.2,
                  ),
                ),
                child: Image.asset(
                  league.badgePath,
                  fit: BoxFit.contain,
                  filterQuality:
                      FilterQuality.high,
                ),
              ),
              const SizedBox(
                width: 14,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  mainAxisAlignment:
                      MainAxisAlignment.center,
                  children: [
                    Text(
                      league.name,
                      maxLines: 1,
                      overflow:
                          TextOverflow.ellipsis,
                      style:
                          const TextStyle(
                        fontFamily:
                            'Oswald',
                        color:
                            Colors.white,
                        fontSize: 21,
                        fontWeight:
                            FontWeight.w500,
                      ),
                    ),
                    const SizedBox(
                      height: 7,
                    ),
                    Row(
                      children: [
                        const Icon(
                          Icons.people_alt_rounded,
                          color: Colors.white,
                          size: 16,
                        ),
                        const SizedBox(
                          width: 5,
                        ),
                        Text(
                          '${league.members} MEMBERS',
                          style:
                              const TextStyle(
                            fontFamily:
                                'Oswald',
                            color:
                                Colors.white,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(
                      height: 6,
                    ),
                    Row(
                      children: [
                        const Icon(
                          Icons.emoji_events_rounded,
                          color: _gold,
                          size: 17,
                        ),
                        const SizedBox(
                          width: 5,
                        ),
                        const Text(
                          'YOUR RANK',
                          style: TextStyle(
                            fontFamily:
                                'Oswald',
                            color:
                                Colors.white,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(
                          width: 6,
                        ),
                        Text(
                          '#${league.rank}',
                          style:
                              const TextStyle(
                            fontFamily:
                                'Oswald',
                            color:
                                _orange,
                            fontSize: 19,
                            fontWeight:
                                FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActions(
    BuildContext context,
  ) {
    return SizedBox(
      width: double.infinity,
      height: 58,
      child: ElevatedButton.icon(
        onPressed: () {
          showModalBottomSheet<void>(
            context: context,
            backgroundColor:
                const Color(0xFF111111),
            shape:
                const RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.vertical(
                top: Radius.circular(22),
              ),
            ),
            builder: (sheetContext) {
              return SafeArea(
                child: Padding(
                  padding:
                      const EdgeInsets.fromLTRB(
                    18,
                    18,
                    18,
                    22,
                  ),
                  child: Column(
                    mainAxisSize:
                        MainAxisSize.min,
                    crossAxisAlignment:
                        CrossAxisAlignment
                            .stretch,
                    children: [
                      const Text(
                        'CREATE OR JOIN A LEAGUE',
                        textAlign:
                            TextAlign.center,
                        style: TextStyle(
                          fontFamily:
                              'Oswald',
                          color:
                              Colors.white,
                          fontSize: 22,
                          fontWeight:
                              FontWeight.w600,
                        ),
                      ),
                      const SizedBox(
                        height: 16,
                      ),
                      SizedBox(
                        height: 54,
                        child:
                            ElevatedButton.icon(
                          onPressed: () {
                            Navigator.of(
                              sheetContext,
                            ).pop();

                            Navigator.of(
                              context,
                            ).push(
                              MaterialPageRoute<
                                  void>(
                                builder:
                                    (context) {
                                  return const CreateLeagueScreen();
                                },
                              ),
                            );
                          },
                          icon: const Icon(
                            Icons.add_rounded,
                          ),
                          label: const Text(
                            'CREATE LEAGUE',
                          ),
                          style:
                              ElevatedButton
                                  .styleFrom(
                            backgroundColor:
                                _orange,
                            foregroundColor:
                                Colors.white,
                            shape:
                                RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(
                                16,
                              ),
                            ),
                            textStyle:
                                const TextStyle(
                              fontFamily:
                                  'Oswald',
                              fontSize: 17,
                              fontWeight:
                                  FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      SizedBox(
                        height: 54,
                        child:
                            OutlinedButton.icon(
                          onPressed: () {
                            Navigator.of(
                              sheetContext,
                            ).pop();

                            Navigator.of(
                              context,
                            ).push(
                              MaterialPageRoute<
                                  void>(
                                builder:
                                    (context) {
                                  return const JoinLeagueScreen();
                                },
                              ),
                            );
                          },
                          icon: const Icon(
                            Icons.group_add_rounded,
                          ),
                          label: const Text(
                            'JOIN A LEAGUE',
                          ),
                          style:
                              OutlinedButton
                                  .styleFrom(
                            foregroundColor:
                                Colors.white,
                            side:
                                const BorderSide(
                              color: _orange,
                              width: 1.5,
                            ),
                            shape:
                                RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(
                                16,
                              ),
                            ),
                            textStyle:
                                const TextStyle(
                              fontFamily:
                                  'Oswald',
                              fontSize: 17,
                              fontWeight:
                                  FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
        icon: const Icon(
          Icons.person_add_alt_1_rounded,
          size: 23,
        ),
        label: const Text(
          'CREATE OR JOIN A LEAGUE',
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: _orange,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(18),
          ),
          textStyle: const TextStyle(
            fontFamily: 'Oswald',
            fontSize: 18,
            fontWeight:
                FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
      ),
    );
  }

  Widget _buildInfoPanel() {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 13,
      ),
      decoration: BoxDecoration(
        color: _panel,
        borderRadius:
            BorderRadius.circular(15),
        border: Border.all(
          color: _border,
        ),
      ),
      child: const Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline_rounded,
            color: _orange,
            size: 21,
          ),
          SizedBox(width: 9),
          Expanded(
            child: Text(
              'Open a league to see its All Time, Daily and Monthly leaderboard.',
              style: TextStyle(
                color: Colors.white,
                fontSize: 11.5,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LeagueData {
  const _LeagueData({
    required this.name,
    required this.members,
    required this.rank,
    required this.badgePath,
  });

  final String name;
  final int members;
  final int rank;
  final String badgePath;
}
