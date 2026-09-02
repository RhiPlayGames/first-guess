part of 'game_screen.dart';

extension _GameScreenView on _GameScreenState {
  Future<void> confirmLeaveGame() async {
    const String hideLeaveWarningPreferenceKey =
        'standard_game_hide_leave_warning_v1';
    const String leaveWarningCountPreferenceKey =
        'standard_game_leave_warning_count_v1';

    final SharedPreferences preferences =
        await SharedPreferences.getInstance();

    final bool hideLeaveWarning =
        preferences.getBool(hideLeaveWarningPreferenceKey) ?? false;

    if (!mounted) {
      return;
    }

    if (hideLeaveWarning) {
      clueTimer?.cancel();
      messageTimer?.cancel();
      timeUpOverlayTimer?.cancel();
      surpriseToastTimer?.cancel();
      Navigator.of(context).pop();
      return;
    }

    final int warningCount =
        preferences.getInt(leaveWarningCountPreferenceKey) ?? 0;

    final bool showDontShowAgain = warningCount >= 1;

    await preferences.setInt(
      leaveWarningCountPreferenceKey,
      warningCount + 1,
    );

    if (!mounted) {
      return;
    }

    final bool? shouldLeave = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
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
                'LEAVE GAME?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Oswald',
                  color: AppColors.orange,
                  fontSize: 32,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 1.4,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: 96,
                height: 96,
                child: Image.asset(
                  'assets/images/stats/leave_game.png',
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.high,
                ),
              ),
            ],
          ),
          title: null,
          content: const Text(
            'Your progress in this game will be lost.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Inter',
              color: AppColors.white,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(
            24,
            0,
            24,
            22,
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 210,
                    height: 50,
                    child: FilledButton(
                      onPressed: () =>
                          Navigator.of(dialogContext).pop(false),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.orange,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'KEEP PLAYING',
                        style: TextStyle(
                          fontFamily: 'Oswald',
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.35,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: 210,
                    height: 46,
                    child: OutlinedButton(
                      onPressed: () =>
                          Navigator.of(dialogContext).pop(true),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(
                          color: AppColors.orange,
                          width: 1.5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'LEAVE GAME',
                        style: TextStyle(
                          fontFamily: 'Oswald',
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.35,
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
                          hideLeaveWarningPreferenceKey,
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

    if (shouldLeave == true && mounted) {
      clueTimer?.cancel();
      messageTimer?.cancel();
      timeUpOverlayTimer?.cancel();
      surpriseToastTimer?.cancel();
      Navigator.of(context).pop();
    }
  }

  Future<void> confirmReturnHome() async {
    const String hideLeaveWarningPreferenceKey =
        'standard_game_hide_leave_warning_v1';

    final SharedPreferences preferences =
        await SharedPreferences.getInstance();

    final bool hideLeaveWarning =
        preferences.getBool(hideLeaveWarningPreferenceKey) ?? false;

    if (!mounted) {
      return;
    }

    if (hideLeaveWarning) {
      clueTimer?.cancel();
      messageTimer?.cancel();
      timeUpOverlayTimer?.cancel();
      surpriseToastTimer?.cancel();
      Navigator.of(context).popUntil((route) => route.isFirst);
      return;
    }

    final bool? shouldReturnHome = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
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
                'RETURN HOME?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Oswald',
                  color: AppColors.orange,
                  fontSize: 32,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 1.4,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: 96,
                height: 96,
                child: Image.asset(
                  'assets/images/stats/leave_game.png',
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.high,
                ),
              ),
            ],
          ),
          title: null,
          content: const Text(
            'Your progress in this game will be lost.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Inter',
              color: AppColors.white,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(
            24,
            0,
            24,
            22,
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 210,
                    height: 50,
                    child: FilledButton(
                      onPressed: () =>
                          Navigator.of(dialogContext).pop(false),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.orange,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'KEEP PLAYING',
                        style: TextStyle(
                          fontFamily: 'Oswald',
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.35,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: 210,
                    height: 46,
                    child: OutlinedButton(
                      onPressed: () =>
                          Navigator.of(dialogContext).pop(true),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(
                          color: AppColors.orange,
                          width: 1.5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'RETURN HOME',
                        style: TextStyle(
                          fontFamily: 'Oswald',
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.35,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );

    if (shouldReturnHome == true && mounted) {
      clueTimer?.cancel();
      messageTimer?.cancel();
      timeUpOverlayTimer?.cancel();
      surpriseToastTimer?.cancel();
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  Widget buildGameScreen() {
    final String representativeCaseQuestionId =
        currentItem.id ?? widget.initialItem?.id ?? widget.items.first.id ?? '';
    final bool isRoundTheWorldCase =
        _countrySubcategoryFromQuestionId(representativeCaseQuestionId) != null;
    final bool isSecretsOfThePastCase =
        _pastPresentSubcategoryFromQuestionId(
              representativeCaseQuestionId,
            ) !=
            null;
    final bool isTasteAndTreatsCase =
        _foodDrinkSubcategoryFromQuestionId(
              representativeCaseQuestionId,
            ) !=
            null;

    final mission = activeCaseStage == null
        ? null
        : isRoundTheWorldCase
            ? CasePathService.roundTheWorldMissionForStage(
                activeCaseStage!,
              )
            : isSecretsOfThePastCase
                ? CasePathService.secretsOfThePastMissionForStage(
                    activeCaseStage!,
                  )
                : isTasteAndTreatsCase
                    ? CasePathService.tasteAndTreatsMissionForStage(
                        activeCaseStage!,
                      )
                    : CasePathService.animalKingdomMissionForStage(
                        activeCaseStage!,
                      );

    final String activeCaseName = isRoundTheWorldCase
        ? 'AROUND THE WORLD'
        : isSecretsOfThePastCase
            ? 'SECRETS OF THE PAST'
            : isTasteAndTreatsCase
                ? 'TASTES & TREATS'
                : 'ANIMAL KINGDOM';

    final double caseToolbarHeight = 56;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        toolbarHeight: widget.launchedFromCaseFile
            ? caseToolbarHeight
            : 102,
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.white,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(
            left: 16,
          ),
          child: IconButton(
            tooltip: 'Back',
            padding: EdgeInsets.zero,
            icon: const Icon(
              Icons.arrow_back_rounded,
              size: 28,
            ),
            onPressed: confirmLeaveGame,
          ),
        ),
        leadingWidth: 64,
        title: Text(
          widget.launchedFromCaseFile
              ? activeCaseStage != null
                  ? '$activeCaseName - CASE $activeCaseStage'
                  : '$activeCaseName - CASE'
              : widget.categoryName,
          maxLines: 1,
          style: TextStyle(
            fontFamily: 'Oswald',
            color: widget.launchedFromCaseFile
                ? AppColors.orange
                : AppColors.white,
            fontSize: widget.launchedFromCaseFile ? 18 : 18,
            fontWeight: widget.launchedFromCaseFile
                ? FontWeight.w800
                : FontWeight.w500,
            letterSpacing: 0.6,
          ),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(
              right: 16,
            ),
            child: FirstGuessHomeButton(
              onPressed: confirmReturnHome,
            ),
          ),
        ],
        bottom: widget.launchedFromCaseFile &&
                caseProgressLoaded &&
                mission != null
            ? PreferredSize(
                preferredSize: const Size.fromHeight(34),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 0, 8, 7),
                  child: SizedBox(
                    width: double.infinity,
                    child: _buildCaseObjectiveRows(mission),
                  ),
                ),
              )
            : null,
      ),
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                18,
                8,
                18,
                28,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 4),
                  StatsPanel(
                    totalScore:
                        statsLoaded ? playerStats.totalScore : 0,
                    currentStreak:
                        statsLoaded ? playerStats.currentStreak : 0,
                    firstGuesses:
                        statsLoaded ? playerStats.firstGuesses : 0,
                    gamesPlayed:
                        statsLoaded ? playerStats.gamesPlayed : 0,
                  ),
                  const SizedBox(height: 12),
                  buildGamePanel(),
                ],
              ),
            ),
            Positioned(
              top: 8,
              left: 10,
              right: 10,
              child: IgnorePointer(
                child: AnimatedSlide(
                  offset: showSurpriseToast
                      ? Offset.zero
                      : const Offset(0, -0.5),
                  duration: const Duration(
                    milliseconds: 250,
                  ),
                  curve: Curves.easeOut,
                  child: AnimatedOpacity(
                    opacity: showSurpriseToast ? 1 : 0,
                    duration:
                        _GameScreenState.surpriseToastFadeDuration,
                    child: _SurpriseChallengeBanner(
                      categoryName: widget.categoryName,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCaseObjectiveRows(dynamic mission) {
    final List<Widget> items = <Widget>[
      _buildCaseObjectiveInline(
        label: 'CORRECT',
        current: activeCaseCorrectCount,
        required: mission.correctRequired,
      ),
    ];

    if ((mission.clueThresholdRequired ?? 0) > 0 &&
        mission.clueThreshold != null) {
      items.add(_buildCaseObjectiveDivider());
      items.add(
        _buildCaseObjectiveInline(
          label: 'BY CLUE ${mission.clueThreshold}',
          current: activeCaseClueThresholdCount,
          required: mission.clueThresholdRequired!,
        ),
      );
    }

    if ((mission.firstGuessesRequired ?? 0) > 0) {
      items.add(_buildCaseObjectiveDivider());
      items.add(
        _buildCaseObjectiveInline(
          label: 'FIRST GUESSES',
          current: activeCaseFirstGuessCount,
          required: mission.firstGuessesRequired!,
        ),
      );
    }

    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.center,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: items,
      ),
    );
  }

  Widget _buildCaseObjectiveInline({
    required String label,
    required int current,
    required int required,
  }) {
    final int shownCurrent = current.clamp(0, required);
    final bool complete = current >= required;
    final Color rowColor = complete
        ? const Color(0xFF63D44A)
        : AppColors.white;

    return Text(
      '$label - $shownCurrent/$required',
      maxLines: 1,
      style: TextStyle(
        fontFamily: 'Oswald',
        color: rowColor,
        fontSize: 16,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.2,
      ),
    );
  }

  Widget _buildCaseObjectiveDivider() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 6),
      child: Text(
        '|',
        style: TextStyle(
          fontFamily: 'Oswald',
          color: AppColors.white,
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }


  Widget buildGamePanel() {
    return Stack(
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(
            10,
            8,
            10,
            10,
          ),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: AppColors.border,
              width: 1.3,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              buildClueHeaderBlock(),
              const SizedBox(height: 8),
              CluePanel(
                clue: currentItem.clues[currentClueIndex],
              ),
              buildGameMessage(),
              const SizedBox(height: 8),
              KeyedSubtree(
                key: ValueKey(
                  '${widget.gameType.name}-'
                  '${currentItem.imagePath}',
                ),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: buildVisualPanel(),
                      ),
                      if (isPracticeModeActive &&
                          !widget.launchedFromCaseFile)
                        const Positioned(
                          top: 10,
                          right: 10,
                          child: _PracticeModeRibbon(),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              GuessPanel(
                controller: guessController,
                focusNode: guessFocusNode,
                enabled:
                    !roundFinished &&
                    !showSurpriseToast &&
                    imageReady,
                isLastClue: isLastClue,
                onGuess: submitGuess,
                onNextClue: showNextClue,
                onGiveUp: giveUpRound,
              ),
            ],
          ),
        ),
        Positioned.fill(
          child: IgnorePointer(
            child: Center(
              child: AnimatedOpacity(
                opacity: showTimeUpOverlay ? 1 : 0,
                duration: const Duration(
                  milliseconds: 180,
                ),
                child: AnimatedScale(
                  scale: showTimeUpOverlay ? 1 : 0.9,
                  duration: const Duration(
                    milliseconds: 180,
                  ),
                  child: const SmallTimeUpOverlay(),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget buildVisualPanel() {
    final String visualImagePath =
        (currentItem.id?.startsWith('who_am_i_') ?? false)
            ? 'assets/images/categories/who_am_i/whoiam.webp'
            : currentItem.imagePath;

    if (!imageReady) {
      return Container(
        height: 282,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.panel,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: AppColors.orange,
            width: 1.8,
          ),
        ),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 36,
              height: 36,
              child: CircularProgressIndicator(
                color: AppColors.orange,
                strokeWidth: 3,
              ),
            ),
            SizedBox(height: 14),
            Text(
              'LOADING IMAGE…',
              style: TextStyle(
                fontFamily: 'Inter',
                color: AppColors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      );
    }

    if (widget.isFlagGame) {
      return RevealImagePanel(
        imagePath: visualImagePath,
        clueIndex: currentClueIndex,
        effect: RevealEffect.none,
        fit: BoxFit.contain,
      );
    }

    if (widget.isCapitalCitiesGame) {
      return RevealImagePanel(
        imagePath: visualImagePath,
        clueIndex: currentClueIndex,
        effect: RevealEffect.none,
        fit: BoxFit.cover,
      );
    }

    if (widget.isMajorCitiesGame) {
      return RevealImagePanel(
        imagePath: visualImagePath,
        clueIndex: currentClueIndex,
        effect: RevealEffect.none,
        fit: BoxFit.cover,
      );
    }

    if (widget.isCountrySilhouettesGame) {
      return SilhouettePanel(
        imagePath: visualImagePath,
        clueIndex: currentClueIndex,
      );
    }

    if (widget.isAuthorGame) {
      return RevealImagePanel(
        imagePath: visualImagePath,
        clueIndex: currentClueIndex,
        effect: RevealEffect.blur,
        fit: BoxFit.cover,
      );
    }

    return RevealImagePanel(
      imagePath: visualImagePath,
      clueIndex: currentClueIndex,
      effect: RevealEffect.none,
      fit: BoxFit.cover,
    );
  }

  Widget buildClueHeaderBlock() {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        10,
        8,
        10,
        8,
      ),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: const Color(0xFF444444),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'CLUE ${currentClueIndex + 1} / '
                      '${currentItem.clues.length}',
                      maxLines: 1,
                      style: const TextStyle(
                        fontFamily: 'Oswald',
                        color: AppColors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              LivesDisplay(
                lives: lives,
                maximumLives:
                    _GameScreenState.maximumLives,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: isPracticeModeActive
                        ? const Text(
                            '0 XP',
                            maxLines: 1,
                            style: TextStyle(
                              fontFamily: 'Oswald',
                              color: AppColors.orange,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          )
                        : currentClueIndex == 0
                            ? Text.rich(
                                const TextSpan(
                                  children: [
                                    TextSpan(
                                      text: '100 XP',
                                      style: TextStyle(
                                        fontFamily: 'Oswald',
                                        color: AppColors.white,
                                        fontSize: 11,
                                        fontWeight:
                                            FontWeight.w600,
                                      ),
                                    ),
                                    TextSpan(
                                      text: ' +50',
                                      style: TextStyle(
                                        fontFamily: 'Oswald',
                                        color: AppColors.orange,
                                        fontSize: 11,
                                        fontWeight:
                                            FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                                maxLines: 1,
                              )
                            : Text(
                                '$pointsAvailable PTS',
                                maxLines: 1,
                                style: const TextStyle(
                                  fontFamily: 'Oswald',
                                  color: AppColors.white,
                                  fontSize: 12,
                                  fontWeight:
                                      FontWeight.w600,
                                ),
                              ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          buildClueProgressSegments(),
          const SizedBox(height: 5),
          buildTimerSegments(),
        ],
      ),
    );
  }

  Widget buildClueProgressSegments() {
    final int clueCount =
        currentItem.clues.length;

    return Row(
      children: List.generate(
        clueCount,
        (index) {
          final bool reached =
              index <= currentClueIndex;

          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                right:
                    index == clueCount - 1 ? 0 : 3,
              ),
              child: Container(
                height: 5,
                decoration: BoxDecoration(
                  color: reached
                      ? AppColors.orange
                      : const Color(0xFF2C2C2C),
                  borderRadius:
                      BorderRadius.circular(3),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget buildTimerSegments() {
    final double safeProgress =
        timerProgress.clamp(0.0, 1.0);

    return ClipRRect(
      borderRadius: BorderRadius.circular(3),
      child: Container(
        height: 5,
        color: const Color(0xFF2C2C2C),
        alignment: Alignment.centerLeft,
        child: FractionallySizedBox(
          widthFactor: safeProgress,
          child: Container(
            color: AppColors.orange,
          ),
        ),
      ),
    );
  }

  Widget buildGameMessage() {
    return AnimatedSwitcher(
      duration: const Duration(
        milliseconds: 250,
      ),
      transitionBuilder: (
        Widget child,
        Animation<double> animation,
      ) {
        return FadeTransition(
          opacity: animation,
          child: SizeTransition(
            sizeFactor: animation,
            child: child,
          ),
        );
      },
      child: gameMessage == null
          ? const SizedBox(
              key: ValueKey('empty-message'),
            )
          : Padding(
              key: ValueKey(
                '${gameMessageType.name}-$gameMessage',
              ),
              padding: const EdgeInsets.only(
                top: 14,
              ),
              child: GameMessagePanel(
                message: gameMessage!,
                type: gameMessageType,
              ),
            ),
    );
  }
}

class _PracticeModeRibbon extends StatelessWidget {
  const _PracticeModeRibbon();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: AppColors.orange,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Colors.black54,
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: const Text(
        'PRACTICE MODE',
        maxLines: 1,
        style: TextStyle(
          fontFamily: 'Oswald',
          color: AppColors.white,
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.7,
        ),
      ),
    );
  }
}

class _SurpriseChallengeBanner extends StatelessWidget {
  final String categoryName;

  const _SurpriseChallengeBanner({
    required this.categoryName,
  });

  String get categoryImagePath {
    switch (categoryName) {
      case 'AUTHORS':
        return 'assets/images/categories/books_and_authors.png';
      case 'FLAGS':
        return 'assets/images/categories/countries.png';
      case 'COUNTRIES':
      default:
        return 'assets/images/categories/countries.png';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 560,
        ),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.panel,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: AppColors.border,
              width: 1.2,
            ),
            boxShadow: const [
              BoxShadow(
                color: Colors.black54,
                blurRadius: 18,
                spreadRadius: 2,
              ),
            ],
          ),
          child: LayoutBuilder(
            builder: (
              BuildContext context,
              BoxConstraints constraints,
            ) {
              final bool isVeryNarrow =
                  constraints.maxWidth < 360;

              return Row(
                children: [
                  Flexible(
                    flex: isVeryNarrow ? 5 : 6,
                    child: Container(
                      height: 48,
                      padding: EdgeInsets.symmetric(
                        horizontal:
                            isVeryNarrow ? 10 : 14,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.orange,
                        borderRadius:
                            BorderRadius.circular(28),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x66FE5E02),
                            blurRadius: 12,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize:
                            MainAxisSize.min,
                        children: [
                          Container(
                            width: 34,
                            height: 34,
                            alignment:
                                Alignment.center,
                            decoration: BoxDecoration(
                              color: Colors.black,
                              borderRadius:
                                  BorderRadius.circular(
                                11,
                              ),
                            ),
                            child: Image.asset(
                              'assets/images/stats/surprise_dice.png',
                              width: 28,
                              height: 28,
                              fit: BoxFit.contain,
                              filterQuality:
                                  FilterQuality.high,
                            ),
                          ),
                          SizedBox(
                            width:
                                isVeryNarrow ? 8 : 10,
                          ),
                          Flexible(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment:
                                  Alignment.centerLeft,
                              child: Text(
                                isVeryNarrow
                                    ? 'SURPRISE'
                                    : 'SURPRISE ME',
                                maxLines: 1,
                                style:
                                    const TextStyle(
                                  fontFamily: 'Inter',
                                  color:
                                      AppColors.white,
                                  fontSize: 14,
                                  fontWeight:
                                      FontWeight.w500,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ),
                          if (!isVeryNarrow) ...[
                            const SizedBox(width: 7),
                            const Icon(
                              Icons.auto_awesome,
                              color: AppColors.white,
                              size: 17,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    width: 1,
                    height: 36,
                    color: AppColors.border,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: isVeryNarrow ? 6 : 7,
                    child: Row(
                      children: [
                        SizedBox(
                          width: 30,
                          height: 30,
                          child: Image.asset(
                            categoryImagePath,
                            fit: BoxFit.contain,
                            filterQuality:
                                FilterQuality.high,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            mainAxisSize:
                                MainAxisSize.min,
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'NOW PLAYING',
                                maxLines: 1,
                                overflow:
                                    TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  color:
                                      AppColors.white,
                                  fontSize: 9,
                                  fontWeight:
                                      FontWeight.w500,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 1),
                              Text(
                                categoryName,
                                maxLines: 1,
                                overflow:
                                    TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontFamily: 'Oswald',
                                  color:
                                      AppColors.white,
                                  fontSize: 14,
                                  fontWeight:
                                      FontWeight.w500,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
