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

class FirstDateGameScreen extends StatefulWidget {
  const FirstDateGameScreen({super.key});

  @override
  State<FirstDateGameScreen> createState() => _FirstDateGameScreenState();
}

class _FirstDateQuestion {
  final String id;
  final String prompt;
  final String answerType;
  final String answer;
  final List<String> acceptedAnswers;
  final List<String> clues;

  const _FirstDateQuestion({
    required this.id,
    required this.prompt,
    required this.answerType,
    required this.answer,
    required this.acceptedAnswers,
    required this.clues,
  });
}

class _MonthYearParts {
  final int? month;
  final int? year;

  const _MonthYearParts({
    required this.month,
    required this.year,
  });
}

class _FirstDateGameScreenState extends State<FirstDateGameScreen> {
  static const int _maximumLives = 3;
  static const int _firstGuessBonus = 50;

  // Ten-clue First Guess scoring:
  // clue 1 = 100 XP, clue 2 = 90 XP ... clue 10 = 10 XP.
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

  final Random _random = Random();
  final Set<String> _practiceSeenIds = <String>{};
  final TextEditingController _answerController = TextEditingController();
  final FocusNode _answerFocusNode = FocusNode();

  _FirstDateQuestion? _question;
  PlayerStats _playerStats = const PlayerStats();

  bool _loading = true;
  bool _hasLoadedStats = false;
  bool _roundFinished = false;
  bool _allQuestionsPlayed = false;
  bool _practiceMode = false;
  bool _submitting = false;

  int _clueIndex = 0;
  int _lives = _maximumLives;
  int _submittedGuessCount = 0;

  int _totalQuestionsAvailable = 0;

  String? _message;
  GameMessageType _messageType = GameMessageType.error;
  Timer? _messageTimer;

  DateTime _roundStartedAt = DateTime.now();

  static const Map<String, int> _monthNumbers = <String, int>{
    'january': 1,
    'jan': 1,
    'february': 2,
    'feb': 2,
    'march': 3,
    'mar': 3,
    'april': 4,
    'apr': 4,
    'may': 5,
    'june': 6,
    'jun': 6,
    'july': 7,
    'jul': 7,
    'august': 8,
    'aug': 8,
    'september': 9,
    'sep': 9,
    'sept': 9,
    'october': 10,
    'oct': 10,
    'november': 11,
    'nov': 11,
    'december': 12,
    'dec': 12,
  };

  @override
  void initState() {
    super.initState();
    _loadRound();
  }

  @override
  void dispose() {
    _messageTimer?.cancel();
    _answerController.dispose();
    _answerFocusNode.dispose();
    super.dispose();
  }

  int get _currentClueNumber => _clueIndex + 1;

  int get _pointsAvailable =>
      _roundFinished ? 0 : _basePoints[_clueIndex.clamp(0, 9)];

  int get _playTimeSeconds =>
      DateTime.now().difference(_roundStartedAt).inSeconds;

  Future<void> _loadRound() async {
    _messageTimer?.cancel();
    _answerController.clear();

    if (mounted) {
      setState(() {
        _loading = true;
        _roundFinished = false;
        _allQuestionsPlayed = false;
        _submitting = false;
        _clueIndex = 0;
        _lives = _maximumLives;
        _submittedGuessCount = 0;
        _message = null;
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
          category: 'first_date',
        ),
      ]);

      final PlayerStats stats = results[0] as PlayerStats;
      _hasLoadedStats = true;
      final Set<String> playedIds = results[1] as Set<String>;
      final List<QueryDocumentSnapshot<Map<String, dynamic>>> documents =
          results[2]
              as List<QueryDocumentSnapshot<Map<String, dynamic>>>;

      final List<_FirstDateQuestion> questions = documents
          .map(_questionFromDocument)
          .whereType<_FirstDateQuestion>()
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

      final List<_FirstDateQuestion> unplayed = questions
          .where(
            (_FirstDateQuestion item) => !playedIds.contains(item.id),
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
          categoryLabel: 'First Date',
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
          _goHome();
        }
        return;
      }

      List<_FirstDateQuestion> pool;

