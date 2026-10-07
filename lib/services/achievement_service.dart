import 'player_stats_service.dart';

enum AchievementRarity {
  bronze,
  silver,
  gold,
  diamond,
}

enum AchievementCategory {
  general,
  firstGuess,
  streak,
  xp,
  dailyFlash,
  firstConnection,
  firstDate,
  firstMatch,
  firstOrder,
  firstWord,
  countries,
  scienceNature,
  animals,
  watchPlay,
  music,
  whoAmI,
  booksAuthors,
  pastPresent,
  foodDrink,
  creativeWorld,
  sports,
  famousWords,
}

class Achievement {
  final String id;
  final String title;
  final String description;
  final AchievementRarity rarity;
  final AchievementCategory category;
  final int target;
  final int achievementPoints;
  final int Function(PlayerStats stats) progressSelector;
  final String? milestoneSeries;
  final String? popupLabel;

  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.rarity,
    required this.category,
    required this.target,
    required this.achievementPoints,
    required this.progressSelector,
    this.milestoneSeries,
    this.popupLabel,
  });

  int progress(PlayerStats stats) {
    return progressSelector(stats);
  }

  bool isUnlocked(PlayerStats stats) {
    return progress(stats) >= target;
  }

  double progressPercentage(PlayerStats stats) {
    if (target <= 0) {
      return 1;
    }

    return (progress(stats) / target).clamp(0.0, 1.0);
  }
}

class EarnedBadge {
  final String name;
  final String imageAsset;

  const EarnedBadge({
    required this.name,
    required this.imageAsset,
  });
}


class AchievementService {
  AchievementService._();

