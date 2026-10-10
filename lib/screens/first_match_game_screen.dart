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

class FirstMatchGameScreen extends StatefulWidget {
  const FirstMatchGameScreen({super.key});

  @override
  State<FirstMatchGameScreen> createState() => _FirstMatchGameScreenState();
}

class _FirstMatchPair {
  final String left;
  final String right;

  const _FirstMatchPair({
    required this.left,
    required this.right,
  });
}

class _FirstMatchChallenge {
  final String id;
  final List<_FirstMatchPair> pairs;

  const _FirstMatchChallenge({
    required this.id,
    required this.pairs,
  });
}

class _FirstMatchGameScreenState extends State<FirstMatchGameScreen> {
  static const int _pairCount = 6;
  static const int _maximumLives = 3;
  static const List<int> _basePoints = <int>[100, 80, 60, 40, 20];
  static const int _firstGuessBonus = 50;

  static const List<Color> _pairColours = <Color>[
    Color(0xFFFE5E02),
    Color(0xFF4DA3FF),
    Color(0xFFA86BFF),
    Color(0xFFFFC447),
    Color(0xFF35C9C3),
    Color(0xFFFF6FAE),
  ];

  final Random _random = Random();
  final Set<String> _practiceSeenIds = <String>{};

  PlayerStats _playerStats = const PlayerStats();
  _FirstMatchChallenge? _challenge;

  List<String> _rightChoices = <String>[];

  // left index -> right choice index.
  final Map<int, int> _tentativeMatches = <int, int>{};

  // Left indexes confirmed correct by a submitted board.
  final Set<int> _lockedLeftIndexes = <int>{};

  // right choice indexes confirmed correct by a submitted board.
  final Set<int> _lockedRightIndexes = <int>{};

  int? _selectedLeftIndex;
  int _lives = _maximumLives;
  int _submittedBoards = 0;

  bool _loading = true;
  bool _hasLoadedStats = false;
  bool _roundFinished = false;
  bool _allQuestionsPlayed = false;
  bool _practiceMode = false;

  int _totalQuestionsAvailable = 0;

  String? _message;
  Color _messageColor = const Color(0xFFE14B4B);
  Timer? _messageTimer;

  DateTime _roundStartedAt = DateTime.now();

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

  int get _currentSubmissionNumber =>
      (_submittedBoards + 1).clamp(1, _basePoints.length);

  int get _pointsAvailable =>
      _basePoints[_currentSubmissionNumber - 1];

  bool get _allUnlockedLeftMatched {
    final _FirstMatchChallenge? challenge = _challenge;
    if (challenge == null) {
      return false;
    }

    for (int i = 0; i < challenge.pairs.length; i++) {
      if (_lockedLeftIndexes.contains(i)) {
        continue;
      }
      if (!_tentativeMatches.containsKey(i)) {
        return false;
      }
    }

    return true;
  }

  int _playTimeSeconds() =>
      DateTime.now().difference(_roundStartedAt).inSeconds;

  _FirstMatchChallenge? _challengeFromDocument(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final Map<String, dynamic> data = doc.data();
    final dynamic rawPairs = data['pairs'];

    if (rawPairs is! List || rawPairs.length != _pairCount) {
      return null;
    }

    final List<_FirstMatchPair> parsed = <_FirstMatchPair>[];

    for (final dynamic item in rawPairs) {
      if (item is! Map) {
        return null;
      }

      final String left = (item['left'] ?? '').toString().trim();
      final String right = (item['right'] ?? '').toString().trim();

      if (left.isEmpty || right.isEmpty) {
        return null;
      }

      parsed.add(
        _FirstMatchPair(
          left: left,
          right: right,
        ),
      );
    }

    return _FirstMatchChallenge(
      id: doc.id,
      pairs: parsed,
    );
  }

