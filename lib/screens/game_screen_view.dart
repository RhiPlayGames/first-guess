part of 'game_screen.dart';

extension _GameScreenView on _GameScreenState {
  bool _useDesktopWebsiteLayout(BuildContext context) {
    const bool isWeb = bool.fromEnvironment('dart.library.js_interop');
    return isWeb && MediaQuery.sizeOf(context).width >= 1200;
  }

  // This is deliberately restricted to installed phone apps. Flutter web and
  // tablets retain their existing gameplay presentation.
  bool _useNativePhoneLayout(BuildContext context) {
    const bool isWeb = bool.fromEnvironment('dart.library.js_interop');
    final MediaQueryData media = MediaQuery.of(context);
    final TargetPlatform platform = Theme.of(context).platform;
    return !isWeb &&
        (platform == TargetPlatform.iOS ||
            platform == TargetPlatform.android) &&
        media.size.shortestSide < 600;
  }

  Future<void> confirmLeaveGame() async {
    if (_useNativePhoneLayout(context)) FocusScope.of(context).unfocus();
    const String hideLeaveWarningPreferenceKey =
        'standard_game_hide_leave_warning_v1';
    const String leaveWarningCountPreferenceKey =
        'standard_game_leave_warning_count_v1';

    final SharedPreferences preferences = await SharedPreferences.getInstance();

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

    await preferences.setInt(leaveWarningCountPreferenceKey, warningCount + 1);

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
            side: const BorderSide(color: AppColors.orange, width: 2),
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
            'Your progress on this question will be lost.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Inter',
              color: AppColors.white,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 22),
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
                      onPressed: () => Navigator.of(dialogContext).pop(false),
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
                      onPressed: () => Navigator.of(dialogContext).pop(true),
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
      if (widget.launchedFromCaseFile) {
        returnToCaseFilesHome(closeDialog: false);
      } else {
        Navigator.of(context).pop();
      }
    }
  }

  Future<void> confirmReturnHome() async {
    if (_useNativePhoneLayout(context)) FocusScope.of(context).unfocus();
    const String hideLeaveWarningPreferenceKey =
        'standard_game_hide_leave_warning_v1';

    final SharedPreferences preferences = await SharedPreferences.getInstance();

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
            side: const BorderSide(color: AppColors.orange, width: 2),
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
            'Your progress on this question will be lost.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Inter',
              color: AppColors.white,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 22),
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
                      onPressed: () => Navigator.of(dialogContext).pop(false),
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
                      onPressed: () => Navigator.of(dialogContext).pop(true),
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
      if (widget.launchedFromCaseFile) {
        returnToCaseFilesHome(closeDialog: false);
      } else {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    }
  }

  Widget buildGameScreen() {
    final String representativeCaseQuestionId =
        currentItem.id ?? widget.initialItem?.id ?? widget.items.first.id ?? '';
    final bool isFinalWhistleCase = _sportsSubcategoryFromQuestionId(representativeCaseQuestionId) != null;
    final bool isRoundTheWorldCase =
        _countrySubcategoryFromQuestionId(representativeCaseQuestionId) != null;
    final bool isSecretsOfThePastCase =
        _pastPresentSubcategoryFromQuestionId(representativeCaseQuestionId) !=
        null;
    final bool isTasteAndTreatsCase =
        _foodDrinkSubcategoryFromQuestionId(representativeCaseQuestionId) !=
        null;
    final bool isNatureOfDiscoveryCase =
        _scienceNatureSubcategoryFromQuestionId(representativeCaseQuestionId) !=
        null;
    final bool isTheWrittenWordCase =
        _booksAuthorsSubcategoryFromQuestionId(representativeCaseQuestionId) !=
        null;
    final bool isTheCreativeCodeCase =
        _creativeWorldSubcategoryFromQuestionId(representativeCaseQuestionId) !=
        null;

    final String currentCasePathId = isRoundTheWorldCase
        ? 'round_the_world'
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
        : isFinalWhistleCase
        ? 'final_whistle'
        : 'animal_kingdom';
    final displayMission = activeCaseStage == null
        ? null
        : CasePathService.originalMissionForDisplay(
            casePathId: currentCasePathId,
            stage: activeCaseStage!,
          );

    final double caseToolbarHeight = 56;
    final bool useDesktopWebsiteLayout = _useDesktopWebsiteLayout(context);
    final bool useNativePhoneLayout = _useNativePhoneLayout(context);
    final bool keyboardOpen =
        useNativePhoneLayout && MediaQuery.viewInsetsOf(context).bottom > 0;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        toolbarHeight: keyboardOpen
            ? 56
            : widget.launchedFromCaseFile
            ? caseToolbarHeight
            : useDesktopWebsiteLayout
            ? 70
            : useNativePhoneLayout
            ? 72
            : 92,
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.white,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16),
          child: IconButton(
            tooltip: 'Back',
            padding: EdgeInsets.zero,
            icon: const Icon(Icons.arrow_back_rounded, size: 28),
            onPressed: confirmLeaveGame,
          ),
        ),
        leadingWidth: 64,
        title: Text(
          widget.launchedFromCaseFile
              ? activeCaseStage != null
                    ? 'CASE $activeCaseStage'
                    : 'CASE FILE'
              : widget.launchedFromSurpriseMe
                  ? 'SURPRISE ME'
                  : _gameplayMainCategoryLabel,
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
            padding: const EdgeInsets.only(right: 16),
            child: FirstGuessHomeButton(onPressed: confirmReturnHome),
          ),
        ],
        bottom:
            widget.launchedFromCaseFile && caseProgressLoaded && displayMission != null
            ? PreferredSize(
                preferredSize: const Size.fromHeight(34),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 0, 8, 7),
                  child: SizedBox(
                    width: double.infinity,
                    child: _buildCaseObjectiveRows(displayMission),
                  ),
                ),
              )
            : null,
      ),
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                useDesktopWebsiteLayout
                    ? 28
                    : useNativePhoneLayout
                    ? 12
                    : keyboardOpen
                    ? 12
                    : 18,
                useNativePhoneLayout ? 5 : keyboardOpen ? 2 : 8,
                useDesktopWebsiteLayout
                    ? 28
                    : useNativePhoneLayout
                    ? 12
                    : keyboardOpen
                    ? 12
                    : 18,
                useNativePhoneLayout ? 14 : keyboardOpen ? 12 : 28,
              ),
              child: useNativePhoneLayout
                  ? buildNativePhoneGamePanel(keyboardOpen: keyboardOpen)
                  : useDesktopWebsiteLayout
                  ? Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1440),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const SizedBox(height: 0),
                            StatsPanel(
                              totalScore: statsLoaded
                                  ? playerStats.totalScore
                                  : 0,
                              currentStreak: statsLoaded
                                  ? playerStats.currentStreak
                                  : 0,
                              firstGuesses: statsLoaded
                                  ? playerStats.firstGuesses
                                  : 0,
                              gamesPlayed: statsLoaded
                                  ? playerStats.gamesPlayed
                                  : 0,
                            ),
                            const SizedBox(height: 12),
                            buildDesktopWebsiteGamePanel(),
                          ],
                        ),
                      ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 4),
                        StatsPanel(
                          totalScore: statsLoaded ? playerStats.totalScore : 0,
                          currentStreak: statsLoaded
                              ? playerStats.currentStreak
                              : 0,
                          firstGuesses: statsLoaded
                              ? playerStats.firstGuesses
                              : 0,
                          gamesPlayed: statsLoaded
                              ? playerStats.gamesPlayed
                              : 0,
                        ),
                        const SizedBox(height: 12),
                        buildGamePanel(),
                      ],
                    ),
            ),
            Positioned(
              top: 8,
              left: useDesktopWebsiteLayout
                  ? ((MediaQuery.sizeOf(context).width - 1440) / 2).clamp(
                      28.0,
                      double.infinity,
                    )
                  : 10,
              right: useDesktopWebsiteLayout ? null : 10,
              width: useDesktopWebsiteLayout ? 560 : null,
              child: IgnorePointer(
                child: AnimatedSlide(
                  offset: showSurpriseToast
                      ? Offset.zero
                      : const Offset(0, -0.5),
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOut,
                  child: AnimatedOpacity(
                    opacity: showSurpriseToast ? 1 : 0,
                    duration: _GameScreenState.surpriseToastFadeDuration,
                    child: _SurpriseChallengeBanner(
                      categoryName: widget.categoryName,
                      questionId: currentItem.id ?? '',
                      alignLeft: useDesktopWebsiteLayout,
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
      child: Row(mainAxisSize: MainAxisSize.min, children: items),
    );
  }

  Widget _buildCaseObjectiveInline({
    required String label,
    required int current,
    required int required,
  }) {
    final int shownCurrent = current.clamp(0, required);
    final bool complete = current >= required;
    final Color rowColor = complete ? const Color(0xFF63D44A) : AppColors.white;

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
          padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColors.border, width: 1.3),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              buildClueHeaderBlock(),
              const SizedBox(height: 8),
              CluePanel(clue: currentItem.clues[currentClueIndex]),
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
                      Positioned.fill(child: buildVisualPanel()),
                      if (isPracticeModeActive && !widget.launchedFromCaseFile)
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
                enabled: !roundFinished && !showSurpriseToast && imageReady,
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
                duration: const Duration(milliseconds: 180),
                child: AnimatedScale(
                  scale: showTimeUpOverlay ? 1 : 0.9,
                  duration: const Duration(milliseconds: 180),
                  child: const SmallTimeUpOverlay(),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Native phone layout: retain a stable TextField and button hierarchy while
  // keyboard insets change. Only the image size and spacing adapt.
  Widget buildNativePhoneGamePanel({required bool keyboardOpen}) {
    final bool canPlay = !roundFinished && !showSurpriseToast && imageReady;

    return Stack(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            buildClueHeaderBlock(),
            SizedBox(height: keyboardOpen ? 4 : 10),
            // The clue never moves below the image.
            CluePanel(clue: currentItem.clues[currentClueIndex]),
            SizedBox(height: keyboardOpen ? 7 : 10),
            LayoutBuilder(
              builder: (context, constraints) {
                // Daily Flash 5 Classic-style image / CTA composition.
                // Size the image explicitly rather than as a fraction of the
                // available width: percentage sizing produced the ~130 px
                // image on iPhone when the keyboard was visible.
                const double gap = 10;
                final double imageSide = keyboardOpen
                    ? ((constraints.maxWidth - gap) * 0.45).clamp(106.0, 164.0)
                    : ((constraints.maxWidth - gap) * 0.57).clamp(126.0, 205.0);
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: imageSide,
                      height: imageSide,
                      child: KeyedSubtree(
                        key: ValueKey(
                          'phone-${widget.gameType.name}-${currentItem.imagePath}',
                        ),
                        child: Stack(
                            children: [
                              Positioned.fill(
                                child: buildNativePhoneVisualPanel(),
                              ),
                              if (isPracticeModeActive && !widget.launchedFromCaseFile)
                                const Positioned(
                                  top: 8,
                                  right: 8,
                                  child: _PracticeModeRibbon(),
                                ),
                            ],
                        ),
                      ),
                    ),
                    const SizedBox(width: gap),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                           _keyboardSideButton(
                             label: 'NEXT CLUE',
                             enabled: canPlay && !isLastClue,
                             onPressed: showNextClue,
                           ),
                           SizedBox(height: keyboardOpen ? 10 : 20),
                           _keyboardSideButton(
                             label: 'GIVE UP',
                             enabled: canPlay,
                             onPressed: giveUpRound,
                             destructive: true,
                           ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
            buildGameMessage(),
            SizedBox(height: 7),
            // Never conditionally replace this TextField: iOS must retain
            // its first-responder connection as the keyboard opens.
            Container(
              height: 54,
              decoration: BoxDecoration(
                color: AppColors.panel,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.orange, width: 1.5),
              ),
              clipBehavior: Clip.antiAlias,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: guessController,
                      focusNode: guessFocusNode,
                      enabled: canPlay,
                      autofocus: false,
                      onSubmitted: (_) { if (canPlay) submitGuess(); },
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.done,
                      scrollPadding: const EdgeInsets.only(bottom: 120),
                      style: const TextStyle(fontFamily: 'Inter', color: AppColors.white, fontSize: 16),
                      decoration: const InputDecoration(
                        hintText: 'Type your guess...',
                        hintStyle: TextStyle(fontFamily: 'Inter', color: AppColors.white, fontSize: 16),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 15),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 126,
                    height: double.infinity,
                    child: FilledButton(
                      onPressed: canPlay ? () { FocusScope.of(context).unfocus(); submitGuess(); } : null,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFFE5E02),
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.zero,
                        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.only(topRight: Radius.circular(14), bottomRight: Radius.circular(14))),
                      ),
                      child: const Text('GUESS', style: TextStyle(fontFamily: 'Oswald', fontSize: 17, fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        Positioned.fill(
          child: IgnorePointer(
            child: Center(
              child: AnimatedOpacity(
                opacity: showTimeUpOverlay ? 1 : 0,
                duration: const Duration(milliseconds: 180),
                child: AnimatedScale(
                  scale: showTimeUpOverlay ? 1 : 0.9,
                  duration: const Duration(milliseconds: 180),
                  child: const SmallTimeUpOverlay(),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _keyboardSideButton({
    required String label,
    required bool enabled,
    required VoidCallback onPressed,
    bool destructive = false,
    bool guess = false,
  }) {
    final BorderRadius radius = BorderRadius.circular(12);
    final Widget text = FittedBox(
      fit: BoxFit.scaleDown,
      child: Text(label, maxLines: 1, style: const TextStyle(
        fontFamily: 'Oswald', fontSize: 18, fontWeight: FontWeight.w700,
      )),
    );
    return SizedBox(
      width: double.infinity,
      height: 43,
      child: guess || destructive
          ? FilledButton(
              onPressed: enabled ? onPressed : null,
              style: FilledButton.styleFrom(
                backgroundColor: guess ? const Color(0xFFFE5E02) : const Color(0xFFD32F2F),
                foregroundColor: AppColors.white,
                disabledBackgroundColor: AppColors.darkGrey,
                padding: const EdgeInsets.symmetric(horizontal: 4),
                shape: RoundedRectangleBorder(borderRadius: radius),
              ),
              child: text,
            )
          : OutlinedButton(
              onPressed: enabled ? onPressed : null,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.white,
                disabledForegroundColor: AppColors.darkGrey,
                side: BorderSide(color: enabled ? const Color(0xFF777777) : AppColors.darkGrey, width: 1.7),
                padding: const EdgeInsets.symmetric(horizontal: 4),
                shape: RoundedRectangleBorder(borderRadius: radius),
              ),
              child: text,
            ),
    );
  }

  Widget buildDesktopWebsiteGamePanel() {
    return Stack(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColors.border, width: 1.3),
          ),
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final double viewportHeight = MediaQuery.sizeOf(context).height;
              final double widthBasedVisual = constraints.maxWidth * 0.54;
              final double heightBasedVisual = viewportHeight - 245;
              final double visualWidth =
                  (widthBasedVisual < heightBasedVisual
                          ? widthBasedVisual
                          : heightBasedVisual)
                      .clamp(520.0, 680.0);

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: visualWidth,
                    child: KeyedSubtree(
                      key: ValueKey(
                        'desktop-${widget.gameType.name}-'
                        '${currentItem.imagePath}',
                      ),
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: Stack(
                          children: [
                            Positioned.fill(child: buildVisualPanel()),
                            if (isPracticeModeActive &&
                                !widget.launchedFromCaseFile)
                              const Positioned(
                                top: 12,
                                right: 12,
                                child: _PracticeModeRibbon(),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        buildClueHeaderBlock(),
                        const SizedBox(height: 10),
                        CluePanel(clue: currentItem.clues[currentClueIndex]),
                        buildGameMessage(),
                        const SizedBox(height: 22),
                        Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 660),
                            child: GuessPanel(
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
        Positioned.fill(
          child: IgnorePointer(
            child: Center(
              child: AnimatedOpacity(
                opacity: showTimeUpOverlay ? 1 : 0,
                duration: const Duration(milliseconds: 180),
                child: AnimatedScale(
                  scale: showTimeUpOverlay ? 1 : 0.9,
                  duration: const Duration(milliseconds: 180),
                  child: const SmallTimeUpOverlay(),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // On installed phones, a clear Classic image should fill its square in
  // the same way as Daily Flash 5. Retain the existing reveal widget for
  // categories that need special reveal/blur/silhouette behaviour.
  Widget buildNativePhoneVisualPanel() {
    if (!imageReady ||
        widget.isFlagGame ||
        widget.isCountrySilhouettesGame ||
        widget.isAuthorGame) {
      return buildVisualPanel();
    }

    final String path = currentItem.imagePath;
    final Uri? uri = Uri.tryParse(path);
    final bool remote = uri != null &&
        (uri.scheme == 'https' || uri.scheme == 'http');
    // Paint the outline *over* the image, not behind its clipped pixels.
    // The outer dimensions remain controlled by the existing parent SizedBox.
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image(
            image: remote ? NetworkImage(path) : AssetImage(path),
            fit: BoxFit.cover,
            filterQuality: FilterQuality.high,
            gaplessPlayback: true,
            errorBuilder: (context, error, stackTrace) {
              debugPrint('CLASSIC IMAGE FAILED: $path — $error');
              return buildVisualPanel();
            },
          ),
          IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.orange, width: 1.8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildVisualPanel({bool containImage = false}) {
    final String visualImagePath = currentItem.imagePath;

    if (!imageReady) {
      return Container(
        height: 282,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.panel,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.orange, width: 1.8),
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
        fit: containImage ? BoxFit.contain : BoxFit.cover,
      );
    }

    if (widget.isMajorCitiesGame) {
      return RevealImagePanel(
        imagePath: visualImagePath,
        clueIndex: currentClueIndex,
        effect: RevealEffect.none,
        fit: containImage ? BoxFit.contain : BoxFit.cover,
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
        fit: containImage ? BoxFit.contain : BoxFit.cover,
      );
    }

    return RevealImagePanel(
      imagePath: visualImagePath,
      clueIndex: currentClueIndex,
      effect: RevealEffect.none,
      fit: containImage ? BoxFit.contain : BoxFit.cover,
    );
  }

  Widget buildClueHeaderBlock() {
    // The phone layout mirrors Daily Flash Classic's two-row status panel;
    // the classic game still uses its own clue count, lives and scoring.
    final bool phone = _useNativePhoneLayout(context);
    if (!phone) {
      return _buildLegacyClueHeaderBlock();
    }
    final bool firstGuessBonus = currentClueIndex == 0 && guessesThisRound == 0;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 9, 12, 9),
      decoration: BoxDecoration(
        color: AppColors.panel,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border, width: 1.2),
      ),
      child: Column(
        children: [
          Row(children: [
            Expanded(child: FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft,
              child: Text(widget.launchedFromCaseFile
                  ? _gameplayMainCategoryLabel
                  : _gameplaySubcategoryLabel,
              style: const TextStyle(fontFamily: 'Oswald', fontSize: 19,
                fontWeight: FontWeight.w700, color: AppColors.white)))),
            LivesDisplay(lives: lives, maximumLives: _GameScreenState.maximumLives),
          ]),
          if (widget.launchedFromCaseFile) ...[
            const SizedBox(height: 3),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                _gameplaySubcategoryLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontFamily: 'Oswald', fontSize: 14,
                  fontWeight: FontWeight.w500, color: AppColors.orange),
              ),
            ),
          ],
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: Text('CLUE ${currentClueIndex + 1} OF ${currentItem.clues.length}',
              style: const TextStyle(fontFamily: 'Oswald', fontSize: 16,
                fontWeight: FontWeight.w600, color: AppColors.white))),
            Text.rich(TextSpan(children: [
              TextSpan(text: isPracticeModeActive ? '0 XP' : '$pointsAvailable XP',
                style: const TextStyle(fontFamily: 'Oswald', fontSize: 16,
                    fontWeight: FontWeight.w700, color: AppColors.white)),
              if (firstGuessBonus && !isPracticeModeActive)
                const TextSpan(text: ' +50', style: TextStyle(fontFamily: 'Oswald',
                  fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.orange)),
            ])),
          ]),
        ],
      ),
    );
  }

  Widget _buildLegacyClueHeaderBlock() {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFF444444), width: 1),
      ),
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              widget.launchedFromCaseFile
                  ? _gameplayMainCategoryLabel
                  : _gameplaySubcategoryLabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontFamily: 'Oswald', fontSize: 17,
                  fontWeight: FontWeight.w700, color: AppColors.white),
            ),
          ),
          if (widget.launchedFromCaseFile)
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                _gameplaySubcategoryLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontFamily: 'Oswald', fontSize: 13,
                    color: AppColors.orange),
              ),
            ),
          const SizedBox(height: 5),
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
                      style: TextStyle(
                        fontFamily: 'Oswald',
                        color: AppColors.white,
                        fontSize: _useNativePhoneLayout(context) ? 14 : 12,
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
                maximumLives: _GameScreenState.maximumLives,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: isPracticeModeActive
                        ? Text(
                            '0 XP',
                            maxLines: 1,
                            style: TextStyle(
                              fontFamily: 'Oswald',
                              color: AppColors.orange,
                              fontSize: _useNativePhoneLayout(context) ? 14 : 12,
                              fontWeight: FontWeight.w700,
                            ),
                          )
                        : currentClueIndex == 0
                        ? Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text: '100 XP',
                                  style: TextStyle(
                                    fontFamily: 'Oswald',
                                    color: AppColors.white,
                                    fontSize: _useNativePhoneLayout(context) ? 13 : 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                TextSpan(
                                  text: ' +50',
                                  style: TextStyle(
                                    fontFamily: 'Oswald',
                                    color: AppColors.orange,
                                    fontSize: _useNativePhoneLayout(context) ? 13 : 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                            maxLines: 1,
                          )
                        : Text(
                            '$pointsAvailable PTS',
                            maxLines: 1,
                            style: TextStyle(
                              fontFamily: 'Oswald',
                              color: AppColors.white,
                              fontSize: _useNativePhoneLayout(context) ? 14 : 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          buildClueProgressSegments(),
        ],
      ),
    );
  }

  Widget buildClueProgressSegments() {
    final int clueCount = currentItem.clues.length;

    return Row(
      children: List.generate(clueCount, (index) {
        final bool reached = index <= currentClueIndex;

        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: index == clueCount - 1 ? 0 : 3),
            child: Container(
              height: 5,
              decoration: BoxDecoration(
                color: reached ? AppColors.orange : const Color(0xFF2C2C2C),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget buildGameMessage() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      transitionBuilder: (Widget child, Animation<double> animation) {
        return FadeTransition(
          opacity: animation,
          child: SizeTransition(sizeFactor: animation, child: child),
        );
      },
      child: gameMessage == null
          ? const SizedBox(key: ValueKey('empty-message'))
          : Padding(
              key: ValueKey('${gameMessageType.name}-$gameMessage'),
              padding: const EdgeInsets.only(top: 14),
              child: GameMessagePanel(
                message: gameMessage!,
                type: gameMessageType,
              ),
            ),
    );
  }
  String _caseFileQuestionPoolLabel(String key) {
    final String normalized = key.trim().toLowerCase().replaceAll('_', ' ');
    const labels = <String, String>{
      'ancient civilisations empires': 'ANCIENT CIVILISATIONS & EMPIRES',
      'artists': 'ARTISTS',
      'battles wars': 'BATTLES & WARS',
      'biology': 'BIOLOGY',
      'book series': 'BOOK SERIES',
      'breakfast': 'BREAKFAST FOODS',
      'capitals': 'CAPITAL CITIES',
      'castles ruins': 'CASTLES & RUINS',
      'chemistry': 'CHEMISTRY',
      'childrens books': 'CHILDREN’S BOOKS',
      'club teams': 'CLUB TEAMS',
      'country silhouettes': 'COUNTRY SILHOUETTES',
      'crafts pottery ceramics': 'CRAFTS, POTTERY & CERAMICS',
      'currencies': 'CURRENCIES',
      'desserts cakes sweets': 'DESSERTS, CAKES & SWEETS',
      'dishes world cuisine': 'DISHES & WORLD CUISINES',
      'drinks': 'WORLD DRINKS',
      'english football': 'ENGLISH FOOTBALL',
      'fashion': 'FASHION',
      'fictional literary locations': 'FICTIONAL LITERARY LOCATIONS',
      'flags': 'FLAGS',
      'folk tales fairy tales': 'FOLK TALES & FAIRY TALES',
      'football world cups': 'FOOTBALL WORLD CUPS',
      'fruit vegs': 'FRUIT & VEGETABLES',
      'herbs spices': 'HERBS AND SPICES',
      'historic objects': 'HISTORICAL OBJECTS',
      'historical events': 'HISTORICAL EVENTS',
      'human body': 'THE HUMAN BODY',
      'inventions': 'INVENTIONS',
      'literary genres': 'LITERARY GENRES',
      'major cities': 'MAJOR CITIES',
      'museums galleries': 'MUSEUMS & GALLERIES',
      'myths legends': 'MYTHS & LEGENDS',
      'natural wonders landscapes': 'NATURAL WONDERS & LANDSCAPES',
      'non english football': 'NON-ENGLISH FOOTBALL',
      'olympic sports': 'OLYMPIC SPORTS',
      'opening lines quotations': 'OPENING LINES & QUOTATIONS',
      'periodic table': 'PERIODIC TABLE',
      'physics': 'PHYSICS',
      'plays': 'PLAYS',
      'poems': 'POEMS',
      'records achievements': 'RECORDS & ACHIEVEMENTS',
      'rocks minerals volcanoes': 'ROCKS, MINERALS & VOLCANOES',
      'scientific discoveries experiments theories': 'SCIENTIFIC DISCOVERIES, EXPERIMENTS & THEORIES',
      'space astronomy': 'SPACE & ASTRONOMY',
      'sporting events': 'SPORTING EVENTS',
      'stadiums venues': 'STADIUMS & VENUES',
      'states regions': 'STATES & REGIONS',
      'theatre': 'THEATRE',
      'animals (mixed)': 'ANIMALS (GENERAL)',
      'animals': 'ANIMALS (GENERAL)',
      'food drink (mixed)': 'FOOD & DRINK (GENERAL)',
      'food drink': 'FOOD & DRINK (GENERAL)',
      'past present (mixed)': 'PAST & PRESENT (GENERAL)',
      'past present': 'PAST & PRESENT (GENERAL)',
      'science nature (mixed)': 'SCIENCE & NATURE (GENERAL)',
      'books authors (mixed)': 'BOOKS & AUTHORS (GENERAL)',
      'creative world (mixed)': 'CREATIVE WORLD (GENERAL)',
      'countries (mixed)': 'COUNTRIES (GENERAL)',
      'national_symbols': 'NATIONAL SYMBOLS',
      'national symbols': 'NATIONAL SYMBOLS',
      'safari jungle animals': 'JUNGLE & SAFARI ANIMALS',
      'sports (mixed)': 'SPORTS (GENERAL)',
      'snacks street food': 'SNACKS & STREET FOODS',
      'snacks street foods': 'SNACKS & STREET FOODS',
      'jungle safari animals': 'JUNGLE & SAFARI ANIMALS',
      'habitats animal groups': 'HABITATS & ANIMAL GROUPS',
      'insects spiders': 'INSECTS & SPIDERS',
      'reptiles amphibians': 'REPTILES & AMPHIBIANS',
      'books novels': 'BOOKS & NOVELS',
      'authors poets playwrights': 'AUTHORS, POETS & PLAYWRIGHTS',
      'computers internet': 'COMPUTERS & THE INTERNET',
      'medicine health': 'MEDICINE & HEALTH',
      'plants trees': 'PLANTS & TREES',
      'paintings sculptures': 'PAINTINGS & SCULPTURES',
      'architecture architects': 'ARCHITECTURE & ARCHITECTS',
    };
    return labels[normalized] ?? normalized.toUpperCase();
  }
}

class _PracticeModeRibbon extends StatelessWidget {
  const _PracticeModeRibbon();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.orange,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: Colors.black54, blurRadius: 8, offset: Offset(0, 3)),
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
  final String questionId;
  final bool alignLeft;

  const _SurpriseChallengeBanner({
    required this.categoryName,
    required this.questionId,
    this.alignLeft = false,
  });

  String get nowPlayingName {
    if (categoryName != 'SURPRISE ME') {
      return categoryName;
    }

    String id = questionId.toLowerCase().trim();

    const List<String> categoryPrefixes = <String>[
      'country_',
      'countries_',
      'animals_',
      'science_nature_',
      'watch_play_',
      'music_',
      'sports_',
      'who_am_i_',
      'famous_people_',
      'books_authors_',
      'past_present_',
      'food_drink_',
      'creative_world_',
    ];

    for (final String prefix in categoryPrefixes) {
      if (id.startsWith(prefix)) {
        id = id.substring(prefix.length);
        break;
      }
    }

    id = id.replaceFirst(RegExp(r'_\d+$'), '');
    id = id.replaceFirst(RegExp(r'\s+\d+$'), '');

    const Map<String, String> friendlyLabels = <String, String>{
      'actors_directors': 'ACTORS & DIRECTORS',
      'ancient_civilisations_empires': 'ANCIENT CIVILISATIONS & EMPIRES',
      'animation_cartoons_anime': 'ANIMATION, CARTOONS & ANIME',
      'architecture_architects': 'ARCHITECTURE & ARCHITECTS',
      'artists': 'ARTISTS',
      'athletes_sports': 'ATHLETES & SPORTS STARS',
      'authors_poets_playwrights': 'AUTHORS, POETS & PLAYWRIGHTS',
      'authors_writers': 'AUTHORS, POETS & PLAYWRIGHTS',
      'bands_1960_1969': 'BANDS: 1960-1969',
      'bands_1970_1979': 'BANDS: 1970-1979',
      'bands_1980_1989': 'BANDS: 1980-1989',
      'bands_1990_1999': 'BANDS: 1990-1999',
      'bands_2000_2009': 'BANDS: 2000-2009',
      'bands_2010_2019': 'BANDS: 2010-2019',
      'bands_2020_2026': 'BANDS: 2020-2026',
      'bands_pre_1960': 'BANDS: PRE-1960',
      'battles_wars': 'BATTLES & WARS',
      'biology': 'BIOLOGY',
      'birds': 'BIRDS',
      'book_series': 'BOOK SERIES',
      'books_literature': 'BOOKS & LITERATURE',
      'books_novels': 'BOOKS & NOVELS',
      'breakfast': 'BREAKFAST FOODS',
      'campaigners_humanitarians': 'CAMPAIGNERS & HUMANITARIANS',
      'capitals': 'CAPITAL CITIES',
      'castles_ruins': 'CASTLES & RUINS',
      'chemistry': 'CHEMISTRY',
      'childrens_books': 'CHILDREN’S BOOKS',
      'club_teams': 'CLUB TEAMS',
      'composers': 'COMPOSERS',
      'computers_internet': 'COMPUTERS & THE INTERNET',
      'consoles_gaming_franchises': 'CONSOLES & GAMING FRANCHISES',
      'country_silhouettes': 'COUNTRY SILHOUETTES',
      'crafts_pottery_ceramics': 'CRAFTS, POTTERY & CERAMICS',
      'currencies': 'CURRENCIES',
      'desserts_cakes_sweets': 'DESSERTS, CAKES & SWEETS',
      'dinosaurs': 'DINOSAURS',
      'dishes_world_cuisine': 'DISHES & WORLD CUISINES',
      'drinks': 'WORLD DRINKS',
      'english_football': 'ENGLISH FOOTBALL',
      'entrepreneurs_business': 'ENTREPRENEURS & BUSINESS LEADERS',
      'explorers_adventurers': 'EXPLORERS & ADVENTURERS',
      'famous_people': 'FAMOUS PEOPLE',
      'fashion': 'FASHION',
      'fictional_literary_locations': 'FICTIONAL LITERARY LOCATIONS',
      'fictional_screen_locations': 'FICTIONAL SCREEN LOCATIONS',
      'flags': 'FLAGS',
      'folk_tales_fairy_tales': 'FOLK TALES & FAIRY TALES',
      'football_world_cups': 'FOOTBALL WORLD CUPS',
      'footballers': 'FOOTBALLERS',
      'fruit_vegs': 'FRUIT & VEGETABLES',
      'furniture_jewellery': 'FURNITURE & JEWELLERY',
      'graphic_novels_comics': 'GRAPHIC NOVELS & COMICS',
      'habitats_animal_groups': 'HABITATS & ANIMAL GROUPS',
      'herbs_spices': 'HERBS & SPICES',
      'historic_objects': 'HISTORICAL OBJECTS',
      'historical_events': 'HISTORICAL EVENTS',
      'historical_objects': 'HISTORICAL OBJECTS',
      'history_speeches': 'HISTORY & SPEECHES',
      'human_body': 'THE HUMAN BODY',
      'insects_spiders': 'INSECTS & SPIDERS',
      'instruments': 'INSTRUMENTS',
      'inventions': 'INVENTIONS',
      'jungle_safari_animals': 'JUNGLE & SAFARI ANIMALS',
      'literary_genres': 'LITERARY GENRES',
      'major_cities': 'MAJOR CITIES',
      'mammals': 'MAMMALS',
      'movie_monsters_villains': 'MOVIE MONSTERS & VILLAINS',
      'movies_film_franchises': 'MOVIES & MOVIES FRANCHISES',
      'movies_television': 'MOVIES & TELEVISION',
      'museums_galleries': 'MUSEUMS & GALLERIES',
      'music_genres': 'MUSIC GENRES',
      'musicians_singers': 'MUSICIANS & SINGERS',
      'myths_legends': 'MYTHS & LEGENDS',
      'national_symbols': 'NATIONAL SYMBOLS',
      'natural_wonders_landscapes': 'NATURAL WONDERS & LANDSCAPES',
      'non_english_football': 'NON-ENGLISH FOOTBALL',
      'olympic_sports': 'OLYMPIC SPORTS',
      'opening_lines_quotations': 'OPENING LINES & QUOTATIONS',
      'paintings_sculptures': 'PAINTINGS & SCULPTURES',
      'periodic_table': 'PERIODIC TABLE',
      'physics': 'PHYSICS',
      'pioneers_records': 'PIONEERS & RECORD BREAKERS',
      'plants_trees': 'PLANTS & TREES',
      'plays': 'PLAYS',
      'poems': 'POEMS',
      'public_internet': 'PUBLIC & INTERNET PERSONALITIES',
      'records_achievements': 'RECORDS & ACHIEVEMENTS',
      'reptiles_amphibians': 'REPTILES & AMPHIBIANS',
      'rocks_minerals_volcanoes': 'ROCKS, MINERALS & VOLCANOES',
      'royalty_leaders': 'ROYALTY & POLITICAL LEADERS',
      'scientific_discoveries_experiments_theories':
          'SCIENTIFIC DISCOVERIES, EXPERIMENTS & THEORIES',
      'scientists_inventors': 'SCIENTISTS & INVENTORS',
      'screen_characters': 'SCREEN CHARACTERS',
      'sea_creatures': 'SEA CREATURES',
      'snacks_street_food': 'SNACKS',
      'solo_artists_1960_1969': 'SOLO ARTISTS: 1960-1969',
      'solo_artists_1970_1979': 'SOLO ARTISTS: 1970-1979',
      'solo_artists_1980_1989': 'SOLO ARTISTS: 1980-1989',
      'solo_artists_1990_1999': 'SOLO ARTISTS: 1990-1999',
      'solo_artists_2000_2009': 'SOLO ARTISTS: 2000-2009',
      'solo_artists_2010_2019': 'SOLO ARTISTS: 2010-2019',
      'solo_artists_2020_2026': 'SOLO ARTISTS: 2020-2026',
      'solo_artists_pre_1960': 'SOLO ARTISTS: PRE-1960',
      'space_astronomy': 'SPACE & ASTRONOMY',
      'sporting_events': 'SPORTING EVENTS',
      'stadiums_venues': 'STADIUMS & VENUES',
      'states_regions': 'STATES & REGIONS',
      'television_streaming_programmes': 'TELEVISION & STREAMING PROGRAMMES',
      'theatre': 'THEATRE',
      'toys_games': 'TOYS & GAMES',
      'toys_traditional_games': 'TOYS & GAMES',
      'tracks_footprints': 'TRACKS & FOOTPRINTS',
      'video_games_gaming_characters': 'GAMING CHARACTERS',
    };

    final String? friendly = friendlyLabels[id];
    if (friendly != null) {
      return friendly;
    }

    if (id.isEmpty) {
      return 'SURPRISE ME';
    }

    return id.replaceAll('_', ' ').toUpperCase();
  }

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
    final bool isDesktop = MediaQuery.sizeOf(context).width >= 1200;

    return Align(
      alignment: alignLeft ? Alignment.centerLeft : Alignment.center,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.panel,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColors.border, width: 1.2),
            boxShadow: const [
              BoxShadow(color: Colors.black54, blurRadius: 18, spreadRadius: 2),
            ],
          ),
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final bool isVeryNarrow = constraints.maxWidth < 360;

              return Row(
                children: [
                  Flexible(
                    flex: isVeryNarrow ? 5 : 6,
                    child: Container(
                      height: 48,
                      padding: EdgeInsets.symmetric(
                        horizontal: isVeryNarrow ? 10 : 14,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.orange,
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x66FE5E02),
                            blurRadius: 12,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 34,
                            height: 34,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: Colors.black,
                              borderRadius: BorderRadius.circular(11),
                            ),
                            child: Image.asset(
                              'assets/images/stats/surprise_dice.png',
                              width: 28,
                              height: 28,
                              fit: BoxFit.contain,
                              filterQuality: FilterQuality.high,
                            ),
                          ),
                          SizedBox(width: isVeryNarrow ? 8 : 10),
                          Flexible(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                isVeryNarrow ? 'SURPRISE' : 'SURPRISE ME',
                                maxLines: 1,
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  color: AppColors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
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
                  Container(width: 1, height: 36, color: AppColors.border),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: isVeryNarrow ? 6 : 7,
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                nowPlayingName,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontFamily: 'Oswald',
                                  color: AppColors.white,
                                  fontSize: isDesktop ? 24 : 16,
                                  fontWeight: FontWeight.w500,
                                  height: 1.0,
                                  letterSpacing: 0.2,
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