  static final List<Achievement> achievements = [
    Achievement(
      id: 'first_game',
      title: 'First Steps',
      description: 'Correctly answer your first question',
      rarity: AchievementRarity.bronze,
      category: AchievementCategory.general,
      target: 1,
      achievementPoints: 0,
      progressSelector: (stats) => stats.correctlySolvedGames,
    ),
    Achievement(
      id: 'games_25',
      title: 'Getting Started',
      description: 'Correctly answer 25 questions',
      rarity: AchievementRarity.bronze,
      category: AchievementCategory.general,
      target: 25,
      achievementPoints: 0,
      progressSelector: (stats) => stats.correctlySolvedGames,
    ),
    Achievement(
      id: 'games_100',
      title: 'Dedicated Player',
      description: 'Correctly answer 100 questions',
      rarity: AchievementRarity.silver,
      category: AchievementCategory.general,
      target: 100,
      achievementPoints: 0,
      progressSelector: (stats) => stats.correctlySolvedGames,
    ),
    Achievement(
      id: 'games_250',
      title: 'Century Club',
      description: 'Correctly answer 250 questions',
      rarity: AchievementRarity.gold,
      category: AchievementCategory.general,
      target: 250,
      achievementPoints: 0,
      progressSelector: (stats) => stats.correctlySolvedGames,
    ),
    Achievement(
      id: 'games_500',
      title: 'First Guess Legend',
      description: 'Correctly answer 500 questions',
      rarity: AchievementRarity.diamond,
      category: AchievementCategory.general,
      target: 500,
      achievementPoints: 0,
      progressSelector: (stats) => stats.correctlySolvedGames,
    ),
    Achievement(
      id: 'games_1000',
      title: 'Game Master',
      description: 'Correctly answer 1,000 questions',
      rarity: AchievementRarity.diamond,
      category: AchievementCategory.general,
      target: 1000,
      achievementPoints: 0,
      progressSelector: (stats) => stats.correctlySolvedGames,
    ),
    Achievement(
      id: 'first_guess_1',
      title: 'First First Guess',
      description: 'Get one answer correct on Clue 1',
      rarity: AchievementRarity.bronze,
      category: AchievementCategory.firstGuess,
      target: 1,
      achievementPoints: 0,
      progressSelector: (stats) => stats.firstGuesses,
    ),
    Achievement(
      id: 'first_guesses_25',
      title: 'Quick Thinker',
      description: 'Earn 25 First Guesses',
      rarity: AchievementRarity.bronze,
      category: AchievementCategory.firstGuess,
      target: 25,
      achievementPoints: 0,
      progressSelector: (stats) => stats.firstGuesses,
    ),
    Achievement(
      id: 'first_guesses_100',
      title: 'Sharp Mind',
      description: 'Earn 100 First Guesses',
      rarity: AchievementRarity.silver,
      category: AchievementCategory.firstGuess,
      target: 100,
      achievementPoints: 0,
      progressSelector: (stats) => stats.firstGuesses,
    ),
    Achievement(
      id: 'first_guesses_250',
      title: 'Instant Recognition',
      description: 'Earn 250 First Guesses',
      rarity: AchievementRarity.gold,
      category: AchievementCategory.firstGuess,
      target: 250,
      achievementPoints: 0,
      progressSelector: (stats) => stats.firstGuesses,
    ),
    Achievement(
      id: 'first_guesses_500',
      title: 'First Guess Master',
      description: 'Earn 500 First Guesses',
      rarity: AchievementRarity.diamond,
      category: AchievementCategory.firstGuess,
      target: 500,
      achievementPoints: 0,
      progressSelector: (stats) => stats.firstGuesses,
    ),
    Achievement(
      id: 'first_guesses_1000',
      title: 'First Guess Legend',
      description: 'Earn 1,000 First Guesses',
      rarity: AchievementRarity.diamond,
      category: AchievementCategory.firstGuess,
      target: 1000,
      achievementPoints: 0,
      progressSelector: (stats) => stats.firstGuesses,
    ),
    Achievement(
      id: 'streak_10',
      title: 'Unstoppable',
      description: 'Reach a 10-game winning streak',
      rarity: AchievementRarity.silver,
      category: AchievementCategory.streak,
      target: 10,
      achievementPoints: 0,
      progressSelector: (stats) => stats.longestStreak,
    ),
    Achievement(
      id: 'streak_25',
      title: 'Untouchable',
      description: 'Reach a 25-game winning streak',
      rarity: AchievementRarity.gold,
      category: AchievementCategory.streak,
      target: 25,
      achievementPoints: 0,
      progressSelector: (stats) => stats.longestStreak,
    ),
    Achievement(
      id: 'streak_50',
      title: 'Streak Master',
      description: 'Reach a 50-game winning streak',
      rarity: AchievementRarity.gold,
      category: AchievementCategory.streak,
      target: 50,
      achievementPoints: 0,
      progressSelector: (stats) => stats.longestStreak,
    ),
    Achievement(
      id: 'streak_100',
      title: 'Streak Legend',
      description: 'Reach a 100-game winning streak',
      rarity: AchievementRarity.diamond,
      category: AchievementCategory.streak,
      target: 100,
      achievementPoints: 0,
      progressSelector: (stats) => stats.longestStreak,
    ),
    Achievement(
      id: 'streak_500',
      title: 'Unbreakable',
      description: 'Reach a 500-game winning streak',
      rarity: AchievementRarity.diamond,
      category: AchievementCategory.streak,
      target: 500,
      achievementPoints: 0,
      progressSelector: (stats) => stats.longestStreak,
    ),
    Achievement(
      id: 'first_connection_1',
      title: 'First Connection',
      description: 'Answer 1 question correctly',
      rarity: AchievementRarity.bronze,
      category: AchievementCategory.firstConnection,
      target: 1,
      achievementPoints: 0,
      milestoneSeries: 'first_connection_completions',
      popupLabel: 'QUESTIONS CORRECT',
      progressSelector: (stats) =>
          (stats.categoryCorrectCounts['first_connection'] ?? 0),
    ),
    Achievement(
      id: 'first_connection_25',
      title: 'Making Connections',
      description: 'Answer 25 questions correctly',
      rarity: AchievementRarity.bronze,
      category: AchievementCategory.firstConnection,
      target: 25,
      achievementPoints: 0,
      milestoneSeries: 'first_connection_completions',
      popupLabel: 'QUESTIONS CORRECT',
      progressSelector: (stats) =>
          (stats.categoryCorrectCounts['first_connection'] ?? 0),
    ),
    Achievement(
      id: 'first_connection_50',
      title: 'Connection Hunter',
      description: 'Answer 50 questions correctly',
      rarity: AchievementRarity.silver,
      category: AchievementCategory.firstConnection,
      target: 50,
      achievementPoints: 0,
      milestoneSeries: 'first_connection_completions',
      popupLabel: 'QUESTIONS CORRECT',
      progressSelector: (stats) =>
          (stats.categoryCorrectCounts['first_connection'] ?? 0),
    ),
    Achievement(
      id: 'first_connection_100',
      title: 'Connection Expert',
      description: 'Answer 100 questions correctly',
      rarity: AchievementRarity.silver,
      category: AchievementCategory.firstConnection,
      target: 100,
      achievementPoints: 0,
      milestoneSeries: 'first_connection_completions',
      popupLabel: 'QUESTIONS CORRECT',
      progressSelector: (stats) =>
          (stats.categoryCorrectCounts['first_connection'] ?? 0),
    ),
    Achievement(
      id: 'first_connection_250',
      title: 'Connection Master',
      description: 'Answer 250 questions correctly',
      rarity: AchievementRarity.gold,
      category: AchievementCategory.firstConnection,
      target: 250,
      achievementPoints: 0,
      milestoneSeries: 'first_connection_completions',
      popupLabel: 'QUESTIONS CORRECT',
      progressSelector: (stats) =>
          (stats.categoryCorrectCounts['first_connection'] ?? 0),
    ),
    Achievement(
      id: 'first_connection_500',
      title: 'First Connection Legend',
      description: 'Answer 500 questions correctly',
      rarity: AchievementRarity.diamond,
      category: AchievementCategory.firstConnection,
      target: 500,
      achievementPoints: 0,
      milestoneSeries: 'first_connection_completions',
      popupLabel: 'QUESTIONS CORRECT',
      progressSelector: (stats) =>
          (stats.categoryCorrectCounts['first_connection'] ?? 0),
    ),
    Achievement(
      id: 'first_connection_best_10',
      title: 'Quick Connection',
      description: 'Earn 10 First Guesses',
      rarity: AchievementRarity.bronze,
      category: AchievementCategory.firstConnection,
      target: 10,
      achievementPoints: 0,
      milestoneSeries: 'first_connection_first_guesses',
      popupLabel: 'FIRST GUESSES',
      progressSelector: (stats) =>
          (stats.categoryFirstGuessCounts['first_connection'] ?? 0),
    ),
    Achievement(
      id: 'first_connection_best_25',
      title: 'Sharp Connector',
      description: 'Earn 25 First Guesses',
      rarity: AchievementRarity.silver,
      category: AchievementCategory.firstConnection,
      target: 25,
      achievementPoints: 0,
      milestoneSeries: 'first_connection_first_guesses',
      popupLabel: 'FIRST GUESSES',
      progressSelector: (stats) =>
          (stats.categoryFirstGuessCounts['first_connection'] ?? 0),
    ),
    Achievement(
      id: 'first_connection_best_100',
      title: 'Connection Pro',
      description: 'Earn 100 First Guesses',
      rarity: AchievementRarity.gold,
      category: AchievementCategory.firstConnection,
      target: 100,
      achievementPoints: 0,
      milestoneSeries: 'first_connection_first_guesses',
      popupLabel: 'FIRST GUESSES',
      progressSelector: (stats) =>
          (stats.categoryFirstGuessCounts['first_connection'] ?? 0),
    ),
    Achievement(
      id: 'first_connection_streak_5',
      title: 'Connection Streak',
      description: 'Answer 5 questions correctly in a row',
      rarity: AchievementRarity.bronze,
      category: AchievementCategory.firstConnection,
      target: 5,
      achievementPoints: 0,
      milestoneSeries: 'first_connection_streak',
      popupLabel: 'QUESTIONS IN A ROW',
      progressSelector: (stats) =>
          (stats.categoryLongestStreakCounts['first_connection'] ?? 0),
    ),
    Achievement(
      id: 'first_date_1',
      title: 'First Date',
      description: 'Answer 1 question correctly',
      rarity: AchievementRarity.bronze,
      category: AchievementCategory.firstDate,
      target: 1,
      achievementPoints: 0,
      milestoneSeries: 'first_date_completions',
      popupLabel: 'QUESTIONS CORRECT',
      progressSelector: (stats) =>
          (stats.categoryCorrectCounts['first_date'] ?? 0),
    ),
    Achievement(
      id: 'first_date_25',
      title: 'Getting Acquainted',
      description: 'Answer 25 questions correctly',
      rarity: AchievementRarity.bronze,
      category: AchievementCategory.firstDate,
      target: 25,
      achievementPoints: 0,
      milestoneSeries: 'first_date_completions',
      popupLabel: 'QUESTIONS CORRECT',
      progressSelector: (stats) =>
          (stats.categoryCorrectCounts['first_date'] ?? 0),
    ),
    Achievement(
      id: 'first_date_50',
      title: 'Date Detective',
      description: 'Answer 50 questions correctly',
      rarity: AchievementRarity.silver,
      category: AchievementCategory.firstDate,
      target: 50,
      achievementPoints: 0,
      milestoneSeries: 'first_date_completions',
      popupLabel: 'QUESTIONS CORRECT',
      progressSelector: (stats) =>
          (stats.categoryCorrectCounts['first_date'] ?? 0),
    ),
    Achievement(
      id: 'first_date_100',
      title: 'Date Expert',
      description: 'Answer 100 questions correctly',
      rarity: AchievementRarity.silver,
      category: AchievementCategory.firstDate,
      target: 100,
      achievementPoints: 0,
      milestoneSeries: 'first_date_completions',
      popupLabel: 'QUESTIONS CORRECT',
      progressSelector: (stats) =>
          (stats.categoryCorrectCounts['first_date'] ?? 0),
    ),
    Achievement(
      id: 'first_date_250',
      title: 'Date Master',
      description: 'Answer 250 questions correctly',
      rarity: AchievementRarity.gold,
      category: AchievementCategory.firstDate,
      target: 250,
      achievementPoints: 0,
      milestoneSeries: 'first_date_completions',
      popupLabel: 'QUESTIONS CORRECT',
      progressSelector: (stats) =>
          (stats.categoryCorrectCounts['first_date'] ?? 0),
    ),
    Achievement(
      id: 'first_date_500',
      title: 'First Date Legend',
      description: 'Answer 500 questions correctly',
      rarity: AchievementRarity.diamond,
      category: AchievementCategory.firstDate,
      target: 500,
      achievementPoints: 0,
      milestoneSeries: 'first_date_completions',
      popupLabel: 'QUESTIONS CORRECT',
      progressSelector: (stats) =>
          (stats.categoryCorrectCounts['first_date'] ?? 0),
    ),
    Achievement(
      id: 'first_date_best_10',
      title: 'Perfect Timing',
      description: 'Earn 10 First Guesses',
      rarity: AchievementRarity.bronze,
      category: AchievementCategory.firstDate,
      target: 10,
      achievementPoints: 0,
      milestoneSeries: 'first_date_first_guesses',
      popupLabel: 'FIRST GUESSES',
      progressSelector: (stats) =>
          (stats.categoryFirstGuessCounts['first_date'] ?? 0),
    ),
    Achievement(
      id: 'first_date_best_25',
      title: 'Date Sharp',
      description: 'Earn 25 First Guesses',
      rarity: AchievementRarity.silver,
      category: AchievementCategory.firstDate,
      target: 25,
      achievementPoints: 0,
      milestoneSeries: 'first_date_first_guesses',
      popupLabel: 'FIRST GUESSES',
      progressSelector: (stats) =>
          (stats.categoryFirstGuessCounts['first_date'] ?? 0),
    ),
    Achievement(
      id: 'first_date_best_100',
      title: 'Date Pro',
      description: 'Earn 100 First Guesses',
      rarity: AchievementRarity.gold,
      category: AchievementCategory.firstDate,
      target: 100,
      achievementPoints: 0,
      milestoneSeries: 'first_date_first_guesses',
      popupLabel: 'FIRST GUESSES',
      progressSelector: (stats) =>
          (stats.categoryFirstGuessCounts['first_date'] ?? 0),
    ),
    Achievement(
      id: 'first_date_streak_5',
      title: 'Date Streak',
      description: 'Answer 5 questions correctly in a row',
      rarity: AchievementRarity.bronze,
      category: AchievementCategory.firstDate,
      target: 5,
      achievementPoints: 0,
      milestoneSeries: 'first_date_streak',
      popupLabel: 'QUESTIONS IN A ROW',
      progressSelector: (stats) =>
          (stats.categoryLongestStreakCounts['first_date'] ?? 0),
    ),
    Achievement(
      id: 'first_match_1',
      title: 'First Match',
      description: 'Answer 1 question correctly',
      rarity: AchievementRarity.bronze,
      category: AchievementCategory.firstMatch,
      target: 1,
      achievementPoints: 0,
      milestoneSeries: 'first_match_completions',
      popupLabel: 'QUESTIONS CORRECT',
      progressSelector: (stats) =>
          (stats.categoryCorrectCounts['first_match'] ?? 0),
    ),
    Achievement(
      id: 'first_match_25',
      title: 'Finding Your Feet',
      description: 'Answer 25 questions correctly',
      rarity: AchievementRarity.bronze,
      category: AchievementCategory.firstMatch,
      target: 25,
      achievementPoints: 0,
      milestoneSeries: 'first_match_completions',
      popupLabel: 'QUESTIONS CORRECT',
      progressSelector: (stats) =>
          (stats.categoryCorrectCounts['first_match'] ?? 0),
    ),
    Achievement(
      id: 'first_match_50',
      title: 'Match Maker',
      description: 'Answer 50 questions correctly',
      rarity: AchievementRarity.silver,
      category: AchievementCategory.firstMatch,
      target: 50,
      achievementPoints: 0,
      milestoneSeries: 'first_match_completions',
      popupLabel: 'QUESTIONS CORRECT',
      progressSelector: (stats) =>
          (stats.categoryCorrectCounts['first_match'] ?? 0),
    ),
    Achievement(
      id: 'first_match_100',
      title: 'Match Expert',
      description: 'Answer 100 questions correctly',
      rarity: AchievementRarity.silver,
      category: AchievementCategory.firstMatch,
      target: 100,
      achievementPoints: 0,
      milestoneSeries: 'first_match_completions',
      popupLabel: 'QUESTIONS CORRECT',
      progressSelector: (stats) =>
          (stats.categoryCorrectCounts['first_match'] ?? 0),
    ),
    Achievement(
      id: 'first_match_250',
      title: 'Match Master',
      description: 'Answer 250 questions correctly',
      rarity: AchievementRarity.gold,
      category: AchievementCategory.firstMatch,
      target: 250,
      achievementPoints: 0,
      milestoneSeries: 'first_match_completions',
      popupLabel: 'QUESTIONS CORRECT',
      progressSelector: (stats) =>
          (stats.categoryCorrectCounts['first_match'] ?? 0),
    ),
    Achievement(
      id: 'first_match_500',
      title: 'First Match Legend',
      description: 'Answer 500 questions correctly',
      rarity: AchievementRarity.diamond,
      category: AchievementCategory.firstMatch,
      target: 500,
      achievementPoints: 0,
      milestoneSeries: 'first_match_completions',
      popupLabel: 'QUESTIONS CORRECT',
      progressSelector: (stats) =>
          (stats.categoryCorrectCounts['first_match'] ?? 0),
    ),
    Achievement(
      id: 'first_match_best_10',
      title: 'Perfect Match',
      description: 'Earn 10 First Guesses',
      rarity: AchievementRarity.bronze,
      category: AchievementCategory.firstMatch,
      target: 10,
      achievementPoints: 0,
      milestoneSeries: 'first_match_first_guesses',
      popupLabel: 'FIRST GUESSES',
      progressSelector: (stats) =>
          (stats.categoryFirstGuessCounts['first_match'] ?? 0),
    ),
    Achievement(
      id: 'first_match_best_25',
      title: 'Match Sharp',
      description: 'Earn 25 First Guesses',
      rarity: AchievementRarity.silver,
      category: AchievementCategory.firstMatch,
      target: 25,
      achievementPoints: 0,
      milestoneSeries: 'first_match_first_guesses',
      popupLabel: 'FIRST GUESSES',
      progressSelector: (stats) =>
          (stats.categoryFirstGuessCounts['first_match'] ?? 0),
    ),
    Achievement(
      id: 'first_match_best_100',
      title: 'Match Pro',
      description: 'Earn 100 First Guesses',
      rarity: AchievementRarity.gold,
      category: AchievementCategory.firstMatch,
      target: 100,
      achievementPoints: 0,
      milestoneSeries: 'first_match_first_guesses',
      popupLabel: 'FIRST GUESSES',
      progressSelector: (stats) =>
          (stats.categoryFirstGuessCounts['first_match'] ?? 0),
    ),
    Achievement(
      id: 'first_match_streak_5',
      title: 'Match Streak',
      description: 'Answer 5 questions correctly in a row',
      rarity: AchievementRarity.bronze,
      category: AchievementCategory.firstMatch,
      target: 5,
      achievementPoints: 0,
      milestoneSeries: 'first_match_streak',
      popupLabel: 'QUESTIONS IN A ROW',
      progressSelector: (stats) =>
          (stats.categoryLongestStreakCounts['first_match'] ?? 0),
    ),
    Achievement(
      id: 'first_order_1',
      title: 'Order Up',
      description: 'Answer 1 question correctly',
      rarity: AchievementRarity.bronze,
      category: AchievementCategory.firstOrder,
      target: 1,
      achievementPoints: 0,
      milestoneSeries: 'first_order_completions',
      popupLabel: 'QUESTIONS CORRECT',
      progressSelector: (stats) =>
          (stats.categoryCorrectCounts['first_order'] ?? 0),
    ),
    Achievement(
      id: 'first_order_25',
      title: 'Getting Organised',
      description: 'Answer 25 questions correctly',
      rarity: AchievementRarity.bronze,
      category: AchievementCategory.firstOrder,
      target: 25,
      achievementPoints: 0,
      milestoneSeries: 'first_order_completions',
      popupLabel: 'QUESTIONS CORRECT',
      progressSelector: (stats) =>
          (stats.categoryCorrectCounts['first_order'] ?? 0),
    ),
    Achievement(
      id: 'first_order_50',
      title: 'Order Expert',
      description: 'Answer 50 questions correctly',
      rarity: AchievementRarity.silver,
      category: AchievementCategory.firstOrder,
      target: 50,
      achievementPoints: 0,
      milestoneSeries: 'first_order_completions',
      popupLabel: 'QUESTIONS CORRECT',
      progressSelector: (stats) =>
          (stats.categoryCorrectCounts['first_order'] ?? 0),
    ),
    Achievement(
      id: 'first_order_100',
      title: 'Order Mastermind',
      description: 'Answer 100 questions correctly',
      rarity: AchievementRarity.silver,
      category: AchievementCategory.firstOrder,
      target: 100,
      achievementPoints: 0,
      milestoneSeries: 'first_order_completions',
      popupLabel: 'QUESTIONS CORRECT',
      progressSelector: (stats) =>
          (stats.categoryCorrectCounts['first_order'] ?? 0),
    ),
    Achievement(
      id: 'first_order_250',
      title: 'Order Master',
      description: 'Answer 250 questions correctly',
      rarity: AchievementRarity.gold,
      category: AchievementCategory.firstOrder,
      target: 250,
      achievementPoints: 0,
      milestoneSeries: 'first_order_completions',
      popupLabel: 'QUESTIONS CORRECT',
      progressSelector: (stats) =>
          (stats.categoryCorrectCounts['first_order'] ?? 0),
    ),
    Achievement(
      id: 'first_order_500',
      title: 'First Order Legend',
      description: 'Answer 500 questions correctly',
      rarity: AchievementRarity.diamond,
      category: AchievementCategory.firstOrder,
      target: 500,
      achievementPoints: 0,
      milestoneSeries: 'first_order_completions',
      popupLabel: 'QUESTIONS CORRECT',
      progressSelector: (stats) =>
          (stats.categoryCorrectCounts['first_order'] ?? 0),
    ),
    Achievement(
      id: 'first_order_best_10',
      title: 'Perfect Order',
      description: 'Earn 10 First Guesses',
      rarity: AchievementRarity.bronze,
      category: AchievementCategory.firstOrder,
      target: 10,
      achievementPoints: 0,
      milestoneSeries: 'first_order_first_guesses',
      popupLabel: 'FIRST GUESSES',
      progressSelector: (stats) =>
          (stats.categoryFirstGuessCounts['first_order'] ?? 0),
    ),
    Achievement(
      id: 'first_order_best_25',
      title: 'Order Sharp',
      description: 'Earn 25 First Guesses',
      rarity: AchievementRarity.silver,
      category: AchievementCategory.firstOrder,
      target: 25,
      achievementPoints: 0,
      milestoneSeries: 'first_order_first_guesses',
      popupLabel: 'FIRST GUESSES',
      progressSelector: (stats) =>
          (stats.categoryFirstGuessCounts['first_order'] ?? 0),
    ),
    Achievement(
      id: 'first_order_best_100',
      title: 'Order Pro',
      description: 'Earn 100 First Guesses',
      rarity: AchievementRarity.gold,
      category: AchievementCategory.firstOrder,
      target: 100,
      achievementPoints: 0,
      milestoneSeries: 'first_order_first_guesses',
      popupLabel: 'FIRST GUESSES',
      progressSelector: (stats) =>
          (stats.categoryFirstGuessCounts['first_order'] ?? 0),
    ),
    Achievement(
      id: 'first_order_streak_5',
      title: 'Order Streak',
      description: 'Answer 5 questions correctly in a row',
      rarity: AchievementRarity.bronze,
      category: AchievementCategory.firstOrder,
      target: 5,
      achievementPoints: 0,
      milestoneSeries: 'first_order_streak',
      popupLabel: 'QUESTIONS IN A ROW',
      progressSelector: (stats) =>
          (stats.categoryLongestStreakCounts['first_order'] ?? 0),
    ),
    Achievement(
      id: 'first_word_1',
      title: 'Word Starter',
      description: 'Answer 1 question correctly',
      rarity: AchievementRarity.bronze,
      category: AchievementCategory.firstWord,
      target: 1,
      achievementPoints: 0,
      milestoneSeries: 'first_word_completions',
      popupLabel: 'QUESTIONS CORRECT',
      progressSelector: (stats) =>
          (stats.categoryCorrectCounts['first_word'] ?? 0),
    ),
    Achievement(
      id: 'first_word_25',
      title: 'Getting the Hang of It',
      description: 'Answer 25 questions correctly',
      rarity: AchievementRarity.bronze,
      category: AchievementCategory.firstWord,
      target: 25,
      achievementPoints: 0,
      milestoneSeries: 'first_word_completions',
      popupLabel: 'QUESTIONS CORRECT',
      progressSelector: (stats) =>
          (stats.categoryCorrectCounts['first_word'] ?? 0),
    ),
    Achievement(
      id: 'first_word_50',
      title: 'Word Hunter',
      description: 'Answer 50 questions correctly',
      rarity: AchievementRarity.silver,
      category: AchievementCategory.firstWord,
      target: 50,
      achievementPoints: 0,
      milestoneSeries: 'first_word_completions',
      popupLabel: 'QUESTIONS CORRECT',
      progressSelector: (stats) =>
          (stats.categoryCorrectCounts['first_word'] ?? 0),
    ),
    Achievement(
      id: 'first_word_100',
      title: 'Word Expert',
      description: 'Answer 100 questions correctly',
      rarity: AchievementRarity.silver,
      category: AchievementCategory.firstWord,
      target: 100,
      achievementPoints: 0,
      milestoneSeries: 'first_word_completions',
      popupLabel: 'QUESTIONS CORRECT',
      progressSelector: (stats) =>
          (stats.categoryCorrectCounts['first_word'] ?? 0),
    ),
    Achievement(
      id: 'first_word_250',
      title: 'Word Master',
      description: 'Answer 250 questions correctly',
      rarity: AchievementRarity.gold,
      category: AchievementCategory.firstWord,
      target: 250,
      achievementPoints: 0,
      milestoneSeries: 'first_word_completions',
      popupLabel: 'QUESTIONS CORRECT',
      progressSelector: (stats) =>
          (stats.categoryCorrectCounts['first_word'] ?? 0),
    ),
    Achievement(
      id: 'first_word_500',
      title: 'First Word Legend',
      description: 'Answer 500 questions correctly',
      rarity: AchievementRarity.diamond,
      category: AchievementCategory.firstWord,
      target: 500,
      achievementPoints: 0,
      milestoneSeries: 'first_word_completions',
      popupLabel: 'QUESTIONS CORRECT',
      progressSelector: (stats) =>
          (stats.categoryCorrectCounts['first_word'] ?? 0),
    ),
    Achievement(
      id: 'first_word_first_guesses_10',
      title: 'Quick Thinker',
      description: 'Earn 10 First Guesses',
      rarity: AchievementRarity.bronze,
      category: AchievementCategory.firstWord,
      target: 10,
      achievementPoints: 0,
      milestoneSeries: 'first_word_first_guesses',
      popupLabel: 'FIRST GUESSES',
      progressSelector: (stats) =>
          (stats.categoryFirstGuessCounts['first_word'] ?? 0),
    ),
    Achievement(
      id: 'first_word_first_guesses_25',
      title: 'Sharp Mind',
      description: 'Earn 25 First Guesses',
      rarity: AchievementRarity.silver,
      category: AchievementCategory.firstWord,
      target: 25,
      achievementPoints: 0,
      milestoneSeries: 'first_word_first_guesses',
      popupLabel: 'FIRST GUESSES',
      progressSelector: (stats) =>
          (stats.categoryFirstGuessCounts['first_word'] ?? 0),
    ),
    Achievement(
      id: 'first_word_first_guesses_100',
      title: 'First Guess Pro',
      description: 'Earn 100 First Guesses',
      rarity: AchievementRarity.gold,
      category: AchievementCategory.firstWord,
      target: 100,
      achievementPoints: 0,
      milestoneSeries: 'first_word_first_guesses',
      popupLabel: 'FIRST GUESSES',
      progressSelector: (stats) =>
          (stats.categoryFirstGuessCounts['first_word'] ?? 0),
    ),
    Achievement(
      id: 'first_word_streak_5',
      title: 'Word Streak',
      description: 'Answer 5 questions correctly in a row',
      rarity: AchievementRarity.bronze,
      category: AchievementCategory.firstWord,
      target: 5,
      achievementPoints: 0,
      milestoneSeries: 'first_word_streak',
      popupLabel: 'QUESTIONS IN A ROW',
      progressSelector: (stats) => stats.firstWordLongestStreak,
    ),
    Achievement(
      id: 'xp_1000',
      title: 'XP Starter',
      description: 'Earn 1,000 XP',
      rarity: AchievementRarity.bronze,
      category: AchievementCategory.xp,
      target: 1000,
      achievementPoints: 0,
      progressSelector: (stats) => stats.totalXp,
    ),
    Achievement(
      id: 'xp_5000',
      title: 'XP Hunter',
      description: 'Earn 5,000 XP',
      rarity: AchievementRarity.bronze,
      category: AchievementCategory.xp,
      target: 5000,
      achievementPoints: 0,
      progressSelector: (stats) => stats.totalXp,
    ),
    Achievement(
      id: 'xp_10000',
      title: 'XP Expert',
      description: 'Earn 10,000 XP',
      rarity: AchievementRarity.silver,
      category: AchievementCategory.xp,
      target: 10000,
      achievementPoints: 0,
      progressSelector: (stats) => stats.totalXp,
    ),
    Achievement(
      id: 'xp_25000',
      title: 'XP Legend',
      description: 'Earn 25,000 XP',
      rarity: AchievementRarity.gold,
      category: AchievementCategory.xp,
      target: 25000,
      achievementPoints: 0,
      progressSelector: (stats) => stats.totalXp,
    ),
    Achievement(
      id: 'xp_50000',
      title: 'XP Master',
      description: 'Earn 50,000 XP',
      rarity: AchievementRarity.gold,
      category: AchievementCategory.xp,
      target: 50000,
      achievementPoints: 0,
      progressSelector: (stats) => stats.totalXp,
    ),
    Achievement(
      id: 'xp_100000',
      title: 'XP Elite',
      description: 'Earn 100,000 XP',
      rarity: AchievementRarity.diamond,
      category: AchievementCategory.xp,
      target: 100000,
      achievementPoints: 0,
      progressSelector: (stats) => stats.totalXp,
    ),
    Achievement(
      id: 'xp_250000',
      title: 'XP Champion',
      description: 'Earn 250,000 XP',
      rarity: AchievementRarity.diamond,
      category: AchievementCategory.xp,
      target: 250000,
      achievementPoints: 0,
      progressSelector: (stats) => stats.totalXp,
    ),
    Achievement(
      id: 'xp_500000',
      title: 'XP Superstar',
      description: 'Earn 500,000 XP',
      rarity: AchievementRarity.diamond,
      category: AchievementCategory.xp,
      target: 500000,
      achievementPoints: 0,
      progressSelector: (stats) => stats.totalXp,
    ),
    Achievement(
      id: 'xp_1000000',
      title: 'XP Ultimate',
      description: 'Earn 1,000,000 XP',
      rarity: AchievementRarity.diamond,
      category: AchievementCategory.xp,
      target: 1000000,
      achievementPoints: 0,
      progressSelector: (stats) => stats.totalXp,
    ),
    Achievement(
      id: 'countries_first',
      title: 'First Stamp',
      description: 'Correctly answer your first Countries question',
      rarity: AchievementRarity.bronze,
      category: AchievementCategory.countries,
      target: 1,
      achievementPoints: 0,
      progressSelector: (stats) => (stats.categoryCorrectCounts['countries'] ?? 0),
    ),
    Achievement(
      id: 'countries_25',
      title: 'Explorer',
      description: 'Correctly answer 25 Countries questions',
      rarity: AchievementRarity.bronze,
      category: AchievementCategory.countries,
      target: 25,
      achievementPoints: 0,
      progressSelector: (stats) => (stats.categoryCorrectCounts['countries'] ?? 0),
    ),
    Achievement(
      id: 'countries_100',
      title: 'Globe Trotter',
      description: 'Correctly answer 100 Countries questions',
      rarity: AchievementRarity.silver,
      category: AchievementCategory.countries,
      target: 100,
      achievementPoints: 0,
      progressSelector: (stats) => (stats.categoryCorrectCounts['countries'] ?? 0),
    ),
    Achievement(
      id: 'countries_250',
      title: 'World Master',
      description: 'Correctly answer 250 Countries questions',
      rarity: AchievementRarity.gold,
      category: AchievementCategory.countries,
      target: 250,
      achievementPoints: 0,
      progressSelector: (stats) => (stats.categoryCorrectCounts['countries'] ?? 0),
    ),
    Achievement(
      id: 'countries_500',
      title: 'World Expert',
      description: 'Correctly answer 500 Countries questions',
      rarity: AchievementRarity.diamond,
      category: AchievementCategory.countries,
      target: 500,
      achievementPoints: 0,
      progressSelector: (stats) => (stats.categoryCorrectCounts['countries'] ?? 0),
    ),
    Achievement(
      id: 'countries_1000',
      title: 'Global Legend',
      description: 'Correctly answer 1,000 Countries questions',
      rarity: AchievementRarity.diamond,
      category: AchievementCategory.countries,
      target: 1000,
      achievementPoints: 0,
      progressSelector: (stats) => (stats.categoryCorrectCounts['countries'] ?? 0),
    ),
    Achievement(
      id: 'science_nature_first',
      title: 'Curious Mind',
      description: 'Correctly answer your first Science & Nature question',
      rarity: AchievementRarity.bronze,
      category: AchievementCategory.scienceNature,
      target: 1,
      achievementPoints: 0,
      progressSelector: (stats) => (stats.categoryCorrectCounts['science_nature'] ?? 0),
    ),
    Achievement(
      id: 'science_nature_25',
      title: 'Lab Explorer',
      description: 'Correctly answer 25 Science & Nature questions',
      rarity: AchievementRarity.bronze,
      category: AchievementCategory.scienceNature,
      target: 25,
      achievementPoints: 0,
      progressSelector: (stats) => (stats.categoryCorrectCounts['science_nature'] ?? 0),
    ),
    Achievement(
      id: 'science_nature_100',
      title: 'Science Scholar',
      description: 'Correctly answer 100 Science & Nature questions',
      rarity: AchievementRarity.silver,
      category: AchievementCategory.scienceNature,
      target: 100,
      achievementPoints: 0,
      progressSelector: (stats) => (stats.categoryCorrectCounts['science_nature'] ?? 0),
    ),
    Achievement(
      id: 'science_nature_250',
      title: 'Master of Discovery',
      description: 'Correctly answer 250 Science & Nature questions',
      rarity: AchievementRarity.gold,
      category: AchievementCategory.scienceNature,
      target: 250,
      achievementPoints: 0,
      progressSelector: (stats) => (stats.categoryCorrectCounts['science_nature'] ?? 0),
    ),
    Achievement(
      id: 'science_nature_500',
      title: 'Science Expert',
      description: 'Correctly answer 500 Science & Nature questions',
      rarity: AchievementRarity.diamond,
      category: AchievementCategory.scienceNature,
      target: 500,
      achievementPoints: 0,
      progressSelector: (stats) => (stats.categoryCorrectCounts['science_nature'] ?? 0),
    ),
    Achievement(
      id: 'science_nature_1000',
      title: 'Discovery Legend',
      description: 'Correctly answer 1,000 Science & Nature questions',
      rarity: AchievementRarity.diamond,
      category: AchievementCategory.scienceNature,
      target: 1000,
      achievementPoints: 0,
      progressSelector: (stats) => (stats.categoryCorrectCounts['science_nature'] ?? 0),
    ),
    Achievement(
      id: 'animals_first',
      title: 'Animal Instinct',
      description: 'Correctly answer your first Animals question',
      rarity: AchievementRarity.bronze,
      category: AchievementCategory.animals,
      target: 1,
      achievementPoints: 0,
      progressSelector: (stats) => (stats.categoryCorrectCounts['animals'] ?? 0),
    ),
    Achievement(
      id: 'animals_25',
      title: 'Wildlife Spotter',
      description: 'Correctly answer 25 Animals questions',
      rarity: AchievementRarity.bronze,
      category: AchievementCategory.animals,
      target: 25,
      achievementPoints: 0,
      progressSelector: (stats) => (stats.categoryCorrectCounts['animals'] ?? 0),
    ),
    Achievement(
      id: 'animals_100',
      title: 'Wildlife Expert',
      description: 'Correctly answer 100 Animals questions',
      rarity: AchievementRarity.silver,
      category: AchievementCategory.animals,
      target: 100,
      achievementPoints: 0,
      progressSelector: (stats) => (stats.categoryCorrectCounts['animals'] ?? 0),
    ),
    Achievement(
      id: 'animals_250',
      title: 'Animal Kingdom Master',
      description: 'Correctly answer 250 Animals questions',
      rarity: AchievementRarity.gold,
      category: AchievementCategory.animals,
      target: 250,
      achievementPoints: 0,
      progressSelector: (stats) => (stats.categoryCorrectCounts['animals'] ?? 0),
    ),
    Achievement(
      id: 'animals_500',
      title: 'Wildlife Master',
      description: 'Correctly answer 500 Animals questions',
      rarity: AchievementRarity.diamond,
      category: AchievementCategory.animals,
      target: 500,
      achievementPoints: 0,
      progressSelector: (stats) => (stats.categoryCorrectCounts['animals'] ?? 0),
    ),
    Achievement(
      id: 'animals_1000',
      title: 'Animal Legend',
      description: 'Correctly answer 1,000 Animals questions',
      rarity: AchievementRarity.diamond,
      category: AchievementCategory.animals,
      target: 1000,
      achievementPoints: 0,
      progressSelector: (stats) => (stats.categoryCorrectCounts['animals'] ?? 0),
    ),
    Achievement(
      id: 'watch_play_first',
      title: 'Opening Scene',
      description: 'Correctly answer your first Watch & Play question',
      rarity: AchievementRarity.bronze,
      category: AchievementCategory.watchPlay,
      target: 1,
      achievementPoints: 0,
      progressSelector: (stats) => (stats.categoryCorrectCounts['watch_play'] ?? 0),
    ),
    Achievement(
      id: 'watch_play_25',
      title: 'Screen Fan',
      description: 'Correctly answer 25 Watch & Play questions',
      rarity: AchievementRarity.bronze,
      category: AchievementCategory.watchPlay,
      target: 25,
      achievementPoints: 0,
      progressSelector: (stats) => (stats.categoryCorrectCounts['watch_play'] ?? 0),
    ),
    Achievement(
      id: 'watch_play_100',
      title: 'Screen Expert',
      description: 'Correctly answer 100 Watch & Play questions',
      rarity: AchievementRarity.silver,
      category: AchievementCategory.watchPlay,
      target: 100,
      achievementPoints: 0,
      progressSelector: (stats) => (stats.categoryCorrectCounts['watch_play'] ?? 0),
    ),
    Achievement(
      id: 'watch_play_250',
      title: 'Entertainment Legend',
      description: 'Correctly answer 250 Watch & Play questions',
      rarity: AchievementRarity.gold,
      category: AchievementCategory.watchPlay,
      target: 250,
      achievementPoints: 0,
      progressSelector: (stats) => (stats.categoryCorrectCounts['watch_play'] ?? 0),
    ),
    Achievement(
      id: 'watch_play_500',
      title: 'Screen Master',
      description: 'Correctly answer 500 Watch & Play questions',
      rarity: AchievementRarity.diamond,
      category: AchievementCategory.watchPlay,
      target: 500,
      achievementPoints: 0,
      progressSelector: (stats) => (stats.categoryCorrectCounts['watch_play'] ?? 0),
    ),
    Achievement(
      id: 'watch_play_1000',
      title: 'Watch & Play Legend',
      description: 'Correctly answer 1,000 Watch & Play questions',
      rarity: AchievementRarity.diamond,
      category: AchievementCategory.watchPlay,
      target: 1000,
      achievementPoints: 0,
      progressSelector: (stats) => (stats.categoryCorrectCounts['watch_play'] ?? 0),
    ),
    Achievement(
      id: 'music_first',
      title: 'First Note',
      description: 'Correctly answer your first Music question',
      rarity: AchievementRarity.bronze,
      category: AchievementCategory.music,
      target: 1,
      achievementPoints: 0,
      progressSelector: (stats) => (stats.categoryCorrectCounts['music'] ?? 0),
    ),
    Achievement(
      id: 'music_25',
      title: 'Music Fan',
      description: 'Correctly answer 25 Music questions',
      rarity: AchievementRarity.bronze,
      category: AchievementCategory.music,
      target: 25,
      achievementPoints: 0,
      progressSelector: (stats) => (stats.categoryCorrectCounts['music'] ?? 0),
    ),
    Achievement(
      id: 'music_100',
      title: 'Music Maestro',
      description: 'Correctly answer 100 Music questions',
      rarity: AchievementRarity.silver,
      category: AchievementCategory.music,
      target: 100,
      achievementPoints: 0,
      progressSelector: (stats) => (stats.categoryCorrectCounts['music'] ?? 0),
    ),
    Achievement(
      id: 'music_250',
      title: 'Music Legend',
      description: 'Correctly answer 250 Music questions',
      rarity: AchievementRarity.gold,
      category: AchievementCategory.music,
      target: 250,
      achievementPoints: 0,
      progressSelector: (stats) => (stats.categoryCorrectCounts['music'] ?? 0),
    ),
    Achievement(
      id: 'music_500',
      title: 'Music Master',
      description: 'Correctly answer 500 Music questions',
      rarity: AchievementRarity.diamond,
      category: AchievementCategory.music,
      target: 500,
      achievementPoints: 0,
      progressSelector: (stats) => (stats.categoryCorrectCounts['music'] ?? 0),
    ),
    Achievement(
      id: 'music_1000',
      title: 'Sound Legend',
      description: 'Correctly answer 1,000 Music questions',
      rarity: AchievementRarity.diamond,
      category: AchievementCategory.music,
      target: 1000,
      achievementPoints: 0,
      progressSelector: (stats) => (stats.categoryCorrectCounts['music'] ?? 0),
    ),
    Achievement(
      id: 'famous_people_first',
      title: 'First Identity',
      description: 'Correctly answer your first Who Am I? question',
      rarity: AchievementRarity.bronze,
      category: AchievementCategory.whoAmI,
      target: 1,
      achievementPoints: 0,
      progressSelector: (stats) => (stats.categoryCorrectCounts['famous_people'] ?? 0),
    ),
    Achievement(
      id: 'famous_people_25',
      title: 'Familiar Face',
      description: 'Correctly answer 25 Who Am I? questions',
      rarity: AchievementRarity.bronze,
      category: AchievementCategory.whoAmI,
      target: 25,
      achievementPoints: 0,
      progressSelector: (stats) => (stats.categoryCorrectCounts['famous_people'] ?? 0),
    ),
    Achievement(
      id: 'famous_people_100',
      title: 'Identity Expert',
      description: 'Correctly answer 100 Who Am I? questions',
      rarity: AchievementRarity.silver,
      category: AchievementCategory.whoAmI,
      target: 100,
      achievementPoints: 0,
      progressSelector: (stats) => (stats.categoryCorrectCounts['famous_people'] ?? 0),
    ),
    Achievement(
      id: 'famous_people_250',
      title: 'Master of Who Am I?',
      description: 'Correctly answer 250 Who Am I? questions',
      rarity: AchievementRarity.gold,
      category: AchievementCategory.whoAmI,
      target: 250,
      achievementPoints: 0,
      progressSelector: (stats) => (stats.categoryCorrectCounts['famous_people'] ?? 0),
    ),
    Achievement(
      id: 'famous_people_500',
      title: 'Identity Master',
      description: 'Correctly answer 500 Who Am I? questions',
      rarity: AchievementRarity.diamond,
      category: AchievementCategory.whoAmI,
      target: 500,
      achievementPoints: 0,
      progressSelector: (stats) => (stats.categoryCorrectCounts['famous_people'] ?? 0),
    ),
    Achievement(
      id: 'famous_people_1000',
      title: 'Who Am I? Legend',
      description: 'Correctly answer 1,000 Who Am I? questions',
      rarity: AchievementRarity.diamond,
      category: AchievementCategory.whoAmI,
      target: 1000,
      achievementPoints: 0,
      progressSelector: (stats) => (stats.categoryCorrectCounts['famous_people'] ?? 0),
    ),
    Achievement(
      id: 'books_authors_first',
      title: 'First Chapter',
      description: 'Correctly answer your first Books & Authors question',
      rarity: AchievementRarity.bronze,
      category: AchievementCategory.booksAuthors,
      target: 1,
      achievementPoints: 0,
      progressSelector: (stats) => (stats.categoryCorrectCounts['books_authors'] ?? 0),
    ),
    Achievement(
      id: 'books_authors_25',
      title: 'Bookworm',
      description: 'Correctly answer 25 Books & Authors questions',
      rarity: AchievementRarity.bronze,
      category: AchievementCategory.booksAuthors,
      target: 25,
      achievementPoints: 0,
      progressSelector: (stats) => (stats.categoryCorrectCounts['books_authors'] ?? 0),
    ),
    Achievement(
      id: 'books_authors_100',
      title: 'Literary Expert',
      description: 'Correctly answer 100 Books & Authors questions',
      rarity: AchievementRarity.silver,
      category: AchievementCategory.booksAuthors,
      target: 100,
      achievementPoints: 0,
      progressSelector: (stats) => (stats.categoryCorrectCounts['books_authors'] ?? 0),
    ),
    Achievement(
      id: 'books_authors_250',
      title: 'Literary Legend',
      description: 'Correctly answer 250 Books & Authors questions',
      rarity: AchievementRarity.gold,
      category: AchievementCategory.booksAuthors,
      target: 250,
      achievementPoints: 0,
      progressSelector: (stats) => (stats.categoryCorrectCounts['books_authors'] ?? 0),
    ),
    Achievement(
      id: 'books_authors_500',
      title: 'Literary Master',
      description: 'Correctly answer 500 Books & Authors questions',
      rarity: AchievementRarity.diamond,
      category: AchievementCategory.booksAuthors,
      target: 500,
      achievementPoints: 0,
      progressSelector: (stats) => (stats.categoryCorrectCounts['books_authors'] ?? 0),
    ),
    Achievement(
      id: 'books_authors_1000',
      title: 'Book & Author Legend',
      description: 'Correctly answer 1,000 Books & Authors questions',
      rarity: AchievementRarity.diamond,
      category: AchievementCategory.booksAuthors,
      target: 1000,
      achievementPoints: 0,
      progressSelector: (stats) => (stats.categoryCorrectCounts['books_authors'] ?? 0),
    ),
    Achievement(
      id: 'past_present_first',
      title: 'History Begins',
      description: 'Correctly answer your first Past Worlds question',
      rarity: AchievementRarity.bronze,
      category: AchievementCategory.pastPresent,
      target: 1,
      achievementPoints: 0,
      progressSelector: (stats) => (stats.categoryCorrectCounts['past_present'] ?? 0),
    ),
    Achievement(
      id: 'past_present_25',
      title: 'Time Traveller',
      description: 'Correctly answer 25 Past Worlds questions',
      rarity: AchievementRarity.bronze,
      category: AchievementCategory.pastPresent,
      target: 25,
      achievementPoints: 0,
      progressSelector: (stats) => (stats.categoryCorrectCounts['past_present'] ?? 0),
    ),
    Achievement(
      id: 'past_present_100',
      title: 'History Expert',
      description: 'Correctly answer 100 Past Worlds questions',
      rarity: AchievementRarity.silver,
      category: AchievementCategory.pastPresent,
      target: 100,
      achievementPoints: 0,
      progressSelector: (stats) => (stats.categoryCorrectCounts['past_present'] ?? 0),
    ),
    Achievement(
      id: 'past_present_250',
      title: 'Master Historian',
      description: 'Correctly answer 250 Past Worlds questions',
      rarity: AchievementRarity.gold,
      category: AchievementCategory.pastPresent,
      target: 250,
      achievementPoints: 0,
      progressSelector: (stats) => (stats.categoryCorrectCounts['past_present'] ?? 0),
    ),
    Achievement(
      id: 'past_present_500',
      title: 'History Master',
      description: 'Correctly answer 500 Past Worlds questions',
      rarity: AchievementRarity.diamond,
      category: AchievementCategory.pastPresent,
      target: 500,
      achievementPoints: 0,
      progressSelector: (stats) => (stats.categoryCorrectCounts['past_present'] ?? 0),
    ),
    Achievement(
      id: 'past_present_1000',
      title: 'Past Worlds Legend',
      description: 'Correctly answer 1,000 Past Worlds questions',
      rarity: AchievementRarity.diamond,
      category: AchievementCategory.pastPresent,
      target: 1000,
      achievementPoints: 0,
      progressSelector: (stats) => (stats.categoryCorrectCounts['past_present'] ?? 0),
    ),
    Achievement(
      id: 'food_drink_first',
      title: 'First Bite',
      description: 'Correctly answer your first Flavors of the World question',
      rarity: AchievementRarity.bronze,
      category: AchievementCategory.foodDrink,
      target: 1,
      achievementPoints: 0,
      progressSelector: (stats) => (stats.categoryCorrectCounts['food_drink'] ?? 0),
    ),
    Achievement(
      id: 'food_drink_25',
      title: 'Food Explorer',
      description: 'Correctly answer 25 Flavors of the World questions',
      rarity: AchievementRarity.bronze,
      category: AchievementCategory.foodDrink,
      target: 25,
      achievementPoints: 0,
      progressSelector: (stats) => (stats.categoryCorrectCounts['food_drink'] ?? 0),
    ),
    Achievement(
      id: 'food_drink_100',
      title: 'Culinary Expert',
      description: 'Correctly answer 100 Flavors of the World questions',
      rarity: AchievementRarity.silver,
      category: AchievementCategory.foodDrink,
      target: 100,
      achievementPoints: 0,
      progressSelector: (stats) => (stats.categoryCorrectCounts['food_drink'] ?? 0),
    ),
    Achievement(
      id: 'food_drink_250',
      title: 'World Food Master',
      description: 'Correctly answer 250 Flavors of the World questions',
      rarity: AchievementRarity.gold,
      category: AchievementCategory.foodDrink,
      target: 250,
      achievementPoints: 0,
      progressSelector: (stats) => (stats.categoryCorrectCounts['food_drink'] ?? 0),
    ),
    Achievement(
      id: 'food_drink_500',
      title: 'Culinary Master',
      description: 'Correctly answer 500 Flavors of the World questions',
      rarity: AchievementRarity.diamond,
      category: AchievementCategory.foodDrink,
      target: 500,
      achievementPoints: 0,
      progressSelector: (stats) => (stats.categoryCorrectCounts['food_drink'] ?? 0),
    ),
    Achievement(
      id: 'food_drink_1000',
      title: 'Flavors Legend',
      description: 'Correctly answer 1,000 Flavors of the World questions',
      rarity: AchievementRarity.diamond,
      category: AchievementCategory.foodDrink,
      target: 1000,
      achievementPoints: 0,
      progressSelector: (stats) => (stats.categoryCorrectCounts['food_drink'] ?? 0),
    ),
    Achievement(
      id: 'creative_world_first',
      title: 'Creative Spark',
      description: 'Correctly answer your first Creative World question',
      rarity: AchievementRarity.bronze,
      category: AchievementCategory.creativeWorld,
      target: 1,
      achievementPoints: 0,
      progressSelector: (stats) => (stats.categoryCorrectCounts['creative_world'] ?? 0),
    ),
    Achievement(
      id: 'creative_world_25',
      title: 'Art Explorer',
      description: 'Correctly answer 25 Creative World questions',
      rarity: AchievementRarity.bronze,
      category: AchievementCategory.creativeWorld,
      target: 25,
      achievementPoints: 0,
      progressSelector: (stats) => (stats.categoryCorrectCounts['creative_world'] ?? 0),
    ),
    Achievement(
      id: 'creative_world_100',
      title: 'Creative Expert',
      description: 'Correctly answer 100 Creative World questions',
      rarity: AchievementRarity.silver,
      category: AchievementCategory.creativeWorld,
      target: 100,
      achievementPoints: 0,
      progressSelector: (stats) => (stats.categoryCorrectCounts['creative_world'] ?? 0),
    ),
    Achievement(
      id: 'creative_world_250',
      title: 'Creative Master',
      description: 'Correctly answer 250 Creative World questions',
      rarity: AchievementRarity.gold,
      category: AchievementCategory.creativeWorld,
      target: 250,
      achievementPoints: 0,
      progressSelector: (stats) => (stats.categoryCorrectCounts['creative_world'] ?? 0),
    ),
    Achievement(
      id: 'creative_world_500',
      title: 'Creative Virtuoso',
      description: 'Correctly answer 500 Creative World questions',
      rarity: AchievementRarity.diamond,
      category: AchievementCategory.creativeWorld,
      target: 500,
      achievementPoints: 0,
      progressSelector: (stats) => (stats.categoryCorrectCounts['creative_world'] ?? 0),
    ),
    Achievement(
      id: 'creative_world_1000',
      title: 'Creative Legend',
      description: 'Correctly answer 1,000 Creative World questions',
      rarity: AchievementRarity.diamond,
      category: AchievementCategory.creativeWorld,
      target: 1000,
      achievementPoints: 0,
      progressSelector: (stats) => (stats.categoryCorrectCounts['creative_world'] ?? 0),
    ),
    Achievement(
      id: 'sports_first',
      title: 'First Whistle',
      description: 'Correctly answer your first Sports question',
      rarity: AchievementRarity.bronze,
      category: AchievementCategory.sports,
      target: 1,
      achievementPoints: 0,
      progressSelector: (stats) => (stats.categoryCorrectCounts['sports'] ?? 0),
    ),
    Achievement(
      id: 'sports_25',
      title: 'Sports Fan',
      description: 'Correctly answer 25 Sports questions',
      rarity: AchievementRarity.bronze,
      category: AchievementCategory.sports,
      target: 25,
      achievementPoints: 0,
      progressSelector: (stats) => (stats.categoryCorrectCounts['sports'] ?? 0),
    ),
    Achievement(
      id: 'sports_100',
      title: 'Sports Expert',
      description: 'Correctly answer 100 Sports questions',
      rarity: AchievementRarity.silver,
      category: AchievementCategory.sports,
      target: 100,
      achievementPoints: 0,
      progressSelector: (stats) => (stats.categoryCorrectCounts['sports'] ?? 0),
    ),
    Achievement(
      id: 'sports_250',
      title: 'Sporting Legend',
      description: 'Correctly answer 250 Sports questions',
      rarity: AchievementRarity.gold,
      category: AchievementCategory.sports,
      target: 250,
      achievementPoints: 0,
      progressSelector: (stats) => (stats.categoryCorrectCounts['sports'] ?? 0),
    ),
    Achievement(
      id: 'sports_500',
      title: 'Sports Master',
      description: 'Correctly answer 500 Sports questions',
      rarity: AchievementRarity.diamond,
      category: AchievementCategory.sports,
      target: 500,
      achievementPoints: 0,
      progressSelector: (stats) => (stats.categoryCorrectCounts['sports'] ?? 0),
    ),
    Achievement(
      id: 'sports_1000',
      title: 'Ultimate Sports Fan',
      description: 'Correctly answer 1,000 Sports questions',
      rarity: AchievementRarity.diamond,
      category: AchievementCategory.sports,
      target: 1000,
      achievementPoints: 0,
      progressSelector: (stats) => (stats.categoryCorrectCounts['sports'] ?? 0),
    ),
    Achievement(
      id: 'famous_words_first',
      title: 'Quote Starter',
      description: 'Correctly answer your first Famous Words question',
      rarity: AchievementRarity.bronze,
      category: AchievementCategory.famousWords,
      target: 1,
      achievementPoints: 0,
      progressSelector: (stats) => (stats.categoryCorrectCounts['famous_words'] ?? 0),
    ),
    Achievement(
      id: 'famous_words_25',
      title: 'Word Spotter',
      description: 'Correctly answer 25 Famous Words questions',
      rarity: AchievementRarity.bronze,
      category: AchievementCategory.famousWords,
      target: 25,
      achievementPoints: 0,
      progressSelector: (stats) => (stats.categoryCorrectCounts['famous_words'] ?? 0),
    ),
    Achievement(
      id: 'famous_words_100',
      title: 'Quote Expert',
      description: 'Correctly answer 100 Famous Words questions',
      rarity: AchievementRarity.silver,
      category: AchievementCategory.famousWords,
      target: 100,
      achievementPoints: 0,
      progressSelector: (stats) => (stats.categoryCorrectCounts['famous_words'] ?? 0),
    ),
    Achievement(
      id: 'famous_words_250',
      title: 'Famous Words Master',
      description: 'Correctly answer 250 Famous Words questions',
      rarity: AchievementRarity.gold,
      category: AchievementCategory.famousWords,
      target: 250,
      achievementPoints: 0,
      progressSelector: (stats) => (stats.categoryCorrectCounts['famous_words'] ?? 0),
    ),
    Achievement(
      id: 'famous_words_500',
      title: 'Quotation Master',
      description: 'Correctly answer 500 Famous Words questions',
      rarity: AchievementRarity.diamond,
      category: AchievementCategory.famousWords,
      target: 500,
      achievementPoints: 0,
      progressSelector: (stats) => (stats.categoryCorrectCounts['famous_words'] ?? 0),
    ),
    Achievement(
      id: 'famous_words_1000',
      title: 'Famous Words Legend',
      description: 'Correctly answer 1,000 Famous Words questions',
      rarity: AchievementRarity.diamond,
      category: AchievementCategory.famousWords,
      target: 1000,
      achievementPoints: 0,
      progressSelector: (stats) => (stats.categoryCorrectCounts['famous_words'] ?? 0),
    ),
  ];

