import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../services/achievement_service.dart';
import '../services/analytics_service.dart';
import '../services/content_consumption_service.dart';
import '../services/firebase_challenge_service.dart';
import '../services/player_stats_service.dart';
import '../theme/app_colors.dart';
import '../widgets/app_home_button.dart';
import '../widgets/game_dialogs.dart';
import '../widgets/lives_display.dart';
import '../widgets/milestone_reached_dialog.dart';
import '../widgets/stats_panel.dart';


bool _isInstalledPhone(BuildContext context) {
  const bool isWeb = bool.fromEnvironment('dart.library.js_interop');
  final TargetPlatform platform = Theme.of(context).platform;
  return !isWeb &&
      (platform == TargetPlatform.iOS || platform == TargetPlatform.android) &&
      MediaQuery.sizeOf(context).shortestSide < 600;
}

class _SixDotDragGrip extends StatelessWidget {
  final Color color;

  const _SixDotDragGrip({
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    const double dotSize = 4.2;
    const double gap = 3.2;

    return SizedBox(
      width: 22,
      height: 30,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            for (int row = 0; row < 3; row++) ...<Widget>[
              Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  _GripDot(size: dotSize, color: color),
                  const SizedBox(width: gap),
                  _GripDot(size: dotSize, color: color),
                ],
              ),
              if (row < 2) const SizedBox(height: gap),
            ],
          ],
        ),
      ),
    );
  }
}

class _GripDot extends StatelessWidget {
  final double size;
  final Color color;

