import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../models/quiz_item.dart';

class FirebaseChallengeSubcategory {
  const FirebaseChallengeSubcategory({
    required this.category,
    required this.subcategory,
    required this.items,
  });

  final String category;
  final String subcategory;
  final List<QuizItem> items;
}

class FirebaseSurpriseSelection {
  const FirebaseSurpriseSelection({
    required this.category,
    required this.subcategory,
    required this.item,
  });

  final String category;
  final String subcategory;
  final QuizItem item;

  String get groupKey => '$category::$subcategory';
}

class FirebaseChallengeService {
  FirebaseChallengeService._();

  static const Set<String> _surpriseExcludedCategories = <String>{
    'daily_flash',
    'case_files',
  };

  static Future<FirebaseSurpriseSelection?> loadRandomLiveSurpriseQuestion({
    required Set<String> playedQuestionIds,
    String? previousCategory,
    String? previousSubcategory,
    String? excludedQuestionId,
  }) async {
    final QuerySnapshot<Map<String, dynamic>> snapshot =
        await FirebaseFirestore.instance
            .collection('challenges')
            .where('status', isEqualTo: 'live')
            .get();

    if (snapshot.docs.isEmpty) {
      return null;
    }

    final String? previousGroupKey =
        previousCategory != null && previousSubcategory != null
            ? '$previousCategory::$previousSubcategory'
            : null;

    final List<QueryDocumentSnapshot<Map<String, dynamic>>> eligible =
        snapshot.docs.where((document) {
      final Map<String, dynamic> data = document.data();
      final String? category = _readString(data['category']);
      final String? subcategory = _readString(data['subcategory']);
      final String questionId =
          _readString(data['questionId']) ?? document.id;

      if (category == null || subcategory == null) {
        return false;
      }

      if (_surpriseExcludedCategories.contains(category)) {
        return false;
      }

      if (excludedQuestionId != null &&
          excludedQuestionId.isNotEmpty &&
          questionId == excludedQuestionId) {
        return false;
      }

      return questionId.isNotEmpty;
    }).toList(growable: false);

    if (eligible.isEmpty) {
      return null;
    }

    List<QueryDocumentSnapshot<Map<String, dynamic>>> candidates =
        eligible.where((document) {
      final Map<String, dynamic> data = document.data();
      final String questionId =
          _readString(data['questionId']) ?? document.id;

      return !playedQuestionIds.contains(questionId);
    }).toList();

    if (candidates.isEmpty) {
      candidates = List<QueryDocumentSnapshot<Map<String, dynamic>>>.from(
        eligible,
      );
    }

    if (previousGroupKey != null && candidates.length > 1) {
      final List<QueryDocumentSnapshot<Map<String, dynamic>>>
          differentSubcategoryCandidates = candidates.where((document) {
        final Map<String, dynamic> data = document.data();
        final String? category = _readString(data['category']);
        final String? subcategory = _readString(data['subcategory']);

        if (category == null || subcategory == null) {
          return false;
        }

        return '$category::$subcategory' != previousGroupKey;
      }).toList();

      if (differentSubcategoryCandidates.isNotEmpty) {
        candidates = differentSubcategoryCandidates;
      }
    }

    final Random random = Random();
    final QueryDocumentSnapshot<Map<String, dynamic>> selectedDocument =
        candidates[random.nextInt(candidates.length)];

    final Map<String, dynamic> selectedData = selectedDocument.data();
    final String? category = _readString(selectedData['category']);
    final String? subcategory = _readString(selectedData['subcategory']);

    if (category == null || subcategory == null) {
      return null;
    }

    final QuizItem item = await _quizItemFromDocument(selectedDocument);

    return FirebaseSurpriseSelection(
      category: category,
      subcategory: subcategory,
      item: item,
    );
  }

