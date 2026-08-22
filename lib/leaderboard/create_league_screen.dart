import 'package:flutter/material.dart';

import '../widgets/app_home_button.dart';

class CreateLeagueScreen extends StatefulWidget {
  const CreateLeagueScreen({
    super.key,
  });

  @override
  State<CreateLeagueScreen> createState() =>
      _CreateLeagueScreenState();
}

class _CreateLeagueScreenState extends State<CreateLeagueScreen> {
  static const Color _orange = Color(0xFFFE5E02);
  static const Color _background = Color(0xFF050505);
  static const Color _panel = Color(0xFF111111);
  static const Color _panelLight = Color(0xFF181818);
  static const Color _border = Color(0xFF343434);
  static const Color _grey = Color(0xFFAAAAAA);

  final TextEditingController _nameController =
      TextEditingController();

  int _selectedBadgeIndex = 6;
  int _selectedColorIndex = 0;

  static const List<_LeagueBadgeOption> _badges = [
    _LeagueBadgeOption(
      label: 'Book',
      path:
          'assets/images/leaderboard/league_badges/league_book.webp',
    ),
    _LeagueBadgeOption(
      label: 'Brain',
      path:
          'assets/images/leaderboard/league_badges/league_brain.webp',
    ),
    _LeagueBadgeOption(
      label: 'Cat',
      path:
          'assets/images/leaderboard/league_badges/league_cat.webp',
    ),
    _LeagueBadgeOption(
      label: 'Cobra',
      path:
          'assets/images/leaderboard/league_badges/league_cobra.webp',
    ),
    _LeagueBadgeOption(
      label: 'Crown',
      path:
          'assets/images/leaderboard/league_badges/league_crown.webp',
    ),
    _LeagueBadgeOption(
      label: 'Diamond',
      path:
          'assets/images/leaderboard/league_badges/league_diamond.webp',
    ),
    _LeagueBadgeOption(
      label: 'Dog',
      path:
          'assets/images/leaderboard/league_badges/league_dog.webp',
    ),
    _LeagueBadgeOption(
      label: 'Dragon',
      path:
          'assets/images/leaderboard/league_badges/league_dragon.webp',
    ),
    _LeagueBadgeOption(
      label: 'Fox',
      path:
          'assets/images/leaderboard/league_badges/league_fox.webp',
    ),
    _LeagueBadgeOption(
      label: 'Globe',
      path:
          'assets/images/leaderboard/league_badges/league_globe.webp',
    ),
    _LeagueBadgeOption(
      label: 'Knight',
      path:
          'assets/images/leaderboard/league_badges/league_knight.webp',
    ),
    _LeagueBadgeOption(
      label: 'Lightning',
      path:
          'assets/images/leaderboard/league_badges/league_lightning.webp',
    ),
    _LeagueBadgeOption(
      label: 'Lion',
      path:
          'assets/images/leaderboard/league_badges/league_lion.webp',
    ),
    _LeagueBadgeOption(
      label: 'Medal',
      path:
          'assets/images/leaderboard/league_badges/league_medal.webp',
    ),
    _LeagueBadgeOption(
      label: 'Mountain',
      path:
          'assets/images/leaderboard/league_badges/league_mountain.webp',
    ),
    _LeagueBadgeOption(
      label: 'Otter',
      path:
          'assets/images/leaderboard/league_badges/league_otter.webp',
    ),
    _LeagueBadgeOption(
      label: 'Owl',
      path:
          'assets/images/leaderboard/league_badges/league_owl.webp',
    ),
    _LeagueBadgeOption(
      label: 'People',
      path:
          'assets/images/leaderboard/league_badges/league_people.webp',
    ),
    _LeagueBadgeOption(
      label: 'Rocket',
      path:
          'assets/images/leaderboard/league_badges/league_rocket.webp',
    ),
    _LeagueBadgeOption(
      label: 'Shark',
      path:
          'assets/images/leaderboard/league_badges/league_shark.webp',
    ),
    _LeagueBadgeOption(
      label: 'Star',
      path:
          'assets/images/leaderboard/league_badges/league_star.webp',
    ),
    _LeagueBadgeOption(
      label: 'Tiger',
      path:
          'assets/images/leaderboard/league_badges/league_tiger.webp',
    ),
    _LeagueBadgeOption(
      label: 'Trophy',
      path:
          'assets/images/leaderboard/league_badges/league_trophy.webp',
    ),
    _LeagueBadgeOption(
      label: 'Cupcake',
      path:
          'assets/images/leaderboard/league_badges/league_cupcake.webp',
    ),
    _LeagueBadgeOption(
      label: 'Wave',
      path:
          'assets/images/leaderboard/league_badges/league_wave.webp',
    ),
  ];

  static const List<Color> _leagueColors = [
    Color(0xFFFE5E02),
    Color(0xFFFF2D1A),
    Color(0xFFE62E74),
    Color(0xFFA847C7),
    Color(0xFF4F6FD8),
    Color(0xFF14A9C7),
    Color(0xFF62B54A),
    Color(0xFFD6C72E),
    Color(0xFFFFB21A),
  ];

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  String get _leagueName {
    final String value = _nameController.text.trim();

    if (value.isEmpty) {
      return 'Your League Name';
    }

    return value;
  }

