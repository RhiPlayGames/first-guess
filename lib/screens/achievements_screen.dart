import 'package:flutter/material.dart';

import '../services/achievement_service.dart';
import '../services/player_stats_service.dart';
import '../theme/app_colors.dart';
import '../widgets/app_home_button.dart';

class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({super.key});

  @override
  State<AchievementsScreen> createState() =>
      _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen> {
  PlayerStats _stats = const PlayerStats();
  int _dailyFlashCompleted = 0;
  int _dailyFlashPerfect5s = 0;
  bool _isLoading = true;
  _FilterData? _selectedFilter;

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

  List<Achievement> get _visibleAchievements {
    final List<Achievement> achievements;

    final List<Achievement> dailyFlashAchievements = <Achievement>[
      Achievement(
        id: 'daily_flash_1',
        title: 'Flash Starter',
        description: 'Complete your first Daily Flash 5',
        rarity: AchievementRarity.bronze,
        category: AchievementCategory.dailyFlash,
        target: 1,
        achievementPoints: 20,
        progressSelector: (_) => _dailyFlashCompleted,
      ),
      Achievement(
        id: 'daily_flash_10',
        title: 'Flash Regular',
        description: 'Complete 10 Daily Flash 5 challenges',
        rarity: AchievementRarity.silver,
        category: AchievementCategory.dailyFlash,
        target: 10,
        achievementPoints: 60,
        progressSelector: (_) => _dailyFlashCompleted,
      ),
      Achievement(
        id: 'daily_flash_50',
        title: 'Flash Veteran',
        description: 'Complete 50 Daily Flash 5 challenges',
        rarity: AchievementRarity.gold,
        category: AchievementCategory.dailyFlash,
        target: 50,
        achievementPoints: 125,
        progressSelector: (_) => _dailyFlashCompleted,
      ),
      Achievement(
        id: 'daily_flash_100',
        title: 'Flash Legend',
        description: 'Complete 100 Daily Flash 5 challenges',
        rarity: AchievementRarity.diamond,
        category: AchievementCategory.dailyFlash,
        target: 100,
        achievementPoints: 300,
        progressSelector: (_) => _dailyFlashCompleted,
      ),
      Achievement(
        id: 'daily_flash_perfect_1',
        title: 'Perfect Flash',
        description: 'Score a perfect 5 out of 5 in Daily Flash 5',
        rarity: AchievementRarity.bronze,
        category: AchievementCategory.dailyFlash,
        target: 1,
        achievementPoints: 30,
        progressSelector: (_) => _dailyFlashPerfect5s,
      ),
      Achievement(
        id: 'daily_flash_perfect_5',
        title: 'Perfect Five',
        description: 'Score 5 perfect Daily Flash 5s',
        rarity: AchievementRarity.silver,
        category: AchievementCategory.dailyFlash,
        target: 5,
        achievementPoints: 75,
        progressSelector: (_) => _dailyFlashPerfect5s,
      ),
      Achievement(
        id: 'daily_flash_perfect_25',
        title: 'Flash Perfectionist',
        description: 'Score 25 perfect Daily Flash 5s',
        rarity: AchievementRarity.gold,
        category: AchievementCategory.dailyFlash,
        target: 25,
        achievementPoints: 150,
        progressSelector: (_) => _dailyFlashPerfect5s,
      ),
    ];

    if (_selectedFilter == null || _selectedFilter!.categories == null) {
      achievements = <Achievement>[
        ...AchievementService.achievements,
        ...dailyFlashAchievements,
      ];
    } else {
      final Set<AchievementCategory> selectedCategories =
          _selectedFilter!.categories!;

      achievements = <Achievement>[
        ...AchievementService.achievements.where(
          (achievement) =>
              selectedCategories.contains(achievement.category),
        ),
        if (selectedCategories.contains(AchievementCategory.dailyFlash))
          ...dailyFlashAchievements,
      ];
    }

    achievements.sort((first, second) {
      final int firstStatusRank = _achievementStatusRank(first);
      final int secondStatusRank = _achievementStatusRank(second);

      if (firstStatusRank != secondStatusRank) {
        return firstStatusRank.compareTo(secondStatusRank);
      }

      final int firstCategoryRank = _achievementCategoryRank(first.category);
      final int secondCategoryRank = _achievementCategoryRank(second.category);

      if (firstCategoryRank != secondCategoryRank) {
        return firstCategoryRank.compareTo(secondCategoryRank);
      }

      return first.target.compareTo(second.target);
    });

    return achievements;
  }

  int _achievementStatusRank(Achievement achievement) {
    if (achievement.isUnlocked(_stats)) {
      return 2;
    }

    if (achievement.progress(_stats) > 0) {
      return 0;
    }

    return 1;
  }

  int _achievementCategoryRank(AchievementCategory category) {
    switch (category) {
      case AchievementCategory.xp:
        return 0;
      case AchievementCategory.score:
        return 1;
      case AchievementCategory.streak:
        return 2;
      case AchievementCategory.firstGuess:
        return 3;
      case AchievementCategory.dailyFlash:
        return 4;
      case AchievementCategory.books:
        return 5;
      case AchievementCategory.countries:
        return 6;
      case AchievementCategory.flags:
        return 7;
      case AchievementCategory.animals:
        return 8;
      case AchievementCategory.footballTeams:
        return 9;
      case AchievementCategory.movies:
        return 10;
      case AchievementCategory.general:
        return 11;
    }
  }

  List<Achievement> get _dailyFlashAchievementsForSummary {
    return <Achievement>[
      Achievement(
        id: 'daily_flash_1',
        title: 'Flash Starter',
        description: 'Complete your first Daily Flash 5',
        rarity: AchievementRarity.bronze,
        category: AchievementCategory.dailyFlash,
        target: 1,
        achievementPoints: 20,
        progressSelector: (_) => _dailyFlashCompleted,
      ),
      Achievement(
        id: 'daily_flash_10',
        title: 'Flash Regular',
        description: 'Complete 10 Daily Flash 5 challenges',
        rarity: AchievementRarity.silver,
        category: AchievementCategory.dailyFlash,
        target: 10,
        achievementPoints: 60,
        progressSelector: (_) => _dailyFlashCompleted,
      ),
      Achievement(
        id: 'daily_flash_50',
        title: 'Flash Veteran',
        description: 'Complete 50 Daily Flash 5 challenges',
        rarity: AchievementRarity.gold,
        category: AchievementCategory.dailyFlash,
        target: 50,
        achievementPoints: 125,
        progressSelector: (_) => _dailyFlashCompleted,
      ),
      Achievement(
        id: 'daily_flash_100',
        title: 'Flash Legend',
        description: 'Complete 100 Daily Flash 5 challenges',
        rarity: AchievementRarity.diamond,
        category: AchievementCategory.dailyFlash,
        target: 100,
        achievementPoints: 300,
        progressSelector: (_) => _dailyFlashCompleted,
      ),
      Achievement(
        id: 'daily_flash_perfect_1',
        title: 'Perfect Flash',
        description: 'Score a perfect 5 out of 5 in Daily Flash 5',
        rarity: AchievementRarity.bronze,
        category: AchievementCategory.dailyFlash,
        target: 1,
        achievementPoints: 30,
        progressSelector: (_) => _dailyFlashPerfect5s,
      ),
      Achievement(
        id: 'daily_flash_perfect_5',
        title: 'Perfect Five',
        description: 'Score 5 perfect Daily Flash 5s',
        rarity: AchievementRarity.silver,
        category: AchievementCategory.dailyFlash,
        target: 5,
        achievementPoints: 75,
        progressSelector: (_) => _dailyFlashPerfect5s,
      ),
      Achievement(
        id: 'daily_flash_perfect_25',
        title: 'Flash Perfectionist',
        description: 'Score 25 perfect Daily Flash 5s',
        rarity: AchievementRarity.gold,
        category: AchievementCategory.dailyFlash,
        target: 25,
        achievementPoints: 150,
        progressSelector: (_) => _dailyFlashPerfect5s,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final List<Achievement> allAchievements = <Achievement>[
      ...AchievementService.achievements,
      ..._dailyFlashAchievementsForSummary,
    ];

    final int completedCount = allAchievements
        .where((achievement) => achievement.isUnlocked(_stats))
        .length;

    final int totalCount = allAchievements.length;

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
            'MY ACHIEVEMENTS',
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
                child: CustomScrollView(
                  physics:
                      const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(
                        18,
                        12,
                        18,
                        18,
                      ),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate(
                          [
                            _AchievementSummary(
                              completedCount: completedCount,
                              totalCount: totalCount,
                            ),
                            const SizedBox(height: 20),
                            _CategoryFilters(
                              selectedFilter: _selectedFilter,
                              onFilterSelected: (filter) {
                                setState(() {
                                  _selectedFilter = filter;
                                });
                              },
                            ),
                            const SizedBox(height: 20),
                            Text(
                              _selectedFilter == null ||
                                      _selectedFilter!.categories == null
                                  ? 'ALL ACHIEVEMENTS'
                                  : '${_selectedFilter!.label} ACHIEVEMENTS',
                              style: const TextStyle(
                                color: AppColors.white,
                                fontSize: 17,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(
                        18,
                        0,
                        18,
                        32,
                      ),
                      sliver: SliverList.separated(
                        itemCount: _visibleAchievements.length,
                        separatorBuilder: (context, index) {
                          return const SizedBox(height: 12);
                        },
                        itemBuilder: (context, index) {
                          final Achievement achievement =
                              _visibleAchievements[index];

                          return _AchievementCard(
                            achievement: achievement,
                            stats: _stats,
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

}

class _AchievementSummary extends StatelessWidget {
  final int completedCount;
  final int totalCount;

  const _AchievementSummary({
    required this.completedCount,
    required this.totalCount,
  });

  @override
  Widget build(BuildContext context) {
    final double progress = totalCount == 0
        ? 0
        : completedCount / totalCount;

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      decoration: BoxDecoration(
        color: AppColors.panel,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
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
              'assets/images/stats/my_stats/achievements.webp',
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            '$completedCount / $totalCount',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Oswald',
              color: AppColors.white,
              fontSize: 30,
              fontWeight: FontWeight.w600,
              height: 1,
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            'ACHIEVEMENTS COMPLETED',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Inter',
              color: AppColors.white,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 18),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 12,
              backgroundColor: AppColors.border,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(
                AppColors.orange,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryFilters extends StatelessWidget {
  final _FilterData? selectedFilter;
  final ValueChanged<_FilterData?> onFilterSelected;

  const _CategoryFilters({
    required this.selectedFilter,
    required this.onFilterSelected,
  });

  @override
  Widget build(BuildContext context) {
    const List<_FilterData> filters = [
      _FilterData(
        label: 'ALL',
        categories: null,
      ),
      _FilterData(
        label: 'XP',
        categories: <AchievementCategory>{
          AchievementCategory.xp,
        },
      ),
      _FilterData(
        label: 'SCORE',
        categories: <AchievementCategory>{
          AchievementCategory.score,
        },
      ),
      _FilterData(
        label: 'STREAK',
        categories: <AchievementCategory>{
          AchievementCategory.streak,
        },
      ),
      _FilterData(
        label: 'FIRST GUESS',
        categories: <AchievementCategory>{
          AchievementCategory.firstGuess,
        },
      ),
      _FilterData(
        label: 'DAILY FLASH 5',
        categories: <AchievementCategory>{
          AchievementCategory.dailyFlash,
        },
      ),
      _FilterData(
        label: 'BOOKS & AUTHORS',
        categories: <AchievementCategory>{
          AchievementCategory.books,
        },
      ),
      _FilterData(
        label: 'COUNTRIES',
        categories: <AchievementCategory>{
          AchievementCategory.countries,
          AchievementCategory.flags,
        },
      ),
      _FilterData(
        label: 'CREATIVE WORLD',
        categories: <AchievementCategory>{},
      ),
      _FilterData(
        label: 'FAMOUS PEOPLE',
        categories: <AchievementCategory>{},
      ),
      _FilterData(
        label: 'MUSIC',
        categories: <AchievementCategory>{},
      ),
      _FilterData(
        label: 'PAST & PRESENT',
        categories: <AchievementCategory>{},
      ),
      _FilterData(
        label: 'SCIENCE & DISCOVERY',
        categories: <AchievementCategory>{
          AchievementCategory.animals,
        },
      ),
      _FilterData(
        label: 'SPORTS',
        categories: <AchievementCategory>{
          AchievementCategory.footballTeams,
        },
      ),
      _FilterData(
        label: 'WATCH & PLAY',
        categories: <AchievementCategory>{
          AchievementCategory.movies,
        },
      ),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((filter) {
          final bool isAll = filter.categories == null;
          final bool isSelected = isAll
              ? selectedFilter == null ||
                  selectedFilter?.categories == null
              : selectedFilter?.label == filter.label;

          return Padding(
            padding: const EdgeInsets.only(right: 9),
            child: ChoiceChip(
              selected: isSelected,
              onSelected: (_) {
                onFilterSelected(isAll ? null : filter);
              },
              label: Text(filter.label),
              labelStyle: TextStyle(
                fontFamily: 'Inter',
                color: isSelected
                    ? Colors.black
                    : AppColors.white,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
              selectedColor: AppColors.orange,
              backgroundColor: AppColors.panel,
              side: BorderSide(
                color: isSelected
                    ? AppColors.orange
                    : AppColors.border,
              ),
              showCheckmark: false,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _FilterData {
  final String label;
  final Set<AchievementCategory>? categories;

  const _FilterData({
    required this.label,
    required this.categories,
  });
}

class _AchievementCard extends StatelessWidget {
  final Achievement achievement;
  final PlayerStats stats;

  const _AchievementCard({
    required this.achievement,
    required this.stats,
  });

  static const Color _completedGreen = Color(0xFF79D44C);

  @override
  Widget build(BuildContext context) {
    final int currentProgress = achievement.progress(stats);
    final bool isCompleted = achievement.isUnlocked(stats);
    final bool isInProgress = !isCompleted && currentProgress > 0;

    final _AchievementDisplayStatus status = isCompleted
        ? _AchievementDisplayStatus.completed
        : isInProgress
            ? _AchievementDisplayStatus.inProgress
            : _AchievementDisplayStatus.notStarted;

    final bool isNotStarted =
        status == _AchievementDisplayStatus.notStarted;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 15,
      ),
      decoration: BoxDecoration(
        color: AppColors.panel,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.orange,
          width: 1.4,
        ),
        boxShadow: isCompleted
            ? const [
                BoxShadow(
                  color: Color(0x22FE5E02),
                  blurRadius: 12,
                ),
              ]
            : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _AchievementIcon(
            achievement: achievement,
            isNotStarted: isNotStarted,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  achievement.title.toUpperCase(),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Oswald',
                    color: isNotStarted
                        ? AppColors.grey
                        : AppColors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.4,
                    height: 1.05,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  achievement.description,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    color: isNotStarted
                        ? AppColors.grey
                        : AppColors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          _AchievementStatusPill(
            status: status,
            completedGreen: _completedGreen,
          ),
        ],
      ),
    );
  }
}

enum _AchievementDisplayStatus {
  inProgress,
  notStarted,
  completed,
}

class _AchievementStatusPill extends StatelessWidget {
  final _AchievementDisplayStatus status;
  final Color completedGreen;

  const _AchievementStatusPill({
    required this.status,
    required this.completedGreen,
  });

  @override
  Widget build(BuildContext context) {
    final String label;
    final IconData? icon;
    final Color backgroundColor;
    final Color foregroundColor;
    final Color borderColor;

    switch (status) {
      case _AchievementDisplayStatus.inProgress:
        label = 'IN PROGRESS';
        icon = null;
        backgroundColor = AppColors.orange;
        foregroundColor = AppColors.white;
        borderColor = AppColors.orange;
        break;

      case _AchievementDisplayStatus.notStarted:
        label = 'NOT STARTED';
        icon = Icons.more_horiz_rounded;
        backgroundColor = const Color(0xFF242424);
        foregroundColor = AppColors.grey;
        borderColor = AppColors.darkGrey;
        break;

      case _AchievementDisplayStatus.completed:
        label = 'COMPLETED';
        icon = Icons.check_circle_rounded;
        backgroundColor = completedGreen;
        foregroundColor = AppColors.white;
        borderColor = completedGreen;
        break;
    }

    return Container(
      constraints: const BoxConstraints(
        minWidth: 108,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 9,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: borderColor,
          width: 1.2,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              color: foregroundColor,
              size: 17,
            ),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.fade,
              softWrap: false,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Oswald',
                color: foregroundColor,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.25,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AchievementIcon extends StatelessWidget {
  final Achievement achievement;
  final bool isNotStarted;

  const _AchievementIcon({
    required this.achievement,
    required this.isNotStarted,
  });

  String get _imagePath {
    switch (achievement.category) {
      case AchievementCategory.general:
        return 'assets/images/stats/my_stats/games_played.webp';

      case AchievementCategory.countries:
        return 'assets/images/categories/subcategories/countries/countries_globe.webp';

      case AchievementCategory.firstGuess:
        return 'assets/images/stats/my_stats/first_guesses.webp';

      case AchievementCategory.streak:
        return 'assets/images/stats/my_stats/achievements.webp';

      case AchievementCategory.score:
        return 'assets/images/stats/my_stats/highest_score.webp';

      case AchievementCategory.xp:
        return 'assets/images/stats/my_stats/xp.webp';

      case AchievementCategory.dailyFlash:
        return achievement.id.contains('perfect')
            ? 'assets/images/stats/my_stats/daily_flash_perfect.webp'
            : 'assets/images/stats/my_stats/daily_flash_completed.webp';

      case AchievementCategory.flags:
        return 'assets/images/categories/subcategories/countries/countries_globe.webp';

      case AchievementCategory.movies:
        return 'assets/images/categories/watch_and_play.png';

      case AchievementCategory.books:
        return 'assets/images/categories/books_and_authors.png';

      case AchievementCategory.animals:
        return 'assets/images/stats/my_stats/achievements.webp';

      case AchievementCategory.footballTeams:
        return 'assets/images/categories/sports.png';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      height: 64,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.background,
        border: Border.all(
          color: isNotStarted
              ? AppColors.darkGrey
              : AppColors.orange,
          width: isNotStarted ? 1.0 : 1.3,
        ),
      ),
      child: Opacity(
        opacity: isNotStarted ? 0.45 : 1.0,
        child: Image.asset(
          _imagePath,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.high,
        ),
      ),
    );
  }
}

