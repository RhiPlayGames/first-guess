import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../author_data.dart';
import '../flag_data.dart';
import '../game_data.dart';
import '../models/quiz_item.dart';
import '../services/firebase_challenge_service.dart';
import '../services/player_stats_service.dart';
import '../theme/app_colors.dart';
import '../widgets/clue_panel.dart';
import '../widgets/flag_image_panel.dart';
import '../widgets/game_dialogs.dart';
import '../widgets/app_home_button.dart';
import '../widgets/guess_panel.dart';
import '../widgets/lives_display.dart';
import '../widgets/reveal_image_panel.dart';
import '../widgets/silhouette_panel.dart';
import '../widgets/stats_panel.dart';

part 'game_screen_logic.dart';
part 'game_screen_view.dart';

enum QuizGameType {
  countries,
  flags,
  authors,
  capitalCities,
  countrySilhouettes,
  currencies,
  majorCities,
  birds,
  dinosaurs,
  breakfastFoods,
  dessertsCakesSweets,
  firebaseDynamic,
}

class GameScreen extends StatefulWidget {
  final QuizGameType gameType;
  final List<QuizItem> items;
  final QuizItem? initialItem;
  final bool launchedFromSurpriseMe;
  final bool showSurpriseToast;

  const GameScreen({
    super.key,
    this.initialItem,
    this.launchedFromSurpriseMe = false,
    this.showSurpriseToast = false,
  })  : gameType = QuizGameType.countries,
        items = countries;

  const GameScreen.countries({
    super.key,
    this.initialItem,
    this.launchedFromSurpriseMe = false,
    this.showSurpriseToast = false,
  })  : gameType = QuizGameType.countries,
        items = countries;

  const GameScreen.flags({
    super.key,
    this.initialItem,
    this.launchedFromSurpriseMe = false,
    this.showSurpriseToast = false,
  })  : gameType = QuizGameType.flags,
        items = flags;

  const GameScreen.authors({
    super.key,
    this.initialItem,
    this.launchedFromSurpriseMe = false,
    this.showSurpriseToast = false,
  })  : gameType = QuizGameType.authors,
        items = authors;

  const GameScreen.capitalCities({
    super.key,
    required this.items,
    this.initialItem,
    this.launchedFromSurpriseMe = false,
    this.showSurpriseToast = false,
  }) : gameType = QuizGameType.capitalCities;

  const GameScreen.countrySilhouettes({
    super.key,
    required this.items,
    this.initialItem,
    this.launchedFromSurpriseMe = false,
    this.showSurpriseToast = false,
  }) : gameType = QuizGameType.countrySilhouettes;

  const GameScreen.currencies({
    super.key,
    required this.items,
    this.initialItem,
    this.launchedFromSurpriseMe = false,
    this.showSurpriseToast = false,
  }) : gameType = QuizGameType.currencies;

  const GameScreen.majorCities({
    super.key,
    required this.items,
    this.initialItem,
    this.launchedFromSurpriseMe = false,
    this.showSurpriseToast = false,
  }) : gameType = QuizGameType.majorCities;

  const GameScreen.birds({
    super.key,
    required this.items,
    this.initialItem,
    this.launchedFromSurpriseMe = false,
    this.showSurpriseToast = false,
  }) : gameType = QuizGameType.birds;

  const GameScreen.dinosaurs({
    super.key,
    required this.items,
    this.initialItem,
    this.launchedFromSurpriseMe = false,
    this.showSurpriseToast = false,
  }) : gameType = QuizGameType.dinosaurs;

  const GameScreen.breakfastFoods({
    super.key,
    required this.items,
    this.initialItem,
    this.launchedFromSurpriseMe = false,
    this.showSurpriseToast = false,
  }) : gameType = QuizGameType.breakfastFoods;

  const GameScreen.dessertsCakesSweets({
  super.key,
  required this.items,
  this.initialItem,
  this.launchedFromSurpriseMe = false,
  this.showSurpriseToast = false,
}) : gameType = QuizGameType.dessertsCakesSweets;


  const GameScreen.firebaseDynamic({
    super.key,
    required this.items,
    this.initialItem,
    this.launchedFromSurpriseMe = false,
    this.showSurpriseToast = false,
  }) : gameType = QuizGameType.firebaseDynamic;

  bool get isFlagGame =>
      gameType == QuizGameType.flags ||
      (gameType == QuizGameType.firebaseDynamic &&
          _representativeQuestionId.startsWith('countries_flags_'));

  bool get isAuthorGame => gameType == QuizGameType.authors;

