import 'package:flutter/material.dart';

import '../widgets/app_home_button.dart';

class LeagueSettingsScreen extends StatefulWidget {
  const LeagueSettingsScreen({
    super.key,
    required this.leagueName,
    required this.badgePath,
    required this.memberCount,
  });

  final String leagueName;
  final String badgePath;
  final int memberCount;

  @override
  State<LeagueSettingsScreen> createState() => _LeagueSettingsScreenState();
}

class _LeagueSettingsScreenState extends State<LeagueSettingsScreen> {
  static const Color _orange = Color(0xFFFE5E02);
  static const Color _background = Color(0xFF050505);
  static const Color _panel = Color(0xFF111111);
  static const Color _border = Color(0xFF343434);
  static const Color _red = Color(0xFFFF5145);

  late final TextEditingController _nameController;
  late String _selectedBadgePath;
  int _selectedColorIndex = 0;

  static const List<String> _badges = [
    'assets/images/leaderboard/league_badges/league_book.webp',
    'assets/images/leaderboard/league_badges/league_brain.webp',
    'assets/images/leaderboard/league_badges/league_cat.webp',
    'assets/images/leaderboard/league_badges/league_cobra.webp',
    'assets/images/leaderboard/league_badges/league_crown.webp',
    'assets/images/leaderboard/league_badges/league_diamond.webp',
    'assets/images/leaderboard/league_badges/league_dog.webp',
    'assets/images/leaderboard/league_badges/league_dragon.webp',
    'assets/images/leaderboard/league_badges/league_fox.webp',
    'assets/images/leaderboard/league_badges/league_globe.webp',
    'assets/images/leaderboard/league_badges/league_knight.webp',
    'assets/images/leaderboard/league_badges/league_lightning.webp',
    'assets/images/leaderboard/league_badges/league_lion.webp',
    'assets/images/leaderboard/league_badges/league_medal.webp',
    'assets/images/leaderboard/league_badges/league_mountain.webp',
    'assets/images/leaderboard/league_badges/league_otter.webp',
    'assets/images/leaderboard/league_badges/league_owl.webp',
    'assets/images/leaderboard/league_badges/league_people.webp',
    'assets/images/leaderboard/league_badges/league_rocket.webp',
    'assets/images/leaderboard/league_badges/league_shark.webp',
    'assets/images/leaderboard/league_badges/league_star.webp',
    'assets/images/leaderboard/league_badges/league_tiger.webp',
    'assets/images/leaderboard/league_badges/league_trophy.webp',
    'assets/images/leaderboard/league_badges/league_cupcake.webp',
    'assets/images/leaderboard/league_badges/league_wave.webp',
  ];

  static const List<Color> _colors = [
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
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.leagueName);
    _selectedBadgePath = widget.badgePath;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Color get _selectedColor => _colors[_selectedColorIndex];

