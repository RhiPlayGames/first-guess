import 'player_stats_service.dart';

enum AchievementRarity {
  bronze,
  silver,
  gold,
  diamond,
}

enum AchievementCategory {
  general,
  countries,
  firstGuess,
  streak,
  score,
  xp,
  dailyFlash,
  flags,
  movies,
  books,
  animals,
  footballTeams,
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

  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.rarity,
    required this.category,
    required this.target,
    required this.achievementPoints,
    required this.progressSelector,
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

class AchievementService {
  AchievementService._();

  static final List<Achievement> achievements = [
    Achievement(
      id: 'first_game',
      title: 'First Steps',
      description: 'Play your first game',
      rarity: AchievementRarity.bronze,
      category: AchievementCategory.general,
      target: 1,
      achievementPoints: 10,
      progressSelector: (stats) => stats.gamesPlayed,
    ),
    Achievement(
      id: 'games_10',
      title: 'Getting Started',
      description: 'Play 10 games',
      rarity: AchievementRarity.bronze,
      category: AchievementCategory.general,
      target: 10,
      achievementPoints: 20,
      progressSelector: (stats) => stats.gamesPlayed,
    ),
    Achievement(
      id: 'games_50',
      title: 'Dedicated Player',
      description: 'Play 50 games',
      rarity: AchievementRarity.silver,
      category: AchievementCategory.general,
      target: 50,
      achievementPoints: 50,
      progressSelector: (stats) => stats.gamesPlayed,
    ),
    Achievement(
      id: 'games_100',
      title: 'Century Club',
      description: 'Play 100 games',
      rarity: AchievementRarity.gold,
      category: AchievementCategory.general,
      target: 100,
      achievementPoints: 100,
      progressSelector: (stats) => stats.gamesPlayed,
    ),
    Achievement(
      id: 'games_500',
      title: 'First Guess Legend',
      description: 'Play 500 games',
      rarity: AchievementRarity.diamond,
      category: AchievementCategory.general,
      target: 500,
      achievementPoints: 250,
      progressSelector: (stats) => stats.gamesPlayed,
    ),

    Achievement(
      id: 'country_1',
      title: 'First Country',
      description: 'Correctly identify your first country',
      rarity: AchievementRarity.bronze,
      category: AchievementCategory.countries,
      target: 1,
      achievementPoints: 10,
      progressSelector: (stats) => stats.countriesCompleted,
    ),
    Achievement(
      id: 'countries_10',
      title: 'Explorer',
      description: 'Correctly identify 10 countries',
      rarity: AchievementRarity.bronze,
      category: AchievementCategory.countries,
      target: 10,
      achievementPoints: 25,
      progressSelector: (stats) => stats.countriesCompleted,
    ),
    Achievement(
      id: 'countries_25',
      title: 'World Traveller',
      description: 'Correctly identify 25 countries',
      rarity: AchievementRarity.silver,
      category: AchievementCategory.countries,
      target: 25,
      achievementPoints: 50,
      progressSelector: (stats) => stats.countriesCompleted,
    ),
    Achievement(
      id: 'countries_50',
      title: 'Globe Trotter',
      description: 'Correctly identify 50 countries',
      rarity: AchievementRarity.gold,
      category: AchievementCategory.countries,
      target: 50,
      achievementPoints: 100,
      progressSelector: (stats) => stats.countriesCompleted,
    ),
    Achievement(
      id: 'countries_100',
      title: 'Geography Master',
      description: 'Correctly identify 100 countries',
      rarity: AchievementRarity.diamond,
      category: AchievementCategory.countries,
      target: 100,
      achievementPoints: 250,
      progressSelector: (stats) => stats.countriesCompleted,
    ),

    Achievement(
      id: 'first_guess_1',
      title: 'First First Guess',
      description: 'Get one answer correct on Clue 1',
      rarity: AchievementRarity.bronze,
      category: AchievementCategory.firstGuess,
      target: 1,
      achievementPoints: 20,
      progressSelector: (stats) => stats.firstGuesses,
    ),
    Achievement(
      id: 'first_guesses_5',
      title: 'Quick Thinker',
      description: 'Earn 5 First Guesses',
      rarity: AchievementRarity.bronze,
      category: AchievementCategory.firstGuess,
      target: 5,
      achievementPoints: 30,
      progressSelector: (stats) => stats.firstGuesses,
    ),
    Achievement(
      id: 'first_guesses_10',
      title: 'Sharp Mind',
      description: 'Earn 10 First Guesses',
      rarity: AchievementRarity.silver,
      category: AchievementCategory.firstGuess,
      target: 10,
      achievementPoints: 60,
      progressSelector: (stats) => stats.firstGuesses,
    ),
    Achievement(
      id: 'first_guesses_25',
      title: 'Instant Recognition',
      description: 'Earn 25 First Guesses',
      rarity: AchievementRarity.gold,
      category: AchievementCategory.firstGuess,
      target: 25,
      achievementPoints: 125,
      progressSelector: (stats) => stats.firstGuesses,
    ),
    Achievement(
      id: 'first_guesses_100',
      title: 'First Guess Master',
      description: 'Earn 100 First Guesses',
      rarity: AchievementRarity.diamond,
      category: AchievementCategory.firstGuess,
      target: 100,
      achievementPoints: 300,
      progressSelector: (stats) => stats.firstGuesses,
    ),

    Achievement(
      id: 'streak_3',
      title: 'Heating Up',
      description: 'Reach a 3-game winning streak',
      rarity: AchievementRarity.bronze,
      category: AchievementCategory.streak,
      target: 3,
      achievementPoints: 20,
      progressSelector: (stats) => stats.longestStreak,
    ),
    Achievement(
      id: 'streak_5',
      title: 'On Fire',
      description: 'Reach a 5-game winning streak',
      rarity: AchievementRarity.silver,
      category: AchievementCategory.streak,
      target: 5,
      achievementPoints: 50,
      progressSelector: (stats) => stats.longestStreak,
    ),
    Achievement(
      id: 'streak_10',
      title: 'Unstoppable',
      description: 'Reach a 10-game winning streak',
      rarity: AchievementRarity.gold,
      category: AchievementCategory.streak,
      target: 10,
      achievementPoints: 100,
      progressSelector: (stats) => stats.longestStreak,
    ),
    Achievement(
      id: 'streak_25',
      title: 'Untouchable',
      description: 'Reach a 25-game winning streak',
      rarity: AchievementRarity.diamond,
      category: AchievementCategory.streak,
      target: 25,
      achievementPoints: 300,
      progressSelector: (stats) => stats.longestStreak,
    ),

    Achievement(
      id: 'score_1000',
      title: 'High Scorer',
      description: 'Earn 1,000 total points',
      rarity: AchievementRarity.bronze,
      category: AchievementCategory.score,
      target: 1000,
      achievementPoints: 25,
      progressSelector: (stats) => stats.totalScore,
    ),
    Achievement(
      id: 'score_5000',
      title: 'Point Collector',
      description: 'Earn 5,000 total points',
      rarity: AchievementRarity.silver,
      category: AchievementCategory.score,
      target: 5000,
      achievementPoints: 60,
      progressSelector: (stats) => stats.totalScore,
    ),
    Achievement(
      id: 'score_10000',
      title: 'Score Hunter',
      description: 'Earn 10,000 total points',
      rarity: AchievementRarity.gold,
      category: AchievementCategory.score,
      target: 10000,
      achievementPoints: 125,
      progressSelector: (stats) => stats.totalScore,
    ),
    Achievement(
      id: 'score_50000',
      title: 'Elite Scorer',
      description: 'Earn 50,000 total points',
      rarity: AchievementRarity.diamond,
      category: AchievementCategory.score,
      target: 50000,
      achievementPoints: 300,
      progressSelector: (stats) => stats.totalScore,
    ),

    Achievement(
      id: 'xp_1000',
      title: 'XP Starter',
      description: 'Earn 1,000 XP',
      rarity: AchievementRarity.bronze,
      category: AchievementCategory.xp,
      target: 1000,
      achievementPoints: 25,
      progressSelector: (stats) => stats.totalXp,
    ),
    Achievement(
      id: 'xp_5000',
      title: 'XP Hunter',
      description: 'Earn 5,000 XP',
      rarity: AchievementRarity.silver,
      category: AchievementCategory.xp,
      target: 5000,
      achievementPoints: 60,
      progressSelector: (stats) => stats.totalXp,
    ),
    Achievement(
      id: 'xp_10000',
      title: 'XP Expert',
      description: 'Earn 10,000 XP',
      rarity: AchievementRarity.gold,
      category: AchievementCategory.xp,
      target: 10000,
      achievementPoints: 125,
      progressSelector: (stats) => stats.totalXp,
    ),
    Achievement(
      id: 'xp_25000',
      title: 'XP Legend',
      description: 'Earn 25,000 XP',
      rarity: AchievementRarity.diamond,
      category: AchievementCategory.xp,
      target: 25000,
      achievementPoints: 300,
      progressSelector: (stats) => stats.totalXp,
    ),

    Achievement(
      id: 'flag_1',
      title: 'First Flag',
      description: 'Correctly identify your first flag',
      rarity: AchievementRarity.bronze,
      category: AchievementCategory.flags,
      target: 1,
      achievementPoints: 10,
      progressSelector: (stats) => stats.flagsCompleted,
    ),
    Achievement(
      id: 'flags_25',
      title: 'Flag Spotter',
      description: 'Correctly identify 25 flags',
      rarity: AchievementRarity.silver,
      category: AchievementCategory.flags,
      target: 25,
      achievementPoints: 60,
      progressSelector: (stats) => stats.flagsCompleted,
    ),
    Achievement(
      id: 'flags_100',
      title: 'Vexillology Expert',
      description: 'Correctly identify 100 flags',
      rarity: AchievementRarity.diamond,
      category: AchievementCategory.flags,
      target: 100,
      achievementPoints: 250,
      progressSelector: (stats) => stats.flagsCompleted,
    ),

    Achievement(
      id: 'movie_1',
      title: 'Opening Credits',
      description: 'Correctly identify your first movie',
      rarity: AchievementRarity.bronze,
      category: AchievementCategory.movies,
      target: 1,
      achievementPoints: 10,
      progressSelector: (stats) => stats.moviesCompleted,
    ),
    Achievement(
      id: 'movies_50',
      title: 'Film Buff',
      description: 'Correctly identify 50 movies',
      rarity: AchievementRarity.gold,
      category: AchievementCategory.movies,
      target: 50,
      achievementPoints: 125,
      progressSelector: (stats) => stats.moviesCompleted,
    ),

    Achievement(
      id: 'book_1',
      title: 'First Chapter',
      description: 'Correctly identify your first book',
      rarity: AchievementRarity.bronze,
      category: AchievementCategory.books,
      target: 1,
      achievementPoints: 10,
      progressSelector: (stats) => stats.booksCompleted,
    ),
    Achievement(
      id: 'books_50',
      title: 'Bookworm',
      description: 'Correctly identify 50 books',
      rarity: AchievementRarity.gold,
      category: AchievementCategory.books,
      target: 50,
      achievementPoints: 125,
      progressSelector: (stats) => stats.booksCompleted,
    ),

    Achievement(
      id: 'animal_1',
      title: 'Animal Instinct',
      description: 'Correctly identify your first animal',
      rarity: AchievementRarity.bronze,
      category: AchievementCategory.animals,
      target: 1,
      achievementPoints: 10,
      progressSelector: (stats) => stats.animalsCompleted,
    ),
    Achievement(
      id: 'animals_50',
      title: 'Wildlife Expert',
      description: 'Correctly identify 50 animals',
      rarity: AchievementRarity.gold,
      category: AchievementCategory.animals,
      target: 50,
      achievementPoints: 125,
      progressSelector: (stats) => stats.animalsCompleted,
    ),

    Achievement(
      id: 'football_1',
      title: 'Kick Off',
      description: 'Correctly identify your first football team',
      rarity: AchievementRarity.bronze,
      category: AchievementCategory.footballTeams,
      target: 1,
      achievementPoints: 10,
      progressSelector: (stats) => stats.footballTeamsCompleted,
    ),
    Achievement(
      id: 'football_50',
      title: 'Football Expert',
      description: 'Correctly identify 50 football teams',
      rarity: AchievementRarity.gold,
      category: AchievementCategory.footballTeams,
      target: 50,
      achievementPoints: 125,
      progressSelector: (stats) => stats.footballTeamsCompleted,
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
}
