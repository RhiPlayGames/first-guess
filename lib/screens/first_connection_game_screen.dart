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

class FirstConnectionGameScreen extends StatefulWidget {
  const FirstConnectionGameScreen({super.key});

  @override
  State<FirstConnectionGameScreen> createState() =>
      _FirstConnectionGameScreenState();
}

class _FirstConnectionQuestion {
  final String id;
  final String answer;
  final String displayAnswer;
  final Set<String> acceptedAnswers;
  final List<String> clues;

  const _FirstConnectionQuestion({
    required this.id,
    required this.answer,
    required this.displayAnswer,
    required this.acceptedAnswers,
    required this.clues,
  });
}

class _FirstConnectionGameScreenState
    extends State<FirstConnectionGameScreen> {
  static const int _maximumLives = 3;
  static const List<int> _basePoints = <int>[100, 80, 60, 40, 20];
  static const int _firstGuessBonus = 50;

  final TextEditingController _guessController = TextEditingController();
  final FocusNode _guessFocusNode = FocusNode();
  final Random _random = Random();
  final Set<String> _practiceSeenIds = <String>{};

  _FirstConnectionQuestion? _question;
  PlayerStats _playerStats = const PlayerStats();

  bool _loading = true;
  bool _hasLoadedStats = false;
  bool _roundFinished = false;
  bool _allQuestionsPlayed = false;
  bool _practiceMode = false;

  // Stage 0 = 2 clues visible, stage 4 = all 6 clues visible.
  int _stageIndex = 0;
  int _lives = _maximumLives;
  int _submittedGuessCount = 0;

  int _totalQuestionsAvailable = 0;

  String? _message;
  Color _messageColor = const Color(0xFFE14B4B);
  Timer? _messageTimer;
  DateTime _roundStartedAt = DateTime.now();

  bool get _isLastStage => _stageIndex >= 4;
  int get _visibleClueCount => _stageIndex + 2;

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

  Future<void> _loadRound() async {
    _messageTimer?.cancel();

    if (mounted) {
      setState(() {
        _loading = true;
        _roundFinished = false;
        _allQuestionsPlayed = false;
        _stageIndex = 0;
        _lives = _maximumLives;
        _submittedGuessCount = 0;
        _message = null;
        _guessController.clear();
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
          category: 'first_connection',
        ),
      ]);

      final PlayerStats stats = results[0] as PlayerStats;
      _hasLoadedStats = true;
      final Set<String> playedIds = results[1] as Set<String>;
      final List<QueryDocumentSnapshot<Map<String, dynamic>>> documents =
          results[2]
              as List<QueryDocumentSnapshot<Map<String, dynamic>>>;

      final List<_FirstConnectionQuestion> questions = documents
          .map(_questionFromDocument)
          .whereType<_FirstConnectionQuestion>()
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

      final List<_FirstConnectionQuestion> unplayed = questions
          .where(
            (_FirstConnectionQuestion item) => !playedIds.contains(item.id),
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
          categoryLabel: 'First Connection',
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

      List<_FirstConnectionQuestion> pool;

      if (_practiceMode) {
        pool = questions
            .where(
              (_FirstConnectionQuestion item) =>
                  !_practiceSeenIds.contains(item.id),
            )
            .toList();

        if (pool.isEmpty) {
          _practiceSeenIds.clear();
          pool = List<_FirstConnectionQuestion>.from(questions);
        }
      } else {
        pool = unplayed;
      }

      final _FirstConnectionQuestion selected =
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
          gameType: 'first_connection',
          category: 'first_connection',
          subcategory: 'first_connection',
          questionId: selected.id,
          source: 'main_game',
          practiceMode: _practiceMode,
        ),
      );

      unawaited(
        AnalyticsService.logQuestionStarted(
          gameKey: 'first_connection',
          category: 'first_connection',
          subcategory: 'first_connection',
          questionId: selected.id,
          source: 'main_game',
          practiceMode: _practiceMode,
        ),
      );

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

  Future<void> _recordContentConsumption(
    String questionId,
  ) async {
    if (_practiceMode || _totalQuestionsAvailable <= 0) {
      return;
    }

    try {
      await ContentConsumptionService.recordQuestionCompleted(
        gameKey: 'first_connection',
        category: 'first_connection',
        subcategory: 'first_connection',
        questionId: questionId,
        totalQuestionsAvailable: _totalQuestionsAvailable,
      );
    } catch (error, stackTrace) {
      debugPrint(
        'FIRST_CONNECTION CONTENT CONSUMPTION TRACKING ERROR: $error',
      );
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  _FirstConnectionQuestion? _questionFromDocument(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final Map<String, dynamic> data = document.data();

    final String answer = (data['answer'] ?? '').toString().trim();
    if (answer.isEmpty) {
      return null;
    }

    final String rawDisplayAnswer =
        (data['displayAnswer'] ?? '').toString().trim();
    final String displayAnswer =
        rawDisplayAnswer.isNotEmpty ? rawDisplayAnswer : answer;

    final List<String> clues = <String>[
      for (int index = 1; index <= 6; index++)
        (data['clue$index'] ?? '').toString().trim(),
    ];

    if (clues.any((String clue) => clue.isEmpty)) {
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
      for (final String value in rawAccepted.toString().split('*')) {
        final String normalised = _normalise(value);
        if (normalised.isNotEmpty) {
          accepted.add(normalised);
        }
      }
    }

    return _FirstConnectionQuestion(
      id: document.id,
      answer: answer,
      displayAnswer: displayAnswer,
      acceptedAnswers: accepted,
      clues: clues,
    );
  }

  String _normalise(String value) {
    String normalised = value.trim().toLowerCase();
    normalised = normalised.replaceAll('&', ' and ');
    normalised = normalised.replaceAll(RegExp(r'[^a-z0-9]+'), ' ');
    return normalised.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  bool _isBroadButRelatedGuess(
    String normalisedGuess,
    Set<String> acceptedAnswers,
  ) {
    if (normalisedGuess.isEmpty ||
        acceptedAnswers.contains(normalisedGuess)) {
      return false;
    }

    final List<String> guessWords = normalisedGuess.split(' ');
    final Set<String> ignoredWords = <String>{
      'a',
      'an',
      'and',
      'of',
      'the',
      'to',
      'in',
      'on',
      'for',
      'with',
      'types',
      'type',
      'kind',
      'kinds',
    };

    final List<String> meaningfulGuessWords = guessWords
        .where(
          (String word) =>
              word.length >= 3 && !ignoredWords.contains(word),
        )
        .toList();

    if (meaningfulGuessWords.isEmpty) {
      return false;
    }

    for (final String accepted in acceptedAnswers) {
      final List<String> acceptedWords = accepted.split(' ');

      if (meaningfulGuessWords.every(acceptedWords.contains)) {
        return true;
      }
    }

    return false;
  }

  Future<void> _submitGuess() async {
    final _FirstConnectionQuestion? question = _question;

    if (question == null || _roundFinished || _lives <= 0) {
      return;
    }

    final String rawGuess = _guessController.text.trim();
    if (rawGuess.isEmpty) {
      _showTemporaryMessage('TYPE YOUR GUESS FIRST');
      return;
    }

    final String normalisedGuess = _normalise(rawGuess);
    final bool isCorrect =
        question.acceptedAnswers.contains(normalisedGuess);

    final bool wasFirstGuess =
        isCorrect && _stageIndex == 0 && _submittedGuessCount == 0;

    _submittedGuessCount++;

    if (isCorrect) {
      await _finishCorrect(wasFirstGuess: wasFirstGuess);
      return;
    }

    final bool isBroadButRelated = _isBroadButRelatedGuess(
      normalisedGuess,
      question.acceptedAnswers,
    );

    if (isBroadButRelated) {
      setState(() {
        _guessController.clear();
      });

      _showTemporaryMessage(
        'CLOSE! BE MORE SPECIFIC.',
        color: AppColors.orange,
      );

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _guessFocusNode.requestFocus();
        }
      });

      return;
    }

    final int newLives = _lives - 1;

    if (newLives <= 0) {
      setState(() {
        _lives = 0;
        _guessController.clear();
        _message = null;
      });
      _messageTimer?.cancel();

      _showTemporaryMessage(
        'INCORRECT — NO LIVES LEFT',
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
      if (!_isLastStage) {
        _stageIndex++;
      }
      _guessController.clear();
    });

    _showTemporaryMessage('Incorrect! One life lost.');

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _guessFocusNode.requestFocus();
      }
    });
  }

  Future<void> _nextClue() async {
    if (_roundFinished || _isLastStage || _lives <= 0) {
      return;
    }

    setState(() {
      _stageIndex++;
      _guessController.clear();
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _guessFocusNode.requestFocus();
      }
    });
  }

  int _playTimeSeconds() {
    return DateTime.now().difference(_roundStartedAt).inSeconds;
  }

  Future<void> _showNewAchievementPopups({
    required PlayerStats previous,
    required PlayerStats current,
  }) async {
    final List<EarnedBadge> earnedBadges =
        AchievementService.newlyEarnedBadges(
      previous: previous,
      current: current,
      gameKey: 'first_connection',
      gameLabel: 'First Connection',
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
      gameCategory: AchievementCategory.firstConnection,
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

  Future<void> _finishCorrect({
    required bool wasFirstGuess,
  }) async {
    final _FirstConnectionQuestion? question = _question;

    if (question == null || _roundFinished) {
      return;
    }

    setState(() {
      _roundFinished = true;
    });

    FocusScope.of(context).unfocus();

    final int base = _basePoints[_stageIndex];
    final int pointsWon =
        base + (wasFirstGuess ? _firstGuessBonus : 0);

    if (_practiceMode) {
      unawaited(
        AnalyticsService.logGameCompleted(
          gameType: 'first_connection',
          category: 'first_connection',
          subcategory: 'first_connection',
          questionId: question.id,
          source: 'main_game',
          result: 'correct',
          xpEarned: 0,
          firstGuess: wasFirstGuess,
          practiceMode: true,
          clueNumber: _stageIndex + 1,
          guesses: _submittedGuessCount,
          livesRemaining: _lives,
          playTimeSeconds: _playTimeSeconds(),
        ),
      );

      unawaited(
        AnalyticsService.logQuestionCompleted(
          gameKey: 'first_connection',
          category: 'first_connection',
          subcategory: 'first_connection',
          questionId: question.id,
          source: 'main_game',
          result: 'correct',
          xpEarned: 0,
          firstGuess: wasFirstGuess,
          practiceMode: true,
          clueNumber: _stageIndex + 1,
          guesses: _submittedGuessCount,
          livesRemaining: _lives,
          playTimeSeconds: _playTimeSeconds(),
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
    await _recordContentConsumption(question.id);

    final PlayerStats previousStats = _playerStats;
    final PlayerStats updated =
        await PlayerStatsService.recordCorrectGame(
      currentStats: _playerStats,
      category: GameCategory.other,
      pointsWon: pointsWon,
      clueNumber: _stageIndex + 1,
      wasFirstGuess: wasFirstGuess,
      playTimeSeconds: _playTimeSeconds(),
      mainCategoryKey: 'first_connection',
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _playerStats = updated;
    });

    unawaited(
      AnalyticsService.logGameCompleted(
        gameType: 'first_connection',
        category: 'first_connection',
        subcategory: 'first_connection',
        questionId: question.id,
        source: 'main_game',
        result: 'correct',
        xpEarned: pointsWon,
        firstGuess: wasFirstGuess,
        practiceMode: false,
        clueNumber: _stageIndex + 1,
        guesses: _submittedGuessCount,
        livesRemaining: _lives,
        playTimeSeconds: _playTimeSeconds(),
      ),
    );

    unawaited(
      AnalyticsService.logQuestionCompleted(
        gameKey: 'first_connection',
        category: 'first_connection',
        subcategory: 'first_connection',
        questionId: question.id,
        source: 'main_game',
        result: 'correct',
        xpEarned: pointsWon,
        firstGuess: wasFirstGuess,
        practiceMode: false,
        clueNumber: _stageIndex + 1,
        guesses: _submittedGuessCount,
        livesRemaining: _lives,
        playTimeSeconds: _playTimeSeconds(),
      ),
    );

    if (wasFirstGuess) {
      unawaited(
        AnalyticsService.logFirstGuessEarned(
          gameType: 'first_connection',
          category: 'first_connection',
          subcategory: 'first_connection',
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
      gameKey: 'first_connection',
      gameLabel: 'First Connection',
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
    final _FirstConnectionQuestion? question = _question;

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
          gameType: 'first_connection',
          category: 'first_connection',
          subcategory: 'first_connection',
          questionId: question.id,
          source: 'main_game',
          result: 'failed',
          xpEarned: 0,
          firstGuess: false,
          practiceMode: true,
          clueNumber: _stageIndex + 1,
          guesses: _submittedGuessCount,
          livesRemaining: _lives,
          playTimeSeconds: _playTimeSeconds(),
        ),
      );

      unawaited(
        AnalyticsService.logQuestionCompleted(
          gameKey: 'first_connection',
          category: 'first_connection',
          subcategory: 'first_connection',
          questionId: question.id,
          source: 'main_game',
          result: 'failed',
          xpEarned: 0,
          firstGuess: false,
          practiceMode: true,
          clueNumber: _stageIndex + 1,
          guesses: _submittedGuessCount,
          livesRemaining: _lives,
          playTimeSeconds: _playTimeSeconds(),
        ),
      );

      await _showResultDialog(
        title: 'GAME OVER',
        message:
            'The connection was ${question.displayAnswer}.\n\nPRACTICE MODE\n0 XP',
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
      mainCategoryKey: 'first_connection',
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _playerStats = updated;
    });

    unawaited(
      AnalyticsService.logGameCompleted(
        gameType: 'first_connection',
        category: 'first_connection',
        subcategory: 'first_connection',
        questionId: question.id,
        source: 'main_game',
        result: 'failed',
        xpEarned: 0,
        firstGuess: false,
        practiceMode: false,
        clueNumber: _stageIndex + 1,
        guesses: _submittedGuessCount,
        livesRemaining: _lives,
        playTimeSeconds: _playTimeSeconds(),
      ),
    );

    unawaited(
      AnalyticsService.logQuestionCompleted(
        gameKey: 'first_connection',
        category: 'first_connection',
        subcategory: 'first_connection',
        questionId: question.id,
        source: 'main_game',
        result: 'failed',
        xpEarned: 0,
        firstGuess: false,
        practiceMode: false,
        clueNumber: _stageIndex + 1,
        guesses: _submittedGuessCount,
        livesRemaining: _lives,
        playTimeSeconds: _playTimeSeconds(),
      ),
    );

    await _showResultDialog(
      title: 'GAME OVER',
      message:
          'The connection was ${question.displayAnswer}.',
      success: false,
    );
  }

  Future<void> _giveUp() async {
    final _FirstConnectionQuestion? question = _question;

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
          gameType: 'first_connection',
          category: 'first_connection',
          subcategory: 'first_connection',
          questionId: question.id,
          source: 'main_game',
          result: 'gave_up',
          xpEarned: 0,
          firstGuess: false,
          practiceMode: true,
          clueNumber: _stageIndex + 1,
          guesses: _submittedGuessCount,
          livesRemaining: _lives,
          playTimeSeconds: _playTimeSeconds(),
        ),
      );

      unawaited(
        AnalyticsService.logQuestionCompleted(
          gameKey: 'first_connection',
          category: 'first_connection',
          subcategory: 'first_connection',
          questionId: question.id,
          source: 'main_game',
          result: 'gave_up',
          xpEarned: 0,
          firstGuess: false,
          practiceMode: true,
          clueNumber: _stageIndex + 1,
          guesses: _submittedGuessCount,
          livesRemaining: _lives,
          playTimeSeconds: _playTimeSeconds(),
        ),
      );

      await _showResultDialog(
        title: 'YOU GAVE UP!',
        message:
            'The connection was ${question.displayAnswer}.\n\nPRACTICE MODE\n0 XP',
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
      mainCategoryKey: 'first_connection',
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _playerStats = updated;
    });

    unawaited(
      AnalyticsService.logGameCompleted(
        gameType: 'first_connection',
        category: 'first_connection',
        subcategory: 'first_connection',
        questionId: question.id,
        source: 'main_game',
        result: 'gave_up',
        xpEarned: 0,
        firstGuess: false,
        practiceMode: false,
        clueNumber: _stageIndex + 1,
        guesses: _submittedGuessCount,
        livesRemaining: _lives,
        playTimeSeconds: _playTimeSeconds(),
      ),
    );

    unawaited(
      AnalyticsService.logQuestionCompleted(
        gameKey: 'first_connection',
        category: 'first_connection',
        subcategory: 'first_connection',
        questionId: question.id,
        source: 'main_game',
        result: 'gave_up',
        xpEarned: 0,
        firstGuess: false,
        practiceMode: false,
        clueNumber: _stageIndex + 1,
        guesses: _submittedGuessCount,
        livesRemaining: _lives,
        playTimeSeconds: _playTimeSeconds(),
      ),
    );

    await _showResultDialog(
      title: 'YOU GAVE UP!',
      message:
          'The connection was ${question.displayAnswer}.',
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
                'assets/images/categories/category_headers/first_connection_bold_title_card.webp',
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
              Icons.hub_rounded,
              color: AppColors.orange,
              size: 64,
            ),
            const SizedBox(height: 18),
            Text(
              _allQuestionsPlayed
                  ? 'ALL FIRST CONNECTION QUESTIONS PLAYED!'
                  : 'No live First Connection questions found.',
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
                  ? 'You have completed every live First Connection question. Continue in Practice Mode for 0 XP, or return when new questions are added.'
                  : 'Import the First Connection workbook into Firebase, then try again.',
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
    final _FirstConnectionQuestion question = _question!;
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
              _buildClueHeaderBlock(),
              const SizedBox(height: 12),
              _buildInstructionStrip(),
              if (_message != null) ...<Widget>[
                const SizedBox(height: 12),
                GameMessagePanel(
                  message: _message!,
                  type: _messageColor == const Color(0xFFE14B4B)
                      ? GameMessageType.error
                      : GameMessageType.info,
                ),
              ],
              const SizedBox(height: 12),
              _buildConnectionGrid(
                question,
                isDesktop: isDesktop,
              ),
              const SizedBox(height: 14),
              _buildGuessPanel(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildConnectionGrid(
    _FirstConnectionQuestion question, {
    required bool isDesktop,
  }) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 6,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: isDesktop ? 14 : 10,
        mainAxisSpacing: isDesktop ? 14 : 10,
        childAspectRatio: isDesktop ? 4.6 : 3.2,
      ),
      itemBuilder: (
        BuildContext context,
        int index,
      ) {
        final bool revealed = index < _visibleClueCount;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          alignment: Alignment.center,
          padding: EdgeInsets.symmetric(
            horizontal: isDesktop ? 18 : 10,
            vertical: isDesktop ? 7 : 6,
          ),
          decoration: BoxDecoration(
            color: revealed
                ? const Color(0xFF171717)
                : const Color(0xFF111111),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: AppColors.orange,
              width: 1.0,
            ),
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              revealed
                  ? question.clues[index].toUpperCase()
                  : '?',
              maxLines: 1,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Oswald',
                color: revealed
                    ? AppColors.white
                    : const Color(0xFF666666),
                fontSize: revealed
                    ? (isDesktop ? 26 : 20)
                    : (isDesktop ? 32 : 27),
                fontWeight: FontWeight.w700,
                letterSpacing: revealed ? 0.35 : 0,
                height: 1,
              ),
            ),
          ),
        );
      },
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
        'LOOK AT THE CLUES AND FIND THE CONNECTION',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontFamily: 'Oswald',
          color: AppColors.white,
          fontSize: 17,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.35,
          height: 1.1,
        ),
      ),
    );
  }

  Widget _buildGuessPanel() {
    final bool enabled =
        !_roundFinished && _lives > 0;

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
            hintText: 'Type your guess...',
            hintStyle: TextStyle(
              fontFamily: 'Inter',
              color: AppColors.white,
              fontSize: 17,
            ),
            filled: true,
            fillColor: AppColors.panel,
            contentPadding: EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 15,
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
                  onPressed: enabled && !_isLastStage
                      ? _nextClue
                      : null,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.white,
                    disabledForegroundColor:
                        const Color(0xFF5E5E5E),
                    side: BorderSide(
                      color: enabled && !_isLastStage
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
    final int points = _basePoints[_stageIndex];

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
                  'CLUES $_visibleClueCount / 6',
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
                    : _stageIndex == 0
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