  static Future<List<FirebaseChallengeSubcategory>>
      loadAllLiveSubcategories() async {
    final QuerySnapshot<Map<String, dynamic>> snapshot =
        await FirebaseFirestore.instance
            .collection('challenges')
            .where('status', isEqualTo: 'live')
            .get();

    final Map<String, List<QueryDocumentSnapshot<Map<String, dynamic>>>>
        documentsBySubcategory =
        <String, List<QueryDocumentSnapshot<Map<String, dynamic>>>>{};

    for (final QueryDocumentSnapshot<Map<String, dynamic>> document
        in snapshot.docs) {
      final Map<String, dynamic> data = document.data();
      final String? category = _readString(data['category']);
      final String? subcategory = _readString(data['subcategory']);

      if (category == null || subcategory == null) {
        continue;
      }

      final String key = '$category::$subcategory';

      documentsBySubcategory
          .putIfAbsent(
            key,
            () => <QueryDocumentSnapshot<Map<String, dynamic>>>[],
          )
          .add(document);
    }

    final List<FirebaseChallengeSubcategory> groups =
        <FirebaseChallengeSubcategory>[];

    for (final MapEntry<
            String,
            List<QueryDocumentSnapshot<Map<String, dynamic>>>> entry
        in documentsBySubcategory.entries) {
      final List<String> keyParts = entry.key.split('::');

      final List<QuizItem> items = await Future.wait(
        entry.value.map(_quizItemFromDocument),
      );

      items.sort(
        (QuizItem first, QuizItem second) {
          final String firstId = first.id ?? '';
          final String secondId = second.id ?? '';

          return firstId.compareTo(secondId);
        },
      );

      if (items.isEmpty) {
        continue;
      }

      groups.add(
        FirebaseChallengeSubcategory(
          category: keyParts[0],
          subcategory: keyParts[1],
          items: items,
        ),
      );
    }

    groups.sort(
      (
        FirebaseChallengeSubcategory first,
        FirebaseChallengeSubcategory second,
      ) {
        final int categoryComparison =
            first.category.compareTo(second.category);

        if (categoryComparison != 0) {
          return categoryComparison;
        }

        return first.subcategory.compareTo(second.subcategory);
      },
    );

    return groups;
  }

  static Future<List<QuizItem>> loadLiveSubcategory({
    required String category,
    required String subcategory,
  }) async {
    final QuerySnapshot<Map<String, dynamic>> snapshot =
        await FirebaseFirestore.instance
            .collection('challenges')
            .where('category', isEqualTo: category)
            .where('subcategory', isEqualTo: subcategory)
            .where('status', isEqualTo: 'live')
            .get();

    final List<QuizItem> items = await Future.wait(
      snapshot.docs.map(_quizItemFromDocument),
    );

    items.sort(
      (QuizItem first, QuizItem second) {
        final String firstId = first.id ?? '';
        final String secondId = second.id ?? '';

        return firstId.compareTo(secondId);
      },
    );

    return items;
  }

  static Future<QuizItem> _quizItemFromDocument(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) async {
    final Map<String, dynamic> data = document.data();

    final String questionId =
        _readString(data['questionId']) ?? document.id;

    final String answer =
        _readString(data['answer']) ?? '';

    final String storedImagePath =
        _readString(data['imagePath']) ?? '';

    final List<String> clues =
        _readStringList(data['clues']);

    final List<String> acceptedAnswers =
        _readStringList(data['acceptedAnswers']);

    if (questionId.isEmpty) {
      throw StateError(
        'Firebase challenge ${document.id} has no question ID.',
      );
    }

    if (answer.isEmpty) {
      throw StateError(
        'Firebase challenge $questionId has no answer.',
      );
    }

    if (storedImagePath.isEmpty) {
      throw StateError(
        'Firebase challenge $questionId has no image path.',
      );
    }

    final String imagePath =
        await _resolveImagePath(storedImagePath);

    if (clues.isEmpty) {
      throw StateError(
        'Firebase challenge $questionId has no clues.',
      );
    }

    return QuizItem(
      id: questionId,
      answer: answer,
      imagePath: imagePath,
      clues: clues,
      acceptedAnswers: acceptedAnswers,
    );
  }

  static Future<String> _resolveImagePath(
    String imagePath,
  ) async {
    final Uri? uri = Uri.tryParse(imagePath);

    if (uri != null &&
        (uri.scheme == 'http' || uri.scheme == 'https')) {
      return imagePath;
    }

    if (imagePath.startsWith('gs://')) {
      return FirebaseStorage.instance
          .refFromURL(imagePath)
          .getDownloadURL();
    }

    return FirebaseStorage.instance
        .ref()
        .child(imagePath)
        .getDownloadURL();
  }

  static String? _readString(dynamic value) {
    if (value is! String) {
      return null;
    }

    final String trimmed = value.trim();

    if (trimmed.isEmpty) {
      return null;
    }

    return trimmed;
  }

  static List<String> _readStringList(dynamic value) {
    if (value is! List) {
      return const <String>[];
    }

    return value
        .whereType<String>()
        .map((String item) => item.trim())
        .where((String item) => item.isNotEmpty)
        .toList(growable: false);
  }
}
