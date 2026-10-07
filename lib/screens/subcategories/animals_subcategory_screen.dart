import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../models/quiz_item.dart';
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

class AnimalsSubcategoryScreen extends StatefulWidget {
  const AnimalsSubcategoryScreen({super.key});

  @override
  State<AnimalsSubcategoryScreen> createState() =>
      _AnimalsSubcategoryScreenState();
}

class _AnimalsSubcategoryScreenState
    extends State<AnimalsSubcategoryScreen> {
  static const List<_AnimalSubcategory> _items = [
    _AnimalSubcategory(
          'Birds',
          'assets/images/categories/subcategories/animals/birds.webp',
          firebaseKey: 'birds',
        ),
    _AnimalSubcategory(
          'Dinosaurs',
          'assets/images/categories/subcategories/animals/dinosaurs.webp',
          firebaseKey: 'dinosaurs',
        ),
    _AnimalSubcategory(
          'Habitats & Animal Groups',
          'assets/images/categories/subcategories/animals/habitats_animal_groups.webp',
          firebaseKey: 'habitats_animal_groups',
        ),
    _AnimalSubcategory(
          'Insects & Spiders',
          'assets/images/categories/subcategories/animals/insects.webp',
          firebaseKey: 'insects_spiders',
        ),
    _AnimalSubcategory(
          'Jungle & Safari Animals',
          'assets/images/categories/subcategories/animals/safari.webp',
          firebaseKey: 'jungle_safari_animals',
        ),
    _AnimalSubcategory(
          'Mammals',
          'assets/images/categories/subcategories/animals/mammals.webp',
          firebaseKey: 'mammals',
        ),
    _AnimalSubcategory(
          'Reptiles & Amphibians',
          'assets/images/categories/subcategories/animals/reptiles.webp',
          firebaseKey: 'reptiles_amphibians',
        ),
    _AnimalSubcategory(
          'Sea Creatures',
          'assets/images/categories/subcategories/animals/sea_creatures.webp',
          firebaseKey: 'sea_creatures',
        ),
    _AnimalSubcategory(
          'Tracks & Footprints',
          'assets/images/categories/subcategories/animals/tracks.webp',
          firebaseKey: 'tracks_footprints',
        ),
  ];

  Set<String> _liveFirebaseSubcategories = <String>{};
  Map<String, int> _liveQuestionCounts = <String, int>{};
  Map<String, Set<String>> _liveQuestionIds = <String, Set<String>>{};
  Map<String, int> _playedQuestionCounts = <String, int>{};
  Map<String, int> _completedQuestionTotals = <String, int>{};

  PlayerStats _playerStats = const PlayerStats();
  bool _statsLoaded = false;
  bool _surpriseMeLoading = false;

  @override
  void initState() {
    super.initState();
    _refreshSubcategoryProgress();
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

  Future<void> _refreshSubcategoryProgress() async {
    await Future.wait<void>(<Future<void>>[
      _loadPlayerStats(),
      _loadFirebaseSubcategoryAvailability(),
    ]);

    if (!mounted) {
      return;
    }

    await _loadPlayedQuestionCounts();

    if (!mounted) {
      return;
    }

    await _loadAndUpdateCompletionSnapshots();
  }

  Future<void> _loadPlayedQuestionCounts() async {
    final Set<String> playedIds =
        await QuestionHistoryService.loadPlayedQuestionIds();

    if (!mounted) {
      return;
    }

    final Map<String, int> counts = <String, int>{};

    for (final _AnimalSubcategory item in _items) {
      final Set<String> liveIds =
          _liveQuestionIds[item.firebaseKey] ?? <String>{};

      counts[item.firebaseKey] =
          liveIds.where(playedIds.contains).length;
    }

    setState(() {
      _playedQuestionCounts = counts;
    });
  }

  Future<void> _loadAndUpdateCompletionSnapshots() async {
    final Map<String, int> savedCompletedTotals =
        await SubcategoryCompletionHistoryService
            .loadCompletedTotals(
      category: 'animals',
      subcategories:
          _items.map((item) => item.firebaseKey),
    );

    final Map<String, int> updatedCompletedTotals =
        Map<String, int>.from(savedCompletedTotals);

    for (final _AnimalSubcategory item in _items) {
      final int totalQuestions =
          _liveQuestionCounts[item.firebaseKey] ?? 0;

      final int playedQuestions =
          _playedQuestionCounts[item.firebaseKey] ?? 0;

      if (totalQuestions > 0 &&
          playedQuestions >= totalQuestions) {
        await SubcategoryCompletionHistoryService
            .recordCompletion(
          category: 'animals',
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

  Future<void> _loadFirebaseSubcategoryAvailability() async {
    try {
      final List<QueryDocumentSnapshot<Map<String, dynamic>>> documents =
          await FirebaseChallengeService.loadLiveCategoryDocuments(
        category: 'animals',
      );

      if (!mounted) {
        return;
      }

      final Set<String> knownKeys =
          _items.map((_AnimalSubcategory item) => item.firebaseKey).toSet();
      final Set<String> liveSubcategories = <String>{};
      final Map<String, int> liveQuestionCounts = <String, int>{
        for (final String key in knownKeys) key: 0,
      };
      final Map<String, Set<String>> liveQuestionIds =
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

        liveQuestionIds[subcategory]!.add(document.id);
      }

      for (final String key in knownKeys) {
        final int count = liveQuestionIds[key]!.length;
        liveQuestionCounts[key] = count;

        if (count > 0) {
          liveSubcategories.add(key);
        }
      }

      setState(() {
        _liveFirebaseSubcategories = liveSubcategories;
        _liveQuestionCounts = liveQuestionCounts;
        _liveQuestionIds = liveQuestionIds;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _liveFirebaseSubcategories = <String>{};
        _liveQuestionCounts = <String, int>{};
        _liveQuestionIds = <String, Set<String>>{};
      });
    }
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
        category: 'animals',
        playedQuestionIds: playedIds,
      );

      if (!mounted) {
        return;
      }

      if (selected == null) {
        _showNoQuestionsMessage('Animals');
        return;
      }

      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (context) => GameScreen.firebaseDynamic(
            items: <QuizItem>[selected.item],
            initialItem: selected.item,
            launchedFromSurpriseMe: true,
            showSurpriseToast: true,
          ),
        ),
      );

      if (mounted) {
        await _refreshSubcategoryProgress();
      }
    } catch (error, stackTrace) {
      debugPrint(
        'ANIMALS SURPRISE ME ERROR: $error',
      );

      debugPrintStack(
        stackTrace: stackTrace,
      );

      if (!mounted) {
        return;
      }

      _showLoadErrorMessage('Animals Surprise Me');
    } finally {
      if (mounted) {
        setState(() {
          _surpriseMeLoading = false;
        });
      }
    }
  }

  Future<void> _openSubcategory(
    _AnimalSubcategory item,
  ) async {
    if (!_liveFirebaseSubcategories.contains(
      item.firebaseKey,
    )) {
      return;
    }

    if (item.firebaseKey == 'birds') {
      await _openBirds();
      return;
    }

    if (item.firebaseKey == 'dinosaurs') {
      await _openDinosaurs();
      return;
    }

    await _openDynamicFirebaseSubcategory(item);
  }

  Future<void> _openBirds() async {
    try {
      final items =
          await FirebaseChallengeService
              .loadLiveSubcategory(
        category: 'animals',
        subcategory: 'birds',
      );

      if (!mounted) {
        return;
      }

      if (items.isEmpty) {
        _showNoQuestionsMessage('Birds');
        return;
      }

      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (context) => GameScreen.birds(
            items: items,
          ),
        ),
      );

      if (mounted) {
        await _refreshSubcategoryProgress();
      }
    } catch (error, stackTrace) {
      debugPrint(
        'ANIMALS BIRDS OPEN ERROR: $error',
      );

      debugPrintStack(
        stackTrace: stackTrace,
      );

      if (!mounted) {
        return;
      }

      _showLoadErrorMessage('Birds');
    }
  }

  Future<void> _openDinosaurs() async {
    try {
      final items =
          await FirebaseChallengeService
              .loadLiveSubcategory(
        category: 'animals',
        subcategory: 'dinosaurs',
      );

      if (!mounted) {
        return;
      }

      if (items.isEmpty) {
        _showNoQuestionsMessage('Dinosaurs');
        return;
      }

      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (context) =>
              GameScreen.dinosaurs(
            items: items,
          ),
        ),
      );

      if (mounted) {
        await _refreshSubcategoryProgress();
      }
    } catch (error, stackTrace) {
      debugPrint(
        'ANIMALS DINOSAURS OPEN ERROR: $error',
      );

      debugPrintStack(
        stackTrace: stackTrace,
      );

      if (!mounted) {
        return;
      }

      _showLoadErrorMessage('Dinosaurs');
    }
  }

  Future<void> _openDynamicFirebaseSubcategory(
    _AnimalSubcategory item,
  ) async {
    try {
      final items =
          await FirebaseChallengeService
              .loadLiveSubcategory(
        category: 'animals',
        subcategory: item.firebaseKey,
      );

      if (!mounted) {
        return;
      }

      if (items.isEmpty) {
        _showNoQuestionsMessage(item.title);
        return;
      }

      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (context) =>
              GameScreen.firebaseDynamic(
            items: items,
            subcategoryTitle: item.title,
            launchedFromSurpriseMe: false,
            showSurpriseToast: false,
          ),
        ),
      );

      if (mounted) {
        await _refreshSubcategoryProgress();
      }
    } catch (error, stackTrace) {
      debugPrint(
        'ANIMALS ${item.firebaseKey} OPEN ERROR: $error',
      );

      debugPrintStack(
        stackTrace: stackTrace,
      );

      if (!mounted) {
        return;
      }

      _showLoadErrorMessage(item.title);
    }
  }

  void _showNoQuestionsMessage(
    String title,
  ) {
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
            'No live $title questions were found.',
            style: AppTextStyles.body.copyWith(
              color: AppColors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
  }

  void _showLoadErrorMessage(
    String title,
  ) {
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
            '$title could not be loaded from Firebase.',
            style: AppTextStyles.body.copyWith(
              color: AppColors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
  }

  Widget _buildSubcategoryCard(
    _AnimalSubcategory item,
  ) {
    final bool isAvailable =
        _liveFirebaseSubcategories.contains(item.firebaseKey);

    final int totalQuestions =
        _liveQuestionCounts[item.firebaseKey] ?? 0;

    final int playedQuestions =
        _playedQuestionCounts[item.firebaseKey] ?? 0;

    final int completedTotal =
        _completedQuestionTotals[item.firebaseKey] ?? 0;

    final bool hadPreviouslyCompleted =
        SubcategoryCompletionHistoryService
            .hasNewQuestionsSinceCompletion(
      completedTotal: completedTotal,
      playedQuestions: playedQuestions,
      totalQuestions: totalQuestions,
    );

    return _AnimalCard(
      item: item,
      isAvailable: isAvailable,
      totalQuestions: totalQuestions,
      playedQuestions: playedQuestions,
      hadPreviouslyCompleted: hadPreviouslyCompleted,
      onTap: () => _openSubcategory(item),
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
            header: const ClassicCategoryHeader(title: 'ANIMALS'),
            statsPanel: Padding(
              padding:
                  const EdgeInsets.fromLTRB(
                16,
                0,
                16,
                14,
              ),
              child: StatsPanel(
                totalScore:
                    _statsLoaded
                        ? _playerStats.totalScore
                        : 0,
                currentStreak:
                    _statsLoaded
                        ? _playerStats.currentStreak
                        : 0,
                firstGuesses:
                    _statsLoaded
                        ? _playerStats.firstGuesses
                        : 0,
                gamesPlayed:
                    _statsLoaded
                        ? _playerStats.gamesPlayed
                        : 0,
              ),
            ),
            padding: const EdgeInsets.fromLTRB(
                  16,
                  4,
                  16,
                  28,
                ),
                itemCount: _items.length + 1,
                separatorBuilder: (_, _) =>
                    const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final int orderedIndex =
                      _orderedIndexForDisplay(
                    context,
                    index,
                    _items.length + 1,
                  );

                  if (orderedIndex == 0) {
                    return _AnimalSurpriseCard(
                    isLoading: _surpriseMeLoading,
                    onTap: _openCategorySurprise,
                  );
                  }

                  return _buildSubcategoryCard(
                  _items[orderedIndex - 1],
                );
                },
        ),
      ),
    );
  }
}

