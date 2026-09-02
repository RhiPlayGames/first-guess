import 'dart:async';
import 'package:flutter/material.dart';

import '../case_files/screens/case_files_home_screen.dart';
import '../daily_flash/screens/daily_flash_loading_screen.dart';
import '../daily_flash/services/daily_flash_progress_service.dart';
import '../models/quiz_item.dart';
import '../services/avatar_preferences_service.dart';
import '../services/firebase_challenge_service.dart';
import '../services/player_stats_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/stats_panel.dart';
import 'game_screen.dart';
import 'profile_screen.dart';
import 'subcategories/countries_subcategory_screen.dart';
import 'subcategories/animals_subcategory_screen.dart';
import 'subcategories/food_drink_subcategory_screen.dart';
import 'subcategories/science_nature_subcategory_screen.dart';
import 'subcategories/books_authors_subcategory_screen.dart';
import 'subcategories/creative_world_subcategory_screen.dart';
import 'subcategories/famous_people_subcategory_screen.dart';
import 'subcategories/famous_words_subcategory_screen.dart';
import 'subcategories/music_subcategory_screen.dart';
import 'subcategories/sports_subcategory_screen.dart';
import 'subcategories/past_present_subcategory_screen.dart';
import 'subcategories/watch_play_subcategory_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? _selectedAvatarPath;

  bool _dailyFlashComplete = false;
  bool _surpriseMeLoading = false;

  PlayerStats _playerStats = const PlayerStats();
  bool _statsLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadSelectedAvatar();
    _loadPlayerStats();
    _loadDailyFlashStatus();
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

  Future<void> _loadDailyFlashStatus() async {
    try {
      final DailyFlashProgress progress =
          await DailyFlashProgressService.loadToday();

      if (!mounted) {
        return;
      }

      setState(() {
        _dailyFlashComplete = progress.allQuestionsAttempted;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _dailyFlashComplete = false;
      });
    }
  }

  Future<void> _openCountriesSubcategories() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => const CountriesSubcategoryScreen(),
      ),
    );

    if (mounted) {
      await _loadPlayerStats();
    }
  }

  Future<void> _openAnimalsSubcategories() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => const AnimalsSubcategoryScreen(),
      ),
    );

    if (mounted) {
      await _loadPlayerStats();
    }
  }

  Future<void> _openFoodDrinkSubcategories() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => const FoodDrinkSubcategoryScreen(),
      ),
    );

    if (mounted) {
      await _loadPlayerStats();
    }
  }

  Future<void> _openScienceNatureSubcategories() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => const ScienceNatureSubcategoryScreen(),
      ),
    );

    if (mounted) {
      await _loadPlayerStats();
    }
  }

  Future<void> _openBooksAuthorsSubcategories() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => const BooksAuthorsSubcategoryScreen(),
      ),
    );

    if (mounted) {
      await _loadPlayerStats();
    }
  }

  Future<void> _openCreativeWorldSubcategories() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => const CreativeWorldSubcategoryScreen(),
      ),
    );

    if (mounted) {
      await _loadPlayerStats();
    }
  }

  Future<void> _openFamousWordsSubcategories() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => const FamousWordsSubcategoryScreen(),
      ),
    );

    if (mounted) {
      await _loadPlayerStats();
    }
  }

  Future<void> _openFamousPeopleSubcategories() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => const FamousPeopleSubcategoryScreen(),
      ),
    );

    if (mounted) {
      await _loadPlayerStats();
    }
  }

  Future<void> _openMusicSubcategories() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => const MusicSubcategoryScreen(),
      ),
    );

    if (mounted) {
      await _loadPlayerStats();
    }
  }

  Future<void> _openSportsSubcategories() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => const SportsSubcategoryScreen(),
      ),
    );

    if (mounted) {
      await _loadPlayerStats();
    }
  }

  Future<void> _openPastPresentSubcategories() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => const PastPresentSubcategoryScreen(),
      ),
    );

    if (mounted) {
      await _loadPlayerStats();
    }
  }

  Future<void> _openWatchPlaySubcategories() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => const WatchPlaySubcategoryScreen(),
      ),
    );

    if (mounted) {
      await _loadPlayerStats();
    }
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
                'Surprise Me could not find any live questions.',
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

      if (mounted) {
        await _loadPlayerStats();
      }
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

  Future<void> _openDailyFlash() async {
    if (_dailyFlashComplete) {
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => DailyFlashLoadingScreen(
          onChallengeFinished: _loadDailyFlashStatus,
        ),
      ),
    );

    if (!mounted) {
      return;
    }

    await Future.wait([
      _loadDailyFlashStatus(),
      _loadPlayerStats(),
    ]);
  }

  Future<void> _openProfile(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => const ProfileScreen(),
      ),
    );

    await Future.wait([
      _loadSelectedAvatar(),
      _loadPlayerStats(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final List<_CategoryData> categories = <_CategoryData>[
      _CategoryData(
        title: 'Surprise Me',
        subtitle: _surpriseMeLoading
            ? 'Picking your surprise...'
            : 'Let First Guess choose your challenge',
        imagePath: 'assets/images/categories/surprise_me.webp',
        isAvailable: true,
        onPressed:
            _surpriseMeLoading ? null : _openSurpriseGame,
      ),
      _CategoryData(
        title: 'Animals',
        subtitle: 'Explore mammals, birds, wildlife and more',
        imagePath: 'assets/images/categories/animals.webp',
        isAvailable: true,
        onPressed: _openAnimalsSubcategories,
      ),
      _CategoryData(
        title: 'Books & Authors',
        subtitle: 'Identify famous writers from portraits and clues',
        imagePath: 'assets/images/categories/books_and_authors.webp',
        isAvailable: true,
        onPressed: _openBooksAuthorsSubcategories,
      ),
      _CategoryData(
        title: 'Countries',
        subtitle: 'Guess countries from their outlines and clues',
        imagePath: 'assets/images/categories/countries.webp',
        isAvailable: true,
        onPressed: _openCountriesSubcategories,
      ),
      _CategoryData(
        title: 'Creative World',
        subtitle: 'Explore art, design, theatre and architecture',
        imagePath: 'assets/images/categories/creative_world.webp',
        isAvailable: true,
        onPressed: _openCreativeWorldSubcategories,
      ),
      _CategoryData(
        title: 'Famous Words',
        subtitle: 'Identify famous words, quotations and speeches',
        imagePath: 'assets/images/categories/famous_words/famous_words.webp',
        isAvailable: true,
        onPressed: _openFamousWordsSubcategories,
      ),
      _CategoryData(
        title: 'Food & Drink',
        subtitle: 'Explore dishes, ingredients, drinks and cuisines',
        imagePath: 'assets/images/categories/food_and_drink.webp',
        isAvailable: true,
        onPressed: _openFoodDrinkSubcategories,
      ),
      _CategoryData(
        title: 'Music',
        subtitle: 'Guess artists, songs, albums and instruments',
        imagePath: 'assets/images/categories/music.webp',
        isAvailable: true,
        onPressed: _openMusicSubcategories,
      ),
      _CategoryData(
        title: 'Past & Present',
        subtitle: 'Travel through history, events and changing times',
        imagePath: 'assets/images/categories/past_and_present.webp',
        isAvailable: true,
        onPressed: _openPastPresentSubcategories,
      ),
      _CategoryData(
        title: 'Science & Nature',
        subtitle: 'Explore science, nature, space and inventions',
        imagePath: 'assets/images/categories/science_and_nature.webp',
        isAvailable: true,
        onPressed: _openScienceNatureSubcategories,
      ),
      _CategoryData(
        title: 'Sports',
        subtitle: 'Identify teams, players, events and sporting moments',
        imagePath: 'assets/images/categories/sports.webp',
        isAvailable: true,
        onPressed: _openSportsSubcategories,
      ),
      _CategoryData(
        title: 'Watch & Play',
        subtitle: 'Test your knowledge of film, television and games',
        imagePath: 'assets/images/categories/watch_and_play.webp',
        isAvailable: true,
        onPressed: _openWatchPlaySubcategories,
      ),
      _CategoryData(
        title: 'Who Am I?',
        subtitle: 'Recognise notable people from around the world',
        imagePath: 'assets/images/categories/famous_people.webp',
        isAvailable: true,
        onPressed: _openFamousPeopleSubcategories,
      ),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _HomeHeader(
                onProfilePressed: () => _openProfile(context),
                selectedAvatarPath: _selectedAvatarPath,
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(0, 0, 0, 10),
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
              const SizedBox(height: 10),
              _QuickPlayRow(
                onCaseFilesPressed: _openCaseFiles,
                onDailyFlashPressed: _openDailyFlash,
                dailyFlashComplete: _dailyFlashComplete,
              ),
              const SizedBox(height: 10),
              const _ChallengeHeading(),
              const SizedBox(height: 10),
              ...categories.map(
                (_CategoryData category) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _CategoryCard(category: category),
                ),
              ),
              const SizedBox(height: 4),
              const _AdSpace(),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  final VoidCallback onProfilePressed;
  final String? selectedAvatarPath;

  const _HomeHeader({
    required this.onProfilePressed,
    required this.selectedAvatarPath,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (
        BuildContext context,
        BoxConstraints constraints,
      ) {
        final bool isNarrow = constraints.maxWidth < 390;

        final double logoWidth = isNarrow ? 58 : 68;
        final double logoHeight = isNarrow ? 66 : 76;
        final double titleHeight = isNarrow ? 48 : 56;
        final double headerHeight = isNarrow ? 78 : 88;

        return SizedBox(
          height: headerHeight,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Align(
                alignment: Alignment.center,
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isNarrow ? 72 : 84,
                  ),
                  child: Image.asset(
                    'assets/images/first_guess_header.png',
                    height: titleHeight,
                    fit: BoxFit.contain,
                    alignment: Alignment.center,
                  ),
                ),
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: SizedBox(
                  width: logoWidth,
                  height: logoHeight,
                  child: Image.asset(
                    'assets/images/first_guess_logo.png',
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: onProfilePressed,
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 2,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: isNarrow ? 46 : 52,
                            height: isNarrow ? 46 : 52,
                            child: Image.asset(
                              selectedAvatarPath ??
                                  'assets/images/avatars/default_avatar.webp',
                              fit: BoxFit.contain,
                              filterQuality: FilterQuality.high,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'MY PROFILE',
                            maxLines: 1,
                            style: AppTextStyles.label.copyWith(
                              color: AppColors.white,
                              fontSize: isNarrow ? 9.5 : 10.5,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.25,
                              height: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _QuickPlayRow extends StatelessWidget {
  final VoidCallback onCaseFilesPressed;
  final VoidCallback onDailyFlashPressed;
  final bool dailyFlashComplete;

  const _QuickPlayRow({
    required this.onCaseFilesPressed,
    required this.onDailyFlashPressed,
    required this.dailyFlashComplete,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (
        BuildContext context,
        BoxConstraints constraints,
      ) {
        final bool isNarrow = constraints.maxWidth < 390;
        final double gap = isNarrow ? 7 : 9;

        return SizedBox(
          height: isNarrow ? 158 : 166,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 11,
                child: _DailyFlashCard(
                  onTap: onDailyFlashPressed,
                  isNarrow: isNarrow,
                  isComplete: dailyFlashComplete,
                ),
              ),
              SizedBox(width: gap),
              Expanded(
                flex: 9,
                child: _CaseFilesCard(
                  onTap: onCaseFilesPressed,
                  isNarrow: isNarrow,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CaseFilesCard extends StatelessWidget {
  final VoidCallback onTap;
  final bool isNarrow;

  const _CaseFilesCard({
    required this.onTap,
    required this.isNarrow,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Container(
            width: double.infinity,
            height: double.infinity,
            color: Colors.black,
            alignment: Alignment.center,
            child: Image.asset(
              'assets/images/case_files/case_file_mainV2_image.webp',
              width: double.infinity,
              height: double.infinity,
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

class _DailyFlashCard extends StatelessWidget {
  final VoidCallback onTap;
  final bool isNarrow;
  final bool isComplete;

  const _DailyFlashCard({
    required this.onTap,
    required this.isNarrow,
    required this.isComplete,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: isComplete ? null : onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          height: double.infinity,
          padding: EdgeInsets.fromLTRB(
            isNarrow ? 8 : 10,
            8,
            isNarrow ? 8 : 10,
            10,
          ),
          decoration: BoxDecoration(
            color: AppColors.panel,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: AppColors.orange,
              width: 1.2,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x22FE5E02),
                blurRadius: 8,
              ),
            ],
          ),
          child: Column(
            children: [
              SizedBox(
                height: isNarrow ? 48 : 52,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: isNarrow ? 38 : 44,
                      height: double.infinity,
                      child: Image.asset(
                        'assets/images/orangeflashbolt_T_O.png',
                        fit: BoxFit.contain,
                        filterQuality: FilterQuality.high,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Center(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            'DAILY FLASH 5',
                            maxLines: 1,
                            style: AppTextStyles.category.copyWith(
                              color: AppColors.white,
                              fontSize: isNarrow ? 20 : 23,
                              height: 1,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.1,
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: isNarrow ? 44 : 50,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 3),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: isNarrow ? 10 : 12,
                      vertical: isNarrow ? 5 : 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.orange,
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Text(
                      '2× XP',
                      style: AppTextStyles.label.copyWith(
                        color: Colors.black,
                        fontSize: isNarrow ? 12.5 : 14,
                        fontWeight: FontWeight.w900,
                        height: 1,
                      ),
                    ),
                  ),
                  const SizedBox(width: 7),
                  const Flexible(
                    child: _MidnightCountdown(),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                height: isNarrow ? 40 : 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isComplete ? AppColors.background : null,
                  gradient: isComplete
                      ? null
                      : const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Color(0xFFFFA512),
                            Color(0xFFFF7900),
                            Color(0xFFFF4B00),
                          ],
                        ),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isComplete
                        ? AppColors.orange
                        : const Color(0xFFFFB21A),
                    width: 1,
                  ),
                  boxShadow: isComplete
                      ? null
                      : const [
                          BoxShadow(
                            color: Color(0x44FF6500),
                            blurRadius: 7,
                          ),
                        ],
                ),
                child: Text(
                  isComplete ? 'FLASH COMPLETE' : 'PLAY NOW',
                  maxLines: 1,
                  style: AppTextStyles.label.copyWith(
                    color: isComplete
                        ? AppColors.orange
                        : AppColors.white,
                    fontSize: isNarrow ? 14.5 : 16,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.15,
                    height: 1,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MidnightCountdown extends StatefulWidget {
  const _MidnightCountdown();

  @override
  State<_MidnightCountdown> createState() =>
      _MidnightCountdownState();
}

class _MidnightCountdownState
    extends State<_MidnightCountdown> {
  Timer? _timer;
  Duration _remaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    _refresh();
    _timer = Timer.periodic(
      const Duration(minutes: 1),
      (_) => _refresh(),
    );
  }

  void _refresh() {
    final DateTime now = DateTime.now();
    final DateTime nextMidnight = DateTime(
      now.year,
      now.month,
      now.day + 1,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _remaining = nextMidnight.difference(now);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final int hours = _remaining.inHours;
    final int minutes =
        _remaining.inMinutes.remainder(60);

    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerRight,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 8,
          vertical: 5,
        ),
        decoration: BoxDecoration(
          color: const Color(0x1FFE5E02),
          borderRadius: BorderRadius.circular(11),
          border: Border.all(
            color: AppColors.orange,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.access_time_rounded,
              color: AppColors.orange,
              size: 15,
            ),
            const SizedBox(width: 4),
            Text(
              'ENDS IN ${hours}HR ${minutes}M',
              maxLines: 1,
              style: AppTextStyles.label.copyWith(
                color: AppColors.white,
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChallengeHeading extends StatelessWidget {
  const _ChallengeHeading();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (
        BuildContext context,
        BoxConstraints constraints,
      ) {
        final bool isVeryNarrow =
            constraints.maxWidth < 360;
        final bool isNarrow =
            constraints.maxWidth < 430;

        final double sideGap =
            isVeryNarrow ? 8 : 10;

        return Row(
          children: [
            const Expanded(
              child: _ChallengeLine(),
            ),
            SizedBox(width: sideGap),
            SizedBox(
              width: isVeryNarrow
                  ? 214
                  : (isNarrow ? 226 : 238),
              child: Row(
                mainAxisAlignment:
                    MainAxisAlignment.center,
                children: [
                  const _ChallengeShield(),
                  SizedBox(
                    width: isVeryNarrow ? 5 : 7,
                  ),
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        'PICK YOUR CHALLENGE',
                        maxLines: 1,
                        textAlign: TextAlign.center,
                        style:
                            AppTextStyles.category.copyWith(
                          color: AppColors.white,
                          fontSize: isVeryNarrow
                              ? 16
                              : (isNarrow ? 17 : 18),
                          fontWeight:
                              FontWeight.w600,
                          letterSpacing: 0.45,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: sideGap),
            const Expanded(
              child: _ChallengeLine(),
            ),
          ],
        );
      },
    );
  }
}

class _ChallengeShield extends StatelessWidget {
  const _ChallengeShield();

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        const Icon(
          Icons.shield_rounded,
          size: 21,
          color: AppColors.orange,
        ),
        Text(
          '?',
          style: AppTextStyles.label.copyWith(
            color: AppColors.white,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            height: 1,
          ),
        ),
      ],
    );
  }
}

class _ChallengeLine extends StatelessWidget {
  const _ChallengeLine();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1.5,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.transparent,
            AppColors.orange,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x55FE5E02),
            blurRadius: 5,
          ),
        ],
      ),
    );
  }
}

class _CategoryData {
  final String title;
  final String subtitle;
  final String imagePath;
  final bool isAvailable;
  final VoidCallback? onPressed;

  const _CategoryData({
    required this.title,
    required this.subtitle,
    required this.imagePath,
    this.onPressed,
    this.isAvailable = false,
  });
}

class _CategoryCard extends StatelessWidget {
  final _CategoryData category;

  const _CategoryCard({
    required this.category,
  });

  @override
  Widget build(BuildContext context) {
    final bool isAvailable = category.isAvailable;

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: isAvailable ? 1 : 0.52,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          onTap:
              isAvailable ? category.onPressed : null,
          borderRadius:
              BorderRadius.circular(22),
          child: Ink(
            decoration: BoxDecoration(
              color: AppColors.panel,
              borderRadius:
                  BorderRadius.circular(22),
              border: Border.all(
                color: isAvailable
                    ? AppColors.orange
                    : AppColors.darkGrey,
                width: isAvailable ? 1.8 : 1.2,
              ),
              boxShadow: isAvailable
                  ? const [
                      BoxShadow(
                        color: Color(0x2BFE5E02),
                        blurRadius: 12,
                        spreadRadius: 0.5,
                      ),
                    ]
                  : null,
            ),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 14,
              ),
              child: Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color:
                          AppColors.background,
                      borderRadius:
                          BorderRadius.circular(17),
                      border: Border.all(
                        color: isAvailable
                            ? AppColors.orange
                            : AppColors.darkGrey,
                        width: 1.4,
                      ),
                    ),
                    child: Image.asset(
                      category.imagePath,
                      fit: BoxFit.contain,
                      filterQuality:
                          FilterQuality.high,
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          category.title
                              .toUpperCase(),
                          maxLines: 1,
                          overflow:
                              TextOverflow.ellipsis,
                          style: AppTextStyles
                              .category
                              .copyWith(
                            color: isAvailable
                                ? AppColors.white
                                : AppColors.grey,
                            fontSize: 17,
                            letterSpacing: 0.15,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          category.subtitle,
                          maxLines: 2,
                          overflow:
                              TextOverflow.ellipsis,
                          style:
                              AppTextStyles.body.copyWith(
                            color: isAvailable
                                ? AppColors.white
                                : AppColors.grey,
                            fontSize: 12,
                            height: 1.25,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  if (isAvailable)
                    const _AvailableCategoryStatus()
                  else
                    const _LockedCategoryStatus(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AvailableCategoryStatus
    extends StatelessWidget {
  const _AvailableCategoryStatus();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 92,
      height: 48,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFFFE5E02),
        borderRadius:
            BorderRadius.circular(12),
      ),
      child: Text(
        'PLAY',
        textAlign: TextAlign.center,
        style: AppTextStyles.label.copyWith(
          color: AppColors.white,
          fontSize: 15,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.2,
          height: 1,
        ),
      ),
    );
  }
}

class _LockedCategoryStatus
    extends StatelessWidget {
  const _LockedCategoryStatus();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 92,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.lock_rounded,
            color: AppColors.grey,
            size: 21,
          ),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: 6,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius:
                  BorderRadius.circular(15),
              border: Border.all(
                color: AppColors.orange,
                width: 1,
              ),
            ),
            child: Text(
              'COMING SOON',
              textAlign: TextAlign.center,
              maxLines: 1,
              style:
                  AppTextStyles.label.copyWith(
                color: AppColors.grey,
                fontSize: 8,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AdSpace extends StatelessWidget {
  const _AdSpace();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 76,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.panel,
        borderRadius:
            BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.border,
        ),
      ),
      child: Text(
        'ADVERTISEMENT',
        style: AppTextStyles.label.copyWith(
          color: AppColors.grey,
          fontSize: 10,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}