  static List<Achievement> unlockedAchievements(
    PlayerStats stats,
  ) {
    return achievements
        .where((achievement) => achievement.isUnlocked(stats))
        .toList();
  }

  static List<Achievement> lockedAchievements(
    PlayerStats stats,
  ) {
    return achievements
        .where((achievement) => !achievement.isUnlocked(stats))
        .toList();
  }

  static int unlockedCount(PlayerStats stats) {
    return unlockedAchievements(stats).length;
  }

  static int totalAchievementPoints(PlayerStats stats) {
    return unlockedAchievements(stats).fold<int>(
      0,
      (total, achievement) {
        return total + achievement.achievementPoints;
      },
    );
  }

  static List<Achievement> achievementsForCategory(
    AchievementCategory category,
  ) {
    return achievements
        .where((achievement) => achievement.category == category)
        .toList();
  }

  static List<Achievement> newlyReachedMilestones({
    required PlayerStats previous,
    required PlayerStats current,
  }) {
    return achievements.where((Achievement achievement) {
      final int before = achievement.progress(previous);
      final int after = achievement.progress(current);

      return before < achievement.target &&
          after >= achievement.target;
    }).toList();
  }

  static Achievement? nextMilestoneAfter(
    Achievement achievement,
  ) {
    final List<Achievement> sameCategory = achievements
        .where(
          (Achievement candidate) =>
              candidate.category == achievement.category &&
              candidate.milestoneSeries == achievement.milestoneSeries &&
              candidate.target > achievement.target,
        )
        .toList()
      ..sort(
        (Achievement first, Achievement second) =>
            first.target.compareTo(second.target),
      );

    return sameCategory.isEmpty ? null : sameCategory.first;
  }

