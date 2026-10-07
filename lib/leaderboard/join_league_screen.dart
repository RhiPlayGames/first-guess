import 'package:flutter/material.dart';

import '../services/league_service.dart';
import '../widgets/app_home_button.dart';

class JoinLeagueScreen extends StatefulWidget {
  const JoinLeagueScreen({
    super.key,
  });

  @override
  State<JoinLeagueScreen> createState() =>
      _JoinLeagueScreenState();
}

class _JoinLeagueScreenState extends State<JoinLeagueScreen> {
  static const Color _orange = Color(0xFFFE5E02);
  static const Color _background = Color(0xFF050505);
  static const Color _panel = Color(0xFF111111);
  static const Color _panelLight = Color(0xFF181818);
  static const Color _border = Color(0xFF343434);

  final TextEditingController _codeController =
      TextEditingController();

  bool _showPreview = false;
  bool _isFindingLeague = false;
  bool _isJoiningLeague = false;
  LeagueRecord? _foundLeague;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _findLeague() async {
    if (_isFindingLeague || _isJoiningLeague) {
      return;
    }

    final String code = _codeController.text.trim();

    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Color(0xFF111111),
          content: Text(
            'Enter an invite code first.',
            style: TextStyle(
              color: Colors.white,
            ),
          ),
        ),
      );
      return;
    }

    setState(() {
      _isFindingLeague = true;
      _showPreview = false;
      _foundLeague = null;
    });

    try {
      final LeagueRecord? league =
          await LeagueService.findLeagueByInviteCode(code);

      if (!mounted) {
        return;
      }

      if (league == null) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(
              backgroundColor: Color(0xFF111111),
              content: Text(
                'No league was found for that invite code.',
                style: TextStyle(
                  color: Colors.white,
                ),
              ),
            ),
          );

        return;
      }

      setState(() {
        _foundLeague = league;
        _showPreview = true;
      });
    } on LeagueServiceException catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF111111),
            content: Text(
              error.message,
              style: const TextStyle(
                color: Colors.white,
              ),
            ),
          ),
        );
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            backgroundColor: Color(0xFF111111),
            content: Text(
              'The league could not be found. Please try again.',
              style: TextStyle(
                color: Colors.white,
              ),
            ),
          ),
        );
    } finally {
      if (mounted) {
        setState(() {
          _isFindingLeague = false;
        });
      }
    }
  }

  Future<void> _joinLeague() async {
    if (_isJoiningLeague || _isFindingLeague) {
      return;
    }

    final LeagueRecord? league = _foundLeague;

    if (league == null) {
      return;
    }

    setState(() {
      _isJoiningLeague = true;
    });

    try {
      final LeagueRecord joinedLeague =
          await LeagueService.joinLeagueByInviteCode(
        league.inviteCode,
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF111111),
            content: Text(
              'You joined ${joinedLeague.name}.',
              style: const TextStyle(
                color: Colors.white,
              ),
            ),
            duration: const Duration(seconds: 2),
          ),
        );

      Navigator.of(context).pop(true);
    } on LeagueServiceException catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF111111),
            content: Text(
              error.message,
              style: const TextStyle(
                color: Colors.white,
              ),
            ),
          ),
        );
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            backgroundColor: Color(0xFF111111),
            content: Text(
              'The league could not be joined. Please try again.',
              style: TextStyle(
                color: Colors.white,
              ),
            ),
          ),
        );
    } finally {
      if (mounted) {
        setState(() {
          _isJoiningLeague = false;
        });
      }
    }
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
                  isDesktop ? 24 : 16,
                  8,
                  isDesktop ? 24 : 16,
                  28,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth:
                          isDesktop ? 720 : double.infinity,
                    ),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.stretch,
                      children: [
                    const Text(
                      'Enter an invite code to find a private league.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 22),
                    _buildSectionTitle(
                      number: 1,
                      title: 'ENTER INVITE CODE',
                    ),
                    const SizedBox(height: 10),
                    _buildCodeField(),
                    const SizedBox(height: 12),
                    _buildFindButton(),
                    const SizedBox(height: 24),
                    if (_showPreview) ...[
                      _buildDivider(),
                      const SizedBox(height: 20),
                      _buildSectionTitle(
                        number: 2,
                        title: 'LEAGUE FOUND',
                      ),
                      const SizedBox(height: 12),
                      _buildLeaguePreview(),
                      const SizedBox(height: 18),
                      _buildJoinButton(),
                    ] else
                      _buildHelpPanel(),
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
        10,
        8,
        10,
        4,
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
                size: 23,
              ),
            ),
          ),
          const Expanded(
            child: Text(
              'JOIN LEAGUE',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Oswald',
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.4,
              ),
            ),
          ),
          const FirstGuessHomeButton(),
        ],
      ),
    );
  }

  Widget _buildSectionTitle({
    required int number,
    required String title,
  }) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: _orange,
            shape: BoxShape.circle,
          ),
          child: Text(
            '$number',
            style: const TextStyle(
              fontFamily: 'Oswald',
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 9),
        Text(
          title,
          style: const TextStyle(
            fontFamily: 'Oswald',
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }

  Widget _buildCodeField() {
    return TextField(
      controller: _codeController,
      textCapitalization:
          TextCapitalization.characters,
      onChanged: (_) {
        if (_showPreview || _foundLeague != null) {
          setState(() {
            _showPreview = false;
            _foundLeague = null;
          });
        }
      },
      style: const TextStyle(
        color: Colors.white,
        fontSize: 18,
        letterSpacing: 2,
        fontWeight: FontWeight.w700,
      ),
      decoration: InputDecoration(
        hintText: 'e.g. AB12CD34',
        hintStyle: const TextStyle(
          color: Color(0xFF777777),
          letterSpacing: 1,
          fontWeight: FontWeight.w500,
        ),
        prefixIcon: const Icon(
          Icons.key_rounded,
          color: _orange,
        ),
        filled: true,
        fillColor: _panel,
        contentPadding:
            const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 17,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: _border,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: _orange,
            width: 1.5,
          ),
        ),
      ),
    );
  }

  Widget _buildFindButton() {
    return SizedBox(
      height: 52,
      child: OutlinedButton.icon(
        onPressed: _isFindingLeague || _isJoiningLeague
            ? null
            : _findLeague,
        icon: _isFindingLeague
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.1,
                  color: Colors.white,
                ),
              )
            : const Icon(
                Icons.search_rounded,
              ),
        label: Text(
          _isFindingLeague ? 'FINDING LEAGUE...' : 'FIND LEAGUE',
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          side: const BorderSide(
            color: _orange,
            width: 1.5,
          ),
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontFamily: 'Oswald',
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
      ),
    );
  }

  Widget _buildLeaguePreview() {
    final LeagueRecord league = _foundLeague!;
    final Color leagueColor = Color(league.accentColorValue);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _panelLight,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: _border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(
              12,
              12,
              12,
              12,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFF0A0A0A),
              borderRadius: BorderRadius.circular(
                14,
              ),
              border: Border.all(
                color: leagueColor,
                width: 1.3,
              ),
              boxShadow: [
                BoxShadow(
                  color: leagueColor.withValues(
                    alpha: 0.18,
                  ),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 96,
                  height: 96,
                  child: Image.asset(
                    league.badgePath,
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.high,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        league.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Oswald',
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'LEAGUE',
                        style: TextStyle(
                          fontFamily: 'Oswald',
                          color: Colors.white,
                          fontSize: 13,
                          letterSpacing: 1.1,
                        ),
                      ),
                      const SizedBox(height: 9),
                      Row(
                        children: [
                          Icon(
                            Icons.people_alt_rounded,
                            color: leagueColor,
                            size: 17,
                          ),
                          const SizedBox(
                            width: 5,
                          ),
                          Text(
                            '${league.memberCount} ${league.memberCount == 1 ? 'MEMBER' : 'MEMBERS'}',
                            style: const TextStyle(
                              fontFamily: 'Oswald',
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Play. Guess. Win. Together.',
                        style: TextStyle(
                          color: leagueColor,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Row(
            children: [
              Icon(
                Icons.lock_rounded,
                color: Colors.white,
                size: 17,
              ),
              SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Private league • Invitation required',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11.5,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildJoinButton() {
    final LeagueRecord league = _foundLeague!;
    final Color leagueColor = Color(league.accentColorValue);

    return SizedBox(
      height: 56,
      child: ElevatedButton.icon(
        onPressed: _isJoiningLeague || _isFindingLeague
            ? null
            : _joinLeague,
        icon: _isJoiningLeague
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  color: Colors.white,
                ),
              )
            : const Icon(
                Icons.group_add_rounded,
                size: 22,
              ),
        label: Text(
          _isJoiningLeague
              ? 'JOINING LEAGUE...'
              : 'JOIN ${league.name.toUpperCase()}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: leagueColor,
          foregroundColor: Colors.white,
          disabledBackgroundColor: leagueColor.withValues(
            alpha: 0.55,
          ),
          disabledForegroundColor: Colors.white,
          elevation: 5,
          shadowColor: leagueColor.withValues(
            alpha: 0.35,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          textStyle: const TextStyle(
            fontFamily: 'Oswald',
            fontSize: 17,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.35,
          ),
        ),
      ),
    );
  }

  Widget _buildHelpPanel() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 14,
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
              'Ask the league owner for their invite code. Invite links will be supported in a later update.',
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

  Widget _buildDivider() {
    return Container(
      height: 1,
      color: _border,
    );
  }
}
