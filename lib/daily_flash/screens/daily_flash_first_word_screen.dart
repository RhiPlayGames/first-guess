import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../services/analytics_service.dart';
import '../../services/player_stats_service.dart';
import '../services/daily_flash_game_progress_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/stats_panel.dart';
import '../../widgets/app_home_button.dart';
import '../../widgets/game_dialogs.dart';
import '../../widgets/lives_display.dart';

class DailyFlashFirstWordScreen extends StatefulWidget {
  final VoidCallback? onChallengeFinished;

  const DailyFlashFirstWordScreen({super.key, this.onChallengeFinished});

  @override
  State<DailyFlashFirstWordScreen> createState() => _DailyFlashFirstWordScreenState();
}

class _FirstWordQuestion {
  final String id;
  final String answer;
  final Set<String> acceptedAnswers;
  final List<String> clues;
  final List<String> patterns;

  const _FirstWordQuestion({
    required this.id,
    required this.answer,
    required this.acceptedAnswers,
    required this.clues,
    required this.patterns,
  });
}

class _DailyFlashFirstWordScreenState extends State<DailyFlashFirstWordScreen> {
  static const int _maximumLives = 3;
  static const List<int> _basePoints = <int>[100, 80, 60, 40, 20];
  static const int _firstGuessBonus = 50;

  final TextEditingController _guessController = TextEditingController();
  final FocusNode _guessFocusNode = FocusNode();

  _FirstWordQuestion? _question;
  bool _loading = true;
  bool _roundFinished = false;
  int _clueIndex = 0;
  int _lives = _maximumLives;
  int _submittedGuessCount = 0;
  String? _message;
  Color _messageColor = const Color(0xFFE14B4B);
  Timer? _messageTimer;
  DateTime _roundStartedAt = DateTime.now();
  DailyFlashGameProgress? _dailyProgress;
  int _dailyQuestionIndex = 0;
  bool _dailyComplete = false;


  bool get _isLastClue => _clueIndex >= 4;

  void _showTemporaryMessage(
    String message, {
    Color color = const Color(0xFFE14B4B),
    Duration duration = const Duration(seconds: 3),
  }) {
    _messageTimer?.cancel();

    if (!mounted) {
      return;
    }

    setState(() {
      _message = message;
      _messageColor = color;
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


  @override
  void initState() {
    super.initState();
    unawaited(_loadDisplayStats());
    _loadRound();
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
    _guessController.dispose();
    _guessFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadRound() async {
    _messageTimer?.cancel();

    if (mounted) {
      setState(() {
        _loading = true;
        _roundFinished = false;
        _clueIndex = 0;
        _lives = _maximumLives;
        _submittedGuessCount = 0;
        _message = null;
        _guessController.clear();
      });
    }

    try {
      final DailyFlashGameProgress progress =
          await DailyFlashGameProgressService.loadToday(
        gameKey: 'first_word',
      );

      final List<_FirstWordQuestion> todaysQuestions =
          await _loadScheduledQuestions(progress.dateKey);

      if (!mounted) return;

      if (todaysQuestions.length < 5) {
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
          _dailyComplete = true;
          _question = null;
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
        _question = todaysQuestions[index];
        _dailyComplete = false;
        _loading = false;
        _roundStartedAt = DateTime.now();
      });

      unawaited(
        AnalyticsService.logGameStarted(
          gameType: 'first_word',
          category: 'first_word',
          subcategory: 'first_word',
          questionId: todaysQuestions[index].id,
          source: 'daily_flash',
          practiceMode: false,
        ),
      );

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _guessFocusNode.requestFocus();
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _question = null;
      });
    }
  }

  String _compactDateKey(String value) =>
      value.replaceAll('-', '');

  Future<List<_FirstWordQuestion>> _loadScheduledQuestions(
    String dateKey,
  ) async {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;
    final String compact = _compactDateKey(dateKey);

    final List<Future<DocumentSnapshot<Map<String, dynamic>>>> reads =
        <Future<DocumentSnapshot<Map<String, dynamic>>>>[
      for (int number = 1; number <= 5; number++)
        firestore
            .collection('daily_flash_questions')
            .doc(
              'df_first_word_${compact}_${number.toString().padLeft(2, '0')}',
            )
            .get(),
    ];

    final List<DocumentSnapshot<Map<String, dynamic>>> snapshots =
        await Future.wait(reads);

    return snapshots
        .map(_questionFromSnapshot)
        .whereType<_FirstWordQuestion>()
        .toList(growable: false);
  }

  _FirstWordQuestion? _questionFromSnapshot(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    if (!document.exists) {
      return null;
    }

    final Map<String, dynamic>? rawData = document.data();
    if (rawData == null) {
      return null;
    }

    final Map<String, dynamic> data = rawData;
    final String answer = (data['answer'] ?? '').toString().trim();
    if (answer.isEmpty) {
      return null;
    }

    final List<String> clues = <String>[
      for (int index = 1; index <= 5; index++)
        (data['clue$index'] ?? '').toString().trim(),
    ];
    final List<String> patterns = <String>[
      for (int index = 1; index <= 5; index++)
        (data['pattern$index'] ?? '').toString().trim(),
    ];

    if (clues.any((String clue) => clue.isEmpty) ||
        patterns.any((String pattern) => pattern.isEmpty)) {
      return null;
    }

    final Set<String> accepted = <String>{_normalise(answer)};
    final dynamic rawAccepted = data['acceptedAnswers'];
    if (rawAccepted is List) {
      for (final dynamic value in rawAccepted) {
        final String normalised = _normalise(value.toString());
        if (normalised.isNotEmpty) {
          accepted.add(normalised);
        }
      }
    } else if (rawAccepted != null) {
      for (final String value in rawAccepted.toString().split(RegExp(r'[\*\|]'))) {
        final String normalised = _normalise(value);
        if (normalised.isNotEmpty) {
          accepted.add(normalised);
        }
      }
    }

    return _FirstWordQuestion(
      id: document.id,
      answer: answer,
      acceptedAnswers: accepted,
      clues: clues,
      patterns: patterns,
    );
  }

  String _normalise(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]'), '');
  }