  static String milestoneLabelFor(
    Achievement achievement,
  ) {
    return achievement.popupLabel ?? milestoneLabel(achievement.category);
  }

  static String milestoneLabel(
    AchievementCategory category,
  ) {
    switch (category) {
      case AchievementCategory.general:
        return 'CORRECT ANSWERS';
      case AchievementCategory.firstGuess:
        return 'FIRST GUESSES';
      case AchievementCategory.streak:
        return 'GAME STREAK';
      case AchievementCategory.xp:
        return 'XP';
      case AchievementCategory.dailyFlash:
        return 'DAILY FLASH 5s';
      case AchievementCategory.firstConnection:
        return 'FIRST CONNECTION';
      case AchievementCategory.firstDate:
        return 'FIRST DATE';
      case AchievementCategory.firstMatch:
        return 'FIRST MATCH';
      case AchievementCategory.firstOrder:
        return 'FIRST ORDER';
      case AchievementCategory.firstWord:
        return 'FIRST WORD';
      case AchievementCategory.countries:
        return 'COUNTRIES';
      case AchievementCategory.scienceNature:
        return 'SCIENCE & NATURE';
      case AchievementCategory.animals:
        return 'ANIMALS';
      case AchievementCategory.watchPlay:
        return 'WATCH & PLAY';
      case AchievementCategory.music:
        return 'MUSIC';
      case AchievementCategory.whoAmI:
        return 'WHO AM I?';
      case AchievementCategory.booksAuthors:
        return 'BOOKS & AUTHORS';
      case AchievementCategory.pastPresent:
        return 'PAST WORLDS';
      case AchievementCategory.foodDrink:
        return 'FLAVORS OF THE WORLD';
      case AchievementCategory.creativeWorld:
        return 'CREATIVE WORLD';
      case AchievementCategory.sports:
        return 'SPORTS';
      case AchievementCategory.famousWords:
        return 'FAMOUS WORDS';
    }
  }


