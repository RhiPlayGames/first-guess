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

class BooksAuthorsSubcategoryScreen extends StatefulWidget {
  const BooksAuthorsSubcategoryScreen({super.key});

  @override
  State<BooksAuthorsSubcategoryScreen> createState() =>
      _BooksAuthorsSubcategoryScreenState();
}

class _BooksAuthorsSubcategoryScreenState
    extends State<BooksAuthorsSubcategoryScreen> {
  static const List<_BooksAuthorsSubcategory> _items =
      <_BooksAuthorsSubcategory>[
    _BooksAuthorsSubcategory(
          'Authors, Poets & Playwrights',
          Icons.edit_rounded,
          firebaseKey: 'authors_poets_playwrights',
          imagePath:
              'assets/images/categories/subcategories/books_authors/authors.webp',
        ),
    _BooksAuthorsSubcategory(
          'Book Series',
          Icons.library_books_rounded,
          firebaseKey: 'book_series',
          imagePath:
              'assets/images/categories/subcategories/books_authors/book_series.webp',
        ),
    _BooksAuthorsSubcategory(
          'Books & Novels',
          Icons.menu_book_rounded,
          firebaseKey: 'books_novels',
          imagePath:
              'assets/images/categories/subcategories/books_authors/books_novels.webp',
        ),
    _BooksAuthorsSubcategory(
          'Children’s Books',
          Icons.child_care_rounded,
          firebaseKey: 'childrens_books',
          imagePath:
              'assets/images/categories/subcategories/books_authors/childrens_books.webp',
        ),
    _BooksAuthorsSubcategory(
          'Fictional Literary Locations',
          Icons.castle_rounded,
          firebaseKey: 'fictional_literary_locations',
          imagePath:
              'assets/images/categories/subcategories/books_authors/fictional_literary_locations.webp',
        ),
    _BooksAuthorsSubcategory(
          'Folk Tales & Fairy Tales',
          Icons.auto_awesome_rounded,
          firebaseKey: 'folk_tales_fairy_tales',
          imagePath:
              'assets/images/categories/subcategories/books_authors/folk_tales_fairy_tales.webp',
        ),
    _BooksAuthorsSubcategory(
          'Graphic Novels & Comics',
          Icons.auto_stories_rounded,
          firebaseKey: 'graphic_novels_comics',
          imagePath:
              'assets/images/categories/subcategories/books_authors/graphic_novels_comics.webp',
        ),
    _BooksAuthorsSubcategory(
          'Literary Genres',
          Icons.category_rounded,
          firebaseKey: 'literary_genres',
          imagePath:
              'assets/images/categories/subcategories/books_authors/literary_genres.webp',
        ),
    _BooksAuthorsSubcategory(
          'Opening Lines & Quotations',
          Icons.format_quote_rounded,
          firebaseKey: 'opening_lines_quotations',
          imagePath:
              'assets/images/categories/subcategories/books_authors/opening_lines.webp',
        ),
    _BooksAuthorsSubcategory(
          'Plays',
          Icons.theater_comedy_rounded,
          firebaseKey: 'plays',
          imagePath:
              'assets/images/categories/subcategories/books_authors/plays.webp',
        ),
    _BooksAuthorsSubcategory(
          'Poems',
          Icons.auto_stories_rounded,
          firebaseKey: 'poems',
          imagePath:
              'assets/images/categories/subcategories/books_authors/poems.webp',
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

    for (final _BooksAuthorsSubcategory item in _items) {
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
      category: 'books_authors',
      subcategories:
          _items.map((item) => item.firebaseKey),
    );

    final Map<String, int> updatedCompletedTotals =
        Map<String, int>.from(savedCompletedTotals);

    for (final _BooksAuthorsSubcategory item in _items) {
      final int totalQuestions =
          _liveQuestionCounts[item.firebaseKey] ?? 0;
      final int playedQuestions =
          _playedQuestionCounts[item.firebaseKey] ?? 0;

      if (totalQuestions > 0 &&
          playedQuestions >= totalQuestions) {
        await SubcategoryCompletionHistoryService
            .recordCompletion(
          category: 'books_authors',
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
        category: 'books_authors',
      );

      if (!mounted) {
        return;
      }

      final Set<String> knownKeys =
          _items.map((_BooksAuthorsSubcategory item) => item.firebaseKey).toSet();
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

  Future<void> _openSubcategory(
    _BooksAuthorsSubcategory item,
  ) async {
    if (!_liveFirebaseSubcategories.contains(item.firebaseKey)) {
      return;
    }

    try {
      final items =
          await FirebaseChallengeService.loadLiveSubcategory(
        category: 'books_authors',
        subcategory: item.firebaseKey,
      );

      if (!mounted) {
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
                'No live ${item.title} questions were found.',
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
            subcategoryTitle: item.title,
            launchedFromSurpriseMe: false,
            showSurpriseToast: false,
          ),
        ),
      );

      if (mounted) {
        await _refreshSubcategoryProgress();
      }
    } catch (_) {
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
              '${item.title} could not be loaded from Firebase.',
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
        category: 'books_authors',
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
                'No live Books & Authors questions were found.',
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
        await _refreshSubcategoryProgress();
      }
    } catch (error, stackTrace) {
      debugPrint('BOOKS & AUTHORS SURPRISE ME ERROR: $error');
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
              'Books & Authors Surprise Me could not be loaded.',
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
    _BooksAuthorsSubcategory item,
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

    return _BooksAuthorsCard(
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
            header: const ClassicCategoryHeader(title: 'BOOKS & AUTHORS'),
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
                    return _CategorySurpriseCard(
                    isLoading: _surpriseMeLoading,
                    onTap: _openCategorySurprise,
                    description: 'Random Books & Authors challenge',
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

class _BooksAuthorsCard extends StatelessWidget {
  const _BooksAuthorsCard({
    required this.item,
    required this.isAvailable,
    required this.totalQuestions,
    required this.playedQuestions,
    required this.hadPreviouslyCompleted,
    required this.onTap,
  });

  final _BooksAuthorsSubcategory item;
  final bool isAvailable;
  final int totalQuestions;
  final int playedQuestions;
  final bool hadPreviouslyCompleted;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: isAvailable ? onTap : null,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          padding: const EdgeInsets.fromLTRB(12, 13, 12, 13),
          decoration: BoxDecoration(
            color: AppColors.panel,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color:
                  isAvailable ? AppColors.orange : AppColors.darkGrey,
              width: isAvailable ? 1.4 : 1,
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
                child: item.imagePath != null
                    ? Padding(
                        padding: const EdgeInsets.all(6),
                        child: Image.asset(
                          item.imagePath!,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) => Icon(
                            item.icon,
                            color: AppColors.orange,
                            size: 36,
                          ),
                        ),
                      )
                    : Icon(
                        item.icon,
                        color: AppColors.orange,
                        size: 36,
                      ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
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
                      '${playedQuestions > totalQuestions ? totalQuestions : playedQuestions} of $totalQuestions played',
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
              Builder(
                builder: (context) {
                  final SubcategoryProgressStatus progressStatus =
                      SubcategoryProgressStatus.resolve(
                    isAvailable: isAvailable,
                    playedQuestions: playedQuestions,
                    totalQuestions: totalQuestions,
                    hadPreviouslyCompleted:
                        hadPreviouslyCompleted,
                  );

                  final bool isCompleted =
                      progressStatus.state ==
                          SubcategoryProgressState.completed;

                  return SubcategoryStatusBadge(
                    text: progressStatus.ctaLabel,
                    color: !isAvailable
                        ? AppColors.white
                        : isCompleted
                            ? AppColors.darkGrey
                            : AppColors.orange,
                    filled: isAvailable,
                  );
                },
              )
            ],
          ),
        ),
      ),
    );
  }
}

class _BooksAuthorsSubcategory {
  const _BooksAuthorsSubcategory(
    this.title,
    this.icon, {
    required this.firebaseKey,
    this.imagePath,
  });

  final String title;
  final IconData icon;
  final String firebaseKey;
  final String? imagePath;
}