class _AnimalSurpriseCard extends StatelessWidget {
  const _AnimalSurpriseCard({
    required this.isLoading,
    required this.onTap,
  });

  final bool isLoading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: isLoading ? null : onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          padding: const EdgeInsets.fromLTRB(
            12,
            13,
            12,
            13,
          ),
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
                      isLoading
                          ? 'Picking an Animals question...'
                          : 'Random Animals challenge',
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

class _AnimalCard extends StatelessWidget {
  const _AnimalCard({
    required this.item,
    required this.isAvailable,
    required this.totalQuestions,
    required this.playedQuestions,
    required this.hadPreviouslyCompleted,
    required this.onTap,
  });

  final _AnimalSubcategory item;
  final bool isAvailable;
  final int totalQuestions;
  final int playedQuestions;
  final bool hadPreviouslyCompleted;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius:
          BorderRadius.circular(18),
      child: InkWell(
        onTap:
            isAvailable ? onTap : null,
        borderRadius:
            BorderRadius.circular(18),
        child: Ink(
          padding:
              const EdgeInsets.fromLTRB(
            12,
            13,
            12,
            13,
          ),
          decoration: BoxDecoration(
            color: AppColors.panel,
            borderRadius:
                BorderRadius.circular(
              18,
            ),
            border: Border.all(
              color: isAvailable
                  ? AppColors.orange
                  : AppColors.darkGrey,
              width:
                  isAvailable
                      ? 1.4
                      : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 64,
                height: 64,
                alignment:
                    Alignment.center,
                decoration:
                    BoxDecoration(
                  color:
                      AppColors.background,
                  borderRadius:
                      BorderRadius.circular(
                    16,
                  ),
                  border:
                      Border.all(
                    color:
                        AppColors.orange,
                    width: 1.2,
                  ),
                ),
                child: Padding(
                  padding:
                      const EdgeInsets.all(
                    6,
                  ),
                  child: Image.asset(
                    item.imagePath,
                    width: 52,
                    height: 52,
                    fit:
                        BoxFit.contain,
                    filterQuality:
                        FilterQuality.high,
                  ),
                ),
              ),
              const SizedBox(
                width: 14,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment
                          .start,
                  children: [
                    Text(
                      item.title,
                      maxLines: 2,
                      overflow:
                          TextOverflow
                              .ellipsis,
                      style:
                          AppTextStyles
                              .category
                              .copyWith(
                        color:
                            AppColors.white,
                        fontSize: subcategoryTitleFontSize(context),
                        fontWeight:
                            FontWeight
                                .w600,
                        height: 1.08,
                        letterSpacing:
                            0.1,
                      ),
                    ),
                    const SizedBox(
                      height: 7,
                    ),
                    Text(
                      '${playedQuestions > totalQuestions ? totalQuestions : playedQuestions} of $totalQuestions played',
                      style:
                          AppTextStyles
                              .body
                              .copyWith(
                        color:
                            AppColors.white,
                        fontSize: subcategoryProgressFontSize(context),
                        fontWeight:
                            FontWeight
                                .w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(
                width: 12,
              ),
              SubcategoryStatusBadge(
                text:
                    SubcategoryProgressStatus
                        .resolve(
                  isAvailable:
                      isAvailable,
                  playedQuestions:
                      playedQuestions,
                  totalQuestions:
                      totalQuestions,
                  hadPreviouslyCompleted:
                      hadPreviouslyCompleted,
                ).ctaLabel,
                color: isAvailable
                    ? AppColors.orange
                    : AppColors.white,
                filled:
                    isAvailable,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AnimalSubcategory {
  const _AnimalSubcategory(
    this.title,
    this.imagePath, {
    required this.firebaseKey,
  });

  final String title;
  final String imagePath;
  final String firebaseKey;
}