  static const Set<AchievementCategory> _classicCategoryAchievements =
      <AchievementCategory>{
    AchievementCategory.animals,
    AchievementCategory.booksAuthors,
    AchievementCategory.countries,
    AchievementCategory.creativeWorld,
    AchievementCategory.famousWords,
    AchievementCategory.foodDrink,
    AchievementCategory.music,
    AchievementCategory.pastPresent,
    AchievementCategory.scienceNature,
    AchievementCategory.sports,
    AchievementCategory.watchPlay,
    AchievementCategory.whoAmI,
  };

  static Achievement? _highestTarget(
    Iterable<Achievement> values,
  ) {
    Achievement? highest;
    for (final Achievement achievement in values) {
      if (highest == null || achievement.target > highest.target) {
        highest = achievement;
      }
    }
    return highest;
  }

  static int _classicCorrectCount(PlayerStats stats) {
    const List<String> keys = <String>[
      'animals',
      'books_authors',
      'countries',
      'creative_world',
      'famous_words',
      'food_drink',
      'music',
      'past_present',
      'science_nature',
      'sports',
      'watch_play',
      'famous_people',
    ];

    int total = 0;
    for (final String key in keys) {
      total += stats.categoryCorrectCounts[key] ?? 0;
    }
    return total;
  }

