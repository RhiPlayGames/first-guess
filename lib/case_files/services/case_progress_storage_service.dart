import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/case_progress.dart';

class CaseProgressStorageService {
  CaseProgressStorageService._();

  static final SharedPreferencesAsync _preferences =
      SharedPreferencesAsync();

  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  static const int _schemaVersion = 1;

  static String _localKey(String casePathId) =>
      'case_path_progress_v1_$casePathId';

  static DocumentReference<Map<String, dynamic>>?
      _cloudDocument(String casePathId) {
    final User? user = _auth.currentUser;

    if (user == null) {
      return null;
    }

    return _firestore
        .collection('players')
        .doc(user.uid)
        .collection('case_paths')
        .doc(casePathId);
  }

  static Future<CaseProgress?> loadProgress({
    required String casePathId,
  }) async {
    final CaseProgress? local =
        await _loadLocal(casePathId);

    final DocumentReference<Map<String, dynamic>>?
        cloudDocument = _cloudDocument(casePathId);

    if (cloudDocument == null) {
      return local;
    }

    try {
      final DocumentSnapshot<Map<String, dynamic>>
          snapshot = await cloudDocument.get();

      final CaseProgress? cloud =
          _fromMap(snapshot.data());

      final CaseProgress? selected =
          _newestProgress(local, cloud);

      if (selected != null) {
        await _saveLocal(selected);

        if (cloud == null ||
            !_sameProgress(cloud, selected)) {
          await _saveCloud(
            selected,
            cloudDocument,
          );
        }
      }

      return selected;
    } on FirebaseException {
      return local;
    }
  }

  static Future<void> saveProgress(
    CaseProgress progress,
  ) async {
    await _saveLocal(progress);

    final DocumentReference<Map<String, dynamic>>?
        cloudDocument =
        _cloudDocument(progress.casePathId);

    if (cloudDocument == null) {
      return;
    }

    try {
      await _saveCloud(
        progress,
        cloudDocument,
      );
    } on FirebaseException {
      // Local progress remains available if cloud sync fails.
    }
  }

  static Future<void> clearProgress({
    required String casePathId,
  }) async {
    await _preferences.remove(
      _localKey(casePathId),
    );

    final DocumentReference<Map<String, dynamic>>?
        cloudDocument = _cloudDocument(casePathId);

    if (cloudDocument == null) {
      return;
    }

    try {
      await cloudDocument.delete();
    } on FirebaseException {
      // Local progress is still cleared if cloud deletion fails.
    }
  }

  static Future<CaseProgress?> _loadLocal(
    String casePathId,
  ) async {
    final String? raw =
        await _preferences.getString(
      _localKey(casePathId),
    );

    if (raw == null || raw.isEmpty) {
      return null;
    }

    try {
      final dynamic decoded = jsonDecode(raw);

      if (decoded is! Map) {
        return null;
      }

      return _fromMap(
        Map<String, dynamic>.from(decoded),
      );
    } on FormatException {
      return null;
    }
  }

  static Future<void> _saveLocal(
    CaseProgress progress,
  ) async {
    await _preferences.setString(
      _localKey(progress.casePathId),
      jsonEncode(_toMap(progress)),
    );
  }

  static Future<void> _saveCloud(
    CaseProgress progress,
    DocumentReference<Map<String, dynamic>>
        cloudDocument,
  ) async {
    final Map<String, dynamic> data =
        _toMap(progress);

    data['serverUpdatedAt'] =
        FieldValue.serverTimestamp();

    await cloudDocument.set(
      data,
      SetOptions(merge: true),
    );
  }

