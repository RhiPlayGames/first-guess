import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../services/analytics_service.dart';
import '../../services/player_stats_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/stats_panel.dart';
import '../../widgets/app_home_button.dart';
import '../../widgets/game_dialogs.dart';
import '../../widgets/lives_display.dart';
import '../services/daily_flash_game_progress_service.dart';
import '../widgets/daily_flash_results_dialog.dart';

bool _isInstalledPhone(BuildContext context) {
  const bool isWeb = bool.fromEnvironment('dart.library.js_interop');
  final TargetPlatform platform = Theme.of(context).platform;
  return !isWeb &&
      (platform == TargetPlatform.iOS || platform == TargetPlatform.android) &&
      MediaQuery.sizeOf(context).shortestSide < 600;
}

class DailyFlashFirstDateScreen extends StatefulWidget {
  final VoidCallback? onChallengeFinished;

  const DailyFlashFirstDateScreen({
    super.key,
    this.onChallengeFinished,
  });

  @override
  State<DailyFlashFirstDateScreen> createState() =>
      _DailyFlashFirstDateScreenState();
}

class _DailyFlashFirstDateQuestion {
  final String id;
  final String prompt;
  final String answerType;
  final String answer;
  final Set<String> acceptedAnswers;
  final List<String> clues;

  const _DailyFlashFirstDateQuestion({
    required this.id,
    required this.prompt,
    required this.answerType,
    required this.answer,
    required this.acceptedAnswers,
    required this.clues,
  });
}

