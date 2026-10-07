import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../case_files/screens/case_files_home_screen.dart';
import '../models/quiz_item.dart';
import '../services/firebase_challenge_service.dart';
import '../services/player_stats_service.dart';
import '../services/subcategory_progress_status.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/app_home_button.dart';
import 'game_screen.dart';
import 'subcategories/animals_subcategory_screen.dart';
import 'subcategories/books_authors_subcategory_screen.dart';
import 'subcategories/countries_subcategory_screen.dart';
import 'subcategories/creative_world_subcategory_screen.dart';
import 'subcategories/famous_people_subcategory_screen.dart';
import 'subcategories/famous_words_subcategory_screen.dart';
import 'subcategories/food_drink_subcategory_screen.dart';
import 'subcategories/music_subcategory_screen.dart';
import 'subcategories/past_present_subcategory_screen.dart';
import 'subcategories/science_nature_subcategory_screen.dart';
import 'subcategories/sports_subcategory_screen.dart';
import 'subcategories/watch_play_subcategory_screen.dart';

class ClassicFirstGuessScreen extends StatefulWidget {
  const ClassicFirstGuessScreen({super.key});

  @override
  State<ClassicFirstGuessScreen> createState() =>
      _ClassicFirstGuessScreenState();
}

class _ClassicFirstGuessScreenState extends State<ClassicFirstGuessScreen> {
  Map<String, int> _categoryLiveTotals = <String, int>{};
  Map<String, int> _categoryPlayedTotals = <String, int>{};
  Map<String, int> _categoryCompletedTotals = <String, int>{};
  bool _surpriseMeLoading = false;

  static const List<String> _trackedCategories = <String>[
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
  ];

  @override
  void initState() {
    super.initState();
    _loadCategoryProgress();
  }