  /// Returns every newly earned badge for one completed answer.
  /// Multiple badges are intentionally allowed to pop from the same action.
  /// The list is ordered Game badge -> General Clue badge. A Case File badge,
  /// when relevant, is shown by the Case File flow before this list.
  static List<EarnedBadge> newlyEarnedBadges({
    required PlayerStats previous,
    required PlayerStats current,
    required String gameKey,
    required String gameLabel,
  }) {
    final List<EarnedBadge> earned = <EarnedBadge>[];

    final int beforeGame = gameKey == 'first_guess'
        ? _classicCorrectCount(previous)
        : (previous.categoryCorrectCounts[gameKey] ?? 0);
    final int afterGame = gameKey == 'first_guess'
        ? _classicCorrectCount(current)
        : (current.categoryCorrectCounts[gameKey] ?? 0);

    const List<MapEntry<int, String>> gameTiers = <MapEntry<int, String>>[
      MapEntry<int, String>(10, 'starter'),
      MapEntry<int, String>(50, 'advanced'),
      MapEntry<int, String>(150, 'expert'),
      MapEntry<int, String>(500, 'master'),
      MapEntry<int, String>(1000, 'legend'),
    ];

    for (final MapEntry<int, String> tier in gameTiers) {
      if (beforeGame < tier.key && afterGame >= tier.key) {
        final String displayTier =
            '${tier.value[0].toUpperCase()}${tier.value.substring(1)}';
        earned.add(
          EarnedBadge(
            name: '$gameLabel $displayTier Badge',
            imageAsset:
                'assets/images/badges/final/game_badges/${gameKey}_${tier.value}.webp',
          ),
        );
      }
    }

    const List<MapEntry<int, String>> clueTiers = <MapEntry<int, String>>[
      MapEntry<int, String>(1500, 'starter'),
      MapEntry<int, String>(15000, 'advanced'),
      MapEntry<int, String>(37500, 'expert'),
      MapEntry<int, String>(75000, 'master'),
      MapEntry<int, String>(150000, 'elite'),
    ];

    for (final MapEntry<int, String> tier in clueTiers) {
      if (previous.totalXp < tier.key && current.totalXp >= tier.key) {
        final String displayTier =
            '${tier.value[0].toUpperCase()}${tier.value.substring(1)}';
        earned.add(
          EarnedBadge(
            name: 'Clue $displayTier Badge',
            imageAsset:
                'assets/images/badges/final/clue/clue_${tier.value}.webp',
          ),
        );
      }
    }

    return earned;
  }