  Future<void> _submitGuess() async {
    final _FirstWordQuestion? question = _question;
    if (question == null || _roundFinished || _lives <= 0) {
      return;
    }

    final String rawGuess = _guessController.text.trim();
    if (rawGuess.isEmpty) {
      _showTemporaryMessage('Enter a word before guessing.');
      return;
    }

    final String normalisedGuess = _normalise(rawGuess);
    final bool isCorrect = question.acceptedAnswers.contains(normalisedGuess);
    final bool wasFirstGuess =
        isCorrect && _clueIndex == 0 && _submittedGuessCount == 0;

    _submittedGuessCount++;

    if (isCorrect) {
      await _finishCorrect(wasFirstGuess: wasFirstGuess);
      return;
    }

    final int newLives = _lives - 1;
    final bool outOfLives = newLives <= 0;
    final bool noMoreClues = _isLastClue;

    if (outOfLives || noMoreClues) {
      setState(() {
        _lives = newLives < 0 ? 0 : newLives;
        _guessController.clear();
        _message = null;
      });
      _messageTimer?.cancel();

      _showTemporaryMessage(
        outOfLives
            ? 'INCORRECT — NO LIVES LEFT'
            : 'INCORRECT — NO CLUES LEFT',
        color: const Color(0xFFE14B4B),
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

    setState(() {
      _lives = newLives;
      _clueIndex++;
      _guessController.clear();
    });

    _showTemporaryMessage(
      newLives == 1
          ? 'Incorrect. 1 life left.'
          : 'Incorrect. $newLives lives left.',
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _guessFocusNode.requestFocus();
      }
    });
  }

