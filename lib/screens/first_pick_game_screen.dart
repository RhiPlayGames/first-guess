import '../services/sound_effects_service.dart';
import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import '../services/content_consumption_service.dart';
import '../services/achievement_service.dart';
import '../widgets/game_dialogs.dart';
import '../widgets/app_home_button.dart';
import '../widgets/stats_panel.dart';
import '../widgets/lives_display.dart';
import '../widgets/milestone_reached_dialog.dart';
import '../services/player_stats_service.dart';
import '../theme/app_colors.dart';
import '../daily_flash/services/daily_flash_game_progress_service.dart';

class FirstPickGameScreen extends StatefulWidget {
  const FirstPickGameScreen({
    super.key,
    required this.subcategory,
    required this.categoryTitle,
    this.dailyFlash = false,
    this.onChallengeFinished,
  });

  final String? subcategory;
  final String categoryTitle;
  final bool dailyFlash;
  final VoidCallback? onChallengeFinished;

  @override
  State<FirstPickGameScreen> createState() => _FirstPickGameScreenState();
}

class _PickQuestion {
  const _PickQuestion(
    this.id,
    this.category,
    this.question,
    this.options,
    this.correctIndex,
    this.explanation,
  );
  final String id;
  final String category;
  final String question;
  final List<String> options;
  final int correctIndex;
  final String explanation;
}

class _FirstPickGameScreenState extends State<FirstPickGameScreen> {
  static const List<int> _baseXpByAttempt = <int>[50, 30, 20];
  static const int _firstGuessBonusXp = 25;

  static int _earnedXpForAttempt(int attempt) =>
      _baseXpByAttempt[attempt - 1] +
      (attempt == 1 ? _firstGuessBonusXp : 0);

  final Random _random = Random();
  final Set<String> _seenThisSession = {};
  List<_PickQuestion> _questions = [];
  Set<String> _playedIds = {};
  _PickQuestion? _current;
  PlayerStats _stats = const PlayerStats();
  DailyFlashGameProgress? _dailyProgress;
  int _dailyQuestionIndex = 0;
  bool _loading = true;
  bool _submitting = false;
  bool _practice = false;
  String? _error;
  int _attempts = 0;
  final Set<int> _wrongOptions = {};
  bool _finished = false;
  bool _lastPickWasCorrect = false;
  String? _message;
  Timer? _messageTimer;
  DateTime _startedAt = DateTime.now();

  @override
  void dispose() {
    _messageTimer?.cancel();
    super.dispose();
  }