class _DailyFlashFirstDateScreenState
    extends State<DailyFlashFirstDateScreen> {
  static const int _maximumLives = 3;
  static const int _firstGuessBonus = 50;
  static const List<int> _basePoints = <int>[
    100,
    90,
    80,
    70,
    60,
    50,
    40,
    30,
    20,
    10,
  ];

  final TextEditingController _answerController =
      TextEditingController();
  final FocusNode _answerFocusNode = FocusNode();

  DailyFlashGameProgress? _dailyProgress;
  _DailyFlashFirstDateQuestion? _question;

  bool _loading = true;
  bool _roundFinished = false;
  bool _submitting = false;
  bool _dailyComplete = false;

  int _dailyQuestionIndex = 0;
  int _clueIndex = 0;
  int _lives = _maximumLives;

  String? _message;
  GameMessageType _messageType = GameMessageType.error;
  Timer? _messageTimer;
  DateTime _roundStartedAt = DateTime.now();

  int get _currentClueNumber => _clueIndex + 1;

  int get _pointsAvailable =>
      _roundFinished ? 0 : _basePoints[_clueIndex.clamp(0, 9)];

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
    _answerController.dispose();
    _answerFocusNode.dispose();
    super.dispose();
  }

  String _todayKey() {
    final DateTime now = DateTime.now();
    return '${now.year.toString().padLeft(4, '0')}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
  }

  String _compactDateKey(String dateKey) =>
      dateKey.replaceAll('-', '');

  Future<void> _loadDailyFlash() async {
    _messageTimer?.cancel();
    _answerController.clear();

    if (mounted) {
      setState(() {
        _loading = true;
        _roundFinished = false;
        _submitting = false;
        _clueIndex = 0;
        _lives = _maximumLives;
        _message = null;
      });
    }

    try {
      final DailyFlashGameProgress progress =
          await DailyFlashGameProgressService.loadToday(
        gameKey: 'first_date',
      );

      final List<_DailyFlashFirstDateQuestion> questions =
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

      setState(() {
        _dailyProgress = progress;
        _dailyQuestionIndex = index;
        _question = questions[index];
        _dailyComplete = false;
        _roundFinished = false;
        _submitting = false;
        _clueIndex = 0;
        _lives = _maximumLives;
        _message = null;
        _loading = false;
        _roundStartedAt = DateTime.now();
      });

      unawaited(
        AnalyticsService.logGameStarted(
          gameType: 'first_date',
          category: 'first_date',
          subcategory: 'first_date',
          questionId: questions[index].id,
          source: 'daily_flash',
          practiceMode: false,
        ),
      );

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _answerFocusNode.requestFocus();
        }
      });
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

  Future<List<_DailyFlashFirstDateQuestion>>
      _loadScheduledQuestions(String dateKey) async {
    final String compactDate = _compactDateKey(dateKey);
    final FirebaseFirestore firestore = FirebaseFirestore.instance;

    final List<Future<DocumentSnapshot<Map<String, dynamic>>>> reads =
        <Future<DocumentSnapshot<Map<String, dynamic>>>>[
      for (int number = 1; number <= 5; number++)
        firestore
            .collection('daily_flash_questions')
            .doc(
              'df_first_date_${compactDate}_${number.toString().padLeft(2, '0')}',
            )
            .get(),
    ];

    final List<DocumentSnapshot<Map<String, dynamic>>> snapshots =
        await Future.wait(reads);

    return snapshots
        .map(_questionFromSnapshot)
        .whereType<_DailyFlashFirstDateQuestion>()
        .toList(growable: false);
  }

  _DailyFlashFirstDateQuestion? _questionFromSnapshot(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    if (!snapshot.exists) {
      return null;
    }

    final Map<String, dynamic>? data = snapshot.data();
    if (data == null) {
      return null;
    }

    final String answer =
        (data['answer'] ?? '').toString().trim();
    final String answerType =
        (data['answerType'] ?? 'year')
            .toString()
            .trim()
            .toLowerCase();
    final String prompt =
        (data['prompt'] ?? '').toString().trim();

    if (answer.isEmpty) {
      return null;
    }

    final List<String> clues = <String>[
      for (int index = 1; index <= 10; index++)
        (data['clue$index'] ?? '').toString().trim(),
    ];

    if (clues.any((String clue) => clue.isEmpty)) {
      return null;
    }

    final Set<String> acceptedAnswers =
        <String>{_normalise(answer)};

    final dynamic rawAccepted = data['acceptedAnswers'];

    if (rawAccepted is List) {
      for (final dynamic value in rawAccepted) {
        final String normalised =
            _normalise(value.toString());
        if (normalised.isNotEmpty) {
          acceptedAnswers.add(normalised);
        }
      }
    } else if (rawAccepted != null) {
      for (final String value
          in rawAccepted.toString().split(RegExp(r'[\*\|]'))) {
        final String normalised = _normalise(value);
        if (normalised.isNotEmpty) {
          acceptedAnswers.add(normalised);
        }
      }
    }

    return _DailyFlashFirstDateQuestion(
      id: snapshot.id,
      prompt: prompt,
      answerType: answerType,
      answer: answer,
      acceptedAnswers: acceptedAnswers,
      clues: clues,
    );
  }

  String _normalise(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll('&', ' and ')
        .replaceAll(RegExp(r'[^a-z0-9]'), '');
  }

  void _showTemporaryMessage(
    String message, {
    GameMessageType type = GameMessageType.error,
    Duration duration = const Duration(seconds: 3),
  }) {
    _messageTimer?.cancel();

    if (!mounted) {
      return;
    }

    setState(() {
      _message = message;
      _messageType = type;
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

  Future<void> _submitGuess() async {
    final _DailyFlashFirstDateQuestion? question = _question;

    if (question == null ||
        _roundFinished ||
        _submitting) {
      return;
    }

    final String guess = _answerController.text.trim();

    if (guess.isEmpty) {
      _showTemporaryMessage(
        'Enter your answer before guessing.',
      );
      return;
    }

    setState(() {
      _submitting = true;
    });

    final bool correct =
        question.acceptedAnswers.contains(_normalise(guess));

    if (correct) {
      await _finishCorrect();
      return;
    }

    final int remainingLives = _lives - 1;
    final bool noLivesLeft = remainingLives <= 0;
    final bool noCluesLeft =
        _clueIndex >= question.clues.length - 1;

    _answerController.clear();

    setState(() {
      _lives = remainingLives;
      _submitting = false;

      if (!noCluesLeft) {
        _clueIndex += 1;
      }
    });

    if (noLivesLeft || noCluesLeft) {
      _showTemporaryMessage(
        noLivesLeft
            ? 'INCORRECT — NO LIVES LEFT'
            : 'INCORRECT — NO CLUES LEFT',
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
      remainingLives == 1
          ? 'Incorrect. 1 life left.'
          : 'Incorrect. $remainingLives lives left.',
    );

    if (mounted) {
      _answerFocusNode.requestFocus();
    }
  }

  void _skipClue() {
    final _DailyFlashFirstDateQuestion? question = _question;

    if (question == null ||
        _roundFinished ||
        _submitting ||
        _clueIndex >= question.clues.length - 1) {
      return;
    }

    _answerController.clear();

    setState(() {
      _clueIndex += 1;
      _message = null;
    });

    _answerFocusNode.requestFocus();
  }

  Future<void> _finishCorrect() async {
    final _DailyFlashFirstDateQuestion? question = _question;
    final DailyFlashGameProgress? progress = _dailyProgress;

    if (question == null ||
        progress == null ||
        _roundFinished) {
      return;
    }

    final int clueNumber = _currentClueNumber;
    final bool wasFirstGuess = clueNumber == 1;
    final int normalXp =
        _basePoints[_clueIndex] +
            (wasFirstGuess ? _firstGuessBonus : 0);
    final int xpEarned = normalXp * 2;

    setState(() {
      _roundFinished = true;
      _submitting = false;
      _message = null;
    });
    _messageTimer?.cancel();
    FocusScope.of(context).unfocus();

    final DailyFlashGameProgress updated =
        await DailyFlashGameProgressService.recordResult(
      gameKey: 'first_date',
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
        gameType: 'first_date',
        category: 'first_date',
        subcategory: 'first_date',
        questionId: question.id,
        source: 'daily_flash',
        result: 'correct',
        xpEarned: xpEarned,
        firstGuess: wasFirstGuess,
        practiceMode: false,
        clueNumber: clueNumber,
        guesses: 1,
        livesRemaining: _lives,
        playTimeSeconds: _playTimeSeconds,
      ),
    );

    if (wasFirstGuess) {
      unawaited(
        AnalyticsService.logFirstGuessEarned(
          gameType: 'first_date',
          category: 'first_date',
          subcategory: 'first_date',
          questionId: question.id,
          source: 'daily_flash',
          xpEarned: xpEarned,
          practiceMode: false,
        ),
      );
    }

    await _showResultDialog(
      title: wasFirstGuess ? 'FIRST GUESS!' : 'CORRECT!',
      message: '$xpEarned XP',
      success: true,
    );
  }

  Future<void> _finishFailed() async {
    final _DailyFlashFirstDateQuestion? question = _question;
    final DailyFlashGameProgress? progress = _dailyProgress;

    if (question == null ||
        progress == null ||
        _roundFinished) {
      return;
    }

    setState(() {
      _roundFinished = true;
      _submitting = false;
      _message = null;
    });
    _messageTimer?.cancel();
    FocusScope.of(context).unfocus();

    final DailyFlashGameProgress updated =
        await DailyFlashGameProgressService.recordResult(
      gameKey: 'first_date',
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
        gameType: 'first_date',
        category: 'first_date',
        subcategory: 'first_date',
        questionId: question.id,
        source: 'daily_flash',
        result: 'failed',
        xpEarned: 0,
        firstGuess: false,
        practiceMode: false,
        clueNumber: _currentClueNumber,
        guesses: 1,
        livesRemaining: _lives,
        playTimeSeconds: _playTimeSeconds,
      ),
    );

    await _showResultDialog(
      title: 'GAME OVER',
      message: 'THE ANSWER WAS:\n\n${question.answer}',
      success: false,
    );
  }

  Future<void> _giveUp() async {
    final _DailyFlashFirstDateQuestion? question = _question;
    final DailyFlashGameProgress? progress = _dailyProgress;

    if (question == null ||
        progress == null ||
        _roundFinished) {
      return;
    }

    setState(() {
      _roundFinished = true;
      _submitting = false;
      _message = null;
    });
    _messageTimer?.cancel();
    FocusScope.of(context).unfocus();

    final DailyFlashGameProgress updated =
        await DailyFlashGameProgressService.recordResult(
      gameKey: 'first_date',
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
      message: 'THE ANSWER WAS:\n\n${question.answer}',
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
    final NavigatorState rootNavigator =
        Navigator.of(context, rootNavigator: true);

    if (rootNavigator.canPop()) {
      rootNavigator.pop();
    }

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
      gameKey: 'first_date',
    );

    final PlayerStats before =
        await PlayerStatsService.loadStats();

    final PlayerStats after =
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

    assert(after.totalXp >= before.totalXp);

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
            'FIRST DATE COMPLETE',
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

  void _goBack() {
    Navigator.of(context).maybePop();
  }

  void _goHome() {
    Navigator.of(context).popUntil(
      (Route<dynamic> route) => route.isFirst,
    );
  }

  String _displayPrompt(
    _DailyFlashFirstDateQuestion question,
  ) {
    switch (question.answerType) {
      case 'month':
        return 'Guess the month';
      case 'year':
        return 'Guess the year';
      case 'month_year':
        return 'Guess the month and year';
      default:
        return question.prompt.isEmpty
            ? 'Guess the date'
            : question.prompt;
    }
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
              Icons.calendar_month_rounded,
              color: AppColors.orange,
              size: 64,
            ),
            const SizedBox(height: 16),
            const Text(
              'TODAY’S FIRST DATE\nDAILY FLASH IS NOT READY YET.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Oswald',
                color: AppColors.white,
                fontSize: 22,
                fontWeight: FontWeight.w700,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Expected 5 scheduled questions for ${_todayKey()}.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.grey,
                height: 1.4,
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
          constraints: const BoxConstraints(maxWidth: 880),
          child: Container(
            padding: MediaQuery.sizeOf(context).width >= 600
                ? const EdgeInsets.all(14)
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
              const SizedBox(height: 10),
              if (_message != null) ...<Widget>[
                GameMessagePanel(
                  message: _message!,
                  type: _messageType,
                ),
                const SizedBox(height: 12),
              ],
              _buildStatusBlock(),
              const SizedBox(height: 14),
              if (!_isInstalledPhone(context)) _buildPromptCard(),
              SizedBox(height: _isInstalledPhone(context) ? 0 : 12),
              _buildClueCard(isDesktop: isDesktop),
              const SizedBox(height: 14),
              _buildAnswerField(),
              const SizedBox(height: 12),
              _buildActionButtons(),
              ],
            ),
          ),
        ),
      ),
    );
  }



  Widget _buildStatusBlock() {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        12,
        10,
        12,
        10,
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
                'CLUE $_currentClueNumber / 10',
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
                child: _currentClueNumber == 1
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
                        maxLines: 1,
                      )
                    : Text(
                        '${_pointsAvailable * 2} XP',
                        maxLines: 1,
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

  Widget _buildPromptCard() {
    final _DailyFlashFirstDateQuestion question = _question!;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 14,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF151515),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFF3E3E3E),
          width: 1,
        ),
      ),
      child: Text(
        _displayPrompt(question).toUpperCase(),
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontFamily: 'Oswald',
          color: AppColors.white,
          fontSize: 22,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.35,
          height: 1.15,
        ),
      ),
    );
  }

  Widget _buildClueCard({
    required bool isDesktop,
  }) {
    final _DailyFlashFirstDateQuestion question = _question!;

    return Container(
      width: double.infinity,
      constraints: BoxConstraints(
        minHeight: isDesktop ? 150 : 128,
      ),
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 28 : 20,
        vertical: isDesktop ? 26 : 22,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.orange,
          width: 1.5,
        ),
      ),
      child: Center(
        child: Text(
          question.clues[_clueIndex],
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Inter',
            color: AppColors.white,
            fontSize: isDesktop ? 20 : 17,
            fontWeight: FontWeight.w600,
            height: 1.35,
          ),
        ),
      ),
    );
  }

  Widget _buildAnswerField() {
    final bool enabled =
        !_roundFinished && !_submitting && _lives > 0;

    return TextField(
      controller: _answerController,
      focusNode: _answerFocusNode,
      enabled: enabled,
      textInputAction: TextInputAction.done,
      onSubmitted: (_) {
        if (enabled) {
          unawaited(_submitGuess());
        }
      },
      style: const TextStyle(
        fontFamily: 'Inter',
        color: AppColors.white,
        fontSize: 17,
        fontWeight: FontWeight.w600,
      ),
      decoration: InputDecoration(
        suffixIcon: _isInstalledPhone(context)
            ? Padding(
                padding: EdgeInsets.zero,
                child: SizedBox(
                  width: 110,
                  child: FilledButton(
                    onPressed: enabled ? () => unawaited(_submitGuess()) : null,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFFE5E02),
                      foregroundColor: AppColors.white,
                      padding: EdgeInsets.zero,
                      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.only(topRight: Radius.circular(12), bottomRight: Radius.circular(12))),
                    ),
                    child: const Text('GUESS', style: TextStyle(fontFamily: 'Oswald', fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
                ),
              )
            : null,
        hintText: _isInstalledPhone(context)
            ? _phoneDateHint()
            : _answerHint(),
        hintStyle: const TextStyle(
          color: AppColors.white,
          fontFamily: 'Inter',
        ),
        filled: true,
        fillColor: const Color(0xFF121212),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 17,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: AppColors.orange,
            width: 1.5,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: AppColors.orange,
            width: 2,
          ),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: AppColors.darkGrey,
          ),
        ),
      ),
    );
  }

  String _phoneDateHint() {
    switch (_question?.answerType) {
      case 'year': return 'GUESS THE YEAR...';
      case 'month': return 'GUESS THE MONTH...';
      case 'month_year': return 'GUESS MONTH AND YEAR...';
      default: return 'GUESS THE DATE...';
    }
  }

  String _answerHint() {
    switch (_question?.answerType) {
      case 'year':
        return 'Enter a year...';
      case 'month':
        return 'Enter a month...';
      case 'month_year':
        return 'Enter a month and year...';
      default:
        return 'Enter your answer...';
    }
  }

  Widget _buildActionButtons() {
    final bool enabled =
        !_roundFinished && !_submitting && _lives > 0;
    final bool canAdvanceClue =
        enabled &&
        _question != null &&
        _clueIndex < _question!.clues.length - 1;

    if (_isInstalledPhone(context)) {
      return Row(
        children: <Widget>[
          Expanded(
            child: SizedBox(
              height: 42,
              child: OutlinedButton(
                onPressed: canAdvanceClue ? _skipClue : null,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.white,
                  side: const BorderSide(color: Color(0xFF777777), width: 1.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
                ),
                child: const FittedBox(fit: BoxFit.scaleDown, child: Text('NEXT CLUE', style: TextStyle(fontFamily: 'Oswald', fontWeight: FontWeight.w600, fontSize: 16))),
              ),
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: SizedBox(
              height: 42,
              child: FilledButton(
                onPressed: enabled ? () => unawaited(_giveUp()) : null,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFAF3932),
                  foregroundColor: AppColors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
                ),
                child: const Text('GIVE UP', style: TextStyle(fontFamily: 'Oswald', fontWeight: FontWeight.w600, fontSize: 16)),
              ),
            ),
          ),
        ],
      );
    }

    return Column(
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: SizedBox(
                height: 48,
                child: FilledButton(
                  onPressed: enabled
                      ? () => unawaited(_submitGuess())
                      : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.orange,
                    foregroundColor: AppColors.white,
                    disabledBackgroundColor: AppColors.darkGrey,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    _submitting ? 'CHECKING...' : 'GUESS',
                    style: const TextStyle(
                      fontFamily: 'Oswald',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: SizedBox(
                height: 48,
                child: OutlinedButton(
                  onPressed: canAdvanceClue ? _skipClue : null,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.white,
                    disabledForegroundColor: AppColors.grey,
                    side: BorderSide(
                      color: canAdvanceClue
                          ? AppColors.white
                          : AppColors.darkGrey,
                      width: 1.5,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'NEXT CLUE',
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
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: FilledButton(
            onPressed:
                enabled ? () => unawaited(_giveUp()) : null,
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
              style: TextStyle(
                fontFamily: 'Oswald',
                fontSize: 16,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
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
                alignment:
                    Alignment.centerLeft,
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
                alignment:
                    Alignment.centerRight,
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
