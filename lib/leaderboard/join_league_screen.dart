import 'package:flutter/material.dart';

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

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  void _findLeague() {
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
      _showPreview = true;
    });
  }

  void _joinLeague() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: Color(0xFF111111),
        content: Text(
          'Join League is ready to connect to Firebase later.',
          style: TextStyle(
            color: Colors.white,
          ),
        ),
        duration: Duration(seconds: 2),
      ),
    );
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
                  16,
                  8,
                  16,
                  28,
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
        if (_showPreview) {
          setState(() {
            _showPreview = false;
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
        hintText: 'e.g. SCRAPPY24',
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
        onPressed: _findLeague,
        icon: const Icon(
          Icons.search_rounded,
        ),
        label: const Text(
          'FIND LEAGUE',
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _panelLight,
        borderRadius:
            BorderRadius.circular(18),
        border: Border.all(
          color: _border,
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.stretch,
        children: [
          Container(
            padding:
                const EdgeInsets.fromLTRB(
              12,
              12,
              12,
              12,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFF0A0A0A),
              borderRadius:
                  BorderRadius.circular(
                14,
              ),
              border: Border.all(
                color: _orange,
                width: 1.3,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x2BFE5E02),
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
                    'assets/images/leaderboard/league_badges/league_dog.webp',
                    fit: BoxFit.contain,
                    filterQuality:
                        FilterQuality.high,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Scrappy',
                        style: TextStyle(
                          fontFamily:
                              'Oswald',
                          color:
                              Colors.white,
                          fontSize: 22,
                          fontWeight:
                              FontWeight
                                  .w600,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'LEAGUE',
                        style: TextStyle(
                          fontFamily:
                              'Oswald',
                          color: Colors.white,
                          fontSize: 13,
                          letterSpacing:
                              1.1,
                        ),
                      ),
                      SizedBox(height: 9),
                      Row(
                        children: [
                          Icon(
                            Icons
                                .people_alt_rounded,
                            color:
                                _orange,
                            size: 17,
                          ),
                          SizedBox(
                            width: 5,
                          ),
                          Text(
                            '12 MEMBERS',
                            style:
                                TextStyle(
                              fontFamily:
                                  'Oswald',
                              color:
                                  Colors.white,
                              fontSize:
                                  12,
                              fontWeight:
                                  FontWeight
                                      .w500,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Play. Guess. Win. Together.',
                        style:
                            TextStyle(
                          color: _orange,
                          fontSize: 11.5,
                          fontWeight:
                              FontWeight
                                  .w600,
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
    return SizedBox(
      height: 56,
      child: ElevatedButton.icon(
        onPressed: _joinLeague,
        icon: const Icon(
          Icons.group_add_rounded,
          size: 22,
        ),
        label: const Text(
          'JOIN SCRAPPY',
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: _orange,
          foregroundColor: Colors.white,
          elevation: 5,
          shadowColor:
              const Color(0x55FE5E02),
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(18),
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
              'Ask the league owner for their invite code. Invite links will also be supported when Firebase is connected.',
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