  bool get isCapitalCitiesGame => gameType == QuizGameType.capitalCities;

  bool get isCountrySilhouettesGame =>
      gameType == QuizGameType.countrySilhouettes ||
      (gameType == QuizGameType.firebaseDynamic &&
          _representativeQuestionId
              .startsWith('countries_country_silhouettes_'));

  bool get isCurrenciesGame =>
      gameType == QuizGameType.currencies;

  bool get isMajorCitiesGame => gameType == QuizGameType.majorCities;

  String get _representativeQuestionId =>
      initialItem?.id ?? items.first.id ?? '';

  String get gameTitle {
    switch (gameType) {
      case QuizGameType.countries:
        return 'GUESS THE COUNTRY';
      case QuizGameType.flags:
        return 'GUESS THE FLAG';
      case QuizGameType.authors:
        return 'GUESS THE AUTHOR';
      case QuizGameType.capitalCities:
        return 'GUESS THE CAPITAL';
      case QuizGameType.countrySilhouettes:
        return 'GUESS THE COUNTRY';
      case QuizGameType.currencies:
        return 'GUESS THE CURRENCY';
      case QuizGameType.majorCities:
        return 'GUESS THE CITY';
      case QuizGameType.birds:
        return 'GUESS THE BIRD';
      case QuizGameType.dinosaurs:
        return 'GUESS THE DINOSAUR';
      case QuizGameType.breakfastFoods:
        return 'GUESS THE BREAKFAST FOOD';
      case QuizGameType.dessertsCakesSweets:
        return 'GUESS THE DESSERT';
      case QuizGameType.firebaseDynamic:
        return 'FIRST GUESS';
    }
  }

  String get categoryName {
    switch (gameType) {
      case QuizGameType.countries:
        return 'COUNTRIES';
      case QuizGameType.flags:
        return 'FLAGS';
      case QuizGameType.authors:
        return 'AUTHORS';
      case QuizGameType.capitalCities:
        return 'CAPITAL CITIES';
      case QuizGameType.countrySilhouettes:
        return 'COUNTRY SILHOUETTES';
      case QuizGameType.currencies:
        return 'CURRENCIES';
      case QuizGameType.majorCities:
        return 'MAJOR CITIES';
      case QuizGameType.birds:
        return 'BIRDS';
      case QuizGameType.dinosaurs:
        return 'DINOSAURS';
      case QuizGameType.breakfastFoods:
        return 'BREAKFAST FOODS';
      case QuizGameType.dessertsCakesSweets:
        return 'DESSERTS, CAKES & SWEETS';
      case QuizGameType.firebaseDynamic:
        return 'SURPRISE ME';
    }
  }

  IconData get categoryIcon {
    switch (gameType) {
      case QuizGameType.countries:
        return Icons.public;
      case QuizGameType.flags:
        return Icons.flag;
      case QuizGameType.authors:
        return Icons.edit_note;
      case QuizGameType.capitalCities:
        return Icons.location_city;
      case QuizGameType.countrySilhouettes:
        return Icons.public;
      case QuizGameType.currencies:
        return Icons.currency_exchange;
      case QuizGameType.majorCities:
        return Icons.location_city;
      case QuizGameType.birds:
        return Icons.flutter_dash_rounded;
      case QuizGameType.dinosaurs:
        return Icons.landscape_rounded;
      case QuizGameType.breakfastFoods:
        return Icons.breakfast_dining_rounded;
      case QuizGameType.dessertsCakesSweets:
        return Icons.cake_rounded;
      case QuizGameType.firebaseDynamic:
        return Icons.shuffle_rounded;
    }
  }

  GameCategory get statsCategory {
    switch (gameType) {
      case QuizGameType.countries:
        return GameCategory.countries;
      case QuizGameType.flags:
        return GameCategory.flags;
      case QuizGameType.authors:
        return GameCategory.authors;
      case QuizGameType.capitalCities:
        return GameCategory.capitalCities;
      case QuizGameType.countrySilhouettes:
        return GameCategory.countries;
      case QuizGameType.currencies:
        return GameCategory.countries;
      case QuizGameType.majorCities:
        return GameCategory.capitalCities;
      case QuizGameType.birds:
        return GameCategory.animals;
      case QuizGameType.dinosaurs:
        return GameCategory.animals;
      case QuizGameType.breakfastFoods:
        return GameCategory.foodDrink;
      case QuizGameType.dessertsCakesSweets:
        return GameCategory.foodDrink;
      case QuizGameType.firebaseDynamic:
        final String id = _representativeQuestionId;
        if (id.startsWith('animals_')) {
          return GameCategory.animals;
        }
        if (id.startsWith('food_drink_')) {
          return GameCategory.foodDrink;
        }
        if (id.startsWith('books_authors_')) {
          return GameCategory.authors;
        }
        if (id.startsWith('countries_flags_')) {
          return GameCategory.flags;
        }
        if (id.startsWith('countries_capitals_')) {
          return GameCategory.capitalCities;
        }
        if (id.startsWith('countries_')) {
          return GameCategory.countries;
        }
        return GameCategory.other;
    }
  }

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  static const int clueDurationMilliseconds = 14000;
  static const int timerUpdateMilliseconds = 100;
  static const int maximumLives = 3;

