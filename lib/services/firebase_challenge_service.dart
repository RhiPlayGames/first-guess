import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

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

  static final Map<String, Future<String>> _imageUrlCache =
      <String, Future<String>>{};

  static final Map<
      String,
      Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>>>
      _liveCategoryDocumentCache =
      <String, Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>>>{};

  static final Map<String, Future<List<QuizItem>>> _liveSubcategoryItemsCache =
      <String, Future<List<QuizItem>>>{};

  static Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>>
      loadLiveCategoryDocuments({
    required String category,
    bool forceRefresh = false,
  }) {
    if (forceRefresh) {
      _liveCategoryDocumentCache.remove(category);
    }

    return _liveCategoryDocumentCache.putIfAbsent(
      category,
      () async {
        try {
          final QuerySnapshot<Map<String, dynamic>> snapshot =
              await FirebaseFirestore.instance
                  .collection('challenges')
                  .where('category', isEqualTo: category)
                  .where('status', isEqualTo: 'live')
                  .get();

          return List<QueryDocumentSnapshot<Map<String, dynamic>>>.unmodifiable(
            snapshot.docs,
          );
        } catch (_) {
          _liveCategoryDocumentCache.remove(category);
          rethrow;
        }
      },
    );
  }

  static void clearSessionChallengeCache() {
    _liveCategoryDocumentCache.clear();
    _liveSubcategoryItemsCache.clear();
  }

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
      return null;
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

  static Future<FirebaseSurpriseSelection?>
      loadRandomLiveCategorySurpriseQuestion({
    required String category,
    required Set<String> playedQuestionIds,
  }) async {
    if (_surpriseExcludedCategories.contains(category)) {
      return null;
    }

    final List<QueryDocumentSnapshot<Map<String, dynamic>>> documents =
        await loadLiveCategoryDocuments(
      category: category,
    );

    if (documents.isEmpty) {
      return null;
    }

    final List<QueryDocumentSnapshot<Map<String, dynamic>>> eligible =
        documents.where((document) {
      final Map<String, dynamic> data = document.data();
      final String? documentCategory = _readString(data['category']);
      final String? subcategory = _readString(data['subcategory']);
      final String questionId =
          _readString(data['questionId']) ?? document.id;

      return documentCategory == category &&
          subcategory != null &&
          questionId.isNotEmpty;
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
      candidates =
          List<QueryDocumentSnapshot<Map<String, dynamic>>>.from(eligible);
    }

    final Random random = Random();
    final QueryDocumentSnapshot<Map<String, dynamic>> selectedDocument =
        candidates[random.nextInt(candidates.length)];

    final Map<String, dynamic> selectedData = selectedDocument.data();
    final String? selectedCategory =
        _readString(selectedData['category']);
    final String? selectedSubcategory =
        _readString(selectedData['subcategory']);

    if (selectedCategory == null || selectedSubcategory == null) {
      return null;
    }

    final QuizItem item =
        await _quizItemFromDocument(selectedDocument);

    return FirebaseSurpriseSelection(
      category: selectedCategory,
      subcategory: selectedSubcategory,
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

      final List<QuizItem?> loadedItems = await Future.wait(
        entry.value.map(_safeQuizItemFromDocument),
      );

      final List<QuizItem> items =
          loadedItems.whereType<QuizItem>().toList();

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
    bool forceRefresh = false,
  }) {
    final String cacheKey = '$category::$subcategory';

    if (forceRefresh) {
      _liveSubcategoryItemsCache.remove(cacheKey);
    }

    return _liveSubcategoryItemsCache.putIfAbsent(
      cacheKey,
      () async {
        try {
          final List<QueryDocumentSnapshot<Map<String, dynamic>>> docs;

          final Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>>?
              cachedCategoryFuture = _liveCategoryDocumentCache[category];

          if (cachedCategoryFuture != null) {
            final List<QueryDocumentSnapshot<Map<String, dynamic>>> categoryDocs =
                await cachedCategoryFuture;

            docs = categoryDocs.where((document) {
              final String? documentSubcategory =
                  _readString(document.data()['subcategory']);
              return documentSubcategory == subcategory;
            }).toList(growable: false);
          } else {
            final QuerySnapshot<Map<String, dynamic>> snapshot =
                await FirebaseFirestore.instance
                    .collection('challenges')
                    .where('category', isEqualTo: category)
                    .where('subcategory', isEqualTo: subcategory)
                    .where('status', isEqualTo: 'live')
                    .get();

            docs = snapshot.docs;
          }

          final List<QuizItem?> loadedItems = await Future.wait(
            docs.map(_safeQuizItemFromDocument),
          );

          final List<QuizItem> items =
              loadedItems.whereType<QuizItem>().toList();

          items.sort(
            (QuizItem first, QuizItem second) {
              final String firstId = first.id ?? '';
              final String secondId = second.id ?? '';

              return firstId.compareTo(secondId);
            },
          );

          return List<QuizItem>.unmodifiable(items);
        } catch (_) {
          _liveSubcategoryItemsCache.remove(cacheKey);
          rethrow;
        }
      },
    );
  }

  static Future<QuizItem?> _safeQuizItemFromDocument(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) async {
    try {
      return await _quizItemFromDocument(document);
    } catch (error, stackTrace) {
      debugPrint(
        'SKIPPING INVALID FIREBASE CHALLENGE ${document.id}: $error',
      );
      debugPrintStack(stackTrace: stackTrace);
      return null;
    }
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
  ) {
    final Uri? uri = Uri.tryParse(imagePath);

    if (uri != null &&
        (uri.scheme == 'http' || uri.scheme == 'https')) {
      return Future<String>.value(imagePath);
    }

    return _imageUrlCache.putIfAbsent(
      imagePath,
      () {
        if (imagePath.startsWith('gs://')) {
          return FirebaseStorage.instance
              .refFromURL(imagePath)
              .getDownloadURL();
        }

        return FirebaseStorage.instance
            .ref()
            .child(imagePath)
            .getDownloadURL();
      },
    );
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
