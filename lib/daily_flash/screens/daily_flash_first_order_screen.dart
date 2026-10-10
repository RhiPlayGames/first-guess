import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../services/analytics_service.dart';
import '../../services/player_stats_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/stats_panel.dart';
import '../../widgets/lives_display.dart';
import '../../widgets/app_home_button.dart';
import '../../widgets/game_dialogs.dart';
import '../services/daily_flash_game_progress_service.dart';
import '../widgets/daily_flash_results_dialog.dart';

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

class DailyFlashFirstOrderScreen extends StatefulWidget {
  final VoidCallback? onChallengeFinished;

  const DailyFlashFirstOrderScreen({
    super.key,
    this.onChallengeFinished,
  });

  @override
  State<DailyFlashFirstOrderScreen> createState() =>
      _DailyFlashFirstOrderScreenState();
}

class _DailyFlashFirstOrderQuestion {
  final String id;
  final String prompt;
  final List<String> orderedItems;

  const _DailyFlashFirstOrderQuestion({
    required this.id,
    required this.prompt,
    required this.orderedItems,
  });
}

class _DailyFlashFirstOrderScreenState
    extends State<DailyFlashFirstOrderScreen> {
  static const int _maximumSubmissions = 3;
  static const List<int> _basePoints = <int>[100, 80, 60];
  static const int _firstGuessBonus = 50;

  DailyFlashGameProgress? _dailyProgress;
  _DailyFlashFirstOrderQuestion? _question;

  List<String> _currentOrder = <String>[];
  Set<int> _lockedPositions = <int>{};

  bool _loading = true;
  bool _roundFinished = false;
  bool _dailyComplete = false;

  int _dailyQuestionIndex = 0;
  int _submittedOrderCount = 0;

  String? _message;
  Timer? _messageTimer;
  DateTime _roundStartedAt = DateTime.now();

  int get _submissionsRemaining =>
      _maximumSubmissions - _submittedOrderCount;

  int get _currentAttemptNumber =>
      (_submittedOrderCount + 1).clamp(1, _maximumSubmissions);

  int get _pointsAvailable =>
      _basePoints[(_currentAttemptNumber - 1).clamp(
        0,
        _basePoints.length - 1,
      )];

  int get _playTimeSeconds =>
      DateTime.now().difference(_roundStartedAt).inSeconds;

  @override
  void initState() {
    super.initState();
    unawaited(_loadDisplayStats());
    _loadDailyFlash();
  }

  PlayerStats _displayStats = const PlayerStats();

  Future<void> _loadDisplayStats() async {
    try {
      final PlayerStats result = await PlayerStatsService.loadStats();
      if (mounted) setState(() => _displayStats = result);
    } catch (_) {
      // Display-only stats must not interrupt a Daily Flash question.
    }
  }

  @override
  void dispose() {
    _messageTimer?.cancel();
    super.dispose();
  }

  String _compactDateKey(String value) =>
      value.replaceAll('-', '');

  Future<void> _loadDailyFlash() async {
    _messageTimer?.cancel();

    if (mounted) {
      setState(() {
        _loading = true;
        _roundFinished = false;
        _currentOrder = <String>[];
        _lockedPositions = <int>{};
        _submittedOrderCount = 0;
        _message = null;
      });
    }

    try {
      final DailyFlashGameProgress progress =
          await DailyFlashGameProgressService.loadToday(
        gameKey: 'first_order',
      );

      final List<_DailyFlashFirstOrderQuestion> questions =
          await _loadScheduledQuestions(progress.dateKey);

      if (!mounted) {
        return;
      }

      if (questions.length != 5) {
        setState(() {
          _dailyProgress = progress;
          _question = null;
          _loading = false;
        });
        return;
      }

      if (progress.allQuestionsAttempted) {
        setState(() {
          _dailyProgress = progress;
          _dailyQuestionIndex = 5;
          _question = null;
          _dailyComplete = true;
          _loading = false;
        });

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _showCompletedTodayDialog();
          }
        });
        return;
      }

      final int index = progress.nextQuestionIndex.clamp(0, 4);
      final _DailyFlashFirstOrderQuestion selected = questions[index];
      final List<String> startingOrder =
          List<String>.from(selected.orderedItems);

      // Start each round shuffled, but never accidentally start solved.
      do {
        startingOrder.shuffle();
      } while (_sameOrder(
        startingOrder,
        selected.orderedItems,
      ));

      setState(() {
        _dailyProgress = progress;
        _dailyQuestionIndex = index;
        _question = selected;
        _currentOrder = startingOrder;
        _lockedPositions = <int>{};
        _submittedOrderCount = 0;
        _roundFinished = false;
        _dailyComplete = false;
        _message = null;
        _loading = false;
        _roundStartedAt = DateTime.now();
      });

      unawaited(
        AnalyticsService.logGameStarted(
          gameType: 'first_order',
          category: 'first_order',
          subcategory: 'first_order',
          questionId: selected.id,
          source: 'daily_flash',
          practiceMode: false,
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

  bool _sameOrder(
    List<String> a,
    List<String> b,
  ) {
    if (a.length != b.length) {
      return false;
    }

    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) {
        return false;
      }
    }

    return true;
  }

  Future<List<_DailyFlashFirstOrderQuestion>>
      _loadScheduledQuestions(String dateKey) async {
    final FirebaseFirestore firestore =
        FirebaseFirestore.instance;
    final String compact = _compactDateKey(dateKey);

    final List<
        Future<DocumentSnapshot<Map<String, dynamic>>>> reads =
        <Future<DocumentSnapshot<Map<String, dynamic>>>>[
      for (int number = 1; number <= 5; number++)
        firestore
            .collection('daily_flash_questions')
            .doc(
              'df_first_order_${compact}_${number.toString().padLeft(2, '0')}',
            )
            .get(),
    ];

    final List<DocumentSnapshot<Map<String, dynamic>>>
        snapshots = await Future.wait(reads);

    return snapshots
        .map(_questionFromSnapshot)
        .whereType<_DailyFlashFirstOrderQuestion>()
        .toList(growable: false);
  }

  _DailyFlashFirstOrderQuestion? _questionFromSnapshot(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    if (!snapshot.exists) {
      return null;
    }

    final Map<String, dynamic>? data = snapshot.data();

    if (data == null) {
      return null;
    }

    final String prompt =
        (data['prompt'] ?? '').toString().trim();

    List<String> orderedItems = <String>[];

    final dynamic rawItems = data['orderedItems'];

    if (rawItems is List) {
      orderedItems = rawItems
          .map((dynamic item) => item.toString().trim())
          .where((String item) => item.isNotEmpty)
          .toList(growable: false);
    } else {
      orderedItems = <String>[
        for (int index = 1; index <= 5; index++)
          (data['item$index'] ?? '').toString().trim(),
      ];
    }

    if (orderedItems.length != 5 ||
        orderedItems.any((String item) => item.isEmpty)) {
      return null;
    }

    return _DailyFlashFirstOrderQuestion(
      id: snapshot.id,
      prompt: prompt.isEmpty
          ? 'Put these in the correct order'
          : prompt,
      orderedItems: orderedItems,
    );
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

  Set<int> _correctPositions(
    _DailyFlashFirstOrderQuestion question,
  ) {
    final Set<int> correct = <int>{};

    for (int index = 0; index < question.orderedItems.length; index++) {
      if (_currentOrder[index] == question.orderedItems[index]) {
        correct.add(index);
      }
    }

    return correct;
  }

  Future<void> _submitOrder() async {
    final _DailyFlashFirstOrderQuestion? question = _question;

    if (question == null || _roundFinished) {
      return;
    }

    final int attemptNumber = _submittedOrderCount + 1;
    final Set<int> newlyCorrect = _correctPositions(question);
    final bool solved = newlyCorrect.length == question.orderedItems.length;

    if (solved) {
      await _finishCorrect(
        attemptNumber: attemptNumber,
      );
      return;
    }

    if (attemptNumber >= _maximumSubmissions) {
      setState(() {
        _submittedOrderCount = _maximumSubmissions;
        _lockedPositions = <int>{
          ..._lockedPositions,
          ...newlyCorrect,
        };
        _message = null;
      });
      _messageTimer?.cancel();

      _showTemporaryMessage(
        'INCORRECT — NO LIVES LEFT',
        duration: const Duration(milliseconds: 1800),
      );

      await Future<void>.delayed(
        const Duration(milliseconds: 1800),
      );

      if (!mounted) {
        return;
      }

      await _finishFailed();
      return;
    }

    setState(() {
      _submittedOrderCount = attemptNumber;
      _lockedPositions = <int>{
        ..._lockedPositions,
        ...newlyCorrect,
      };
    });

    _showTemporaryMessage(
      newlyCorrect.isEmpty
          ? 'Not quite — no positions locked. One life lost.'
          : 'Not quite — correct cards are locked. One life lost.',
    );
  }

  Future<void> _finishCorrect({
    required int attemptNumber,
  }) async {
    final _DailyFlashFirstOrderQuestion? question = _question;
    final DailyFlashGameProgress? progress = _dailyProgress;

    if (question == null ||
        progress == null ||
        _roundFinished) {
      return;
    }

    final bool wasFirstGuess = attemptNumber == 1;
    final int normalXp =
        _basePoints[(attemptNumber - 1)
                .clamp(0, _basePoints.length - 1)] +
            (wasFirstGuess ? _firstGuessBonus : 0);
    final int xpEarned = normalXp * 2;

    setState(() {
      _roundFinished = true;
      _submittedOrderCount = attemptNumber;
      _currentOrder =
          List<String>.from(question.orderedItems);
      _lockedPositions =
          <int>{0, 1, 2, 3, 4};
      _message = null;
    });

    final DailyFlashGameProgress updated =
        await DailyFlashGameProgressService.recordResult(
      gameKey: 'first_order',
      progress: progress,
      questionIndex: _dailyQuestionIndex,
      correct: true,
      xpEarned: xpEarned,
      wasFirstGuess: wasFirstGuess,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _dailyProgress = updated;
    });

    unawaited(
      AnalyticsService.logGameCompleted(
        gameType: 'first_order',
        category: 'first_order',
        subcategory: 'first_order',
        questionId: question.id,
        source: 'daily_flash',
        result: 'correct',
        xpEarned: xpEarned,
        firstGuess: wasFirstGuess,
        practiceMode: false,
        clueNumber: attemptNumber,
        guesses: attemptNumber,
        livesRemaining:
            _maximumSubmissions - attemptNumber + 1,
        playTimeSeconds: _playTimeSeconds,
      ),
    );

    await _showResultDialog(
      title: wasFirstGuess ? 'FIRST GUESS!' : 'CORRECT!',
      message: '$xpEarned XP',
      success: true,
    );
  }

  Future<void> _finishFailed() async {
    final _DailyFlashFirstOrderQuestion? question = _question;
    final DailyFlashGameProgress? progress = _dailyProgress;

    if (question == null ||
        progress == null ||
        _roundFinished) {
      return;
    }

    setState(() {
      _roundFinished = true;
      _currentOrder =
          List<String>.from(question.orderedItems);
      _message = null;
    });

    final DailyFlashGameProgress updated =
        await DailyFlashGameProgressService.recordResult(
      gameKey: 'first_order',
      progress: progress,
      questionIndex: _dailyQuestionIndex,
      correct: false,
      xpEarned: 0,
      wasFirstGuess: false,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _dailyProgress = updated;
    });

    unawaited(
      AnalyticsService.logGameCompleted(
        gameType: 'first_order',
        category: 'first_order',
        subcategory: 'first_order',
        questionId: question.id,
        source: 'daily_flash',
        result: 'failed',
        xpEarned: 0,
        firstGuess: false,
        practiceMode: false,
        clueNumber: _submittedOrderCount.clamp(1, _maximumSubmissions),
        guesses: _submittedOrderCount,
        livesRemaining: 0,
        playTimeSeconds: _playTimeSeconds,
      ),
    );

    await _showResultDialog(
      title: 'GAME OVER',
      message:
          'THE CORRECT ORDER WAS:\n\n${_correctOrderText(question)}',
      success: false,
    );
  }

  Future<void> _giveUp() async {
    final _DailyFlashFirstOrderQuestion? question = _question;
    final DailyFlashGameProgress? progress = _dailyProgress;

    if (question == null ||
        progress == null ||
        _roundFinished) {
      return;
    }

    setState(() {
      _roundFinished = true;
      _currentOrder =
          List<String>.from(question.orderedItems);
      _message = null;
    });

    final DailyFlashGameProgress updated =
        await DailyFlashGameProgressService.recordResult(
      gameKey: 'first_order',
      progress: progress,
      questionIndex: _dailyQuestionIndex,
      correct: false,
      xpEarned: 0,
      wasFirstGuess: false,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _dailyProgress = updated;
    });

    await _showResultDialog(
      title: 'YOU GAVE UP!',
      message:
          'THE CORRECT ORDER WAS:\n\n${_correctOrderText(question)}',
      success: false,
    );
  }

  String _correctOrderText(
    _DailyFlashFirstOrderQuestion question,
  ) {
    return <String>[
      for (int index = 0;
          index < question.orderedItems.length;
          index++)
        '${index + 1}. ${question.orderedItems[index]}',
    ].join('\n');
  }

  Future<void> _showResultDialog({
    required String title,
    required String message,
    required bool success,
  }) {
    return showGameResultDialog(
      context: context,
      title: title,
      message: message,
      imageAsset: title == 'YOU GAVE UP!'
          ? 'assets/images/ui/popups/give_up.webp'
          : null,
      onPlayAgain: () {
        unawaited(_advanceAfterResult());
      },
      onHome: () {
        Navigator.of(context, rootNavigator: true).pop();
        if (mounted) {
          Navigator.of(context).maybePop();
        }
      },
      primaryButtonLabel: 'NEXT QUESTION',
      secondaryButtonLabel: 'BACK TO DAILY FLASH',
    );
  }

  Future<void> _advanceAfterResult() async {
    if (!mounted) {
      return;
    }

    final DailyFlashGameProgress? progress = _dailyProgress;

    if (progress == null) {
      return;
    }

    if (progress.allQuestionsAttempted) {
      await _finishDailyFlash();
      return;
    }

    await _loadDailyFlash();
  }

  Future<void> _finishDailyFlash() async {
    if (_dailyComplete) {
      return;
    }

    final DailyFlashGameProgress? progress = _dailyProgress;

    if (progress == null ||
        !progress.allQuestionsAttempted) {
      return;
    }

    _dailyComplete = true;

    final bool perfect =
        progress.questionsCorrect == 5;

    await DailyFlashMilestoneService
        .recordCompletionAndAwardIfEarned(
      perfect: perfect,
      gameKey: 'first_order',
    );

    await PlayerStatsService.addBonusXp(
      xp: progress.totalXp,
    );

    if (!mounted) {
      return;
    }

    final int baseXp = progress.totalXp ~/ 2;
    final int bonusXp = progress.totalXp - baseXp;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return DailyFlashResultsDialog(
          perfect: perfect,
          score: progress.questionsCorrect,
          baseXp: baseXp,
          bonusXp: bonusXp,
          totalXp: progress.totalXp,
          hasMilestone: false,
          onContinue: () {
            Navigator.of(dialogContext).pop();
          },
        );
      },
    );

    if (!mounted) {
      return;
    }

    widget.onChallengeFinished?.call();
    Navigator.of(context).maybePop();
  }

  Future<void> _showCompletedTodayDialog() async {
    final DailyFlashGameProgress? progress = _dailyProgress;

    if (progress == null || !mounted) {
      return;
    }

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.panel,
          title: const Text(
            'FIRST ORDER COMPLETE',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Oswald',
              color: AppColors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: Text(
            '${progress.questionsCorrect}/5 correct\n'
            '${progress.totalXp} XP earned today',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.white,
              height: 1.45,
            ),
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: <Widget>[
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.orange,
                foregroundColor: AppColors.white,
              ),
              onPressed: () =>
                  Navigator.of(dialogContext).pop(),
              child: const Text(
                'BACK',
                style: TextStyle(
                  fontFamily: 'Oswald',
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (!mounted) {
      return;
    }

    Navigator.of(context).maybePop();
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



  void _goBack() {
    Navigator.of(context).maybePop();
  }

  void _goHome() {
    Navigator.of(context).popUntil(
      (Route<dynamic> route) => route.isFirst,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _DailyFlashGameHeader(
        onBack: _goBack,
        onHome: _goHome,
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
            const SizedBox(height: 16),
            const Text(
              'TODAY’S FIRST ORDER\nDAILY FLASH IS NOT READY YET.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Oswald',
                color: AppColors.white,
                fontSize: 22,
                fontWeight: FontWeight.w700,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 20),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.orange,
                foregroundColor: AppColors.white,
              ),
              onPressed: _goBack,
              child: const Text(
                'BACK TO DAILY FLASH',
                style: TextStyle(
                  fontFamily: 'Oswald',
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGame() {
    final _DailyFlashFirstOrderQuestion question = _question!;
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
                  totalScore: _displayStats.totalScore,
                  currentStreak: _displayStats.currentStreak,
                  firstGuesses: _displayStats.firstGuesses,
                  gamesPlayed: _displayStats.gamesPlayed,
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
    final int points = _pointsAvailable * 2;

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
                child: _submittedOrderCount == 0
                        ? Text.rich(
                            const TextSpan(
                              children: <InlineSpan>[
                                TextSpan(
                                  text: '200 XP',
                                  style: TextStyle(
                                    fontFamily: 'Oswald',
                                    color: AppColors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                TextSpan(
                                  text: ' +100',
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

  Widget _buildPrompt(_DailyFlashFirstOrderQuestion question) {
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
          idleHeight: _isInstalledPhone(context) ? 17 : (compactHeight ? 20 : 40),
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
            idleHeight: _isInstalledPhone(context) ? 17 : (compactHeight ? 20 : 40),
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
                backgroundColor: _isInstalledPhone(context) ? const Color(0xFFFE5E02) : AppColors.orange,
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

class _DailyFlashGameHeader extends StatelessWidget
    implements PreferredSizeWidget {
  final VoidCallback onBack;
  final VoidCallback onHome;

  const _DailyFlashGameHeader({
    required this.onBack,
    required this.onHome,
  });

  @override
  Size get preferredSize =>
      const Size.fromHeight(62);

  @override
  Widget build(BuildContext context) {
    final bool isSmall =
        MediaQuery.sizeOf(context).width < 600;

    return Material(
      color: AppColors.background,
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: isSmall ? 53 : 62,
          child: Stack(
            alignment: Alignment.center,
            children: <Widget>[
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  tooltip: 'Back',
                  onPressed: onBack,
                  padding: EdgeInsets.zero,
                  visualDensity:
                      VisualDensity.compact,
                  icon: Icon(
                    Icons.arrow_back_rounded,
                    color: AppColors.white,
                    size: isSmall ? 28 : 32,
                  ),
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding:
                      const EdgeInsets.only(
                    right: 14,
                  ),
                  child: FirstGuessHomeButton(
                    onPressed: onHome,
                  ),
                ),
              ),
              Row(
                mainAxisSize:
                    MainAxisSize.min,
                children: <Widget>[
                  Icon(
                    Icons.bolt_rounded,
                    color: AppColors.orange,
                    size: isSmall ? 28 : 34,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    'DAILY FLASH 5',
                    maxLines: 1,
                    style: TextStyle(
                      fontFamily: 'Oswald',
                      color: AppColors.white,
                      fontSize:
                          isSmall ? 25 : 30,
                      fontWeight:
                          FontWeight.w700,
                      letterSpacing: 0.55,
                      height: 1,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Icon(
                    Icons.bolt_rounded,
                    color: AppColors.orange,
                    size: isSmall ? 28 : 34,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
