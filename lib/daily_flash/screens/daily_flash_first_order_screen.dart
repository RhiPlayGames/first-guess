import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../services/analytics_service.dart';
import '../../services/player_stats_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_home_button.dart';
import '../services/daily_flash_game_progress_service.dart';

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
    _loadDailyFlash();
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
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.panel,
          title: Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Oswald',
              color: AppColors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: Text(
            message,
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
              onPressed: () {
                Navigator.of(dialogContext).pop();
                unawaited(_advanceAfterResult());
              },
              child: const Text(
                'NEXT QUESTION',
                style: TextStyle(
                  fontFamily: 'Oswald',
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                Navigator.of(context).maybePop();
              },
              child: const Text(
                'BACK TO DAILY FLASH',
                style: TextStyle(
                  fontFamily: 'Oswald',
                  color: AppColors.grey,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
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

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.panel,
          title: Text(
            perfect
                ? 'PERFECT 5!'
                : 'DAILY FLASH 5 COMPLETE',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Oswald',
              color: AppColors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: Text(
            '${progress.questionsCorrect}/5 correct\n'
            '${progress.firstGuesses} First Guesses\n\n'
            '${progress.totalXp} XP earned',
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
                'CONTINUE',
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

  void _moveItem(
    int oldIndex,
    int newIndex,
  ) {
    if (_roundFinished) {
      return;
    }

    if (_lockedPositions.contains(oldIndex)) {
      return;
    }

    if (newIndex < 0 ||
        newIndex >= _currentOrder.length) {
      return;
    }

    if (_lockedPositions.contains(newIndex)) {
      return;
    }

    setState(() {
      final String item =
          _currentOrder.removeAt(oldIndex);
      _currentOrder.insert(newIndex, item);
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
    final _DailyFlashFirstOrderQuestion question =
        _question!;
    final bool isDesktop =
        MediaQuery.sizeOf(context).width >= 900;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        isDesktop ? 32 : 16,
        6,
        isDesktop ? 32 : 16,
        28,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints:
              const BoxConstraints(maxWidth: 880),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.stretch,
            children: <Widget>[
              _buildDailyProgressStrip(),
              const SizedBox(height: 10),
              if (_message != null) ...<Widget>[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF151515),
                    borderRadius:
                        BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.orange,
                    ),
                  ),
                  child: Text(
                    _message!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              _buildStatusBlock(),
              const SizedBox(height: 12),
              _buildPromptCard(question.prompt),
              const SizedBox(height: 12),
              ReorderableListView.builder(
                shrinkWrap: true,
                physics:
                    const NeverScrollableScrollPhysics(),
                itemCount: _currentOrder.length,
                onReorderItem: _moveItem,
                buildDefaultDragHandles: false,
                itemBuilder:
                    (BuildContext context, int index) {
                  final bool locked =
                      _lockedPositions.contains(index);

                  return Container(
                    key: ValueKey<String>(
                      '${_currentOrder[index]}-$index',
                    ),
                    margin:
                        const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: locked
                          ? const Color(0xFF1B3A24)
                          : const Color(0xFF151515),
                      borderRadius:
                          BorderRadius.circular(12),
                      border: Border.all(
                        color: locked
                            ? Colors.green
                            : const Color(0xFF444444),
                        width: 1,
                      ),
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        radius: 16,
                        backgroundColor:
                            AppColors.orange,
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(
                            color: AppColors.white,
                            fontFamily: 'Oswald',
                            fontWeight:
                                FontWeight.w700,
                          ),
                        ),
                      ),
                      title: Text(
                        _currentOrder[index],
                        style: const TextStyle(
                          color: AppColors.white,
                          fontWeight:
                              FontWeight.w600,
                        ),
                      ),
                      trailing: locked
                          ? const Icon(
                              Icons.check_circle_rounded,
                              color: Colors.green,
                            )
                          : ReorderableDragStartListener(
                              index: index,
                              child: const Icon(
                                Icons.drag_indicator_rounded,
                                color: AppColors.grey,
                              ),
                            ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 8),
              _buildButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDailyProgressStrip() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF151515),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.orange,
          width: 1,
        ),
      ),
      child: Row(
        children: <Widget>[
          const Icon(
            Icons.format_list_numbered_rounded,
            color: AppColors.orange,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'FIRST ORDER • QUESTION ${_dailyQuestionIndex + 1} OF 5',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'Oswald',
                color: AppColors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 8),
          const Text(
            '2× XP',
            style: TextStyle(
              fontFamily: 'Oswald',
              color: AppColors.orange,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBlock() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: const Color(0xFF444444),
          width: 1,
        ),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              'ATTEMPT $_currentAttemptNumber / $_maximumSubmissions',
              style: const TextStyle(
                fontFamily: 'Oswald',
                color: AppColors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              for (int index = 0;
                  index < _maximumSubmissions;
                  index++)
                Padding(
                  padding:
                      const EdgeInsets.symmetric(
                    horizontal: 2,
                  ),
                  child: Icon(
                    Icons.favorite_rounded,
                    size: 22,
                    color:
                        index < _submissionsRemaining
                            ? AppColors.orange
                            : const Color(0xFF555555),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: _currentAttemptNumber == 1
                    ? Text.rich(
                        const TextSpan(
                          children: <InlineSpan>[
                            TextSpan(
                              text: '200 XP',
                              style: TextStyle(
                                fontFamily: 'Oswald',
                                color: AppColors.white,
                                fontSize: 15,
                                fontWeight:
                                    FontWeight.w600,
                              ),
                            ),
                            TextSpan(
                              text: ' +100',
                              style: TextStyle(
                                fontFamily: 'Oswald',
                                color: AppColors.orange,
                                fontSize: 15,
                                fontWeight:
                                    FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      )
                    : Text(
                        '${_pointsAvailable * 2} XP',
                        style: const TextStyle(
                          fontFamily: 'Oswald',
                          color: AppColors.white,
                          fontSize: 16,
                          fontWeight:
                              FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPromptCard(String prompt) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 16,
      ),
      decoration: BoxDecoration(
        color: AppColors.panel,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.orange,
          width: 1.2,
        ),
      ),
      child: Text(
        prompt,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontFamily: 'Oswald',
          color: AppColors.white,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          height: 1.25,
        ),
      ),
    );
  }

  Widget _buildButtons() {
    return Column(
      children: <Widget>[
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.orange,
              foregroundColor: AppColors.white,
              padding: const EdgeInsets.symmetric(
                vertical: 14,
              ),
            ),
            onPressed: _roundFinished
                ? null
                : () => unawaited(_submitOrder()),
            child: const Text(
              'SUBMIT ORDER',
              style: TextStyle(
                fontFamily: 'Oswald',
                fontWeight: FontWeight.w700,
                fontSize: 17,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: _roundFinished
              ? null
              : () => unawaited(_giveUp()),
          child: const Text(
            'GIVE UP',
            style: TextStyle(
              fontFamily: 'Oswald',
              color: AppColors.grey,
              fontWeight: FontWeight.w600,
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