  /// Classic First Guess popup priority when no badge or level/rank popup wins:
  /// Overall Correct Answers -> First Guess -> Winning Streak -> XP -> Category.
  /// XP + Winning Streak are the one achievement pair allowed to both pop.
  static List<Achievement> popupAchievementsForClassic({
    required PlayerStats previous,
    required PlayerStats current,
  }) {
    final List<Achievement> reached = newlyReachedMilestones(
      previous: previous,
      current: current,
    );

    final Achievement? overall = _highestTarget(
      reached.where((a) => a.category == AchievementCategory.general),
    );
    if (overall != null) {
      return <Achievement>[overall];
    }

    final Achievement? firstGuess = _highestTarget(
      reached.where((a) => a.category == AchievementCategory.firstGuess),
    );
    if (firstGuess != null) {
      return <Achievement>[firstGuess];
    }

    final Achievement? streak = _highestTarget(
      reached.where((a) => a.category == AchievementCategory.streak),
    );
    final Achievement? xp = _highestTarget(
      reached.where((a) => a.category == AchievementCategory.xp),
    );

    if (streak != null && xp != null) {
      return <Achievement>[streak, xp];
    }
    if (streak != null) {
      return <Achievement>[streak];
    }
    if (xp != null) {
      return <Achievement>[xp];
    }

    final Achievement? category = _highestTarget(
      reached.where(
        (a) => _classicCategoryAchievements.contains(a.category),
      ),
    );
    return category == null ? <Achievement>[] : <Achievement>[category];
  }