  void _showTemporaryMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF111111),
        content: Text(
          message,
          style: const TextStyle(
            color: Colors.white,
          ),
        ),
        duration: const Duration(seconds: 1),
      ),
    );
  }


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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Color(0xFF111111),
          content: Text(
            'Please choose another league name.',
            style: TextStyle(
              color: Colors.white,
            ),
          ),
        ),
      );
      return false;
    }

    return true;
  }

  void _saveChanges() {
    final String name = _nameController.text.trim();

    if (name.isEmpty) {
      _showTemporaryMessage('League name cannot be empty.');
      return;
    }

    if (!_validateLeagueName(context, name)) {
      return;
    }

    _showTemporaryMessage(
      'League settings are ready to save when Firebase is connected.',
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
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildLeagueSummary(),
                    const SizedBox(height: 22),
                    _buildSectionTitle('LEAGUE NAME'),
                    const SizedBox(height: 10),
                    _buildNameField(),
                    const SizedBox(height: 22),
                    _buildSectionTitle('LEAGUE BADGE'),
                    const SizedBox(height: 10),
                    _buildBadgeGrid(),
                    const SizedBox(height: 22),
                    _buildSectionTitle('LEAGUE COLOR'),
                    const SizedBox(height: 12),
                    _buildColorSelector(),
                    const SizedBox(height: 22),
                    _buildSectionTitle('MEMBERS'),
                    const SizedBox(height: 10),
                    _buildMembersCard(),
                    const SizedBox(height: 22),
                    _buildSaveButton(),
                    const SizedBox(height: 26),
                    _buildDangerZone(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 4),
      child: Row(
        children: [
          SizedBox(
            width: 44,
            height: 44,
            child: IconButton(
              padding: EdgeInsets.zero,
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Colors.white,
                size: 23,
              ),
            ),
          ),
          const Expanded(
            child: Text(
              'LEAGUE SETTINGS',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Oswald',
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const FirstGuessHomeButton(),
        ],
      ),
    );
  }

  Widget _buildLeagueSummary() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _panel,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 86,
            height: 86,
            child: Image.asset(
              _selectedBadgePath,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _nameController.text.trim().isEmpty
                      ? 'Your League'
                      : _nameController.text.trim(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Oswald',
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 7),
                Row(
                  children: [
                    Icon(Icons.people_alt_rounded, color: _selectedColor, size: 17),
                    const SizedBox(width: 5),
                    Text(
                      '${widget.memberCount} MEMBERS',
                      style: const TextStyle(
                        fontFamily: 'Oswald',
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Icon(Icons.settings_rounded, color: _selectedColor, size: 28),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontFamily: 'Oswald',
        color: Colors.white,
        fontSize: 18,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.3,
      ),
    );
  }

  Widget _buildNameField() {
    return TextField(
      controller: _nameController,
      maxLength: 28,
      onChanged: (_) => setState(() {}),
      style: const TextStyle(color: Colors.white, fontSize: 15),
      decoration: InputDecoration(
        counterText: '',
        filled: true,
        fillColor: _panel,
        prefixIcon: Icon(Icons.edit_rounded, color: _selectedColor),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: _selectedColor, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildBadgeGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _badges.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemBuilder: (context, index) {
        final bool selected = _badges[index] == _selectedBadgePath;
        return GestureDetector(
          onTap: () => setState(() => _selectedBadgePath = _badges[index]),
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: _panel,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selected ? _selectedColor : _border,
                width: selected ? 2 : 1,
              ),
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  child: Image.asset(
                    _badges[index],
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.high,
                  ),
                ),
                if (selected)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      width: 19,
                      height: 19,
                      decoration: BoxDecoration(
                        color: _selectedColor,
                        shape: BoxShape.circle,
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
        );
      },
    );
  }

  Widget _buildColorSelector() {
    return Wrap(
      spacing: 11,
      runSpacing: 11,
      children: List.generate(_colors.length, (index) {
        final bool selected = index == _selectedColorIndex;
        return GestureDetector(
          onTap: () => setState(() => _selectedColorIndex = index),
          child: Container(
            width: 38,
            height: 38,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: selected ? Colors.white : Colors.transparent,
                width: 2,
              ),
            ),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _colors[index],
              ),
              child: selected
                  ? const Icon(Icons.check_rounded, color: Colors.white, size: 21)
                  : null,
            ),
          ),
        );
      }),
    );
  }

  Widget _buildMembersCard() {
    return Container(
      decoration: BoxDecoration(
        color: _panel,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.people_alt_rounded, color: _orange),
            title: Text(
              '${widget.memberCount} league members',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: const Text(
              'View members and manage your league roster.',
              style: TextStyle(color: Colors.white, fontSize: 11.5),
            ),
            trailing: const Icon(Icons.chevron_right_rounded, color: _orange),
            onTap: () => _showTemporaryMessage(
              'Member management will use real league members later.',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      height: 54,
      child: ElevatedButton.icon(
        onPressed: _saveChanges,
        icon: const Icon(Icons.save_rounded),
        label: const Text('SAVE CHANGES'),
        style: ElevatedButton.styleFrom(
          backgroundColor: _selectedColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(17),
          ),
          textStyle: const TextStyle(
            fontFamily: 'Oswald',
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildDangerZone() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF130B0B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF572424)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'LEAGUE CONTROLS',
            style: TextStyle(
              fontFamily: 'Oswald',
              color: _red,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 11),
          OutlinedButton.icon(
            onPressed: () => _showTemporaryMessage(
              'Leave League will be enabled with real membership data.',
            ),
            icon: const Icon(Icons.logout_rounded),
            label: const Text('LEAVE LEAGUE'),
            style: OutlinedButton.styleFrom(
              foregroundColor: _red,
              side: const BorderSide(color: _red),
            ),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => _showTemporaryMessage(
              'Delete League will be available to the league owner.',
            ),
            icon: const Icon(Icons.delete_outline_rounded),
            label: const Text('DELETE LEAGUE'),
            style: OutlinedButton.styleFrom(
              foregroundColor: _red,
              side: const BorderSide(color: _red),
            ),
          ),
        ],
      ),
    );
  }
}