  const _GripDot({
    required this.size,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}

class FirstOrderGameScreen extends StatefulWidget {
  const FirstOrderGameScreen({super.key});

  @override
  State<FirstOrderGameScreen> createState() => _FirstOrderGameScreenState();
}

class _FirstOrderQuestion {
  final String id;
  final String prompt;
  final List<String> orderedItems;

  const _FirstOrderQuestion({
    required this.id,
    required this.prompt,
    required this.orderedItems,
  });
}

class _FirstOrderGameScreenState extends State<FirstOrderGameScreen> {
  static const int _maximumSubmissions = 3;
  static const List<int> _basePoints = <int>[100, 80, 60, 40, 20];
  static const int _firstGuessBonus = 50;

  final Random _random = Random();
  final Set<String> _practiceSeenIds = <String>{};

  _FirstOrderQuestion? _question;
  PlayerStats _playerStats = const PlayerStats();

  List<String> _currentOrder = <String>[];
  Set<int> _lockedPositions = <int>{};

  bool _loading = true;
  bool _hasLoadedStats = false;
  bool _roundFinished = false;
  bool _allQuestionsPlayed = false;
  bool _practiceMode = false;

  int _submittedOrderCount = 0;

  int _totalQuestionsAvailable = 0;

  String? _message;
  Timer? _messageTimer;
  DateTime _roundStartedAt = DateTime.now();

  int get _submissionsRemaining =>
      _maximumSubmissions - _submittedOrderCount;

  int get _currentBasePoints {
    final int index =
        _submittedOrderCount.clamp(0, _basePoints.length - 1);
    return _basePoints[index];
  }

  @override
  void initState() {
    super.initState();
    _loadRound();
  }

  @override
  void dispose() {
    _messageTimer?.cancel();
    super.dispose();
  }

  void _showTemporaryMessage(
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    _messageTimer?.cancel();

    if (!mounted) {
      return;
    }

    setState(() {
      _message = message;
    });

    _messageTimer = Timer(duration, () {
      if (!mounted) {
        return;
      }

      setState(() {
        _message = null;
      });
    });
  }

  Future<void> _loadRound() async {
    _messageTimer?.cancel();

    if (mounted) {
      setState(() {
        _loading = true;
        _roundFinished = false;
        _allQuestionsPlayed = false;
        _submittedOrderCount = 0;
        _message = null;
        _currentOrder = <String>[];
        _lockedPositions = <int>{};
      });
    }

    try {
      final List<dynamic> results =
          await Future.wait<dynamic>(<Future<dynamic>>[
        _hasLoadedStats
            ? Future<PlayerStats>.value(_playerStats)
            : PlayerStatsService.loadStats(),
        QuestionHistoryService.loadPlayedQuestionIds(),
        FirebaseChallengeService.loadLiveCategoryDocuments(
          category: 'first_order',
        ),
      ]);

      final PlayerStats stats = results[0] as PlayerStats;
      _hasLoadedStats = true;
      final Set<String> playedIds = results[1] as Set<String>;
      final List<QueryDocumentSnapshot<Map<String, dynamic>>> documents =
          results[2]
              as List<QueryDocumentSnapshot<Map<String, dynamic>>>;

      final List<_FirstOrderQuestion> questions = documents
          .map(_questionFromDocument)
          .whereType<_FirstOrderQuestion>()
          .toList();

      _totalQuestionsAvailable = questions.length;

      if (!mounted) {
        return;
      }

      if (questions.isEmpty) {
        setState(() {
          _playerStats = stats;
          _question = null;
          _loading = false;
        });
        return;
      }

      final List<_FirstOrderQuestion> unplayed = questions
          .where(
            (_FirstOrderQuestion item) => !playedIds.contains(item.id),
          )
          .toList();

      if (!_practiceMode && unplayed.isEmpty) {
        setState(() {
          _playerStats = stats;
          _question = null;
          _allQuestionsPlayed = true;
          _loading = false;
        });

        final bool? continueInPractice = await showPracticeModeDialog(
          context: context,
          categoryLabel: 'First Order',
        );

        if (!mounted) {
          return;
        }

        if (continueInPractice == true) {
          setState(() {
            _practiceMode = true;
            _allQuestionsPlayed = false;
            _practiceSeenIds.clear();
          });
          await _loadRound();
        } else {
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
        return;
      }

      List<_FirstOrderQuestion> pool;

      if (_practiceMode) {
        pool = questions
            .where(
              (_FirstOrderQuestion item) =>
                  !_practiceSeenIds.contains(item.id),
            )
            .toList();

        if (pool.isEmpty) {
          _practiceSeenIds.clear();
          pool = List<_FirstOrderQuestion>.from(questions);
        }
      } else {
        pool = unplayed;
      }

      final _FirstOrderQuestion selected =
          pool[_random.nextInt(pool.length)];

      if (_practiceMode) {
        _practiceSeenIds.add(selected.id);
      }

      final List<String> shuffled =
          List<String>.from(selected.orderedItems)..shuffle(_random);

      // Avoid beginning in the correct order by chance.
      if (_ordersMatch(shuffled, selected.orderedItems) &&
          shuffled.length > 1) {
        final String first = shuffled.removeAt(0);
        shuffled.add(first);
      }

      setState(() {
        _playerStats = stats;
        _question = selected;
        _currentOrder = shuffled;
        _allQuestionsPlayed = false;
        _loading = false;
        _roundStartedAt = DateTime.now();
      });

      unawaited(
        AnalyticsService.logGameStarted(
          gameType: 'first_order',
          category: 'first_order',
          subcategory: 'first_order',
          questionId: selected.id,
          source: 'main_game',
          practiceMode: _practiceMode,
        ),
      );

      unawaited(
        AnalyticsService.logQuestionStarted(
          gameKey: 'first_order',
          category: 'first_order',
          subcategory: 'first_order',
          questionId: selected.id,
          source: 'main_game',
          practiceMode: _practiceMode,
        ),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _loading = false;
        _question = null;
      });
    }
  }

  Future<void> _recordContentConsumption(
    String questionId,
  ) async {
    if (_practiceMode || _totalQuestionsAvailable <= 0) {
      return;
    }

    try {
      await ContentConsumptionService.recordQuestionCompleted(
        gameKey: 'first_order',
        category: 'first_order',
        subcategory: 'first_order',
        questionId: questionId,
        totalQuestionsAvailable: _totalQuestionsAvailable,
      );
    } catch (error, stackTrace) {
      debugPrint(
        'FIRST_ORDER CONTENT CONSUMPTION TRACKING ERROR: $error',
      );
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  _FirstOrderQuestion? _questionFromDocument(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final Map<String, dynamic> data = document.data();

    final String prompt = (data['prompt'] ?? '').toString().trim();
    final dynamic rawItems = data['orderedItems'];

    if (prompt.isEmpty || rawItems is! List) {
      return null;
    }

    final List<String> items = rawItems
        .map((dynamic item) => item.toString().trim())
        .where((String item) => item.isNotEmpty)
        .toList();

    if (items.length != 5 ||
        items.map((String item) => item.toLowerCase()).toSet().length != 5) {
      return null;
    }

    return _FirstOrderQuestion(
      id: document.id,
      prompt: prompt,
      orderedItems: items,
    );
  }

  bool _ordersMatch(List<String> a, List<String> b) {
    if (a.length != b.length) {
      return false;
    }

    for (int index = 0; index < a.length; index++) {
      if (a[index] != b[index]) {
        return false;
      }
    }

    return true;
  }

  int _playTimeSeconds() {
    return DateTime.now().difference(_roundStartedAt).inSeconds;
  }

  void _moveCardToSlot(int fromIndex, int targetSlot) {
    if (_roundFinished || _lockedPositions.contains(fromIndex)) {
      return;
    }

    final List<int> unlockedPositions = <int>[
      for (int index = 0; index < _currentOrder.length; index++)
        if (!_lockedPositions.contains(index)) index,
    ];

    final int fromSlot = unlockedPositions.indexOf(fromIndex);
    if (fromSlot == -1) {
      return;
    }

    setState(() {
      final List<String> movableItems = <String>[
        for (final int index in unlockedPositions) _currentOrder[index],
      ];

      final String movingItem = movableItems.removeAt(fromSlot);

      int insertAt = targetSlot;
      if (fromSlot < targetSlot) {
        insertAt -= 1;
      }

      insertAt = insertAt.clamp(0, movableItems.length).toInt();
      movableItems.insert(insertAt, movingItem);

      for (int slot = 0; slot < unlockedPositions.length; slot++) {
        _currentOrder[unlockedPositions[slot]] = movableItems[slot];
      }
    });
  }

  Set<int> _correctPositions(_FirstOrderQuestion question) {
    final Set<int> correct = <int>{};

    for (int index = 0; index < question.orderedItems.length; index++) {
      if (_currentOrder[index] == question.orderedItems[index]) {
        correct.add(index);
      }
    }

    return correct;
  }

  Future<void> _submitOrder() async {
    final _FirstOrderQuestion? question = _question;

    if (question == null ||
        _roundFinished ||
        _submittedOrderCount >= _maximumSubmissions) {
      return;
    }

    final bool correct =
        _ordersMatch(_currentOrder, question.orderedItems);

    final int attemptNumber = _submittedOrderCount + 1;

    if (correct) {
      setState(() {
        _submittedOrderCount = attemptNumber;
      });

      await _finishCorrect(
        attemptNumber: attemptNumber,
        wasFirstGuess: attemptNumber == 1,
      );
      return;
    }

    if (attemptNumber >= _maximumSubmissions) {
      setState(() {
        _submittedOrderCount = _maximumSubmissions;
        _message = null;
      });
      _messageTimer?.cancel();

      _showTemporaryMessage(
        'INCORRECT — NO LIVES LEFT',
        duration: const Duration(milliseconds: 2200),
      );

      await Future<void>.delayed(
        const Duration(milliseconds: 2200),
      );

      if (!mounted) {
        return;
      }

      await _finishFailed();
      return;
    }

    final Set<int> newlyCorrect = _correctPositions(question);

    setState(() {
      _submittedOrderCount = attemptNumber;
      _lockedPositions = <int>{
        ..._lockedPositions,
        ...newlyCorrect,
      };
    });

    _showTemporaryMessage(
      'Not quite — correct cards are locked. One life lost.',
    );
  }

  Future<void> _giveUp() async {
    final _FirstOrderQuestion? question = _question;

    if (question == null || _roundFinished) {
      return;
    }

    _messageTimer?.cancel();

    setState(() {
      _roundFinished = true;
      _currentOrder = List<String>.from(question.orderedItems);
      _message = null;
    });

    final String orderText = _correctOrderText(question);

    if (_practiceMode) {
      unawaited(
        AnalyticsService.logGameCompleted(
          gameType: 'first_order',
          category: 'first_order',
          subcategory: 'first_order',
          questionId: question.id,
          source: 'main_game',
          result: 'gave_up',
          xpEarned: 0,
          firstGuess: false,
          practiceMode: true,
          clueNumber: (_submittedOrderCount + 1).clamp(1, _maximumSubmissions),
          guesses: _submittedOrderCount,
          livesRemaining: _submissionsRemaining,
          playTimeSeconds: _playTimeSeconds(),
        ),
      );

      unawaited(
        AnalyticsService.logQuestionCompleted(
          gameKey: 'first_order',
          category: 'first_order',
          subcategory: 'first_order',
          questionId: question.id,
          source: 'main_game',
          result: 'gave_up',
          xpEarned: 0,
          firstGuess: false,
          practiceMode: true,
          clueNumber: (_submittedOrderCount + 1).clamp(1, _maximumSubmissions),
          guesses: _submittedOrderCount,
          livesRemaining: _submissionsRemaining,
          playTimeSeconds: _playTimeSeconds(),
        ),
      );

      await _showResultDialog(
        title: 'YOU GAVE UP!',
        message:
            'THE CORRECT ORDER WAS:\n\n$orderText\n\nPRACTICE MODE\n0 XP',
        success: false,
      );
      return;
    }

    await QuestionHistoryService.recordPlayedQuestion(question.id);
    await _recordContentConsumption(question.id);

    final PlayerStats updated =
        await PlayerStatsService.recordFailedGame(
      currentStats: _playerStats,
      playTimeSeconds: _playTimeSeconds(),
      mainCategoryKey: 'first_order',
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _playerStats = updated;
    });

    unawaited(
      AnalyticsService.logGameCompleted(
        gameType: 'first_order',
        category: 'first_order',
        subcategory: 'first_order',
        questionId: question.id,
        source: 'main_game',
        result: 'gave_up',
        xpEarned: 0,
        firstGuess: false,
        practiceMode: false,
        clueNumber: (_submittedOrderCount + 1).clamp(1, _maximumSubmissions),
        guesses: _submittedOrderCount,
        livesRemaining: _submissionsRemaining,
        playTimeSeconds: _playTimeSeconds(),
      ),
    );

    unawaited(
      AnalyticsService.logQuestionCompleted(
        gameKey: 'first_order',
        category: 'first_order',
        subcategory: 'first_order',
        questionId: question.id,
        source: 'main_game',
        result: 'gave_up',
        xpEarned: 0,
        firstGuess: false,
        practiceMode: false,
        clueNumber: (_submittedOrderCount + 1).clamp(1, _maximumSubmissions),
        guesses: _submittedOrderCount,
        livesRemaining: _submissionsRemaining,
        playTimeSeconds: _playTimeSeconds(),
      ),
    );

    await _showResultDialog(
      title: 'YOU GAVE UP!',
      message: 'THE CORRECT ORDER WAS:\n\n$orderText',
      success: false,
    );
  }

  Future<void> _showNewAchievementPopups({
    required PlayerStats previous,
    required PlayerStats current,
  }) async {
    final List<EarnedBadge> earnedBadges =
        AchievementService.newlyEarnedBadges(
      previous: previous,
      current: current,
      gameKey: 'first_order',
      gameLabel: 'First Order',
    );

    if (earnedBadges.isNotEmpty) {
      for (final EarnedBadge badge in earnedBadges) {
        if (!mounted) {
          return;
        }
        await showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext dialogContext) => BadgeEarnedDialog(
            badgeName: badge.name,
            imageAsset: badge.imageAsset,
          ),
        );
      }
      return;
    }

    final PlayerRankProgress previousRank =
        PlayerRankProgress.fromXp(previous.totalXp);
    final PlayerRankProgress currentRank =
        PlayerRankProgress.fromXp(current.totalXp);

    if (currentRank.isLevelUpFrom(previousRank)) {
      await showRankProgressDialog(
        context: context,
        previous: previousRank,
        current: currentRank,
        xpEarned: current.totalXp - previous.totalXp,
      );
      return;
    }

    final List<Achievement> reached =
        AchievementService.popupAchievementsForGame(
      previous: previous,
      current: current,
      gameCategory: AchievementCategory.firstOrder,
    );

    for (final Achievement achievement in reached) {
      final Achievement? next =
          AchievementService.nextMilestoneAfter(achievement);

      if (!mounted) {
        return;
      }

      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext dialogContext) {
          return MilestoneReachedDialog(
            milestone: MilestonePopupData(
              target: achievement.target,
              label: AchievementService.milestoneLabelFor(achievement),
              nextTarget: next?.target,
              nextLabel: next == null
                  ? null
                  : AchievementService.milestoneLabelFor(next),
            ),
          );
        },
      );
    }
  }

  Future<void> _finishResultAction({
    required bool goHome,
    PlayerStats? previousStats,
    PlayerStats? currentStats,
  }) async {
    final NavigatorState navigator = Navigator.of(context);

    if (navigator.canPop()) {
      navigator.pop();
    }

    if (previousStats != null && currentStats != null) {
      await _showNewAchievementPopups(
        previous: previousStats,
        current: currentStats,
      );

      if (!mounted) {
        return;
      }
    }

    if (goHome) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    } else {
      await _loadRound();
    }
  }

  String _correctOrderText(_FirstOrderQuestion question) {
    return <String>[
      for (int index = 0; index < question.orderedItems.length; index++)
        '${index + 1}. ${question.orderedItems[index]}',
    ].join('\n');
  }

  Future<void> _finishCorrect({
    required int attemptNumber,
    required bool wasFirstGuess,
  }) async {
    final _FirstOrderQuestion? question = _question;

    if (question == null || _roundFinished) {
      return;
    }

    setState(() {
      _roundFinished = true;
      _currentOrder = List<String>.from(question.orderedItems);
    });

    final int basePoints = _basePoints[attemptNumber - 1];
    final int pointsWon =
        basePoints + (wasFirstGuess ? _firstGuessBonus : 0);
    final String orderText = _correctOrderText(question);

    if (_practiceMode) {
      unawaited(
        AnalyticsService.logGameCompleted(
          gameType: 'first_order',
          category: 'first_order',
          subcategory: 'first_order',
          questionId: question.id,
          source: 'main_game',
          result: 'correct',
          xpEarned: 0,
          firstGuess: wasFirstGuess,
          practiceMode: true,
          clueNumber: attemptNumber,
          guesses: attemptNumber,
          livesRemaining: _maximumSubmissions - attemptNumber,
          playTimeSeconds: _playTimeSeconds(),
        ),
      );

      unawaited(
        AnalyticsService.logQuestionCompleted(
          gameKey: 'first_order',
          category: 'first_order',
          subcategory: 'first_order',
          questionId: question.id,
          source: 'main_game',
          result: 'correct',
          xpEarned: 0,
          firstGuess: wasFirstGuess,
          practiceMode: true,
          clueNumber: attemptNumber,
          guesses: attemptNumber,
          livesRemaining: _maximumSubmissions - attemptNumber,
          playTimeSeconds: _playTimeSeconds(),
        ),
      );

      await _showResultDialog(
        title: 'CORRECT!',
        message: '$orderText\n\nPRACTICE MODE\n0 XP',
        success: true,
      );
      return;
    }

    await QuestionHistoryService.recordPlayedQuestion(question.id);
    await _recordContentConsumption(question.id);

    final PlayerStats previousStats = _playerStats;
    final PlayerStats updated =
        await PlayerStatsService.recordCorrectGame(
      currentStats: _playerStats,
      category: GameCategory.other,
      pointsWon: pointsWon,
      clueNumber: attemptNumber,
      wasFirstGuess: wasFirstGuess,
      playTimeSeconds: _playTimeSeconds(),
      mainCategoryKey: 'first_order',
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _playerStats = updated;
    });

    unawaited(
      AnalyticsService.logGameCompleted(
        gameType: 'first_order',
        category: 'first_order',
        subcategory: 'first_order',
        questionId: question.id,
        source: 'main_game',
        result: 'correct',
        xpEarned: pointsWon,
        firstGuess: wasFirstGuess,
        practiceMode: false,
        clueNumber: attemptNumber,
        guesses: attemptNumber,
        livesRemaining: _maximumSubmissions - attemptNumber,
        playTimeSeconds: _playTimeSeconds(),
      ),
    );

    unawaited(
      AnalyticsService.logQuestionCompleted(
        gameKey: 'first_order',
        category: 'first_order',
        subcategory: 'first_order',
        questionId: question.id,
        source: 'main_game',
        result: 'correct',
        xpEarned: pointsWon,
        firstGuess: wasFirstGuess,
        practiceMode: false,
        clueNumber: attemptNumber,
        guesses: attemptNumber,
        livesRemaining: _maximumSubmissions - attemptNumber,
        playTimeSeconds: _playTimeSeconds(),
      ),
    );

    if (wasFirstGuess) {
      unawaited(
        AnalyticsService.logFirstGuessEarned(
          gameType: 'first_order',
          category: 'first_order',
          subcategory: 'first_order',
          questionId: question.id,
          source: 'main_game',
          xpEarned: pointsWon,
          practiceMode: false,
        ),
      );
    }

    await AnalyticsService.logEarnedRewards(
      previous: previousStats,
      current: updated,
      gameKey: 'first_order',
      gameLabel: 'First Order',
    );

    await _showResultDialog(
      title: wasFirstGuess ? 'FIRST GUESS!' : 'CORRECT!',
      message: wasFirstGuess
          ? '$orderText\n\n100 XP\n50 XP First Guess Bonus\n\n150 XP TOTAL'
          : '$orderText\n\n$pointsWon XP',
      success: true,
      previousStats: previousStats,
      currentStats: updated,
    );
  }

  Future<void> _finishFailed() async {
    final _FirstOrderQuestion? question = _question;

    if (question == null || _roundFinished) {
      return;
    }

    setState(() {
      _roundFinished = true;
    });

    final String orderText = _correctOrderText(question);

    if (_practiceMode) {
      unawaited(
        AnalyticsService.logGameCompleted(
          gameType: 'first_order',
          category: 'first_order',
          subcategory: 'first_order',
          questionId: question.id,
          source: 'main_game',
          result: 'failed',
          xpEarned: 0,
          firstGuess: false,
          practiceMode: true,
          clueNumber: _submittedOrderCount,
          guesses: _submittedOrderCount,
          livesRemaining: _submissionsRemaining,
          playTimeSeconds: _playTimeSeconds(),
        ),
      );

      unawaited(
        AnalyticsService.logQuestionCompleted(
          gameKey: 'first_order',
          category: 'first_order',
          subcategory: 'first_order',
          questionId: question.id,
          source: 'main_game',
          result: 'failed',
          xpEarned: 0,
          firstGuess: false,
          practiceMode: true,
          clueNumber: _submittedOrderCount,
          guesses: _submittedOrderCount,
          livesRemaining: _submissionsRemaining,
          playTimeSeconds: _playTimeSeconds(),
        ),
      );

      await _showResultDialog(
        title: 'GAME OVER',
        message:
            'THE CORRECT ORDER WAS:\n\n$orderText\n\nPRACTICE MODE\n0 XP',
        success: false,
      );
      return;
    }

    await QuestionHistoryService.recordPlayedQuestion(question.id);
    await _recordContentConsumption(question.id);

    final PlayerStats updated =
        await PlayerStatsService.recordFailedGame(
      currentStats: _playerStats,
      playTimeSeconds: _playTimeSeconds(),
      mainCategoryKey: 'first_order',
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _playerStats = updated;
    });

    unawaited(
      AnalyticsService.logGameCompleted(
        gameType: 'first_order',
        category: 'first_order',
        subcategory: 'first_order',
        questionId: question.id,
        source: 'main_game',
        result: 'failed',
        xpEarned: 0,
        firstGuess: false,
        practiceMode: false,
        clueNumber: _submittedOrderCount,
        guesses: _submittedOrderCount,
        livesRemaining: _submissionsRemaining,
        playTimeSeconds: _playTimeSeconds(),
      ),
    );

    unawaited(
      AnalyticsService.logQuestionCompleted(
        gameKey: 'first_order',
        category: 'first_order',
        subcategory: 'first_order',
        questionId: question.id,
        source: 'main_game',
        result: 'failed',
        xpEarned: 0,
        firstGuess: false,
        practiceMode: false,
        clueNumber: _submittedOrderCount,
        guesses: _submittedOrderCount,
        livesRemaining: _submissionsRemaining,
        playTimeSeconds: _playTimeSeconds(),
      ),
    );

    await _showResultDialog(
      title: 'GAME OVER',
      message: 'THE CORRECT ORDER WAS:\n\n$orderText',
      success: false,
    );
  }

  Future<void> _showResultDialog({
    required String title,
    required String message,
    required bool success,
    PlayerStats? previousStats,
    PlayerStats? currentStats,
  }) {
    return showGameResultDialog(
      context: context,
      title: title,
      message: message,
      onPlayAgain: () {
        unawaited(
          _finishResultAction(
            goHome: false,
            previousStats: previousStats,
            currentStats: currentStats,
          ),
        );
      },
      onHome: () {
        unawaited(
          _finishResultAction(
            goHome: true,
            previousStats: previousStats,
            currentStats: currentStats,
          ),
        );
      },
      primaryButtonLabel: 'NEXT QUESTION',
      secondaryButtonLabel: 'BACK TO HOME',
    );
  }

  void _goHome() {
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.sizeOf(context);
    final bool isDesktop = screenSize.width >= 900;
    final bool showFramedLayout = screenSize.width >= 600;
    final double gameSidePadding = isDesktop ? 32 : 16;
    final double gameFrameWidth = min(
      880.0,
      screenSize.width - (gameSidePadding * 2),
    );
    final double navInset =
        ((screenSize.width - gameFrameWidth) / 2) + 14;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.white,
        elevation: 0,
        centerTitle: true,
        toolbarHeight: isDesktop ? 80 : 72,
        leadingWidth: showFramedLayout ? navInset + 48 : null,
        leading: showFramedLayout
            ? Padding(
                padding: EdgeInsets.only(left: navInset),
                child: IconButton(
                  tooltip: 'Back',
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
              )
            : null,
        title: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _goHome,
            child: SizedBox(
              height: isDesktop ? 76 : 64,
              child: Image.asset(
                'assets/images/categories/category_headers/first_order_quiz_banner.webp',
                fit: BoxFit.contain,
                filterQuality: FilterQuality.high,
              ),
            ),
          ),
        ),
        actions: <Widget>[
          Padding(
            padding: EdgeInsets.only(
              right: showFramedLayout ? navInset : 16,
            ),
            child: FirstGuessHomeButton(
              onPressed: _goHome,
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: _loading
            ? const Center(
                child: CircularProgressIndicator(
                  color: AppColors.orange,
                ),
              )
            : _question == null
                ? _buildEmptyState()
                : _buildGame(),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(
              Icons.format_list_numbered_rounded,
              color: AppColors.orange,
              size: 64,
            ),
            const SizedBox(height: 18),
            Text(
              _allQuestionsPlayed
                  ? 'ALL FIRST ORDER QUESTIONS PLAYED!'
                  : 'No live First Order questions found.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Oswald',
                color: AppColors.white,
                fontSize: 24,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              _allQuestionsPlayed
                  ? 'You have completed every live First Order question. Continue in Practice Mode for 0 XP, or return when new questions are added.'
                  : 'Import the First Order workbook into Firebase, then try again.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.grey,
              ),
            ),
            if (!_allQuestionsPlayed) ...<Widget>[
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _loadRound,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.orange,
                ),
                child: const Text('RETRY'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildGame() {
    final _FirstOrderQuestion question = _question!;
    final Size screenSize = MediaQuery.sizeOf(context);
    final bool isDesktop = screenSize.width >= 900;
    final bool compactHeight =
        screenSize.width >= 600 && screenSize.height < 820;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        isDesktop ? 32 : 16,
        compactHeight ? 2 : 6,
        isDesktop ? 32 : 16,
        compactHeight ? 6 : 28,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 880),
          child: Container(
            padding: MediaQuery.sizeOf(context).width >= 600
                ? EdgeInsets.all(compactHeight ? 10 : 14)
                : EdgeInsets.zero,
            decoration: MediaQuery.sizeOf(context).width >= 600
                ? BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: AppColors.border,
                      width: 1.3,
                    ),
                  )
                : null,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                StatsPanel(
                  totalScore: _playerStats.totalScore,
                  currentStreak: _playerStats.currentStreak,
                  firstGuesses: _playerStats.firstGuesses,
                  gamesPlayed: _playerStats.gamesPlayed,
                  showWebBorder: false,
                ),
                SizedBox(height: compactHeight ? 6 : 12),
                _buildStatusBlock(),
                SizedBox(height: compactHeight ? 8 : 16),
                _buildPrompt(question),
                _buildGameMessage(),
                SizedBox(height: _isInstalledPhone(context) ? 5 : (compactHeight ? 7 : 14)),
                _buildOrderList(isDesktop: isDesktop),
                SizedBox(height: _isInstalledPhone(context) ? 6 : (compactHeight ? 8 : 16)),
                _buildActionButtons(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGameMessage() {
    return AnimatedSwitcher(
      duration: const Duration(
        milliseconds: 250,
      ),
      transitionBuilder: (
        Widget child,
        Animation<double> animation,
      ) {
        return FadeTransition(
          opacity: animation,
          child: SizeTransition(
            sizeFactor: animation,
            child: child,
          ),
        );
      },
      child: _message == null
          ? const SizedBox(
              key: ValueKey('empty-message'),
            )
          : Padding(
              key: ValueKey(
                'error-$_message',
              ),
              padding: const EdgeInsets.only(
                top: 14,
              ),
              child: GameMessagePanel(
                message: _message!,
                type: GameMessageType.error,
              ),
            ),
    );
  }

  Widget _buildStatusBlock() {
    final int points = _currentBasePoints;

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: const Color(0xFF444444),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  'GUESS ${(_submittedOrderCount + 1).clamp(1, _maximumSubmissions)} / $_maximumSubmissions',
                  maxLines: 1,
                  style: const TextStyle(
                    fontFamily: 'Oswald',
                    color: AppColors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          LivesDisplay(
            lives: _submissionsRemaining,
            maximumLives: _maximumSubmissions,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerRight,
                child: _practiceMode
                    ? const Text(
                        'PRACTICE • 0 XP',
                        maxLines: 1,
                        style: TextStyle(
                          fontFamily: 'Oswald',
                          color: AppColors.orange,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      )
                    : _submittedOrderCount == 0
                        ? Text.rich(
                            const TextSpan(
                              children: <InlineSpan>[
                                TextSpan(
                                  text: '100 XP',
                                  style: TextStyle(
                                    fontFamily: 'Oswald',
                                    color: AppColors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                TextSpan(
                                  text: ' +50',
                                  style: TextStyle(
                                    fontFamily: 'Oswald',
                                    color: AppColors.orange,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                            maxLines: 1,
                          )
                        : Text(
                            '$points XP',
                            maxLines: 1,
                            style: const TextStyle(
                              fontFamily: 'Oswald',
                              color: AppColors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrompt(_FirstOrderQuestion question) {
    final bool isDesktop = MediaQuery.sizeOf(context).width >= 900;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 18 : 14,
        vertical: isDesktop ? 14 : 12,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF151515),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF414141),
          width: 1.2,
        ),
      ),
      child: Text(
        question.prompt.toUpperCase(),
        textAlign: TextAlign.center,
        style: TextStyle(
          fontFamily: 'Oswald',
          color: AppColors.white,
          fontSize: isDesktop ? 17 : 15,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.25,
          height: 1.18,
        ),
      ),
    );
  }

  Widget _buildOrderList({
    required bool isDesktop,
  }) {
    final bool compactHeight =
        MediaQuery.sizeOf(context).width >= 600 &&
        MediaQuery.sizeOf(context).height < 820;

    final List<int> unlockedPositions = <int>[
      for (int index = 0; index < _currentOrder.length; index++)
        if (!_lockedPositions.contains(index)) index,
    ];

    Widget buildDropZone({
      required int slot,
      required double idleHeight,
    }) {
      return DragTarget<int>(
        onWillAcceptWithDetails: (DragTargetDetails<int> details) {
          return !_roundFinished &&
              !_lockedPositions.contains(details.data);
        },
        onAcceptWithDetails: (DragTargetDetails<int> details) {
          _moveCardToSlot(details.data, slot);
        },
        builder: (
          BuildContext context,
          List<int?> candidateData,
          List<dynamic> rejectedData,
        ) {
          final bool active = candidateData.isNotEmpty;

          return AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            height: active ? max(28, idleHeight) : idleHeight,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: active
                  ? const Color(0x22FE5E02)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: active
                  ? Border.all(
                      color: AppColors.orange,
                      width: 1.5,
                    )
                  : null,
            ),
          );
        },
      );
    }

    Widget buildCard({
      required int index,
      required String item,
      required bool locked,
      required bool dragging,
    }) {
      return AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        constraints: BoxConstraints(
          minHeight: compactHeight ? 48 : (isDesktop ? 58 : 54),
        ),
        decoration: BoxDecoration(
          color: locked
              ? const Color(0xFF12311D)
              : const Color(0xFF191919),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: locked
                ? const Color(0xFF3CB963)
                : AppColors.orange,
            width: locked ? 2 : (dragging ? 1.5 : 1.0),
          ),
        ),
        child: Row(
          children: <Widget>[
            Padding(
              padding: EdgeInsets.only(
                left: isDesktop ? 12 : 10,
                right: isDesktop ? 8 : 6,
              ),
              child: locked
                  ? const SizedBox(
                      width: 22,
                      height: 30,
                      child: Center(
                        child: Icon(
                          Icons.lock_rounded,
                          color: Color(0xFF57D47A),
                          size: 22,
                        ),
                      ),
                    )
                  : const _SixDotDragGrip(
                      color: Color(0xFFD8D8D8),
                    ),
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isDesktop ? 34 : 28,
                  vertical: compactHeight ? 5 : 8,
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: Text(
                    item,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      color: AppColors.white,
                      fontSize: isDesktop ? 18 : 16,
                      fontWeight: FontWeight.w600,
                      height: 1.2,
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(width: isDesktop ? 40 : 36),
          ],
        ),
      );
    }

    final List<Widget> children = <Widget>[];

    if (unlockedPositions.isNotEmpty) {
      children.add(
        buildDropZone(
          slot: 0,
          idleHeight: _isInstalledPhone(context) ? 9 : (compactHeight ? 20 : 40),
        ),
      );
    }

    for (int index = 0; index < _currentOrder.length; index++) {
      final String item = _currentOrder[index];

      // IMPORTANT:
      // Ending the round must NOT automatically make every card
      // appear green/correct. Only positions previously confirmed
      // as correct are displayed as locked/green.
      final bool locked = _lockedPositions.contains(index);

      Widget card = buildCard(
        index: index,
        item: item,
        locked: locked,
        dragging: false,
      );

      if (!locked) {
        final int targetSlot = unlockedPositions.indexOf(index);

        final Widget target = DragTarget<int>(
          onWillAcceptWithDetails: (DragTargetDetails<int> details) {
            return details.data != index &&
                !_roundFinished &&
                !_lockedPositions.contains(details.data);
          },
          onAcceptWithDetails: (DragTargetDetails<int> details) {
            final int fromSlot = unlockedPositions.indexOf(details.data);

            int slot = targetSlot;
            if (fromSlot >= 0 && fromSlot < targetSlot) {
              slot += 1;
            }

            _moveCardToSlot(details.data, slot);
          },
          builder: (
            BuildContext context,
            List<int?> candidateData,
            List<dynamic> rejectedData,
          ) {
            return buildCard(
              index: index,
              item: item,
              locked: false,
              dragging: candidateData.isNotEmpty,
            );
          },
        );

        card = Draggable<int>(
          data: index,
          axis: Axis.vertical,
          feedback: Material(
            color: Colors.transparent,
            child: SizedBox(
              width: min(
                MediaQuery.sizeOf(context).width -
                    (isDesktop ? 64 : 32),
                880,
              ),
              child: Opacity(
                opacity: 0.94,
                child: buildCard(
                  index: index,
                  item: item,
                  locked: false,
                  dragging: true,
                ),
              ),
            ),
          ),
          childWhenDragging: Opacity(
            opacity: 0.25,
            child: target,
          ),
          child: MouseRegion(
            cursor: SystemMouseCursors.grab,
            child: target,
          ),
        );
      }

      children.add(
        Padding(
          key: ValueKey<String>(item),
          padding: EdgeInsets.zero,
          child: card,
        ),
      );

      if (index < _currentOrder.length - 1) {
        if (!locked) {
          final int slotAfter = unlockedPositions.indexOf(index) + 1;

          children.add(
            buildDropZone(
              slot: slotAfter,
              idleHeight: compactHeight ? 6 : 12,
            ),
          );
        } else {
          // Locked/correct cards keep exactly the same visual spacing
          // as movable cards so the stack never collapses together.
          children.add(
            SizedBox(height: compactHeight ? 6 : 12),
          );
        }
      } else if (!locked) {
        // Keep a larger bottom-edge target for easier dragging without
        // affecting the spacing between cards.
        final int slotAfter = unlockedPositions.indexOf(index) + 1;

        children.add(
          buildDropZone(
            slot: slotAfter,
            idleHeight: _isInstalledPhone(context) ? 9 : (compactHeight ? 20 : 40),
          ),
        );
      }
    }

    return Column(children: children);
  }

  Widget _buildActionButtons() {
    final bool enabled = !_roundFinished &&
        _submittedOrderCount < _maximumSubmissions;

    final bool compactHeight =
        MediaQuery.sizeOf(context).width >= 600 &&
        MediaQuery.sizeOf(context).height < 820;

    final double buttonHeight = compactHeight ? 44 : 48;

    return Row(
      children: <Widget>[
        Expanded(
          child: SizedBox(
            height: buttonHeight,
            child: FilledButton(
              onPressed: enabled ? _submitOrder : null,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.orange,
                foregroundColor: AppColors.white,
                disabledBackgroundColor: AppColors.darkGrey,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                'SUBMIT ORDER',
                maxLines: 1,
                style: TextStyle(
                  fontFamily: 'Oswald',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: SizedBox(
            height: buttonHeight,
            child: FilledButton(
              onPressed: enabled ? _giveUp : null,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFD32F2F),
                foregroundColor: AppColors.white,
                disabledBackgroundColor: AppColors.darkGrey,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                'GIVE UP',
                maxLines: 1,
                style: TextStyle(
                  fontFamily: 'Oswald',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}