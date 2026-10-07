import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../services/firebase_challenge_service.dart';
import '../../services/player_stats_service.dart';
import '../../services/subcategory_progress_status.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/classic_category_header.dart';
import '../../widgets/subcategory_status_badge.dart';
import '../../widgets/responsive_subcategory_list.dart';
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
          status: SubcategoryProgressStatus.start,
          idPrefix: 'countries_capitals_',
          firebaseKey: 'capitals',
        ),
    _CountriesSubcategoryData(
          title: 'Country Silhouettes',
          imagePath:
              'assets/images/categories/subcategories/countries/countries_silhouettes.webp',
          played: 0,
          total: 10,
          status: SubcategoryProgressStatus.start,
          idPrefix: 'countries_country_silhouettes_',
          firebaseKey: 'country_silhouettes',
        ),
    _CountriesSubcategoryData(
          title: 'Currencies',
          imagePath:
              'assets/images/categories/subcategories/countries/currencies_languages.webp',
          played: 0,
          total: 10,
          status: SubcategoryProgressStatus.start,
          idPrefix: 'countries_currencies_',
          firebaseKey: 'currencies',
        ),
    _CountriesSubcategoryData(
          title: 'Flags',
          imagePath:
              'assets/images/categories/subcategories/countries/flags.webp',
          played: 0,
          total: 30,
          status: SubcategoryProgressStatus.start,
          idPrefix: 'countries_flags_',
          firebaseKey: 'flags',
        ),
    _CountriesSubcategoryData(
          title: 'Major Cities',
          imagePath:
              'assets/images/categories/subcategories/countries/major_cities.webp',
          played: 0,
          total: 10,
          status: SubcategoryProgressStatus.start,
          idPrefix: 'countries_major_cities_',
          firebaseKey: 'major_cities',
        ),
    _CountriesSubcategoryData(
          title: 'National Symbols',
          imagePath:
              'assets/images/categories/subcategories/countries/national_symbols.webp',
          played: 0,
          total: 10,
          status: SubcategoryProgressStatus.start,
          idPrefix: 'countries_national_symbols_',
          firebaseKey: 'national_symbols',
        ),
    _CountriesSubcategoryData(
          title: 'Natural Wonders & Landscapes',
          imagePath:
              'assets/images/categories/subcategories/countries/islands_mountains_rivers.webp',
          played: 0,
          total: 10,
          status: SubcategoryProgressStatus.start,
          idPrefix: 'countries_natural_wonders_landscapes_',
          firebaseKey: 'natural_wonders_landscapes',
        ),
    _CountriesSubcategoryData(
          title: 'States & Regions',
          imagePath:
              'assets/images/categories/subcategories/countries/states_regions.webp',
          played: 0,
          total: 20,
          status: SubcategoryProgressStatus.start,
          idPrefix: 'countries_states_regions_',
          firebaseKey: 'states_regions',
        ),
  ];

  Map<String, int> _playedCounts = <String, int>{};
  Map<String, int> _liveQuestionCounts = <String, int>{};
  Map<String, Set<String>> _liveQuestionIds = <String, Set<String>>{};
  Map<String, int> _completedQuestionTotals = <String, int>{};

  PlayerStats _playerStats = const PlayerStats();
  bool _statsLoaded = false;
  bool _surpriseMeLoading = false;

  @override
  void initState() {
    super.initState();
    _refreshScreenData();
  }

  Future<void> _refreshScreenData() async {
    await Future.wait<void>(<Future<void>>[
      _loadPlayerStats(),
      _loadLiveQuestionData(),
    ]);

    if (!mounted) {
      return;
    }

    await _loadPlayedCounts();

    if (!mounted) {
      return;
    }

    await _loadAndUpdateCompletionSnapshots();
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

  Future<void> _loadLiveQuestionData() async {
    try {
      final List<QueryDocumentSnapshot<Map<String, dynamic>>> documents =
          await FirebaseChallengeService.loadLiveCategoryDocuments(
        category: 'countries',
      );

      if (!mounted) {
        return;
      }

      final Set<String> knownKeys =
          _subcategories.map((_CountriesSubcategoryData item) => item.firebaseKey).toSet();
      final Map<String, int> counts = <String, int>{
        for (final String key in knownKeys) key: 0,
      };
      final Map<String, Set<String>> idsBySubcategory =
          <String, Set<String>>{
        for (final String key in knownKeys) key: <String>{},
      };

      for (final QueryDocumentSnapshot<Map<String, dynamic>> document
          in documents) {
        final String subcategory =
            (document.data()['subcategory'] ?? '').toString().trim();

        if (!knownKeys.contains(subcategory)) {
          continue;
        }

        idsBySubcategory[subcategory]!.add(document.id);
      }

      for (final String key in knownKeys) {
        counts[key] = idsBySubcategory[key]!.length;
      }

      setState(() {
        _liveQuestionCounts = counts;
        _liveQuestionIds = idsBySubcategory;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _liveQuestionCounts = <String, int>{};
        _liveQuestionIds = <String, Set<String>>{};
      });
    }
  }

  Future<void> _loadPlayedCounts() async {
    final Set<String> playedIds =
        await QuestionHistoryService.loadPlayedQuestionIds();

    if (!mounted) {
      return;
    }

    final Map<String, int> counts = <String, int>{};

    for (final _CountriesSubcategoryData item in _subcategories) {
      final Set<String> liveIds =
          _liveQuestionIds[item.firebaseKey] ?? <String>{};

      if (liveIds.isNotEmpty) {
        counts[item.title] =
            liveIds.where(playedIds.contains).length;
      } else if (item.idPrefix != null) {
        counts[item.title] =
            playedIds.where((id) => id.startsWith(item.idPrefix!)).length;
      } else {
        counts[item.title] = item.played;
      }
    }

    setState(() {
      _playedCounts = counts;
    });
  }

  Future<void> _loadAndUpdateCompletionSnapshots() async {
    final Map<String, int> savedCompletedTotals =
        await SubcategoryCompletionHistoryService.loadCompletedTotals(
      category: 'countries',
      subcategories:
          _subcategories.map((item) => item.firebaseKey),
    );

    final Map<String, int> updatedCompletedTotals =
        Map<String, int>.from(savedCompletedTotals);

    for (final _CountriesSubcategoryData item in _subcategories) {
      final int totalQuestions = _totalFor(item);
      final int playedQuestions = _playedFor(item);

      if (totalQuestions > 0 &&
          playedQuestions >= totalQuestions) {
        await SubcategoryCompletionHistoryService.recordCompletion(
          category: 'countries',
          subcategory: item.firebaseKey,
          totalQuestions: totalQuestions,
        );

        updatedCompletedTotals[item.firebaseKey] =
            totalQuestions;
      }
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _completedQuestionTotals =
          updatedCompletedTotals;
    });
  }

  int _totalFor(_CountriesSubcategoryData item) {
    final int liveTotal =
        _liveQuestionCounts[item.firebaseKey] ?? 0;

    return liveTotal > 0 ? liveTotal : item.total;
  }

  int _playedFor(_CountriesSubcategoryData item) {
    final int played = item.idPrefix == null
        ? item.played
        : (_playedCounts[item.title] ?? 0);

    final int total = _totalFor(item);
    return played > total ? total : played;
  }

  SubcategoryProgressStatus _statusFor(
    _CountriesSubcategoryData item,
  ) {
    final int played = _playedFor(item);
    final int total = _totalFor(item);
    final int completedTotal =
        _completedQuestionTotals[item.firebaseKey] ?? 0;

    final bool hadPreviouslyCompleted =
        SubcategoryCompletionHistoryService
            .hasNewQuestionsSinceCompletion(
      completedTotal: completedTotal,
      playedQuestions: played,
      totalQuestions: total,
    );

    return SubcategoryProgressStatus.resolve(
      isAvailable: total > 0,
      playedQuestions: played,
      totalQuestions: total,
      hadPreviouslyCompleted: hadPreviouslyCompleted,
    );
  }

  Future<void> _openCategorySurprise() async {
    if (_surpriseMeLoading) {
      return;
    }

    setState(() {
      _surpriseMeLoading = true;
    });

    try {
      final Set<String> playedIds =
          await QuestionHistoryService.loadPlayedQuestionIds();

      final FirebaseSurpriseSelection? selected =
          await FirebaseChallengeService
              .loadRandomLiveCategorySurpriseQuestion(
        category: 'countries',
        playedQuestionIds: playedIds,
      );

      if (!mounted) {
        return;
      }

      if (selected == null) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              backgroundColor: AppColors.panel,
              behavior: SnackBarBehavior.floating,
              content: Text(
                'No live Countries questions were found.',
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
          builder: (context) => GameScreen.firebaseDynamic(
            items: [selected.item],
            initialItem: selected.item,
            launchedFromSurpriseMe: true,
            showSurpriseToast: true,
          ),
        ),
      );

      if (mounted) {
        await _refreshScreenData();
      }
    } catch (error, stackTrace) {
      debugPrint('COUNTRIES SURPRISE ME ERROR: $error');
      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            backgroundColor: AppColors.panel,
            behavior: SnackBarBehavior.floating,
            content: Text(
              'Countries Surprise Me could not be loaded.',
              style: AppTextStyles.body.copyWith(
                color: AppColors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        );
    } finally {
      if (mounted) {
        setState(() {
          _surpriseMeLoading = false;
        });
      }
    }
  }

  Widget _buildSubcategoryCard(
    BuildContext context,
    _CountriesSubcategoryData item,
  ) {
    return _CountriesSubcategoryCard(
      data: item,
      played: _playedFor(item),
      total: _totalFor(item),
      status: _statusFor(item),
      onTap: () => _handleTap(context, item),
    );
  }

  int _orderedIndexForDisplay(
    BuildContext context,
    int displayIndex,
    int totalCards,
  ) {
    if (MediaQuery.sizeOf(context).width < 900) {
      return displayIndex;
    }

    final int rows = (totalCards + 1) ~/ 2;
    final int row = displayIndex ~/ 2;
    final int column = displayIndex % 2;

    return column == 0 ? row : rows + row;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ResponsiveSubcategoryPage(
            header: const ClassicCategoryHeader(title: 'COUNTRIES'),
            statsPanel: Padding(
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
            padding: const EdgeInsets.fromLTRB(
                  16,
                  4,
                  16,
                  28,
                ),
                itemCount: _subcategories.length + 1,
                separatorBuilder: (_, _) =>
                    const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final int orderedIndex =
                      _orderedIndexForDisplay(
                    context,
                    index,
                    _subcategories.length + 1,
                  );

                  if (orderedIndex == 0) {
                    return _CategorySurpriseCard(
                    isLoading: _surpriseMeLoading,
                    onTap: _openCategorySurprise,
                    description: 'Random Countries challenge',
                  );
                  }

                  return _buildSubcategoryCard(
                  context,
                  _subcategories[orderedIndex - 1],
                );
                },
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

    if (item.title == 'Flags') {
      try {
        final items =
            await FirebaseChallengeService.loadLiveSubcategory(
          category: 'countries',
          subcategory: 'flags',
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
                  'No live Flags questions were found.',
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
            builder: (context) => GameScreen.firebaseDynamic(
              items: items,
              subcategoryTitle: 'Flags',
              launchedFromSurpriseMe: false,
              showSurpriseToast: false,
            ),
          ),
        );

        if (mounted) {
          await _refreshScreenData();
        }
      } catch (error, stackTrace) {
        debugPrint(
          'FLAGS FIREBASE ERROR: $error',
        );
        debugPrintStack(
          stackTrace: stackTrace,
        );

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
                'Flags could not be loaded from Firebase.',
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

    if (item.title == 'Natural Wonders & Landscapes') {
      try {
        final items =
            await FirebaseChallengeService.loadLiveSubcategory(
          category: 'countries',
          subcategory: 'natural_wonders_landscapes',
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
                  'No live Natural Wonders & Landscapes questions were found.',
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
            builder: (context) => GameScreen.firebaseDynamic(
              items: items,
              subcategoryTitle: 'Natural Wonders & Landscapes',
              launchedFromSurpriseMe: false,
              showSurpriseToast: false,
            ),
          ),
        );

        if (mounted) {
          await _refreshScreenData();
        }
      } catch (error, stackTrace) {
        debugPrint(
          'NATURAL WONDERS FIREBASE ERROR: $error',
        );
        debugPrintStack(
          stackTrace: stackTrace,
        );

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
                'Natural Wonders & Landscapes could not be loaded from Firebase.',
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

    if (item.title == 'National Symbols') {
      try {
        final items =
            await FirebaseChallengeService.loadLiveSubcategory(
          category: 'countries',
          subcategory: 'national_symbols',
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
                  'No live National Symbols questions were found.',
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
            builder: (context) => GameScreen.firebaseDynamic(
              items: items,
              subcategoryTitle: 'National Symbols',
              launchedFromSurpriseMe: false,
              showSurpriseToast: false,
            ),
          ),
        );

        if (mounted) {
          await _refreshScreenData();
        }
      } catch (error, stackTrace) {
        debugPrint(
          'NATIONAL SYMBOLS FIREBASE ERROR: $error',
        );
        debugPrintStack(
          stackTrace: stackTrace,
        );

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
                'National Symbols could not be loaded from Firebase.',
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

    if (item.title == 'States & Regions') {
      try {
        final items =
            await FirebaseChallengeService.loadLiveSubcategory(
          category: 'countries',
          subcategory: 'states_regions',
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
                  'No live States & Regions questions were found.',
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
            builder: (context) => GameScreen.firebaseDynamic(
              items: items,
              subcategoryTitle: 'States & Regions',
              launchedFromSurpriseMe: false,
              showSurpriseToast: false,
            ),
          ),
        );

        if (mounted) {
          await _refreshScreenData();
        }
      } catch (error, stackTrace) {
        debugPrint(
          'STATES & REGIONS FIREBASE ERROR: $error',
        );
        debugPrintStack(
          stackTrace: stackTrace,
        );

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
                'States & Regions could not be loaded from Firebase.',
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
    final SubcategoryProgressStatus progressStatus =
        _statusFor(item);

    switch (progressStatus.state) {
      case SubcategoryProgressState.comingSoon:
        message = '${item.title} is coming soon.';
        break;
      case SubcategoryProgressState.start:
        message = 'Start ${item.title}.';
        break;
      case SubcategoryProgressState.continuePlaying:
        message =
            'Continue ${item.title}: ${_playedFor(item)} of ${_totalFor(item)} played.';
        break;
      case SubcategoryProgressState.newQuestions:
        message =
            'New questions are waiting in ${item.title}.';
        break;
      case SubcategoryProgressState.completed:
        message =
            'You have completed all current ${item.title} questions.';
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

class _CategorySurpriseCard extends StatelessWidget {
  const _CategorySurpriseCard({
    required this.isLoading,
    required this.onTap,
    required this.description,
  });

  final bool isLoading;
  final VoidCallback onTap;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: isLoading ? null : onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          padding: const EdgeInsets.fromLTRB(12, 13, 12, 13),
          decoration: BoxDecoration(
            color: AppColors.panel,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: AppColors.orange,
              width: 1.4,
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
                  padding: const EdgeInsets.all(6),
                  child: Image.asset(
                    'assets/images/categories/surprise_me.webp',
                    width: 52,
                    height: 52,
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.high,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Surprise Me',
                      style: AppTextStyles.category.copyWith(
                        color: AppColors.white,
                        fontSize: subcategoryTitleFontSize(context),
                        fontWeight: FontWeight.w600,
                        height: 1.08,
                        letterSpacing: 0.1,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      isLoading ? 'Picking a challenge...' : description,
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.white,
                        fontSize: subcategoryProgressFontSize(context),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              SubcategoryStatusBadge(
                text: isLoading ? 'PICKING...' : 'PLAY',
                color: AppColors.orange,
                filled: true,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CountriesSubcategoryCard extends StatelessWidget {
  const _CountriesSubcategoryCard({
    required this.data,
    required this.played,
    required this.total,
    required this.status,
    required this.onTap,
  });

  final _CountriesSubcategoryData data;
  final int played;
  final int total;
  final SubcategoryProgressStatus status;
  final VoidCallback onTap;

  static const Color _progressTrack = Color(0xFF2B2B2B);

  @override
  Widget build(BuildContext context) {
    final double progress = total == 0
        ? 0
        : (played / total).clamp(0.0, 1.0);

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
                        fontSize: subcategoryTitleFontSize(context),
                        fontWeight: FontWeight.w600,
                        height: 1.08,
                        letterSpacing: 0.1,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      '$played of $total played',
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.white,
                        fontSize: subcategoryProgressFontSize(context),
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
                  minWidth: 118,
                  maxWidth: 150,
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
    final bool isCompleted =
        status.state == SubcategoryProgressState.completed;

    return Align(
      alignment: Alignment.centerRight,
      child: SubcategoryStatusBadge(
        text: status.ctaLabel,
        color: isCompleted
            ? AppColors.darkGrey
            : AppColors.orange,
        filled: true,
      ),
    );
  }

}

class _CountriesSubcategoryData {
  const _CountriesSubcategoryData({
    required this.title,
    required this.imagePath,
    required this.played,
    required this.total,
    required this.status,
    required this.firebaseKey,
    this.idPrefix,
  });

  final String title;
  final String imagePath;
  final int played;
  final int total;
  final SubcategoryProgressStatus status;
  final String firebaseKey;
  final String? idPrefix;
}
