import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../services/player_stats_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/game_dialogs.dart';
import '../../widgets/game_error_screen.dart';
import '../../widgets/app_home_button.dart';
import '../../widgets/timer_bar.dart';

import '../data/planets_daily_flash.dart';
import '../models/daily_flash_question.dart';
import '../services/daily_flash_progress_service.dart';


String _formatDailyFlashNumber(int value) {
  final String digits = value.abs().toString();
  final StringBuffer buffer = StringBuffer();

  for (int i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) {
      buffer.write(',');
    }
    buffer.write(digits[i]);
  }

  return value < 0 ? '-$buffer' : buffer.toString();
}

enum _DailyFlashGuessMatch {
  correct,
  close,
  incorrect,
}

class DailyFlashGameScreen extends StatefulWidget {
  final VoidCallback? onChallengeFinished;

  const DailyFlashGameScreen({
    super.key,
    this.onChallengeFinished,
  });

  @override
  State<DailyFlashGameScreen> createState() =>
      _DailyFlashGameScreenState();
}

class _DailyFlashGameScreenState
    extends State<DailyFlashGameScreen> {
  static const int clueDurationMilliseconds = 14000;
  static const int timerUpdateMilliseconds = 100;
  static const int spellingGraceMilliseconds = 10000;

  static const int maximumLives = 3;
  static const int firstGuessBonus = 50;

  static const String _hideLeaveWarningPreferenceKey =
      'daily_flash_hide_leave_warning_v2';

  static const String _leaveWarningCountPreferenceKey =
      'daily_flash_leave_warning_count_v2';

  static const String heartAsset =
      'assets/images/stats/life_heart.png';

  final TextEditingController guessController =
      TextEditingController();

  final FocusNode guessFocusNode = FocusNode();

  Timer? clueTimer;
  Timer? messageTimer;
  Timer? timeUpOverlayTimer;

  DailyFlashProgress? savedProgress;
  bool loadingProgress = true;

  int questionIndex = 0;
  int clueIndex = 0;

  int millisecondsRemaining =
      clueDurationMilliseconds;

  int lives = maximumLives;

  int closeGuessesThisClue = 0;
  int guessesThisQuestion = 0;

  int totalXp = 0;
  int questionsCorrect = 0;
  int firstGuesses = 0;

  bool questionFinished = false;
  bool challengeFinished = false;
  bool showTimeUpOverlay = false;
  bool hasTechnicalError = false;
  int imageRetryVersion = 0;

  String? gameMessage;

  GameMessageType gameMessageType =
      GameMessageType.info;

  DailyFlashQuestion get currentQuestion =>
      planetsDailyFlashQuestions[questionIndex];

  bool get isLastClue =>
      clueIndex >= currentQuestion.clues.length - 1;

  bool get isLastQuestion =>
      questionIndex >=
      planetsDailyFlashQuestions.length - 1;

  int get baseXp =>
      currentQuestion.baseXpForClue(clueIndex);

  int get doubledBaseXp => baseXp * 2;

  double get timerProgress {
    return (millisecondsRemaining /
            clueDurationMilliseconds)
        .clamp(0.0, 1.0);
  }

  @override
  void initState() {
    super.initState();
    _loadDailyProgress();
  }

  Future<void> _loadDailyProgress() async {
    try {
      if (mounted) {
        setState(() {
          hasTechnicalError = false;
          loadingProgress = true;
        });
      }

      final DailyFlashProgress progress =
          await DailyFlashProgressService.loadToday();

      if (!mounted) {
        return;
      }

      if (progress.allQuestionsAttempted) {
        setState(() {
          savedProgress = progress;
          totalXp = progress.totalXp;
          questionsCorrect = progress.questionsCorrect;
          firstGuesses = progress.firstGuesses;
          loadingProgress = false;
          challengeFinished = true;
          questionFinished = true;
        });

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            showCompletedTodayScreen();
          }
        });
        return;
      }

      setState(() {
        savedProgress = progress;
        questionIndex = progress.nextQuestionIndex;
        totalXp = progress.totalXp;
        questionsCorrect = progress.questionsCorrect;
        firstGuesses = progress.firstGuesses;
        loadingProgress = false;
      });

      await _consumeCurrentQuestion();
    } catch (_) {
      if (!mounted) {
        return;
      }

      clueTimer?.cancel();

      setState(() {
        loadingProgress = false;
        hasTechnicalError = true;
      });
    }
  }

  Future<void> _retryTechnicalError() async {
    setState(() {
      hasTechnicalError = false;
      imageRetryVersion++;
    });

    // If progress has not loaded yet, retry the failed load.
    if (savedProgress == null) {
      await _loadDailyProgress();
      return;
    }

    // Mid-game image/render failure: keep the exact current
    // question/clue and simply rebuild the failed asset.
    startClueTimer(resetTime: false);
  }

  void _showTechnicalError() {
    clueTimer?.cancel();

    if (!mounted) {
      return;
    }

    setState(() {
      hasTechnicalError = true;
    });
  }

  Future<void> _consumeCurrentQuestion() async {
    final DailyFlashProgress? progress = savedProgress;

    if (progress == null || progress.allQuestionsAttempted) {
      return;
    }

    final DailyFlashProgress updated =
        await DailyFlashProgressService.consumeQuestion(
      progress: progress,
      questionIndex: questionIndex,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      savedProgress = updated;
    });

    startClueTimer();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        guessFocusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    clueTimer?.cancel();
    messageTimer?.cancel();
    timeUpOverlayTimer?.cancel();

    guessController.dispose();
    guessFocusNode.dispose();

    super.dispose();
  }

  // =========================================================
  // TIMER
  // =========================================================

  void startClueTimer({
    bool resetTime = true,
  }) {
    clueTimer?.cancel();

    if (!mounted ||
        questionFinished ||
        challengeFinished ||
        loadingProgress) {
      return;
    }

    if (resetTime) {
      setState(() {
        millisecondsRemaining =
            clueDurationMilliseconds;
      });
    }

    clueTimer = Timer.periodic(
      const Duration(
        milliseconds: timerUpdateMilliseconds,
      ),
      (Timer timer) {
        if (!mounted ||
            questionFinished ||
            challengeFinished) {
          timer.cancel();
          return;
        }

        final int newRemainingTime =
            millisecondsRemaining -
            timerUpdateMilliseconds;

        if (newRemainingTime <= 0) {
          timer.cancel();

          setState(() {
            millisecondsRemaining = 0;
          });

          handleTimerExpired();
          return;
        }

        setState(() {
          millisecondsRemaining =
              newRemainingTime;
        });
      },
    );
  }

  Future<void> handleTimerExpired() async {
    if (questionFinished ||
        challengeFinished) {
      return;
    }

    setState(() {
      closeGuessesThisClue = 0;
    });

    if (isLastClue) {
      await finishFailedQuestion();
      return;
    }

    showSmallTimeUpOverlay();

    advanceToNextClue(
      clearGuess: false,
    );
  }

  void showSmallTimeUpOverlay() {
    timeUpOverlayTimer?.cancel();

    if (!mounted) {
      return;
    }

    setState(() {
      showTimeUpOverlay = true;
    });

    timeUpOverlayTimer = Timer(
      const Duration(milliseconds: 1500),
      () {
        if (!mounted) {
          return;
        }

        setState(() {
          showTimeUpOverlay = false;
        });
      },
    );
  }

  // =========================================================
  // GAME MESSAGES
  // =========================================================

  void showGameMessage(
    String message, {
    GameMessageType type = GameMessageType.info,
    Duration duration =
        const Duration(milliseconds: 2200),
  }) {
    messageTimer?.cancel();

    if (!mounted) {
      return;
    }

    setState(() {
      gameMessage = message;
      gameMessageType = type;
    });

    messageTimer = Timer(
      duration,
      () {
        if (!mounted) {
          return;
        }

        setState(() {
          gameMessage = null;
          gameMessageType =
              GameMessageType.info;
        });
      },
    );
  }

  // =========================================================
  // GUESS MATCHING
  // =========================================================

  _DailyFlashGuessMatch checkGuess(
    String guess,
  ) {
    final String typed =
        normalizeAnswer(guess);

    final String answer =
        normalizeAnswer(
      currentQuestion.answer,
    );

    if (typed == answer) {
      return _DailyFlashGuessMatch.correct;
    }

    if (typed.isEmpty) {
      return _DailyFlashGuessMatch.incorrect;
    }

    final String typedForPlural =
        _normalisePluralAnswer(guess);
    final String answerForPlural =
        _normalisePluralAnswer(
      currentQuestion.answer,
    );

    if (_isSingularPluralMatch(
      typedForPlural,
      answerForPlural,
    )) {
      return _DailyFlashGuessMatch.correct;
    }

    final int distance =
        levenshteinDistance(
      typed,
      answer,
    );

    final int longest =
        typed.length > answer.length
            ? typed.length
            : answer.length;

    if (longest <= 5) {
      if (distance <= 1) {
        return _DailyFlashGuessMatch.close;
      }
    } else if (longest <= 9) {
      if (distance <= 2) {
        return _DailyFlashGuessMatch.close;
      }
    } else {
      if (distance <= 3) {
        return _DailyFlashGuessMatch.close;
      }
    }

    return _DailyFlashGuessMatch.incorrect;
  }

  String normalizeAnswer(
    String value,
  ) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll(
          RegExp(r'[^a-z0-9]'),
          '',
        );
  }

  String _normalisePluralAnswer(
    String value,
  ) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll('&', ' and ')
        .replaceAll(
          RegExp(r'[^a-z0-9\s]'),
          '',
        )
        .replaceAll(
          RegExp(r'\s+'),
          ' ',
        )
        .trim();
  }

  bool _isSingularPluralMatch(
    String first,
    String second,
  ) {
    if (first.isEmpty || second.isEmpty || first == second) {
      return false;
    }

    if (_pluralForms(first).contains(second) ||
        _pluralForms(second).contains(first)) {
      return true;
    }

    final String compactFirst =
        first.replaceAll(' ', '');
    final String compactSecond =
        second.replaceAll(' ', '');

    return _pluralForms(compactFirst).contains(compactSecond) ||
        _pluralForms(compactSecond).contains(compactFirst);
  }

  Set<String> _pluralForms(String value) {
    final String normalised = value.trim();

    if (normalised.isEmpty) {
      return <String>{};
    }

    final List<String> words = normalised.split(' ');
    final String finalWord = words.removeLast();

    final Set<String> pluralWords =
        _pluralFormsForWord(finalWord);

    if (words.isEmpty) {
      return pluralWords;
    }

    final String prefix = '${words.join(' ')} ';

    return pluralWords
        .map((String pluralWord) => '$prefix$pluralWord')
        .toSet();
  }

  Set<String> _pluralFormsForWord(String word) {
    const Map<String, List<String>> irregular =
        <String, List<String>>{
      'person': <String>['people'],
      'man': <String>['men'],
      'woman': <String>['women'],
      'child': <String>['children'],
      'mouse': <String>['mice'],
      'goose': <String>['geese'],
      'tooth': <String>['teeth'],
      'foot': <String>['feet'],
      'ox': <String>['oxen'],
      'analysis': <String>['analyses'],
      'diagnosis': <String>['diagnoses'],
      'thesis': <String>['theses'],
      'crisis': <String>['crises'],
      'phenomenon': <String>['phenomena'],
      'criterion': <String>['criteria'],
      'index': <String>['indexes', 'indices'],
      'appendix': <String>['appendixes', 'appendices'],
      'matrix': <String>['matrices', 'matrixes'],
      'vertex': <String>['vertices'],
      'cactus': <String>['cactuses', 'cacti'],
      'fungus': <String>['funguses', 'fungi'],
      'nucleus': <String>['nucleuses', 'nuclei'],
      'syllabus': <String>['syllabuses', 'syllabi'],
      'quiz': <String>['quizzes'],
      'knife': <String>['knives'],
      'life': <String>['lives'],
      'wife': <String>['wives'],
      'leaf': <String>['leaves'],
      'loaf': <String>['loaves'],
      'wolf': <String>['wolves'],
      'shelf': <String>['shelves'],
      'calf': <String>['calves'],
      'half': <String>['halves'],
      'self': <String>['selves'],
      'thief': <String>['thieves'],
      'potato': <String>['potatoes'],
      'tomato': <String>['tomatoes'],
      'hero': <String>['heroes'],
      'echo': <String>['echoes'],
      'fish': <String>['fish', 'fishes'],
      'sheep': <String>['sheep'],
      'deer': <String>['deer'],
      'species': <String>['species'],
      'series': <String>['series'],
      'aircraft': <String>['aircraft'],
      'salmon': <String>['salmon', 'salmons'],
      'trout': <String>['trout', 'trouts'],
    };

    final List<String>? irregularForms = irregular[word];

    if (irregularForms != null) {
      return irregularForms.toSet();
    }

    if (word.length > 1 &&
        word.endsWith('y') &&
        !_isPluralVowel(word[word.length - 2])) {
      return <String>{
        '${word.substring(0, word.length - 1)}ies',
      };
    }

    if (word.endsWith('s') ||
        word.endsWith('x') ||
        word.endsWith('z') ||
        word.endsWith('ch') ||
        word.endsWith('sh')) {
      return <String>{'${word}es'};
    }

    return <String>{'${word}s'};
  }

  bool _isPluralVowel(String character) {
    return 'aeiou'.contains(character);
  }

  int levenshteinDistance(
    String first,
    String second,
  ) {
    if (first == second) {
      return 0;
    }

    if (first.isEmpty) {
      return second.length;
    }

    if (second.isEmpty) {
      return first.length;
    }

    List<int> previous =
        List<int>.generate(
      second.length + 1,
      (int index) => index,
    );

    for (int i = 0;
        i < first.length;
        i++) {
      final List<int> current =
          <int>[i + 1];

      for (int j = 0;
          j < second.length;
          j++) {
        final int insertCost =
            current[j] + 1;

        final int deleteCost =
            previous[j + 1] + 1;

        final int replaceCost =
            previous[j] +
            (first[i] == second[j]
                ? 0
                : 1);

        int result = insertCost;

        if (deleteCost < result) {
          result = deleteCost;
        }

        if (replaceCost < result) {
          result = replaceCost;
        }

        current.add(result);
      }

      previous = current;
    }

    return previous.last;
  }

  // =========================================================
  // SUBMIT GUESS
  // =========================================================

  Future<void> submitGuess() async {
    if (questionFinished ||
        challengeFinished) {
      return;
    }

    final String guess =
        guessController.text.trim();

    if (guess.isEmpty) {
      showGameMessage(
        'Enter an answer before pressing GUESS.',
        type: GameMessageType.info,
      );

      return;
    }

    final _DailyFlashGuessMatch match =
        checkGuess(guess);

    switch (match) {
      case _DailyFlashGuessMatch.correct:
        await handleCorrectGuess();
        return;

      case _DailyFlashGuessMatch.close:
        await handleCloseGuess();
        return;

      case _DailyFlashGuessMatch.incorrect:
        await handleIncorrectGuess();
        return;
    }
  }

  // =========================================================
  // CORRECT
  // =========================================================

  Future<void> handleCorrectGuess() async {
    if (questionFinished ||
        challengeFinished) {
      return;
    }

    clueTimer?.cancel();

    final bool wasFirstGuess =
        clueIndex == 0 &&
        guessesThisQuestion == 0;

    guessesThisQuestion++;

    final int normalScore =
        baseXp +
        (wasFirstGuess
            ? firstGuessBonus
            : 0);

    final int xpEarned =
        normalScore * 2;

    DailyFlashProgress? progress = savedProgress;

    if (progress != null) {
      progress =
          await DailyFlashProgressService.recordCorrectAnswer(
        progress: progress,
        xpEarned: xpEarned,
        wasFirstGuess: wasFirstGuess,
      );
    }

    if (!mounted) {
      return;
    }

    setState(() {
      questionFinished = true;
      closeGuessesThisClue = 0;

      if (progress != null) {
        savedProgress = progress;
        totalXp = progress.totalXp;
        questionsCorrect =
            progress.questionsCorrect;
        firstGuesses =
            progress.firstGuesses;
      } else {
        totalXp += xpEarned;
        questionsCorrect++;

        if (wasFirstGuess) {
          firstGuesses++;
        }
      }
    });

    if (wasFirstGuess) {
      showGameMessage(
        'FIRST GUESS! +$xpEarned XP',
        type: GameMessageType.success,
        duration:
            const Duration(
          milliseconds: 1000,
        ),
      );
    } else {
      showGameMessage(
        'Correct! +$xpEarned XP',
        type: GameMessageType.success,
        duration:
            const Duration(
          milliseconds: 800,
        ),
      );
    }

    await Future<void>.delayed(
      Duration(
        milliseconds:
            wasFirstGuess
                ? 1000
                : 800,
      ),
    );

    if (!mounted ||
        challengeFinished) {
      return;
    }

    if (isLastQuestion) {
      await finishDailyFlash();
      return;
    }

    await moveToNextQuestion();
  }

  // =========================================================
  // CLOSE SPELLING
  // =========================================================

  Future<void> handleCloseGuess() async {
    if (questionFinished ||
        challengeFinished) {
      return;
    }

    final int
        updatedCloseGuessCount =
        closeGuessesThisClue + 1;

    if (updatedCloseGuessCount >= 3) {
      clueTimer?.cancel();

      guessesThisQuestion++;

      setState(() {
        closeGuessesThisClue = 0;
        lives--;
        guessController.clear();
      });

      showGameMessage(
        'Too many spelling attempts! One life lost.',
        type: GameMessageType.error,
        duration:
            const Duration(
          milliseconds: 2200,
        ),
      );

      await Future<void>.delayed(
        const Duration(
          milliseconds: 2200,
        ),
      );

      if (!mounted) {
        return;
      }

      if (lives <= 0 ||
          isLastClue) {
        await finishFailedQuestion();
        return;
      }

      advanceToNextClue();
      return;
    }

    setState(() {
      closeGuessesThisClue =
          updatedCloseGuessCount;

      if (millisecondsRemaining <
          spellingGraceMilliseconds) {
        millisecondsRemaining =
            spellingGraceMilliseconds;
      }
    });

    showGameMessage(
      'So close! Check your spelling.',
      type: GameMessageType.warning,
    );

    WidgetsBinding.instance
        .addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      guessFocusNode.requestFocus();

      guessController.selection =
          TextSelection(
        baseOffset: 0,
        extentOffset:
            guessController.text.length,
      );
    });
  }

  // =========================================================
  // INCORRECT
  // =========================================================

  Future<void> handleIncorrectGuess() async {
    if (questionFinished ||
        challengeFinished) {
      return;
    }

    clueTimer?.cancel();

    guessesThisQuestion++;

    setState(() {
      closeGuessesThisClue = 0;
      lives--;
      guessController.clear();
    });

    if (lives <= 0 ||
        isLastClue) {
      showGameMessage(
        'Incorrect! One life lost.',
        type: GameMessageType.error,
        duration:
            const Duration(
          milliseconds: 700,
        ),
      );

      await Future<void>.delayed(
        const Duration(
          milliseconds: 700,
        ),
      );

      if (!mounted) {
        return;
      }

      await finishFailedQuestion();
      return;
    }

    advanceToNextClue();

    showGameMessage(
      'Incorrect! One life lost.',
      type: GameMessageType.error,
    );
  }

  // =========================================================
  // NEXT CLUE
  // =========================================================

  void advanceToNextClue({
    bool clearGuess = true,
  }) {
    if (questionFinished ||
        challengeFinished ||
        isLastClue) {
      return;
    }

    clueTimer?.cancel();

    setState(() {
      clueIndex++;
      closeGuessesThisClue = 0;

      if (clearGuess) {
        guessController.clear();
      }

      millisecondsRemaining =
          clueDurationMilliseconds;
    });

    startClueTimer();

    WidgetsBinding.instance
        .addPostFrameCallback((_) {
      if (mounted) {
        guessFocusNode.requestFocus();
      }
    });
  }

  Future<void> nextCluePressed() async {
    if (questionFinished ||
        challengeFinished) {
      return;
    }

    if (isLastClue) {
      await finishFailedQuestion();
      return;
    }

    advanceToNextClue();
  }

  // =========================================================
  // GAME OVER FOR CURRENT QUESTION
  // =========================================================

  Future<void> finishFailedQuestion() async {
    if (questionFinished ||
        challengeFinished) {
      return;
    }

    clueTimer?.cancel();
    messageTimer?.cancel();
    timeUpOverlayTimer?.cancel();

    setState(() {
      questionFinished = true;
      showTimeUpOverlay = false;
      gameMessage = null;
    });

    bool continuePressed = false;
    bool leavePressed = false;

    await showGameResultDialog(
      context: context,
      title: 'GAME OVER',
      message:
          'The answer was ${currentQuestion.answer}.',
      icon: Icons.close_rounded,
      primaryButtonLabel:
          isLastQuestion
              ? 'SEE RESULTS'
              : 'NEXT QUESTION',
      secondaryButtonLabel:
          'LEAVE FLASH 5',
      onPlayAgain: () {
        continuePressed = true;

        Navigator.of(context).pop();
      },
      onHome: () {
        leavePressed = true;

        Navigator.of(context).pop();
      },
    );

    if (!mounted) {
      return;
    }

    if (leavePressed) {
      leaveFlash5();
      return;
    }

    if (!continuePressed) {
      return;
    }

    if (isLastQuestion) {
      await finishDailyFlash();
      return;
    }

    await moveToNextQuestion();
  }

  // =========================================================
  // NEXT QUESTION
  // =========================================================

  Future<void> moveToNextQuestion() async {
    clueTimer?.cancel();
    messageTimer?.cancel();
    timeUpOverlayTimer?.cancel();

    if (isLastQuestion) {
      await finishDailyFlash();
      return;
    }

    setState(() {
      questionIndex++;
      clueIndex = 0;

      lives = maximumLives;

      millisecondsRemaining =
          clueDurationMilliseconds;

      closeGuessesThisClue = 0;
      guessesThisQuestion = 0;

      questionFinished = false;
      showTimeUpOverlay = false;

      gameMessage = null;

      gameMessageType =
          GameMessageType.info;

      guessController.clear();
    });

    await _consumeCurrentQuestion();
  }

  // =========================================================
  // LEAVE FLASH 5
  // =========================================================

  void leaveFlash5() {
    clueTimer?.cancel();
    messageTimer?.cancel();
    timeUpOverlayTimer?.cancel();

    Navigator.of(context).popUntil(
      (Route<dynamic> route) =>
          route.isFirst,
    );
  }

  // =========================================================
  // DAILY FLASH RESULTS
  // =========================================================

  Future<void> finishDailyFlash() async {
    if (challengeFinished) return;

    clueTimer?.cancel();
    messageTimer?.cancel();
    timeUpOverlayTimer?.cancel();

    setState(() {
      challengeFinished = true;
      questionFinished = true;
      millisecondsRemaining = 0;
      showTimeUpOverlay = false;
      gameMessage = null;
    });

    final bool perfect = questionsCorrect == 5;

    // Count this Daily Flash once and only show a milestone
    // when the new lifetime total reaches a real milestone target.
    // A perfect 5 is also stored as a lifetime stat.
    final DailyFlashMilestone? milestone =
        await DailyFlashMilestoneService
            .recordCompletionAndAwardIfEarned(
      perfect: perfect,
    );

    // Milestone bonus XP is added to the player's stored XP.
    if (milestone != null && milestone.bonusXp > 0) {
      await PlayerStatsService.addBonusXp(
        xp: milestone.bonusXp,
      );
    }

    if (!mounted) return;

    // totalXp already includes the Daily Flash 2x multiplier.
    final int xpBeforeBonus = totalXp ~/ 2;
    final int bonusXp = totalXp - xpBeforeBonus;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return _DailyFlashResultsDialog(
          perfect: perfect,
          score: questionsCorrect,
          baseXp: xpBeforeBonus,
          bonusXp: bonusXp,
          totalXp: totalXp,
          hasMilestone: milestone != null,
          onContinue: () {
            Navigator.of(dialogContext).pop();
          },
        );
      },
    );

    if (!mounted) return;

    // Milestone celebration appears AFTER the results screen.
    if (milestone != null) {
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext dialogContext) {
          return _DailyFlashMilestoneDialog(
            milestone: milestone,
            onContinue: () {
              Navigator.of(dialogContext).pop();
            },
          );
        },
      );
    }

    if (!mounted) return;

    widget.onChallengeFinished?.call();
    leaveFlash5();
  }

  Future<void> goBack() async {
    if (challengeFinished) {
      leaveFlash5();
      return;
    }

    clueTimer?.cancel();

    final SharedPreferences preferences =
        await SharedPreferences.getInstance();

    if (!mounted) {
      return;
    }

    final bool hideLeaveWarning =
        preferences.getBool(_hideLeaveWarningPreferenceKey) ?? false;

    if (hideLeaveWarning) {
      leaveFlash5();
      return;
    }

    final int warningCount =
        preferences.getInt(_leaveWarningCountPreferenceKey) ?? 0;

    final bool showDontShowAgain = warningCount >= 1;

    await preferences.setInt(
      _leaveWarningCountPreferenceKey,
      warningCount + 1,
    );

    if (!mounted) {
      return;
    }

    final bool? leave =
        await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.panel,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
            side: const BorderSide(
              color: AppColors.orange,
              width: 2,
            ),
          ),
          icon: SizedBox(
            width: 96,
            height: 96,
            child: Image.asset(
              'assets/images/ui/popups/warning.webp',
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
            ),
          ),
          title: const Text(
            'LEAVE DAILY FLASH 5?',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Oswald',
              color: AppColors.orange,
              fontSize: 24,
              fontWeight: FontWeight.w500,
            ),
          ),
          content: Text(
            'Leaving now will forfeit Question ${questionIndex + 1}.\n\n'
            'You can continue with the next question later today, '
            'but you cannot replay this one.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Inter',
              color: AppColors.white,
              fontSize: 15,
              height: 1.5,
            ),
          ),
          actionsPadding:
              const EdgeInsets.fromLTRB(24, 0, 24, 22),
          actions: [
            SizedBox(
              width: double.infinity,
              child: Column(
                children: [
                  SizedBox(
                    width: 230,
                    height: 50,
                    child: FilledButton(
                      onPressed: () {
                        Navigator.of(dialogContext).pop(false);
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.orange,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text(
                        'KEEP PLAYING',
                        style: TextStyle(
                          fontFamily: 'Oswald',
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: 230,
                    height: 48,
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.of(dialogContext).pop(true);
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(
                          color: AppColors.orange,
                        ),
                      ),
                      child: const Text(
                        'LEAVE & FORFEIT QUESTION',
                        style: TextStyle(
                          fontFamily: 'Oswald',
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                  if (showDontShowAgain) ...[
                    const SizedBox(height: 6),
                    TextButton(
                      onPressed: () async {
                        final SharedPreferences preferences =
                            await SharedPreferences.getInstance();

                        await preferences.setBool(
                          _hideLeaveWarningPreferenceKey,
                          true,
                        );

                        if (!dialogContext.mounted) {
                          return;
                        }

                        Navigator.of(dialogContext).pop(false);
                      },
                      child: const Text(
                        "I UNDERSTAND, DON'T SHOW AGAIN",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          color: AppColors.white,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          decoration: TextDecoration.underline,
                          decorationColor: AppColors.white,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        );
      },
    );

    if (!mounted) {
      return;
    }

    if (leave == true) {
      leaveFlash5();
      return;
    }

    startClueTimer(resetTime: false);
  }

  Future<void> showCompletedTodayScreen() async {
    if (!mounted) {
      return;
    }

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.panel,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
            side: const BorderSide(
              color: AppColors.orange,
              width: 2,
            ),
          ),
          icon: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'DAILY FLASH 5',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Oswald',
                  color: AppColors.orange,
                  fontSize: 29,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 12),
              Image.asset(
                'assets/images/stats/correct.png',
                width: 96,
                height: 96,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.high,
              ),
            ],
          ),
          title: const Text(
            'TODAY’S FLASH COMPLETE',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Oswald',
              color: AppColors.white,
              fontSize: 22,
              fontWeight: FontWeight.w500,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$questionsCorrect / 5 CORRECT',
                style: const TextStyle(
                  fontFamily: 'Oswald',
                  color: AppColors.white,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '$firstGuesses FIRST GUESSES',
                style: const TextStyle(
                  fontFamily: 'Oswald',
                  color: AppColors.white,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'TOTAL XP',
                style: TextStyle(
                  fontFamily: 'Oswald',
                  color: AppColors.white,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${_formatDailyFlashNumber(totalXp)} XP',
                style: const TextStyle(
                  fontFamily: 'Oswald',
                  color: AppColors.orange,
                  fontSize: 34,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Come back tomorrow for a new Daily Flash 5.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Inter',
                  color: AppColors.white,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          actionsPadding:
              const EdgeInsets.fromLTRB(24, 0, 24, 22),
          actions: [
            SizedBox(
              width: double.infinity,
              child: Center(
                child: SizedBox(
                  width: 220,
                  height: 50,
                  child: FilledButton(
                    onPressed: () {
                      Navigator.of(dialogContext).pop();
                      leaveFlash5();
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.orange,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text(
                      'BACK TO HOME',
                      style: TextStyle(
                        fontFamily: 'Oswald',
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // =========================================================
  // SCREEN
  // =========================================================

  @override
  Widget build(BuildContext context) {
    if (hasTechnicalError) {
      return GameErrorScreen(
        message: 'We couldn’t load this challenge.',
        onTryAgain: _retryTechnicalError,
        onBackToHome: leaveFlash5,
      );
    }

    if (loadingProgress) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(
            color: AppColors.orange,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor:
          AppColors.background,
      body: SafeArea(
        child: Stack(
          children: [
            LayoutBuilder(
              builder: (
                BuildContext context,
                BoxConstraints constraints,
              ) {
                final bool isSmall =
                    constraints.maxHeight <
                            720 ||
                        constraints.maxWidth <
                            370;

                return SingleChildScrollView(
                  padding:
                      EdgeInsets.fromLTRB(
                    isSmall ? 9 : 12,
                    isSmall ? 5 : 8,
                    isSmall ? 9 : 12,
                    isSmall ? 10 : 14,
                  ),
                  child: Column(
                    children: [
                      _DailyFlashHeader(
                        isSmall: isSmall,
                        onBack: goBack,
                        onHome: goBack,
                      ),

                      SizedBox(
                        height:
                            isSmall ? 5 : 8,
                      ),

                      _TopicBadge(
                        isSmall: isSmall,
                      ),

                      if (gameMessage !=
                          null) ...[
                        SizedBox(
                          height:
                              isSmall
                                  ? 7
                                  : 9,
                        ),
                        GameMessagePanel(
                          message:
                              gameMessage!,
                          type:
                              gameMessageType,
                        ),
                      ],

                      SizedBox(
                        height:
                            isSmall
                                ? 8
                                : 11,
                      ),

                      _GameStatusPanel(
                        questionNumber:
                            questionIndex +
                                1,
                        clueNumber:
                            clueIndex + 1,
                        clueTotal:
                            currentQuestion
                                .clues.length,
                        lives: lives,
                        baseXp: baseXp,
                        showFirstGuessBonus:
                            clueIndex == 0 &&
                            guessesThisQuestion == 0,
                        timerProgress:
                            timerProgress,
                        isSmall:
                            isSmall,
                      ),

                      SizedBox(
                        height:
                            isSmall
                                ? 7
                                : 10,
                      ),

                      _CluePanel(
                        clue:
                            currentQuestion
                                .clues[
                                    clueIndex],
                        isSmall:
                            isSmall,
                      ),

                      SizedBox(
                        height:
                            isSmall
                                ? 7
                                : 10,
                      ),

                      _PlanetImagePanel(
                        key:
                            ValueKey<
                                String>(
                          currentQuestion
                              .answer,
                        ),
                        imagePath:
                            currentQuestion
                                .imagePath,
                        retryVersion:
                            imageRetryVersion,
                        onImageError:
                            _showTechnicalError,
                        isSmall:
                            isSmall,
                      ),

                      SizedBox(
                        height:
                            isSmall
                                ? 7
                                : 10,
                      ),

                      _GuessField(
                        controller:
                            guessController,
                        focusNode:
                            guessFocusNode,
                        enabled:
                            !questionFinished &&
                                !challengeFinished,
                        onSubmitted: (_) {
                          submitGuess();
                        },
                      ),

                      SizedBox(
                        height:
                            isSmall
                                ? 7
                                : 10,
                      ),

                      Row(
                        children: [
                          Expanded(
                            child:
                                _GuessButton(
                              onPressed:
                                  questionFinished ||
                                          challengeFinished
                                      ? null
                                      : submitGuess,
                              isSmall:
                                  isSmall,
                            ),
                          ),
                          const SizedBox(
                            width: 9,
                          ),
                          Expanded(
                            child:
                                _NextClueButton(
                              onPressed:
                                  questionFinished ||
                                          challengeFinished
                                      ? null
                                      : nextCluePressed,
                              isSmall:
                                  isSmall,
                            ),
                          ),
                        ],
                      ),

                      SizedBox(
                        height:
                            isSmall
                                ? 7
                                : 10,
                      ),

                      _GiveUpButton(
                        onPressed:
                            questionFinished ||
                                    challengeFinished
                                ? null
                                : finishFailedQuestion,
                        isSmall:
                            isSmall,
                      ),
                    ],
                  ),
                );
              },
            ),

            if (showTimeUpOverlay)
              Positioned.fill(
                child: IgnorePointer(
                  child: Container(
                    color:
                        Colors.black
                            .withValues(
                      alpha: 0.30,
                    ),
                    alignment:
                        Alignment.center,
                    child: const
                        SmallTimeUpOverlay(),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ===========================================================
// HEADER
// ===========================================================

class _DailyFlashHeader
    extends StatelessWidget {
  final bool isSmall;
  final VoidCallback onBack;
  final VoidCallback onHome;

  const _DailyFlashHeader({
    required this.isSmall,
    required this.onBack,
    required this.onHome,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: isSmall ? 53 : 62,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment:
                Alignment.centerLeft,
            child: IconButton(
              onPressed: onBack,
              padding: EdgeInsets.zero,
              visualDensity:
                  VisualDensity.compact,
              icon: Icon(
                Icons
                    .arrow_back_rounded,
                color:
                    AppColors.white,
                size:
                    isSmall
                        ? 28
                        : 32,
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
            mainAxisSize:
                MainAxisSize.min,
            children: [
              Icon(
                Icons.bolt_rounded,
                color:
                    AppColors.orange,
                size:
                    isSmall
                        ? 28
                        : 34,
              ),
              const SizedBox(
                width: 5,
              ),
              Text(
                'DAILY FLASH 5',
                maxLines: 1,
                style:
                    AppTextStyles
                        .category
                        .copyWith(
                  color:
                      AppColors.white,
                  fontSize:
                      isSmall
                          ? 25
                          : 30,
                  fontWeight:
                      FontWeight.w700,
                  letterSpacing:
                      0.55,
                  height: 1,
                ),
              ),
              const SizedBox(
                width: 5,
              ),
              Icon(
                Icons.bolt_rounded,
                color:
                    AppColors.orange,
                size:
                    isSmall
                        ? 28
                        : 34,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ===========================================================
// TOPIC
// ===========================================================

class _TopicBadge
    extends StatelessWidget {
  final bool isSmall;

  const _TopicBadge({
    required this.isSmall,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          EdgeInsets.symmetric(
        horizontal:
            isSmall ? 15 : 19,
        vertical:
            isSmall ? 6 : 8,
      ),
      decoration: BoxDecoration(
        color: AppColors.panel,
        borderRadius:
            BorderRadius.circular(
          20,
        ),
        border: Border.all(
          color: AppColors.orange,
          width: 1.2,
        ),
      ),
      child: Row(
        mainAxisSize:
            MainAxisSize.min,
        children: [
          Text(
            '🪐',
            style: TextStyle(
              fontSize:
                  isSmall
                      ? 18
                      : 21,
            ),
          ),
          const SizedBox(
            width: 7,
          ),
          Text(
            'TOPIC: ',
            style:
                AppTextStyles
                    .category
                    .copyWith(
              color:
                  AppColors.white,
              fontSize:
                  isSmall
                      ? 18
                      : 21,
              fontWeight:
                  FontWeight.w600,
            ),
          ),
          Text(
            'PLANETS',
            style:
                AppTextStyles
                    .category
                    .copyWith(
              color:
                  AppColors.orange,
              fontSize:
                  isSmall
                      ? 18
                      : 21,
              fontWeight:
                  FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ===========================================================
// STATUS PANEL
// ===========================================================

class _GameStatusPanel
    extends StatelessWidget {
  final int questionNumber;
  final int clueNumber;
  final int clueTotal;
  final int lives;
  final int baseXp;
  final bool showFirstGuessBonus;
  final double timerProgress;
  final bool isSmall;

  const _GameStatusPanel({
    required this.questionNumber,
    required this.clueNumber,
    required this.clueTotal,
    required this.lives,
    required this.baseXp,
    required this.showFirstGuessBonus,
    required this.timerProgress,
    required this.isSmall,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding:
          EdgeInsets.fromLTRB(
        isSmall ? 11 : 14,
        isSmall ? 9 : 11,
        isSmall ? 11 : 14,
        isSmall ? 9 : 11,
      ),
      decoration: BoxDecoration(
        color: AppColors.panel,
        borderRadius:
            BorderRadius.circular(
          18,
        ),
        border: Border.all(
          color: AppColors.border,
          width: 1.2,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              RichText(
                text: TextSpan(
                  style:
                      AppTextStyles
                          .category
                          .copyWith(
                    fontSize:
                        isSmall
                            ? 19
                            : 21,
                    fontWeight:
                        FontWeight
                            .w700,
                  ),
                  children: [
                    const TextSpan(
                      text:
                          'QUESTION ',
                      style:
                          TextStyle(
                        color:
                            AppColors
                                .white,
                      ),
                    ),
                    TextSpan(
                      text:
                          '$questionNumber',
                      style:
                          const TextStyle(
                        color:
                            AppColors
                                .orange,
                      ),
                    ),
                    const TextSpan(
                      text:
                          ' OF 5',
                      style:
                          TextStyle(
                        color:
                            AppColors
                                .white,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              _GlossyLives(
                lives: lives,
                isSmall:
                    isSmall,
              ),
            ],
          ),

          SizedBox(
            height:
                isSmall ? 5 : 7,
          ),

          Row(
            children: [
              Text(
                'CLUE $clueNumber OF $clueTotal',
                style:
                    AppTextStyles
                        .category
                        .copyWith(
                  color:
                      AppColors.white,
                  fontSize:
                      isSmall
                          ? 14
                          : 16,
                  fontWeight:
                      FontWeight
                          .w600,
                ),
              ),

              const Spacer(),

              RichText(
                text: TextSpan(
                  style:
                      AppTextStyles
                          .category
                          .copyWith(
                    fontSize:
                        isSmall
                            ? 15
                            : 17,
                    fontWeight:
                        FontWeight
                            .w600,
                  ),
                  children: [
                    TextSpan(
                      text:
                          '$baseXp XP',
                      style:
                          const TextStyle(
                        color:
                            AppColors
                                .white,
                      ),
                    ),
                    if (showFirstGuessBonus)
                      const TextSpan(
                        text: ' +50',
                        style: TextStyle(
                          color: AppColors.orange,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),

          SizedBox(
            height:
                isSmall ? 6 : 8,
          ),

          TimerBar(
            progress:
                timerProgress,
          ),
        ],
      ),
    );
  }
}

// ===========================================================
// LIVES
// ===========================================================

class _GlossyLives
    extends StatelessWidget {
  final int lives;
  final bool isSmall;

  const _GlossyLives({
    required this.lives,
    required this.isSmall,
  });

  @override
  Widget build(BuildContext context) {
    final double size =
        isSmall ? 27 : 31;

    return Row(
      mainAxisSize:
          MainAxisSize.min,
      children:
          List<Widget>.generate(
        3,
        (int index) {
          return Padding(
            padding:
                const EdgeInsets
                    .symmetric(
              horizontal: 2,
            ),
            child: Opacity(
              opacity:
                  index < lives
                      ? 1.0
                      : 0.25,
              child: Image.asset(
                _DailyFlashGameScreenState
                    .heartAsset,
                width: size,
                height: size,
                fit:
                    BoxFit.contain,
                filterQuality:
                    FilterQuality
                        .high,
              ),
            ),
          );
        },
      ),
    );
  }
}

// ===========================================================
// CLUE
// ===========================================================

class _CluePanel
    extends StatelessWidget {
  final String clue;
  final bool isSmall;

  const _CluePanel({
    required this.clue,
    required this.isSmall,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints:
          BoxConstraints(
        minHeight:
            isSmall ? 54 : 61,
      ),
      padding:
          EdgeInsets.symmetric(
        horizontal:
            isSmall ? 12 : 15,
        vertical:
            isSmall ? 9 : 11,
      ),
      alignment:
          Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.panel,
        borderRadius:
            BorderRadius.circular(
          16,
        ),
        border: Border.all(
          color: AppColors.border,
          width: 1.1,
        ),
      ),
      child: Text(
        clue,
        textAlign:
            TextAlign.center,
        style:
            AppTextStyles.body
                .copyWith(
          color: AppColors.white,
          fontSize:
              isSmall
                  ? 14
                  : 16,
          fontWeight:
              FontWeight.w500,
          height: 1.2,
        ),
      ),
    );
  }
}

// ===========================================================
// PLANET IMAGE
// ===========================================================

class _PlanetImagePanel
    extends StatelessWidget {
  final String imagePath;
  final int retryVersion;
  final VoidCallback onImageError;
  final bool isSmall;

  const _PlanetImagePanel({
    super.key,
    required this.imagePath,
    required this.retryVersion,
    required this.onImageError,
    required this.isSmall,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height:
          isSmall ? 270 : 320,
      width: double.infinity,
      padding:
          EdgeInsets.all(
        isSmall ? 16 : 20,
      ),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius:
            BorderRadius.circular(
          18,
        ),
        border: Border.all(
          color: AppColors.orange,
          width: 1.3,
        ),
      ),
      child: Image.asset(
        imagePath,
        key: ValueKey<String>(
          '$imagePath-$retryVersion',
        ),
        gaplessPlayback: true,
        fit: BoxFit.contain,
        filterQuality:
            FilterQuality.high,
        errorBuilder: (
          BuildContext context,
          Object error,
          StackTrace? stackTrace,
        ) {
          WidgetsBinding.instance
              .addPostFrameCallback((_) {
            onImageError();
          });

          return const SizedBox.shrink();
        },
      ),
    );
  }
}

// ===========================================================
// GUESS FIELD
// ===========================================================

class _GuessField
    extends StatelessWidget {
  final TextEditingController
      controller;

  final FocusNode focusNode;
  final bool enabled;

  final ValueChanged<String>
      onSubmitted;

  const _GuessField({
    required this.controller,
    required this.focusNode,
    required this.enabled,
    required this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      enabled: enabled,
      onSubmitted: onSubmitted,
      textCapitalization:
          TextCapitalization.words,
      textInputAction:
          TextInputAction.done,
      style: const TextStyle(
        fontFamily: 'Inter',
        color: AppColors.white,
        fontSize: 17,
      ),
      decoration:
          const InputDecoration(
        hintText:
            'Type your guess...',
        hintStyle: TextStyle(
          fontFamily: 'Inter',
          color: AppColors.white,
          fontSize: 17,
        ),
        filled: true,
        fillColor:
            AppColors.panel,
        contentPadding:
            EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 15,
        ),
        enabledBorder:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.all(
            Radius.circular(16),
          ),
          borderSide:
              BorderSide(
            color:
                AppColors.orange,
          ),
        ),
        focusedBorder:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.all(
            Radius.circular(16),
          ),
          borderSide:
              BorderSide(
            color:
                AppColors.orange,
            width: 2,
          ),
        ),
        disabledBorder:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.all(
            Radius.circular(16),
          ),
          borderSide:
              BorderSide(
            color:
                AppColors.darkGrey,
          ),
        ),
      ),
    );
  }
}

// ===========================================================
// GUESS BUTTON
// ===========================================================

class _GuessButton
    extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool isSmall;

  const _GuessButton({
    required this.onPressed,
    required this.isSmall,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height:
          isSmall ? 47 : 52,
      child: FilledButton(
        onPressed: onPressed,
        style:
            FilledButton
                .styleFrom(
          backgroundColor:
              AppColors.orange,
          foregroundColor:
              AppColors.white,
          disabledBackgroundColor:
              AppColors.darkGrey,
          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius
                    .circular(
              14,
            ),
          ),
        ),
        child: Text(
          'GUESS',
          style:
              AppTextStyles
                  .category
                  .copyWith(
            color:
                AppColors.white,
            fontSize:
                isSmall
                    ? 16
                    : 18,
            fontWeight:
                FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

// ===========================================================
// NEXT CLUE
// ===========================================================

class _NextClueButton
    extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool isSmall;

  const _NextClueButton({
    required this.onPressed,
    required this.isSmall,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height:
          isSmall ? 47 : 52,
      child: OutlinedButton(
        onPressed: onPressed,
        style:
            OutlinedButton
                .styleFrom(
          foregroundColor:
              AppColors.orange,
          disabledForegroundColor:
              AppColors.darkGrey,
          side: BorderSide(
            color:
                onPressed != null
                    ? AppColors
                        .orange
                    : AppColors
                        .darkGrey,
            width: 1.5,
          ),
          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius
                    .circular(
              14,
            ),
          ),
        ),
        child: Text(
          'NEXT CLUE',
          style:
              AppTextStyles
                  .category
                  .copyWith(
            color:
                onPressed != null
                    ? AppColors
                        .orange
                    : AppColors
                        .darkGrey,
            fontSize:
                isSmall
                    ? 15
                    : 17,
            fontWeight:
                FontWeight.w600,
          ),
        ),
      ),
    );
  }
}


// ===========================================================
// GIVE UP BUTTON
// ===========================================================

class _GiveUpButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool isSmall;

  const _GiveUpButton({
    required this.onPressed,
    required this.isSmall,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: isSmall ? 47 : 52,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFFBA3A34),
          foregroundColor: AppColors.white,
          disabledBackgroundColor: const Color(0xFFBA3A34),
          disabledForegroundColor: AppColors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Text(
          'GIVE UP',
          style: AppTextStyles.category.copyWith(
            color: AppColors.white,
            fontSize: isSmall ? 16 : 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _DailyFlashResultsDialog extends StatefulWidget {
  final bool perfect;
  final int score;
  final int baseXp;
  final int bonusXp;
  final int totalXp;
  final bool hasMilestone;
  final VoidCallback onContinue;

  const _DailyFlashResultsDialog({
    required this.perfect,
    required this.score,
    required this.baseXp,
    required this.bonusXp,
    required this.totalXp,
    required this.hasMilestone,
    required this.onContinue,
  });

  @override
  State<_DailyFlashResultsDialog> createState() =>
      _DailyFlashResultsDialogState();
}

class _DailyFlashResultsDialogState
    extends State<_DailyFlashResultsDialog> {
  Timer? _countdownTimer;
  Duration _remaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    _updateCountdown();
    _countdownTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _updateCountdown(),
    );
  }

  void _updateCountdown() {
    final DateTime now = DateTime.now();
    final DateTime tomorrow = DateTime(
      now.year,
      now.month,
      now.day + 1,
    );
    if (mounted) {
      setState(() => _remaining = tomorrow.difference(now));
    }
  }

  String _two(int value) => value.toString().padLeft(2, '0');

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final int hours = _remaining.inHours;
    final int minutes = _remaining.inMinutes.remainder(60);
    final int seconds = _remaining.inSeconds.remainder(60);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 430),
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
          decoration: BoxDecoration(
            color: AppColors.panel,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.orange, width: 2),
            boxShadow: [
              BoxShadow(
                color: AppColors.orange.withValues(alpha: 0.22),
                blurRadius: 22,
                spreadRadius: 2,
              ),
            ],
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 96,
                  height: 96,
                  child: Image.asset(
                    'assets/images/ui/popups/daily_flash.webp',
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.high,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.orange,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'DAILY FLASH 5',
                    style: TextStyle(
                      fontFamily: 'Oswald',
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  widget.perfect ? 'PERFECT!' : 'FLASH COMPLETE!',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'Oswald',
                    color: Colors.white,
                    fontSize: 34,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 2),
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(text: '${widget.score}'),
                      const TextSpan(
                        text: ' / ',
                        style: TextStyle(color: AppColors.orange),
                      ),
                      const TextSpan(text: '5'),
                    ],
                  ),
                  style: const TextStyle(
                    fontFamily: 'Oswald',
                    color: Colors.white,
                    fontSize: 42,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Column(
                    children: [
                      _DailyFlashXpRow(
                        icon: Icons.star_rounded,
                        label: 'XP EARNED',
                        value: '${_formatDailyFlashNumber(widget.baseXp)} XP',
                      ),
                      const Divider(color: Colors.white24, height: 18),
                      _DailyFlashXpRow(
                        badge: '2×',
                        label: 'DAILY FLASH BONUS',
                        value: '+${_formatDailyFlashNumber(widget.bonusXp)} XP',
                        highlight: true,
                      ),
                      const Divider(color: Colors.white24, height: 18),
                      _DailyFlashXpRow(
                        icon: Icons.emoji_events_rounded,
                        label: 'TOTAL XP EARNED',
                        value: '${_formatDailyFlashNumber(widget.totalXp)} XP',
                        highlight: true,
                        large: true,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'NEXT DAILY FLASH 5 IN',
                  style: TextStyle(
                    fontFamily: 'Oswald',
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.7,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '${_two(hours)} : ${_two(minutes)} : ${_two(seconds)}',
                  style: const TextStyle(
                    fontFamily: 'Oswald',
                    color: AppColors.orange,
                    fontSize: 31,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.5,
                  ),
                ),
                const Text(
                  'HRS          MINS          SECS',
                  style: TextStyle(
                    fontFamily: 'Oswald',
                    color: Colors.white54,
                    fontSize: 10,
                    letterSpacing: 0.7,
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton.icon(
                    onPressed: widget.onContinue,
                    icon: Icon(
                      widget.hasMilestone
                          ? Icons.arrow_forward_rounded
                          : Icons.home_rounded,
                    ),
                    label: Text(
                      widget.hasMilestone
                          ? 'CONTINUE'
                          : 'BACK TO HOME',
                      style: const TextStyle(
                        fontFamily: 'Oswald',
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.6,
                      ),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.orange,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


class _DailyFlashMilestoneDialog extends StatelessWidget {
  final DailyFlashMilestone milestone;
  final VoidCallback onContinue;

  const _DailyFlashMilestoneDialog({
    required this.milestone,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    final int completed = milestone.completions;
    final int? nextTarget = milestone.nextTarget;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 18,
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 430,
        ),
        child: Container(
          padding: const EdgeInsets.fromLTRB(
            20,
            18,
            20,
            20,
          ),
          decoration: BoxDecoration(
            color: AppColors.panel,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: AppColors.orange,
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.orange.withValues(
                  alpha: 0.22,
                ),
                blurRadius: 22,
                spreadRadius: 2,
              ),
            ],
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.orange,
                      width: 2,
                    ),
                  ),
                  child: const Icon(
                    Icons.bolt_rounded,
                    color: AppColors.orange,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'MILESTONE REACHED!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Oswald',
                    color: AppColors.orange,
                    fontSize: 28,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  width: 190,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(
                      alpha: 0.24,
                    ),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: AppColors.orange,
                      width: 2,
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '$completed',
                        style: const TextStyle(
                          fontFamily: 'Oswald',
                          color: AppColors.orange,
                          fontSize: 62,
                          height: 0.95,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'DAILY FLASH 5s\nCOMPLETED',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Oswald',
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          height: 1.15,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'INCREDIBLE DEDICATION!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Oswald',
                    color: AppColors.orange,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'You’ve completed $completed Daily Flash 5 challenges.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    color: Colors.white,
                    fontSize: 14,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 16),
                _DailyFlashMilestoneInfoCard(
                  icon: Icons.workspace_premium_rounded,
                  title: 'MILESTONE BONUS',
                  value: '+${_formatDailyFlashNumber(milestone.bonusXp)} XP',
                ),
                const SizedBox(height: 10),
                _DailyFlashMilestoneInfoCard(
                  icon: Icons.track_changes_rounded,
                  title: 'NEXT TARGET',
                  value: nextTarget == null
                      ? 'MAX MILESTONE'
                      : '$nextTarget DAILY FLASH 5s COMPLETED',
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton.icon(
                    onPressed: onContinue,
                    icon: const Icon(
                      Icons.home_rounded,
                    ),
                    label: const Text(
                      'BACK TO HOME',
                      style: TextStyle(
                        fontFamily: 'Oswald',
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.6,
                      ),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor:
                          AppColors.orange,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DailyFlashMilestoneInfoCard
    extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _DailyFlashMilestoneInfoCard({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: Colors.black.withValues(
          alpha: 0.18,
        ),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: Colors.white24,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.orange,
                width: 1.5,
              ),
            ),
            child: Icon(
              icon,
              color: AppColors.orange,
              size: 27,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Oswald',
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontFamily: 'Oswald',
                    color: AppColors.orange,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DailyFlashXpRow extends StatelessWidget {
  final IconData? icon;
  final String? badge;
  final String label;
  final String value;
  final bool highlight;
  final bool large;

  const _DailyFlashXpRow({
    this.icon,
    this.badge,
    required this.label,
    required this.value,
    this.highlight = false,
    this.large = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 38,
          child: badge != null
              ? Container(
                  width: 34,
                  height: 34,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.orange, width: 2),
                  ),
                  child: Text(
                    badge!,
                    style: const TextStyle(
                      fontFamily: 'Oswald',
                      color: AppColors.orange,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                )
              : Icon(icon, color: AppColors.orange, size: 30),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontFamily: 'Oswald',
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'Oswald',
            color: highlight ? AppColors.orange : Colors.white,
            fontSize: large ? 22 : 17,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
