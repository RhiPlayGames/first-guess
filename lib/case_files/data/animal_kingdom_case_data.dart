import '../models/case_mission.dart';

const List<CaseMission> animalKingdomCaseMissions = [
  CaseMission(
    stage: 1,
    difficulty: CaseDifficulty.easy,
    title: 'CASE 1',
    missionText: 'GET 10 ANIMALS QUESTIONS CORRECT',
    category: 'animals',
    correctRequired: 10,
  ),

  CaseMission(
    stage: 2,
    difficulty: CaseDifficulty.easy,
    title: 'CASE 2',
    missionText: 'GET 10 JUNGLE & SAFARI QUESTIONS CORRECT',
    category: 'animals',
    subcategory: 'jungle_safari_animals',
    correctRequired: 10,
  ),

  CaseMission(
    stage: 3,
    difficulty: CaseDifficulty.easy,
    title: 'CASE 3',
    missionText:
        'GET 10 HABITATS & ANIMAL GROUPS QUESTIONS CORRECT',
    category: 'animals',
    subcategory: 'habitats_animal_groups',
    correctRequired: 10,
  ),

  CaseMission(
    stage: 4,
    difficulty: CaseDifficulty.easy,
    title: 'CASE 4',
    missionText:
        'GET 10 INSECTS & SPIDERS QUESTIONS CORRECT, INCLUDING 4 BY CLUE 5',
    category: 'animals',
    subcategory: 'insects_spiders',
    correctRequired: 10,
    clueThreshold: 5,
    clueThresholdRequired: 4,
  ),

  CaseMission(
    stage: 5,
    difficulty: CaseDifficulty.easy,
    title: 'CASE 5',
    missionText:
        'GET 10 MAMMALS ANIMALS QUESTIONS CORRECT, INCLUDING 5 BY CLUE 5',
    category: 'animals',
    subcategory: 'mammals',
    correctRequired: 10,
    clueThreshold: 5,
    clueThresholdRequired: 5,
  ),

  CaseMission(
    stage: 6,
    difficulty: CaseDifficulty.moderate,
    title: 'CASE 6',
    missionText:
        'GET 10 BIRDS QUESTIONS CORRECT, INCLUDING 5 BY CLUE 5',
    category: 'animals',
    subcategory: 'birds',
    correctRequired: 10,
    clueThreshold: 5,
    clueThresholdRequired: 5,
  ),

  CaseMission(
    stage: 7,
    difficulty: CaseDifficulty.moderate,
    title: 'CASE 7',
    missionText:
        'GET 10 REPTILES & AMPHIBIANS QUESTIONS CORRECT, INCLUDING 5 BY CLUE 4',
    category: 'animals',
    subcategory: 'reptiles_amphibians',
    correctRequired: 10,
    clueThreshold: 4,
    clueThresholdRequired: 5,
  ),

  CaseMission(
    stage: 8,
    difficulty: CaseDifficulty.moderate,
    title: 'CASE 8',
    missionText:
        'GET 10 SEA CREATURES QUESTIONS CORRECT, INCLUDING 5 BY CLUE 4',
    category: 'animals',
    subcategory: 'sea_creatures',
    correctRequired: 10,
    clueThreshold: 4,
    clueThresholdRequired: 5,
  ),

  CaseMission(
    stage: 9,
    difficulty: CaseDifficulty.moderate,
    title: 'CASE 9',
    missionText:
        'GET 10 TRACKS & FOOTPRINTS QUESTIONS CORRECT, INCLUDING 5 BY CLUE 4',
    category: 'animals',
    subcategory: 'tracks_footprints',
    correctRequired: 10,
    clueThreshold: 4,
    clueThresholdRequired: 5,
  ),

  CaseMission(
    stage: 10,
    difficulty: CaseDifficulty.moderate,
    title: 'CASE 10',
    missionText:
        'GET 10 QUESTIONS CORRECT FROM DINOSAURS SUBCATEGORY, INCLUDING 5 BY CLUE 4',
    category: 'animals',
    subcategory: 'dinosaurs',
    correctRequired: 10,
    clueThreshold: 4,
    clueThresholdRequired: 5,
  ),

  CaseMission(
    stage: 11,
    difficulty: CaseDifficulty.hard,
    title: 'CASE 11',
    missionText:
        'GET 10 ANIMALS QUESTIONS CORRECT, INCLUDING 6 BY CLUE 4',
    category: 'animals',
    correctRequired: 10,
    clueThreshold: 4,
    clueThresholdRequired: 6,
  ),

  CaseMission(
    stage: 12,
    difficulty: CaseDifficulty.hard,
    title: 'CASE 12',
    missionText:
        'GET 10 ANIMALS QUESTIONS CORRECT, INCLUDING 5 BY CLUE 3 AND 2 FIRST GUESSES',
    category: 'animals',
    correctRequired: 10,
    clueThreshold: 3,
    clueThresholdRequired: 5,
    firstGuessesRequired: 2,
  ),

  CaseMission(
    stage: 13,
    difficulty: CaseDifficulty.hard,
    title: 'CASE 13',
    missionText:
        'GET 10 ANIMALS QUESTIONS CORRECT, INCLUDING 7 BY CLUE 4 AND 3 FIRST GUESSES',
    category: 'animals',
    correctRequired: 10,
    clueThreshold: 4,
    clueThresholdRequired: 7,
    firstGuessesRequired: 3,
  ),

  CaseMission(
    stage: 14,
    difficulty: CaseDifficulty.hard,
    title: 'CASE 14',
    missionText:
        'GET 10 ANIMALS QUESTIONS CORRECT, INCLUDING 6 BY CLUE 3',
    category: 'animals',
    correctRequired: 10,
    clueThreshold: 3,
    clueThresholdRequired: 6,
  ),

  CaseMission(
    stage: 15,
    difficulty: CaseDifficulty.hard,
    title: 'CASE 15',
    missionText:
        'GET 10 ANIMALS QUESTIONS CORRECT, INCLUDING 7 BY CLUE 3 AND 3 FIRST GUESSES',
    category: 'animals',
    correctRequired: 10,
    clueThreshold: 3,
    clueThresholdRequired: 7,
    firstGuessesRequired: 3,
  ),

  CaseMission(
    stage: 16,
    difficulty: CaseDifficulty.expert,
    title: 'CASE 16',
    missionText:
        'GET 10 ANIMALS QUESTIONS CORRECT, INCLUDING 7 BY CLUE 3 AND 4 FIRST GUESSES',
    category: 'animals',
    correctRequired: 10,
    clueThreshold: 3,
    clueThresholdRequired: 7,
    firstGuessesRequired: 4,
  ),

  CaseMission(
    stage: 17,
    difficulty: CaseDifficulty.expert,
    title: 'CASE 17',
    missionText:
        'GET 10 ANIMALS QUESTIONS CORRECT, INCLUDING 8 BY CLUE 3 AND 4 FIRST GUESSES',
    category: 'animals',
    correctRequired: 10,
    clueThreshold: 3,
    clueThresholdRequired: 8,
    firstGuessesRequired: 4,
  ),

  CaseMission(
    stage: 18,
    difficulty: CaseDifficulty.expert,
    title: 'CASE 18',
    missionText:
        'GET 10 ANIMALS QUESTIONS CORRECT, INCLUDING 8 BY CLUE 3 AND 5 FIRST GUESSES',
    category: 'animals',
    correctRequired: 10,
    clueThreshold: 3,
    clueThresholdRequired: 8,
    firstGuessesRequired: 5,
  ),

  CaseMission(
    stage: 19,
    difficulty: CaseDifficulty.expert,
    title: 'CASE 19',
    missionText:
        'GET 10 ANIMALS QUESTIONS CORRECT, INCLUDING 7 BY CLUE 2 AND 5 FIRST GUESSES',
    category: 'animals',
    correctRequired: 10,
    clueThreshold: 2,
    clueThresholdRequired: 7,
    firstGuessesRequired: 5,
  ),

  CaseMission(
    stage: 20,
    difficulty: CaseDifficulty.finalChallenge,
    title: 'FINAL CASE',
    missionText:
        'GET 10 ANIMALS QUESTIONS CORRECT, INCLUDING 8 BY CLUE 2 AND 6 FIRST GUESSES',
    category: 'animals',
    correctRequired: 10,
    clueThreshold: 2,
    clueThresholdRequired: 8,
    firstGuessesRequired: 6,
  ),
];