import 'package:flutter/material.dart';

import '../case_files/models/case_progress.dart';
import '../case_files/services/case_path_service.dart';
import '../services/feature_flag_service.dart';
import '../services/player_stats_service.dart';
import '../theme/app_colors.dart';
import '../widgets/app_home_button.dart';

class BadgesScreen extends StatefulWidget {
  const BadgesScreen({super.key});

  @override
  State<BadgesScreen> createState() => _BadgesScreenState();
}

class _BadgesScreenState extends State<BadgesScreen> {
  PlayerStats _stats = const PlayerStats();
  CaseProgress? _animalKingdomProgress;
  CaseProgress? _roundTheWorldProgress;
  CaseProgress? _secretsOfThePastProgress;
  CaseProgress? _tasteAndTreatsProgress;
  CaseProgress? _natureOfDiscoveryProgress;
  CaseProgress? _theWrittenWordProgress;
  CaseProgress? _theCreativeCodeProgress;
  bool _isLoading = true;
  bool _firstConnectionEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadBadges();
  }

  Future<void> _loadBadges() async {
    final List<dynamic> initialResults =
        await Future.wait<dynamic>(<Future<dynamic>>[
      PlayerStatsService.loadStats(),
      FeatureFlagService.isFirstConnectionEnabled(),
    ]);

    final PlayerStats savedStats = initialResults[0] as PlayerStats;
    final bool firstConnectionEnabled = initialResults[1] as bool;

    Future<CaseProgress?> safeLoad(
      Future<CaseProgress> Function() loader,
    ) async {
      try {
        return await loader();
      } catch (_) {
        return null;
      }
    }

    final List<CaseProgress?> caseResults = await Future.wait<CaseProgress?>([
      safeLoad(CasePathService.loadAnimalKingdomProgress),
      safeLoad(CasePathService.loadRoundTheWorldProgress),
      safeLoad(CasePathService.loadSecretsOfThePastProgress),
      safeLoad(CasePathService.loadTasteAndTreatsProgress),
      safeLoad(CasePathService.loadNatureOfDiscoveryProgress),
      safeLoad(CasePathService.loadTheWrittenWordProgress),
      safeLoad(CasePathService.loadTheCreativeCodeProgress),
    ]);

    if (!mounted) {
      return;
    }

    setState(() {
      _stats = savedStats;
      _firstConnectionEnabled = firstConnectionEnabled;
      _animalKingdomProgress = caseResults[0];
      _roundTheWorldProgress = caseResults[1];
      _secretsOfThePastProgress = caseResults[2];
      _tasteAndTreatsProgress = caseResults[3];
      _natureOfDiscoveryProgress = caseResults[4];
      _theWrittenWordProgress = caseResults[5];
      _theCreativeCodeProgress = caseResults[6];
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.sizeOf(context).width;
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
        title: const SizedBox.shrink(),
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
                onRefresh: _loadBadges,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    16,
                    horizontalPadding,
                    32,
                  ),
                  children: [
                    _BadgeCollection(
                      totalXp: _stats.totalXp,
                      categoryCorrectCounts: _stats.categoryCorrectCounts,
                      firstConnectionEnabled: _firstConnectionEnabled,
                      animalKingdomBadgeEarned:
                          _animalKingdomProgress?.isCompleted ?? false,
                      roundTheWorldBadgeEarned:
                          _roundTheWorldProgress?.isCompleted ?? false,
                      secretsOfThePastBadgeEarned:
                          _secretsOfThePastProgress?.isCompleted ?? false,
                      tasteAndTreatsBadgeEarned:
                          _tasteAndTreatsProgress?.isCompleted ?? false,
                      natureOfDiscoveryBadgeEarned:
                          _natureOfDiscoveryProgress?.isCompleted ?? false,
                      theWrittenWordBadgeEarned:
                          _theWrittenWordProgress?.isCompleted ?? false,
                      theCreativeCodeBadgeEarned:
                          _theCreativeCodeProgress?.isCompleted ?? false,
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

class _BadgeCollection extends StatelessWidget {
  final int totalXp;
  final Map<String, int> categoryCorrectCounts;
  final bool firstConnectionEnabled;
  final bool animalKingdomBadgeEarned;
  final bool roundTheWorldBadgeEarned;
  final bool secretsOfThePastBadgeEarned;
  final bool tasteAndTreatsBadgeEarned;
  final bool natureOfDiscoveryBadgeEarned;
  final bool theWrittenWordBadgeEarned;
  final bool theCreativeCodeBadgeEarned;

  const _BadgeCollection({
    required this.totalXp,
    required this.categoryCorrectCounts,
    required this.firstConnectionEnabled,
    required this.animalKingdomBadgeEarned,
    required this.roundTheWorldBadgeEarned,
    required this.secretsOfThePastBadgeEarned,
    required this.tasteAndTreatsBadgeEarned,
    required this.natureOfDiscoveryBadgeEarned,
    required this.theWrittenWordBadgeEarned,
    required this.theCreativeCodeBadgeEarned,
  });

  int _gameCorrectCount(List<String> keys) {
    int best = 0;

    for (final String key in keys) {
      final int value = categoryCorrectCounts[key] ?? 0;
      if (value > best) {
        best = value;
      }
    }

    return best;
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.sizeOf(context).width < 700;

    final int storedFirstGuessCorrect = _gameCorrectCount(
      <String>[
        'first_guess',
        'classic_firstguess',
        'classic_first_guess',
      ],
    );

    const List<String> classicCategoryKeys = <String>[
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

    int classicCategoryCorrect = 0;
    for (final String key in classicCategoryKeys) {
      classicCategoryCorrect += categoryCorrectCounts[key] ?? 0;
    }

    final int firstGuessCorrect =
        storedFirstGuessCorrect > classicCategoryCorrect
            ? storedFirstGuessCorrect
            : classicCategoryCorrect;
    final int firstWordCorrect = _gameCorrectCount(<String>['first_word']);
    final int firstDateCorrect = _gameCorrectCount(<String>['first_date']);
    final int firstMatchCorrect = _gameCorrectCount(<String>['first_match']);
    final int firstOrderCorrect = _gameCorrectCount(<String>['first_order']);
    final int firstConnectionCorrect =
        _gameCorrectCount(<String>['first_connection']);

    final List<_BadgeDisplayData> badges = <_BadgeDisplayData>[
      // CASE FILE BADGES
      _BadgeDisplayData(
        imagePath:
            'assets/images/badges/final/case_files/animal_kingdom_case_file_badge.webp',
        tooltip: animalKingdomBadgeEarned
            ? 'Animal Kingdom Badge'
            : 'Animal Kingdom Badge — not yet earned',
        earned: animalKingdomBadgeEarned,
      ),
      _BadgeDisplayData(
        imagePath:
            'assets/images/badges/final/case_files/amazing_world_case_file_badge.webp',
        tooltip: roundTheWorldBadgeEarned
            ? 'Around the World Badge'
            : 'Around the World Badge — not yet earned',
        earned: roundTheWorldBadgeEarned,
      ),
      _BadgeDisplayData(
        imagePath:
            'assets/images/badges/final/case_files/mysteries_legends_case_file_badge.webp',
        tooltip: secretsOfThePastBadgeEarned
            ? 'Secrets of the Past Badge'
            : 'Secrets of the Past Badge — not yet earned',
        earned: secretsOfThePastBadgeEarned,
      ),
      _BadgeDisplayData(
        imagePath:
            'assets/images/badges/final/case_files/tastes_treats_case_file_badge.webp',
        tooltip: tasteAndTreatsBadgeEarned
            ? 'Tastes & Treats Badge'
            : 'Tastes & Treats Badge — not yet earned',
        earned: tasteAndTreatsBadgeEarned,
      ),
      _BadgeDisplayData(
        imagePath:
            'assets/images/badges/final/case_files/nature_of_discovery.webp',
        tooltip: natureOfDiscoveryBadgeEarned
            ? 'Nature of Discovery Badge'
            : 'Nature of Discovery Badge — not yet earned',
        earned: natureOfDiscoveryBadgeEarned,
      ),
      _BadgeDisplayData(
        imagePath:
            'assets/images/badges/final/case_files/the_written_word.webp',
        tooltip: theWrittenWordBadgeEarned
            ? 'The Written Word Badge'
            : 'The Written Word Badge — not yet earned',
        earned: theWrittenWordBadgeEarned,
      ),
      _BadgeDisplayData(
        imagePath:
            'assets/images/badges/final/case_files/the_creative_code.webp',
        tooltip: theCreativeCodeBadgeEarned
            ? 'The Creative Code Badge'
            : 'The Creative Code Badge — not yet earned',
        earned: theCreativeCodeBadgeEarned,
      ),

      // CLUE BADGES
      _BadgeDisplayData(
        imagePath: 'assets/images/badges/final/clue/clue_starter.webp',
        tooltip: totalXp >= 1500
            ? 'Clue Starter Badge'
            : 'Clue Starter Badge — not yet earned',
        earned: totalXp >= 1500,
      ),
      _BadgeDisplayData(
        imagePath: 'assets/images/badges/final/clue/clue_advanced.webp',
        tooltip: totalXp >= 15000
            ? 'Clue Advanced Badge'
            : 'Clue Advanced Badge — not yet earned',
        earned: totalXp >= 15000,
      ),
      _BadgeDisplayData(
        imagePath: 'assets/images/badges/final/clue/clue_expert.webp',
        tooltip: totalXp >= 37500
            ? 'Clue Expert Badge'
            : 'Clue Expert Badge — not yet earned',
        earned: totalXp >= 37500,
      ),
      _BadgeDisplayData(
        imagePath: 'assets/images/badges/final/clue/clue_master.webp',
        tooltip: totalXp >= 75000
            ? 'Clue Master Badge'
            : 'Clue Master Badge — not yet earned',
        earned: totalXp >= 75000,
      ),
      _BadgeDisplayData(
        imagePath: 'assets/images/badges/final/clue/clue_elite.webp',
        tooltip: totalXp >= 150000
            ? 'Clue Elite Badge'
            : 'Clue Elite Badge — not yet earned',
        earned: totalXp >= 150000,
      ),

      // GAME BADGES — STARTER
      _BadgeDisplayData(
        imagePath:
            'assets/images/badges/final/game_badges/first_guess_starter.webp',
        tooltip: firstGuessCorrect >= 10
            ? 'First Guess Starter Badge'
            : 'First Guess Starter Badge — not yet earned',
        earned: firstGuessCorrect >= 10,
      ),
      _BadgeDisplayData(
        imagePath:
            'assets/images/badges/final/game_badges/first_word_starter.webp',
        tooltip: firstWordCorrect >= 10
            ? 'First Word Starter Badge'
            : 'First Word Starter Badge — not yet earned',
        earned: firstWordCorrect >= 10,
      ),
      _BadgeDisplayData(
        imagePath:
            'assets/images/badges/final/game_badges/first_date_starter.webp',
        tooltip: firstDateCorrect >= 10
            ? 'First Date Starter Badge'
            : 'First Date Starter Badge — not yet earned',
        earned: firstDateCorrect >= 10,
      ),
      _BadgeDisplayData(
        imagePath:
            'assets/images/badges/final/game_badges/first_match_starter.webp',
        tooltip: firstMatchCorrect >= 10
            ? 'First Match Starter Badge'
            : 'First Match Starter Badge — not yet earned',
        earned: firstMatchCorrect >= 10,
      ),
      _BadgeDisplayData(
        imagePath:
            'assets/images/badges/final/game_badges/first_order_starter.webp',
        tooltip: firstOrderCorrect >= 10
            ? 'First Order Starter Badge'
            : 'First Order Starter Badge — not yet earned',
        earned: firstOrderCorrect >= 10,
      ),
      _BadgeDisplayData(
        imagePath:
            'assets/images/badges/final/game_badges/first_connection_starter.webp',
        tooltip: firstConnectionCorrect >= 10
            ? 'First Connection Starter Badge'
            : 'First Connection Starter Badge — not yet earned',
        earned: firstConnectionCorrect >= 10,
      ),

      // GAME BADGES — ADVANCED
      _BadgeDisplayData(
        imagePath:
            'assets/images/badges/final/game_badges/first_guess_advanced.webp',
        tooltip: firstGuessCorrect >= 50
            ? 'First Guess Advanced Badge'
            : 'First Guess Advanced Badge — not yet earned',
        earned: firstGuessCorrect >= 50,
      ),
      _BadgeDisplayData(
        imagePath:
            'assets/images/badges/final/game_badges/first_word_advanced.webp',
        tooltip: firstWordCorrect >= 50
            ? 'First Word Advanced Badge'
            : 'First Word Advanced Badge — not yet earned',
        earned: firstWordCorrect >= 50,
      ),
      _BadgeDisplayData(
        imagePath:
            'assets/images/badges/final/game_badges/first_date_advanced.webp',
        tooltip: firstDateCorrect >= 50
            ? 'First Date Advanced Badge'
            : 'First Date Advanced Badge — not yet earned',
        earned: firstDateCorrect >= 50,
      ),
      _BadgeDisplayData(
        imagePath:
            'assets/images/badges/final/game_badges/first_match_advanced.webp',
        tooltip: firstMatchCorrect >= 50
            ? 'First Match Advanced Badge'
            : 'First Match Advanced Badge — not yet earned',
        earned: firstMatchCorrect >= 50,
      ),
      _BadgeDisplayData(
        imagePath:
            'assets/images/badges/final/game_badges/first_order_advanced.webp',
        tooltip: firstOrderCorrect >= 50
            ? 'First Order Advanced Badge'
            : 'First Order Advanced Badge — not yet earned',
        earned: firstOrderCorrect >= 50,
      ),
      _BadgeDisplayData(
        imagePath:
            'assets/images/badges/final/game_badges/first_connection_advanced.webp',
        tooltip: firstConnectionCorrect >= 50
            ? 'First Connection Advanced Badge'
            : 'First Connection Advanced Badge — not yet earned',
        earned: firstConnectionCorrect >= 50,
      ),

      // GAME BADGES — EXPERT
      _BadgeDisplayData(
        imagePath:
            'assets/images/badges/final/game_badges/first_guess_expert.webp',
        tooltip: firstGuessCorrect >= 150
            ? 'First Guess Expert Badge'
            : 'First Guess Expert Badge — not yet earned',
        earned: firstGuessCorrect >= 150,
      ),
      _BadgeDisplayData(
        imagePath:
            'assets/images/badges/final/game_badges/first_word_expert.webp',
        tooltip: firstWordCorrect >= 150
            ? 'First Word Expert Badge'
            : 'First Word Expert Badge — not yet earned',
        earned: firstWordCorrect >= 150,
      ),
      _BadgeDisplayData(
        imagePath:
            'assets/images/badges/final/game_badges/first_date_expert.webp',
        tooltip: firstDateCorrect >= 150
            ? 'First Date Expert Badge'
            : 'First Date Expert Badge — not yet earned',
        earned: firstDateCorrect >= 150,
      ),
      _BadgeDisplayData(
        imagePath:
            'assets/images/badges/final/game_badges/first_match_expert.webp',
        tooltip: firstMatchCorrect >= 150
            ? 'First Match Expert Badge'
            : 'First Match Expert Badge — not yet earned',
        earned: firstMatchCorrect >= 150,
      ),
      _BadgeDisplayData(
        imagePath:
            'assets/images/badges/final/game_badges/first_order_expert.webp',
        tooltip: firstOrderCorrect >= 150
            ? 'First Order Expert Badge'
            : 'First Order Expert Badge — not yet earned',
        earned: firstOrderCorrect >= 150,
      ),
      _BadgeDisplayData(
        imagePath:
            'assets/images/badges/final/game_badges/first_connection_expert.webp',
        tooltip: firstConnectionCorrect >= 150
            ? 'First Connection Expert Badge'
            : 'First Connection Expert Badge — not yet earned',
        earned: firstConnectionCorrect >= 150,
      ),

      // GAME BADGES — MASTER
      _BadgeDisplayData(
        imagePath:
            'assets/images/badges/final/game_badges/first_guess_master.webp',
        tooltip: firstGuessCorrect >= 500
            ? 'First Guess Master Badge'
            : 'First Guess Master Badge — not yet earned',
        earned: firstGuessCorrect >= 500,
      ),
      _BadgeDisplayData(
        imagePath:
            'assets/images/badges/final/game_badges/first_word_master.webp',
        tooltip: firstWordCorrect >= 500
            ? 'First Word Master Badge'
            : 'First Word Master Badge — not yet earned',
        earned: firstWordCorrect >= 500,
      ),
      _BadgeDisplayData(
        imagePath:
            'assets/images/badges/final/game_badges/first_date_master.webp',
        tooltip: firstDateCorrect >= 500
            ? 'First Date Master Badge'
            : 'First Date Master Badge — not yet earned',
        earned: firstDateCorrect >= 500,
      ),
      _BadgeDisplayData(
        imagePath:
            'assets/images/badges/final/game_badges/first_match_master.webp',
        tooltip: firstMatchCorrect >= 500
            ? 'First Match Master Badge'
            : 'First Match Master Badge — not yet earned',
        earned: firstMatchCorrect >= 500,
      ),
      _BadgeDisplayData(
        imagePath:
            'assets/images/badges/final/game_badges/first_order_master.webp',
        tooltip: firstOrderCorrect >= 500
            ? 'First Order Master Badge'
            : 'First Order Master Badge — not yet earned',
        earned: firstOrderCorrect >= 500,
      ),
      _BadgeDisplayData(
        imagePath:
            'assets/images/badges/final/game_badges/first_connection_master.webp',
        tooltip: firstConnectionCorrect >= 500
            ? 'First Connection Master Badge'
            : 'First Connection Master Badge — not yet earned',
        earned: firstConnectionCorrect >= 500,
      ),

      // GAME BADGES — LEGEND
      _BadgeDisplayData(
        imagePath:
            'assets/images/badges/final/game_badges/first_guess_legend.webp',
        tooltip: firstGuessCorrect >= 1000
            ? 'First Guess Legend Badge'
            : 'First Guess Legend Badge — not yet earned',
        earned: firstGuessCorrect >= 1000,
      ),
      _BadgeDisplayData(
        imagePath:
            'assets/images/badges/final/game_badges/first_word_legend.webp',
        tooltip: firstWordCorrect >= 1000
            ? 'First Word Legend Badge'
            : 'First Word Legend Badge — not yet earned',
        earned: firstWordCorrect >= 1000,
      ),
      _BadgeDisplayData(
        imagePath:
            'assets/images/badges/final/game_badges/first_date_legend.webp',
        tooltip: firstDateCorrect >= 1000
            ? 'First Date Legend Badge'
            : 'First Date Legend Badge — not yet earned',
        earned: firstDateCorrect >= 1000,
      ),
      _BadgeDisplayData(
        imagePath:
            'assets/images/badges/final/game_badges/first_match_legend.webp',
        tooltip: firstMatchCorrect >= 1000
            ? 'First Match Legend Badge'
            : 'First Match Legend Badge — not yet earned',
        earned: firstMatchCorrect >= 1000,
      ),
      _BadgeDisplayData(
        imagePath:
            'assets/images/badges/final/game_badges/first_order_legend.webp',
        tooltip: firstOrderCorrect >= 1000
            ? 'First Order Legend Badge'
            : 'First Order Legend Badge — not yet earned',
        earned: firstOrderCorrect >= 1000,
      ),
      _BadgeDisplayData(
        imagePath:
            'assets/images/badges/final/game_badges/first_connection_legend.webp',
        tooltip: firstConnectionCorrect >= 1000
            ? 'First Connection Legend Badge'
            : 'First Connection Legend Badge — not yet earned',
        earned: firstConnectionCorrect >= 1000,
      ),
    ];

    // Keep First Connection badges hidden until the remote launch flag is on.
    if (!firstConnectionEnabled) {
      badges.removeWhere(
        (badge) => badge.imagePath.contains('first_connection_'),
      );
    }

    final List<_BadgeDisplayData> earnedBadges =
        badges.where((badge) => badge.earned).toList();
    final List<_BadgeDisplayData> lockedBadges =
        badges.where((badge) => !badge.earned).toList();

    return Container(
      padding: EdgeInsets.fromLTRB(
        isMobile ? 0 : 14,
        isMobile ? 8 : 16,
        isMobile ? 0 : 14,
        isMobile ? 12 : 18,
      ),
      decoration: BoxDecoration(
        color: isMobile ? Colors.transparent : AppColors.panel,
        borderRadius: BorderRadius.circular(18),
        border: isMobile ? null : Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _BadgeSectionTitle('MY BADGES'),
          const SizedBox(height: 12),
          _BadgeWrap(
            badges: earnedBadges,
            emptyText: 'No badges earned yet.',
          ),
          const SizedBox(height: 26),
          const _BadgeSectionTitle('BADGES STILL TO COLLECT'),
          const SizedBox(height: 12),
          _BadgeWrap(
            badges: lockedBadges,
            emptyText: 'You have collected every badge!',
          ),
        ],
      ),
    );
  }
}

class _BadgeSectionTitle extends StatelessWidget {
  final String text;

  const _BadgeSectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          child: _BadgeSectionLine(),
        ),
        const SizedBox(width: 10),
        Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: 'Oswald',
            color: AppColors.white,
            fontSize: 19,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(width: 10),
        const Expanded(
          child: _BadgeSectionLine(reverse: true),
        ),
      ],
    );
  }
}