  void _showTemporaryMessage(String message) {
    _messageTimer?.cancel();
    if (!mounted) return;
    setState(() => _message = message);
    _messageTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _message = null);
    });
  }

  @override
  void initState() {
    super.initState();
    _init();
  }

  _PickQuestion? _parse(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    if (data == null) return null;
    final dynamic rawOptions = data['options'];
    final options = rawOptions is List
        ? rawOptions
        : [for (final letter in 'ABCDEF'.split('')) data['option$letter']];
    if (options.length != 6) return null;
    final answers = options.map((e) => e.toString().trim()).toList();
    if (answers.any((e) => e.isEmpty || e == 'null')) return null;
    final key = (data['correctOption'] ?? '').toString().toUpperCase();
    if (!'ABCDEF'.contains(key) || key.length != 1) return null;
    final answerIndex = key.codeUnitAt(0) - 65;
    if (answers[answerIndex].toLowerCase() !=
        (data['correctAnswer'] ?? '').toString().trim().toLowerCase()) {
      return null;
    }
    final question = (data['question'] ?? '').toString().trim();
    if (question.isEmpty) return null;
    return _PickQuestion(
      doc.id,
      (data['subcategory'] ?? '').toString(),
      question,
      answers,
      answerIndex,
      (data['explanation'] ?? '').toString(),
    );
  }

  Future<void> _init() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      if (widget.dailyFlash) {
        await _initDailyFlash();
        return;
      }
      debugPrint(
        '[FIRST PICK] project=${Firebase.app().options.projectId} subcategory=${widget.subcategory}',
      );
      // The category-only query avoids requiring a composite index, and
      // the server source prevents a stale local cache from hiding questions.
      final QuerySnapshot<Map<String, dynamic>> serverSnapshot =
          await FirebaseFirestore.instance
              .collection('challenges')
              .where('category', isEqualTo: 'first_pick')
              .get(const GetOptions(source: Source.server));
      final liveDocs = serverSnapshot.docs
          .where((doc) => (doc.data()['status'] ?? '').toString() == 'live')
          .toList();
      final selectedDocs = liveDocs
          .where(
            (doc) =>
                widget.subcategory == null ||
                (doc.data()['subcategory'] ?? '').toString() == widget.subcategory,
          )
          .toList();
      final questions = selectedDocs
          .map(_parse)
          .whereType<_PickQuestion>()
          .toList();
      debugPrint(
        '[FIRST PICK] server category=${serverSnapshot.docs.length} live=${liveDocs.length} selected=${selectedDocs.length} parsed=${questions.length}',
      );
      final played = await QuestionHistoryService.loadPlayedQuestionIds();
      final stats = await PlayerStatsService.loadStats();
      if (!mounted) return;
      setState(() {
        _questions = questions;
        _playedIds = played;
        _stats = stats;
        _loading = false;
        _error = null;
      });
      _next();
    } on FirebaseException catch (e, st) {
      debugPrint(
        '[FIRST PICK] Firebase error code=${e.code} message=${e.message}',
      );
      debugPrintStack(stackTrace: st);
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Could not load First Pick (${e.code}). Please try again.';
      });
    } catch (e, st) {
      debugPrint('[FIRST PICK] loading error: $e');
      debugPrintStack(stackTrace: st);
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Could not load First Pick questions. Please try again.';
      });
    }
  }


  Future<void> _initDailyFlash() async {
    final progress = await DailyFlashGameProgressService.loadToday(
      gameKey: 'first_pick',
    );
    final dateKey = progress.dateKey.replaceAll('-', '');
    final docs = await Future.wait([
      for (int i = 1; i <= 5; i++)
        FirebaseFirestore.instance
            .collection('daily_flash_questions')
            .doc('df_first_pick_${dateKey}_${i.toString().padLeft(2, '0')}')
            .get(const GetOptions(source: Source.server)),
    ]);
    final questions = docs.map(_parse).whereType<_PickQuestion>().toList();
    if (!mounted) return;
    if (questions.length != 5) {
      setState(() {
        _loading = false;
        _error = 'Today’s five First Pick questions are not yet available.';
      });
      return;
    }
    final stats = await PlayerStatsService.loadStats();
    if (!mounted) return;
    setState(() {
      _questions = questions;
      _dailyProgress = progress;
      _dailyQuestionIndex = progress.nextQuestionIndex;
      _stats = stats;
      _loading = false;
    });
    _next();
  }

  void _next() {
    if (widget.dailyFlash) {
      final index = _dailyProgress?.nextQuestionIndex ?? 0;
      setState(() {
        _dailyQuestionIndex = index;
        _current = index < _questions.length ? _questions[index] : null;
        _attempts = 0;
        _wrongOptions.clear();
        _finished = false;
        _lastPickWasCorrect = false;
        _submitting = false;
        _message = null;
        _error = null;
        _startedAt = DateTime.now();
      });
      if (index >= 5) widget.onChallengeFinished?.call();
      return;
    }
    final pool = _questions
        .where(
          (q) => _practice
              ? !_seenThisSession.contains(q.id)
              : !_playedIds.contains(q.id),
        )
        .toList();
    if (pool.isEmpty && _practice && _questions.isNotEmpty) {
      _seenThisSession.clear();
      _next();
      return;
    }
    if (pool.isEmpty) {
      setState(() {
        _current = null;
        _finished = false;
      });
      return;
    }
    final question = pool[_random.nextInt(pool.length)];
    _seenThisSession.add(question.id);
    setState(() {
      _current = question;
      _attempts = 0;
      _wrongOptions.clear();
      _finished = false;
      _lastPickWasCorrect = false;
      _submitting = false;
      _message = null;
      _error = null;
      _startedAt = DateTime.now();
    });
  }

  Future<void> _pick(int index) async {
    final question = _current;
    if (question == null ||
        _finished ||
        _submitting ||
        _wrongOptions.contains(index)) {
      return;
    }
    final attempt = index == -1 ? 3 : _attempts + 1;
    final correct = index == question.correctIndex;
    final finished = correct || attempt == 3;
    if (index >= 0) {
      if (correct) {
        SoundEffectsService.correct();
      } else {
        SoundEffectsService.incorrect();
      }
    }
    setState(() {
      _attempts = attempt;
      if (!correct) _wrongOptions.add(index);
      _finished = finished;
      _lastPickWasCorrect = correct;
      _submitting = finished;
    });
    if (!finished) {
      _showTemporaryMessage('INCORRECT — ${3 - attempt} ${3 - attempt == 1 ? 'LIFE' : 'LIVES'} LEFT');
      return;
    }
    final PlayerStats previousStats = _stats;
    PlayerStats? updatedStats;
    try {
      if (widget.dailyFlash) {
        final progress = _dailyProgress;
        if (progress == null) throw StateError('Daily Flash progress unavailable');
        final xp = correct ? _earnedXpForAttempt(attempt) * 2 : 0;
        final updatedProgress = await DailyFlashGameProgressService.recordResult(
          gameKey: 'first_pick',
          progress: progress,
          questionIndex: _dailyQuestionIndex,
          correct: correct,
          xpEarned: xp,
          wasFirstGuess: correct && attempt == 1,
        );
        if (mounted) setState(() => _dailyProgress = updatedProgress);
      }
      if (!_practice) {
        // Mark completed regardless of outcome so no XP can be farmed by replay.
        if (!widget.dailyFlash) {
          await QuestionHistoryService.recordPlayedQuestion(question.id);
          await ContentConsumptionService.recordQuestionCompleted(
          gameKey: 'first_pick',
          category: 'first_pick',
          subcategory: question.category,
          questionId: question.id,
          totalQuestionsAvailable: 1000,
          );
        }
        final seconds = DateTime.now().difference(_startedAt).inSeconds;
        final updated = correct
            ? await PlayerStatsService.recordCorrectGame(
                currentStats: _stats,
                category: GameCategory.other,
                pointsWon: _earnedXpForAttempt(attempt) * (widget.dailyFlash ? 2 : 1),
                clueNumber: attempt,
                wasFirstGuess: attempt == 1,
                playTimeSeconds: seconds,
                mainCategoryKey: 'first_pick',
              )
            : await PlayerStatsService.recordFailedGame(
                currentStats: _stats,
                playTimeSeconds: seconds,
                mainCategoryKey: 'first_pick',
              );
        updatedStats = updated;
        if (mounted) {
          setState(() {
            _stats = updated;
            if (!widget.dailyFlash) _playedIds.add(question.id);
          });
        }
      }
    } catch (e) {
      // Don't silently award duplicate score after a persistence failure.
      if (mounted) {
        setState(
          () => _error =
              'Progress could not be saved. Please check your connection before continuing.',
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
    if (!mounted || _error != null) return;
    await _showResult(
      question: question,
      correct: correct,
      attempt: attempt,
      previousStats: _practice ? null : previousStats,
      updatedStats: updatedStats,
    );
  }

  Future<void> _showRewards(PlayerStats previous, PlayerStats current) async {
    final badges = AchievementService.newlyEarnedBadges(
      previous: previous, current: current,
      gameKey: 'first_pick', gameLabel: 'First Pick',
    );
    for (final badge in badges) {
      if (!mounted) return;
      await showDialog<void>(
        context: context, barrierDismissible: false,
        builder: (_) => BadgeEarnedDialog(
          badgeName: badge.name, imageAsset: badge.imageAsset,
        ),
      );
    }
    final achievements = AchievementService.popupAchievementsForGame(
      previous: previous,
      current: current,
      gameCategory: AchievementCategory.firstPick,
    );
    for (final achievement in achievements) {
      if (!mounted) return;
      final next = AchievementService.nextMilestoneAfter(achievement);
      await showDialog<void>(
        context: context, barrierDismissible: false,
        builder: (_) => MilestoneReachedDialog(
          milestone: MilestonePopupData(
            target: achievement.target,
            label: AchievementService.milestoneLabelFor(achievement),
            nextTarget: next?.target,
            nextLabel: next == null ? null : AchievementService.milestoneLabelFor(next),
          ),
        ),
      );
    }
  }

  Future<void> _afterResult({
    required bool goHome,
    PlayerStats? previousStats,
    PlayerStats? updatedStats,
  }) async {
    Navigator.of(context).pop();
    if (previousStats != null && updatedStats != null) {
      await _showRewards(previousStats, updatedStats);
    }
    if (!mounted) return;
    if (goHome) {
      if (widget.dailyFlash) widget.onChallengeFinished?.call();
      if (widget.dailyFlash) {
        Navigator.of(context).maybePop();
      } else {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } else if (widget.dailyFlash && (_dailyProgress?.allQuestionsAttempted ?? false)) {
      widget.onChallengeFinished?.call();
      Navigator.of(context).maybePop();
    } else {
      _next();
    }
  }

  Future<void> _showResult({
    required _PickQuestion question,
    required bool correct,
    required int attempt,
    PlayerStats? previousStats,
    PlayerStats? updatedStats,
  }) async {
    if (!mounted) return;
    final xp = correct && !_practice ? _earnedXpForAttempt(attempt) * (widget.dailyFlash ? 2 : 1) : 0;
    return showGameResultDialog(
      context: context,
      title: correct ? (attempt == 1 ? 'FIRST GUESS!' : 'CORRECT!') : 'GAME OVER',
      message: correct
          ? 'You identified ${question.options[question.correctIndex].toUpperCase()}\n\n${_practice ? 'PRACTICE MODE — 0 XP' : attempt == 1 ? (widget.dailyFlash ? '100 XP\n50 XP First Guess Bonus\n\n150 XP TOTAL' : '50 XP\n25 XP First Guess Bonus\n\n75 XP TOTAL') : '$xp XP'}'
          : 'The answer was ${question.options[question.correctIndex]}.',
      onPlayAgain: () => unawaited(_afterResult(
        goHome: false,
        previousStats: previousStats,
        updatedStats: updatedStats,
      )),
      onHome: () => unawaited(_afterResult(
        goHome: true,
        previousStats: previousStats,
        updatedStats: updatedStats,
      )),
      primaryButtonLabel: widget.dailyFlash && (_dailyProgress?.allQuestionsAttempted ?? false) ? 'FINISH DAILY FLASH' : 'NEXT QUESTION',
      secondaryButtonLabel: 'HOME',
    );
  }

  Widget _optionTile(_PickQuestion q, int index) {
    final wrong = _wrongOptions.contains(index);
    final right = _finished && _lastPickWasCorrect && index == q.correctIndex;
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: InkWell(
        onTap: _finished || _submitting || wrong ? null : () => _pick(index),
        borderRadius: BorderRadius.circular(15),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          constraints: const BoxConstraints(minHeight: 58),
          decoration: BoxDecoration(
            color: right ? const Color(0xFF12311D) : const Color(0xFF191919),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: right ? const Color(0xFF3CB963) : AppColors.orange,
              width: right || wrong ? 2 : 1.2,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            child: Row(children: [
              Expanded(child: Text(q.options[index], textAlign: TextAlign.center,
                style: TextStyle(fontFamily: 'Inter', fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: wrong ? AppColors.grey : AppColors.white))),
              if (wrong) const Icon(Icons.close_rounded, color: Color(0xFFD32F2F))
              else if (right) const Icon(Icons.check_rounded, color: Color(0xFF3CB963)),
            ]),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final q = _current;
    final size = MediaQuery.sizeOf(context);
    final isDesktop = size.width >= 900;
    final framed = size.width >= 600;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.white,
        elevation: 0,
        centerTitle: true,
        toolbarHeight: isDesktop ? 80 : 72,
        title: GestureDetector(
          onTap: () => Navigator.of(context).popUntil((route) => route.isFirst),
          child: SizedBox(
            height: isDesktop ? 76 : 64,
            child: Image.asset(
              'assets/images/categories/category_headers/first_pick_logo.webp',
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
            ),
          ),
        ),
        actions: [Padding(
          padding: const EdgeInsets.only(right: 16),
          child: FirstGuessHomeButton(onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst)),
        )],
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: AppColors.orange))
            : _error != null && q == null
                ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Text(_error!, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    FilledButton(onPressed: _init, child: const Text('RETRY')),
                  ]))
                : q == null
                    ? Center(child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(mainAxisSize: MainAxisSize.min, children: [
                          Text(_questions.isEmpty
                              ? 'No live First Pick questions found.'
                              : widget.dailyFlash ? 'FIRST PICK COMPLETE!\n${_dailyProgress?.questionsCorrect ?? 0}/5 correct\n${_dailyProgress?.totalXp ?? 0} XP earned today' : 'You have completed all available First Pick questions in ${widget.categoryTitle}!',
                              textAlign: TextAlign.center),
                          const SizedBox(height: 16),
                          if (_questions.isNotEmpty && !widget.dailyFlash)
                            FilledButton(onPressed: () {setState(() => _practice = true); _next();},
                              child: const Text('PRACTICE (0 XP)')),
                        ]),
                      ))
                    : SingleChildScrollView(
                        padding: EdgeInsets.fromLTRB(isDesktop ? 32 : 8, 4, isDesktop ? 32 : 8, 16),
                        child: Center(child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 880),
                          child: Container(
                            padding: framed ? const EdgeInsets.all(14) : EdgeInsets.zero,
                            decoration: framed ? BoxDecoration(
                              color: AppColors.background,
                              border: Border.all(color: AppColors.border, width: 1.3),
                              borderRadius: BorderRadius.circular(22),
                            ) : null,
                            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                              StatsPanel(
                                totalScore: _stats.totalScore,
                                currentStreak: _stats.currentStreak,
                                firstGuesses: _stats.firstGuesses,
                                gamesPlayed: _stats.gamesPlayed,
                                showWebBorder: false,
                              ),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(15),
                                  color: AppColors.background,
                                  border: Border.all(color: const Color(0xFF444444)),
                                ),
                                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                                  Expanded(child: Text('PICK ${(_attempts + 1).clamp(1, 3)} / 3',
                                    style: const TextStyle(fontFamily: 'Oswald', fontSize: 14))),
                                  LivesDisplay(lives: (3 - _attempts).clamp(0, 3), maximumLives: 3),
                                  const SizedBox(width: 10),
                                  Expanded(child: Text('${_practice ? 0 : _baseXpByAttempt[(_attempts).clamp(0, 2)] * (widget.dailyFlash ? 2 : 1)} XP${!_practice && _attempts == 0 ? (widget.dailyFlash ? ' +50' : ' +25') : ''}',
                                    textAlign: TextAlign.end, style: const TextStyle(fontFamily: 'Oswald', fontSize: 14))),
                                ]),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                                decoration: BoxDecoration(
                                  color: AppColors.panel,
                                  border: Border.all(color: AppColors.orange, width: 1.3),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Text(q.question, textAlign: TextAlign.center,
                                  style: const TextStyle(fontFamily: 'Oswald', fontSize: 18,
                                    fontWeight: FontWeight.w600, color: AppColors.white)),
                              ),
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 250),
                                child: _message == null
                                    ? const SizedBox(key: ValueKey('pick-empty'))
                                    : Padding(
                                        key: ValueKey(_message),
                                        padding: const EdgeInsets.only(top: 8),
                                        child: GameMessagePanel(message: _message!, type: GameMessageType.error),
                                      ),
                              ),
                              const SizedBox(height: 8),
                              for (int i = 0; i < q.options.length; i++) _optionTile(q, i),
                              const SizedBox(height: 4),
                              if (_error != null) Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Text(_error!, style: const TextStyle(color: Color(0xFFD32F2F))),
                              ),
                              SizedBox(height: 44, child: FilledButton(
                                onPressed: _finished || _submitting ? null : () => _pick(-1),
                                style: FilledButton.styleFrom(
                                  backgroundColor: const Color(0xFFD32F2F),
                                  foregroundColor: AppColors.white,
                                  disabledBackgroundColor: AppColors.darkGrey,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                ),
                                child: const Text('GIVE UP', style: TextStyle(
                                  fontFamily: 'Oswald', fontSize: 16, fontWeight: FontWeight.w600)),
                              )),
                            ]),
                          ),
                        )),
                      ),
      ),
    );
  }
}
