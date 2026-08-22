import 'package:flutter/material.dart';

import '../services/player_stats_service.dart';
import '../theme/app_colors.dart';
import '../widgets/app_home_button.dart';
import '../leaderboard/leaderboard_screen.dart';
import 'achievements_screen.dart';
import 'avatar_picker_screen.dart';


class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileHubState();
}

class _ProfileHubState extends State<ProfileScreen> {
  String? _selectedAvatarPath;

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

    setState(() {
      _selectedAvatarPath = selectedAvatarPath;
    });
  }

  void _openStats() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => const StatsDetailScreen(),
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
        'assets/images/avatars/default_avatar.webp';

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
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 32),
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: SizedBox(
                    width: 126,
                    height: 126,
                    child: Image.asset(
                      avatarPath,
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.high,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Center(
                  child: SizedBox(
                    width: 240,
                    child: Material(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(16),
                      child: InkWell(
                        onTap: _changeAvatar,
                        borderRadius: BorderRadius.circular(16),
                        child: Ink(
                          height: 50,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Color(0xFFFFA512),
                                Color(0xFFFF7900),
                                Color(0xFFFF4B00),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: const Color(0xFFFFB21A),
                              width: 1.2,
                            ),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x44FF6500),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'CHANGE AVATAR',
                                style: const TextStyle(
                                  fontFamily: 'Oswald',
                                  color: AppColors.white,
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.35,
                                ),
                              ),
                              const SizedBox(width: 9),
                              const Icon(
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
                const SizedBox(height: 22),
                _ProfileHubActionCard(
                  imagePath: 'assets/images/stats/my_stats/highest_score.webp',
                  title: 'MY STATS',
                  subtitle: 'View your progress and performance',
                  onTap: _openStats,
                ),
                const SizedBox(height: 12),
                _ProfileHubActionCard(
                  imagePath: 'assets/images/stats/my_stats/achievements.webp',
                  title: 'ACHIEVEMENTS',
                  subtitle: 'View your badges and milestones',
                  onTap: _openAchievements,
                ),
                const SizedBox(height: 12),
                _ProfileHubActionCard(
                  imagePath: 'assets/images/stats/my_stats/games_played.webp',
                  title: 'LEADERBOARD',
                  subtitle: 'See how you rank against other players',
                  onTap: _openLeaderboard,
                ),
            ],
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
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          padding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 13,
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
                width: 58,
                height: 58,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(15),
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
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontFamily: 'Oswald',
                        color: AppColors.white,
                        fontSize: 19,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.35,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      maxLines: 2,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        color: AppColors.white,
                        fontSize: 13,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.orange,
                size: 29,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class StatsDetailScreen extends StatefulWidget {
  const StatsDetailScreen({super.key});

  @override
  State<StatsDetailScreen> createState() => _StatsDetailScreenState();
}

class _StatsDetailScreenState extends State<StatsDetailScreen> {
  PlayerStats _stats = const PlayerStats();
  int _dailyFlashCompleted = 0;
  int _dailyFlashPerfect5s = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final PlayerStats savedStats =
        await PlayerStatsService.loadStats();

    final int dailyFlashCompleted =
        await DailyFlashMilestoneService
            .loadLifetimeCompletions();

    final int dailyFlashPerfect5s =
        await DailyFlashMilestoneService
            .loadPerfect5s();

    if (!mounted) {
      return;
    }

    setState(() {
      _stats = savedStats;
      _dailyFlashCompleted = dailyFlashCompleted;
      _dailyFlashPerfect5s = dailyFlashPerfect5s;
      _isLoading = false;
    });
  }

  PlayerRankProgress get _rankProgress {
    return PlayerRankProgress.fromXp(
      _stats.totalXp,
    );
  }

  String _rankImagePath(PlayerRankProgress rank) {
    final String title = rank.fullTitle.toLowerCase();

    const Map<String, String> roles = <String, String>{
      'clue seeker': 'clue_seeker',
      'investigator': 'investigator',
      'detective': 'detective',
      'super sleuth': 'super_sleuth',
      'sleuth': 'sleuth',
    };

    const Map<String, String> tiers = <String, String>{
      'rookie': 'rookie',
      'senior': 'senior',
      'expert': 'expert',
      'master': 'master',
      'elite': 'elite',
    };

    String role = 'clue_seeker';
    String tier = 'rookie';

    for (final MapEntry<String, String> entry in roles.entries) {
      if (title.contains(entry.key)) {
        role = entry.value;
        break;
      }
    }

    for (final MapEntry<String, String> entry in tiers.entries) {
      if (title.contains(entry.key)) {
        tier = entry.value;
        break;
      }
    }

    return 'assets/images/stats/tiers/${role}_$tier.webp';
  }

  String get _bestCategory {
    final Map<String, int> totals = <String, int>{
      'Books & Authors':
          _stats.booksCompleted + _stats.authorsCompleted,
      'Countries':
          _stats.countriesCompleted +
          _stats.capitalCitiesCompleted +
          _stats.flagsCompleted,
      'Past & Present':
          _stats.historicalFiguresCompleted,
      'Science & Discovery':
          _stats.periodicTableCompleted,
      'Sports':
          _stats.footballTeamsCompleted,
      'Watch & Play':
          _stats.moviesCompleted,
    };

    String bestName = '—';
    int bestTotal = 0;

    totals.forEach((String name, int total) {
      if (total > bestTotal) {
        bestName = name;
        bestTotal = total;
      }
    });

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


  String get _firstGuessRate {
    return '${_stats.firstGuessPercentage.toStringAsFixed(1)}%';
  }

  String get _averageClue {
    if (_stats.correctlySolvedGames == 0) {
      return '—';
    }

    return _stats.averageClueNeeded.toStringAsFixed(1);
  }

  void _openAchievements() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => const AchievementsScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                  padding: const EdgeInsets.fromLTRB(
                    18,
                    12,
                    18,
                    32,
                  ),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.stretch,
                    children: [
                      _buildLevelCard(),
                      const SizedBox(height: 16),
                      _buildAchievementsButton(),
                      const SizedBox(height: 20),
                      _buildMainStats(),
                      const SizedBox(height: 20),
                      _buildPerformanceSection(),
                      const SizedBox(height: 20),
                      _buildCategorySection(),
                      const SizedBox(height: 16),
                      _buildCaseFilesSection(),
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

  Widget _buildAchievementsButton() {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: _openAchievements,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          decoration: BoxDecoration(
            color: AppColors.panel,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: AppColors.orange,
              width: 1.4,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 13,
            ),
            child: Row(
              children: [
                Container(
                  width: 58,
                  height: 58,
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.background,
                    border: Border.all(
                      color: AppColors.orange,
                      width: 1.2,
                    ),
                  ),
                  child: Image.asset(
                    'assets/images/stats/my_stats/achievements.webp',
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.high,
                  ),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ACHIEVEMENTS',
                        style: TextStyle(
                          fontFamily: 'Oswald',
                          color: AppColors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.4,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'View your badges and milestones',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          color: AppColors.white,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
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
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.panel,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Expanded(
                child: _ProfileStatCard(
                  imagePath: 'assets/images/stats/my_stats/xp.webp',
                  label: 'EXPERIENCE (XP)',
                  value: _stats.totalXp,
                  formatValue: _formatNumber,
                ),
              ),
              const _VerticalStatDivider(),
              Expanded(
                child: _ProfileStatCard(
                  imagePath: 'assets/images/stats/my_stats/games_played.webp',
                  label: 'GAMES PLAYED',
                  value: _stats.gamesPlayed,
                  formatValue: _formatNumber,
                ),
              ),
              const _VerticalStatDivider(),
              Expanded(
                child: _ProfileStatCard(
                  imagePath: 'assets/images/stats/my_stats/first_guesses.webp',
                  label: 'FIRST GUESSES',
                  value: _stats.firstGuesses,
                  formatValue: _formatNumber,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPerformanceSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _CenteredSectionTitle(
          title: 'PERFORMANCE',
        ),
        const SizedBox(height: 10),
        _StatsList(
          children: [
            _ProfileDetailRow(
              imagePath: 'assets/images/stats/my_stats/first_guess_rate.webp',
              label: 'First Guess Rate',
              value: _firstGuessRate,
            ),
            _ProfileDetailRow(
              imagePath: 'assets/images/stats/my_stats/average_clue.webp',
              label: 'Average Clue Needed',
              value: _averageClue,
            ),
            _ProfileDetailRow(
              imagePath: 'assets/images/stats/my_stats/highest_score.webp',
              label: 'Highest Score',
              value: _formatNumber(_stats.highestScore),
            ),
            _ProfileDetailRow(
              imagePath: 'assets/images/stats/my_stats/best_category.webp',
              label: 'Best Category',
              value: _bestCategory,
            ),
            _ProfileDetailRow(
              imagePath: 'assets/images/stats/my_stats/daily_flash_completed.webp',
              label: 'Daily Flash 5 Completed',
              value: _formatNumber(_dailyFlashCompleted),
            ),
            _ProfileDetailRow(
              imagePath: 'assets/images/stats/my_stats/daily_flash_perfect.webp',
              label: 'Daily Flash Perfect 5s',
              value: _formatNumber(_dailyFlashPerfect5s),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCategorySection() {
    final List<_CategoryTileData> categories = <_CategoryTileData>[
      _CategoryTileData(
        imagePath: 'assets/images/categories/books_and_authors.png',
        label: 'Books & Authors',
        value: _formatNumber(
          _stats.booksCompleted + _stats.authorsCompleted,
        ),
      ),
      _CategoryTileData(
        imagePath: 'assets/images/categories/subcategories/countries/countries_globe.webp',
        label: 'Countries',
        value: _formatNumber(
          _stats.countriesCompleted +
              _stats.capitalCitiesCompleted +
              _stats.flagsCompleted,
        ),
      ),
      const _CategoryTileData(
        imagePath: 'assets/images/categories/creative_world.png',
        label: 'Creative World',
        value: '—',
      ),
      const _CategoryTileData(
        imagePath: 'assets/images/categories/famous_people.png',
        label: 'Famous People',
        value: '—',
      ),
      const _CategoryTileData(
        imagePath: 'assets/images/categories/music.png',
        label: 'Music',
        value: '—',
      ),
      _CategoryTileData(
        imagePath: 'assets/images/categories/past_and_present.png',
        label: 'Past & Present',
        value: _formatNumber(_stats.historicalFiguresCompleted),
      ),
      _CategoryTileData(
        imagePath: 'assets/images/categories/science_and_discovery.png',
        label: 'Science & Discovery',
        value: _formatNumber(_stats.periodicTableCompleted),
      ),
      _CategoryTileData(
        imagePath: 'assets/images/categories/sports.png',
        label: 'Sports',
        value: _formatNumber(_stats.footballTeamsCompleted),
      ),
      _CategoryTileData(
        imagePath: 'assets/images/categories/watch_and_play.png',
        label: 'Watch & Play',
        value: _formatNumber(_stats.moviesCompleted),
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
          padding: const EdgeInsets.fromLTRB(10, 12, 10, 14),
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
                const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 12,
              childAspectRatio: 1.05,
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
            _ProfileDetailRow(
              icon: Icons.search_rounded,
              label: 'Current Case',
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
          Container(
            width: 62,
            height: 62,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.background,
              border: Border.all(
                color: AppColors.orange,
                width: 1.4,
              ),
            ),
            child: Image.asset(
              imagePath,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
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
                    fontSize: 27,
                    fontWeight: FontWeight.w600,
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
              fontFamily: 'Inter',
              color: AppColors.white,
              fontSize: 10.5,
              fontWeight: FontWeight.w500,
              height: 1.15,
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
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 72,
          height: 72,
          child: Image.asset(
            imagePath,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontFamily: 'Oswald',
            color: AppColors.orange,
            fontSize: 23,
            fontWeight: FontWeight.w600,
            height: 1,
          ),
        ),
      ],
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
  final String label;
  final String value;

  const _ProfileDetailRow({
    this.icon,
    this.imagePath,
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
            child: Text(
              label,
              style: const TextStyle(
                fontFamily: 'Inter',
                color: AppColors.white,
                fontSize: 17,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontFamily: 'Oswald',
                color: AppColors.white,
                fontSize: 19,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