      if (_practiceMode) {
        pool = questions
            .where(
              (_FirstDateQuestion item) =>
                  !_practiceSeenIds.contains(item.id),
            )
            .toList();

        if (pool.isEmpty) {
          _practiceSeenIds.clear();
          pool = List<_FirstDateQuestion>.from(questions);
        }
      } else {
        pool = unplayed;
      }

      final _FirstDateQuestion selected =
          pool[_random.nextInt(pool.length)];

      if (_practiceMode) {
        _practiceSeenIds.add(selected.id);
      }

      setState(() {
        _playerStats = stats;
        _question = selected;
        _clueIndex = 0;
        _lives = _maximumLives;
        _submittedGuessCount = 0;
        _allQuestionsPlayed = false;
        _roundFinished = false;
        _roundStartedAt = DateTime.now();
        _loading = false;
      });

      unawaited(
        AnalyticsService.logGameStarted(
          gameType: 'first_date',
          category: 'first_date',
          subcategory: selected.answerType,
          questionId: selected.id,
          source: 'main_game',
          practiceMode: _practiceMode,
        ),
      );

      unawaited(
        AnalyticsService.logQuestionStarted(
          gameKey: 'first_date',
          category: 'first_date',
          subcategory: selected.answerType,
          questionId: selected.id,
          source: 'main_game',
          practiceMode: _practiceMode,
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
        _question = null;
        _loading = false;
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
        gameKey: 'first_date',
        category: 'first_date',
        subcategory: 'first_date',
        questionId: questionId,
        totalQuestionsAvailable: _totalQuestionsAvailable,
      );
    } catch (error, stackTrace) {
      debugPrint(
        'FIRST_DATE CONTENT CONSUMPTION TRACKING ERROR: $error',
      );
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  _FirstDateQuestion? _questionFromDocument(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final Map<String, dynamic> data = document.data();

    final String prompt = (data['prompt'] ?? '').toString().trim();
    final String answerType =
        (data['answerType'] ?? '').toString().trim().toLowerCase();
    final String answer = (data['answer'] ?? '').toString().trim();

    final dynamic rawAccepted = data['acceptedAnswers'];
    final dynamic rawClues = data['clues'];

    if (prompt.isEmpty ||
        answer.isEmpty ||
        !<String>{'year', 'month', 'month_year'}.contains(answerType) ||
        rawAccepted is! List ||
        rawClues is! List) {
      return null;
    }

    final List<String> acceptedAnswers = rawAccepted
        .map((dynamic item) => item.toString().trim())
        .where((String item) => item.isNotEmpty)
        .toList();

    final List<String> clues = rawClues
        .map((dynamic item) => item.toString().trim())
        .where((String item) => item.isNotEmpty)
        .toList();

    if (acceptedAnswers.isEmpty || clues.length != 10) {
      return null;
    }

    return _FirstDateQuestion(
      id: document.id,
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
        .replaceAll(RegExp(r'[.,]'), '')
        .replaceAll(RegExp(r'\s+'), ' ');
  }

  bool _isAcceptedAnswer(
    String guess,
    _FirstDateQuestion question,
  ) {
    final String normalisedGuess = _normalise(guess);

    return question.acceptedAnswers.any(
      (String accepted) =>
          _normalise(accepted) == normalisedGuess,
    );
  }

  _MonthYearParts _monthYearParts(String value) {
    final String input = _normalise(value)
        .replaceAll('-', ' ')
        .replaceAll('/', ' ');

    int? month;
    int? year;

    for (final MapEntry<String, int> entry in _monthNumbers.entries) {
      if (RegExp(
        r'(^|\s)' + RegExp.escape(entry.key) + r'($|\s)',
      ).hasMatch(input)) {
        month = entry.value;
        break;
      }
    }

    final List<String> tokens = input.split(' ');

    for (final String token in tokens) {
      final int? number = int.tryParse(token);

      if (number == null) {
        continue;
      }

      if (number >= 1000 && number <= 9999) {
        year ??= number;
      } else if (number >= 1 && number <= 12) {
        month ??= number;
      }
    }

    return _MonthYearParts(
      month: month,
      year: year,
    );
  }

  String? _partialFeedback(
    String guess,
    _FirstDateQuestion question,
  ) {
    if (question.answerType != 'month_year') {
      return null;
    }

    final _MonthYearParts guessParts = _monthYearParts(guess);
    final _MonthYearParts answerParts =
        _monthYearParts(question.answer);

    if (guessParts.month == null ||
        guessParts.year == null ||
        answerParts.month == null ||
        answerParts.year == null) {
      return null;
    }

    final bool correctMonth =
        guessParts.month == answerParts.month;
    final bool correctYear =
        guessParts.year == answerParts.year;

    if (correctMonth && !correctYear) {
      return 'CORRECT MONTH — WRONG YEAR';
    }

    if (!correctMonth && correctYear) {
      return 'CORRECT YEAR — WRONG MONTH';
    }

    return null;
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

  Future<void> _submitAnswer() async {
    final _FirstDateQuestion? question = _question;
    final String guess = _answerController.text.trim();

    if (question == null ||
        _roundFinished ||
        _submitting ||
        guess.isEmpty) {
      return;
    }

    setState(() {
      _submitting = true;
    });

    _submittedGuessCount++;

    final bool correct = _isAcceptedAnswer(guess, question);

    if (correct) {
      await _finishCorrect();
      return;
    }

    final String? partialMessage =
        _partialFeedback(guess, question);

    final int remainingLives = _lives - 1;
    final bool noLivesLeft = remainingLives <= 0;
    final bool noCluesLeft = _clueIndex >= question.clues.length - 1;

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
        type: GameMessageType.error,
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

    _showTemporaryMessage(
      partialMessage ?? 'Incorrect! One life lost.',
      type: partialMessage == null
          ? GameMessageType.error
          : GameMessageType.success,
      duration: partialMessage == null
          ? const Duration(seconds: 3)
          : const Duration(seconds: 3),
    );

    if (mounted) {
      _answerFocusNode.requestFocus();
    }
  }

  void _skipClue() {
    final _FirstDateQuestion? question = _question;

    if (question == null ||
        _roundFinished ||
        _submitting) {
      return;
    }

    if (_clueIndex >= question.clues.length - 1) {
      return;
    }

    _answerController.clear();

    setState(() {
      _clueIndex += 1;
      _message = null;
    });

    _answerFocusNode.requestFocus();
  }

  Future<void> _showNewAchievementPopups({
    required PlayerStats previous,
    required PlayerStats current,
  }) async {
    final List<EarnedBadge> earnedBadges =
        AchievementService.newlyEarnedBadges(
      previous: previous,
      current: current,
      gameKey: 'first_date',
      gameLabel: 'First Date',
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
      gameCategory: AchievementCategory.firstDate,
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
      _goHome();
    } else {
      await _loadRound();
    }
  }

  Future<void> _finishCorrect() async {
    final _FirstDateQuestion? question = _question;

    if (question == null || _roundFinished) {
      return;
    }

    final int clueNumber = _currentClueNumber;
    final bool wasFirstGuess = clueNumber == 1;
    final int basePoints = _basePoints[_clueIndex];
    final int pointsWon =
        basePoints + (wasFirstGuess ? _firstGuessBonus : 0);

    setState(() {
      _roundFinished = true;
      _submitting = false;
      _message = null;
    });
    _messageTimer?.cancel();

    if (_practiceMode) {
      unawaited(
        AnalyticsService.logGameCompleted(
          gameType: 'first_date',
          category: 'first_date',
          subcategory: question.answerType,
          questionId: question.id,
          source: 'main_game',
          result: 'correct',
          xpEarned: 0,
          firstGuess: wasFirstGuess,
          practiceMode: true,
          clueNumber: clueNumber,
          guesses: _submittedGuessCount,
          livesRemaining: _lives,
          playTimeSeconds: _playTimeSeconds,
        ),
      );

      unawaited(
        AnalyticsService.logQuestionCompleted(
          gameKey: 'first_date',
          category: 'first_date',
          subcategory: question.answerType,
          questionId: question.id,
          source: 'main_game',
          result: 'correct',
          xpEarned: 0,
          firstGuess: wasFirstGuess,
          practiceMode: true,
          clueNumber: clueNumber,
          guesses: _submittedGuessCount,
          livesRemaining: _lives,
          playTimeSeconds: _playTimeSeconds,
        ),
      );

      await _showResultDialog(
        title: 'CORRECT!',
        message: 'SOLVED IN $clueNumber CLUE${clueNumber == 1 ? '' : 'S'}'
            '\n\nPRACTICE MODE\n0 XP',
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
      clueNumber: clueNumber,
      wasFirstGuess: wasFirstGuess,
      playTimeSeconds: _playTimeSeconds,
      mainCategoryKey: 'first_date',
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _playerStats = updated;
    });

    unawaited(
      AnalyticsService.logGameCompleted(
        gameType: 'first_date',
        category: 'first_date',
        subcategory: question.answerType,
        questionId: question.id,
        source: 'main_game',
        result: 'correct',
        xpEarned: pointsWon,
        firstGuess: wasFirstGuess,
        practiceMode: false,
        clueNumber: clueNumber,
        guesses: _submittedGuessCount,
        livesRemaining: _lives,
        playTimeSeconds: _playTimeSeconds,
      ),
    );

    unawaited(
      AnalyticsService.logQuestionCompleted(
        gameKey: 'first_date',
        category: 'first_date',
        subcategory: question.answerType,
        questionId: question.id,
        source: 'main_game',
        result: 'correct',
        xpEarned: pointsWon,
        firstGuess: wasFirstGuess,
        practiceMode: false,
        clueNumber: clueNumber,
        guesses: _submittedGuessCount,
        livesRemaining: _lives,
        playTimeSeconds: _playTimeSeconds,
      ),
    );

    if (wasFirstGuess) {
      unawaited(
        AnalyticsService.logFirstGuessEarned(
          gameType: 'first_date',
          category: 'first_date',
          subcategory: question.answerType,
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
      gameKey: 'first_date',
      gameLabel: 'First Date',
    );

    await _showResultDialog(
      title: wasFirstGuess ? 'FIRST GUESS!' : 'CORRECT!',
      message: wasFirstGuess
          ? '100 XP\n50 XP First Guess Bonus\n\n150 XP TOTAL'
          : '$pointsWon XP',
      success: true,
      previousStats: previousStats,
      currentStats: updated,
    );
  }

  Future<void> _finishFailed() async {
    final _FirstDateQuestion? question = _question;

    if (question == null || _roundFinished) {
      return;
    }

    setState(() {
      _roundFinished = true;
      _submitting = false;
      _message = null;
    });
    _messageTimer?.cancel();

    if (_practiceMode) {
      unawaited(
        AnalyticsService.logGameCompleted(
          gameType: 'first_date',
          category: 'first_date',
          subcategory: question.answerType,
          questionId: question.id,
          source: 'main_game',
          result: 'failed',
          xpEarned: 0,
          firstGuess: false,
          practiceMode: true,
          clueNumber: _currentClueNumber,
          guesses: _submittedGuessCount,
          livesRemaining: _lives,
          playTimeSeconds: _playTimeSeconds,
        ),
      );

      unawaited(
        AnalyticsService.logQuestionCompleted(
          gameKey: 'first_date',
          category: 'first_date',
          subcategory: question.answerType,
          questionId: question.id,
          source: 'main_game',
          result: 'failed',
          xpEarned: 0,
          firstGuess: false,
          practiceMode: true,
          clueNumber: _currentClueNumber,
          guesses: _submittedGuessCount,
          livesRemaining: _lives,
          playTimeSeconds: _playTimeSeconds,
        ),
      );

      await _showResultDialog(
        title: 'GAME OVER',
        message:
            'THE ANSWER WAS:\n\n${question.answer}\n\nPRACTICE MODE\n0 XP',
        success: false,
      );
      return;
    }

    await QuestionHistoryService.recordPlayedQuestion(question.id);
    await _recordContentConsumption(question.id);

    final PlayerStats updated =
        await PlayerStatsService.recordFailedGame(
      currentStats: _playerStats,
      playTimeSeconds: _playTimeSeconds,
      mainCategoryKey: 'first_date',
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _playerStats = updated;
    });

    unawaited(
      AnalyticsService.logGameCompleted(
        gameType: 'first_date',
        category: 'first_date',
        subcategory: question.answerType,
        questionId: question.id,
        source: 'main_game',
        result: 'failed',
        xpEarned: 0,
        firstGuess: false,
        practiceMode: false,
        clueNumber: _currentClueNumber,
        guesses: _submittedGuessCount,
        livesRemaining: _lives,
        playTimeSeconds: _playTimeSeconds,
      ),
    );

    unawaited(
      AnalyticsService.logQuestionCompleted(
        gameKey: 'first_date',
        category: 'first_date',
        subcategory: question.answerType,
        questionId: question.id,
        source: 'main_game',
        result: 'failed',
        xpEarned: 0,
        firstGuess: false,
        practiceMode: false,
        clueNumber: _currentClueNumber,
        guesses: _submittedGuessCount,
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
    final _FirstDateQuestion? question = _question;

    if (question == null || _roundFinished) {
      return;
    }

    setState(() {
      _roundFinished = true;
      _submitting = false;
    });

    if (!_practiceMode) {
      await QuestionHistoryService.recordPlayedQuestion(question.id);
      await _recordContentConsumption(question.id);

      final PlayerStats updated =
          await PlayerStatsService.recordFailedGame(
        currentStats: _playerStats,
        playTimeSeconds: _playTimeSeconds,
        mainCategoryKey: 'first_date',
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _playerStats = updated;
      });
    }

    unawaited(
      AnalyticsService.logGameCompleted(
        gameType: 'first_date',
        category: 'first_date',
        subcategory: question.answerType,
        questionId: question.id,
        source: 'main_game',
        result: 'gave_up',
        xpEarned: 0,
        firstGuess: false,
        practiceMode: _practiceMode,
        clueNumber: _currentClueNumber,
        guesses: _submittedGuessCount,
        livesRemaining: _lives,
        playTimeSeconds: _playTimeSeconds,
      ),
    );

    unawaited(
      AnalyticsService.logQuestionCompleted(
        gameKey: 'first_date',
        category: 'first_date',
        subcategory: question.answerType,
        questionId: question.id,
        source: 'main_game',
        result: 'gave_up',
        xpEarned: 0,
        firstGuess: false,
        practiceMode: _practiceMode,
        clueNumber: _currentClueNumber,
        guesses: _submittedGuessCount,
        livesRemaining: _lives,
        playTimeSeconds: _playTimeSeconds,
      ),
    );

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
    PlayerStats? previousStats,
    PlayerStats? currentStats,
  }) {
    return showGameResultDialog(
      context: context,
      title: title,
      message: message,
      imageAsset: title == 'YOU GAVE UP!'
          ? 'assets/images/ui/popups/give_up.webp'
          : null,
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
                'assets/images/categories/category_headers/first_date_challenge_banner.webp',
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
              Icons.calendar_month_rounded,
              color: AppColors.orange,
              size: 64,
            ),
            const SizedBox(height: 18),
            Text(
              _allQuestionsPlayed
                  ? 'ALL FIRST DATE QUESTIONS PLAYED!'
                  : 'No live First Date questions found.',
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
                  ? 'You have completed every live First Date question. Continue in Practice Mode for 0 XP, or return when new questions are added.'
                  : 'Import the First Date workbook into Firebase, then try again.',
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
                totalScore: _playerStats.totalScore,
                currentStreak: _playerStats.currentStreak,
                firstGuesses: _playerStats.firstGuesses,
                gamesPlayed: _playerStats.gamesPlayed,
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
                  'CLUE $_currentClueNumber / 10',
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
            lives: _lives,
            maximumLives: _maximumLives,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerRight,
                child: _currentClueNumber == 1
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
                        '$_pointsAvailable XP',
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

  String _displayPrompt(_FirstDateQuestion question) {
    switch (question.answerType) {
      case 'month':
        return 'Guess the month';
      case 'year':
        return 'Guess the year';
      case 'month_year':
        return 'Guess the month and year';
      default:
        return question.prompt;
    }
  }

  Widget _buildPromptCard() {
    final _FirstDateQuestion question = _question!;

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
    final _FirstDateQuestion question = _question!;

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
          unawaited(_submitAnswer());
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
                padding: const EdgeInsets.fromLTRB(0, 5, 5, 5),
                child: SizedBox(
                  width: 90,
                  child: FilledButton(
                    onPressed: enabled ? () => unawaited(_submitAnswer()) : null,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.orange,
                      foregroundColor: AppColors.white,
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
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
                      ? () => unawaited(_submitAnswer())
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
