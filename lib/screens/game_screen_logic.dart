// ignore_for_file: invalid_use_of_protected_member

part of 'game_screen.dart';

extension _GameScreenLogic on _GameScreenState {
  static final Map<_GameScreenState, Set<String>>
      _practiceCyclePlayedIds =
      <_GameScreenState, Set<String>>{};

  Set<String> get _practiceCycleIds =>
      _practiceCyclePlayedIds.putIfAbsent(
        this,
        () => <String>{},
      );

  Future<void> loadPlayerStats() async {
    final PlayerStats savedStats =
        await PlayerStatsService.loadStats();

    if (!mounted) {
      return;
    }

    setState(() {
      playerStats = savedStats;
      statsLoaded = true;
    });
  }

  QuizItem chooseRandomItem({
    QuizItem? excluding,
  }) {
    if (widget.items.isEmpty) {
      throw StateError(
        'This game category does not contain any quiz items.',
      );
    }

    if (widget.items.length == 1) {
      return widget.items.first;
    }

    QuizItem selectedItem;

    do {
      selectedItem = widget.items[
          random.nextInt(widget.items.length)];
    } while (
        excluding != null &&
        selectedItem.answer == excluding.answer);

    return selectedItem;
  }

  String get categoryLabel {
    switch (widget.gameType) {
      case QuizGameType.countries:
      case QuizGameType.flags:
      case QuizGameType.capitalCities:
      case QuizGameType.countrySilhouettes:
      case QuizGameType.currencies:
      case QuizGameType.majorCities:
        return 'Countries';

      case QuizGameType.birds:
      case QuizGameType.dinosaurs:
        return 'Animals';

      case QuizGameType.authors:
        return 'Books & Authors';

      case QuizGameType.breakfastFoods:
      case QuizGameType.dessertsCakesSweets:
        return 'Food & Drink';

      case QuizGameType.firebaseDynamic:
        return 'Surprise Me';
    }
  }

  bool get _allItemsHaveStableIds {
    return widget.items.every(
      (item) => item.id != null && item.id!.isNotEmpty,
    );
  }

  bool _hasPlayedItem(QuizItem item) {
    final String? id = item.id;

    return id != null &&
        id.isNotEmpty &&
        playedQuestionIds.contains(id);
  }

  bool get isPracticeModeActive {
    if (widget.launchedFromSurpriseMe ||
        !questionHistoryLoaded ||
        widget.items.isEmpty) {
      return false;
    }

    return currentQuestionIsReplay;
  }

  QuizItem chooseNextItem({
    QuizItem? excluding,
  }) {
    if (!questionHistoryLoaded || !_allItemsHaveStableIds) {
      return chooseRandomItem(excluding: excluding);
    }

    final List<QuizItem> unseenItems = widget.items
        .where((item) => !_hasPlayedItem(item))
        .toList();

    if (unseenItems.isNotEmpty) {
      List<QuizItem> candidates = unseenItems;

      if (excluding != null && candidates.length > 1) {
        candidates = candidates
            .where((item) => item.id != excluding.id)
            .toList();
      }

      if (candidates.isEmpty) {
        return excluding ?? widget.items.first;
      }

      return candidates[random.nextInt(candidates.length)];
    }

    final Set<String> cycleIds = _practiceCycleIds;

    if (cycleIds.length >= widget.items.length) {
      cycleIds.clear();
    }

    List<QuizItem> candidates = widget.items
        .where(
          (item) =>
              item.id != null &&
              !cycleIds.contains(item.id),
        )
        .toList();

    if (excluding != null && candidates.length > 1) {
      candidates = candidates
          .where((item) => item.id != excluding.id)
          .toList();
    }

    if (candidates.isEmpty) {
      cycleIds.clear();

      candidates = widget.items
          .where(
            (item) =>
                excluding == null ||
                item.id != excluding.id,
          )
          .toList();

      if (candidates.isEmpty) {
        candidates = List<QuizItem>.from(widget.items);
      }
    }

    final QuizItem selected =
        candidates[random.nextInt(candidates.length)];

    final String? selectedId = selected.id;
    if (selectedId != null && selectedId.isNotEmpty) {
      cycleIds.add(selectedId);
    }

    return selected;
  }

