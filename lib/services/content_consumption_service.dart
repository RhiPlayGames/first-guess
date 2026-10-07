import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'analytics_service.dart';

class ContentConsumptionSnapshot {
  final String gameKey;
  final String category;
  final String subcategory;
  final int uniqueQuestionsCompleted;
  final int totalQuestionsAvailable;

  const ContentConsumptionSnapshot({
    required this.gameKey,
    required this.category,
    required this.subcategory,
    required this.uniqueQuestionsCompleted,
    required this.totalQuestionsAvailable,
  });

  int get remainingQuestions {
    final int remaining =
        totalQuestionsAvailable - uniqueQuestionsCompleted;
    return remaining < 0 ? 0 : remaining;
  }

  int get saturationPercent {
    if (totalQuestionsAvailable <= 0) {
      return 0;
    }

    return ((uniqueQuestionsCompleted * 100) /
            totalQuestionsAvailable)
        .round()
        .clamp(0, 100);
  }

  bool get isExhausted =>
      totalQuestionsAvailable > 0 &&
      uniqueQuestionsCompleted >= totalQuestionsAvailable;
}

class ContentConsumptionService {
  ContentConsumptionService._();

  static final FirebaseAuth _auth =
      FirebaseAuth.instance;

  static final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  static String _safeSegment(String value) {
    final String normalised = value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');

    return normalised.isEmpty ? 'none' : normalised;
  }

  static String progressDocumentId({
    required String gameKey,
    required String category,
    required String subcategory,
  }) {
    return 'content_${_safeSegment(gameKey)}'
        '__${_safeSegment(category)}'
        '__${_safeSegment(subcategory)}';
  }

  static DocumentReference<Map<String, dynamic>>?
      _progressDocument({
    required String gameKey,
    required String category,
    required String subcategory,
  }) {
    final User? user = _auth.currentUser;

    if (user == null) {
      return null;
    }

    return _firestore
        .collection('players')
        .doc(user.uid)
        .collection('progress')
        .doc(
          progressDocumentId(
            gameKey: gameKey,
            category: category,
            subcategory: subcategory,
          ),
        );
  }

  static Set<String> _questionIdsFromData(
    Map<String, dynamic>? data,
  ) {
    final dynamic raw = data?['completedQuestionIds'];

    if (raw is! List) {
      return <String>{};
    }

    return raw
        .whereType<String>()
        .map((String value) => value.trim())
        .where((String value) => value.isNotEmpty)
        .toSet();
  }

  static Future<ContentConsumptionSnapshot>
      recordQuestionCompleted({
    required String gameKey,
    required String category,
    required String subcategory,
    required String questionId,
    required int totalQuestionsAvailable,
  }) async {
    final String safeQuestionId = questionId.trim();

    if (safeQuestionId.isEmpty) {
      throw ArgumentError.value(
        questionId,
        'questionId',
        'Question ID must not be empty.',
      );
    }

    if (totalQuestionsAvailable < 0) {
      throw ArgumentError.value(
        totalQuestionsAvailable,
        'totalQuestionsAvailable',
        'Total questions cannot be negative.',
      );
    }

    final DocumentReference<Map<String, dynamic>>?
        document = _progressDocument(
      gameKey: gameKey,
      category: category,
      subcategory: subcategory,
    );

    if (document == null) {
      return ContentConsumptionSnapshot(
        gameKey: gameKey,
        category: category,
        subcategory: subcategory,
        uniqueQuestionsCompleted: 0,
        totalQuestionsAvailable: totalQuestionsAvailable,
      );
    }

    final ContentConsumptionSnapshot snapshot =
        await _firestore.runTransaction<
            ContentConsumptionSnapshot>(
      (Transaction transaction) async {
        final DocumentSnapshot<Map<String, dynamic>>
            existing = await transaction.get(document);

        final Set<String> completedIds =
            _questionIdsFromData(existing.data());

        completedIds.add(safeQuestionId);

        final int completedCount = completedIds.length;

        transaction.set(
          document,
          <String, Object>{
            'schemaVersion': 1,
            'gameKey': gameKey,
            'category': category,
            'subcategory': subcategory,
            'completedQuestionIds':
                completedIds.toList()..sort(),
            'uniqueQuestionsCompleted': completedCount,
            'totalQuestionsAvailable':
                totalQuestionsAvailable,
            'saturationPercent':
                totalQuestionsAvailable <= 0
                    ? 0
                    : ((completedCount * 100) /
                            totalQuestionsAvailable)
                        .round()
                        .clamp(0, 100),
            'updatedAt':
                FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );

        return ContentConsumptionSnapshot(
          gameKey: gameKey,
          category: category,
          subcategory: subcategory,
          uniqueQuestionsCompleted: completedCount,
          totalQuestionsAvailable:
              totalQuestionsAvailable,
        );
      },
    );

    await AnalyticsService.logContentProgressSnapshot(
      gameKey: snapshot.gameKey,
      category: snapshot.category,
      subcategory: snapshot.subcategory,
      uniqueQuestionsCompleted:
          snapshot.uniqueQuestionsCompleted,
      totalQuestionsAvailable:
          snapshot.totalQuestionsAvailable,
    );

    return snapshot;
  }

  static Future<ContentConsumptionSnapshot> loadProgress({
    required String gameKey,
    required String category,
    required String subcategory,
    required int totalQuestionsAvailable,
  }) async {
    final DocumentReference<Map<String, dynamic>>?
        document = _progressDocument(
      gameKey: gameKey,
      category: category,
      subcategory: subcategory,
    );

    if (document == null) {
      return ContentConsumptionSnapshot(
        gameKey: gameKey,
        category: category,
        subcategory: subcategory,
        uniqueQuestionsCompleted: 0,
        totalQuestionsAvailable: totalQuestionsAvailable,
      );
    }

    final DocumentSnapshot<Map<String, dynamic>>
        snapshot = await document.get();

    final Set<String> completedIds =
        _questionIdsFromData(snapshot.data());

    return ContentConsumptionSnapshot(
      gameKey: gameKey,
      category: category,
      subcategory: subcategory,
      uniqueQuestionsCompleted: completedIds.length,
      totalQuestionsAvailable: totalQuestionsAvailable,
    );
  }
}