  void _nextClue() {
    if (_roundFinished || _isLastClue) {
      return;
    }

    setState(() {
      _clueIndex++;
      _message = null;
      _guessController.clear();
    });
    _messageTimer?.cancel();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _guessFocusNode.requestFocus();
      }
    });
  }

  int _playTimeSeconds() {
    return DateTime.now().difference(_roundStartedAt).inSeconds;
  }

  Future<void> _advanceAfterResult() async {
    final NavigatorState navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
    }

    if (!mounted) return;

    final DailyFlashGameProgress? progress = _dailyProgress;
    if (progress == null) return;

    if (progress.allQuestionsAttempted) {
      await _finishDailyFlash();
      return;
    }

    await _loadRound();
  }

  Future<void> _finishCorrect({required bool wasFirstGuess}) async {
    final _FirstWordQuestion? question = _question;
    final DailyFlashGameProgress? progress = _dailyProgress;
    if (question == null || progress == null || _roundFinished) return;

    setState(() {
      _roundFinished = true;
    });
    FocusScope.of(context).unfocus();

    final int normalXp =
        _basePoints[_clueIndex] + (wasFirstGuess ? _firstGuessBonus : 0);
    final int xpEarned = normalXp * 2;

    final DailyFlashGameProgress updated =
        await DailyFlashGameProgressService.recordResult(
      gameKey: 'first_word',
      progress: progress,
      questionIndex: _dailyQuestionIndex,
      correct: true,
      xpEarned: xpEarned,
      wasFirstGuess: wasFirstGuess,
    );

    if (!mounted) return;

    setState(() {
      _dailyProgress = updated;
    });

    unawaited(
      AnalyticsService.logGameCompleted(
        gameType: 'first_word',
        category: 'first_word',
        subcategory: 'first_word',
        questionId: question.id,
        source: 'daily_flash',
        result: 'correct',
        xpEarned: xpEarned,
        firstGuess: wasFirstGuess,
        practiceMode: false,
        clueNumber: _clueIndex + 1,
        guesses: _submittedGuessCount,
        livesRemaining: _lives,
        playTimeSeconds: _playTimeSeconds(),
      ),
    );

    if (wasFirstGuess) {
      unawaited(
        AnalyticsService.logFirstGuessEarned(
          gameType: 'first_word',
          category: 'first_word',
          subcategory: 'first_word',
          questionId: question.id,
          source: 'daily_flash',
          xpEarned: xpEarned,
          practiceMode: false,
        ),
      );
    }

    await _showResultDialog(
      title: wasFirstGuess ? 'FIRST GUESS!' : 'CORRECT!',
      message: wasFirstGuess
          ? '200 XP\n100 XP First Guess Bonus\n\n300 XP TOTAL'
          : '$xpEarned XP',
      success: true,
    );
  }

  Future<void> _finishFailed() async {
    final _FirstWordQuestion? question = _question;
    final DailyFlashGameProgress? progress = _dailyProgress;
    if (question == null || progress == null || _roundFinished) return;

    setState(() {
      _roundFinished = true;
    });
    FocusScope.of(context).unfocus();

    final DailyFlashGameProgress updated =
        await DailyFlashGameProgressService.recordResult(
      gameKey: 'first_word',
      progress: progress,
      questionIndex: _dailyQuestionIndex,
      correct: false,
      xpEarned: 0,
      wasFirstGuess: false,
    );

    if (!mounted) return;

    setState(() {
      _dailyProgress = updated;
    });

    unawaited(
      AnalyticsService.logGameCompleted(
        gameType: 'first_word',
        category: 'first_word',
        subcategory: 'first_word',
        questionId: question.id,
        source: 'daily_flash',
        result: 'failed',
        xpEarned: 0,
        firstGuess: false,
        practiceMode: false,
        clueNumber: _clueIndex + 1,
        guesses: _submittedGuessCount,
        livesRemaining: _lives,
        playTimeSeconds: _playTimeSeconds(),
      ),
    );

    await _showResultDialog(
      title: 'GAME OVER',
      message: 'The answer was ${question.answer}.',
      success: false,
    );
  }

  Future<void> _giveUp() async {
    final _FirstWordQuestion? question = _question;
    final DailyFlashGameProgress? progress = _dailyProgress;
    if (_roundFinished || question == null || progress == null) return;

    setState(() {
      _roundFinished = true;
      _message = null;
      _guessController.clear();
    });
    FocusScope.of(context).unfocus();

    final DailyFlashGameProgress updated =
        await DailyFlashGameProgressService.recordResult(
      gameKey: 'first_word',
      progress: progress,
      questionIndex: _dailyQuestionIndex,
      correct: false,
      xpEarned: 0,
      wasFirstGuess: false,
    );

    if (!mounted) return;

    setState(() {
      _dailyProgress = updated;
    });

    unawaited(
      AnalyticsService.logGameCompleted(
        gameType: 'first_word',
        category: 'first_word',
        subcategory: 'first_word',
        questionId: question.id,
        source: 'daily_flash',
        result: 'gave_up',
        xpEarned: 0,
        firstGuess: false,
        practiceMode: false,
        clueNumber: _clueIndex + 1,
        guesses: _submittedGuessCount,
        livesRemaining: _lives,
        playTimeSeconds: _playTimeSeconds(),
      ),
    );

    await _showResultDialog(
      title: 'YOU GAVE UP!',
      message: 'The answer was ${question.answer}.',
      success: false,
    );
  }

  Future<void> _finishDailyFlash() async {
    if (_dailyComplete) return;

    final DailyFlashGameProgress? progress = _dailyProgress;
    if (progress == null || !progress.allQuestionsAttempted) return;

    _dailyComplete = true;

    final bool perfect = progress.questionsCorrect == 5;

    await DailyFlashMilestoneService.recordCompletionAndAwardIfEarned(
      perfect: perfect,
      gameKey: 'first_word',
    );

    final PlayerStats before = await PlayerStatsService.loadStats();
    final PlayerStats after =
        await PlayerStatsService.addBonusXp(xp: progress.totalXp);

    if (!mounted) return;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.panel,
          title: Text(
            perfect ? 'PERFECT 5!' : 'DAILY FLASH 5 COMPLETE',
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
              onPressed: () => Navigator.of(dialogContext).pop(),
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

    if (!mounted) return;

    // Keep the captured snapshots referenced here so adding the final
    // shared reward hierarchy later does not require changing XP logic.
    assert(after.totalXp >= before.totalXp);

    widget.onChallengeFinished?.call();
    Navigator.of(context).pop();
  }

  Future<void> _showCompletedTodayDialog() async {
    final DailyFlashGameProgress? progress = _dailyProgress;
    if (progress == null || !mounted) return;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.panel,
          title: const Text(
            'FIRST WORD COMPLETE',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Oswald',
              color: AppColors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: Text(
            'You have completed today’s First Word Daily Flash 5.\n\n'
            '${progress.questionsCorrect}/5 correct • ${progress.totalXp} XP',
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.white),
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: <Widget>[
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.orange,
              ),
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('BACK TO DAILY FLASH 5'),
            ),
          ],
        );
      },
    );

    if (!mounted) return;
    widget.onChallengeFinished?.call();
    Navigator.of(context).pop();
  }

  Future<void> _showResultDialog({
    required String title,
    required String message,
    required bool success,
  }) {
    final bool isFinalQuestion =
        (_dailyProgress?.allQuestionsAttempted ?? false);

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
        final NavigatorState navigator = Navigator.of(context);
        if (navigator.canPop()) navigator.pop();
        widget.onChallengeFinished?.call();
        if (mounted) Navigator.of(context).pop();
      },
      primaryButtonLabel:
          isFinalQuestion ? 'VIEW RESULTS' : 'NEXT QUESTION',
      secondaryButtonLabel: 'BACK TO DAILY FLASH 5',
    );
  }

  void _goHome() {
    widget.onChallengeFinished?.call();
    Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _DailyFlashGameHeader(
        onBack: () => Navigator.of(context).maybePop(),
        onHome: _goHome,
      ),
      body: SafeArea(
        child: _loading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.orange),
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
              Icons.spellcheck_rounded,
              color: AppColors.orange,
              size: 64,
            ),
            const SizedBox(height: 16),
            const Text(
              'TODAY’S FIRST WORD\nDAILY FLASH IS NOT READY YET.',
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
              onPressed: () => Navigator.of(context).maybePop(),
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
    final _FirstWordQuestion question = _question!;
    final bool isDesktop = MediaQuery.sizeOf(context).width >= 900;

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
              _buildClueHeaderBlock(),
              if (_message != null) ...<Widget>[
                const SizedBox(height: 10),
                GameMessagePanel(
                  message: _message!,
                  type: _messageColor == const Color(0xFFE14B4B)
                      ? GameMessageType.error
                      : GameMessageType.info,
                ),
              ],
              const SizedBox(height: 14),
            ...List<Widget>.generate(
              _clueIndex + 1,
              (int offset) {
                final int clueNumber = _clueIndex - offset;
                final bool isCurrent = offset == 0;

                return Padding(
                  padding: EdgeInsets.only(
                    bottom: clueNumber == 0 ? 0 : 8,
                  ),
                  child: isCurrent
                      ? _buildCurrentCluePanel(
                          question.clues[clueNumber],
                        )
                      : _buildPreviousCluePanel(
                          question.clues[clueNumber],
                        ),
                );
              },
            ),
            const SizedBox(height: 18),
            SizedBox(
              height: isDesktop ? 88 : 76,
              child: Center(
                child: _buildWordPattern(
                  question.patterns[_clueIndex],
                  isDesktop: isDesktop,
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildFirstWordGuessPanel(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentCluePanel(String clue) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 18,
      ),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.orange,
          width: 1.5,
        ),
      ),
      child: Text(
        clue,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontFamily: 'Inter',
          color: AppColors.white,
          fontSize: 17,
          fontWeight: FontWeight.w600,
          height: 1.3,
        ),
      ),
    );
  }

  Widget _buildPreviousCluePanel(String clue) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFF333333),
          width: 1,
        ),
      ),
      child: Text(
        clue,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontFamily: 'Inter',
          color: Color(0xFF8B8B8B),
          fontSize: 12.5,
          fontWeight: FontWeight.w500,
          height: 1.2,
        ),
      ),
    );
  }

  Widget _buildWordPattern(
    String pattern, {
    required bool isDesktop,
  }) {
    final double fontSize = isDesktop ? 42 : 34;
    final List<String> characters = pattern.split('');
    final double spacing = isDesktop ? 6 : 3;
    final double targetSlotWidth = isDesktop ? 192 : 160;

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double availableWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;
        final double totalSpacing =
            spacing * max(0, characters.length - 1);
        final double fittedSlotWidth = characters.isEmpty
            ? targetSlotWidth
            : (availableWidth - totalSpacing) / characters.length;
        final double slotWidth = max(
          32.0,
          min(targetSlotWidth, fittedSlotWidth),
        );

        return Center(
          child: Wrap(
            alignment: WrapAlignment.center,
            spacing: spacing,
            runSpacing: 8,
            children: characters.map((String character) {
              final String display = character == '_' ? '–' : character;

              return SizedBox(
                width: slotWidth,
                child: Text(
                  display,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Oswald',
                    color: AppColors.white,
                    fontSize: fontSize,
                    fontWeight: FontWeight.w700,
                    height: 1,
                  ),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  Widget _buildFirstWordGuessPanel() {
    final bool enabled = !_roundFinished && _lives > 0;

    return Column(
      children: <Widget>[
        TextField(
          controller: _guessController,
          focusNode: _guessFocusNode,
          enabled: enabled,
          autofocus: enabled,
          onSubmitted: (_) {
            if (enabled) {
              _submitGuess();
            }
          },
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.done,
          style: const TextStyle(
            fontFamily: 'Inter',
            color: AppColors.white,
            fontSize: 17,
          ),
          decoration: const InputDecoration(
            hintText: 'Type your word...',
            hintStyle: TextStyle(
              fontFamily: 'Inter',
              color: AppColors.white,
              fontSize: 17,
            ),
            filled: true,
            fillColor: AppColors.panel,
            contentPadding: EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 22,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.all(
                Radius.circular(16),
              ),
              borderSide: BorderSide(
                color: AppColors.orange,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.all(
                Radius.circular(16),
              ),
              borderSide: BorderSide(
                color: AppColors.orange,
                width: 2,
              ),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.all(
                Radius.circular(16),
              ),
              borderSide: BorderSide(
                color: AppColors.darkGrey,
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: <Widget>[
            Expanded(
              child: SizedBox(
                height: 48,
                child: FilledButton(
                  onPressed: enabled ? _submitGuess : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.orange,
                    foregroundColor: AppColors.white,
                    disabledBackgroundColor: AppColors.darkGrey,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'GUESS',
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
                height: 48,
                child: OutlinedButton(
                  onPressed: enabled && !_isLastClue
                      ? _nextClue
                      : null,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.white,
                    disabledForegroundColor:
                        const Color(0xFF5E5E5E),
                    side: BorderSide(
                      color: enabled && !_isLastClue
                          ? const Color(0xFF555555)
                          : const Color(0xFF3A3A3A),
                      width: 2,
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

  Widget _buildClueHeaderBlock() {
    final int normalPoints =
        _basePoints[_clueIndex] + (_clueIndex == 0 ? _firstGuessBonus : 0);
    final int displayedPoints = normalPoints * 2;

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
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                'CLUE ${_clueIndex + 1} / 5',
                maxLines: 1,
                style: const TextStyle(
                  fontFamily: 'Oswald',
                  color: AppColors.white,
                  fontSize: 15,
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
                child: Text(
                  _clueIndex == 0
                      ? '$displayedPoints XP • 2×'
                      : '${_basePoints[_clueIndex] * 2} XP • 2×',
                  maxLines: 1,
                  style: const TextStyle(
                    fontFamily: 'Oswald',
                    color: AppColors.orange,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ],
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
  Size get preferredSize => const Size.fromHeight(62);

  @override
  Widget build(BuildContext context) {
    final bool isSmall = MediaQuery.sizeOf(context).width < 600;

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
                  visualDensity: VisualDensity.compact,
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
                  padding: const EdgeInsets.only(right: 14),
                  child: FirstGuessHomeButton(
                    onPressed: onHome,
                  ),
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
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
                      fontSize: isSmall ? 25 : 30,
                      fontWeight: FontWeight.w700,
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

