import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../services/firebase_challenge_service.dart';
import '../../services/player_stats_service.dart';
import '../../services/subcategory_progress_status.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/app_home_button.dart';
import '../../widgets/subcategory_status_badge.dart';
import '../../widgets/stats_panel.dart';
import '../game_screen.dart';

class PastPresentSubcategoryScreen extends StatefulWidget {
  const PastPresentSubcategoryScreen({super.key});

  @override
  State<PastPresentSubcategoryScreen> createState() =>
      _PastPresentSubcategoryScreenState();
}

class _PastPresentSubcategoryScreenState
    extends State<PastPresentSubcategoryScreen> {
  static const List<_PastPresentSubcategory> _items =
      <_PastPresentSubcategory>[
    _PastPresentSubcategory(
      'Historical Events',
      Icons.history_edu_rounded,
      firebaseKey: 'historical_events',
    ),
    _PastPresentSubcategory(
      'Battles & Wars',
      Icons.security_rounded,
      firebaseKey: 'battles_wars',
    ),
    _PastPresentSubcategory(
      'Ancient Civilisations & Empires',
      Icons.account_balance_rounded,
      firebaseKey: 'ancient_civilisations_empires',
    ),
    _PastPresentSubcategory(
      'Historical Eras',
      Icons.hourglass_bottom_rounded,
      firebaseKey: 'historical_eras',
    ),
    _PastPresentSubcategory(
      'Archaeology',
      Icons.architecture_rounded,
      firebaseKey: 'archaeology',
    ),
    _PastPresentSubcategory(
      'Historic Objects',
      Icons.inventory_2_rounded,
      firebaseKey: 'historic_objects',
    ),
    _PastPresentSubcategory(
      'Castles & Ruins',
      Icons.castle_rounded,
      firebaseKey: 'castles_ruins',
    ),
    _PastPresentSubcategory(
      'Monarchies & Dynasties',
      Icons.workspace_premium_rounded,
      firebaseKey: 'monarchies_dynasties',
    ),
    _PastPresentSubcategory(
      'Revolutions & Political Movements',
      Icons.campaign_rounded,
      firebaseKey: 'revolutions_political_movements',
    ),
    _PastPresentSubcategory(
      'Historical Mysteries',
      Icons.help_center_rounded,
      firebaseKey: 'historical_mysteries',
    ),
    _PastPresentSubcategory(
      'Myths & Legends',
      Icons.auto_awesome_rounded,
      firebaseKey: 'myths_legends',
    ),
    _PastPresentSubcategory(
      'Traditions & Cultural Customs',
      Icons.diversity_3_rounded,
      firebaseKey: 'traditions_cultural_customs',
    ),
    _PastPresentSubcategory(
      'Ancient Religions & Beliefs',
      Icons.temple_buddhist_rounded,
      firebaseKey: 'ancient_religions_beliefs',
    ),
    _PastPresentSubcategory(
      'Then-and-Now Challenges',
      Icons.compare_rounded,
      firebaseKey: 'then_and_now_challenges',
    ),
    _PastPresentSubcategory(
      'Important Dates & Lost Cities',
      Icons.event_note_rounded,
      firebaseKey: 'important_dates_lost_cities',
    ),
  ];

  Set<String> _liveFirebaseSubcategories = <String>{};
  Map<String, int> _liveQuestionCounts = <String, int>{};
  Map<String, Set<String>> _liveQuestionIds = <String, Set<String>>{};
  Map<String, int> _playedQuestionCounts = <String, int>{};
  Map<String, int> _completedQuestionTotals = <String, int>{};

  PlayerStats _playerStats = const PlayerStats();
  bool _statsLoaded = false;

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
    await _loadPlayerStats();

    if (!mounted) {
      return;
    }

    await _loadFirebaseSubcategoryAvailability();

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

    for (final _PastPresentSubcategory item in _items) {
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
      category: 'past_present',
      subcategories:
          _items.map((item) => item.firebaseKey),
    );

    final Map<String, int> updatedCompletedTotals =
        Map<String, int>.from(savedCompletedTotals);

    for (final _PastPresentSubcategory item in _items) {
      final int totalQuestions =
          _liveQuestionCounts[item.firebaseKey] ?? 0;
      final int playedQuestions =
          _playedQuestionCounts[item.firebaseKey] ?? 0;

      if (totalQuestions > 0 &&
          playedQuestions >= totalQuestions) {
        await SubcategoryCompletionHistoryService
            .recordCompletion(
          category: 'past_present',
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
      final List<Future<QuerySnapshot<Map<String, dynamic>>>> checks =
          _items.map((_PastPresentSubcategory item) {
        return FirebaseFirestore.instance
            .collection('challenges')
            .where('category', isEqualTo: 'past_present')
            .where('subcategory', isEqualTo: item.firebaseKey)
            .where('status', isEqualTo: 'live')
            .get();
      }).toList();

      final List<QuerySnapshot<Map<String, dynamic>>> results =
          await Future.wait(checks);

      if (!mounted) {
        return;
      }

      final Set<String> liveSubcategories = <String>{};
      final Map<String, int> liveQuestionCounts = <String, int>{};
      final Map<String, Set<String>> liveQuestionIds =
          <String, Set<String>>{};

      for (int i = 0; i < _items.length; i++) {
        final String firebaseKey = _items[i].firebaseKey;
        final Set<String> ids = results[i].docs
            .map((doc) => doc.id)
            .toSet();

        liveQuestionIds[firebaseKey] = ids;
        liveQuestionCounts[firebaseKey] = ids.length;

        if (ids.isNotEmpty) {
          liveSubcategories.add(firebaseKey);
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
    _PastPresentSubcategory item,
  ) async {
    if (!_liveFirebaseSubcategories.contains(item.firebaseKey)) {
      return;
    }

    try {
      final items =
          await FirebaseChallengeService.loadLiveSubcategory(
        category: 'past_present',
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            const _Header(),
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
                itemCount: _items.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final _PastPresentSubcategory item =
                      _items[index];

                  final bool isAvailable =
                      _liveFirebaseSubcategories
                          .contains(item.firebaseKey);

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

                  return _PastPresentCard(
                    item: item,
                    isAvailable: isAvailable,
                    totalQuestions: totalQuestions,
                    playedQuestions: playedQuestions,
                    hadPreviouslyCompleted:
                        hadPreviouslyCompleted,
                    onTap: () => _openSubcategory(item),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

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
                    'PAST & PRESENT',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.category.copyWith(
                      color: AppColors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.45,
                    ),
                  ),
                ),
                const Align(
                  alignment: Alignment.centerRight,
                  child: FirstGuessHomeButton(),
                ),
              ],
            ),
          ),
          Text(
            'Choose a subcategory to start playing',
            textAlign: TextAlign.center,
            style: AppTextStyles.body.copyWith(
              color: AppColors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _PastPresentCard extends StatelessWidget {
  const _PastPresentCard({
    required this.item,
    required this.isAvailable,
    required this.totalQuestions,
    required this.playedQuestions,
    required this.hadPreviouslyCompleted,
    required this.onTap,
  });

  final _PastPresentSubcategory item;
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
                child: Icon(
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
                        fontSize: 18.5,
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
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              SubcategoryStatusBadge(
                text: SubcategoryProgressStatus.resolve(
                    isAvailable: isAvailable,
                    playedQuestions: playedQuestions,
                    totalQuestions: totalQuestions,
                    hadPreviouslyCompleted:
                        hadPreviouslyCompleted,
                  ).ctaLabel,
                color: isAvailable
                    ? AppColors.orange
                    : AppColors.white,
                filled: isAvailable,
              )
            ],
          ),
        ),
      ),
    );
  }
}

class _PastPresentSubcategory {
  const _PastPresentSubcategory(
    this.title,
    this.icon, {
    required this.firebaseKey,
  });

  final String title;
  final IconData icon;
  final String firebaseKey;
}
