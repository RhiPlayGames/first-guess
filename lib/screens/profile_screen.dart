import 'package:flutter/material.dart';

import '../services/avatar_preferences_service.dart';
import '../services/feature_flag_service.dart';
import '../services/player_profile_service.dart';
import '../services/player_stats_service.dart';
import '../theme/app_colors.dart';
import '../widgets/app_home_button.dart';
import '../leaderboard/leaderboard_screen.dart';
import 'achievements_screen.dart';
import 'badges_screen.dart';
import 'avatar_picker_screen.dart';


class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileHubState();
}

class _ProfileHubState extends State<ProfileScreen> {
  final TextEditingController _playerNameController = TextEditingController();

  String? _selectedAvatarPath;
  bool _isPlayerNameLoading = true;
  bool _isPlayerNameSaving = false;
  String? _playerNameStatus;
  bool _playerNameStatusIsError = false;

  @override
  void initState() {
    super.initState();
    _loadPlayerName();
    _loadSelectedAvatar();
  }

  @override
  void dispose() {
    _playerNameController.dispose();
    super.dispose();
  }

  Future<void> _loadPlayerName() async {
    final String? displayName = await PlayerProfileService.loadDisplayName();

    if (!mounted) {
      return;
    }

    _playerNameController.text = displayName ?? '';

    setState(() {
      _isPlayerNameLoading = false;
    });
  }

  Future<void> _loadSelectedAvatar() async {
    final String? selectedAvatarPath =
        await AvatarPreferencesService.loadSelectedAvatarPath();

    if (!mounted) {
      return;
    }

    setState(() {
      _selectedAvatarPath = selectedAvatarPath;
    });
  }