  /// Non-Classic game priority when no badge or level/rank popup wins:
  /// First Guess -> game streak -> correct-answer total. If the chosen game
  /// streak and an XP achievement land together, both are shown.
  static List<Achievement> popupAchievementsForGame({
    required PlayerStats previous,
    required PlayerStats current,
    required AchievementCategory gameCategory,
  }) {
    final List<Achievement> reached = newlyReachedMilestones(
      previous: previous,
      current: current,
    );

    final List<Achievement> gameReached = reached
        .where((a) => a.category == gameCategory)
        .toList();

    final Achievement? firstGuess = _highestTarget(
      gameReached.where(
        (a) => (a.milestoneSeries ?? '').contains('first_guesses'),
      ),
    );
    if (firstGuess != null) {
      return <Achievement>[firstGuess];
    }

    final Achievement? streak = _highestTarget(
      gameReached.where(
        (a) => (a.milestoneSeries ?? '').endsWith('_streak'),
      ),
    );
    final Achievement? xp = _highestTarget(
      reached.where((a) => a.category == AchievementCategory.xp),
    );

    if (streak != null && xp != null) {
      return <Achievement>[streak, xp];
    }
    if (streak != null) {
      return <Achievement>[streak];
    }

    final Achievement? completion = _highestTarget(
      gameReached.where(
        (a) => (a.milestoneSeries ?? '').endsWith('_completions'),
      ),
    );
    if (completion != null) {
      return <Achievement>[completion];
    }

    return xp == null ? <Achievement>[] : <Achievement>[xp];
  }

}