  static Map<String, dynamic> _toMap(
    CaseProgress progress,
  ) {
    final CaseStageProgress stage =
        progress.currentStageProgress;

    return <String, dynamic>{
      'casePathId': progress.casePathId,
      'currentStage': progress.currentStage,
      'totalStages': progress.totalStages,
      'completedStages': progress.completedStages,
      'isCompleted': progress.isCompleted,
      'currentStageProgress': <String, dynamic>{
        'stage': stage.stage,
        'correctCount': stage.correctCount,
        'clueThresholdCount':
            stage.clueThresholdCount,
        'firstGuessCount': stage.firstGuessCount,
        'lastProcessedAttemptId':
            stage.lastProcessedAttemptId,
        'startedAt': _dateToString(
          stage.startedAt,
        ),
        'completedAt': _dateToString(
          stage.completedAt,
        ),
      },
      'startedAt': _dateToString(
        progress.startedAt,
      ),
      'updatedAt': _dateToString(
        progress.updatedAt,
      ),
      'completedAt': _dateToString(
        progress.completedAt,
      ),
      'schemaVersion': _schemaVersion,
    };
  }

  static CaseProgress? _fromMap(
    Map<String, dynamic>? data,
  ) {
    if (data == null) {
      return null;
    }

    final String? casePathId =
        data['casePathId'] as String?;

    final int? currentStage =
        _asInt(data['currentStage']);

    final int? totalStages =
        _asInt(data['totalStages']);

    final Map<String, dynamic>? stageData =
        _asMap(data['currentStageProgress']);

    if (casePathId == null ||
        casePathId.isEmpty ||
        currentStage == null ||
        totalStages == null ||
        stageData == null) {
      return null;
    }

    final int? stage =
        _asInt(stageData['stage']);

    if (stage == null) {
      return null;
    }

    return CaseProgress(
      casePathId: casePathId,
      currentStage: currentStage,
      totalStages: totalStages,
      completedStages:
          _asIntList(data['completedStages']),
      isCompleted:
          data['isCompleted'] as bool? ?? false,
      currentStageProgress: CaseStageProgress(
        stage: stage,
        correctCount:
            _asInt(stageData['correctCount']) ?? 0,
        clueThresholdCount:
            _asInt(
              stageData['clueThresholdCount'],
            ) ??
            0,
        firstGuessCount:
            _asInt(
              stageData['firstGuessCount'],
            ) ??
            0,
        lastProcessedAttemptId:
            stageData['lastProcessedAttemptId']
                as String?,
        startedAt: _asDate(
          stageData['startedAt'],
        ),
        completedAt: _asDate(
          stageData['completedAt'],
        ),
      ),
      startedAt: _asDate(
        data['startedAt'],
      ),
      updatedAt: _asDate(
        data['updatedAt'],
      ),
      completedAt: _asDate(
        data['completedAt'],
      ),
    );
  }

  static CaseProgress? _newestProgress(
    CaseProgress? local,
    CaseProgress? cloud,
  ) {
    if (local == null) {
      return cloud;
    }

    if (cloud == null) {
      return local;
    }

    if (local.isCompleted &&
        !cloud.isCompleted) {
      return local;
    }

    if (cloud.isCompleted &&
        !local.isCompleted) {
      return cloud;
    }

    if (local.currentStage !=
        cloud.currentStage) {
      return local.currentStage >
              cloud.currentStage
          ? local
          : cloud;
    }

    final DateTime localUpdated =
        local.updatedAt ??
            DateTime.fromMillisecondsSinceEpoch(0);

    final DateTime cloudUpdated =
        cloud.updatedAt ??
            DateTime.fromMillisecondsSinceEpoch(0);

    return localUpdated.isAfter(cloudUpdated)
        ? local
        : cloud;
  }

  static bool _sameProgress(
    CaseProgress first,
    CaseProgress second,
  ) {
    return jsonEncode(_toMap(first)) ==
        jsonEncode(_toMap(second));
  }

  static int? _asInt(dynamic value) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return null;
  }

  static List<int> _asIntList(dynamic value) {
    if (value is! List) {
      return <int>[];
    }

    return value
        .map<int?>((dynamic item) => _asInt(item))
        .whereType<int>()
        .toList()
      ..sort();
  }

  static Map<String, dynamic>? _asMap(
    dynamic value,
  ) {
    if (value is! Map) {
      return null;
    }

    return Map<String, dynamic>.from(value);
  }

  static String? _dateToString(
    DateTime? value,
  ) {
    return value?.toUtc().toIso8601String();
  }

  static DateTime? _asDate(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is String) {
      return DateTime.tryParse(value);
    }

    return null;
  }
}