  Future<void> _savePlayerName() async {
    if (_isPlayerNameSaving) {
      return;
    }

    setState(() {
      _isPlayerNameSaving = true;
      _playerNameStatus = null;
      _playerNameStatusIsError = false;
    });

    try {
      await PlayerProfileService.saveDisplayName(
        _playerNameController.text,
      );

      if (!mounted) {
        return;
      }

      FocusScope.of(context).unfocus();

      setState(() {
        _playerNameStatus = 'Your player name has been saved.';
        _playerNameStatusIsError = false;
      });
    } on PlayerProfileException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _playerNameStatus = error.message;
        _playerNameStatusIsError = true;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isPlayerNameSaving = false;
        });
      }
    }
  }

  Future<void> _changeAvatar() async {
    final String? selectedAvatarPath =
        await Navigator.of(context).push<String>(
      MaterialPageRoute<String>(
        builder: (context) => const AvatarPickerScreen(),
      ),
    );

    if (!mounted || selectedAvatarPath == null) {
      return;
    }

    await AvatarPreferencesService.saveSelectedAvatarPath(
      selectedAvatarPath,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _selectedAvatarPath = selectedAvatarPath;
    });
  }

  Widget _buildPlayerNamePanel() {
    final bool isDesktop =
        MediaQuery.sizeOf(context).width >= 1200;

    final Widget playerNameField = TextField(
      controller: _playerNameController,
      enabled: !_isPlayerNameLoading && !_isPlayerNameSaving,
      maxLength: 20,
      textInputAction: TextInputAction.done,
      onChanged: (_) {
        if (_playerNameStatus != null) {
          setState(() {
            _playerNameStatus = null;
            _playerNameStatusIsError = false;
          });
        }
      },
      onSubmitted: (_) {
        _savePlayerName();
      },
      style: const TextStyle(
        fontFamily: 'Inter',
        color: AppColors.white,
        fontSize: 15,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        counterText: '',
        hintText: _isPlayerNameLoading
            ? 'Loading player name...'
            : 'Enter player name',
        hintStyle: TextStyle(
          fontFamily: 'Inter',
          color: AppColors.white,
          fontSize: isDesktop ? 16 : 14,
          fontWeight: FontWeight.w500,
        ),
        filled: true,
        fillColor: AppColors.background,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: AppColors.orange.withValues(alpha: 0.75),
            width: 1.2,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: AppColors.orange,
            width: 1.6,
          ),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: AppColors.border.withValues(alpha: 0.8),
            width: 1.0,
          ),
        ),
      ),
    );

    final Widget saveButton = SizedBox(
      width: double.infinity,
      height: 46,
      child: ElevatedButton.icon(
        onPressed: _isPlayerNameLoading || _isPlayerNameSaving
            ? null
            : _savePlayerName,
        icon: _isPlayerNameSaving
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.white,
                ),
              )
            : const Icon(
                Icons.save_rounded,
                size: 19,
              ),
        label: Text(
          _isPlayerNameSaving ? 'SAVING...' : 'SAVE PLAYER NAME',
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.orange,
          foregroundColor: AppColors.white,
          disabledBackgroundColor:
              AppColors.orange.withValues(alpha: 0.45),
          disabledForegroundColor:
              AppColors.white.withValues(alpha: 0.8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
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

    final Widget? statusMessage = _playerNameStatus == null
        ? null
        : Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                _playerNameStatusIsError
                    ? Icons.error_outline_rounded
                    : Icons.check_circle_outline_rounded,
                color: _playerNameStatusIsError
                    ? const Color(0xFFFF6B5E)
                    : const Color(0xFF63D67A),
                size: 18,
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  _playerNameStatus!,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    color: _playerNameStatusIsError
                        ? const Color(0xFFFF6B5E)
                        : const Color(0xFF63D67A),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    height: 1.25,
                  ),
                ),
              ),
            ],
          );

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: isDesktop ? 1000 : double.infinity,
        ),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.fromLTRB(
            isDesktop ? 22 : 16,
            isDesktop ? 18 : 14,
            isDesktop ? 22 : 16,
            isDesktop ? 18 : 14,
          ),
          decoration: BoxDecoration(
            color: AppColors.panel,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: AppColors.border,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'PLAYER NAME',
                style: TextStyle(
                  fontFamily: 'Oswald',
                  color: AppColors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.35,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                'Your name will be visible in leagues and leaderboards.',
                style: TextStyle(
                  fontFamily: 'Inter',
                  color: AppColors.white,
                  fontSize: isDesktop ? 15 : 12.5,
                  fontWeight: FontWeight.w500,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 12),
              if (isDesktop) ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: playerNameField),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 220,
                      child: saveButton,
                    ),
                  ],
                ),
                if (statusMessage != null) ...[
                  const SizedBox(height: 8),
                  statusMessage,
                ],
              ] else ...[
                playerNameField,
                if (statusMessage != null) ...[
                  const SizedBox(height: 8),
                  statusMessage,
                ],
                const SizedBox(height: 10),
                saveButton,
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _openStats() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => const StatsDetailScreen(),
      ),
    );
  }

  void _openBadges() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => const BadgesScreen(),
      ),
    );
  }

  void _openAchievements() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => const AchievementsScreen(),
      ),
    );
  }

  void _openLeaderboard() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => const LeaderboardScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String avatarPath = _selectedAvatarPath ??
        'assets/images/avatars/Final/optimized/default_avatar.webp';
    final bool isDesktop =
        MediaQuery.sizeOf(context).width >= 1200;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.white,
        elevation: 0,
        toolbarHeight: isDesktop ? 72 : 82,
        title: Padding(
          padding: EdgeInsets.only(top: isDesktop ? 6 : 14),
          child: const Text(
            'MY PROFILE',
            style: TextStyle(
              fontFamily: 'Oswald',
              fontWeight: FontWeight.w600,
              fontSize: 24,
              letterSpacing: 0.6,
            ),
          ),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: EdgeInsets.only(
              right: 26,
              top: isDesktop ? 6 : 14,
            ),
            child: const Align(
              alignment: Alignment.topRight,
              child: FirstGuessHomeButton(),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(
            isDesktop ? 28 : 18,
            isDesktop ? 4 : 12,
            isDesktop ? 28 : 18,
            32,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: isDesktop ? 1080 : double.infinity,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: SizedBox(
                      width: isDesktop ? 104 : 126,
                      height: isDesktop ? 104 : 126,
                      child: Image.asset(
                        avatarPath,
                        fit: BoxFit.contain,
                        filterQuality: FilterQuality.high,
                      ),
                    ),
                  ),
                  SizedBox(height: isDesktop ? 6 : 10),
                  Center(
                    child: SizedBox(
                      width: isDesktop ? 220 : 240,
                      child: Material(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(16),
                        child: InkWell(
                          onTap: _changeAvatar,
                          borderRadius: BorderRadius.circular(16),
                          child: Ink(
                            height: isDesktop ? 46 : 50,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFE5E02),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'CHANGE AVATAR',
                                  style: TextStyle(
                                    fontFamily: 'Oswald',
                                    color: AppColors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                                SizedBox(width: 9),
                                Icon(
                                  Icons.chevron_right_rounded,
                                  color: AppColors.white,
                                  size: 25,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: isDesktop ? 18 : 14),
                  _buildPlayerNamePanel(),
                  SizedBox(height: isDesktop ? 20 : 22),
                  if (isDesktop) ...[
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 142,
                            child: _ProfileHubActionCard(
                              imagePath:
                                  'assets/images/stats/my_stats/highest_score.webp',
                              title: 'MY STATS',
                              subtitle:
                                  'View your progress and performance',
                              onTap: _openStats,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: SizedBox(
                            height: 142,
                            child: _ProfileHubActionCard(
                              imagePath:
                                  'assets/images/badges/final/clue/clue_starter.webp',
                              title: 'BADGES',
                              subtitle:
                                  'View your collection and earned badges',
                              onTap: _openBadges,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 142,
                            child: _ProfileHubActionCard(
                              imagePath:
                                  'assets/images/stats/my_stats/achievements.webp',
                              title: 'ACHIEVEMENTS',
                              subtitle:
                                  'View all your game achievements',
                              onTap: _openAchievements,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: SizedBox(
                            height: 142,
                            child: _ProfileHubActionCard(
                              imagePath:
                                  'assets/images/stats/my_stats/games_played.webp',
                              title: 'LEADERBOARD',
                              subtitle:
                                  'See how you rank against other players',
                              onTap: _openLeaderboard,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    _ProfileHubActionCard(
                      imagePath:
                          'assets/images/stats/my_stats/highest_score.webp',
                      title: 'MY STATS',
                      subtitle: 'View your progress and performance',
                      onTap: _openStats,
                    ),
                    const SizedBox(height: 12),
                    _ProfileHubActionCard(
                      imagePath:
                          'assets/images/badges/final/clue/clue_starter.webp',
                      title: 'BADGES',
                      subtitle: 'View your badges',
                      onTap: _openBadges,
                    ),
                    const SizedBox(height: 12),
                    _ProfileHubActionCard(
                      imagePath:
                          'assets/images/stats/my_stats/achievements.webp',
                      title: 'ACHIEVEMENTS',
                      subtitle: 'View all your game achievements',
                      onTap: _openAchievements,
                    ),
                    const SizedBox(height: 12),
                    _ProfileHubActionCard(
                      imagePath:
                          'assets/images/stats/my_stats/games_played.webp',
                      title: 'LEADERBOARD',
                      subtitle:
                          'See how you rank against other players',
                      onTap: _openLeaderboard,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileHubActionCard extends StatelessWidget {
  const _ProfileHubActionCard({
    required this.imagePath,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final String imagePath;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bool isDesktop =
        MediaQuery.sizeOf(context).width >= 1200;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          padding: EdgeInsets.symmetric(
            horizontal: isDesktop ? 22 : 14,
            vertical: isDesktop ? 18 : 13,
          ),
          decoration: BoxDecoration(
            color: AppColors.panel,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: AppColors.orange,
              width: 1.3,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: isDesktop ? 76 : 58,
                height: isDesktop ? 76 : 58,
                padding: EdgeInsets.all(isDesktop ? 6 : 4),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(
                    isDesktop ? 18 : 15,
                  ),
                  border: Border.all(
                    color: AppColors.orange,
                    width: 1.1,
                  ),
                ),
                child: Image.asset(
                  imagePath,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.high,
                ),
              ),
              SizedBox(width: isDesktop ? 20 : 14),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Oswald',
                        color: AppColors.white,
                        fontSize: isDesktop ? 23 : 19,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.35,
                      ),
                    ),
                    SizedBox(height: isDesktop ? 7 : 3),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        color: AppColors.white,
                        fontSize: isDesktop ? 14 : 13,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: isDesktop ? 16 : 10),
              Icon(
                Icons.chevron_right_rounded,
                color: AppColors.orange,
                size: isDesktop ? 34 : 29,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _StatsGameMode {
  all,
  classic,
  firstConnection,
  firstDate,
  firstMatch,
  firstOrder,
  firstWord,
}

const List<_StatsGameMode> _baseVisibleStatsGameModes = <_StatsGameMode>[
  _StatsGameMode.all,
  _StatsGameMode.classic,
  _StatsGameMode.firstDate,
  _StatsGameMode.firstMatch,
  _StatsGameMode.firstOrder,
  _StatsGameMode.firstWord,
];

class StatsDetailScreen extends StatefulWidget {
  const StatsDetailScreen({super.key});

  @override
  State<StatsDetailScreen> createState() => _StatsDetailScreenState();
}

class _StatsDetailScreenState extends State<StatsDetailScreen> {
  PlayerStats _stats = const PlayerStats();
  Map<String, int> _dailyFlashGameCompletions = <String, int>{};
  Map<String, int> _dailyFlashGamePerfect5s = <String, int>{};
  Map<String, int> _categoryPlayedCounts = <String, int>{};
  Map<_StatsGameMode, int> _gamePlayedCounts =
      <_StatsGameMode, int>{};
  _StatsGameMode _selectedStatsGame = _StatsGameMode.all;
  bool _isLoading = true;
  bool _firstConnectionEnabled = false;

  List<_StatsGameMode> get _visibleStatsGameModes => <_StatsGameMode>[
        ..._baseVisibleStatsGameModes,
        if (_firstConnectionEnabled) _StatsGameMode.firstConnection,
      ];

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final List<dynamic> initialResults =
        await Future.wait<dynamic>(<Future<dynamic>>[
      PlayerStatsService.loadStats(),
      FeatureFlagService.isFirstConnectionEnabled(),
    ]);

    final PlayerStats savedStats = initialResults[0] as PlayerStats;
    final bool firstConnectionEnabled = initialResults[1] as bool;

    final Map<String, int> dailyFlashGameCompletions =
        await DailyFlashMilestoneService.loadGameCompletions();

    final Map<String, int> dailyFlashGamePerfect5s =
        await DailyFlashMilestoneService.loadGamePerfect5s();

    final Set<String> playedQuestionIds =
        await QuestionHistoryService.loadPlayedQuestionIds();

    final Map<String, int> categoryPlayedCounts =
        _buildCategoryPlayedCounts(playedQuestionIds);

    final Map<_StatsGameMode, int> gamePlayedCounts =
        _buildGamePlayedCounts(
      playedQuestionIds,
      firstConnectionEnabled: firstConnectionEnabled,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _stats = savedStats;
      _dailyFlashGameCompletions = dailyFlashGameCompletions;
      _dailyFlashGamePerfect5s = dailyFlashGamePerfect5s;
      _categoryPlayedCounts = categoryPlayedCounts;
      _gamePlayedCounts = gamePlayedCounts;
      _firstConnectionEnabled = firstConnectionEnabled;
      _isLoading = false;
    });
  }

  Map<String, int> _buildCategoryPlayedCounts(
    Set<String> playedQuestionIds,
  ) {
    final Map<String, int> counts = <String, int>{
      'Animals': 0,
      'Books & Authors': 0,
      'Countries': 0,
      'Creative World': 0,
      'Famous Words': 0,
      'Food & Drink': 0,
      'Music': 0,
      'Past & Present': 0,
      'Science & Nature': 0,
      'Sports': 0,
      'Watch & Play': 0,
      'Who Am I?': 0,
    };

    for (final String rawId in playedQuestionIds) {
      final String id = rawId.toLowerCase().trim();
      final String? category = _mainCategoryForQuestionId(id);

      if (category != null) {
        counts[category] = (counts[category] ?? 0) + 1;
      }
    }

    return counts;
  }

  Map<_StatsGameMode, int> _buildGamePlayedCounts(
    Set<String> playedQuestionIds, {
    required bool firstConnectionEnabled,
  }) {
    final Map<_StatsGameMode, int> counts = <_StatsGameMode, int>{
      for (final _StatsGameMode mode in _StatsGameMode.values) mode: 0,
    };

    for (final String rawId in playedQuestionIds) {
      final String id = rawId.toLowerCase().trim();
      final _StatsGameMode? mode = _gameModeForQuestionId(id);

      if (mode != null) {
        counts[mode] = (counts[mode] ?? 0) + 1;
      }
    }

    final List<_StatsGameMode> visibleModes = <_StatsGameMode>[
      ..._baseVisibleStatsGameModes,
      if (firstConnectionEnabled) _StatsGameMode.firstConnection,
    ];

    counts[_StatsGameMode.all] = visibleModes
        .where((_StatsGameMode mode) => mode != _StatsGameMode.all)
        .fold<int>(
          0,
          (int total, _StatsGameMode mode) => total + (counts[mode] ?? 0),
        );

    return counts;
  }

  _StatsGameMode? _gameModeForQuestionId(String id) {
    if (id.startsWith('first_connection_')) {
      return _StatsGameMode.firstConnection;
    }
    if (id.startsWith('first_date_')) {
      return _StatsGameMode.firstDate;
    }
    if (id.startsWith('first_match_')) {
      return _StatsGameMode.firstMatch;
    }
    if (id.startsWith('first_order_')) {
      return _StatsGameMode.firstOrder;
    }
    if (id.startsWith('first_word_')) {
      return _StatsGameMode.firstWord;
    }

    if (_mainCategoryForQuestionId(id) != null) {
      return _StatsGameMode.classic;
    }

    return null;
  }

  String? _mainCategoryForQuestionId(String id) {
    if (_startsWithAny(id, const <String>[
      'animals_',
      'birds_',
      'dinosaurs_',
      'habitats_animal_groups_',
      'insects_spiders_',
      'jungle_safari_animals_',
      'safari_jungle_animals_',
      'mammals_',
      'reptiles_amphibians_',
      'sea_creatures_',
      'tracks_footprints_',
    ])) {
      return 'Animals';
    }

    if (_startsWithAny(id, const <String>[
      'books_authors_',
      'authors_',
    ])) {
      return 'Books & Authors';
    }

    if (_startsWithAny(id, const <String>[
      'countries_',
      'country_',
    ])) {
      return 'Countries';
    }

    if (id.startsWith('creative_world_')) {
      return 'Creative World';
    }

    if (id.startsWith('famous_words_')) {
      return 'Famous Words';
    }

    if (id.startsWith('food_drink_')) {
      return 'Food & Drink';
    }

    if (id.startsWith('music_')) {
      return 'Music';
    }

    if (id.startsWith('past_present_')) {
      return 'Past & Present';
    }

    if (_startsWithAny(id, const <String>[
      'science_nature_',
      'plants_trees_',
      'periodic_table_',
      'human_body_',
      'space_missions_',
      'space_astronomy_',
      'medicine_health_',
      'computers_internet_',
      'inventions_technology_',
      'chemistry_physics_biology_maths_',
      'rocks_minerals_volcanoes_',
      'scientific_discoveries_experiments_theories_',
      'weather_oceans_ecosystems_',
    ])) {
      return 'Science & Nature';
    }

    if (id.startsWith('sports_')) {
      return 'Sports';
    }

    if (id.startsWith('watch_play_')) {
      return 'Watch & Play';
    }

    if (_startsWithAny(id, const <String>[
      'who_am_i_',
      'famous_people_',
    ])) {
      return 'Who Am I?';
    }

    return null;
  }

  bool _startsWithAny(String value, List<String> prefixes) {
    return prefixes.any(value.startsWith);
  }

  PlayerRankProgress get _rankProgress {
    return PlayerRankProgress.fromXp(
      _stats.totalXp,
    );
  }

  String _rankImagePath(PlayerRankProgress rank) {
    switch (rank.tierName) {
      case 'Starter Tier':
        return 'assets/images/badges/clue_starter.webp';
      case 'Advanced Tier':
        return 'assets/images/badges/clue_advanced.webp';
      case 'Expert Tier':
        return 'assets/images/badges/clue_expert.webp';
      case 'Master Tier':
        return 'assets/images/badges/clue_master.webp';
      case 'Elite Tier':
        return 'assets/images/badges/clue_elite.webp';
    }

    return 'assets/images/badges/clue_starter.webp';
  }

  String get _topCorrectCategory {
    return _topCategoryName(
      _stats.categoryCorrectCounts,
    );
  }

  String get _topFirstGuessCategory {
    return _topCategoryName(
      _stats.categoryFirstGuessCounts,
    );
  }

  String _topCategoryName(Map<String, int> totals) {
    const Map<String, String> labels = <String, String>{
      'animals': 'Animals',
      'books_authors': 'Books & Authors',
      'countries': 'Countries',
      'creative_world': 'Creative World',
      'famous_words': 'Famous Words',
      'food_drink': 'Food & Drink',
      'music': 'Music',
      'past_present': 'Past & Present',
      'science_nature': 'Science & Nature',
      'sports': 'Sports',
      'watch_play': 'Watch & Play',
      'famous_people': 'Who Am I?',
    };

    String bestName = '—';
    int bestTotal = 0;

    for (final MapEntry<String, String> entry in labels.entries) {
      final int total = totals[entry.key] ?? 0;
      if (total > bestTotal) {
        bestName = entry.value;
        bestTotal = total;
      }
    }

    return bestName;
  }

  String _formatNumber(int value) {
    final String digits = value.abs().toString();
    final StringBuffer buffer = StringBuffer();

    for (int index = 0; index < digits.length; index++) {
      if (index > 0 &&
          (digits.length - index) % 3 == 0) {
        buffer.write(',');
      }

      buffer.write(digits[index]);
    }

    return value < 0
        ? '-${buffer.toString()}'
        : buffer.toString();
  }


  @override
  Widget build(BuildContext context) {
    final double screenWidth =
        MediaQuery.sizeOf(context).width;
    final bool isDesktop = screenWidth >= 1200;
    final double horizontalPadding = isDesktop
        ? ((screenWidth - 1100) / 2).clamp(24.0, double.infinity)
        : 18.0;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.white,
        elevation: 0,
        toolbarHeight: 82,
        title: const Padding(
          padding: EdgeInsets.only(top: 14),
          child: Text(
            'MY STATS',
            style: TextStyle(
              fontFamily: 'Oswald',
              fontWeight: FontWeight.w500,
              letterSpacing: 0.6,
            ),
          ),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(
              right: 26,
              top: 14,
            ),
            child: Align(
              alignment: Alignment.topRight,
              child: FirstGuessHomeButton(),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  color: AppColors.orange,
                ),
              )
            : RefreshIndicator(
                color: AppColors.orange,
                backgroundColor: AppColors.panel,
                onRefresh: _loadStats,
                child: SingleChildScrollView(
                  physics:
                      const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    12,
                    horizontalPadding,
                    32,
                  ),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.stretch,
                    children: [
                      _buildLevelCard(),
                      const SizedBox(height: 20),
                      _buildMainStats(),
                      const SizedBox(height: 20),
                      _buildGameStatsSection(),
                      if (_selectedStatsGame == _StatsGameMode.classic) ...[
                        const SizedBox(height: 20),
                        _buildCategorySection(),
                      ],
                      if (_selectedStatsGame == _StatsGameMode.classic) ...[
                        const SizedBox(height: 16),
                        _buildCaseFilesSection(),
                      ],
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildLevelCard() {
    final PlayerRankProgress rank = _rankProgress;

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      decoration: BoxDecoration(
        color: AppColors.panel,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: AppColors.orange,
          width: 1.7,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.orange,
                width: 1.2,
              ),
            ),
            child: Transform.scale(
              scale: 1.48,
              child: Image.asset(
                _rankImagePath(rank),
                fit: BoxFit.contain,
                filterQuality: FilterQuality.high,
                errorBuilder: (
                  BuildContext context,
                  Object error,
                  StackTrace? stackTrace,
                ) {
                  return Center(
                    child: Text(
                      rank.roleEmoji,
                      style: const TextStyle(fontSize: 36),
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  rank.fullTitle.toUpperCase(),
                  maxLines: 2,
                  style: const TextStyle(
                    fontFamily: 'Oswald',
                    color: AppColors.white,
                    fontSize: 23,
                    fontWeight: FontWeight.w600,
                    height: 1.05,
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'LEVEL ${rank.level} OF ${PlayerRankProgress.maximumLevel}',
                  style: const TextStyle(
                    fontFamily: 'Oswald',
                    color: AppColors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  rank.isMaximumLevel
                      ? 'MAXIMUM RANK'
                      : '${_formatNumber(rank.xpNeededForNextLevel)} XP TO NEXT LEVEL',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    color: AppColors.orange,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildMainStats() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _CenteredSectionTitle(
          title: 'LIFETIME STATS',
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (
            BuildContext context,
            BoxConstraints constraints,
          ) {
            final bool isDesktop = constraints.maxWidth >= 900;

            final List<Widget> stats = <Widget>[
              _ProfileStatCard(
                imagePath: 'assets/images/stats/stat_score.png',
                label: 'SCORE',
                value: _stats.totalScore,
                formatValue: _formatNumber,
              ),
              _ProfileStatCard(
                imagePath: 'assets/images/stats/stat_streak.png',
                label: 'STREAK',
                value: _stats.currentStreak,
                formatValue: _formatNumber,
              ),
              _ProfileStatCard(
                imagePath: 'assets/images/stats/stat_first_guess.png',
                label: 'FIRST GUESSES',
                value: _stats.firstGuesses,
                formatValue: _formatNumber,
              ),
              _ProfileStatCard(
                imagePath: 'assets/images/stats/stat_played.png',
                label: 'QUESTIONS PLAYED',
                value: _stats.gamesPlayed,
                formatValue: _formatNumber,
              ),
            ];

            return Container(
              padding: EdgeInsets.symmetric(
                vertical: isDesktop ? 14 : 10,
                horizontal: isDesktop ? 12 : 8,
              ),
              decoration: BoxDecoration(
                color: AppColors.panel,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: AppColors.border,
                ),
              ),
              child: isDesktop
                  ? Row(
                      children: [
                        Expanded(child: stats[0]),
                        const _VerticalStatDivider(),
                        Expanded(child: stats[1]),
                        const _VerticalStatDivider(),
                        Expanded(child: stats[2]),
                        const _VerticalStatDivider(),
                        Expanded(child: stats[3]),
                      ],
                    )
                  : Column(
                      children: [
                        Row(
                          children: [
                            Expanded(child: stats[0]),
                            const _VerticalStatDivider(),
                            Expanded(child: stats[1]),
                          ],
                        ),
                        const Divider(
                          height: 1,
                          color: AppColors.border,
                        ),
                        Row(
                          children: [
                            Expanded(child: stats[2]),
                            const _VerticalStatDivider(),
                            Expanded(child: stats[3]),
                          ],
                        ),
                      ],
                    ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildGameStatsSection() {
    final List<Widget> rows = _selectedGameStatRows();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _CenteredSectionTitle(
          title: 'GAME STATS',
        ),
        const SizedBox(height: 12),
        _buildGameSelector(),
        const SizedBox(height: 28),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          child: Column(
            key: ValueKey<_StatsGameMode>(_selectedStatsGame),
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _CenteredSectionTitle(
                title: _gameModeLabel(_selectedStatsGame).toUpperCase(),
              ),
              const SizedBox(height: 20),
              _StatsList(children: rows),
              if (_selectedStatsGame == _StatsGameMode.all) ...[
                const SizedBox(height: 28),
                _buildGamePerformanceRankingSection(),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGamePerformanceRankingSection() {
    final List<_StatsGameMode> rankedModes = _visibleStatsGameModes
        .where((_StatsGameMode mode) =>
            mode != _StatsGameMode.all &&
            (_gamePlayedCounts[mode] ?? 0) > 0)
        .toList()
      ..sort((_StatsGameMode first, _StatsGameMode second) {
        final double firstAccuracy = _accuracyForMode(first);
        final double secondAccuracy = _accuracyForMode(second);

        final int accuracyComparison = secondAccuracy.compareTo(firstAccuracy);
        if (accuracyComparison != 0) {
          return accuracyComparison;
        }

        final int correctComparison =
            _correctCountForMode(second).compareTo(_correctCountForMode(first));
        if (correctComparison != 0) {
          return correctComparison;
        }

        final int playedComparison = (_gamePlayedCounts[second] ?? 0)
            .compareTo(_gamePlayedCounts[first] ?? 0);
        if (playedComparison != 0) {
          return playedComparison;
        }

        return _StatsGameMode.values
            .indexOf(first)
            .compareTo(_StatsGameMode.values.indexOf(second));
      });

    final Set<_StatsGameMode> rankedSet = rankedModes.toSet();
    final List<_StatsGameMode> unrankedModes = _visibleStatsGameModes
        .where((_StatsGameMode mode) =>
            mode != _StatsGameMode.all && !rankedSet.contains(mode))
        .toList();

    final List<Widget> rows = <Widget>[];

    for (int index = 0; index < rankedModes.length; index++) {
      final _StatsGameMode mode = rankedModes[index];
      final bool isFirst = index == 0;
      final bool isLast = index == rankedModes.length - 1 &&
          rankedModes.length > 1;

      rows.add(
        _ProfileDetailRow(
          imagePath: 'assets/images/stats/my_stats/first_guess_rateV2.webp',
          forceSingleLine: true,
          label: isFirst
              ? 'Best Game'
              : isLast
                  ? 'Worst Game'
                  : _rankingPositionLabel(index + 1),
          value:
              '${_gameModeLabel(mode)} - ${_formatAccuracy(_accuracyForMode(mode))}',
        ),
      );
    }

    for (final _StatsGameMode mode in unrankedModes) {
      rows.add(
        _ProfileDetailRow(
          imagePath: 'assets/images/stats/my_stats/first_guess_rateV2.webp',
          forceSingleLine: true,
          label: 'Not Ranked Yet',
          value: '${_gameModeLabel(mode)} - No questions played',
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _CenteredSectionTitle(
          title: 'GAME PERFORMANCE RANKING',
        ),
        const SizedBox(height: 10),
        _StatsList(children: rows),
      ],
    );
  }

  double _accuracyForMode(_StatsGameMode mode) {
    final int played = _gamePlayedCounts[mode] ?? 0;
    if (played <= 0) {
      return 0;
    }

    final int correct = _correctCountForMode(mode);
    return (correct / played).clamp(0.0, 1.0);
  }

  String _formatAccuracy(double accuracy) {
    return '${(accuracy * 100).toStringAsFixed(1)}%';
  }

  String _rankingPositionLabel(int position) {
    switch (position) {
      case 2:
        return '2nd Best Game';
      case 3:
        return '3rd Best Game';
      case 4:
        return '4th Best Game';
      case 5:
        return '5th Best Game';
      default:
        return '${position}th Best Game';
    }
  }

  Widget _buildGameSelector() {
    final bool isDesktop =
        MediaQuery.sizeOf(context).width >= 1200;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _visibleStatsGameModes.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isDesktop ? 6 : 2,
        crossAxisSpacing: isDesktop ? 9 : 8,
        mainAxisSpacing: 8,
        childAspectRatio: isDesktop ? 3.2 : 3.35,
      ),
      itemBuilder: (BuildContext context, int index) {
        final _StatsGameMode mode = _visibleStatsGameModes[index];
        final bool selected = mode == _selectedStatsGame;

        return Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            onTap: () {
              setState(() {
                _selectedStatsGame = mode;
              });
            },
            borderRadius: BorderRadius.circular(14),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: AppColors.panel,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: selected
                      ? AppColors.orange
                      : AppColors.border,
                  width: selected ? 1.7 : 1.0,
                ),
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  _gameModeShortLabel(mode),
                  maxLines: 2,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Oswald',
                    color: AppColors.white,
                    fontSize: isDesktop ? 17 : 17,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.25,
                    height: 1.05,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  List<Widget> _selectedGameStatRows() {
    final _StatsGameMode mode = _selectedStatsGame;

    final int played = _gamePlayedCounts[mode] ?? 0;
    final int correct = _correctCountForMode(mode);
    final int firstGuesses = _firstGuessCountForMode(mode);
    final String accuracy = played <= 0
        ? '0.0%'
        : '${((correct / played) * 100).clamp(0.0, 100.0).toStringAsFixed(1)}%';

    final List<Widget> rows = <Widget>[
      _ProfileDetailRow(
        imagePath: 'assets/images/stats/my_stats/games_played.webp',
        label: 'Questions Played',
        value: _formatNumber(played),
      ),
      _ProfileDetailRow(
        imagePath: 'assets/images/stats/my_stats/highest_score.webp',
        label: _solvedLabelForMode(mode),
        value: _formatNumber(correct),
      ),
      _ProfileDetailRow(
        imagePath: 'assets/images/stats/my_stats/first_guess_rate.webp',
        label: mode == _StatsGameMode.firstWord ||
                mode == _StatsGameMode.firstConnection
            ? 'Solve Rate'
            : 'Accuracy',
        value: accuracy,
      ),
      _ProfileDetailRow(
        imagePath: 'assets/images/stats/my_stats/first_guesses.webp',
        label: 'First Guesses',
        value: _formatNumber(firstGuesses),
      ),
    ];

    if (mode == _StatsGameMode.classic) {
      rows.addAll(<Widget>[
        _ProfileDetailRow(
          imagePath: 'assets/images/stats/my_stats/best_category.webp',
          label: 'Top Correct Category',
          value: _topCorrectCategory,
        ),
        _ProfileDetailRow(
          imagePath: 'assets/images/stats/my_stats/first_guesses.webp',
          label: 'Top First Guess Category',
          value: _topFirstGuessCategory,
        ),
        _ProfileDetailRow(
          imagePath: 'assets/images/stats/stat_streak.png',
          label: 'Current Streak',
          value: _formatNumber(
            _stats.categoryCurrentStreakCounts['classic_first_guess'] ?? 0,
          ),
        ),
        _ProfileDetailRow(
          imagePath: 'assets/images/stats/stat_streak.png',
          label: 'Best Streak',
          value: _formatNumber(
            _stats.categoryLongestStreakCounts['classic_first_guess'] ?? 0,
          ),
        ),
      ]);
    } else if (mode != _StatsGameMode.all) {
      final String statsKey = _modeStatsKey(mode);

      rows.addAll(<Widget>[
        _ProfileDetailRow(
          imagePath: 'assets/images/stats/stat_streak.png',
          label: 'Current Streak',
          value: _formatNumber(
            _stats.categoryCurrentStreakCounts[statsKey] ?? 0,
          ),
        ),
        _ProfileDetailRow(
          imagePath: 'assets/images/stats/stat_streak.png',
          label: 'Best Streak',
          value: _formatNumber(
            _stats.categoryLongestStreakCounts[statsKey] ?? 0,
          ),
        ),
      ]);
    }

    if (mode != _StatsGameMode.all) {
      final String flashKey = _dailyFlashStatsKey(mode);
      final int flashCompleted =
          _dailyFlashGameCompletions[flashKey] ?? 0;
      final int flashPerfect =
          _dailyFlashGamePerfect5s[flashKey] ?? 0;
      final String perfectFlashRate = flashCompleted <= 0
          ? '0.0%'
          : '${((flashPerfect / flashCompleted) * 100).toStringAsFixed(1)}%';

      rows.addAll(<Widget>[
        _ProfileDetailRow(
          imagePath:
              'assets/images/stats/my_stats/daily_flash_completed.webp',
          label: 'Daily Flash 5 Completed',
          value: _formatNumber(flashCompleted),
        ),
        _ProfileDetailRow(
          imagePath:
              'assets/images/stats/my_stats/daily_flash_perfect.webp',
          label: 'Daily Flash Perfect 5s',
          value: _formatNumber(flashPerfect),
        ),
        _ProfileDetailRow(
          imagePath: 'assets/images/stats/my_stats/first_guess_rate.webp',
          label: 'Daily Flash Perfect Rate',
          value: perfectFlashRate,
        ),
      ]);
    }

    return rows;
  }

  int _correctCountForMode(_StatsGameMode mode) {
    if (mode == _StatsGameMode.all) {
      return _visibleStatsGameModes
          .where((_StatsGameMode item) => item != _StatsGameMode.all)
          .fold<int>(
            0,
            (int total, _StatsGameMode item) =>
                total + _correctCountForMode(item),
          );
    }

    if (mode == _StatsGameMode.classic) {
      const Set<String> classicKeys = <String>{
        'animals',
        'books_authors',
        'countries',
        'creative_world',
        'famous_words',
        'food_drink',
        'music',
        'past_present',
        'science_nature',
        'sports',
        'watch_play',
        'famous_people',
      };

      int total = 0;
      for (final String key in classicKeys) {
        total += _stats.categoryCorrectCounts[key] ?? 0;
      }
      return total;
    }

    return _stats.categoryCorrectCounts[_modeStatsKey(mode)] ?? 0;
  }

  int _firstGuessCountForMode(_StatsGameMode mode) {
    if (mode == _StatsGameMode.all) {
      return _visibleStatsGameModes
          .where((_StatsGameMode item) => item != _StatsGameMode.all)
          .fold<int>(
            0,
            (int total, _StatsGameMode item) =>
                total + _firstGuessCountForMode(item),
          );
    }

    if (mode == _StatsGameMode.classic) {
      const Set<String> classicKeys = <String>{
        'animals',
        'books_authors',
        'countries',
        'creative_world',
        'famous_words',
        'food_drink',
        'music',
        'past_present',
        'science_nature',
        'sports',
        'watch_play',
        'famous_people',
      };

      int total = 0;
      for (final String key in classicKeys) {
        total += _stats.categoryFirstGuessCounts[key] ?? 0;
      }
      return total;
    }

    return _stats.categoryFirstGuessCounts[_modeStatsKey(mode)] ?? 0;
  }

  String _modeStatsKey(_StatsGameMode mode) {
    switch (mode) {
      case _StatsGameMode.all:
        return '';
      case _StatsGameMode.firstConnection:
        return 'first_connection';
      case _StatsGameMode.firstDate:
        return 'first_date';
      case _StatsGameMode.firstMatch:
        return 'first_match';
      case _StatsGameMode.firstOrder:
        return 'first_order';
      case _StatsGameMode.firstWord:
        return 'first_word';
      case _StatsGameMode.classic:
        return '';
    }
  }

  String _dailyFlashStatsKey(_StatsGameMode mode) {
    switch (mode) {
      case _StatsGameMode.classic:
        return 'classic';
      case _StatsGameMode.firstConnection:
        return 'first_connection';
      case _StatsGameMode.firstDate:
        return 'first_date';
      case _StatsGameMode.firstMatch:
        return 'first_match';
      case _StatsGameMode.firstOrder:
        return 'first_order';
      case _StatsGameMode.firstWord:
        return 'first_word';
      case _StatsGameMode.all:
        return '';
    }
  }

  String _solvedLabelForMode(_StatsGameMode mode) {
    switch (mode) {
      case _StatsGameMode.all:
        return 'Correct Answers';
      case _StatsGameMode.classic:
        return 'Correct Answers';
      case _StatsGameMode.firstConnection:
        return 'Connections Solved';
      case _StatsGameMode.firstDate:
        return 'Dates Solved';
      case _StatsGameMode.firstMatch:
        return 'Matches Solved';
      case _StatsGameMode.firstOrder:
        return 'Orders Solved';
      case _StatsGameMode.firstWord:
        return 'Words Solved';
    }
  }

  String _gameModeLabel(_StatsGameMode mode) {
    switch (mode) {
      case _StatsGameMode.all:
        return 'All';
      case _StatsGameMode.classic:
        return 'Classic First Guess';
      case _StatsGameMode.firstConnection:
        return 'First Connection';
      case _StatsGameMode.firstDate:
        return 'First Date';
      case _StatsGameMode.firstMatch:
        return 'First Match';
      case _StatsGameMode.firstOrder:
        return 'First Order';
      case _StatsGameMode.firstWord:
        return 'First Word';
    }
  }

  String _gameModeShortLabel(_StatsGameMode mode) {
    switch (mode) {
      case _StatsGameMode.all:
        return 'ALL';
      case _StatsGameMode.classic:
        return 'CLASSIC FIRST\nGUESS';
      case _StatsGameMode.firstConnection:
        return 'FIRST\nCONNECTION';
      case _StatsGameMode.firstDate:
        return 'FIRST DATE';
      case _StatsGameMode.firstMatch:
        return 'FIRST MATCH';
      case _StatsGameMode.firstOrder:
        return 'FIRST ORDER';
      case _StatsGameMode.firstWord:
        return 'FIRST WORD';
    }
  }

  Widget _buildCategorySection() {
    final bool isDesktop =
        MediaQuery.sizeOf(context).width >= 1200;

    final List<_CategoryTileData> categories = <_CategoryTileData>[
      _CategoryTileData(
        imagePath: 'assets/images/categories/animals.webp',
        label: 'Animals',
        value: _formatNumber(_categoryPlayedCounts['Animals'] ?? 0),
      ),
      _CategoryTileData(
        imagePath: 'assets/images/categories/books_and_authors.webp',
        label: 'Books & Authors',
        value: _formatNumber(
          _categoryPlayedCounts['Books & Authors'] ?? 0,
        ),
      ),
      _CategoryTileData(
        imagePath: 'assets/images/categories/countries.webp',
        label: 'Countries',
        value: _formatNumber(_categoryPlayedCounts['Countries'] ?? 0),
      ),
      _CategoryTileData(
        imagePath: 'assets/images/categories/creative_world.webp',
        label: 'Creative World',
        value: _formatNumber(
          _categoryPlayedCounts['Creative World'] ?? 0,
        ),
      ),
      _CategoryTileData(
        imagePath:
            'assets/images/categories/famous_words/famous_words.webp',
        label: 'Famous Words',
        value: _formatNumber(
          _categoryPlayedCounts['Famous Words'] ?? 0,
        ),
      ),
      _CategoryTileData(
        imagePath: 'assets/images/categories/food_and_drink.webp',
        label: 'Food & Drink',
        value: _formatNumber(
          _categoryPlayedCounts['Food & Drink'] ?? 0,
        ),
      ),
      _CategoryTileData(
        imagePath: 'assets/images/categories/music.webp',
        label: 'Music',
        value: _formatNumber(_categoryPlayedCounts['Music'] ?? 0),
      ),
      _CategoryTileData(
        imagePath: 'assets/images/categories/past_and_present.webp',
        label: 'Past & Present',
        value: _formatNumber(
          _categoryPlayedCounts['Past & Present'] ?? 0,
        ),
      ),
      _CategoryTileData(
        imagePath: 'assets/images/categories/science_and_nature.webp',
        label: 'Science & Nature',
        value: _formatNumber(
          _categoryPlayedCounts['Science & Nature'] ?? 0,
        ),
      ),
      _CategoryTileData(
        imagePath: 'assets/images/categories/sports.webp',
        label: 'Sports',
        value: _formatNumber(_categoryPlayedCounts['Sports'] ?? 0),
      ),
      _CategoryTileData(
        imagePath: 'assets/images/categories/watch_and_play.webp',
        label: 'Watch & Play',
        value: _formatNumber(
          _categoryPlayedCounts['Watch & Play'] ?? 0,
        ),
      ),
      _CategoryTileData(
        imagePath: 'assets/images/categories/famous_people.webp',
        label: 'Who Am I?',
        value: _formatNumber(
          _categoryPlayedCounts['Who Am I?'] ?? 0,
        ),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _CenteredSectionTitle(
          title: 'CATEGORY GAMES PLAYED',
        ),
        const SizedBox(height: 12),
        Container(
          padding: EdgeInsets.fromLTRB(
            isDesktop ? 18 : 10,
            isDesktop ? 18 : 12,
            isDesktop ? 18 : 10,
            isDesktop ? 18 : 14,
          ),
          decoration: BoxDecoration(
            color: AppColors.panel,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border),
          ),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: categories.length,
            gridDelegate:
                SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: isDesktop ? 6 : 3,
              crossAxisSpacing: isDesktop ? 14 : 8,
              mainAxisSpacing: isDesktop ? 14 : 12,
              childAspectRatio: isDesktop ? 1.15 : 1.05,
            ),
            itemBuilder: (BuildContext context, int index) {
              final _CategoryTileData category = categories[index];

              return _CategoryStatTile(
                imagePath: category.imagePath,
                label: category.label,
                value: category.value,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCaseFilesSection() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _CenteredSectionTitle(
          title: 'CASE FILES',
        ),
        SizedBox(height: 10),
        _StatsList(
          children: [
            _ProfileDetailRow(
              icon: Icons.folder_open_rounded,
              label: 'Case Files Started',
              value: '—',
            ),
            _ProfileDetailRow(
              icon: Icons.check_circle_outline_rounded,
              label: 'Cases Solved',
              value: '—',
            ),
            _ProfileDetailRow(
              icon: Icons.route_rounded,
              label: 'Case Paths Completed',
              value: '—',
            ),
          ],
        ),
      ],
    );
  }

}

class _CenteredSectionTitle extends StatelessWidget {
  final String title;

  const _CenteredSectionTitle({
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          child: _SectionHeadingLine(
            reverse: false,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          maxLines: 1,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: 'Oswald',
            color: AppColors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.7,
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: _SectionHeadingLine(
            reverse: true,
          ),
        ),
      ],
    );
  }
}

class _SectionHeadingLine extends StatelessWidget {
  final bool reverse;

  const _SectionHeadingLine({
    required this.reverse,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1.5,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: reverse
              ? const [
                  AppColors.orange,
                  Colors.transparent,
                ]
              : const [
                  Colors.transparent,
                  AppColors.orange,
                ],
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x55FE5E02),
            blurRadius: 5,
          ),
        ],
      ),
    );
  }
}

class _VerticalStatDivider extends StatelessWidget {
  const _VerticalStatDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 118,
      color: AppColors.orange.withValues(alpha: 0.45),
    );
  }
}

class _ProfileStatCard extends StatelessWidget {
  final String imagePath;
  final String label;
  final int value;
  final String Function(int value) formatValue;

  const _ProfileStatCard({
    required this.imagePath,
    required this.label,
    required this.value,
    required this.formatValue,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 5,
        vertical: 14,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 62,
            height: 62,
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Image.asset(
                imagePath,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.high,
              ),
            ),
          ),
          const SizedBox(height: 9),
          TweenAnimationBuilder<int>(
            tween: IntTween(begin: 0, end: value),
            duration: const Duration(milliseconds: 850),
            curve: Curves.easeOutCubic,
            builder: (
              BuildContext context,
              int animatedValue,
              Widget? child,
            ) {
              return FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  formatValue(animatedValue),
                  style: const TextStyle(
                    fontFamily: 'Oswald',
                    color: AppColors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.7,
                    height: 1,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            style: const TextStyle(
              fontFamily: 'Oswald',
              color: AppColors.white,
              fontSize: 20,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.7,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryTileData {
  final String imagePath;
  final String label;
  final String value;

  const _CategoryTileData({
    required this.imagePath,
    required this.label,
    required this.value,
  });
}

class _CategoryStatTile extends StatelessWidget {
  final String imagePath;
  final String label;
  final String value;

  const _CategoryStatTile({
    required this.imagePath,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDesktop =
        MediaQuery.sizeOf(context).width >= 1200;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 8 : 4,
        vertical: isDesktop ? 10 : 6,
      ),
      decoration: isDesktop
          ? BoxDecoration(
              color: AppColors.background.withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.border.withValues(alpha: 0.85),
              ),
            )
          : null,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: isDesktop ? 58 : 72,
            height: isDesktop ? 58 : 72,
            child: Image.asset(
              imagePath,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
            ),
          ),
          SizedBox(height: isDesktop ? 7 : 8),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Oswald',
              color: AppColors.orange,
              fontSize: isDesktop ? 22 : 23,
              fontWeight: FontWeight.w600,
              height: 1,
            ),
          ),
          if (isDesktop) ...[
            const SizedBox(height: 6),
            Text(
              label.toUpperCase(),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Inter',
                color: AppColors.white,
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                height: 1.15,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatsList extends StatelessWidget {
  final List<Widget> children;

  const _StatsList({required this.children});

  @override
  Widget build(BuildContext context) {
    final List<Widget> rows = <Widget>[];

    for (int index = 0; index < children.length; index++) {
      rows.add(children[index]);
      if (index < children.length - 1) {
        rows.add(const Divider(
          height: 1,
          color: AppColors.border,
        ));
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.panel,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(children: rows),
    );
  }
}

class _ProfileDetailRow extends StatelessWidget {
  final IconData? icon;
  final String? imagePath;
  final bool forceSingleLine;
  final String label;
  final String value;

  const _ProfileDetailRow({
    this.icon,
    this.imagePath,
    this.forceSingleLine = false,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 13),
      child: Row(
        children: [
          if (imagePath != null)
            Container(
              width: 38,
              height: 38,
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.background,
                border: Border.all(
                  color: AppColors.orange,
                  width: 1.0,
                ),
              ),
              child: Image.asset(
                imagePath!,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.high,
              ),
            )
          else
            Icon(
              icon,
              color: AppColors.orange,
              size: 22,
            ),
          const SizedBox(width: 12),
          Expanded(
            flex: forceSingleLine ? 4 : 6,
            child: Text(
              label,
              maxLines: forceSingleLine ? 1 : null,
              softWrap: !forceSingleLine,
              overflow: forceSingleLine ? TextOverflow.visible : null,
              textAlign: TextAlign.left,
              style: TextStyle(
                fontFamily: 'Oswald',
                color: AppColors.white,
                fontSize: forceSingleLine ? 15 : 18,
                fontWeight: FontWeight.w500,
                height: 1.15,
              ),
            ),
          ),
          SizedBox(width: forceSingleLine ? 8 : 12),
          Expanded(
            flex: forceSingleLine ? 7 : 5,
            child: Text(
              value,
              maxLines: forceSingleLine ? 1 : null,
              softWrap: !forceSingleLine,
              overflow: forceSingleLine ? TextOverflow.visible : null,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontFamily: 'Oswald',
                color: AppColors.white,
                fontSize: forceSingleLine ? 15 : 18,
                fontWeight: FontWeight.w500,
                height: 1.15,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
