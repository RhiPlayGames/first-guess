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
import '../widgets/milestone_reached_dialog.dart';
import '../services/player_stats_service.dart';
import '../theme/app_colors.dart';

class FirstPickGameScreen extends StatefulWidget {
  const FirstPickGameScreen({
    super.key,
    required this.subcategory,
    required this.categoryTitle,
  });

  final String? subcategory;
  final String categoryTitle;

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
  final Random _random = Random();
  final Set<String> _seenThisSession = {};
  List<_PickQuestion> _questions = [];
  Set<String> _playedIds = {};
  _PickQuestion? _current;
  PlayerStats _stats = const PlayerStats();
  bool _loading = true;
  bool _submitting = false;
  bool _practice = false;
  String? _error;
  int _attempts = 0;
  final Set<int> _wrongOptions = {};
  bool _finished = false;
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

  _PickQuestion? _parse(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    final options = data['options'];
    if (options is! List || options.length != 6) return null;
    final answers = options.map((e) => e.toString().trim()).toList();
    if (answers.any((e) => e.isEmpty)) return null;
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

  void _next() {
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
    setState(() {
      _attempts = attempt;
      if (!correct) _wrongOptions.add(index);
      _finished = finished;
      _submitting = finished;
    });
    if (!finished) {
      _showTemporaryMessage('INCORRECT — ${3 - attempt} ${3 - attempt == 1 ? 'LIFE' : 'LIVES'} LEFT');
      return;
    }
    final PlayerStats previousStats = _stats;
    PlayerStats? updatedStats;
    try {
      if (!_practice) {
        // Mark completed regardless of outcome so no XP can be farmed by replay.
        await QuestionHistoryService.recordPlayedQuestion(question.id);
        await ContentConsumptionService.recordQuestionCompleted(
          gameKey: 'first_pick',
          category: 'first_pick',
          subcategory: question.category,
          questionId: question.id,
          totalQuestionsAvailable: 1000,
        );
        final seconds = DateTime.now().difference(_startedAt).inSeconds;
        final updated = correct
            ? await PlayerStatsService.recordCorrectGame(
                currentStats: _stats,
                category: GameCategory.other,
                pointsWon: const [100, 60, 30][attempt - 1],
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
            _playedIds.add(question.id);
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
      Navigator.of(context).popUntil((route) => route.isFirst);
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
    final xp = correct && !_practice ? const [100, 60, 30][attempt - 1] : 0;
    return showGameResultDialog(
      context: context,
      title: correct ? (attempt == 1 ? 'FIRST GUESS!' : 'CORRECT!') : 'GAME OVER',
      message: correct
          ? '${question.options[question.correctIndex]}\n\n${_practice ? 'PRACTICE MODE — 0 XP' : '$xp XP'}${question.explanation.isEmpty ? '' : '\n\n${question.explanation}'}'
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
      primaryButtonLabel: 'NEXT QUESTION',
      secondaryButtonLabel: 'BACK TO HOME',
    );
  }

  Widget _optionTile(_PickQuestion q, int index) {
    final wrong = _wrongOptions.contains(index);
    final right = _finished && index == q.correctIndex;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: _finished || _submitting || wrong ? null : () => _pick(index),
        borderRadius: BorderRadius.circular(15),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          constraints: const BoxConstraints(minHeight: 54),
          decoration: BoxDecoration(
            color: right ? const Color(0xFF12311D) : const Color(0xFF191919),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: right ? const Color(0xFF3CB963) : wrong ? const Color(0xFFD32F2F) : AppColors.orange,
              width: right || wrong ? 2 : 1.2,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(children: [
              Expanded(child: Text(q.options[index], textAlign: TextAlign.center,
                style: TextStyle(fontFamily: 'Inter', fontSize: 16,
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
          child: Text('FIRST PICK', style: TextStyle(
            fontFamily: 'Oswald', fontSize: isDesktop ? 28 : 24,
            fontWeight: FontWeight.w600,
          )),
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
                              : 'You have completed all available First Pick questions in ${widget.categoryTitle}!',
                              textAlign: TextAlign.center),
                          const SizedBox(height: 16),
                          if (_questions.isNotEmpty)
                            FilledButton(onPressed: () {setState(() => _practice = true); _next();},
                              child: const Text('PRACTICE (0 XP)')),
                        ]),
                      ))
                    : SingleChildScrollView(
                        padding: EdgeInsets.fromLTRB(isDesktop ? 32 : 16, 6, isDesktop ? 32 : 16, 28),
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
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(15),
                                  color: AppColors.background,
                                  border: Border.all(color: const Color(0xFF444444)),
                                ),
                                child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                                  Flexible(child: Text(widget.categoryTitle.toUpperCase(),
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontFamily: 'Oswald', fontSize: 16, color: AppColors.orange))),
                                  Text('${3 - _attempts} ${3 - _attempts == 1 ? 'LIFE' : 'LIVES'} LEFT',
                                    style: const TextStyle(fontFamily: 'Oswald', fontSize: 15)),
                                ]),
                              ),
                              const SizedBox(height: 16),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(18),
                                decoration: BoxDecoration(
                                  color: AppColors.panel,
                                  border: Border.all(color: AppColors.orange, width: 1.3),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Text(q.question, textAlign: TextAlign.center,
                                  style: const TextStyle(fontFamily: 'Oswald', fontSize: 23,
                                    fontWeight: FontWeight.w600, color: AppColors.white)),
                              ),
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 250),
                                child: _message == null
                                    ? const SizedBox(key: ValueKey('pick-empty'))
                                    : Padding(
                                        key: ValueKey(_message),
                                        padding: const EdgeInsets.only(top: 14),
                                        child: GameMessagePanel(message: _message!, type: GameMessageType.error),
                                      ),
                              ),
                              const SizedBox(height: 16),
                              for (int i = 0; i < q.options.length; i++) _optionTile(q, i),
                              const SizedBox(height: 8),
                              if (_error != null) Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Text(_error!, style: const TextStyle(color: Color(0xFFD32F2F))),
                              ),
                              SizedBox(height: 48, child: FilledButton(
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
