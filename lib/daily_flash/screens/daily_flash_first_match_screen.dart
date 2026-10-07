import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../services/analytics_service.dart';
import '../../services/player_stats_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_home_button.dart';
import '../../widgets/game_dialogs.dart';
import '../../widgets/lives_display.dart';
import '../services/daily_flash_game_progress_service.dart';

class DailyFlashFirstMatchScreen extends StatefulWidget {
  final VoidCallback? onChallengeFinished;

  const DailyFlashFirstMatchScreen({
    super.key,
    this.onChallengeFinished,
  });

  @override
  State<DailyFlashFirstMatchScreen> createState() =>
      _DailyFlashFirstMatchScreenState();
}

class _FirstMatchPair {
  final String left;
  final String right;

  const _FirstMatchPair({
    required this.left,
    required this.right,
  });
}

class _DailyFlashFirstMatchQuestion {
  final String id;
  final List<_FirstMatchPair> pairs;

  const _DailyFlashFirstMatchQuestion({
    required this.id,
    required this.pairs,
  });
}

class _DailyFlashFirstMatchScreenState
    extends State<DailyFlashFirstMatchScreen> {
  static const int _pairCount = 6;
  static const int _maximumLives = 3;
  static const List<int> _basePoints = <int>[100, 80, 60];
  static const int _firstGuessBonus = 50;

  final Random _random = Random();

  DailyFlashGameProgress? _dailyProgress;
  _DailyFlashFirstMatchQuestion? _question;

  List<String> _rightChoices = <String>[];
  final Map<int, int> _tentativeMatches = <int, int>{};
  final Set<int> _lockedLeftIndexes = <int>{};
  final Set<int> _lockedRightIndexes = <int>{};

  int? _selectedLeftIndex;
  int _dailyQuestionIndex = 0;
  int _lives = _maximumLives;
  int _submittedBoards = 0;

  bool _loading = true;
  bool _roundFinished = false;
  bool _dailyComplete = false;

  String? _message;
  Timer? _messageTimer;
  DateTime _roundStartedAt = DateTime.now();

  int get _currentSubmissionNumber =>
      (_submittedBoards + 1).clamp(1, _basePoints.length);

  int get _pointsAvailable =>
      _basePoints[_currentSubmissionNumber - 1];

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
        _selectedLeftIndex = null;
        _tentativeMatches.clear();
        _lockedLeftIndexes.clear();
        _lockedRightIndexes.clear();
        _rightChoices = <String>[];
        _lives = _maximumLives;
        _submittedBoards = 0;
        _message = null;
      });
    }

    try {
      final DailyFlashGameProgress progress =
          await DailyFlashGameProgressService.loadToday(
        gameKey: 'first_match',
      );

      final List<_DailyFlashFirstMatchQuestion> questions =
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

      final int index =
          progress.nextQuestionIndex.clamp(0, 4);
      final _DailyFlashFirstMatchQuestion selected =
          questions[index];

      final List<String> shuffled = selected.pairs
          .map((_FirstMatchPair pair) => pair.right)
          .toList()
        ..shuffle(_random);

      setState(() {
        _dailyProgress = progress;
        _dailyQuestionIndex = index;
        _question = selected;
        _rightChoices = shuffled;
        _dailyComplete = false;
        _roundFinished = false;
        _selectedLeftIndex = null;
        _tentativeMatches.clear();
        _lockedLeftIndexes.clear();
        _lockedRightIndexes.clear();
        _lives = _maximumLives;
        _submittedBoards = 0;
        _message = null;
        _loading = false;
        _roundStartedAt = DateTime.now();
      });

      unawaited(
        AnalyticsService.logGameStarted(
          gameType: 'first_match',
          category: 'first_match',
          subcategory: 'first_match',
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

  Future<List<_DailyFlashFirstMatchQuestion>>
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
              'df_first_match_${compact}_${number.toString().padLeft(2, '0')}',
            )
            .get(),
    ];

    final List<DocumentSnapshot<Map<String, dynamic>>>
        snapshots = await Future.wait(reads);

    return snapshots
        .map(_questionFromSnapshot)
        .whereType<_DailyFlashFirstMatchQuestion>()
        .toList(growable: false);
  }

  _DailyFlashFirstMatchQuestion? _questionFromSnapshot(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    if (!snapshot.exists) {
      return null;
    }

    final Map<String, dynamic>? data = snapshot.data();

    if (data == null) {
      return null;
    }

    final List<_FirstMatchPair> pairs =
        <_FirstMatchPair>[];

    final dynamic rawPairs = data['pairs'];

    if (rawPairs is List && rawPairs.length == _pairCount) {
      for (final dynamic item in rawPairs) {
        if (item is! Map) {
          return null;
        }

        final String left =
            (item['left'] ?? '').toString().trim();
        final String right =
            (item['right'] ?? '').toString().trim();

        if (left.isEmpty || right.isEmpty) {
          return null;
        }

        pairs.add(
          _FirstMatchPair(
            left: left,
            right: right,
          ),
        );
      }
    } else {
      for (int index = 1; index <= _pairCount; index++) {
        final String left = (data['pair${index}Left'] ??
                data['left$index'] ??
                '')
            .toString()
            .trim();
        final String right = (data['pair${index}Right'] ??
                data['right$index'] ??
                '')
            .toString()
            .trim();

        if (left.isEmpty || right.isEmpty) {
          return null;
        }

        pairs.add(
          _FirstMatchPair(
            left: left,
            right: right,
          ),
        );
      }
    }

    return _DailyFlashFirstMatchQuestion(
      id: snapshot.id,
      pairs: pairs,
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

  void _selectLeft(int index) {
    if (_roundFinished ||
        _lockedLeftIndexes.contains(index)) {
      return;
    }

    setState(() {
      _selectedLeftIndex = index;
    });
  }

  void _selectRight(int rightIndex) {
    final int? leftIndex = _selectedLeftIndex;

    if (_roundFinished ||
        leftIndex == null ||
        _lockedRightIndexes.contains(rightIndex)) {
      return;
    }

    setState(() {
      _tentativeMatches.removeWhere(
        (int left, int right) =>
            left == leftIndex || right == rightIndex,
      );
      _tentativeMatches[leftIndex] = rightIndex;
      _selectedLeftIndex = null;
    });
  }

  bool _isCorrectPair(
    _DailyFlashFirstMatchQuestion question,
    int leftIndex,
    int rightIndex,
  ) {
    final String expected =
        question.pairs[leftIndex].right;
    final String selected =
        _rightChoices[rightIndex];

    return expected == selected;
  }

  Future<void> _submitBoard() async {
    final _DailyFlashFirstMatchQuestion? question =
        _question;

    if (question == null || _roundFinished) {
      return;
    }

    final List<int> unlockedLeft = <int>[
      for (int i = 0; i < question.pairs.length; i++)
        if (!_lockedLeftIndexes.contains(i)) i,
    ];

    final bool allMatched = unlockedLeft.every(
      (int index) => _tentativeMatches.containsKey(index),
    );

    if (!allMatched) {
      _showTemporaryMessage(
        'Match every remaining item before submitting.',
      );
      return;
    }

    final int attemptNumber = _submittedBoards + 1;

    final Set<int> newlyCorrectLeft = <int>{};
    final Set<int> newlyCorrectRight = <int>{};

    for (final MapEntry<int, int> entry
        in _tentativeMatches.entries) {
      if (_isCorrectPair(
        question,
        entry.key,
        entry.value,
      )) {
        newlyCorrectLeft.add(entry.key);
        newlyCorrectRight.add(entry.value);
      }
    }

    final bool boardComplete =
        _lockedLeftIndexes.length +
                newlyCorrectLeft.length ==
            _pairCount;

    if (boardComplete) {
      await _finishCorrect(
        attemptNumber: attemptNumber,
      );
      return;
    }

    final int remainingLives = _lives - 1;

    setState(() {
      _submittedBoards = attemptNumber;
      _lives = remainingLives;
      _lockedLeftIndexes.addAll(newlyCorrectLeft);
      _lockedRightIndexes.addAll(newlyCorrectRight);
      _tentativeMatches.removeWhere(
        (int left, int right) =>
            !newlyCorrectLeft.contains(left),
      );
      _selectedLeftIndex = null;
    });

    if (remainingLives <= 0) {
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

    _showTemporaryMessage(
      newlyCorrectLeft.isEmpty
          ? 'No new matches. One life lost.'
          : '${newlyCorrectLeft.length} correct. Those matches are locked.',
    );
  }

  Future<void> _finishCorrect({
    required int attemptNumber,
  }) async {
    final _DailyFlashFirstMatchQuestion? question =
        _question;
    final DailyFlashGameProgress? progress =
        _dailyProgress;

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
      _submittedBoards = attemptNumber;
      _lockedLeftIndexes
        ..clear()
        ..addAll(
          List<int>.generate(_pairCount, (int i) => i),
        );
      _lockedRightIndexes
        ..clear()
        ..addAll(
          List<int>.generate(_pairCount, (int i) => i),
        );
      _message = null;
    });

    final DailyFlashGameProgress updated =
        await DailyFlashGameProgressService.recordResult(
      gameKey: 'first_match',
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
        gameType: 'first_match',
        category: 'first_match',
        subcategory: 'first_match',
        questionId: question.id,
        source: 'daily_flash',
        result: 'correct',
        xpEarned: xpEarned,
        firstGuess: wasFirstGuess,
        practiceMode: false,
        clueNumber: attemptNumber,
        guesses: attemptNumber,
        livesRemaining: _lives,
        playTimeSeconds: _playTimeSeconds,
      ),
    );

    await _showResultDialog(
      title:
          wasFirstGuess ? 'FIRST GUESS!' : 'MATCHED!',
      message: '$xpEarned XP',
      success: true,
    );
  }

  Future<void> _finishFailed() async {
    final _DailyFlashFirstMatchQuestion? question =
        _question;
    final DailyFlashGameProgress? progress =
        _dailyProgress;

    if (question == null ||
        progress == null ||
        _roundFinished) {
      return;
    }

    setState(() {
      _roundFinished = true;
      _message = null;
    });

    final DailyFlashGameProgress updated =
        await DailyFlashGameProgressService.recordResult(
      gameKey: 'first_match',
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
        gameType: 'first_match',
        category: 'first_match',
        subcategory: 'first_match',
        questionId: question.id,
        source: 'daily_flash',
        result: 'failed',
        xpEarned: 0,
        firstGuess: false,
        practiceMode: false,
        clueNumber: _submittedBoards.clamp(1, _maximumLives),
        guesses: _submittedBoards,
        livesRemaining: _lives,
        playTimeSeconds: _playTimeSeconds,
      ),
    );

    await _showResultDialog(
      title: 'GAME OVER',
      message: 'The board was not completed.',
      success: false,
    );
  }

  Future<void> _giveUp() async {
    final DailyFlashGameProgress? progress =
        _dailyProgress;
    final _DailyFlashFirstMatchQuestion? question =
        _question;

    if (progress == null ||
        question == null ||
        _roundFinished) {
      return;
    }

    setState(() {
      _roundFinished = true;
      _message = null;
    });

    final DailyFlashGameProgress updated =
        await DailyFlashGameProgressService.recordResult(
      gameKey: 'first_match',
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
      message: 'The board was not completed.',
      success: false,
    );
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
        Navigator.of(
          context,
          rootNavigator: true,
        ).pop();

        if (mounted) {
          Navigator.of(context).maybePop();
        }
      },
      primaryButtonLabel: 'NEXT QUESTION',
      secondaryButtonLabel: 'BACK TO DAILY FLASH',
    );
  }

  Future<void> _advanceAfterResult() async {
    final NavigatorState rootNavigator =
        Navigator.of(context, rootNavigator: true);

    if (rootNavigator.canPop()) {
      rootNavigator.pop();
    }

    if (!mounted) {
      return;
    }

    final DailyFlashGameProgress? progress =
        _dailyProgress;

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

    final DailyFlashGameProgress? progress =
        _dailyProgress;

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
      gameKey: 'first_match',
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
    final DailyFlashGameProgress? progress =
        _dailyProgress;

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
            'FIRST MATCH COMPLETE',
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
          actionsAlignment:
              MainAxisAlignment.center,
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
              Icons.compare_arrows_rounded,
              color: AppColors.orange,
              size: 64,
            ),
            const SizedBox(height: 16),
            const Text(
              'TODAY’S FIRST MATCH\nDAILY FLASH IS NOT READY YET.',
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
    final _DailyFlashFirstMatchQuestion question =
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
              _buildInstructionStrip(),
              const SizedBox(height: 12),
              _buildBoard(question),
              const SizedBox(height: 14),
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
            Icons.compare_arrows_rounded,
            color: AppColors.orange,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'FIRST MATCH • QUESTION ${_dailyQuestionIndex + 1} OF 5',
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
    final int correct =
        _lockedLeftIndexes.length;

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
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                'MATCHES $correct / 6',
                style: const TextStyle(
                  fontFamily: 'Oswald',
                  color: AppColors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          LivesDisplay(
            lives: _lives,
            maximumLives: _maximumLives,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: _currentSubmissionNumber == 1
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

  Widget _buildInstructionStrip() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF151515),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFF3E3E3E),
          width: 1,
        ),
      ),
      child: const Text(
        'SELECT A LEFT ITEM, THEN CHOOSE ITS MATCH ON THE RIGHT',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontFamily: 'Oswald',
          color: AppColors.white,
          fontSize: 17,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  Widget _buildBoard(
    _DailyFlashFirstMatchQuestion question,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          child: Column(
            children: <Widget>[
              const _ColumnHeading('MATCH'),
              const SizedBox(height: 8),
              for (int i = 0;
                  i < question.pairs.length;
                  i++) ...<Widget>[
                _buildLeftTile(question, i),
                if (i != question.pairs.length - 1)
                  const SizedBox(height: 8),
              ],
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            children: <Widget>[
              const _ColumnHeading('WITH'),
              const SizedBox(height: 8),
              for (int i = 0;
                  i < _rightChoices.length;
                  i++) ...<Widget>[
                _buildRightTile(i),
                if (i != _rightChoices.length - 1)
                  const SizedBox(height: 8),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLeftTile(
    _DailyFlashFirstMatchQuestion question,
    int index,
  ) {
    final bool locked =
        _lockedLeftIndexes.contains(index);
    final bool selected =
        _selectedLeftIndex == index;
    final int? matchedRight =
        _tentativeMatches[index];

    return InkWell(
      onTap: locked ? null : () => _selectLeft(index),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        constraints:
            const BoxConstraints(minHeight: 58),
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: locked
              ? const Color(0xFF1B3A24)
              : selected
                  ? const Color(0xFF2A1C13)
                  : const Color(0xFF151515),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: locked
                ? Colors.green
                : selected
                    ? AppColors.orange
                    : const Color(0xFF444444),
            width: selected ? 1.8 : 1,
          ),
        ),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Text(
                question.pairs[index].left,
                style: const TextStyle(
                  color: AppColors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (locked)
              const Icon(
                Icons.check_circle_rounded,
                color: Colors.green,
                size: 20,
              )
            else if (matchedRight != null)
              const Icon(
                Icons.link_rounded,
                color: AppColors.orange,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRightTile(int index) {
    final bool locked =
        _lockedRightIndexes.contains(index);
    final bool chosen =
        _tentativeMatches.containsValue(index);

    return InkWell(
      onTap: locked ? null : () => _selectRight(index),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        constraints:
            const BoxConstraints(minHeight: 58),
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: locked
              ? const Color(0xFF1B3A24)
              : chosen
                  ? const Color(0xFF2A1C13)
                  : const Color(0xFF151515),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: locked
                ? Colors.green
                : chosen
                    ? AppColors.orange
                    : const Color(0xFF444444),
            width: chosen ? 1.8 : 1,
          ),
        ),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Text(
                _rightChoices[index],
                style: const TextStyle(
                  color: AppColors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (locked)
              const Icon(
                Icons.check_circle_rounded,
                color: Colors.green,
                size: 20,
              ),
          ],
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
                : () => unawaited(_submitBoard()),
            child: const Text(
              'SUBMIT MATCHES',
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

class _ColumnHeading extends StatelessWidget {
  final String text;

  const _ColumnHeading(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontFamily: 'Oswald',
        color: AppColors.orange,
        fontSize: 16,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.5,
      ),
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
