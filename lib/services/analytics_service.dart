import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'achievement_service.dart';
import 'player_stats_service.dart';

class AnalyticsService {
  AnalyticsService._();

  static final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  static String get _accountType {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.isAnonymous) {
      return 'guest';
    }
    return 'signed_in';
  }

  static Map<String, Object> _withOptionalParameters(
    Map<String, Object> parameters, {
    String? sessionId,
    String? dailyFlashDate,
    String? gameKey,
  }) {
    if (sessionId != null && sessionId.trim().isNotEmpty) {
      parameters['game_session_id'] = sessionId.trim();
    }
    if (dailyFlashDate != null && dailyFlashDate.trim().isNotEmpty) {
      parameters['daily_flash_date'] = dailyFlashDate.trim();
    }
    if (gameKey != null && gameKey.trim().isNotEmpty) {
      parameters['game_key'] = gameKey.trim();
    }
    return parameters;
  }

  static Map<String, Object> _baseGameParameters({
    required String gameType,
    required String category,
    required String subcategory,
    required String questionId,
    required String source,
    required bool practiceMode,
  }) {
    return <String, Object>{
      'game_type': gameType,
      'category': category,
      'subcategory': subcategory,
      'question_id': questionId,
      'source': source,
      'practice_mode': practiceMode ? 1 : 0,
      'account_type': _accountType,
    };
  }

  static Future<void> logGameStarted({
    required String gameType,
    required String category,
    required String subcategory,
    required String questionId,
    required String source,
    required bool practiceMode,
  }) async {
    await _analytics.logEvent(
      name: 'game_started',
      parameters: _baseGameParameters(
        gameType: gameType,
        category: category,
        subcategory: subcategory,
        questionId: questionId,
        source: source,
        practiceMode: practiceMode,
      ),
    );
  }

  static Future<void> logGameCompleted({
    required String gameType,
    required String category,
    required String subcategory,
    required String questionId,
    required String source,
    required String result,
    required int xpEarned,
    required bool firstGuess,
    required bool practiceMode,
    required int clueNumber,
    required int guesses,
    required int livesRemaining,
    required int playTimeSeconds,
  }) async {
    final Map<String, Object> parameters = _baseGameParameters(
      gameType: gameType,
      category: category,
      subcategory: subcategory,
      questionId: questionId,
      source: source,
      practiceMode: practiceMode,
    )
      ..addAll(<String, Object>{
        'result': result,
        'xp_earned': xpEarned,
        'first_guess': firstGuess ? 1 : 0,
        'clue_number': clueNumber,
        'guesses': guesses,
        'lives_remaining': livesRemaining,
        'play_time_seconds': playTimeSeconds,
      });

    await _analytics.logEvent(
      name: 'game_completed',
      parameters: parameters,
    );
  }

  static Future<void> logFirstGuessEarned({
    required String gameType,
    required String category,
    required String subcategory,
    required String questionId,
    required String source,
    required int xpEarned,
    required bool practiceMode,
  }) async {
    final Map<String, Object> parameters = _baseGameParameters(
      gameType: gameType,
      category: category,
      subcategory: subcategory,
      questionId: questionId,
      source: source,
      practiceMode: practiceMode,
    )
      ..addAll(<String, Object>{
        'xp_earned': xpEarned,
      });

    await _analytics.logEvent(
      name: 'first_guess_earned',
      parameters: parameters,
    );
  }

  static Future<void> logGameSessionStarted({
    required String gameKey,
    required String source,
    String category = '',
    String subcategory = '',
    bool practiceMode = false,
    String? sessionId,
    String? dailyFlashDate,
  }) async {
    final Map<String, Object> parameters = <String, Object>{
      'game_key': gameKey,
      'source': source,
      'category': category,
      'subcategory': subcategory,
      'practice_mode': practiceMode ? 1 : 0,
      'account_type': _accountType,
    };

    await _analytics.logEvent(
      name: 'game_session_started',
      parameters: _withOptionalParameters(
        parameters,
        sessionId: sessionId,
        dailyFlashDate: dailyFlashDate,
      ),
    );
  }

  static Future<void> logGameSessionCompleted({
    required String gameKey,
    required String source,
    required int questionsAttempted,
    required int questionsCorrect,
    required int xpEarned,
    required int playTimeSeconds,
    String category = '',
    String subcategory = '',
    bool practiceMode = false,
    String? sessionId,
    String? dailyFlashDate,
  }) async {
    final Map<String, Object> parameters = <String, Object>{
      'game_key': gameKey,
      'source': source,
      'category': category,
      'subcategory': subcategory,
      'practice_mode': practiceMode ? 1 : 0,
      'questions_attempted': questionsAttempted,
      'questions_correct': questionsCorrect,
      'xp_earned': xpEarned,
      'play_time_seconds': playTimeSeconds,
      'account_type': _accountType,
    };

    await _analytics.logEvent(
      name: 'game_session_completed',
      parameters: _withOptionalParameters(
        parameters,
        sessionId: sessionId,
        dailyFlashDate: dailyFlashDate,
      ),
    );
  }

  static Future<void> logGameAbandoned({
    required String gameKey,
    required String source,
    required int questionsAttempted,
    required int playTimeSeconds,
    String category = '',
    String subcategory = '',
    String questionId = '',
    int clueNumber = 0,
    bool practiceMode = false,
    String? sessionId,
    String? dailyFlashDate,
  }) async {
    final Map<String, Object> parameters = <String, Object>{
      'game_key': gameKey,
      'source': source,
      'category': category,
      'subcategory': subcategory,
      'question_id': questionId,
      'clue_number': clueNumber,
      'questions_attempted': questionsAttempted,
      'play_time_seconds': playTimeSeconds,
      'practice_mode': practiceMode ? 1 : 0,
      'account_type': _accountType,
    };

    await _analytics.logEvent(
      name: 'game_abandoned',
      parameters: _withOptionalParameters(
        parameters,
        sessionId: sessionId,
        dailyFlashDate: dailyFlashDate,
      ),
    );
  }

  static Future<void> logQuestionStarted({
    required String gameKey,
    required String category,
    required String subcategory,
    required String questionId,
    required String source,
    bool practiceMode = false,
    String? sessionId,
    String? dailyFlashDate,
  }) async {
    final Map<String, Object> parameters = <String, Object>{
      'game_key': gameKey,
      'category': category,
      'subcategory': subcategory,
      'question_id': questionId,
      'source': source,
      'practice_mode': practiceMode ? 1 : 0,
      'account_type': _accountType,
    };

    await _analytics.logEvent(
      name: 'question_started',
      parameters: _withOptionalParameters(
        parameters,
        sessionId: sessionId,
        dailyFlashDate: dailyFlashDate,
      ),
    );
  }

  static Future<void> logQuestionCompleted({
    required String gameKey,
    required String category,
    required String subcategory,
    required String questionId,
    required String source,
    required String result,
    required int xpEarned,
    required bool firstGuess,
    required int clueNumber,
    required int guesses,
    required int livesRemaining,
    required int playTimeSeconds,
    bool practiceMode = false,
    String? sessionId,
    String? dailyFlashDate,
  }) async {
    final Map<String, Object> parameters = <String, Object>{
      'game_key': gameKey,
      'category': category,
      'subcategory': subcategory,
      'question_id': questionId,
      'source': source,
      'result': result,
      'xp_earned': xpEarned,
      'first_guess': firstGuess ? 1 : 0,
      'clue_number': clueNumber,
      'guesses': guesses,
      'lives_remaining': livesRemaining,
      'play_time_seconds': playTimeSeconds,
      'practice_mode': practiceMode ? 1 : 0,
      'account_type': _accountType,
    };

    await _analytics.logEvent(
      name: 'question_completed',
      parameters: _withOptionalParameters(
        parameters,
        sessionId: sessionId,
        dailyFlashDate: dailyFlashDate,
      ),
    );
  }

  static Future<void> logContentProgressSnapshot({
    required String gameKey,
    required String category,
    required String subcategory,
    required int uniqueQuestionsCompleted,
    required int totalQuestionsAvailable,
  }) async {
    final int saturationPercent = totalQuestionsAvailable <= 0
        ? 0
        : ((uniqueQuestionsCompleted * 100) / totalQuestionsAvailable)
            .round()
            .clamp(0, 100);

    await _analytics.logEvent(
      name: 'content_progress',
      parameters: <String, Object>{
        'game_key': gameKey,
        'category': category,
        'subcategory': subcategory,
        'unique_questions_completed': uniqueQuestionsCompleted,
        'total_questions_available': totalQuestionsAvailable,
        'saturation_percent': saturationPercent,
        'account_type': _accountType,
      },
    );
  }

  static Future<void> logDailyFlashStarted({
    required String dateKey,
    String gameKey = 'classic',
  }) async {
    await _analytics.logEvent(
      name: 'daily_flash_started',
      parameters: <String, Object>{
        'date_key': dateKey,
        'game_key': gameKey,
        'account_type': _accountType,
      },
    );
  }

  static Future<void> logDailyFlashCompleted({
    required String dateKey,
    required int questionsCorrect,
    required int firstGuesses,
    required int totalXp,
    required bool perfect,
    String gameKey = 'classic',
  }) async {
    await _analytics.logEvent(
      name: 'daily_flash_completed',
      parameters: <String, Object>{
        'date_key': dateKey,
        'game_key': gameKey,
        'questions_correct': questionsCorrect,
        'first_guesses': firstGuesses,
        'xp_earned': totalXp,
        'perfect': perfect ? 1 : 0,
        'account_type': _accountType,
      },
    );
  }

  static Future<void> logCaseFileStarted({
    required String caseKey,
    required String caseName,
    required bool resume,
  }) async {
    await _analytics.logEvent(
      name: 'case_file_started',
      parameters: <String, Object>{
        'case_key': caseKey,
        'case_name': caseName,
        'resume': resume ? 1 : 0,
        'account_type': _accountType,
      },
    );
  }

  static Future<void> logCaseFileCompleted({
    required String caseKey,
    required String caseName,
    required int totalStages,
  }) async {
    await _analytics.logEvent(
      name: 'case_file_completed',
      parameters: <String, Object>{
        'case_key': caseKey,
        'case_name': caseName,
        'total_stages': totalStages,
        'account_type': _accountType,
      },
    );
  }

  static Future<void> logCaseFileStageStarted({
    required String caseKey,
    required String caseName,
    required int stageNumber,
    required int totalStages,
    required bool resume,
  }) async {
    final int progressPercent = totalStages <= 0
        ? 0
        : (((stageNumber - 1).clamp(0, totalStages) * 100) / totalStages)
            .round()
            .clamp(0, 100);

    await _analytics.logEvent(
      name: 'case_file_stage_started',
      parameters: <String, Object>{
        'case_key': caseKey,
        'case_name': caseName,
        'stage_number': stageNumber,
        'total_stages': totalStages,
        'progress_percent': progressPercent,
        'resume': resume ? 1 : 0,
        'account_type': _accountType,
      },
    );
  }

  static Future<void> logCaseFileStageCompleted({
    required String caseKey,
    required String caseName,
    required int stageNumber,
    required int totalStages,
  }) async {
    final int progressPercent = totalStages <= 0
        ? 0
        : ((stageNumber.clamp(0, totalStages) * 100) / totalStages)
            .round()
            .clamp(0, 100);

    await _analytics.logEvent(
      name: 'case_file_stage_completed',
      parameters: <String, Object>{
        'case_key': caseKey,
        'case_name': caseName,
        'stage_number': stageNumber,
        'total_stages': totalStages,
        'progress_percent': progressPercent,
        'account_type': _accountType,
      },
    );
  }

  static Future<void> logCaseFileProgress({
    required String caseKey,
    required String caseName,
    required int currentStage,
    required int totalStages,
    bool isCompleted = false,
  }) async {
    final int completedStages = isCompleted
        ? totalStages
        : (currentStage - 1).clamp(0, totalStages);
    final int progressPercent = totalStages <= 0
        ? 0
        : ((completedStages * 100) / totalStages)
            .round()
            .clamp(0, 100);

    await _analytics.logEvent(
      name: 'case_file_progress',
      parameters: <String, Object>{
        'case_key': caseKey,
        'case_name': caseName,
        'current_stage': currentStage,
        'completed_stages': completedStages,
        'total_stages': totalStages,
        'progress_percent': progressPercent,
        'is_completed': isCompleted ? 1 : 0,
        'account_type': _accountType,
      },
    );
  }

  static Future<void> logCaseFileAbandoned({
    required String caseKey,
    required String caseName,
    required int currentStage,
    required int totalStages,
    required int playTimeSeconds,
  }) async {
    final int completedStages =
        (currentStage - 1).clamp(0, totalStages);
    final int progressPercent = totalStages <= 0
        ? 0
        : ((completedStages * 100) / totalStages)
            .round()
            .clamp(0, 100);

    await _analytics.logEvent(
      name: 'case_file_abandoned',
      parameters: <String, Object>{
        'case_key': caseKey,
        'case_name': caseName,
        'current_stage': currentStage,
        'completed_stages': completedStages,
        'total_stages': totalStages,
        'progress_percent': progressPercent,
        'play_time_seconds': playTimeSeconds,
        'account_type': _accountType,
      },
    );
  }

  static Future<void> logLeagueCreated({
    required int memberCount,
  }) async {
    await _analytics.logEvent(
      name: 'league_created',
      parameters: <String, Object>{
        'member_count': memberCount,
        'account_type': _accountType,
      },
    );
  }

  static Future<void> logLeagueJoined({
    required int memberCount,
  }) async {
    await _analytics.logEvent(
      name: 'league_joined',
      parameters: <String, Object>{
        'member_count': memberCount,
        'account_type': _accountType,
      },
    );
  }

  static Future<void> logBadgeEarned({
    required String badgeName,
    required String gameType,
  }) async {
    await _analytics.logEvent(
      name: 'badge_earned',
      parameters: <String, Object>{
        'badge_name': badgeName,
        'game_type': gameType,
        'account_type': _accountType,
      },
    );
  }

  static Future<void> logAchievementEarned({
    required String achievementId,
    required String achievementTitle,
    required String category,
    required int target,
  }) async {
    await _analytics.logEvent(
      name: 'achievement_earned',
      parameters: <String, Object>{
        'achievement_id': achievementId,
        'achievement_title': achievementTitle,
        'achievement_category': category,
        'target': target,
        'account_type': _accountType,
      },
    );
  }

  static Future<void> logEarnedRewards({
    required PlayerStats previous,
    required PlayerStats current,
    required String gameKey,
    required String gameLabel,
  }) async {
    final List<EarnedBadge> badges =
        AchievementService.newlyEarnedBadges(
      previous: previous,
      current: current,
      gameKey: gameKey,
      gameLabel: gameLabel,
    );

    for (final EarnedBadge badge in badges) {
      await logBadgeEarned(
        badgeName: badge.name,
        gameType: gameKey,
      );
    }

    final List<Achievement> achievements =
        AchievementService.newlyReachedMilestones(
      previous: previous,
      current: current,
    );

    for (final Achievement achievement in achievements) {
      await logAchievementEarned(
        achievementId: achievement.id,
        achievementTitle: achievement.title,
        category: achievement.category.name,
        target: achievement.target,
      );
    }
  }

}
