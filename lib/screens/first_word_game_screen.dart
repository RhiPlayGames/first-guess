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

class FirstWordGameScreen extends StatefulWidget {
  const FirstWordGameScreen({super.key});

  @override
  State<FirstWordGameScreen> createState() => _FirstWordGameScreenState();
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

class _FirstWordGameScreenState extends State<FirstWordGameScreen> {
  static const int _maximumLives = 3;
  static const List<int> _basePoints = <int>[100, 80, 60, 40, 20];
  static const int _firstGuessBonus = 50;

  final TextEditingController _guessController = TextEditingController();
  final FocusNode _guessFocusNode = FocusNode();
  final Random _random = Random();
  final Set<String> _practiceSeenIds = <String>{};

  _FirstWordQuestion? _question;
  PlayerStats _playerStats = const PlayerStats();
  bool _loading = true;
  bool _hasLoadedStats = false;
  bool _roundFinished = false;
  bool _allQuestionsPlayed = false;
  bool _practiceMode = false;
  int _clueIndex = 0;
  int _lives = _maximumLives;
  int _submittedGuessCount = 0;
  int _totalQuestionsAvailable = 0;
  String? _message;
  Color _messageColor = const Color(0xFFE14B4B);
  Timer? _messageTimer;
  DateTime _roundStartedAt = DateTime.now();

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
    _loadRound();
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
        _allQuestionsPlayed = false;
        _clueIndex = 0;
        _lives = _maximumLives;
        _submittedGuessCount = 0;
        _message = null;
        _guessController.clear();
      });
    }

    try {
      final List<dynamic> results = await Future.wait<dynamic>(<Future<dynamic>>[
        _hasLoadedStats
            ? Future<PlayerStats>.value(_playerStats)
            : PlayerStatsService.loadStats(),
        QuestionHistoryService.loadPlayedQuestionIds(),
        FirebaseChallengeService.loadLiveCategoryDocuments(
          category: 'first_word',
        ),
      ]);

      final PlayerStats stats = results[0] as PlayerStats;
      _hasLoadedStats = true;
      final Set<String> playedIds = results[1] as Set<String>;
      final List<QueryDocumentSnapshot<Map<String, dynamic>>> documents =
          results[2]
              as List<QueryDocumentSnapshot<Map<String, dynamic>>>;

      final List<_FirstWordQuestion> questions = documents
          .map(_questionFromDocument)
          .whereType<_FirstWordQuestion>()
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

      final List<_FirstWordQuestion> unplayed = questions
          .where((_FirstWordQuestion item) => !playedIds.contains(item.id))
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
          categoryLabel: 'First Word',
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

      List<_FirstWordQuestion> pool;

      if (_practiceMode) {
        pool = questions
            .where(
              (_FirstWordQuestion item) =>
                  !_practiceSeenIds.contains(item.id),
            )
            .toList();

        // Global no-repeat rule: random order, but every eligible
        // question must appear once before any question can repeat.
        if (pool.isEmpty) {
          _practiceSeenIds.clear();
          pool = List<_FirstWordQuestion>.from(questions);
        }
      } else {
        pool = unplayed;
      }

      final _FirstWordQuestion selected =
          pool[_random.nextInt(pool.length)];

      if (_practiceMode) {
        _practiceSeenIds.add(selected.id);
      }

      setState(() {
        _playerStats = stats;
        _question = selected;
        _allQuestionsPlayed = false;
        _loading = false;
        _roundStartedAt = DateTime.now();
      });

      unawaited(
        AnalyticsService.logGameStarted(
          gameType: 'first_word',
          category: 'first_word',
          subcategory: 'first_word',
          questionId: selected.id,
          source: 'main_game',
          practiceMode: _practiceMode,
        ),
      );

      unawaited(_logQuestionStarted(selected));

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _guessFocusNode.requestFocus();
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

  Future<void> _logQuestionStarted(
    _FirstWordQuestion question,
  ) {
    return AnalyticsService.logQuestionStarted(
      gameKey: 'first_word',
      category: 'first_word',
      subcategory: 'first_word',
      questionId: question.id,
      source: 'main_game',
      practiceMode: _practiceMode,
    );
  }

  Future<void> _logQuestionCompleted({
    required _FirstWordQuestion question,
    required String result,
    required int xpEarned,
    required bool firstGuess,
  }) {
    return AnalyticsService.logQuestionCompleted(
      gameKey: 'first_word',
      category: 'first_word',
      subcategory: 'first_word',
      questionId: question.id,
      source: 'main_game',
      result: result,
      xpEarned: xpEarned,
      firstGuess: firstGuess,
      clueNumber: _clueIndex + 1,
      guesses: _submittedGuessCount,
      livesRemaining: _lives,
      playTimeSeconds: _playTimeSeconds(),
      practiceMode: _practiceMode,
    );
  }

  Future<void> _recordContentConsumption(
    _FirstWordQuestion question,
  ) async {
    if (_practiceMode || _totalQuestionsAvailable <= 0) {
      return;
    }

    try {
      await ContentConsumptionService.recordQuestionCompleted(
        gameKey: 'first_word',
        category: 'first_word',
        subcategory: 'first_word',
        questionId: question.id,
        totalQuestionsAvailable: _totalQuestionsAvailable,
      );
    } catch (error, stackTrace) {
      debugPrint(
        'FIRST WORD CONTENT CONSUMPTION TRACKING ERROR: $error',
      );
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  _FirstWordQuestion? _questionFromDocument(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final Map<String, dynamic> data = document.data();
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
      for (final String value in rawAccepted.toString().split('|')) {
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

  Future<void> _showNewAchievementAndBadgePopups({
    required PlayerStats previous,
    required PlayerStats current,
  }) async {
    final List<EarnedBadge> earnedBadges =
        AchievementService.newlyEarnedBadges(
      previous: previous,
      current: current,
      gameKey: 'first_word',
      gameLabel: 'First Word',
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
      gameCategory: AchievementCategory.firstWord,
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
      await _showNewAchievementAndBadgePopups(
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

  Future<void> _finishCorrect({required bool wasFirstGuess}) async {
    final _FirstWordQuestion? question = _question;
    if (question == null || _roundFinished) {
      return;
    }

    setState(() {
      _roundFinished = true;
    });
    FocusScope.of(context).unfocus();

    final int base = _basePoints[_clueIndex];
    final int pointsWon = base + (wasFirstGuess ? _firstGuessBonus : 0);

    if (_practiceMode) {
      unawaited(
        AnalyticsService.logGameCompleted(
          gameType: 'first_word',
          category: 'first_word',
          subcategory: 'first_word',
          questionId: question.id,
          source: 'main_game',
          result: 'correct',
          xpEarned: 0,
          firstGuess: wasFirstGuess,
          practiceMode: true,
          clueNumber: _clueIndex + 1,
          guesses: _submittedGuessCount,
          livesRemaining: _lives,
          playTimeSeconds: _playTimeSeconds(),
        ),
      );

      unawaited(
        _logQuestionCompleted(
          question: question,
          result: 'correct',
          xpEarned: 0,
          firstGuess: wasFirstGuess,
        ),
      );

      await _showResultDialog(
        title: 'CORRECT!',
        message: 'PRACTICE MODE\n0 XP',
        success: true,
      );
      return;
    }

    await QuestionHistoryService.recordPlayedQuestion(question.id);
    final PlayerStats previousStats = _playerStats;
    final PlayerStats updated = await PlayerStatsService.recordCorrectGame(
      currentStats: _playerStats,
      category: GameCategory.other,
      pointsWon: pointsWon,
      clueNumber: _clueIndex + 1,
      wasFirstGuess: wasFirstGuess,
      playTimeSeconds: _playTimeSeconds(),
      mainCategoryKey: 'first_word',
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _playerStats = updated;
    });

    unawaited(
      AnalyticsService.logGameCompleted(
        gameType: 'first_word',
        category: 'first_word',
        subcategory: 'first_word',
        questionId: question.id,
        source: 'main_game',
        result: 'correct',
        xpEarned: pointsWon,
        firstGuess: wasFirstGuess,
        practiceMode: false,
        clueNumber: _clueIndex + 1,
        guesses: _submittedGuessCount,
        livesRemaining: _lives,
        playTimeSeconds: _playTimeSeconds(),
      ),
    );

    unawaited(
      _logQuestionCompleted(
        question: question,
        result: 'correct',
        xpEarned: pointsWon,
        firstGuess: wasFirstGuess,
      ),
    );

    await _recordContentConsumption(question);

    if (wasFirstGuess) {
      unawaited(
        AnalyticsService.logFirstGuessEarned(
          gameType: 'first_word',
          category: 'first_word',
          subcategory: 'first_word',
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
      gameKey: 'first_word',
      gameLabel: 'First Word',
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
    final _FirstWordQuestion? question = _question;
    if (question == null || _roundFinished) {
      return;
    }

    setState(() {
      _roundFinished = true;
    });
    FocusScope.of(context).unfocus();

    if (_practiceMode) {
      unawaited(
        AnalyticsService.logGameCompleted(
          gameType: 'first_word',
          category: 'first_word',
          subcategory: 'first_word',
          questionId: question.id,
          source: 'main_game',
          result: 'failed',
          xpEarned: 0,
          firstGuess: false,
          practiceMode: true,
          clueNumber: _clueIndex + 1,
          guesses: _submittedGuessCount,
          livesRemaining: _lives,
          playTimeSeconds: _playTimeSeconds(),
        ),
      );

      unawaited(
        _logQuestionCompleted(
          question: question,
          result: 'failed',
          xpEarned: 0,
          firstGuess: false,
        ),
      );

      await _showResultDialog(
        title: 'GAME OVER',
        message:
            'The answer was ${question.answer}.\n\nPRACTICE MODE\n0 XP',
        success: false,
      );
      return;
    }

    await QuestionHistoryService.recordPlayedQuestion(question.id);
    final PlayerStats updated = await PlayerStatsService.recordFailedGame(
      currentStats: _playerStats,
      playTimeSeconds: _playTimeSeconds(),
      mainCategoryKey: 'first_word',
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _playerStats = updated;
    });

    unawaited(
      AnalyticsService.logGameCompleted(
        gameType: 'first_word',
        category: 'first_word',
        subcategory: 'first_word',
        questionId: question.id,
        source: 'main_game',
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

    unawaited(
      _logQuestionCompleted(
        question: question,
        result: 'failed',
        xpEarned: 0,
        firstGuess: false,
      ),
    );

    await _recordContentConsumption(question);

    await _showResultDialog(
      title: 'GAME OVER',
      message: 'The answer was ${question.answer}.',
      success: false,
    );
  }

  Future<void> _giveUp() async {
    final _FirstWordQuestion? question = _question;
    if (_roundFinished || question == null) {
      return;
    }

    setState(() {
      _roundFinished = true;
      _message = null;
      _guessController.clear();
    });
    FocusScope.of(context).unfocus();

    if (_practiceMode) {
      unawaited(
        AnalyticsService.logGameCompleted(
          gameType: 'first_word',
          category: 'first_word',
          subcategory: 'first_word',
          questionId: question.id,
          source: 'main_game',
          result: 'gave_up',
          xpEarned: 0,
          firstGuess: false,
          practiceMode: true,
          clueNumber: _clueIndex + 1,
          guesses: _submittedGuessCount,
          livesRemaining: _lives,
          playTimeSeconds: _playTimeSeconds(),
        ),
      );

      unawaited(
        _logQuestionCompleted(
          question: question,
          result: 'gave_up',
          xpEarned: 0,
          firstGuess: false,
        ),
      );

      await _showResultDialog(
        title: 'YOU GAVE UP!',
        message:
            'The answer was ${question.answer}.\n\nPRACTICE MODE\n0 XP',
        success: false,
      );
      return;
    }

    await QuestionHistoryService.recordPlayedQuestion(question.id);
    final PlayerStats updated = await PlayerStatsService.recordFailedGame(
      currentStats: _playerStats,
      playTimeSeconds: _playTimeSeconds(),
      mainCategoryKey: 'first_word',
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _playerStats = updated;
    });

    unawaited(
      AnalyticsService.logGameCompleted(
        gameType: 'first_word',
        category: 'first_word',
        subcategory: 'first_word',
        questionId: question.id,
        source: 'main_game',
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

    unawaited(
      _logQuestionCompleted(
        question: question,
        result: 'gave_up',
        xpEarned: 0,
        firstGuess: false,
      ),
    );

    await _recordContentConsumption(question);

    await _showResultDialog(
      title: 'YOU GAVE UP!',
      message: 'The answer was ${question.answer}.',
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
                'assets/images/categories/category_headers/first_word_the_ultimate_quiz_banner.webp',
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
            const Icon(Icons.spellcheck_rounded, color: AppColors.orange, size: 64),
            const SizedBox(height: 18),
            Text(
              _allQuestionsPlayed
                  ? 'ALL FIRST WORD QUESTIONS PLAYED!'
                  : 'No live First Word questions found.',
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
                  ? 'You have completed every live First Word question. Continue in Practice Mode for 0 XP, or return when new questions are added.'
                  : 'Import the First Word workbook into Firebase, then try again.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.grey),
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
                totalScore: _playerStats.totalScore,
                currentStreak: _playerStats.currentStreak,
                firstGuesses: _playerStats.firstGuesses,
                gamesPlayed: _playerStats.gamesPlayed,
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
            SizedBox(height: _isInstalledPhone(context) ? 6 : 18),
            SizedBox(
              height: _isInstalledPhone(context) ? 44 : (isDesktop ? 88 : 76),
              child: Center(
                child: _buildWordPattern(
                  question.patterns[_clueIndex],
                  isDesktop: isDesktop,
                ),
              ),
            ),
            SizedBox(height: _isInstalledPhone(context) ? 6 : 16),
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
          decoration: InputDecoration(
            suffixIcon: _isInstalledPhone(context)
                ? Padding(
                    padding: EdgeInsets.zero,
                    child: SizedBox(
                      width: 110,
                      child: FilledButton(
                        onPressed: enabled ? _submitGuess : null,
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
              vertical: _isInstalledPhone(context) ? 12 : 22,
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
            if (!_isInstalledPhone(context)) Expanded(
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
            if (!_isInstalledPhone(context)) const SizedBox(width: 12),
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
            if (_isInstalledPhone(context)) ...<Widget>[
              const SizedBox(width: 10),
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: FilledButton(
                    onPressed: enabled ? _giveUp : null,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFAF3932),
                      foregroundColor: AppColors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text('GIVE UP', style: TextStyle(fontFamily: 'Oswald', fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
                ),
              ),
            ],
          ],
        ),
        if (!_isInstalledPhone(context)) const SizedBox(height: 12),
        if (!_isInstalledPhone(context)) SizedBox(
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
    final int points = _basePoints[_clueIndex];

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
                  'CLUE ${_clueIndex + 1} / 5',
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
                    : _clueIndex == 0
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

}
