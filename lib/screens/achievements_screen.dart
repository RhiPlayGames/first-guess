import 'package:flutter/material.dart';

import '../services/achievement_service.dart';
import '../services/feature_flag_service.dart';
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
  bool _isLoading = true;
  bool _firstConnectionEnabled = false;
  _FilterData? _selectedFilter;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    // Load the core player stats first so the Achievements screen can
    // render quickly instead of waiting for every secondary source.
    final List<dynamic> results = await Future.wait<dynamic>(<Future<dynamic>>[
      PlayerStatsService.loadStats(),
      FeatureFlagService.isFirstConnectionEnabled(),
    ]);

    final PlayerStats savedStats = results[0] as PlayerStats;
    final bool firstConnectionEnabled = results[1] as bool;

    if (!mounted) {
      return;
    }

    setState(() {
      _stats = savedStats;
      _firstConnectionEnabled = firstConnectionEnabled;
      _isLoading = false;
    });

    // Load Daily Flash achievement progress after the main stats.
    final int dailyFlashCompleted =
        await DailyFlashMilestoneService.loadLifetimeCompletions();

    if (!mounted) {
      return;
    }

    setState(() {
      _dailyFlashCompleted = dailyFlashCompleted;
    });
  }

  List<Achievement> get _visibleAchievements {
    final List<Achievement> achievements;

    final List<Achievement> dailyFlashAchievements = <Achievement>[
      Achievement(
        id: 'daily_flash_1',
        title: 'Flash Starter',
        description: 'Complete your first Daily Flash 5.',
        rarity: AchievementRarity.bronze,
        category: AchievementCategory.dailyFlash,
        target: 1,
        achievementPoints: 0,
        progressSelector: (_) => _dailyFlashCompleted,
      ),
      Achievement(
        id: 'daily_flash_10',
        title: 'Flash Regular',
        description: 'Complete 10 Daily Flash 5 challenges.',
        rarity: AchievementRarity.bronze,
        category: AchievementCategory.dailyFlash,
        target: 10,
        achievementPoints: 0,
        progressSelector: (_) => _dailyFlashCompleted,
      ),
      Achievement(
        id: 'daily_flash_50',
        title: 'Flash Veteran',
        description: 'Complete 50 Daily Flash 5 challenges.',
        rarity: AchievementRarity.silver,
        category: AchievementCategory.dailyFlash,
        target: 50,
        achievementPoints: 0,
        progressSelector: (_) => _dailyFlashCompleted,
      ),
      Achievement(
        id: 'daily_flash_100',
        title: 'Flash Legend',
        description: 'Complete 100 Daily Flash 5 challenges.',
        rarity: AchievementRarity.gold,
        category: AchievementCategory.dailyFlash,
        target: 100,
        achievementPoints: 0,
        progressSelector: (_) => _dailyFlashCompleted,
      ),
      Achievement(
        id: 'daily_flash_250',
        title: 'Flash Master',
        description: 'Complete 250 Daily Flash 5 challenges.',
        rarity: AchievementRarity.diamond,
        category: AchievementCategory.dailyFlash,
        target: 250,
        achievementPoints: 0,
        progressSelector: (_) => _dailyFlashCompleted,
      ),
      Achievement(
        id: 'daily_flash_365',
        title: 'Year of Flash',
        description: 'Complete 365 Daily Flash 5 challenges.',
        rarity: AchievementRarity.diamond,
        category: AchievementCategory.dailyFlash,
        target: 365,
        achievementPoints: 0,
        progressSelector: (_) => _dailyFlashCompleted,
      ),
    ];

    if (_selectedFilter == null || _selectedFilter!.categories == null) {
      achievements = <Achievement>[
        ...AchievementService.achievements.where(
          (achievement) =>
              _firstConnectionEnabled ||
              achievement.category != AchievementCategory.firstConnection,
        ),
        ...dailyFlashAchievements,
      ];
    } else {
      final Set<AchievementCategory> selectedCategories =
          _selectedFilter!.categories!;

      achievements = <Achievement>[
        ...AchievementService.achievements.where(
          (achievement) =>
              (_firstConnectionEnabled ||
                  achievement.category != AchievementCategory.firstConnection) &&
              selectedCategories.contains(achievement.category),
        ),
        if (selectedCategories.contains(AchievementCategory.dailyFlash))
          ...dailyFlashAchievements,
      ];
    }

    achievements.sort((first, second) {
      final bool firstUnlocked = first.isUnlocked(_stats);
      final bool secondUnlocked = second.isUnlocked(_stats);

      if (firstUnlocked != secondUnlocked) {
        return firstUnlocked ? -1 : 1;
      }

      return first.target.compareTo(second.target);
    });

    return achievements;
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
        centerTitle: true,
        title: const Text(
          'MY ACHIEVEMENTS',
          style: TextStyle(
            fontFamily: 'Oswald',
            fontWeight: FontWeight.w500,
            letterSpacing: 0.6,
          ),
        ),
        actions: <Widget>[
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: FirstGuessHomeButton(
              onPressed: () =>
                  Navigator.of(context).popUntil((route) => route.isFirst),
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
                      padding: EdgeInsets.fromLTRB(
                        horizontalPadding,
                        12,
                        horizontalPadding,
                        18,
                      ),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate(
                          [
                            _CategoryFilters(
                              selectedFilter: _selectedFilter,
                              firstConnectionEnabled: _firstConnectionEnabled,
                              onFilterSelected: (filter) {
                                setState(() {
                                  _selectedFilter = filter;
                                });
                              },
                            ),
                            const SizedBox(height: 16),
                            const _AchievementDivider(),
                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(
                        horizontalPadding,
                        0,
                        horizontalPadding,
                        32,
                      ),
                      sliver: isDesktop
                          ? SliverGrid(
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 14,
                                mainAxisSpacing: 14,
                                mainAxisExtent: 150,
                              ),
                              delegate: SliverChildBuilderDelegate(
                                (context, index) {
                                  final Achievement achievement =
                                      _visibleAchievements[index];

                                  return _AchievementCard(
                                    achievement: achievement,
                                    stats: _stats,
                                  );
                                },
                                childCount:
                                    _visibleAchievements.length,
                              ),
                            )
                          : SliverList.separated(
                              itemCount:
                                  _visibleAchievements.length,
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

class _AchievementDivider extends StatelessWidget {
  const _AchievementDivider();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          child: Divider(
            color: AppColors.orange,
            thickness: 1,
            height: 1,
          ),
        ),
        Transform.rotate(
          angle: 0.785398,
          child: Container(
            width: 10,
            height: 10,
            margin: const EdgeInsets.symmetric(horizontal: 8),
            color: AppColors.orange,
          ),
        ),
        const Expanded(
          child: Divider(
            color: AppColors.orange,
            thickness: 1,
            height: 1,
          ),
        ),
      ],
    );
  }
}

class _CategoryFilters extends StatelessWidget {
  final _FilterData? selectedFilter;
  final bool firstConnectionEnabled;
  final ValueChanged<_FilterData?> onFilterSelected;

  const _CategoryFilters({
    required this.selectedFilter,
    required this.firstConnectionEnabled,
    required this.onFilterSelected,
  });

  static const Set<AchievementCategory> _classicCategories =
      <AchievementCategory>{
    AchievementCategory.firstGuess,
    AchievementCategory.animals,
    AchievementCategory.booksAuthors,
    AchievementCategory.countries,
    AchievementCategory.creativeWorld,
    AchievementCategory.famousWords,
    AchievementCategory.foodDrink,
    AchievementCategory.music,
    AchievementCategory.pastPresent,
    AchievementCategory.scienceNature,
    AchievementCategory.sports,
    AchievementCategory.watchPlay,
    AchievementCategory.whoAmI,
  };

  static const List<_FilterData> _baseFilters = <_FilterData>[
    _FilterData(label: 'ALL', categories: null),
    _FilterData(
      label: 'DAILY FLASH 5',
      categories: <AchievementCategory>{AchievementCategory.dailyFlash},
    ),
    _FilterData(
      label: 'GAMES PLAYED',
      categories: <AchievementCategory>{AchievementCategory.general},
    ),
    _FilterData(
      label: 'STREAK',
      categories: <AchievementCategory>{AchievementCategory.streak},
    ),
    _FilterData(
      label: 'XP',
      categories: <AchievementCategory>{AchievementCategory.xp},
    ),
    _FilterData(
      label: 'CLASSIC FIRST GUESS',
      categories: _classicCategories,
    ),
    _FilterData(
      label: 'FIRST DATE',
      categories: <AchievementCategory>{AchievementCategory.firstDate},
    ),
    _FilterData(
      label: 'FIRST MATCH',
      categories: <AchievementCategory>{AchievementCategory.firstMatch},
    ),
    _FilterData(
      label: 'FIRST ORDER',
      categories: <AchievementCategory>{AchievementCategory.firstOrder},
    ),
    _FilterData(
      label: 'FIRST WORD',
      categories: <AchievementCategory>{AchievementCategory.firstWord},
    ),
  ];

  Widget _buildChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 9),
      child: ChoiceChip(
        selected: isSelected,
        onSelected: (_) => onTap(),
        label: Text(label),
        labelStyle: TextStyle(
          fontFamily: 'Inter',
          color: isSelected ? Colors.black : AppColors.white,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
        selectedColor: AppColors.orange,
        backgroundColor: AppColors.panel,
        side: BorderSide(
          color: isSelected ? AppColors.orange : AppColors.border,
        ),
        showCheckmark: false,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<_FilterData> filters = <_FilterData>[
      ..._baseFilters,
      if (firstConnectionEnabled)
        const _FilterData(
          label: 'FIRST CONNECTION',
          categories: <AchievementCategory>{
            AchievementCategory.firstConnection,
          },
        ),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((filter) {
          final bool isAll = filter.categories == null;
          final bool isSelected = isAll
              ? selectedFilter == null || selectedFilter?.categories == null
              : selectedFilter?.label == filter.label;

          return _buildChip(
            label: filter.label,
            isSelected: isSelected,
            onTap: () => onFilterSelected(isAll ? null : filter),
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

  String _formatNumber(int value) {
    final String digits = value.abs().toString();
    final StringBuffer buffer = StringBuffer();

    for (int index = 0; index < digits.length; index++) {
      if (index > 0 && (digits.length - index) % 3 == 0) {
        buffer.write(',');
      }
      buffer.write(digits[index]);
    }

    return value < 0 ? '-$buffer' : buffer.toString();
  }

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

    final int cappedProgress = currentProgress.clamp(
      0,
      achievement.target,
    );
    final double progressFraction =
        achievement.target <= 0
            ? 1
            : (cappedProgress / achievement.target)
                .clamp(0.0, 1.0);
    final int progressPercent =
        (progressFraction * 100).round();

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _AchievementIcon(
                achievement: achievement,
                isCompleted: isCompleted,
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
                        color: isCompleted || isInProgress
                            ? AppColors.white
                            : AppColors.grey,
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
                        color: isCompleted || isInProgress
                            ? AppColors.white
                            : AppColors.grey,
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
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                '${_formatNumber(cappedProgress)} / '
                '${_formatNumber(achievement.target)}',
                style: TextStyle(
                  fontFamily: 'Inter',
                  color: isCompleted || isInProgress
                      ? AppColors.white
                      : AppColors.grey,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                '$progressPercent%',
                style: TextStyle(
                  fontFamily: 'Inter',
                  color: isCompleted || isInProgress
                      ? AppColors.white
                      : AppColors.grey,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progressFraction,
              minHeight: 6,
              backgroundColor: AppColors.darkGrey,
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.orange,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

enum _AchievementDisplayStatus {
  notStarted,
  inProgress,
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
    final Color backgroundColor;
    final Color foregroundColor;
    final Color borderColor;

    switch (status) {
      case _AchievementDisplayStatus.notStarted:
        label = 'NOT STARTED';
        backgroundColor = const Color(0xFF242424);
        foregroundColor = AppColors.white;
        borderColor = AppColors.white;
        break;

      case _AchievementDisplayStatus.inProgress:
        label = 'IN PROGRESS';
        backgroundColor = const Color(0xFF242424);
        foregroundColor = AppColors.orange;
        borderColor = AppColors.orange;
        break;

      case _AchievementDisplayStatus.completed:
        label = 'COMPLETED';
        backgroundColor = const Color(0xFF242424);
        foregroundColor = completedGreen;
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
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: borderColor,
          width: 1.2,
        ),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.fade,
        softWrap: false,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontFamily: 'Inter',
          color: foregroundColor,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0,
        ),
      ),
    );
  }
}

class _AchievementIcon extends StatelessWidget {
  final Achievement achievement;
  final bool isCompleted;

  const _AchievementIcon({
    required this.achievement,
    required this.isCompleted,
  });

  String get _imagePath {
    switch (achievement.category) {
      case AchievementCategory.general:
        return 'assets/images/stats/my_stats/games_played.webp';

      case AchievementCategory.firstGuess:
        return 'assets/images/stats/my_stats/first_guesses.webp';

      case AchievementCategory.streak:
        return 'assets/images/stats/stat_streak.png';

      case AchievementCategory.xp:
        return 'assets/images/stats/my_stats/xp.webp';

      case AchievementCategory.dailyFlash:
        return 'assets/images/stats/my_stats/daily_flash_completed.webp';

      case AchievementCategory.firstConnection:
        return 'assets/images/categories/first_connection/firstconnections_icon128.webp';

      case AchievementCategory.firstDate:
        return 'assets/images/categories/first_date/firstdateicon128.webp';

      case AchievementCategory.firstMatch:
        return 'assets/images/categories/first_match/firstmatch_icon128.webp';

      case AchievementCategory.firstOrder:
        return 'assets/images/categories/first_order/firstorder_icon128.webp';

      case AchievementCategory.firstWord:
        return 'assets/images/categories/first_word/firstword_128.webp';

      case AchievementCategory.countries:
        return 'assets/images/categories/countries.webp';

      case AchievementCategory.scienceNature:
        return 'assets/images/categories/science_and_nature.webp';

      case AchievementCategory.animals:
        return 'assets/images/categories/animals.webp';

      case AchievementCategory.watchPlay:
        return 'assets/images/categories/watch_and_play.webp';

      case AchievementCategory.music:
        return 'assets/images/categories/music.webp';

      case AchievementCategory.booksAuthors:
        return 'assets/images/categories/books_and_authors.webp';

      case AchievementCategory.sports:
        return 'assets/images/categories/sports.webp';

      case AchievementCategory.whoAmI:
        return 'assets/images/categories/famous_people.webp';

      case AchievementCategory.pastPresent:
        return 'assets/images/categories/past_and_present.webp';

      case AchievementCategory.foodDrink:
        return 'assets/images/categories/food_and_drink.webp';

      case AchievementCategory.creativeWorld:
        return 'assets/images/categories/creative_world.webp';

      case AchievementCategory.famousWords:
        return 'assets/images/categories/famous_words/famous_words.webp';
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
          color: AppColors.orange,
          width: 1.3,
        ),
      ),
      child: Opacity(
        opacity: isCompleted ? 1 : 0.72,
        child: Image.asset(
          _imagePath,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.high,
          errorBuilder: (context, error, stackTrace) {
            return const Icon(
              Icons.emoji_events_rounded,
              color: AppColors.orange,
              size: 30,
            );
          },
        ),
      ),
    );
  }
}