  Future<void> _openSurpriseGame() async {
    if (_surpriseMeLoading) {
      return;
    }

    setState(() {
      _surpriseMeLoading = true;
    });

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          duration: Duration(seconds: 2),
          content: Text(
            'Picking your Surprise Me question...',
          ),
        ),
      );

    try {
      final Set<String> playedIds =
          await QuestionHistoryService.loadPlayedQuestionIds();

      if (!mounted) {
        return;
      }

      final FirebaseSurpriseSelection? selected =
          await FirebaseChallengeService.loadRandomLiveSurpriseQuestion(
        playedQuestionIds: playedIds,
      );

      if (!mounted) {
        return;
      }

      if (selected == null) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(
              content: Text(
                "You've played all available Surprise Me questions.",
              ),
            ),
          );
        return;
      }

      ScaffoldMessenger.of(context).hideCurrentSnackBar();

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

    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              'Surprise Me could not load a live question.',
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

  void _openCaseFiles() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => const CaseFilesHomeScreen(),
      ),
    );
  }

  Future<void> _loadCategoryProgress() async {
    try {
      final QuerySnapshot<Map<String, dynamic>> snapshot =
          await FirebaseFirestore.instance
              .collection('challenges')
              .where('status', isEqualTo: 'live')
              .get();

      final Set<String> playedIds =
          await QuestionHistoryService.loadPlayedQuestionIds();

      final Map<String, Set<String>> liveIdsByCategory =
          <String, Set<String>>{};

      for (final QueryDocumentSnapshot<Map<String, dynamic>> doc
          in snapshot.docs) {
        final String category =
            (doc.data()['category'] ?? '').toString();

        if (category.isEmpty) {
          continue;
        }

        liveIdsByCategory
            .putIfAbsent(category, () => <String>{})
            .add(doc.id);
      }

      final Map<String, int> liveTotals = <String, int>{};
      final Map<String, int> playedTotals = <String, int>{};

      for (final String category in _trackedCategories) {
        final Set<String> ids =
            liveIdsByCategory[category] ?? <String>{};

        liveTotals[category] = ids.length;
        playedTotals[category] =
            ids.where(playedIds.contains).length;
      }

      final Map<String, int> savedCompletedTotals =
          await CategoryCompletionHistoryService.loadCompletedTotals(
        categories: _trackedCategories,
      );

      final Map<String, int> updatedCompletedTotals =
          Map<String, int>.from(savedCompletedTotals);

      for (final String category in _trackedCategories) {
        final int total = liveTotals[category] ?? 0;
        final int played = playedTotals[category] ?? 0;

        if (total > 0 && played >= total) {
          await CategoryCompletionHistoryService.recordCompletion(
            category: category,
            totalQuestions: total,
          );

          updatedCompletedTotals[category] = total;
        }
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _categoryLiveTotals = liveTotals;
        _categoryPlayedTotals = playedTotals;
        _categoryCompletedTotals = updatedCompletedTotals;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _categoryLiveTotals = <String, int>{};
        _categoryPlayedTotals = <String, int>{};
        _categoryCompletedTotals = <String, int>{};
      });
    }
  }

  String _categoryCtaLabel(String firebaseCategory) {
    final int total =
        _categoryLiveTotals[firebaseCategory] ?? 0;
    final int played =
        _categoryPlayedTotals[firebaseCategory] ?? 0;
    final int completedTotal =
        _categoryCompletedTotals[firebaseCategory] ?? 0;

    if (total <= 0) {
      return 'PLAY';
    }

    if (played >= total) {
      return 'COMPLETED';
    }

    final bool hasNewQuestions =
        CategoryCompletionHistoryService
            .hasNewQuestionsSinceCompletion(
      completedTotal: completedTotal,
      playedQuestions: played,
      totalQuestions: total,
    );

    if (hasNewQuestions) {
      return 'NEW QUESTIONS';
    }

    return 'PLAY';
  }

  Future<void> _openScreen(Widget screen) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => screen,
      ),
    );

    if (mounted) {
      await _loadCategoryProgress();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDesktop =
        MediaQuery.sizeOf(context).width >= 1200;

    final List<_ClassicCategoryData> categories =
        <_ClassicCategoryData>[
      _ClassicCategoryData(
        title: 'Surprise Me',
        subtitle: _surpriseMeLoading
            ? 'Picking your surprise...'
            : 'Let First Guess choose your challenge',
        imagePath: 'assets/images/categories/surprise_me.webp',
        firebaseCategory: '',
        onPressed: _surpriseMeLoading ? () {} : _openSurpriseGame,
      ),
      _ClassicCategoryData(
        title: 'Animals',
        subtitle: 'Explore mammals, birds, wildlife and more',
        imagePath: 'assets/images/categories/animals.webp',
        firebaseCategory: 'animals',
        onPressed: () => _openScreen(
          const AnimalsSubcategoryScreen(),
        ),
      ),
      _ClassicCategoryData(
        title: 'Books & Authors',
        subtitle: 'Explore books, writers, characters and literature',
        imagePath:
            'assets/images/categories/books_and_authors.webp',
        firebaseCategory: 'books_authors',
        onPressed: () => _openScreen(
          const BooksAuthorsSubcategoryScreen(),
        ),
      ),
      _ClassicCategoryData(
        title: 'Countries',
        subtitle: 'Explore countries, flags, cities, landmarks and more',
        imagePath: 'assets/images/categories/countries.webp',
        firebaseCategory: 'countries',
        onPressed: () => _openScreen(
          const CountriesSubcategoryScreen(),
        ),
      ),
      _ClassicCategoryData(
        title: 'Creative World',
        subtitle: 'Explore art, design, theatre and architecture',
        imagePath:
            'assets/images/categories/creative_world.webp',
        firebaseCategory: 'creative_world',
        onPressed: () => _openScreen(
          const CreativeWorldSubcategoryScreen(),
        ),
      ),
      _ClassicCategoryData(
        title: 'Famous Words',
        subtitle: 'Identify famous words, quotations and speeches',
        imagePath:
            'assets/images/categories/famous_words/famous_words.webp',
        firebaseCategory: 'famous_words',
        onPressed: () => _openScreen(
          const FamousWordsSubcategoryScreen(),
        ),
      ),
      _ClassicCategoryData(
        title: 'Food & Drink',
        subtitle: 'Explore dishes, ingredients, drinks and cuisines',
        imagePath:
            'assets/images/categories/food_and_drink.webp',
        firebaseCategory: 'food_drink',
        onPressed: () => _openScreen(
          const FoodDrinkSubcategoryScreen(),
        ),
      ),
      _ClassicCategoryData(
        title: 'Music',
        subtitle: 'Guess artists, songs, albums and instruments',
        imagePath: 'assets/images/categories/music.webp',
        firebaseCategory: 'music',
        onPressed: () => _openScreen(
          const MusicSubcategoryScreen(),
        ),
      ),
      _ClassicCategoryData(
        title: 'Past Worlds',
        subtitle:
            'Explore history, civilisations, legends and changing times',
        imagePath:
            'assets/images/categories/past_and_present.webp',
        firebaseCategory: 'past_present',
        onPressed: () => _openScreen(
          const PastPresentSubcategoryScreen(),
        ),
      ),
      _ClassicCategoryData(
        title: 'Science & Nature',
        subtitle: 'Explore science, nature, space and inventions',
        imagePath:
            'assets/images/categories/science_and_nature.webp',
        firebaseCategory: 'science_nature',
        onPressed: () => _openScreen(
          const ScienceNatureSubcategoryScreen(),
        ),
      ),
      _ClassicCategoryData(
        title: 'Sports',
        subtitle:
            'Identify teams, players, events and sporting moments',
        imagePath: 'assets/images/categories/sports.webp',
        firebaseCategory: 'sports',
        onPressed: () => _openScreen(
          const SportsSubcategoryScreen(),
        ),
      ),
      _ClassicCategoryData(
        title: 'Watch & Play',
        subtitle: 'Test your knowledge of film, television and games',
        imagePath:
            'assets/images/categories/watch_and_play.webp',
        firebaseCategory: 'watch_play',
        onPressed: () => _openScreen(
          const WatchPlaySubcategoryScreen(),
        ),
      ),
      _ClassicCategoryData(
        title: 'Who Am I?',
        subtitle: 'Recognise notable people from around the world',
        imagePath:
            'assets/images/categories/famous_people.webp',
        firebaseCategory: 'famous_people',
        onPressed: () => _openScreen(
          const FamousPeopleSubcategoryScreen(),
        ),
      ),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.white,
        elevation: 0,
        centerTitle: true,
        toolbarHeight: isDesktop ? 80 : 72,
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: Center(
              child: FirstGuessHomeButton(),
            ),
          ),
        ],
        title: Image.asset(
          'assets/images/categories/category_headers/classic_first_guess_logo.webp',
          height: isDesktop ? 76 : 64,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.high,
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            isDesktop ? 24 : 16,
            8,
            isDesktop ? 24 : 16,
            28,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: isDesktop ? 1360 : double.infinity,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _CaseFilesBanner(
                    onTap: _openCaseFiles,
                  ),
                  SizedBox(height: isDesktop ? 24 : 18),
                  _CategoryHeading(
                    isDesktop: isDesktop,
                  ),
                  SizedBox(height: isDesktop ? 16 : 12),
                  if (!isDesktop)
                    Column(
                      children: categories
                          .map(
                            (_ClassicCategoryData category) =>
                                Padding(
                              padding:
                                  const EdgeInsets.only(bottom: 12),
                              child: _ClassicCategoryCard(
                                category: category,
                                ctaLabel: _categoryCtaLabel(
                                  category.firebaseCategory,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    )
                  else
                    GridView.builder(
                      shrinkWrap: true,
                      physics:
                          const NeverScrollableScrollPhysics(),
                      itemCount: categories.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 14,
                        mainAxisSpacing: 12,
                        mainAxisExtent: 96,
                      ),
                      itemBuilder: (
                        BuildContext context,
                        int index,
                      ) {
                        final _ClassicCategoryData category =
                            categories[index];

                        return _ClassicCategoryCard(
                          category: category,
                          ctaLabel: _categoryCtaLabel(
                            category.firebaseCategory,
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}


class _CategoryHeading extends StatelessWidget {
  final bool isDesktop;

  const _CategoryHeading({
    required this.isDesktop,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          child: _CategoryHeadingLine(),
        ),
        SizedBox(width: isDesktop ? 16 : 10),
        Text(
          'CHOOSE A CATEGORY',
          textAlign: TextAlign.center,
          style: AppTextStyles.category.copyWith(
            color: AppColors.white,
            fontSize: isDesktop ? 22 : 18,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        SizedBox(width: isDesktop ? 16 : 10),
        const Expanded(
          child: _CategoryHeadingLine(
            reverse: true,
          ),
        ),
      ],
    );
  }
}

class _CategoryHeadingLine extends StatelessWidget {
  final bool reverse;

  const _CategoryHeadingLine({
    this.reverse = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1.5,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: reverse
              ? Alignment.centerRight
              : Alignment.centerLeft,
          end: reverse
              ? Alignment.centerLeft
              : Alignment.centerRight,
          colors: const [
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

class _CaseFilesBanner extends StatelessWidget {
  final VoidCallback onTap;

  const _CaseFilesBanner({
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.sizeOf(context).width;
    final bool isDesktop = width >= 1200;
    final bool useMobileArtwork = width < 600;

    final String assetPath = useMobileArtwork
        ? 'assets/images/case_files/new/casefileheader_mobile.webp'
        : 'assets/images/case_files/new/casefileheader_desktop.webp';

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(isDesktop ? 16 : 14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(isDesktop ? 15 : 13),
          child: Transform.scale(
            scale: isDesktop ? 1.0 : 1.055,
            child: Image.asset(
              assetPath,
              width: double.infinity,
              fit: BoxFit.contain,
              alignment: Alignment.center,
              filterQuality: FilterQuality.high,
            ),
          ),
        ),
      ),
    );
  }
}


class _ClassicCategoryData {
  final String title;
  final String subtitle;
  final String imagePath;
  final String firebaseCategory;
  final VoidCallback onPressed;

  const _ClassicCategoryData({
    required this.title,
    required this.subtitle,
    required this.imagePath,
    required this.firebaseCategory,
    required this.onPressed,
  });
}

class _ClassicCategoryCard extends StatelessWidget {
  final _ClassicCategoryData category;
  final String ctaLabel;

  const _ClassicCategoryCard({
    required this.category,
    required this.ctaLabel,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDesktop =
        MediaQuery.sizeOf(context).width >= 1200;
    final double radius = isDesktop ? 16 : 22;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(radius),
      child: InkWell(
        onTap: category.onPressed,
        borderRadius: BorderRadius.circular(radius),
        child: Ink(
          decoration: BoxDecoration(
            color: AppColors.panel,
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(
              color: AppColors.orange,
              width: 1.8,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x2BFE5E02),
                blurRadius: 12,
                spreadRadius: 0.5,
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isDesktop ? 12 : 14,
              vertical: isDesktop ? 10 : 14,
            ),
            child: Row(
              children: [
                Container(
                  width: isDesktop ? 58 : 60,
                  height: isDesktop ? 58 : 60,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius:
                        BorderRadius.circular(isDesktop ? 14 : 17),
                    border: Border.all(
                      color: AppColors.orange,
                      width: 1.4,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: ClipRRect(
                      borderRadius:
                          BorderRadius.circular(isDesktop ? 10 : 13),
                      child: Image.asset(
                        category.imagePath,
                        fit: BoxFit.contain,
                        filterQuality: FilterQuality.high,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: isDesktop ? 12 : 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        category.title.toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.category.copyWith(
                          color: AppColors.white,
                          fontSize: isDesktop ? 20 : 17,
                          letterSpacing: 0.15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        category.subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.body.copyWith(
                          color: AppColors.white,
                          fontSize: isDesktop ? 14.5 : 12,
                          height: 1.25,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: isDesktop ? 12 : 10),
                _ClassicDesktopCta(text: ctaLabel),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ClassicDesktopCta extends StatelessWidget {
  final String text;

  const _ClassicDesktopCta({
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    final bool isCompleted = text == 'COMPLETED';

    return Container(
      width: 118,
      height: 44,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isCompleted
            ? AppColors.darkGrey
            : AppColors.orange,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCompleted
              ? AppColors.darkGrey
              : AppColors.orange,
          width: 1.2,
        ),
      ),
      child: Text(
        text,
        maxLines: 1,
        textAlign: TextAlign.center,
        overflow: TextOverflow.ellipsis,
        style: AppTextStyles.label.copyWith(
          color: AppColors.white,
          fontSize: text == 'NEW QUESTIONS' ? 10 : 12.5,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.1,
        ),
      ),
    );
  }
}