  static const Duration surpriseToastDisplayDuration =
      Duration(seconds: 3);

  static const Duration surpriseToastFadeDuration =
      Duration(milliseconds: 250);

  final TextEditingController guessController =
      TextEditingController();

  final FocusNode guessFocusNode = FocusNode();

  final Random random = Random();

  Timer? clueTimer;
  Timer? messageTimer;
  Timer? timeUpOverlayTimer;
  Timer? surpriseToastTimer;

  late QuizItem currentItem;
  QuizItem? preloadedNextItem;
  late DateTime roundStartedAt;

  PlayerStats playerStats = const PlayerStats();

  Set<String> playedQuestionIds = <String>{};
  bool questionHistoryLoaded = false;
  bool currentQuestionIsReplay = false;
  bool practiceModeNoticeShown = false;

  int currentClueIndex = 0;
  int lives = maximumLives;
  int guessesThisRound = 0;
  int closeGuessesThisClue = 0;
  int millisecondsRemaining = clueDurationMilliseconds;

  bool roundFinished = false;
  bool showTimeUpOverlay = false;
  bool statsLoaded = false;
  bool showSurpriseToast = false;
  bool imageReady = false;

  String? gameMessage;
  GameMessageType gameMessageType = GameMessageType.info;

  int get pointsAvailable => 100 - (currentClueIndex * 10);

  bool get isLastClue =>
      currentClueIndex >= currentItem.clues.length - 1;

  double get timerProgress {
    return (millisecondsRemaining / clueDurationMilliseconds)
        .clamp(0.0, 1.0);
  }

  int get roundPlayTimeSeconds {
    return DateTime.now()
        .difference(roundStartedAt)
        .inSeconds;
  }

  @override
  void initState() {
    super.initState();

    if (widget.items.isEmpty) {
      throw StateError(
        'This game category does not contain any quiz items.',
      );
    }

    currentItem = widget.initialItem ?? widget.items.first;
    roundStartedAt = DateTime.now();

    showSurpriseToast =
        widget.launchedFromSurpriseMe &&
        widget.showSurpriseToast;

    loadPlayerStats();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await initialiseQuestionHistoryAndRound();
    });
  }

  ImageProvider<Object> imageProviderForPath(String imagePath) {
    final Uri? uri = Uri.tryParse(imagePath);
    final bool isNetworkImage =
        uri != null &&
        (uri.scheme == 'http' || uri.scheme == 'https');

    if (isNetworkImage) {
      return NetworkImage(imagePath);
    }

    return AssetImage(imagePath);
  }

  Future<void> prepareCurrentImage() async {
    if (mounted) {
      setState(() {
        imageReady = false;
      });
    }

    try {
      await precacheImage(
        imageProviderForPath(currentItem.imagePath),
        context,
      );
    } catch (_) {
      // The image widget still handles genuine image failures.
    }

    if (!mounted) {
      return;
    }

    setState(() {
      imageReady = true;
    });
  }

  void _showSurpriseToastThenStartTimer() {
    surpriseToastTimer?.cancel();

    surpriseToastTimer = Timer(
      surpriseToastDisplayDuration,
      () {
        if (!mounted) {
          return;
        }

        setState(() {
          showSurpriseToast = false;
        });

        surpriseToastTimer = Timer(
          surpriseToastFadeDuration,
          () {
            if (!mounted) {
              return;
            }

            roundStartedAt = DateTime.now();
            startClueTimer();
          },
        );
      },
    );
  }

  @override
  void dispose() {
    clueTimer?.cancel();
    messageTimer?.cancel();
    timeUpOverlayTimer?.cancel();
    surpriseToastTimer?.cancel();

    guessController.dispose();
    guessFocusNode.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return buildGameScreen();
  }
}