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

  String get _analyticsQuestionId => currentItem.id ?? '';

  String get _analyticsCategoryKey {
    return _mainStatsCategoryKeyForQuestionId(_analyticsQuestionId) ??
        widget.statsCategory.name;
  }

  String get _analyticsSubcategoryKey {
    final String? explicitTitle = widget.subcategoryTitle?.trim();
    if (explicitTitle != null && explicitTitle.isNotEmpty) {
      return explicitTitle
          .toLowerCase()
          .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
          .replaceAll(RegExp(r'^_+|_+$'), '');
    }

    String id = _analyticsQuestionId.toLowerCase();
    id = id.replaceFirst(RegExp(r'_\d+$'), '');

    final String category = _analyticsCategoryKey;
    final List<String> prefixes = <String>[
      '${category}_',
      if (category == 'famous_people') 'who_am_i_',
    ];

    for (final String prefix in prefixes) {
      if (id.startsWith(prefix)) {
        return id.substring(prefix.length);
      }
    }

    return id;
  }

  String get _analyticsSource {
    if (widget.launchedFromCaseFile) {
      return widget.caseFileReplay ? 'case_file_replay' : 'case_file';
    }
    if (widget.launchedFromSurpriseMe) {
      return 'surprise_me';
    }
    return 'category';
  }

  Future<void> _logClassicGameStarted() {
    return AnalyticsService.logGameStarted(
      gameType: 'classic_first_guess',
      category: _analyticsCategoryKey,
      subcategory: _analyticsSubcategoryKey,
      questionId: _analyticsQuestionId,
      source: _analyticsSource,
      practiceMode: currentQuestionIsReplay,
    );
  }

  Future<void> _logClassicGameCompleted({
    required String result,
    required int xpEarned,
    required bool firstGuess,
  }) {
    return AnalyticsService.logGameCompleted(
      gameType: 'classic_first_guess',
      category: _analyticsCategoryKey,
      subcategory: _analyticsSubcategoryKey,
      questionId: _analyticsQuestionId,
      source: _analyticsSource,
      result: result,
      xpEarned: xpEarned,
      firstGuess: firstGuess,
      practiceMode: currentQuestionIsReplay,
      clueNumber: currentClueIndex + 1,
      guesses: guessesThisRound,
      livesRemaining: lives,
      playTimeSeconds: roundPlayTimeSeconds,
    );
  }

  Future<void> _logClassicQuestionStarted() {
    return AnalyticsService.logQuestionStarted(
      gameKey: 'classic_first_guess',
      category: _analyticsCategoryKey,
      subcategory: _analyticsSubcategoryKey,
      questionId: _analyticsQuestionId,
      source: _analyticsSource,
      practiceMode: currentQuestionIsReplay,
    );
  }

  Future<void> _logClassicQuestionCompleted({
    required String result,
    required int xpEarned,
    required bool firstGuess,
  }) {
    return AnalyticsService.logQuestionCompleted(
      gameKey: 'classic_first_guess',
      category: _analyticsCategoryKey,
      subcategory: _analyticsSubcategoryKey,
      questionId: _analyticsQuestionId,
      source: _analyticsSource,
      result: result,
      xpEarned: xpEarned,
      firstGuess: firstGuess,
      clueNumber: currentClueIndex + 1,
      guesses: guessesThisRound,
      livesRemaining: lives,
      playTimeSeconds: roundPlayTimeSeconds,
      practiceMode: currentQuestionIsReplay,
    );
  }

  Future<void> _recordClassicContentConsumption() async {
    if (currentQuestionIsReplay ||
        widget.launchedFromSurpriseMe ||
        widget.launchedFromCaseFile) {
      return;
    }

    final String questionId = _analyticsQuestionId.trim();

    if (questionId.isEmpty || widget.items.isEmpty) {
      return;
    }

    try {
      await ContentConsumptionService.recordQuestionCompleted(
        gameKey: 'classic_first_guess',
        category: _analyticsCategoryKey,
        subcategory: _analyticsSubcategoryKey,
        questionId: questionId,
        totalQuestionsAvailable: widget.items.length,
      );
    } catch (error, stackTrace) {
      debugPrint(
        'CONTENT CONSUMPTION TRACKING ERROR: $error',
      );
      debugPrintStack(stackTrace: stackTrace);
    }
  }

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

    roundStartedAt = DateTime.now();
    await _logClassicGameStarted();
    await _logClassicQuestionStarted();

    if (showSurpriseToast) {
      _showSurpriseToastThenStartTimer();
    } else {
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
    // Classic First Guess is now untimed.
    // Daily Flash 5 uses its own separate timer in
    // daily_flash_game_screen.dart and is unaffected.
    clueTimer?.cancel();

    if (!mounted || roundFinished) {
      return;
    }

    if (resetTime &&
        millisecondsRemaining !=
            _GameScreenState.clueDurationMilliseconds) {
      setState(() {
        millisecondsRemaining =
            _GameScreenState.clueDurationMilliseconds;
      });
    }
  }

  Future<void> submitGuess() async {
    if (_useNativePhoneLayout(context)) FocusScope.of(context).unfocus();
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

      case GuessMatch.specific:
        const int specificAnswerGraceMilliseconds =
            10000;

        setState(() {
          closeGuessesThisClue = 0;

          if (millisecondsRemaining <
              specificAnswerGraceMilliseconds) {
            millisecondsRemaining =
                specificAnswerGraceMilliseconds;
          }
        });

        showGameMessage(
          'Close! Be more specific.',
          type: GameMessageType.warning,
        );

        WidgetsBinding.instance
            .addPostFrameCallback((_) {
          if (!mounted) {
            return;
          }

          if (!_useNativePhoneLayout(context)) guessFocusNode.requestFocus();

          guessController.selection =
              TextSelection(
            baseOffset: 0,
            extentOffset:
                guessController.text.length,
          );
        });

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

          if (lives <= 0 || isLastClue) {
            showGameMessage(
              lives <= 0
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

            await finishFailedRound();
            return;
          }

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

          if (!_useNativePhoneLayout(context)) guessFocusNode.requestFocus();

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
            lives <= 0
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

  Future<void> loadAnimalKingdomGameplayProgress() async {
    if (!widget.launchedFromCaseFile) {
      return;
    }

    try {
      final String representativeId =
          widget.initialItem?.id ??
          (widget.items.isNotEmpty
              ? widget.items.first.id ?? ''
              : '');

      final bool isRoundTheWorld =
          _countrySubcategoryFromQuestionId(
                representativeId,
              ) !=
              null;

      final bool isSecretsOfThePast =
          _pastPresentSubcategoryFromQuestionId(
                representativeId,
              ) !=
              null;

      final bool isTasteAndTreats =
          _foodDrinkSubcategoryFromQuestionId(
                representativeId,
              ) !=
              null;

      final bool isNatureOfDiscovery =
          _scienceNatureSubcategoryFromQuestionId(
                representativeId,
              ) !=
              null;

      final bool isTheWrittenWord =
          _booksAuthorsSubcategoryFromQuestionId(
                representativeId,
              ) !=
              null;

      final bool isTheCreativeCode =
          _creativeWorldSubcategoryFromQuestionId(
                representativeId,
              ) !=
              null;

      final progress = isRoundTheWorld
          ? await CasePathService.loadRoundTheWorldProgress()
          : isSecretsOfThePast
              ? await CasePathService.loadSecretsOfThePastProgress()
              : isTasteAndTreats
                  ? await CasePathService.loadTasteAndTreatsProgress()
                  : isNatureOfDiscovery
                      ? await CasePathService.loadNatureOfDiscoveryProgress()
                      : isTheWrittenWord
                          ? await CasePathService.loadTheWrittenWordProgress()
                          : isTheCreativeCode
                              ? await CasePathService.loadTheCreativeCodeProgress()
                              : await CasePathService.loadAnimalKingdomProgress();

      if (!mounted) {
        return;
      }

      setState(() {
        activeCaseStage = progress.currentStage;
        activeCaseCorrectCount =
            progress.currentStageProgress.correctCount;
        activeCaseClueThresholdCount =
            progress.currentStageProgress.clueThresholdCount;
        activeCaseFirstGuessCount =
            progress.currentStageProgress.firstGuessCount;
        caseProgressLoaded = true;
      });
    } catch (error, stackTrace) {
      debugPrint(
        'CASE FILE PROGRESS LOAD ERROR: $error',
      );
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  String? _countrySubcategoryFromQuestionId(
    String questionId,
  ) {
    if (questionId.startsWith('countries_')) {
      final String remainder =
          questionId.substring('countries_'.length);
      final int finalUnderscore =
          remainder.lastIndexOf('_');

      if (finalUnderscore > 0) {
        final String parsed =
            remainder.substring(0, finalUnderscore);

        if (parsed == 'currencies') {
          return 'currencies_languages';
        }

        return parsed;
      }
    }

    const Map<String, String> countryQuestionIdPrefixes =
        <String, String>{
      'country_silhouettes_': 'country_silhouettes',
      'flags_': 'flags',
      'capitals_': 'capitals',
      'major_cities_': 'major_cities',
      'states_regions_': 'states_regions',
      'maps_borders_': 'maps_borders',
      'landmarks_world_wonders_': 'landmarks_world_wonders',
      'currencies_languages_': 'currencies_languages',
      'currencies_': 'currencies_languages',
      'national_symbols_': 'national_symbols',
      'islands_mountains_rivers_': 'islands_mountains_rivers',
      'national_foods_': 'national_foods',
    };

    for (final MapEntry<String, String> entry
        in countryQuestionIdPrefixes.entries) {
      if (questionId.startsWith(entry.key)) {
        return entry.value;
      }
    }

    return null;
  }

  String? _pastPresentSubcategoryFromQuestionId(
    String questionId,
  ) {
    if (questionId.startsWith('past_present_')) {
      final String remainder =
          questionId.substring('past_present_'.length);
      final int finalUnderscore = remainder.lastIndexOf('_');

      if (finalUnderscore > 0) {
        return remainder.substring(0, finalUnderscore);
      }
    }

    const Map<String, String> pastPresentQuestionIdPrefixes =
        <String, String>{
      'historical_events_': 'historical_events',
      'battles_wars_': 'battles_wars',
      'ancient_civilisations_empires_':
          'ancient_civilisations_empires',
      'historical_eras_': 'historical_eras',
      'historic_objects_': 'historic_objects',
      'castles_ruins_': 'castles_ruins',
      'monarchies_dynasties_': 'monarchies_dynasties',
      'revolutions_political_movements_':
          'revolutions_political_movements',
      'historical_mysteries_': 'historical_mysteries',
      'myths_legends_': 'myths_legends',
      'traditions_cultural_customs_':
          'traditions_cultural_customs',
      'ancient_religions_beliefs_':
          'ancient_religions_beliefs',
      'important_dates_': 'important_dates',
    };

    for (final MapEntry<String, String> entry
        in pastPresentQuestionIdPrefixes.entries) {
      if (questionId.startsWith(entry.key)) {
        return entry.value;
      }
    }

    return null;
  }

  String? _foodDrinkSubcategoryFromQuestionId(
    String questionId,
  ) {
    if (questionId.startsWith('food_drink_')) {
      final String remainder =
          questionId.substring('food_drink_'.length);
      final int finalUnderscore = remainder.lastIndexOf('_');

      if (finalUnderscore > 0) {
        final String parsed =
            remainder.substring(0, finalUnderscore);

        if (parsed.isNotEmpty) {
          return parsed;
        }
      }
    }

    const Map<String, String> foodDrinkQuestionIdPrefixes =
        <String, String>{
      'breakfast_foods_': 'breakfast',
      'breakfast_': 'breakfast',
      'desserts_cakes_sweets_': 'desserts',
      'desserts_': 'desserts',
      'dishes_world_cuisine_': 'dishes_world_cuisine',
      'fruit_vegs_': 'fruit_vegs',
      'herbs_spices_': 'herbs_spices',
      'snacks_street_food_': 'snacks_street_food',
      'drinks_': 'drinks',
    };

    for (final MapEntry<String, String> entry
        in foodDrinkQuestionIdPrefixes.entries) {
      if (questionId.startsWith(entry.key)) {
        return entry.value;
      }
    }

    return null;
  }

  String? _scienceNatureSubcategoryFromQuestionId(
    String questionId,
  ) {
    if (questionId.startsWith('science_nature_')) {
      final String remainder =
          questionId.substring('science_nature_'.length);
      final int finalUnderscore =
          remainder.lastIndexOf('_');

      if (finalUnderscore > 0) {
        final String parsed =
            remainder.substring(0, finalUnderscore);

        if (parsed.isNotEmpty) {
          return parsed;
        }
      }
    }

    const Map<String, String> prefixes = <String, String>{
      'chemistry_physics_biology_maths_':
          'chemistry_physics_biology_maths',
      'chemistry_': 'chemistry',
      'physics_': 'physics',
      'biology_': 'biology',
      'mathematics_': 'mathematics',
      'computers_internet_': 'computers_internet',
      'inventions_technology_': 'inventions_technology',
      'inventions_': 'inventions_technology',
      'medicine_health_': 'medicine_health',
      'periodic_table_': 'periodic_table',
      'plants_trees_': 'plants_trees',
      'rocks_minerals_volcanoes_':
          'rocks_minerals_volcanoes',
      'scientific_discoveries_experiments_theories_':
          'scientific_discoveries_experiments_theories',
      'space_astronomy_': 'space_astronomy',
      'space_missions_': 'space_missions',
      'human_body_': 'human_body',
      'weather_oceans_ecosystems_':
          'weather_oceans_ecosystems',
    };

    for (final MapEntry<String, String> entry
        in prefixes.entries) {
      if (questionId.startsWith(entry.key)) {
        return entry.value;
      }
    }

    return null;
  }

  String? _booksAuthorsSubcategoryFromQuestionId(
    String questionId,
  ) {
    if (!questionId.startsWith('books_authors_')) {
      return null;
    }

    final String remainder =
        questionId.substring('books_authors_'.length);
    final int finalUnderscore = remainder.lastIndexOf('_');

    if (finalUnderscore <= 0) {
      return null;
    }

    final String parsed = remainder.substring(0, finalUnderscore);
    return parsed.isEmpty ? null : parsed;
  }

  String? _creativeWorldSubcategoryFromQuestionId(
    String questionId,
  ) {
    if (!questionId.startsWith('creative_world_')) {
      return null;
    }

    final String remainder =
        questionId.substring('creative_world_'.length);
    final int finalUnderscore = remainder.lastIndexOf('_');

    if (finalUnderscore <= 0) {
      return null;
    }

    final String parsed = remainder.substring(0, finalUnderscore);
    return parsed.isEmpty ? null : parsed;
  }


  Future<int?> recordAnimalKingdomCaseResult({
    required int clueNumber,
    required bool wasFirstGuess,
    required bool practiceMode,
  }) async {
    if (widget.caseFileReplay) {
      return null;
    }

    final String? questionId = currentItem.id;

    if (questionId == null || questionId.isEmpty) {
      return null;
    }

    bool isRoundTheWorld = false;
    bool isSecretsOfThePast = false;
    bool isTasteAndTreats = false;
    bool isNatureOfDiscovery = false;
    bool isTheWrittenWord = false;
    bool isTheCreativeCode = false;
    String? category;
    String? subcategory =
        _countrySubcategoryFromQuestionId(questionId);

    if (subcategory != null) {
      isRoundTheWorld = true;
      category = 'countries';
    } else {
      subcategory =
          _pastPresentSubcategoryFromQuestionId(questionId);

      if (subcategory != null) {
        isSecretsOfThePast = true;
        category = 'past_present';
      } else {
        subcategory = _foodDrinkSubcategoryFromQuestionId(questionId);

        if (subcategory != null) {
          isTasteAndTreats = true;
          category = 'food_drink';
        } else {
          subcategory =
              _scienceNatureSubcategoryFromQuestionId(questionId);

          if (subcategory != null) {
            isNatureOfDiscovery = true;
            category = 'science_nature';
          }
 else {
            subcategory =
                _booksAuthorsSubcategoryFromQuestionId(questionId);

            if (subcategory != null) {
              isTheWrittenWord = true;
              category = 'books_authors';
            }
 else {
              subcategory =
                  _creativeWorldSubcategoryFromQuestionId(questionId);

              if (subcategory != null) {
                isTheCreativeCode = true;
                category = 'creative_world';
              }
            }
          }
        }
      }

      if (subcategory == null && widget.gameType == QuizGameType.birds) {
        subcategory = 'birds';
      } else if (subcategory == null && widget.gameType == QuizGameType.dinosaurs) {
        subcategory = 'dinosaurs';
      } else if (subcategory == null && questionId.startsWith('animals_')) {
        final String remainder =
            questionId.substring('animals_'.length);
        final int finalUnderscore =
            remainder.lastIndexOf('_');

        if (finalUnderscore > 0) {
          subcategory =
              remainder.substring(0, finalUnderscore);
        }
      } else if (subcategory == null) {
        const Map<String, String> animalQuestionIdPrefixes =
            <String, String>{
          'birds_': 'birds',
          'dinosaurs_': 'dinosaurs',
          'habitats_animal_groups_': 'habitats_animal_groups',
          'insects_spiders_': 'insects_spiders',
          'safari_jungle_animals_': 'jungle_safari_animals',
          'jungle_safari_animals_': 'jungle_safari_animals',
          'mammals_': 'mammals',
          'reptiles_amphibians_': 'reptiles_amphibians',
          'sea_creatures_': 'sea_creatures',
          'tracks_footprints_': 'tracks_footprints',
        };

        for (final MapEntry<String, String> entry
            in animalQuestionIdPrefixes.entries) {
          if (questionId.startsWith(entry.key)) {
            subcategory = entry.value;
            break;
          }
        }
      }

      if (subcategory != null &&
          !isSecretsOfThePast &&
          !isTasteAndTreats &&
          !isNatureOfDiscovery &&
          !isTheWrittenWord &&
          !isTheCreativeCode) {
        category = 'animals';
      }
    }

    if (subcategory == null ||
        subcategory.isEmpty ||
        category == null) {
      return null;
    }

    const Set<String> animalSubcategories = <String>{
      'birds',
      'dinosaurs',
      'habitats_animal_groups',
      'insects_spiders',
      'jungle_safari_animals',
      'mammals',
      'reptiles_amphibians',
      'sea_creatures',
      'tracks_footprints',
    };

    const Set<String> scienceNatureSubcategories = <String>{
      'chemistry_physics_biology_maths',
      'computers_internet',
      'inventions_technology',
      'medicine_health',
      'periodic_table',
      'plants_trees',
      'rocks_minerals_volcanoes',
      'scientific_discoveries_experiments_theories',
      'space_astronomy',
      'space_missions',
      'human_body',
      'weather_oceans_ecosystems',
    };

    const Set<String> booksAuthorsSubcategories = <String>{
      'authors_poets_playwrights',
      'book_series',
      'books_novels',
      'childrens_books',
      'fictional_literary_locations',
      'folk_tales_fairy_tales',
      'graphic_novels_comics',
      'literary_genres',
      'opening_lines_quotations',
      'plays',
      'poems',
    };

    const Set<String> creativeWorldSubcategories = <String>{
      'architecture_architects',
      'artists',
      'crafts_pottery_ceramics',
      'fashion',
      'museums_galleries',
      'paintings_sculptures',
      'theatre',
    };

    const Set<String> countrySubcategories = <String>{
      'country_silhouettes',
      'flags',
      'capitals',
      'major_cities',
      'states_regions',
      'maps_borders',
      'landmarks_world_wonders',
      'currencies_languages',
      'national_symbols',
      'islands_mountains_rivers',
      'national_foods',
    };

    const Set<String> pastPresentSubcategories = <String>{
      'historical_events',
      'battles_wars',
      'ancient_civilisations_empires',
      'historical_eras',
      'historic_objects',
      'castles_ruins',
      'monarchies_dynasties',
      'revolutions_political_movements',
      'historical_mysteries',
      'myths_legends',
      'traditions_cultural_customs',
      'ancient_religions_beliefs',
      'important_dates',
    };

    if (isRoundTheWorld) {
      if (!countrySubcategories.contains(subcategory)) {
        return null;
      }
    } else if (isSecretsOfThePast) {
      if (!pastPresentSubcategories.contains(subcategory)) {
        return null;
      }
    } else if (isTasteAndTreats) {
      // Food & Drink uses dynamic Firebase subcategory IDs.
      // Any non-empty food_drink_* subcategory is valid here.
    } else if (isNatureOfDiscovery) {
      if (!scienceNatureSubcategories.contains(subcategory)) {
        return null;
      }
    } else if (isTheWrittenWord) {
      if (!booksAuthorsSubcategories.contains(subcategory)) {
        return null;
      }
    } else if (isTheCreativeCode) {
      if (!creativeWorldSubcategories.contains(subcategory)) {
        return null;
      }
    } else if (!animalSubcategories.contains(subcategory)) {
      return null;
    }

    int? stageBefore = activeCaseStage;

    try {
      if (widget.launchedFromCaseFile &&
          stageBefore == null) {
        final progressBefore = isRoundTheWorld
            ? await CasePathService.loadRoundTheWorldProgress()
            : isSecretsOfThePast
                ? await CasePathService.loadSecretsOfThePastProgress()
                : isTasteAndTreats
                    ? await CasePathService.loadTasteAndTreatsProgress()
                    : isNatureOfDiscovery
                        ? await CasePathService.loadNatureOfDiscoveryProgress()
                        : isTheWrittenWord
                            ? await CasePathService.loadTheWrittenWordProgress()
                            : isTheCreativeCode
                                ? await CasePathService.loadTheCreativeCodeProgress()
                                : await CasePathService.loadAnimalKingdomProgress();

        stageBefore = progressBefore.currentStage;
      }

      final String attemptId =
          '${questionId}_${roundStartedAt.microsecondsSinceEpoch}';

      final GameplayResultEvent event =
          GameplayResultEvent(
        attemptId: attemptId,
        questionId: questionId,
        category: category,
        subcategory: subcategory,
        correct: true,
        clueNumberSolved: clueNumber,
        firstGuess: wasFirstGuess,
        practiceMode: practiceMode,
        completedAt: DateTime.now(),
      );

      final updatedProgress = isRoundTheWorld
          ? await CasePathService.recordRoundTheWorldResult(
              event: event,
            )
          : isSecretsOfThePast
              ? await CasePathService.recordSecretsOfThePastResult(
                  event: event,
                )
              : isTasteAndTreats
                  ? await CasePathService.recordTasteAndTreatsResult(
                      event: event,
                    )
                  : isNatureOfDiscovery
                      ? await CasePathService.recordNatureOfDiscoveryResult(
                          event: event,
                        )
                      : isTheWrittenWord
                          ? await CasePathService.recordTheWrittenWordResult(
                              event: event,
                            )
                          : isTheCreativeCode
                              ? await CasePathService.recordTheCreativeCodeResult(
                                  event: event,
                                )
                              : await CasePathService.recordAnimalKingdomResult(
                                  event: event,
                                );

      int? completedStage;

      if (widget.launchedFromCaseFile &&
          stageBefore != null) {
        final bool stageCompleted = isRoundTheWorld
            ? CasePathService.isRoundTheWorldStageCompleted(
                progress: updatedProgress,
                stage: stageBefore,
              )
            : isSecretsOfThePast
                ? CasePathService.isSecretsOfThePastStageCompleted(
                    progress: updatedProgress,
                    stage: stageBefore,
                  )
                : isTasteAndTreats
                    ? CasePathService.isTasteAndTreatsStageCompleted(
                        progress: updatedProgress,
                        stage: stageBefore,
                      )
                    : isNatureOfDiscovery
                        ? CasePathService.isNatureOfDiscoveryStageCompleted(
                            progress: updatedProgress,
                            stage: stageBefore,
                          )
                        : isTheWrittenWord
                            ? CasePathService.isTheWrittenWordStageCompleted(
                                progress: updatedProgress,
                                stage: stageBefore,
                              )
                            : isTheCreativeCode
                                ? CasePathService.isTheCreativeCodeStageCompleted(
                                    progress: updatedProgress,
                                    stage: stageBefore,
                                  )
                                : CasePathService.isAnimalKingdomStageCompleted(
                            progress: updatedProgress,
                            stage: stageBefore,
                          );

        if (stageCompleted) {
          completedStage = stageBefore;
        }
      }

      if (widget.launchedFromCaseFile && mounted) {
        setState(() {
          if (completedStage != null) {
            final completedMission = isRoundTheWorld
                ? CasePathService.roundTheWorldMissionForStage(
                    completedStage
                  )
                : isSecretsOfThePast
                    ? CasePathService.secretsOfThePastMissionForStage(
                        completedStage
                      )
                    : isTasteAndTreats
                        ? CasePathService.tasteAndTreatsMissionForStage(
                            completedStage
                          )
                        : isNatureOfDiscovery
                            ? CasePathService.natureOfDiscoveryMissionForStage(
                                completedStage,
                              )
                            : isTheWrittenWord
                                ? CasePathService.theWrittenWordMissionForStage(
                                    completedStage,
                                  )
                                : isTheCreativeCode
                                    ? CasePathService.theCreativeCodeMissionForStage(
                                        completedStage,
                                      )
                                    : CasePathService.animalKingdomMissionForStage(
                                    completedStage,
                                  );

            activeCaseStage = completedStage;
            activeCaseCorrectCount =
                completedMission?.correctRequired ?? 10;
            activeCaseClueThresholdCount =
                completedMission?.clueThresholdRequired ?? 0;
            activeCaseFirstGuessCount =
                completedMission?.firstGuessesRequired ?? 0;
          } else {
            activeCaseStage = updatedProgress.currentStage;
            activeCaseCorrectCount =
                updatedProgress.currentStageProgress.correctCount;
            activeCaseClueThresholdCount =
                updatedProgress
                    .currentStageProgress.clueThresholdCount;
            activeCaseFirstGuessCount =
                updatedProgress.currentStageProgress.firstGuessCount;
          }

          caseProgressLoaded = true;
        });
      }

      return completedStage;
    } catch (error, stackTrace) {
      debugPrint(
        '${isRoundTheWorld ? 'AROUND THE WORLD' : isSecretsOfThePast ? 'SECRETS OF THE PAST' : isTasteAndTreats ? 'A TASTE OF MYSTERY' : isNatureOfDiscovery ? 'THE NATURE OF DISCOVERY' : isTheWrittenWord ? 'THE WRITTEN WORD' : isTheCreativeCode ? 'THE CREATIVE CODE' : 'ANIMAL KINGDOM'} '
        'CASE TRACKING ERROR: $error',
      );
      debugPrintStack(stackTrace: stackTrace);
      return null;
    }
  }

  String? _mainStatsCategoryKeyForQuestionId(
    String questionId,
  ) {
    final String id = questionId.toLowerCase().trim();

    bool startsWithAny(List<String> prefixes) {
      return prefixes.any(id.startsWith);
    }

    if (startsWithAny(const <String>[
      'animals_',
      'birds_',
      'dinosaurs_',
      'habitats_animal_groups_',
      'insects_spiders_',
      'jungle_safari_animals_',
      'safari_jungle_animals_',
      'mammals_',
      'reptiles_amphibians_',
      'sea_creatures_',
      'tracks_footprints_',
    ])) {
      return 'animals';
    }

    if (startsWithAny(const <String>[
      'books_authors_',
      'authors_',
    ])) {
      return 'books_authors';
    }

    if (startsWithAny(const <String>[
      'countries_',
      'country_',
      'flags_',
      'capitals_',
      'major_cities_',
      'states_regions_',
      'maps_borders_',
      'landmarks_world_wonders_',
      'currencies_languages_',
      'currencies_',
      'national_symbols_',
      'islands_mountains_rivers_',
      'national_foods_',
    ])) {
      return 'countries';
    }

    if (id.startsWith('creative_world_')) {
      return 'creative_world';
    }

    if (id.startsWith('famous_words_')) {
      return 'famous_words';
    }

    if (startsWithAny(const <String>[
      'food_drink_',
      'breakfast_foods_',
      'desserts_cakes_sweets_',
    ])) {
      return 'food_drink';
    }

    if (id.startsWith('music_')) {
      return 'music';
    }

    if (startsWithAny(const <String>[
      'past_present_',
      'historical_events_',
      'battles_wars_',
      'ancient_civilisations_empires_',
      'historical_eras_',
      'archaeology_',
      'historic_objects_',
      'castles_ruins_',
      'monarchies_dynasties_',
      'revolutions_political_movements_',
      'historical_mysteries_',
      'myths_legends_',
      'traditions_cultural_customs_',
      'ancient_religions_beliefs_',
      'then_now_',
      'important_dates_',
    ])) {
      return 'past_present';
    }

    if (startsWithAny(const <String>[
      'science_nature_',
      'plants_trees_',
      'periodic_table_',
      'human_body_',
      'space_missions_',
      'space_astronomy_',
      'medicine_health_',
      'computers_internet_',
      'inventions_technology_',
      'chemistry_physics_biology_maths_',
      'rocks_minerals_volcanoes_',
      'scientific_discoveries_experiments_theories_',
      'weather_oceans_ecosystems_',
    ])) {
      return 'science_nature';
    }

    if (id.startsWith('sports_')) {
      return 'sports';
    }

    if (id.startsWith('watch_play_')) {
      return 'watch_play';
    }

    if (startsWithAny(const <String>[
      'who_am_i_',
      'famous_people_',
    ])) {
      return 'famous_people';
    }

    switch (widget.statsCategory) {
      case GameCategory.countries:
      case GameCategory.capitalCities:
      case GameCategory.flags:
        return 'countries';
      case GameCategory.authors:
        return 'books_authors';
      case GameCategory.animals:
        return 'animals';
      case GameCategory.foodDrink:
        return 'food_drink';
      case GameCategory.other:
        return null;
    }
  }

  Future<void> _showClassicRewardPopups({
    required PlayerStats previous,
    required PlayerStats current,
    required PlayerRankProgress previousRank,
    required PlayerRankProgress currentRank,
    required int xpEarned,
    bool caseBadgeEarned = false,
  }) async {
    final List<EarnedBadge> earnedBadges =
        AchievementService.newlyEarnedBadges(
      previous: previous,
      current: current,
      gameKey: 'first_guess',
      gameLabel: 'First Guess',
    );

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

    // A Case File badge is shown by the Case File completion result itself.
    // Any badge earned from this action suppresses non-badge popups.
    if (caseBadgeEarned || earnedBadges.isNotEmpty) {
      return;
    }

    if (!mounted) {
      return;
    }

    if (currentRank.isLevelUpFrom(previousRank)) {
      await showRankProgressDialog(
        context: context,
        previous: previousRank,
        current: currentRank,
        xpEarned: xpEarned,
      );
      return;
    }

    final List<Achievement> reached =
        AchievementService.popupAchievementsForClassic(
      previous: previous,
      current: current,
    );

    for (final Achievement achievement in reached) {
      final Achievement? next =
          AchievementService.nextMilestoneAfter(achievement);

      if (!mounted) {
        return;
      }

      final String label =
          AchievementService.milestoneLabelFor(achievement);

      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext dialogContext) {
          return MilestoneReachedDialog(
            milestone: MilestonePopupData(
              target: achievement.target,
              label: label,
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

    final int? completedCaseStage =
        await recordAnimalKingdomCaseResult(
      clueNumber: clueNumber,
      wasFirstGuess: wasFirstGuess,
      practiceMode: isReplay,
    );

    final PlayerRankProgress previousRank =
        PlayerRankProgress.fromXp(
      playerStats.totalXp,
    );

    final PlayerStats playerStatsBeforeUpdate =
        playerStats;

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
            mainCategoryKey:
                _mainStatsCategoryKeyForQuestionId(
              currentItem.id ?? '',
            ),
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

    if (!isReplay) {
      await AnalyticsService.logEarnedRewards(
        previous: playerStatsBeforeUpdate,
        current: updatedStats,
        gameKey: 'first_guess',
        gameLabel: 'First Guess',
      );
    }

    await _logClassicGameCompleted(
      result: 'correct',
      xpEarned: pointsWon,
      firstGuess: wasFirstGuess,
    );

    await _logClassicQuestionCompleted(
      result: 'correct',
      xpEarned: pointsWon,
      firstGuess: wasFirstGuess,
    );

    await _recordClassicContentConsumption();

    if (wasFirstGuess) {
      await AnalyticsService.logFirstGuessEarned(
        gameType: 'classic_first_guess',
        category: _analyticsCategoryKey,
        subcategory: _analyticsSubcategoryKey,
        questionId: _analyticsQuestionId,
        source: _analyticsSource,
        xpEarned: pointsWon,
        practiceMode: isReplay,
      );
    }

    Future<void> showPostResultRewardsThen(
      VoidCallback afterRewards, {
      bool caseBadgeEarned = false,
    }) async {
      final NavigatorState navigator = Navigator.of(context);

      if (navigator.canPop()) {
        navigator.pop();
      }

      if (!isReplay) {
        await _showClassicRewardPopups(
          previous: playerStatsBeforeUpdate,
          current: updatedStats,
          previousRank: previousRank,
          currentRank: currentRank,
          xpEarned: pointsWon,
          caseBadgeEarned: caseBadgeEarned,
        );

        if (!mounted) {
          return;
        }
      }

      afterRewards();
    }

    if (widget.launchedFromCaseFile &&
        completedCaseStage != null) {
      final bool isRoundTheWorldCase =
          _countrySubcategoryFromQuestionId(
                currentItem.id ?? '',
              ) !=
              null;

      final bool isSecretsOfThePastCase =
          _pastPresentSubcategoryFromQuestionId(
                currentItem.id ?? '',
              ) !=
              null;

      final bool isTasteAndTreatsCase =
          _foodDrinkSubcategoryFromQuestionId(
                currentItem.id ?? '',
              ) !=
              null;

      final bool isNatureOfDiscoveryCase =
          _scienceNatureSubcategoryFromQuestionId(
                currentItem.id ?? '',
              ) !=
              null;

      final bool isTheWrittenWordCase =
          _booksAuthorsSubcategoryFromQuestionId(
                currentItem.id ?? '',
              ) !=
              null;

      final bool isTheCreativeCodeCase =
          _creativeWorldSubcategoryFromQuestionId(
                currentItem.id ?? '',
              ) !=
              null;

      final int totalStages = isRoundTheWorldCase
          ? CasePathService.roundTheWorldTotalStages
          : isSecretsOfThePastCase
              ? CasePathService.secretsOfThePastTotalStages
              : isTasteAndTreatsCase
                  ? CasePathService.tasteAndTreatsTotalStages
                  : isNatureOfDiscoveryCase
                      ? CasePathService.natureOfDiscoveryTotalStages
                      : isTheWrittenWordCase
                          ? CasePathService.theWrittenWordTotalStages
                          : isTheCreativeCodeCase
                              ? CasePathService.theCreativeCodeTotalStages
                              : CasePathService.animalKingdomTotalStages;

      final bool completedEntireCasePath =
          completedCaseStage >= totalStages;

      final String caseName = isRoundTheWorldCase
          ? 'AROUND THE WORLD'
          : isSecretsOfThePastCase
              ? 'SECRETS OF THE PAST'
              : isTasteAndTreatsCase
                  ? 'A TASTE OF MYSTERY'
                  : isNatureOfDiscoveryCase
                      ? 'THE NATURE OF DISCOVERY'
                      : isTheWrittenWordCase
                          ? 'THE WRITTEN WORD'
                          : isTheCreativeCodeCase
                              ? 'THE CREATIVE CODE'
                              : 'ANIMAL KINGDOM';

      final String badgeName = isRoundTheWorldCase
          ? 'AROUND THE WORLD CASE BADGE'
          : isSecretsOfThePastCase
              ? 'SECRETS OF THE PAST CASE BADGE'
              : isTasteAndTreatsCase
                  ? 'A TASTE OF MYSTERY CASE BADGE'
                  : isNatureOfDiscoveryCase
                      ? 'THE NATURE OF DISCOVERY CASE BADGE'
                      : isTheWrittenWordCase
                          ? 'THE WRITTEN WORD CASE BADGE'
                          : isTheCreativeCodeCase
                              ? 'THE CREATIVE CODE CASE BADGE'
                              : 'ANIMAL KINGDOM CASE BADGE';

      final String caseKey = isRoundTheWorldCase
          ? 'around_the_world'
          : isSecretsOfThePastCase
              ? 'secrets_of_the_past'
              : isTasteAndTreatsCase
                  ? 'taste_and_treats'
                  : isNatureOfDiscoveryCase
                      ? 'nature_of_discovery'
                      : isTheWrittenWordCase
                          ? 'the_written_word'
                          : isTheCreativeCodeCase
                              ? 'the_creative_code'
                              : 'animal_kingdom';

      if (completedEntireCasePath) {
        await AnalyticsService.logCaseFileCompleted(
          caseKey: caseKey,
          caseName: caseName,
          totalStages: totalStages,
        );

        await AnalyticsService.logBadgeEarned(
          badgeName: badgeName,
          gameType: 'case_file',
        );
      }

      final String completionTitle =
          completedEntireCasePath
              ? '$caseName COMPLETE!'
              : 'CASE $completedCaseStage COMPLETE!';

      final String completionMessage =
          completedEntireCasePath
              ? 'You\'ve correctly identified:\n'
                  '${currentItem.answer.toUpperCase()}\n'
                  'BADGE EARNED: $badgeName'
              : 'You\'ve correctly identified:\n'
                  '${currentItem.answer.toUpperCase()}\n'
                  'Case ${completedCaseStage + 1} is now unlocked.';

      if (completedEntireCasePath) {
        final String finalCaseTitle = isRoundTheWorldCase
            ? 'AROUND THE WORLD COMPLETE!'
            : isSecretsOfThePastCase
                ? 'SECRETS OF THE PAST COMPLETE!'
                : isTasteAndTreatsCase
                    ? 'A TASTE OF MYSTERY COMPLETE!'
                    : isNatureOfDiscoveryCase
                        ? 'THE NATURE OF DISCOVERY COMPLETE!'
                        : isTheWrittenWordCase
                            ? 'THE WRITTEN WORD COMPLETE!'
                            : isTheCreativeCodeCase
                                ? 'THE CREATIVE CODE COMPLETE!'
                                : 'ANIMAL KINGDOM COMPLETE!';

        final String finalBadgeAsset = isRoundTheWorldCase
            ? 'assets/images/badges/amazing_world_case_file_badge.webp'
            : isSecretsOfThePastCase
                ? 'assets/images/badges/mysteries_legends_case_file_badge.webp'
                : isTasteAndTreatsCase
                    ? 'assets/images/badges/tastes_treats_case_file_badge.webp'
                    : isNatureOfDiscoveryCase
                        ? 'assets/images/badges/nature_of_discovery.webp'
                    : isTheWrittenWordCase
                        ? 'assets/images/badges/the_written_word.webp'
                        : isTheCreativeCodeCase
                            ? 'assets/images/badges/the_creative_code.webp'
                            : 'assets/images/badges/animal_kingdom_case_file_badge.webp';

        await showResult(
          title: finalCaseTitle,
          message: 'CONGRATULATIONS!\n'
              'YOU SOLVED THE CASE\n'
              'BADGE EARNED',
          imageAsset: finalBadgeAsset,
          primaryButtonLabel: 'BACK TO CASE FILES',
          secondaryButtonLabel: 'PLAY AGAIN',
          onPlayAgainOverride: () async {
            await showPostResultRewardsThen(
              () {
              returnToCaseFilesHome(
                closeDialog: false,
              );
              },
              caseBadgeEarned: true,
            );
          },
          onHomeOverride: () async {
            await showPostResultRewardsThen(
              () {
              returnToCase(
                closeDialog: false,
              );
              },
              caseBadgeEarned: true,
            );
          },
        );

        return;
      }

      await showResult(
        title: completionTitle,
        message: completionMessage,
        imageAsset: completedEntireCasePath
            ? isRoundTheWorldCase
                ? 'assets/images/badges/amazing_world_case_file_badge.webp'
                : isSecretsOfThePastCase
                    ? 'assets/images/badges/mysteries_legends_case_file_badge.webp'
                    : isTasteAndTreatsCase
                        ? 'assets/images/badges/tastes_treats_case_file_badge.webp'
                        : isNatureOfDiscoveryCase
                            ? 'assets/images/badges/nature_of_discovery.webp'
                            : isTheWrittenWordCase
                                ? 'assets/images/badges/the_written_word.webp'
                                : isTheCreativeCodeCase
                                    ? 'assets/images/badges/the_creative_code.webp'
                                    : 'assets/images/badges/animal_kingdom_case_file_badge.webp'
            : 'assets/images/ui/popups/challenges_complete.webp',
        primaryButtonLabel: 'BACK TO CASE FILES',
        suppressDefaultSecondaryButton: true,
        onPlayAgainOverride: () async {
          await showPostResultRewardsThen(() {
            returnToCaseFilesHome(
              closeDialog: false,
            );
          });
        },
        onHomeOverride: () async {
          await showPostResultRewardsThen(() {
            returnHome(
              closeDialog: false,
            );
          });
        },
      );

      return;
    }

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
      onPlayAgainOverride: () async {
        await showPostResultRewardsThen(() {
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
      },
      onHomeOverride: () async {
        await showPostResultRewardsThen(() {
          if (widget.launchedFromCaseFile) {
            returnToCaseFilesHome(
              closeDialog: false,
            );
          } else {
            returnHome(
              closeDialog: false,
            );
          }
        });
      },
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

    await _logClassicGameCompleted(
      result: 'failed',
      xpEarned: 0,
      firstGuess: false,
    );

    await _logClassicQuestionCompleted(
      result: 'failed',
      xpEarned: 0,
      firstGuess: false,
    );

    await _recordClassicContentConsumption();

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

    await _logClassicGameCompleted(
      result: 'gave_up',
      xpEarned: 0,
      firstGuess: false,
    );

    await _logClassicQuestionCompleted(
      result: 'gave_up',
      xpEarned: 0,
      firstGuess: false,
    );

    await _recordClassicContentConsumption();

    await showResult(
      title: 'YOU GAVE UP!',
      message:
          'The answer was ${currentItem.answer}.',
      imageAsset: 'assets/images/ui/popups/give_up.webp',
      primaryButtonLabel: 'NEXT QUESTION',
      secondaryButtonLabel: widget.launchedFromCaseFile
          ? 'BACK TO CASE FILES'
          : 'BACK TO HOME',
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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || roundFinished) {
        return;
      }

      if (!_useNativePhoneLayout(context)) guessFocusNode.requestFocus();
    });
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
    bool suppressDefaultSecondaryButton = false,
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
      onHome: onHomeOverride ??
          (widget.launchedFromCaseFile
              ? returnToCaseFilesHome
              : returnHome),
      primaryButtonLabel: primaryButtonLabel,
      secondaryButtonLabel: suppressDefaultSecondaryButton
          ? null
          : secondaryButtonLabel ??
              (widget.launchedFromCaseFile
                  ? 'BACK TO CASE FILES'
                  : null),
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

  void returnToCase({
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

    if (navigator.canPop()) {
      navigator.pop();
    }
  }

  void returnToCaseFilesHome({
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

    // GameScreen -> Mission screen -> Case map -> Case Files home.
    for (int i = 0; i < 3 && navigator.canPop(); i++) {
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

      final String? scopedCategory = widget.surpriseCategory?.trim();

      final FirebaseSurpriseSelection? selected =
          scopedCategory != null && scopedCategory.isNotEmpty
              ? await FirebaseChallengeService
                  .loadRandomLiveCategorySurpriseQuestion(
                  category: scopedCategory,
                  playedQuestionIds: <String>{
                    ...playedIds,
                    if (currentId.isNotEmpty) currentId,
                  },
                )
              : await FirebaseChallengeService.loadRandomLiveSurpriseQuestion(
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
                "You've played all available Surprise Me questions.",
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
            surpriseCategory: widget.surpriseCategory,
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
      await _logClassicGameStarted();

      if (!mounted) {
        return;
      }

      startClueTimer();
    });
  }
}
