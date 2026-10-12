import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../services/content_consumption_service.dart';
import '../services/firebase_challenge_service.dart';
import '../services/player_stats_service.dart';
import '../theme/app_colors.dart';

class FirstPickGameScreen extends StatefulWidget {
  const FirstPickGameScreen({super.key});

  @override
  State<FirstPickGameScreen> createState() => _FirstPickGameScreenState();
}

class _PickQuestion {
  const _PickQuestion(this.id, this.category, this.question, this.options,
      this.correctIndex, this.explanation);
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
  int? _picked;
  bool _finished = false;
  DateTime _startedAt = DateTime.now();

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
    return _PickQuestion(doc.id, (data['subcategory'] ?? '').toString(),
        question, answers, answerIndex,
        (data['explanation'] ?? '').toString());
  }

  Future<void> _init() async {
    try {
      final docs = await FirebaseChallengeService.loadLiveCategoryDocuments(category: 'first_pick');
      final questions = docs.map(_parse).whereType<_PickQuestion>().toList();
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
    } catch (e) {
      if (!mounted) return;
      setState(() { _loading = false; _error = 'Could not load First Pick questions. Please try again.'; });
    }
  }

  void _next() {
    final pool = _questions.where((q) => _practice
        ? !_seenThisSession.contains(q.id)
        : !_playedIds.contains(q.id)).toList();
    if (pool.isEmpty && _practice && _questions.isNotEmpty) {
      _seenThisSession.clear();
      _next();
      return;
    }
    if (pool.isEmpty) {
      setState(() { _current = null; _finished = false; });
      return;
    }
    final question = pool[_random.nextInt(pool.length)];
    _seenThisSession.add(question.id);
    setState(() {
      _current = question;
      _attempts = 0;
      _wrongOptions.clear();
      _picked = null;
      _finished = false;
      _submitting = false;
      _startedAt = DateTime.now();
    });
  }

  Future<void> _pick(int index) async {
    final question = _current;
    if (question == null || _finished || _submitting || _wrongOptions.contains(index)) return;
    final attempt = index == -1 ? 3 : _attempts + 1;
    final correct = index == question.correctIndex;
    final finished = correct || attempt == 3;
    setState(() {
      _attempts = attempt;
      _picked = index;
      if (!correct) _wrongOptions.add(index);
      _finished = finished;
      _submitting = finished;
    });
    if (!finished) return;
    try {
      if (!_practice) {
        // Mark completed regardless of outcome so no XP can be farmed by replay.
        await QuestionHistoryService.recordPlayedQuestion(question.id);
        await ContentConsumptionService.recordQuestionCompleted(
          gameKey: 'first_pick', category: 'first_pick',
          subcategory: question.category, questionId: question.id,
          totalQuestionsAvailable: _questions.length,
        );
        final seconds = DateTime.now().difference(_startedAt).inSeconds;
        final updated = correct
            ? await PlayerStatsService.recordCorrectGame(
                currentStats: _stats, category: GameCategory.other,
                pointsWon: const [100, 60, 30][attempt - 1],
                clueNumber: attempt, wasFirstGuess: attempt == 1,
                playTimeSeconds: seconds, mainCategoryKey: 'first_pick')
            : await PlayerStatsService.recordFailedGame(
                currentStats: _stats, playTimeSeconds: seconds,
                mainCategoryKey: 'first_pick');
        if (mounted) setState(() { _stats = updated; _playedIds.add(question.id); });
      }
    } catch (e) {
      // Don't silently award duplicate score after a persistence failure.
      if (mounted) setState(() => _error = 'Progress could not be saved. Please check your connection before continuing.');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final q = _current;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(backgroundColor: AppColors.background,
        title: const Text('FIRST PICK', style: TextStyle(fontFamily: 'Oswald'))),
      body: SafeArea(child: Center(child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null && q == null
            ? Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text(_error!, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                FilledButton(onPressed: _init, child: const Text('RETRY'))])
            : q == null
              ? Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text(_questions.isEmpty ? 'No First Pick questions are live yet.' :
                      'You have completed all ${_questions.length} First Pick questions!',
                      textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  if (_questions.isNotEmpty) FilledButton(
                    onPressed: () { setState(() => _practice = true); _next(); },
                    child: const Text('PRACTICE (0 XP)')),
                ])
              : SingleChildScrollView(padding: const EdgeInsets.all(18), child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(q.category.replaceAll('_',' ').toUpperCase(),
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Color(0xFFFE5E02), fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(_practice ? 'PRACTICE · 0 XP' :
                        'Attempt ${(_attempts + 1).clamp(1, 3)} of 3 · ${const [100,60,30][_attempts < 3 ? _attempts : 2]} XP available',
                        textAlign: TextAlign.center),
                    const SizedBox(height: 20),
                    Text(q.question, textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 20),
                    for (var i = 0; i < 6; i++) Padding(
                      padding: const EdgeInsets.only(bottom: 9),
                      child: OutlinedButton(
                        onPressed: _finished || _wrongOptions.contains(i) ? null : () => _pick(i),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
                          side: BorderSide(color: _finished && i == q.correctIndex
                              ? Colors.green : _wrongOptions.contains(i) ? Colors.red :
                                  const Color(0xFFFE5E02)),
                          foregroundColor: Colors.white),
                        child: Row(children: [
                          Text('${String.fromCharCode(65+i)}.  '),
                          Expanded(child: Text(q.options[i])),
                          if (_finished && i == q.correctIndex) const Icon(Icons.check, color: Colors.green),
                        ]),
                      ),
                    ),
                    if (_finished) ...[
                      const SizedBox(height: 8),
                      Text(_picked == q.correctIndex ? 'CORRECT!' : 'OUT OF TRIES',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text(q.explanation, textAlign: TextAlign.center),
                      const SizedBox(height: 12),
                      if (_error != null) Text(_error!, style: const TextStyle(color: Colors.red)),
                      FilledButton(onPressed: _submitting || _error != null ? null : _next,
                          child: const Text('NEXT QUESTION')),
                    ] else ...[
                      Text('${3 - _attempts} tries remaining', textAlign: TextAlign.center),
                      TextButton(onPressed: () => _pick(-1), child: const Text('GIVE UP', style: TextStyle(color: Colors.red))),
                    ],
                  ],
                )),
      ))),
    );
  }
}