  Future<void> initialiseQuestionHistoryAndRound() async {
    final Set<String> savedPlayedIds =
        await QuestionHistoryService.loadPlayedQuestionIds();

    if (!mounted) {
      return;
    }

    playedQuestionIds = savedPlayedIds;
    questionHistoryLoaded = true;

    final bool allCurrentChallengesPlayed =
        !widget.launchedFromSurpriseMe &&
        _allItemsHaveStableIds &&
        widget.items.every(_hasPlayedItem);

    final QuizItem selectedItem =
        widget.initialItem ?? chooseNextItem();

    setState(() {
      currentItem = selectedItem;
      currentQuestionIsReplay =
          allCurrentChallengesPlayed ||
          _hasPlayedItem(selectedItem);
    });

    if (allCurrentChallengesPlayed) {
      if (!mounted) {
        return;
      }

      final bool? continuePlaying =
          await showPracticeModeDialog(
        context: context,
        categoryLabel: categoryLabel,
      );

      if (!mounted) {
        return;
      }

      if (continuePlaying != true) {
        returnToCategory(closeDialog: false);
        return;
      }

      setState(() {
        practiceModeNoticeShown = true;
      });
    }

    await prepareCurrentImage();

    if (!mounted) {
      return;
    }

    await recordCurrentQuestionAsPlayed();

    if (!mounted) {
      return;
    }

    if (showSurpriseToast) {
      _showSurpriseToastThenStartTimer();
    } else {
      roundStartedAt = DateTime.now();
      startClueTimer();
    }
  }

  Future<void> recordCurrentQuestionAsPlayed() async {
    final String? questionId = currentItem.id;

    if (questionId == null ||
        questionId.isEmpty ||
        playedQuestionIds.contains(questionId)) {
      return;
    }

    await QuestionHistoryService.recordPlayedQuestion(
      questionId,
    );

    playedQuestionIds.add(questionId);
  }