  Color get _selectedColor =>
      _leagueColors[_selectedColorIndex];

  _LeagueBadgeOption get _selectedBadge =>
      _badges[_selectedBadgeIndex];


  String _normaliseLeagueNameForModeration(
    String value,
  ) {
    String normalised = value.toLowerCase();

    const Map<String, String> substitutions = {
      '0': 'o',
      '1': 'i',
      '3': 'e',
      '4': 'a',
      '5': 's',
      '7': 't',
      '@': 'a',
      r'$': 's',
    };

    substitutions.forEach((from, to) {
      normalised = normalised.replaceAll(from, to);
    });

    normalised = normalised.replaceAll(
      RegExp(r'[^a-z0-9]+'),
      '',
    );

    normalised = normalised.replaceAllMapped(
      RegExp(r'(.)\1{2,}'),
      (match) => '${match.group(1)}${match.group(1)}',
    );

    return normalised;
  }

  bool _containsBlockedLeagueName(
    String value,
  ) {
    final String normalised =
        _normaliseLeagueNameForModeration(value);

    const List<String> blockedTerms = [
      'fuck',
      'fuk',
      'shit',
      'sh1t',
      'bitch',
      'cunt',
      'dick',
      'cock',
      'pussy',
      'asshole',
      'arsehole',
      'wanker',
      'twat',
      'bastard',
      'slut',
      'whore',
      'nigger',
      'nigga',
      'faggot',
      'retard',
    ];

    return blockedTerms.any(
      normalised.contains,
    );
  }

  bool _validateLeagueName(
    BuildContext context,
    String value,
  ) {
    if (_containsBlockedLeagueName(value)) {
      final ScaffoldMessengerState messenger =
          ScaffoldMessenger.of(context);

      messenger.hideCurrentMaterialBanner();
      messenger.showMaterialBanner(
        MaterialBanner(
          backgroundColor: const Color(0xFF111111),
          elevation: 2,
          padding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 12,
          ),
          content: const Text(
            'Please choose another league name.',
            style: TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          actions: [
            IconButton(
              onPressed: messenger.hideCurrentMaterialBanner,
              icon: const Icon(
                Icons.close_rounded,
                color: Colors.white,
              ),
            ),
          ],
        ),
      );

      Future<void>.delayed(
        const Duration(seconds: 3),
        messenger.hideCurrentMaterialBanner,
      );

      return false;
    }

    return true;
  }