  Future<void> _loadRound() async {
    _messageTimer?.cancel();

    if (mounted) {
      setState(() {
        _loading = true;
        _roundFinished = false;
        _allQuestionsPlayed = false;
        _tentativeMatches.clear();
        _lockedLeftIndexes.clear();
        _lockedRightIndexes.clear();
        _selectedLeftIndex = null;
        _lives = _maximumLives;
        _submittedBoards = 0;
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
          category: 'first_match',
        ),
      ]);

      final PlayerStats stats = results[0] as PlayerStats;
      _hasLoadedStats = true;
      final Set<String> playedIds = results[1] as Set<String>;
      final List<QueryDocumentSnapshot<Map<String, dynamic>>> documents =
          results[2]
              as List<QueryDocumentSnapshot<Map<String, dynamic>>>;

      final List<_FirstMatchChallenge> challenges = documents
          .map(_challengeFromDocument)
          .whereType<_FirstMatchChallenge>()
          .toList();

      _totalQuestionsAvailable = challenges.length;

      if (!mounted) {
        return;
      }

      if (challenges.isEmpty) {
        setState(() {
          _playerStats = stats;
          _challenge = null;
          _loading = false;
        });
        return;
      }

      final List<_FirstMatchChallenge> unplayed = challenges
          .where(
            (_FirstMatchChallenge item) =>
                !playedIds.contains(item.id),
          )
          .toList();

      if (!_practiceMode && unplayed.isEmpty) {
        setState(() {
          _playerStats = stats;
          _challenge = null;
          _allQuestionsPlayed = true;
          _loading = false;
        });

        final bool? continueInPractice =
            await showPracticeModeDialog(
          context: context,
          categoryLabel: 'First Match',
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

      List<_FirstMatchChallenge> pool;

      if (_practiceMode) {
        pool = challenges
            .where(
              (_FirstMatchChallenge item) =>
                  !_practiceSeenIds.contains(item.id),
            )
            .toList();

        if (pool.isEmpty) {
          _practiceSeenIds.clear();
          pool = List<_FirstMatchChallenge>.from(challenges);
        }
      } else {
        pool = unplayed;
      }

      final _FirstMatchChallenge selected =
          pool[_random.nextInt(pool.length)];

      if (_practiceMode) {
        _practiceSeenIds.add(selected.id);
      }

      final List<String> shuffled = selected.pairs
          .map((_FirstMatchPair pair) => pair.right)
          .toList();

      do {
        shuffled.shuffle(_random);
      } while (_sameOrder(
        shuffled,
        selected.pairs
            .map((_FirstMatchPair pair) => pair.right)
            .toList(),
      ));

      setState(() {
        _playerStats = stats;
        _challenge = selected;
        _rightChoices = shuffled;
        _roundStartedAt = DateTime.now();
        _loading = false;
      });

      unawaited(
        AnalyticsService.logGameStarted(
          gameType: 'first_match',
          category: 'first_match',
          subcategory: 'first_match',
          questionId: selected.id,
          source: 'main_game',
          practiceMode: _practiceMode,
        ),
      );

      unawaited(
        AnalyticsService.logQuestionStarted(
          gameKey: 'first_match',
          category: 'first_match',
          subcategory: 'first_match',
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
        _challenge = null;
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
        gameKey: 'first_match',
        category: 'first_match',
        subcategory: 'first_match',
        questionId: questionId,
        totalQuestionsAvailable: _totalQuestionsAvailable,
      );
    } catch (error, stackTrace) {
      debugPrint(
        'FIRST_MATCH CONTENT CONSUMPTION TRACKING ERROR: $error',
      );
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  bool _sameOrder(
    List<String> first,
    List<String> second,
  ) {
    if (first.length != second.length) {
      return false;
    }

    for (int i = 0; i < first.length; i++) {
      if (first[i] != second[i]) {
        return false;
      }
    }

    return true;
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

  int? _leftForRight(int rightIndex) {
    for (final MapEntry<int, int> entry
        in _tentativeMatches.entries) {
      if (entry.value == rightIndex) {
        return entry.key;
      }
    }
    return null;
  }

  int? _pairColourIndexForLeft(int leftIndex) {
    if (_lockedLeftIndexes.contains(leftIndex) ||
        _selectedLeftIndex == leftIndex ||
        _tentativeMatches.containsKey(leftIndex)) {
      return leftIndex % _pairColours.length;
    }

    return null;
  }

  int? _pairColourIndexForRight(int rightIndex) {
    if (_lockedRightIndexes.contains(rightIndex)) {
      final _FirstMatchChallenge? challenge = _challenge;
      if (challenge == null ||
          rightIndex < 0 ||
          rightIndex >= _rightChoices.length) {
        return null;
      }

      final String rightValue = _rightChoices[rightIndex];
      for (int leftIndex = 0;
          leftIndex < challenge.pairs.length;
          leftIndex++) {
        if (challenge.pairs[leftIndex].right == rightValue) {
          return leftIndex % _pairColours.length;
        }
      }

      return null;
    }

    final int? leftIndex = _leftForRight(rightIndex);
    if (leftIndex == null) {
      return null;
    }

    return leftIndex % _pairColours.length;
  }

  void _selectLeft(int leftIndex) {
    if (_roundFinished ||
        _lockedLeftIndexes.contains(leftIndex)) {
      return;
    }

    setState(() {
      if (_tentativeMatches.containsKey(leftIndex)) {
        _tentativeMatches.remove(leftIndex);
        _selectedLeftIndex = null;
        return;
      }

      _selectedLeftIndex =
          _selectedLeftIndex == leftIndex
              ? null
              : leftIndex;
    });
  }

  void _selectRight(int rightIndex) {
    if (_roundFinished ||
        _lockedRightIndexes.contains(rightIndex)) {
      return;
    }

    final int? leftIndex = _selectedLeftIndex;

    if (leftIndex == null) {
      final int? currentlyPairedLeft =
          _leftForRight(rightIndex);

      if (currentlyPairedLeft != null &&
          !_lockedLeftIndexes.contains(currentlyPairedLeft)) {
        setState(() {
          _tentativeMatches.remove(currentlyPairedLeft);
          _selectedLeftIndex = null;
        });
        return;
      }

      _showTemporaryMessage(
        'SELECT AN ITEM ON THE LEFT FIRST',
        color: AppColors.orange,
        duration: const Duration(milliseconds: 1300),
      );
      return;
    }

    setState(() {
      // If this right choice was tentatively paired elsewhere,
      // remove that old pairing first.
      final int? oldLeft = _leftForRight(rightIndex);
      if (oldLeft != null &&
          !_lockedLeftIndexes.contains(oldLeft)) {
        _tentativeMatches.remove(oldLeft);
      }

      _tentativeMatches[leftIndex] = rightIndex;
      _selectedLeftIndex = null;
    });
  }

  Future<void> _submitMatches() async {
    final _FirstMatchChallenge? challenge = _challenge;

    if (challenge == null ||
        _roundFinished ||
        !_allUnlockedLeftMatched) {
      return;
    }

    final int submissionNumber = _currentSubmissionNumber;
    final Set<int> newlyCorrectLeft = <int>{};
    final Set<int> newlyCorrectRight = <int>{};

    for (int leftIndex = 0;
        leftIndex < challenge.pairs.length;
        leftIndex++) {
      if (_lockedLeftIndexes.contains(leftIndex)) {
        continue;
      }

      final int? rightIndex =
          _tentativeMatches[leftIndex];

      if (rightIndex == null) {
        continue;
      }

      final String chosen = _rightChoices[rightIndex];
      final String correct =
          challenge.pairs[leftIndex].right;

      if (chosen == correct) {
        newlyCorrectLeft.add(leftIndex);
        newlyCorrectRight.add(rightIndex);
      }
    }

    final Set<int> incorrectLeft = _tentativeMatches.keys
        .where(
          (int leftIndex) =>
              !_lockedLeftIndexes.contains(leftIndex) &&
              !newlyCorrectLeft.contains(leftIndex),
        )
        .toSet();

    setState(() {
      _lockedLeftIndexes.addAll(newlyCorrectLeft);
      _lockedRightIndexes.addAll(newlyCorrectRight);

      for (final int leftIndex in newlyCorrectLeft) {
        _tentativeMatches.remove(leftIndex);
      }

      for (final int leftIndex in incorrectLeft) {
        _tentativeMatches.remove(leftIndex);
      }

      _selectedLeftIndex = null;
    });

    if (_lockedLeftIndexes.length == _pairCount) {
      await _finishCorrect(
        submissionNumber: submissionNumber,
      );
      return;
    }

    final int nextLives = _lives - 1;
    final int nextSubmitted = _submittedBoards + 1;

    setState(() {
      _lives = nextLives;
      _submittedBoards = nextSubmitted;
    });

    if (nextLives <= 0 || nextSubmitted >= _maximumLives) {
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

    final int lockedCount = _lockedLeftIndexes.length;
    final int remaining = _pairCount - lockedCount;

    _showTemporaryMessage(
      '$lockedCount CORRECT — $remaining TO GO — ONE LIFE LOST',
      color: AppColors.orange,
      duration: const Duration(milliseconds: 2200),
    );
  }

  Future<void> _finishCorrect({
    required int submissionNumber,
  }) async {
    final _FirstMatchChallenge? challenge = _challenge;

    if (challenge == null || _roundFinished) {
      return;
    }

    final bool wasFirstGuess = submissionNumber == 1;
    final int pointsWon =
        _basePoints[submissionNumber - 1] +
            (wasFirstGuess ? _firstGuessBonus : 0);

    setState(() {
      _roundFinished = true;
      _selectedLeftIndex = null;
    });

    if (_practiceMode) {
      unawaited(
        AnalyticsService.logGameCompleted(
          gameType: 'first_match',
          category: 'first_match',
          subcategory: 'first_match',
          questionId: challenge.id,
          source: 'main_game',
          result: 'correct',
          xpEarned: 0,
          firstGuess: wasFirstGuess,
          practiceMode: true,
          clueNumber: submissionNumber,
          guesses: submissionNumber,
          livesRemaining: _lives,
          playTimeSeconds: _playTimeSeconds(),
        ),
      );

      unawaited(
        AnalyticsService.logQuestionCompleted(
          gameKey: 'first_match',
          category: 'first_match',
          subcategory: 'first_match',
          questionId: challenge.id,
          source: 'main_game',
          result: 'correct',
          xpEarned: 0,
          firstGuess: wasFirstGuess,
          practiceMode: true,
          clueNumber: submissionNumber,
          guesses: submissionNumber,
          livesRemaining: _lives,
          playTimeSeconds: _playTimeSeconds(),
        ),
      );

      await _showResultDialog(
        title: 'PERFECT MATCH!',
        message: 'ALL 6 PAIRS CORRECT\n\nPRACTICE MODE\n0 XP',
      );
      return;
    }

    await QuestionHistoryService.recordPlayedQuestion(
      challenge.id,
    );
    await _recordContentConsumption(challenge.id);

    final PlayerStats previousStats = _playerStats;
    final PlayerStats updated =
        await PlayerStatsService.recordCorrectGame(
      currentStats: _playerStats,
      category: GameCategory.other,
      pointsWon: pointsWon,
      clueNumber: submissionNumber,
      wasFirstGuess: wasFirstGuess,
      playTimeSeconds: _playTimeSeconds(),
      mainCategoryKey: 'first_match',
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _playerStats = updated;
    });

    unawaited(
      AnalyticsService.logGameCompleted(
        gameType: 'first_match',
        category: 'first_match',
        subcategory: 'first_match',
        questionId: challenge.id,
        source: 'main_game',
        result: 'correct',
        xpEarned: pointsWon,
        firstGuess: wasFirstGuess,
        practiceMode: false,
        clueNumber: submissionNumber,
        guesses: submissionNumber,
        livesRemaining: _lives,
        playTimeSeconds: _playTimeSeconds(),
      ),
    );

    unawaited(
      AnalyticsService.logQuestionCompleted(
        gameKey: 'first_match',
        category: 'first_match',
        subcategory: 'first_match',
        questionId: challenge.id,
        source: 'main_game',
        result: 'correct',
        xpEarned: pointsWon,
        firstGuess: wasFirstGuess,
        practiceMode: false,
        clueNumber: submissionNumber,
        guesses: submissionNumber,
        livesRemaining: _lives,
        playTimeSeconds: _playTimeSeconds(),
      ),
    );

    if (wasFirstGuess) {
      unawaited(
        AnalyticsService.logFirstGuessEarned(
          gameType: 'first_match',
          category: 'first_match',
          subcategory: 'first_match',
          questionId: challenge.id,
          source: 'main_game',
          xpEarned: pointsWon,
          practiceMode: false,
        ),
      );
    }

    await AnalyticsService.logEarnedRewards(
      previous: previousStats,
      current: updated,
      gameKey: 'first_match',
      gameLabel: 'First Match',
    );

    await _showResultDialog(
      title: wasFirstGuess
          ? 'FIRST GUESS!'
          : 'PERFECT MATCH!',
      message: wasFirstGuess
          ? 'ALL 6 PAIRS CORRECT\n\n100 XP\n50 XP First Guess Bonus\n\n150 XP TOTAL'
          : 'ALL 6 PAIRS CORRECT\n\n$pointsWon XP',
      previousStats: previousStats,
      currentStats: updated,
    );
  }

  String _correctMatchesText(_FirstMatchChallenge challenge) {
    return challenge.pairs
        .map(
          (_FirstMatchPair pair) =>
              '${pair.left} — ${pair.right}',
        )
        .join('\n');
  }

  Future<void> _finishFailed() async {
    final _FirstMatchChallenge? challenge = _challenge;

    if (challenge == null || _roundFinished) {
      return;
    }

    setState(() {
      _roundFinished = true;
      _selectedLeftIndex = null;
      _tentativeMatches.clear();
    });

    if (!_practiceMode) {
      await QuestionHistoryService.recordPlayedQuestion(
        challenge.id,
      );
      await _recordContentConsumption(challenge.id);

      final PlayerStats updated =
          await PlayerStatsService.recordFailedGame(
        currentStats: _playerStats,
        playTimeSeconds: _playTimeSeconds(),
        mainCategoryKey: 'first_match',
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _playerStats = updated;
      });
    }

    if (!mounted) {
      return;
    }

    final String correctMatches =
        _correctMatchesText(challenge);

    unawaited(
      AnalyticsService.logGameCompleted(
        gameType: 'first_match',
        category: 'first_match',
        subcategory: 'first_match',
        questionId: challenge.id,
        source: 'main_game',
        result: 'failed',
        xpEarned: 0,
        firstGuess: false,
        practiceMode: _practiceMode,
        clueNumber: _currentSubmissionNumber,
        guesses: _submittedBoards,
        livesRemaining: _lives,
        playTimeSeconds: _playTimeSeconds(),
      ),
    );

    unawaited(
      AnalyticsService.logQuestionCompleted(
        gameKey: 'first_match',
        category: 'first_match',
        subcategory: 'first_match',
        questionId: challenge.id,
        source: 'main_game',
        result: 'failed',
        xpEarned: 0,
        firstGuess: false,
        practiceMode: _practiceMode,
        clueNumber: _currentSubmissionNumber,
        guesses: _submittedBoards,
        livesRemaining: _lives,
        playTimeSeconds: _playTimeSeconds(),
      ),
    );

    await _showResultDialog(
      title: 'GAME OVER',
      message: _practiceMode
          ? 'THE CORRECT MATCHES WERE:\n\n$correctMatches\n\nPRACTICE MODE\n0 XP'
          : 'THE CORRECT MATCHES WERE:\n\n$correctMatches',
    );
  }

  Future<void> _giveUp() async {
    final _FirstMatchChallenge? challenge = _challenge;

    if (challenge == null || _roundFinished) {
      return;
    }

    setState(() {
      _roundFinished = true;
      _selectedLeftIndex = null;
      _tentativeMatches.clear();

      for (int leftIndex = 0;
          leftIndex < challenge.pairs.length;
          leftIndex++) {
        final int rightIndex = _rightChoices.indexOf(
          challenge.pairs[leftIndex].right,
        );

        if (rightIndex >= 0) {
          _lockedLeftIndexes.add(leftIndex);
          _lockedRightIndexes.add(rightIndex);
        }
      }
    });

    if (!_practiceMode) {
      await QuestionHistoryService.recordPlayedQuestion(
        challenge.id,
      );
      await _recordContentConsumption(challenge.id);

      final PlayerStats updated =
          await PlayerStatsService.recordFailedGame(
        currentStats: _playerStats,
        playTimeSeconds: _playTimeSeconds(),
        mainCategoryKey: 'first_match',
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _playerStats = updated;
      });
    }

    if (!mounted) {
      return;
    }

    final String correctMatches =
        _correctMatchesText(challenge);

    unawaited(
      AnalyticsService.logGameCompleted(
        gameType: 'first_match',
        category: 'first_match',
        subcategory: 'first_match',
        questionId: challenge.id,
        source: 'main_game',
        result: 'gave_up',
        xpEarned: 0,
        firstGuess: false,
        practiceMode: _practiceMode,
        clueNumber: _currentSubmissionNumber,
        guesses: _submittedBoards,
        livesRemaining: _lives,
        playTimeSeconds: _playTimeSeconds(),
      ),
    );

    unawaited(
      AnalyticsService.logQuestionCompleted(
        gameKey: 'first_match',
        category: 'first_match',
        subcategory: 'first_match',
        questionId: challenge.id,
        source: 'main_game',
        result: 'gave_up',
        xpEarned: 0,
        firstGuess: false,
        practiceMode: _practiceMode,
        clueNumber: _currentSubmissionNumber,
        guesses: _submittedBoards,
        livesRemaining: _lives,
        playTimeSeconds: _playTimeSeconds(),
      ),
    );

    await _showResultDialog(
      title: 'YOU GAVE UP!',
      message: _practiceMode
          ? 'THE CORRECT MATCHES WERE:\n\n$correctMatches\n\nPRACTICE MODE\n0 XP'
          : 'THE CORRECT MATCHES WERE:\n\n$correctMatches',
    );
  }

  Future<void> _showResultDialog({
    required String title,
    required String message,
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

  Future<void> _showNewAchievementPopups({
    required PlayerStats previous,
    required PlayerStats current,
  }) async {
    final List<EarnedBadge> earnedBadges =
        AchievementService.newlyEarnedBadges(
      previous: previous,
      current: current,
      gameKey: 'first_match',
      gameLabel: 'First Match',
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
      gameCategory: AchievementCategory.firstMatch,
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
    Navigator.of(context, rootNavigator: true).pop();

    if (!mounted) {
      return;
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
      return;
    }

    await _loadRound();
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
                'assets/images/categories/category_headers/first_match_can_you_get_it_right.webp',
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
            : _challenge == null
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
            const SizedBox(height: 18),
            Text(
              _allQuestionsPlayed
                  ? 'ALL FIRST MATCH QUESTIONS PLAYED!'
                  : 'No live First Match questions found.',
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
                  ? 'You have completed every live First Match question. Continue in Practice Mode for 0 XP, or return when new questions are added.'
                  : 'Import the First Match workbook into Firebase, then try again.',
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
    final Size screenSize = MediaQuery.sizeOf(context);
    final bool isDesktop = screenSize.width >= 900;
    final bool compactHeight =
        screenSize.width >= 600 && screenSize.height < 820;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        isDesktop ? 32 : 12,
        compactHeight ? 2 : 6,
        isDesktop ? 32 : 12,
        compactHeight ? 6 : 28,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 880,
          ),
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
              if (_message != null) ...<Widget>[
                SizedBox(height: compactHeight ? 7 : 10),
                GameMessagePanel(
                  message: _message!,
                  type: _messageColor == const Color(0xFFE14B4B)
                      ? GameMessageType.error
                      : GameMessageType.info,
                ),
              ],
              SizedBox(height: compactHeight ? 7 : 14),
              _buildInstructionStrip(),
              SizedBox(height: compactHeight ? 7 : 14),
              _buildBoard(isDesktop: isDesktop),
              SizedBox(height: compactHeight ? 8 : 14),
              Container(
                padding: EdgeInsets.only(
                  top: compactHeight ? 9 : 14,
                ),
                decoration: const BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: Color(0xFF3E3E3E),
                      width: 1,
                    ),
                  ),
                ),
                child: _buildButtons(),
              ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBlock() {
    final int correct = _lockedLeftIndexes.length;

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
                      )
                    : Text(
                        '$_pointsAvailable XP',
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

  Widget _buildInstructionStrip() {
    final bool compactHeight =
        MediaQuery.sizeOf(context).width >= 600 &&
        MediaQuery.sizeOf(context).height < 820;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: 16,
        vertical: _isInstalledPhone(context) ? 7 : (compactHeight ? 8 : 12),
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
        _isInstalledPhone(context)
            ? 'SELECT LEFT, THEN MATCH TO THE RIGHT'
            : 'SELECT A LEFT ITEM, THEN CHOOSE ITS MATCH ON THE RIGHT',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontFamily: 'Oswald',
          color: AppColors.white,
          fontSize: _isInstalledPhone(context) ? 14 : 17,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
          height: 1.1,
        ),
      ),
    );
  }

  Widget _buildBoard({
    required bool isDesktop,
  }) {
    final _FirstMatchChallenge challenge = _challenge!;
    final bool compactHeight =
        MediaQuery.sizeOf(context).width >= 600 &&
        MediaQuery.sizeOf(context).height < 820;
    final double rowGap = compactHeight ? 5 : 8;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          child: Column(
            children: <Widget>[
              const _ColumnHeading('MATCH'),
              SizedBox(height: rowGap),
              for (int i = 0; i < challenge.pairs.length; i++) ...<Widget>[
                _buildLeftTile(i),
                if (i != challenge.pairs.length - 1)
                  SizedBox(height: rowGap),
              ],
            ],
          ),
        ),
        SizedBox(width: isDesktop ? 18 : 8),
        Expanded(
          child: Column(
            children: <Widget>[
              const _ColumnHeading('WITH'),
              const SizedBox(height: 8),
              for (int i = 0; i < _rightChoices.length; i++) ...<Widget>[
                _buildRightTile(i),
                if (i != _rightChoices.length - 1)
                  SizedBox(height: rowGap),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLeftTile(int leftIndex) {
    final _FirstMatchChallenge challenge = _challenge!;
    final bool locked =
        _lockedLeftIndexes.contains(leftIndex);
    final bool selected =
        _selectedLeftIndex == leftIndex;

    final int? colourIndex =
        _pairColourIndexForLeft(leftIndex);

    return _MatchChoiceTile(
      text: challenge.pairs[leftIndex].left,
      locked: locked,
      selected: selected,
      outlineColour: colourIndex == null
          ? const Color(0xFF454545)
          : _pairColours[colourIndex],
      onTap: _roundFinished || locked
          ? null
          : () => _selectLeft(leftIndex),
    );
  }

  Widget _buildRightTile(int rightIndex) {
    final bool locked =
        _lockedRightIndexes.contains(rightIndex);

    final int? colourIndex =
        _pairColourIndexForRight(rightIndex);

    return _MatchChoiceTile(
      text: _rightChoices[rightIndex],
      locked: locked,
      selected: false,
      outlineColour: colourIndex == null
          ? const Color(0xFF454545)
          : _pairColours[colourIndex],
      onTap: _roundFinished || locked
          ? null
          : () => _selectRight(rightIndex),
    );
  }

  Widget _buildButtons() {
    final bool enabled =
        !_roundFinished && _lives > 0;
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
              onPressed:
                  enabled && _allUnlockedLeftMatched
                      ? _submitMatches
                      : null,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.orange,
                foregroundColor: AppColors.white,
                disabledBackgroundColor: AppColors.darkGrey,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  'SUBMIT MATCHES',
                  maxLines: 1,
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

class _ColumnHeading extends StatelessWidget {
  final String text;

  const _ColumnHeading(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: TextAlign.center,
      style: const TextStyle(
        fontFamily: 'Oswald',
        color: AppColors.grey,
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.6,
      ),
    );
  }
}

class _MatchChoiceTile extends StatelessWidget {
  final String text;
  final bool locked;
  final bool selected;
  final Color outlineColour;
  final VoidCallback? onTap;

  const _MatchChoiceTile({
    required this.text,
    required this.locked,
    required this.selected,
    required this.outlineColour,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool compactHeight =
        MediaQuery.sizeOf(context).width >= 600 &&
        MediaQuery.sizeOf(context).height < 820;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          constraints: BoxConstraints(
            minHeight: compactHeight ? 48 : 58,
          ),
          alignment: Alignment.center,
          padding: EdgeInsets.symmetric(
            horizontal: 10,
            vertical: compactHeight ? 6 : 10,
          ),
          decoration: BoxDecoration(
            color: locked
                ? const Color(0xFF102519)
                : selected
                    ? const Color(0xFF25170E)
                    : const Color(0xFF171717),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: outlineColour,
              width: locked || selected ? 2.2 : 1.5,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Flexible(
                child: Text(
                  text.toUpperCase(),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Oswald',
                    color: locked
                        ? const Color(0xFF72E59E)
                        : AppColors.white,
                    fontSize: compactHeight ? 15 : 17,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.15,
                    height: 1.05,
                  ),
                ),
              ),
              if (locked) ...<Widget>[
                const SizedBox(width: 6),
                const Icon(
                  Icons.lock_rounded,
                  size: 16,
                  color: Color(0xFF72E59E),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
