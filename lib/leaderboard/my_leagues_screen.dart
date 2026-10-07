import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../services/league_service.dart';
import 'create_league_screen.dart';
import 'join_league_screen.dart';
import 'league_detail_screen.dart';

class MyLeaguesScreen extends StatefulWidget {
  const MyLeaguesScreen({
    super.key,
    required this.onGlobalPressed,
  });

  final VoidCallback onGlobalPressed;

  @override
  State<MyLeaguesScreen> createState() => _MyLeaguesScreenState();
}

class _MyLeaguesScreenState extends State<MyLeaguesScreen> {
  static const Color _orange = Color(0xFFFE5E02);
  static const Color _panel = Color(0xFF111111);
  static const Color _panelLight = Color(0xFF181818);
  static const Color _border = Color(0xFF343434);
  static const Color _gold = Color(0xFFFFB21A);

  List<LeagueRecord> _leagues = <LeagueRecord>[];
  bool _isLoading = true;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _loadLeagues();
  }

  Future<void> _loadLeagues() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _loadError = null;
      });
    }

    try {
      final List<LeagueRecord> leagues = await LeagueService.loadMyLeagues();

      if (!mounted) {
        return;
      }

      setState(() {
        _leagues = leagues;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _loadError = 'Your leagues could not be loaded. Pull to refresh or try again.';
        _isLoading = false;
      });
    }
  }

  void _openLeague(
    BuildContext context,
    LeagueRecord league,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) {
          return LeagueDetailScreen(
            leagueName: league.name,
            badgePath: league.badgePath,
            memberCount: league.memberCount,
            inviteCode: league.inviteCode,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDesktop =
        MediaQuery.sizeOf(context).width >= 1200;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        isDesktop ? 24 : 14,
        8,
        isDesktop ? 24 : 14,
        28,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: isDesktop ? 1280 : double.infinity,
          ),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.stretch,
            children: [
              _buildMainTabs(),
              SizedBox(height: isDesktop ? 12 : 22),
              _buildIntro(context),
              SizedBox(height: isDesktop ? 14 : 22),
              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 28),
                  child: Center(
                    child: CircularProgressIndicator(
                      color: _orange,
                    ),
                  ),
                )
              else if (_loadError != null)
                _buildLoadError()
              else if (_leagues.isEmpty)
                _buildEmptyState()
              else if (isDesktop)
                Wrap(
                  spacing: 14,
                  runSpacing: 14,
                  children: [
                    for (final LeagueRecord league in _leagues)
                      SizedBox(
                        width: 390,
                        child: _buildLeagueCard(
                          context,
                          league,
                        ),
                      ),
                  ],
                )
              else
                ..._leagues.map(
                  (LeagueRecord league) => Padding(
                    padding: const EdgeInsets.only(
                      bottom: 12,
                    ),
                    child: _buildLeagueCard(
                      context,
                      league,
                    ),
                  ),
                ),
              SizedBox(height: isDesktop ? 14 : 8),
              _buildActions(context),
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
                onTap: widget.onGlobalPressed,
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

  Widget _buildIntro(
    BuildContext context,
  ) {
    final bool isDesktop =
        MediaQuery.sizeOf(context).width >= 1200;

    return Column(
      children: [
        Image.asset(
          'assets/images/leaderboard/my_leagues.webp',
          width: isDesktop ? 72 : 92,
          height: isDesktop ? 72 : 92,
          fit: BoxFit.contain,
        ),
        const SizedBox(height: 8),
        const Text(
          'Compete with friends, family and your favourite rivals.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
            height: 1.35,
          ),
        ),
      ],
    );
  }

  Widget _buildLeagueCard(
    BuildContext context,
    LeagueRecord league,
  ) {
    final bool isDesktop =
        MediaQuery.sizeOf(context).width >= 1200;

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
              BoxConstraints(
            minHeight: isDesktop ? 104 : 118,
          ),
          padding:
              EdgeInsets.fromLTRB(
            isDesktop ? 12 : 14,
            isDesktop ? 10 : 12,
            isDesktop ? 10 : 12,
            isDesktop ? 10 : 12,
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
                width: isDesktop ? 72 : 88,
                height: isDesktop ? 72 : 88,
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
                          TextStyle(
                        fontFamily:
                            'Oswald',
                        color:
                            Colors.white,
                        fontSize: isDesktop ? 19 : 21,
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
                          '${league.memberCount} ${league.memberCount == 1 ? 'MEMBER' : 'MEMBERS'}',
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
                    const Row(
                      children: [
                        Icon(
                          Icons.emoji_events_rounded,
                          color: _gold,
                          size: 17,
                        ),
                        SizedBox(
                          width: 5,
                        ),
                        Text(
                          'YOUR RANK',
                          style: TextStyle(
                            fontFamily: 'Oswald',
                            color: Colors.white,
                            fontSize: 13,
                          ),
                        ),
                        SizedBox(
                          width: 6,
                        ),
                        Text(
                          '—',
                          style: TextStyle(
                            fontFamily: 'Oswald',
                            color: _orange,
                            fontSize: 19,
                            fontWeight: FontWeight.w600,
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

  Widget _buildEmptyState() {
    return Center(
      child: Container(
        width: kIsWeb ? 760 : double.infinity,
        alignment: Alignment.center,
        padding: const EdgeInsets.fromLTRB(18, 22, 18, 22),
        decoration: BoxDecoration(
          color: _panelLight,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: _border,
          ),
        ),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'NO LEAGUES YET',
              style: TextStyle(
                fontFamily: 'Oswald',
                color: Colors.white,
                fontSize: 19,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 5),
            Text(
              'Create a league or join one with an invite code.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 17,
                height: 1.35,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadError() {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      decoration: BoxDecoration(
        color: _panelLight,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: _border,
        ),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: _orange,
            size: 34,
          ),
          const SizedBox(height: 8),
          Text(
            _loadError ?? 'Your leagues could not be loaded.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12.5,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _loadLeagues,
            icon: const Icon(Icons.refresh_rounded),
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

  Widget _buildActions(
    BuildContext context,
  ) {
    final bool isDesktop =
        MediaQuery.sizeOf(context).width >= 1200;

    return Align(
      alignment: Alignment.center,
      child: SizedBox(
        width: isDesktop ? 420 : double.infinity,
        height: 56,
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
                            )
                                .push<bool>(
                              MaterialPageRoute<bool>(
                                builder: (context) {
                                  return const CreateLeagueScreen();
                                },
                              ),
                            )
                                .then((bool? created) {
                              if (created == true) {
                                _loadLeagues();
                              }
                            });
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
                            )
                                .push<void>(
                              MaterialPageRoute<void>(
                                builder: (context) {
                                  return const JoinLeagueScreen();
                                },
                              ),
                            )
                                .then((_) {
                              _loadLeagues();
                            });
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
      ),
    );
  }



}