  void _createLeague() {
    final String name = _nameController.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Color(0xFF111111),
          content: Text(
            'Enter a league name first.',
            style: TextStyle(
              color: Colors.white,
            ),
          ),
        ),
      );
      return;
    }

    if (!_validateLeagueName(context, name)) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF111111),
        content: Text(
          '$name is ready to connect to Firebase later.',
          style: const TextStyle(
            color: Colors.white,
          ),
        ),
        duration: const Duration(seconds: 2),
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
                      'Build your league. Invite your people.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildSectionTitle(
                      number: 1,
                      title: 'LEAGUE NAME',
                    ),
                    const SizedBox(height: 10),
                    _buildNameField(),
                    const SizedBox(height: 7),
                    const Text(
                      'Choose a name that represents your league.',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11.5,
                      ),
                    ),
                    const SizedBox(height: 22),
                    _buildSectionDivider(),
                    const SizedBox(height: 18),
                    _buildSectionTitle(
                      number: 2,
                      title: 'CHOOSE A BADGE',
                    ),
                    const SizedBox(height: 12),
                    _buildBadgeGrid(),
                    const SizedBox(height: 9),
                    const Center(
                      child: Text(
                        '25 BADGES TO CHOOSE FROM',
                        style: TextStyle(
                          fontFamily: 'Oswald',
                          color: Colors.white,
                          fontSize: 11.5,
                          letterSpacing: 0.7,
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),
                    _buildSectionDivider(),
                    const SizedBox(height: 18),
                    _buildSectionTitle(
                      number: 3,
                      title: 'CHOOSE A COLOR',
                    ),
                    const SizedBox(height: 13),
                    _buildColorSelector(),
                    const SizedBox(height: 8),
                    const Text(
                      'This color will be used for your league accents.',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11.5,
                      ),
                    ),
                    const SizedBox(height: 22),
                    _buildPreviewPanel(),
                    const SizedBox(height: 18),
                    _buildCreateButton(),
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
              'CREATE LEAGUE',
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

  Widget _buildNameField() {
    return TextField(
      controller: _nameController,
      onChanged: (_) {
        setState(() {});
      },
      maxLength: 28,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 15,
      ),
      decoration: InputDecoration(
        counterText: '',
        hintText: 'Enter league name',
        hintStyle: const TextStyle(
          color: Color(0xFF777777),
        ),
        prefixIcon: Icon(
          Icons.groups_2_rounded,
          color: _selectedColor,
        ),
        filled: true,
        fillColor: _panel,
        contentPadding:
            const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 16,
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
          borderSide: BorderSide(
            color: _selectedColor,
            width: 1.5,
          ),
        ),
      ),
    );
  }

  Widget _buildBadgeGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics:
          const NeverScrollableScrollPhysics(),
      itemCount: _badges.length,
      gridDelegate:
          const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1,
      ),
      itemBuilder: (
        BuildContext context,
        int index,
      ) {
        final bool selected =
            index == _selectedBadgeIndex;

        return Material(
          color: Colors.transparent,
          borderRadius:
              BorderRadius.circular(12),
          child: InkWell(
            onTap: () {
              setState(() {
                _selectedBadgeIndex = index;
              });
            },
            borderRadius:
                BorderRadius.circular(12),
            child: AnimatedContainer(
              duration:
                  const Duration(
                milliseconds: 160,
              ),
              padding:
                  const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: selected
                    ? const Color(0xFF18110D)
                    : _panel,
                borderRadius:
                    BorderRadius.circular(12),
                border: Border.all(
                  color: selected
                      ? _selectedColor
                      : _border,
                  width: selected ? 2 : 1,
                ),
                boxShadow: selected
                    ? [
                        BoxShadow(
                          color: _selectedColor
                              .withValues(
                            alpha: 0.22,
                          ),
                          blurRadius: 8,
                        ),
                      ]
                    : null,
              ),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Image.asset(
                      _badges[index].path,
                      fit: BoxFit.contain,
                      filterQuality:
                          FilterQuality.high,
                    ),
                  ),
                  if (selected)
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Container(
                        width: 19,
                        height: 19,
                        decoration:
                            BoxDecoration(
                          color:
                              _selectedColor,
                          shape:
                              BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check_rounded,
                          color: Colors.white,
                          size: 14,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildColorSelector() {
    return Wrap(
      spacing: 11,
      runSpacing: 11,
      children: List.generate(
        _leagueColors.length,
        (index) {
          final Color color =
              _leagueColors[index];

          final bool selected =
              index == _selectedColorIndex;

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedColorIndex =
                    index;
              });
            },
            child: AnimatedContainer(
              duration:
                  const Duration(
                milliseconds: 150,
              ),
              width: 38,
              height: 38,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected
                      ? Colors.white
                      : Colors.transparent,
                  width: 2,
                ),
              ),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color,
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(
                        alpha: 0.22,
                      ),
                      blurRadius: 7,
                    ),
                  ],
                ),
                child: selected
                    ? const Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: 21,
                      )
                    : null,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPreviewPanel() {
    return Container(
      padding: const EdgeInsets.all(12),
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
            CrossAxisAlignment.start,
        children: [
          const Text(
            'THIS IS HOW YOUR LEAGUE WILL LOOK',
            style: TextStyle(
              fontFamily: 'Oswald',
              color: Colors.white,
              fontSize: 11,
              letterSpacing: 0.55,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
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
                color: _selectedColor,
                width: 1.3,
              ),
              boxShadow: [
                BoxShadow(
                  color:
                      _selectedColor.withValues(
                    alpha: 0.18,
                  ),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 92,
                  height: 92,
                  child: Image.asset(
                    _selectedBadge.path,
                    fit: BoxFit.contain,
                    filterQuality:
                        FilterQuality.high,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        _leagueName,
                        maxLines: 2,
                        overflow:
                            TextOverflow
                                .ellipsis,
                        style:
                            const TextStyle(
                          fontFamily:
                              'Oswald',
                          color:
                              Colors.white,
                          fontSize: 20,
                          fontWeight:
                              FontWeight
                                  .w600,
                        ),
                      ),
                      const SizedBox(
                        height: 7,
                      ),
                      Row(
                        children: [
                          Icon(
                            Icons
                                .people_alt_rounded,
                            color:
                                _selectedColor,
                            size: 17,
                          ),
                          const SizedBox(
                            width: 5,
                          ),
                          const Text(
                            '1 MEMBER',
                            style:
                                TextStyle(
                              fontFamily:
                                  'Oswald',
                              color:
                                  _grey,
                              fontSize:
                                  11.5,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(
                        height: 7,
                      ),
                      Text(
                        'Play. Guess. Win. Together.',
                        style:
                            TextStyle(
                          color:
                              _selectedColor,
                          fontSize: 11.5,
                          fontWeight:
                              FontWeight
                                  .w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons
                      .verified_user_rounded,
                  color: _selectedColor,
                  size: 28,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCreateButton() {
    return SizedBox(
      height: 56,
      child: ElevatedButton.icon(
        onPressed: _createLeague,
        icon: const Icon(
          Icons.person_add_alt_1_rounded,
          size: 22,
        ),
        label: const Text(
          'CREATE LEAGUE',
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor:
              _selectedColor,
          foregroundColor: Colors.white,
          elevation: 5,
          shadowColor:
              _selectedColor.withValues(
            alpha: 0.35,
          ),
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

  Widget _buildSectionDivider() {
    return Container(
      height: 1,
      color: _border,
    );
  }
}

class _LeagueBadgeOption {
  const _LeagueBadgeOption({
    required this.label,
    required this.path,
  });

  final String label;
  final String path;
}