  void startClueTimer({
    bool resetTime = true,
  }) {
    clueTimer?.cancel();

    if (!mounted || roundFinished) {
      return;
    }

    if (resetTime) {
      setState(() {
        millisecondsRemaining =
            _GameScreenState
                .clueDurationMilliseconds;
      });
    }

    clueTimer = Timer.periodic(
      const Duration(
        milliseconds:
            _GameScreenState
                .timerUpdateMilliseconds,
      ),
      (timer) {
        if (!mounted || roundFinished) {
          timer.cancel();
          return;
        }

        final int newRemainingTime =
            millisecondsRemaining -
            _GameScreenState
                .timerUpdateMilliseconds;

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
    if (roundFinished) {
      return;
    }

    setState(() {
      closeGuessesThisClue = 0;
    });

    if (isLastClue) {
      await finishFailedRound();
      return;
    }

    showSmallTimeUpOverlay();
    advanceToNextClue(clearGuess: false);
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

  Future<void> submitGuess() async {
    if (roundFinished) {
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

    final GuessMatch match =
        currentItem.checkGuess(guess);

    switch (match) {
      case GuessMatch.correct:
        clueTimer?.cancel();

        final bool isFirstSubmittedGuess =
            guessesThisRound == 0;

        guessesThisRound++;

        setState(() {
          closeGuessesThisClue = 0;
        });

        showGameMessage(
          'Correct!',
          type: GameMessageType.success,
          duration: const Duration(
            milliseconds: 700,
          ),
        );

        await Future<void>.delayed(
          const Duration(milliseconds: 700),
        );

        if (!mounted) {
          return;
        }

        await finishCorrectRound(
          wasFirstGuess:
              currentClueIndex == 0 &&
              isFirstSubmittedGuess,
        );

        return;

      case GuessMatch.close:
        const int spellingGraceMilliseconds =
            10000;

        final int updatedCloseGuessCount =
            closeGuessesThisClue + 1;

        if (updatedCloseGuessCount >= 3) {
          clueTimer?.cancel();

          guessesThisRound++;

          setState(() {
            closeGuessesThisClue = 0;
            lives--;
            guessController.clear();
          });

          showGameMessage(
            'Too many spelling attempts! One life lost.',
            type: GameMessageType.error,
            duration: const Duration(
              milliseconds: 2200,
            ),
          );

          await Future<void>.delayed(
            const Duration(milliseconds: 2200),
          );

          if (!mounted) {
            return;
          }

          if (lives <= 0 || isLastClue) {
            await finishFailedRound();
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

        return;

      case GuessMatch.incorrect:
        clueTimer?.cancel();

        guessesThisRound++;

        setState(() {
          closeGuessesThisClue = 0;
          lives--;
          guessController.clear();
        });

        if (lives <= 0 || isLastClue) {
          showGameMessage(
            'Incorrect! One life lost.',
            type: GameMessageType.error,
            duration: const Duration(
              milliseconds: 700,
            ),
          );

          await Future<void>.delayed(
            const Duration(milliseconds: 700),
          );

          if (!mounted) {
            return;
          }

          await finishFailedRound();
          return;
        }

        advanceToNextClue();

        showGameMessage(
          'Incorrect! One life lost.',
          type: GameMessageType.error,
        );

        return;
    }
  }

  bool get _allCurrentQuestionsHaveNowBeenPlayed {
    return !widget.launchedFromSurpriseMe &&
        _allItemsHaveStableIds &&
        widget.items.every(_hasPlayedItem);
  }

  Future<bool> showCompletionNoticeIfNeeded() async {
    if (practiceModeNoticeShown ||
        !_allCurrentQuestionsHaveNowBeenPlayed) {
      return true;
    }

    final bool? continuePlaying =
        await showPracticeModeDialog(
      context: context,
      categoryLabel: categoryLabel,
    );

    if (!mounted) {
      return false;
    }

    if (continuePlaying != true) {
      returnToCategory(closeDialog: false);
      return false;
    }

    setState(() {
      practiceModeNoticeShown = true;
    });

    return true;
  }

  Future<void> continueToNextRoundAfterResult({
    bool closeResultDialog = true,
  }) async {
    if (closeResultDialog) {
      final NavigatorState navigator =
          Navigator.of(context);

      if (navigator.canPop()) {
        navigator.pop();
      }
    }

    final bool continuePlaying =
        await showCompletionNoticeIfNeeded();

    if (!mounted || !continuePlaying) {
      return;
    }

    startNewRound(
      closeDialog: false,
    );
  }

  void continueToNextRoundFromResult() {
    unawaited(
      continueToNextRoundAfterResult(),
    );
  }

  Future<void> finishCorrectRound({
    required bool wasFirstGuess,
  }) async {
    if (roundFinished) {
      return;
    }

    clueTimer?.cancel();

    const int firstGuessBonus = 50;

    final bool isReplay = currentQuestionIsReplay;

    final int pointsWon = isReplay
        ? 0
        : wasFirstGuess
            ? pointsAvailable + firstGuessBonus
            : pointsAvailable;

    final int clueNumber =
        currentClueIndex + 1;

    setState(() {
      roundFinished = true;
    });

    await recordCurrentQuestionAsPlayed();

    final PlayerRankProgress previousRank =
        PlayerRankProgress.fromXp(
      playerStats.totalXp,
    );

    final PlayerStats updatedStats = isReplay
        ? playerStats
        : await PlayerStatsService
            .recordCorrectGame(
            currentStats: playerStats,
            category: widget.statsCategory,
            pointsWon: pointsWon,
            clueNumber: clueNumber,
            wasFirstGuess: wasFirstGuess,
            playTimeSeconds:
                roundPlayTimeSeconds,
          );

    if (!mounted) {
      return;
    }

    final PlayerRankProgress currentRank =
        PlayerRankProgress.fromXp(
      updatedStats.totalXp,
    );

    setState(() {
      playerStats = updatedStats;
    });

    if (isReplay) {
      if (widget.launchedFromSurpriseMe) {
        startNextSurpriseGame(
          closeDialog: false,
        );
      } else {
        startNewRound(
          closeDialog: false,
        );
      }
      return;
    }

    final bool didLevelUp =
        currentRank.isLevelUpFrom(previousRank);

    Future<void> showLevelUpThen(
      VoidCallback afterLevelUp,
    ) async {
      Navigator.of(context).pop();

      await showRankProgressDialog(
        context: context,
        previous: previousRank,
        current: currentRank,
        xpEarned: pointsWon,
      );

      if (!mounted) {
        return;
      }

      afterLevelUp();
    }

    await showResult(
      title: isReplay
          ? 'CORRECT!'
          : wasFirstGuess
              ? 'FIRST GUESS!'
              : 'CORRECT!',
      message: isReplay
          ? 'You identified ${currentItem.answer.toUpperCase()}'
          : wasFirstGuess
              ? 'You identified ${currentItem.answer.toUpperCase()}\n\n'
                  '$pointsAvailable XP\n'
                  '$firstGuessBonus XP First Guess Bonus\n\n'
                  '$pointsWon XP TOTAL'
              : 'You identified ${currentItem.answer.toUpperCase()}\n\n'
                  '$pointsWon XP',
      icon: !isReplay && wasFirstGuess
          ? Icons.looks_one
          : Icons.emoji_events,
      onPlayAgainOverride: didLevelUp
          ? () async {
              await showLevelUpThen(() {
                if (widget.launchedFromSurpriseMe) {
                  startNextSurpriseGame(
                    closeDialog: false,
                  );
                } else {
                  unawaited(
                    continueToNextRoundAfterResult(
                      closeResultDialog: false,
                    ),
                  );
                }
              });
            }
          : null,
      onHomeOverride: didLevelUp
          ? () async {
              await showLevelUpThen(() {
                returnHome(
                  closeDialog: false,
                );
              });
            }
          : null,
    );

    if (!mounted) {
      return;
    }
  }

  Future<void> finishFailedRound() async {
    if (roundFinished) {
      return;
    }

    clueTimer?.cancel();

    final bool isReplay = currentQuestionIsReplay;

    setState(() {
      roundFinished = true;
    });

    await recordCurrentQuestionAsPlayed();

    final PlayerStats updatedStats = isReplay
        ? playerStats
        : await PlayerStatsService
            .recordFailedGame(
            currentStats: playerStats,
            playTimeSeconds:
                roundPlayTimeSeconds,
          );

    if (!mounted) {
      return;
    }

    setState(() {
      playerStats = updatedStats;
    });

    await showResult(
      title: 'GAME OVER',
      message:
          'The answer was ${currentItem.answer}.',
      imageAsset: 'assets/images/stats/game_over.png',
    );
  }

  Future<void> giveUpRound() async {
    if (roundFinished) {
      return;
    }

    clueTimer?.cancel();
    messageTimer?.cancel();
    timeUpOverlayTimer?.cancel();

    final bool isReplay = currentQuestionIsReplay;

    setState(() {
      roundFinished = true;
      closeGuessesThisClue = 0;
      gameMessage = null;
      showTimeUpOverlay = false;
      guessController.clear();
    });

    await recordCurrentQuestionAsPlayed();

    final PlayerStats updatedStats = isReplay
        ? playerStats
        : await PlayerStatsService
            .recordFailedGame(
            currentStats: playerStats,
            playTimeSeconds:
                roundPlayTimeSeconds,
          );

    if (!mounted) {
      return;
    }

    setState(() {
      playerStats = updatedStats;
    });

    await showResult(
      title: 'YOU GAVE UP!',
      message:
          'The answer was ${currentItem.answer}.',
      imageAsset: 'assets/images/ui/popups/give_up.webp',
      primaryButtonLabel: 'NEXT QUESTION',
      secondaryButtonLabel: 'BACK TO HOME',
    );
  }

  void showNextClue() {
    if (roundFinished || isLastClue) {
      return;
    }

    clueTimer?.cancel();
    messageTimer?.cancel();
    timeUpOverlayTimer?.cancel();

    setState(() {
      closeGuessesThisClue = 0;
      gameMessage = null;
      showTimeUpOverlay = false;
    });

    advanceToNextClue();
  }

  void advanceToNextClue({
    bool clearGuess = true,
  }) {
    if (isLastClue || roundFinished) {
      return;
    }

    setState(() {
      currentClueIndex++;
      closeGuessesThisClue = 0;

      if (clearGuess) {
        guessController.clear();
      }
    });

    startClueTimer();
  }

  void showGameMessage(
    String message, {
    GameMessageType type =
        GameMessageType.info,
    Duration duration = const Duration(
      milliseconds: 2200,
    ),
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
        });
      },
    );
  }

  Future<void> showResult({
    required String title,
    required String message,
    IconData? icon,
    String? imageAsset,
    VoidCallback? onPlayAgainOverride,
    VoidCallback? onHomeOverride,
    String? primaryButtonLabel,
    String? secondaryButtonLabel,
  }) async {
    clueTimer?.cancel();
    messageTimer?.cancel();
    timeUpOverlayTimer?.cancel();
    surpriseToastTimer?.cancel();

    if (mounted) {
      setState(() {
        gameMessage = null;
        showTimeUpOverlay = false;
        showSurpriseToast = false;
      });
    }

    if (!widget.launchedFromSurpriseMe) {
      preloadedNextItem = chooseNextItem(
        excluding: currentItem,
      );

      try {
        await precacheImage(
          imageProviderForPath(
            preloadedNextItem!.imagePath,
          ),
          context,
        );
      } catch (_) {
        // The image widget still handles genuine asset failures.
      }
    }

    if (!mounted) {
      return;
    }

    await showGameResultDialog(
      context: context,
      title: title,
      message: message,
      icon: icon,
      imageAsset: imageAsset,
      onPlayAgain: onPlayAgainOverride ??
          (widget.launchedFromSurpriseMe
              ? startNextSurpriseGame
              : continueToNextRoundFromResult),
      onHome: onHomeOverride ?? returnHome,
      primaryButtonLabel: primaryButtonLabel,
      secondaryButtonLabel: secondaryButtonLabel,
    );
  }

  void returnToCategory({
    bool closeDialog = true,
  }) {
    _practiceCyclePlayedIds.remove(this);

    clueTimer?.cancel();
    messageTimer?.cancel();
    timeUpOverlayTimer?.cancel();
    surpriseToastTimer?.cancel();

    final NavigatorState navigator = Navigator.of(context);

    if (closeDialog && navigator.canPop()) {
      navigator.pop();
    }

    if (navigator.canPop()) {
      navigator.pop();
    }
  }

  void returnHome({
    bool closeDialog = true,
  }) {
    _practiceCyclePlayedIds.remove(this);

    clueTimer?.cancel();
    messageTimer?.cancel();
    timeUpOverlayTimer?.cancel();
    surpriseToastTimer?.cancel();

    final NavigatorState navigator = Navigator.of(context);

    if (closeDialog && navigator.canPop()) {
      navigator.pop();
    }

    navigator.popUntil((route) => route.isFirst);
  }

  Future<void> startNextSurpriseGame({
    bool closeDialog = true,
  }) async {
    final NavigatorState navigator = Navigator.of(context);

    clueTimer?.cancel();
    messageTimer?.cancel();
    timeUpOverlayTimer?.cancel();
    surpriseToastTimer?.cancel();

    if (closeDialog && navigator.canPop()) {
      navigator.pop();
    }

    final String currentId = currentItem.id ?? '';
    final List<String> idParts = currentId.split('_');

    String? currentCategory;
    String? currentSubcategory;

    if (idParts.length >= 3) {
      if (currentId.startsWith('food_drink_')) {
        currentCategory = 'food_drink';
      } else if (currentId.startsWith('books_authors_')) {
        currentCategory = 'books_authors';
      } else if (currentId.startsWith('science_nature_')) {
        currentCategory = 'science_nature';
      } else if (currentId.startsWith('past_present_')) {
        currentCategory = 'past_present';
      } else if (currentId.startsWith('famous_people_')) {
        currentCategory = 'famous_people';
      } else if (currentId.startsWith('creative_world_')) {
        currentCategory = 'creative_world';
      } else if (currentId.startsWith('watch_play_')) {
        currentCategory = 'watch_play';
      } else {
        currentCategory = idParts.first;
      }
    }

    if (currentCategory != null && currentId.startsWith('${currentCategory}_')) {
      final String rest = currentId.substring(currentCategory.length + 1);
      final int lastUnderscore = rest.lastIndexOf('_');
      if (lastUnderscore > 0) {
        currentSubcategory = rest.substring(0, lastUnderscore);
      }
    }

    try {
      final Set<String> playedIds =
          await QuestionHistoryService.loadPlayedQuestionIds();

      if (!mounted) {
        return;
      }

      final FirebaseSurpriseSelection? selected =
          await FirebaseChallengeService.loadRandomLiveSurpriseQuestion(
        playedQuestionIds: playedIds,
        previousCategory: currentCategory,
        previousSubcategory: currentSubcategory,
        excludedQuestionId: currentId,
      );

      if (!mounted) {
        return;
      }

      if (selected == null) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(
              content: Text(
                'Surprise Me could not find another live question.',
              ),
            ),
          );
        return;
      }

      navigator.pushReplacement(
        MaterialPageRoute<void>(
          builder: (context) => GameScreen.firebaseDynamic(
            items: <QuizItem>[selected.item],
            initialItem: selected.item,
            launchedFromSurpriseMe: true,
            showSurpriseToast: true,
          ),
        ),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              'Surprise Me could not load the next live question.',
            ),
          ),
        );
    }
  }

  void startNewRound({
    bool closeDialog = true,
  }) {
    if (closeDialog) {
      Navigator.of(context).pop();
    }

    clueTimer?.cancel();
    messageTimer?.cancel();
    timeUpOverlayTimer?.cancel();
    surpriseToastTimer?.cancel();

    setState(() {
      currentItem = preloadedNextItem ??
          chooseNextItem(
            excluding: currentItem,
          );
      currentQuestionIsReplay =
          _hasPlayedItem(currentItem);
      preloadedNextItem = null;
      imageReady = false;

      currentClueIndex = 0;
      lives =
          _GameScreenState.maximumLives;
      guessesThisRound = 0;
      closeGuessesThisClue = 0;
      millisecondsRemaining =
          _GameScreenState
              .clueDurationMilliseconds;

      roundFinished = false;
      showTimeUpOverlay = false;
      showSurpriseToast = false;

      gameMessage = null;
      gameMessageType =
          GameMessageType.info;

      guessController.clear();
      roundStartedAt = DateTime.now();
    });

    WidgetsBinding.instance
        .addPostFrameCallback((_) async {
      await prepareCurrentImage();

      if (!mounted) {
        return;
      }

      await recordCurrentQuestionAsPlayed();

      if (!mounted) {
        return;
      }

      roundStartedAt = DateTime.now();
      startClueTimer();
    });
  }
}