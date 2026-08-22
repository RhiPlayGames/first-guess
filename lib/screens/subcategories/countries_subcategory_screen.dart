import 'package:flutter/material.dart';

import '../../services/firebase_challenge_service.dart';
import '../../services/player_stats_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/app_home_button.dart';
import '../../widgets/subcategory_status_badge.dart';
import '../../widgets/stats_panel.dart';
import '../game_screen.dart';

class CountriesSubcategoryScreen extends StatefulWidget {
  const CountriesSubcategoryScreen({super.key});

  @override
  State<CountriesSubcategoryScreen> createState() =>
      _CountriesSubcategoryScreenState();
}

class _CountriesSubcategoryScreenState
    extends State<CountriesSubcategoryScreen> {
  static const List<_CountriesSubcategoryData>
      _subcategories = <_CountriesSubcategoryData>[
    _CountriesSubcategoryData(
      title: 'Capital Cities',
      imagePath:
          'assets/images/categories/subcategories/countries/capitals_cities.webp',
      played: 0,
      total: 10,
      status: _SubcategoryStatus.notStarted,
      idPrefix: 'countries_capitals_',
    ),
    _CountriesSubcategoryData(
      title: 'Country Silhouettes',
      imagePath:
          'assets/images/categories/subcategories/countries/countries_silhouettes.webp',
      played: 0,
      total: 10,
      status: _SubcategoryStatus.notStarted,
      idPrefix: 'countries_country_silhouettes_',
    ),
    _CountriesSubcategoryData(
      title: 'Currencies',
      imagePath:
          'assets/images/categories/subcategories/countries/currencies_languages.webp',
      played: 0,
      total: 10,
      status: _SubcategoryStatus.notStarted,
      idPrefix: 'countries_currencies_',
    ),
    _CountriesSubcategoryData(
      title: 'Flags',
      imagePath:
          'assets/images/categories/subcategories/countries/flags.webp',
      played: 60,
      total: 70,
      status: _SubcategoryStatus.newQuestions,
      newQuestions: 10,
    ),
    _CountriesSubcategoryData(
      title: 'Natural Wonders & Landscapes',
      imagePath:
          'assets/images/categories/subcategories/countries/islands_mountains_rivers.webp',
      played: 40,
      total: 40,
      status: _SubcategoryStatus.allCaughtUp,
    ),
    _CountriesSubcategoryData(
      title: 'Landmarks & Wonders',
      imagePath:
          'assets/images/categories/subcategories/countries/landmarks_wonders.webp',
      played: 50,
      total: 50,
      status: _SubcategoryStatus.allCaughtUp,
    ),
    _CountriesSubcategoryData(
      title: 'Major Cities',
      imagePath:
          'assets/images/categories/subcategories/countries/major_cities.webp',
      played: 0,
      total: 10,
      status: _SubcategoryStatus.notStarted,
      idPrefix: 'countries_major_cities_',
    ),
    _CountriesSubcategoryData(
      title: 'Maps & Borders',
      imagePath:
          'assets/images/categories/subcategories/countries/maps_borders.webp',
      played: 8,
      total: 60,
      status: _SubcategoryStatus.inProgress,
    ),
    _CountriesSubcategoryData(
      title: 'National Foods',
      imagePath:
          'assets/images/categories/subcategories/countries/national_foods.webp',
      played: 0,
      total: 40,
      status: _SubcategoryStatus.notStarted,
    ),
    _CountriesSubcategoryData(
      title: 'National Symbols',
      imagePath:
          'assets/images/categories/subcategories/countries/national_symbols.webp',
      played: 40,
      total: 52,
      status: _SubcategoryStatus.newQuestions,
      newQuestions: 12,
    ),
    _CountriesSubcategoryData(
      title: 'States & Regions',
      imagePath:
          'assets/images/categories/subcategories/countries/states_regions.webp',
      played: 60,
      total: 60,
      status: _SubcategoryStatus.allCaughtUp,
    ),
  ];

  Map<String, int> _playedCounts = <String, int>{};

  PlayerStats _playerStats = const PlayerStats();
  bool _statsLoaded = false;

  @override
  void initState() {
    super.initState();
    _refreshScreenData();
  }

  Future<void> _refreshScreenData() async {
    await Future.wait([
      _loadPlayerStats(),
      _loadPlayedCounts(),
    ]);
  }

  Future<void> _loadPlayerStats() async {
    final PlayerStats savedStats =
        await PlayerStatsService.loadStats();

    if (!mounted) {
      return;
    }

    setState(() {
      _playerStats = savedStats;
      _statsLoaded = true;
    });
  }

  Future<void> _loadPlayedCounts() async {
    final Map<String, String> prefixesBySubcategory =
        <String, String>{
      for (final _CountriesSubcategoryData item in _subcategories)
        if (item.idPrefix != null)
          item.title: item.idPrefix!,
    };

    final Map<String, int> countsByPrefix =
        await QuestionHistoryService
            .countPlayedQuestionsByPrefixes(
      prefixesBySubcategory.values,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _playedCounts = <String, int>{
        for (final MapEntry<String, String> entry
            in prefixesBySubcategory.entries)
          entry.key: countsByPrefix[entry.value] ?? 0,
      };
    });
  }

  int _playedFor(_CountriesSubcategoryData item) {
    final int played = item.idPrefix == null
        ? item.played
        : (_playedCounts[item.title] ?? 0);

    return played > item.total ? item.total : played;
  }

  _SubcategoryStatus _statusFor(
    _CountriesSubcategoryData item,
  ) {
    if (item.idPrefix == null) {
      return item.status;
    }

    final int played = _playedFor(item);

    if (played <= 0) {
      return _SubcategoryStatus.notStarted;
    }

    if (played >= item.total) {
      return _SubcategoryStatus.allCaughtUp;
    }

    return _SubcategoryStatus.inProgress;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            const _CountriesHeader(),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
              child: StatsPanel(
                totalScore:
                    _statsLoaded ? _playerStats.totalScore : 0,
                currentStreak:
                    _statsLoaded ? _playerStats.currentStreak : 0,
                firstGuesses:
                    _statsLoaded ? _playerStats.firstGuesses : 0,
                gamesPlayed:
                    _statsLoaded ? _playerStats.gamesPlayed : 0,
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
                itemCount: _subcategories.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(height: 10),
                itemBuilder: (
                  BuildContext context,
                  int index,
                ) {
                  final _CountriesSubcategoryData item =
                      _subcategories[index];

                  return _CountriesSubcategoryCard(
                    data: item,
                    played: _playedFor(item),
                    status: _statusFor(item),
                    onTap: () => _handleTap(context, item),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleTap(
    BuildContext context,
    _CountriesSubcategoryData item,
  ) async {
    if (item.title == 'Capital Cities') {
      try {
        final items =
            await FirebaseChallengeService.loadLiveSubcategory(
          category: 'countries',
          subcategory: 'capitals',
        );

        if (!context.mounted) {
          return;
        }

        if (items.isEmpty) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                backgroundColor: AppColors.panel,
                behavior: SnackBarBehavior.floating,
                content: Text(
                  'No live Capital Cities questions were found.',
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            );
          return;
        }

        await Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (context) => GameScreen.capitalCities(
              items: items,
            ),
          ),
        );

        if (mounted) {
          await _refreshScreenData();
        }
      } catch (_) {
        if (!context.mounted) {
          return;
        }

        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              backgroundColor: AppColors.panel,
              behavior: SnackBarBehavior.floating,
              content: Text(
                'Capital Cities could not be loaded from Firebase.',
                style: AppTextStyles.body.copyWith(
                  color: AppColors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          );
      }

      return;
    }

    if (item.title == 'Country Silhouettes') {
      try {
        final items =
            await FirebaseChallengeService.loadLiveSubcategory(
          category: 'countries',
          subcategory: 'country_silhouettes',
        );

        if (!context.mounted) {
          return;
        }

        if (items.isEmpty) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                backgroundColor: AppColors.panel,
                behavior: SnackBarBehavior.floating,
                content: Text(
                  'No live Country Silhouettes questions were found.',
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            );
          return;
        }

        await Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (context) => GameScreen.countrySilhouettes(
              items: items,
            ),
          ),
        );

        if (mounted) {
          await _refreshScreenData();
        }
      } catch (_) {
        if (!context.mounted) {
          return;
        }

        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              backgroundColor: AppColors.panel,
              behavior: SnackBarBehavior.floating,
              content: Text(
                'Country Silhouettes could not be loaded from Firebase.',
                style: AppTextStyles.body.copyWith(
                  color: AppColors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          );
      }

      return;
    }

    if (item.title == 'Currencies') {
      try {
        final items =
            await FirebaseChallengeService.loadLiveSubcategory(
          category: 'countries',
          subcategory: 'currencies',
        );

        if (!context.mounted) {
          return;
        }

        if (items.isEmpty) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                backgroundColor: AppColors.panel,
                behavior: SnackBarBehavior.floating,
                content: Text(
                  'No live Currencies questions were found.',
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            );
          return;
        }

        await Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (context) => GameScreen.currencies(
              items: items,
            ),
          ),
        );

        if (mounted) {
          await _refreshScreenData();
        }
      } catch (_) {
        if (!context.mounted) {
          return;
        }

        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              backgroundColor: AppColors.panel,
              behavior: SnackBarBehavior.floating,
              content: Text(
                'Currencies could not be loaded from Firebase.',
                style: AppTextStyles.body.copyWith(
                  color: AppColors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          );
      }

      return;
    }

    if (item.title == 'Major Cities') {
      try {
        final items =
            await FirebaseChallengeService.loadLiveSubcategory(
          category: 'countries',
          subcategory: 'major_cities',
        );

        if (!context.mounted) {
          return;
        }

        if (items.isEmpty) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                backgroundColor: AppColors.panel,
                behavior: SnackBarBehavior.floating,
                content: Text(
                  'No live Major Cities questions were found.',
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            );
          return;
        }

        await Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (context) => GameScreen.majorCities(
              items: items,
            ),
          ),
        );

        if (mounted) {
          await _refreshScreenData();
        }
      } catch (_) {
        if (!context.mounted) {
          return;
        }

        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              backgroundColor: AppColors.panel,
              behavior: SnackBarBehavior.floating,
              content: Text(
                'Major Cities could not be loaded from Firebase.',
                style: AppTextStyles.body.copyWith(
                  color: AppColors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          );
      }

      return;
    }

    final String message;

    switch (item.status) {
      case _SubcategoryStatus.notStarted:
        message = 'Start ${item.title}.';
        break;
      case _SubcategoryStatus.inProgress:
        message =
            'Continue ${item.title}: ${item.played} of ${item.total} played.';
        break;
      case _SubcategoryStatus.allCaughtUp:
        message =
            'You are all caught up in ${item.title}. You can play again anytime.';
        break;
      case _SubcategoryStatus.newQuestions:
        message =
            '${item.newQuestions} new questions are waiting in ${item.title}.';
        break;
      case _SubcategoryStatus.playAgain:
        message =
            'You are all caught up in ${item.title}. Play again to improve your score.';
        break;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          backgroundColor: AppColors.panel,
          behavior: SnackBarBehavior.floating,
          content: Text(
            message,
            style: AppTextStyles.body.copyWith(
              color: AppColors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
  }
}

class _CountriesHeader extends StatelessWidget {
  const _CountriesHeader();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            height: 74,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Center(
                  child: Text(
                    'COUNTRIES',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.category.copyWith(
                      color: AppColors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.45,
                    ),
                  ),
                ),
                const Positioned(
                  right: 10,
                  top: 12,
                  child: FirstGuessHomeButton(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 0),
          Center(
            child: Text(
              'Choose a subcategory to start playing',
              textAlign: TextAlign.center,
              style: AppTextStyles.body.copyWith(
                color: AppColors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CountriesSubcategoryCard extends StatelessWidget {
  const _CountriesSubcategoryCard({
    required this.data,
    required this.played,
    required this.status,
    required this.onTap,
  });

  final _CountriesSubcategoryData data;
  final int played;
  final _SubcategoryStatus status;
  final VoidCallback onTap;

  static const Color _purple = Color(0xFFB86CFF);
  static const Color _blue = Color(0xFF4EA8FF);
  static const Color _progressTrack = Color(0xFF2B2B2B);

  @override
  Widget build(BuildContext context) {
    final double progress = data.total == 0
        ? 0
        : (played / data.total).clamp(0.0, 1.0);

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          padding: const EdgeInsets.fromLTRB(12, 13, 12, 13),
          decoration: BoxDecoration(
            color: AppColors.panel,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: AppColors.darkGrey,
              width: 1.0,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 64,
                height: 64,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.orange,
                    width: 1.2,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Image.asset(
                    data.imagePath,
                    width: 56,
                    height: 56,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.category.copyWith(
                        color: AppColors.white,
                        fontSize: 18.5,
                        fontWeight: FontWeight.w600,
                        height: 1.08,
                        letterSpacing: 0.1,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      '$played of ${data.total} played',
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.white,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 9),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(99),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 6,
                        backgroundColor: _progressTrack,
                        valueColor:
                            const AlwaysStoppedAnimation<Color>(
                          AppColors.orange,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              ConstrainedBox(
                constraints: const BoxConstraints(
                  minWidth: 100,
                  maxWidth: 132,
                ),
                child: _buildStatusArea(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusArea() {
    if (status == _SubcategoryStatus.allCaughtUp) {
      return const Align(
        alignment: Alignment.centerRight,
        child: SubcategoryStatusBadge(
          text: 'PLAY AGAIN',
          color: _blue,
        ),
      );
    }

    return Align(
      alignment: Alignment.centerRight,
      child: _buildSingleStatusBadge(),
    );
  }

  Widget _buildSingleStatusBadge() {
    switch (status) {
      case _SubcategoryStatus.notStarted:
        return const SubcategoryStatusBadge(
          text: 'NOT STARTED',
          color: AppColors.white,
        );
      case _SubcategoryStatus.inProgress:
        return const SubcategoryStatusBadge(
          text: 'IN PROGRESS',
          color: AppColors.orange,
        );
      case _SubcategoryStatus.allCaughtUp:
        return const SubcategoryStatusBadge(
          text: 'PLAY AGAIN',
          color: _blue,
        );
      case _SubcategoryStatus.newQuestions:
        return const SubcategoryStatusBadge(
          text: 'NEW QUESTIONS',
          color: _purple,
        );
      case _SubcategoryStatus.playAgain:
        return const SubcategoryStatusBadge(
          text: 'PLAY AGAIN',
          color: _blue,
        );
    }
  }
}

enum _SubcategoryStatus {
  notStarted,
  inProgress,
  allCaughtUp,
  newQuestions,
  playAgain,
}

class _CountriesSubcategoryData {
  const _CountriesSubcategoryData({
    required this.title,
    required this.imagePath,
    required this.played,
    required this.total,
    required this.status,
    this.newQuestions = 0,
    this.idPrefix,
  });

  final String title;
  final String imagePath;
  final int played;
  final int total;
  final _SubcategoryStatus status;
  final int newQuestions;
  final String? idPrefix;
}