class _BadgeSectionLine extends StatelessWidget {
  final bool reverse;

  const _BadgeSectionLine({
    this.reverse = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1.5,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: reverse ? Alignment.centerRight : Alignment.centerLeft,
          end: reverse ? Alignment.centerLeft : Alignment.centerRight,
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

class _BadgeWrap extends StatelessWidget {
  final List<_BadgeDisplayData> badges;
  final String emptyText;

  const _BadgeWrap({
    required this.badges,
    required this.emptyText,
  });

  @override
  Widget build(BuildContext context) {
    if (badges.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text(
          emptyText,
          style: const TextStyle(
            fontFamily: 'Inter',
            color: AppColors.grey,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isMobile = MediaQuery.sizeOf(context).width < 700;
        final int columns = isMobile ? 4 : 6;
        final double spacing = isMobile ? 6 : 14;
        final double badgeWidth =
            ((constraints.maxWidth - (spacing * (columns - 1))) / columns)
                .clamp(
                  isMobile ? 72.0 : 96.0,
                  isMobile ? 104.0 : 138.0,
                )
                .toDouble();

        return Wrap(
          spacing: spacing,
          runSpacing: isMobile ? 14 : 18,
          children: badges
              .map(
                (_BadgeDisplayData badge) => _CaseFileBadge(
                  imagePath: badge.imagePath,
                  tooltip: badge.tooltip,
                  earned: badge.earned,
                  width: badgeWidth,
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class _BadgeDisplayData {
  final String imagePath;
  final String tooltip;
  final bool earned;

  const _BadgeDisplayData({
    required this.imagePath,
    required this.tooltip,
    required this.earned,
  });
}

class _CaseFileBadge extends StatelessWidget {
  final String imagePath;
  final String tooltip;
  final bool earned;
  final double width;

  const _CaseFileBadge({
    required this.imagePath,
    required this.tooltip,
    required this.earned,
    required this.width,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: SizedBox(
        width: width,
        height: width,
        child: Opacity(
          opacity: earned ? 1.0 : 0.34,
          child: Image.asset(
            imagePath,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
            errorBuilder: (
              BuildContext context,
              Object error,
              StackTrace? stackTrace,
            ) {
              return const Center(
                child: Icon(
                  Icons.emoji_events_rounded,
                  color: AppColors.orange,
                  size: 42,
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
