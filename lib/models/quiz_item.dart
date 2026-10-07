enum GuessMatch {
  correct,
  specific,
  close,
  incorrect,
}

enum AnswerPolicy {
  standard,
  commonNameAllowed,
  specific,
  aliasesOnly,
}

class QuizItem {
  final String? id;
  final String answer;
  final String imagePath;
  final List<String> clues;
  final List<String> acceptedAnswers;
  final AnswerPolicy answerPolicy;

  const QuizItem({
    this.id,
    required this.answer,
    required this.imagePath,
    required this.clues,
    this.acceptedAnswers = const [],
    this.answerPolicy = AnswerPolicy.standard,
  });

  GuessMatch checkGuess(String guess) {
    final String normalisedGuess = _normalise(guess);

    if (normalisedGuess.isEmpty) {
      return GuessMatch.incorrect;
    }

    final List<String> possibleAnswers =
        _buildPossibleAnswers();

    for (final String possibleAnswer in possibleAnswers) {
      final String normalisedAnswer =
          _normalise(possibleAnswer);

      if (normalisedGuess == normalisedAnswer ||
          _withoutSpaces(normalisedGuess) ==
              _withoutSpaces(normalisedAnswer) ||
          _isSingularPluralMatch(
            normalisedGuess,
            normalisedAnswer,
          )) {
        return GuessMatch.correct;
      }
    }

    for (final String possibleAnswer in possibleAnswers) {
      final String normalisedAnswer =
          _normalise(possibleAnswer);

      if (_isTooBroadMatch(
        normalisedGuess,
        normalisedAnswer,
      )) {
        return GuessMatch.specific;
      }
    }

    for (final String possibleAnswer in possibleAnswers) {
      final String normalisedAnswer =
          _normalise(possibleAnswer);

      if (_isCloseSpelling(
        normalisedGuess,
        normalisedAnswer,
      )) {
        return GuessMatch.close;
      }
    }

    return GuessMatch.incorrect;
  }

  List<String> _buildPossibleAnswers() {
    final Set<String> answers = <String>{
      answer,
      ...acceptedAnswers,
    };

    if (answerPolicy == AnswerPolicy.commonNameAllowed) {
      final String? commonName = _commonNameFor(answer);

      if (commonName != null && commonName.isNotEmpty) {
        answers.add(commonName);
      }
    }

    return answers.toList(growable: false);
  }

  static String? _commonNameFor(String value) {
    final String normalised = _normalise(value);

    if (normalised.isEmpty) {
      return null;
    }

    final List<String> words = normalised.split(' ');

    if (words.length < 2) {
      return null;
    }

    final String candidate = words.last;

    if (candidate.length < 3) {
      return null;
    }

    return candidate;
  }

  bool matchesGuess(String guess) {
    return checkGuess(guess) == GuessMatch.correct;
  }

  static String _normalise(String value) {
    String normalised = _foldAccents(value)
        .trim()
        .toLowerCase()
        .replaceAll('&', ' and ')
        // Apostrophes are optional for answer matching. Remove them rather
        // than turning them into spaces so "king's" and "kings" match.
        .replaceAll(RegExp(r"['’‘`´]"), '')
        // Other punctuation, including hyphens and dashes, acts as a word
        // separator. This makes "baba-abdalla" and "baba abdalla" equal.
        .replaceAll(
          RegExp(r'[^a-z0-9\s]'),
          ' ',
        )
        .replaceAll(
          RegExp(r'\s+'),
          ' ',
        )
        .trim();

    if (normalised.isEmpty) {
      return normalised;
    }

    List<String> words = normalised.split(' ');

    // Treat Roman numerals, Arabic numerals, Arabic ordinals and written
    // cardinal/ordinal numbers as equivalent. Examples:
    // XVI = 16 = 16th = sixteen = sixteenth
    // Louis XVI = Louis 16 = Louis 16th = Louis the Sixteenth
    words = _normaliseNumericForms(words);
    words = _normaliseNumberWords(words);

    // Treat common British and American spellings as equivalent.
    // First Guess keeps British English for display text, but players
    // should not be penalised for entering a standard US spelling.
    words = words
        .map((String word) => _ukUsSpellingEquivalents[word] ?? word)
        .toList(growable: false);

    // Articles are optional anywhere in an answer. This covers both a
    // leading "The" and natural title variations such as
    // "The Elves and the Shoemaker" / "Elves and Shoemaker".
    words = words
        .where(
          (String word) =>
              word != 'the' &&
              word != 'a' &&
              word != 'an',
        )
        .toList(growable: false);

    return words.join(' ').trim();
  }

  static List<String> _normaliseNumericForms(
    List<String> words,
  ) {
    final List<String> result = <String>[];

    for (int index = 0; index < words.length; index++) {
      final String word = words[index];

      final Match? ordinalMatch =
          RegExp(r'^(\d+)(st|nd|rd|th)$').firstMatch(word);

      if (ordinalMatch != null) {
        result.add(ordinalMatch.group(1)!);
        continue;
      }

      final int? romanValue = _romanNumeralValue(word);

      // A single leading "I" is commonly a real word/title element
      // (for example "I Robot"), so only treat single-letter Roman I as
      // numeric when it appears after another word, as in "Henry I".
      if (romanValue != null &&
          (word.length > 1 || index > 0)) {
        result.add(romanValue.toString());
        continue;
      }

      result.add(word);
    }

    return result;
  }

  static int? _romanNumeralValue(String value) {
    if (value.isEmpty || !RegExp(r'^[ivxlcdm]+$').hasMatch(value)) {
      return null;
    }

    const Map<String, int> romanValues = <String, int>{
      'i': 1,
      'v': 5,
      'x': 10,
      'l': 50,
      'c': 100,
      'd': 500,
      'm': 1000,
    };

    int total = 0;
    int previous = 0;

    for (int index = value.length - 1; index >= 0; index--) {
      final int current = romanValues[value[index]]!;

      if (current < previous) {
        total -= current;
      } else {
        total += current;
        previous = current;
      }
    }

    if (total <= 0 || total > 3999) {
      return null;
    }

    // Only accept canonical Roman numerals so ordinary strings made only
    // from Roman-numeral letters are not accidentally treated as numbers.
    if (_toRomanNumeral(total) != value) {
      return null;
    }

    return total;
  }

  static String _toRomanNumeral(int value) {
    const List<MapEntry<int, String>> numerals =
        <MapEntry<int, String>>[
      MapEntry<int, String>(1000, 'm'),
      MapEntry<int, String>(900, 'cm'),
      MapEntry<int, String>(500, 'd'),
      MapEntry<int, String>(400, 'cd'),
      MapEntry<int, String>(100, 'c'),
      MapEntry<int, String>(90, 'xc'),
      MapEntry<int, String>(50, 'l'),
      MapEntry<int, String>(40, 'xl'),
      MapEntry<int, String>(10, 'x'),
      MapEntry<int, String>(9, 'ix'),
      MapEntry<int, String>(5, 'v'),
      MapEntry<int, String>(4, 'iv'),
      MapEntry<int, String>(1, 'i'),
    ];

    int remaining = value;
    final StringBuffer buffer = StringBuffer();

    for (final MapEntry<int, String> numeral in numerals) {
      while (remaining >= numeral.key) {
        buffer.write(numeral.value);
        remaining -= numeral.key;
      }
    }

    return buffer.toString();
  }

  static List<String> _normaliseNumberWords(
    List<String> words,
  ) {
    final List<String> result = <String>[];
    int index = 0;

    while (index < words.length) {
      final _ParsedNumberWords? parsed =
          _parseNumberWordsAt(words, index);

      if (parsed == null) {
        result.add(words[index]);
        index++;
        continue;
      }

      result.add(parsed.value.toString());
      index = parsed.nextIndex;
    }

    return result;
  }

  static _ParsedNumberWords? _parseNumberWordsAt(
    List<String> words,
    int startIndex,
  ) {
    if (startIndex >= words.length ||
        (!_isNumberWord(words[startIndex]) &&
            !_isOrdinalNumberWord(words[startIndex]))) {
      return null;
    }

    int index = startIndex;
    int total = 0;
    int current = 0;
    bool consumedAny = false;
    bool usedScale = false;

    while (index < words.length) {
      final String word = words[index];

      final int? ordinalValue = _ordinalNumberWordValues[word];
      if (ordinalValue != null) {
        if (word == 'hundredth' && consumedAny && current > 0) {
          current *= 100;
        } else if (word == 'thousandth' &&
            consumedAny &&
            current > 0) {
          total += current * 1000;
          current = 0;
        } else {
          current += ordinalValue;
        }

        consumedAny = true;
        index++;
        break;
      }

      if (word == 'and') {
        // "And" is part of a written number only after a scale word,
        // e.g. "one hundred and one". It remains untouched in normal
        // phrases such as "seven and nine".
        if (!usedScale ||
            index + 1 >= words.length ||
            (!_isNumberWord(words[index + 1]) &&
                !_isOrdinalNumberWord(words[index + 1]))) {
          break;
        }

        index++;
        continue;
      }

      final int? smallValue = _smallNumberWordValues[word];
      if (smallValue != null) {
        current += smallValue;
        consumedAny = true;
        index++;
        continue;
      }

      final int? tensValue = _tensNumberWordValues[word];
      if (tensValue != null) {
        current += tensValue;
        consumedAny = true;
        index++;
        continue;
      }

      if (word == 'hundred') {
        if (!consumedAny || current == 0) {
          break;
        }

        current *= 100;
        usedScale = true;
        index++;
        continue;
      }

      if (word == 'thousand') {
        if (!consumedAny || current == 0) {
          break;
        }

        total += current * 1000;
        current = 0;
        consumedAny = false;
        usedScale = true;
        index++;
        continue;
      }

      break;
    }

    if (index == startIndex) {
      return null;
    }

    return _ParsedNumberWords(
      value: total + current,
      nextIndex: index,
    );
  }

  static bool _isNumberWord(String word) {
    return _smallNumberWordValues.containsKey(word) ||
        _tensNumberWordValues.containsKey(word) ||
        word == 'hundred' ||
        word == 'thousand';
  }

  static bool _isOrdinalNumberWord(String word) {
    return _ordinalNumberWordValues.containsKey(word);
  }

  static const Map<String, int> _ordinalNumberWordValues =
      <String, int>{
    'first': 1,
    'second': 2,
    'third': 3,
    'fourth': 4,
    'fifth': 5,
    'sixth': 6,
    'seventh': 7,
    'eighth': 8,
    'ninth': 9,
    'tenth': 10,
    'eleventh': 11,
    'twelfth': 12,
    'thirteenth': 13,
    'fourteenth': 14,
    'fifteenth': 15,
    'sixteenth': 16,
    'seventeenth': 17,
    'eighteenth': 18,
    'nineteenth': 19,
    'twentieth': 20,
    'thirtieth': 30,
    'fortieth': 40,
    'fiftieth': 50,
    'sixtieth': 60,
    'seventieth': 70,
    'eightieth': 80,
    'ninetieth': 90,
    'hundredth': 100,
    'thousandth': 1000,
  };

  static const Map<String, int> _smallNumberWordValues =
      <String, int>{
    'zero': 0,
    'one': 1,
    'two': 2,
    'three': 3,
    'four': 4,
    'five': 5,
    'six': 6,
    'seven': 7,
    'eight': 8,
    'nine': 9,
    'ten': 10,
    'eleven': 11,
    'twelve': 12,
    'thirteen': 13,
    'fourteen': 14,
    'fifteen': 15,
    'sixteen': 16,
    'seventeen': 17,
    'eighteen': 18,
    'nineteen': 19,
  };

  static const Map<String, int> _tensNumberWordValues =
      <String, int>{
    'twenty': 20,
    'thirty': 30,
    'forty': 40,
    'fifty': 50,
    'sixty': 60,
    'seventy': 70,
    'eighty': 80,
    'ninety': 90,
  };

  static const Map<String, String> _ukUsSpellingEquivalents =
      <String, String>{
    'theatre': 'theatre',
    'theater': 'theatre',
    'centre': 'centre',
    'center': 'centre',
    'centres': 'centres',
    'centers': 'centres',
    'metre': 'metre',
    'meter': 'metre',
    'litre': 'litre',
    'liter': 'litre',
    'fibre': 'fibre',
    'fiber': 'fibre',
    'colour': 'colour',
    'color': 'colour',
    'favourite': 'favourite',
    'favorite': 'favourite',
    'favour': 'favour',
    'favor': 'favour',
    'honour': 'honour',
    'honor': 'honour',
    'neighbour': 'neighbour',
    'neighbor': 'neighbour',
    'humour': 'humour',
    'humor': 'humour',
    'labour': 'labour',
    'labor': 'labour',
    'organise': 'organise',
    'organize': 'organise',
    'organised': 'organised',
    'organized': 'organised',
    'organising': 'organising',
    'organizing': 'organising',
    'recognise': 'recognise',
    'recognize': 'recognise',
    'recognised': 'recognised',
    'recognized': 'recognised',
    'recognising': 'recognising',
    'recognizing': 'recognising',
    'travelling': 'travelling',
    'traveling': 'travelling',
    'travelled': 'travelled',
    'traveled': 'travelled',
    'cancelling': 'cancelling',
    'canceling': 'cancelling',
    'cancelled': 'cancelled',
    'canceled': 'cancelled',
    'grey': 'grey',
    'gray': 'grey',
    'defence': 'defence',
    'defense': 'defence',
    'offence': 'offence',
    'offense': 'offence',
    'licence': 'licence',
    'license': 'licence',
    'catalogue': 'catalogue',
    'catalog': 'catalogue',
    'dialogue': 'dialogue',
    'dialog': 'dialogue',
    'cheque': 'cheque',
    'check': 'cheque',
    'jewellery': 'jewellery',
    'jewelry': 'jewellery',
    'aluminium': 'aluminium',
    'aluminum': 'aluminium',
    'mould': 'mould',
    'mold': 'mould',
    'plough': 'plough',
    'plow': 'plough',
    'tyre': 'tyre',
    'tire': 'tyre',
    'programme': 'programme',
    'program': 'programme',
  };

  static String _foldAccents(String value) {
    const Map<String, String> replacements = <String, String>{
      'á': 'a', 'à': 'a', 'â': 'a', 'ä': 'a', 'ã': 'a', 'å': 'a',
      'Á': 'A', 'À': 'A', 'Â': 'A', 'Ä': 'A', 'Ã': 'A', 'Å': 'A',
      'æ': 'ae', 'Æ': 'AE',
      'ç': 'c', 'Ç': 'C',
      'é': 'e', 'è': 'e', 'ê': 'e', 'ë': 'e',
      'É': 'E', 'È': 'E', 'Ê': 'E', 'Ë': 'E',
      'í': 'i', 'ì': 'i', 'î': 'i', 'ï': 'i',
      'Í': 'I', 'Ì': 'I', 'Î': 'I', 'Ï': 'I',
      'ñ': 'n', 'Ñ': 'N',
      'ó': 'o', 'ò': 'o', 'ô': 'o', 'ö': 'o', 'õ': 'o', 'ø': 'o',
      'Ó': 'O', 'Ò': 'O', 'Ô': 'O', 'Ö': 'O', 'Õ': 'O', 'Ø': 'O',
      'œ': 'oe', 'Œ': 'OE',
      'š': 's', 'Š': 'S',
      'ú': 'u', 'ù': 'u', 'û': 'u', 'ü': 'u',
      'Ú': 'U', 'Ù': 'U', 'Û': 'U', 'Ü': 'U',
      'ý': 'y', 'ÿ': 'y', 'Ý': 'Y',
      'ž': 'z', 'Ž': 'Z',
    };

    final StringBuffer buffer = StringBuffer();

    for (final String character in value.split('')) {
      buffer.write(replacements[character] ?? character);
    }

    return buffer.toString();
  }

  static String _withoutSpaces(String value) {
    return value.replaceAll(' ', '');
  }

  static bool _isSingularPluralMatch(
    String first,
    String second,
  ) {
    if (first.isEmpty || second.isEmpty || first == second) {
      return false;
    }

    if (_pluralForms(first).contains(second) ||
        _pluralForms(second).contains(first)) {
      return true;
    }

    final String compactFirst = _withoutSpaces(first);
    final String compactSecond = _withoutSpaces(second);

    return _pluralForms(compactFirst).contains(compactSecond) ||
        _pluralForms(compactSecond).contains(compactFirst);
  }

  static Set<String> _pluralForms(String value) {
    final String normalised = value.trim();

    if (normalised.isEmpty) {
      return <String>{};
    }

    final List<String> words = normalised.split(' ');
    final String finalWord = words.removeLast();

    final Set<String> pluralWords =
        _pluralFormsForWord(finalWord);

    if (words.isEmpty) {
      return pluralWords;
    }

    final String prefix = '${words.join(' ')} ';

    return pluralWords
        .map((String pluralWord) => '$prefix$pluralWord')
        .toSet();
  }

  static Set<String> _pluralFormsForWord(String word) {
    const Map<String, List<String>> irregular =
        <String, List<String>>{
      'person': <String>['people'],
      'man': <String>['men'],
      'woman': <String>['women'],
      'child': <String>['children'],
      'mouse': <String>['mice'],
      'goose': <String>['geese'],
      'tooth': <String>['teeth'],
      'foot': <String>['feet'],
      'ox': <String>['oxen'],
      'analysis': <String>['analyses'],
      'diagnosis': <String>['diagnoses'],
      'thesis': <String>['theses'],
      'crisis': <String>['crises'],
      'phenomenon': <String>['phenomena'],
      'criterion': <String>['criteria'],
      'index': <String>['indexes', 'indices'],
      'appendix': <String>['appendixes', 'appendices'],
      'matrix': <String>['matrices', 'matrixes'],
      'vertex': <String>['vertices'],
      'cactus': <String>['cactuses', 'cacti'],
      'fungus': <String>['funguses', 'fungi'],
      'nucleus': <String>['nucleuses', 'nuclei'],
      'syllabus': <String>['syllabuses', 'syllabi'],
      'quiz': <String>['quizzes'],
      'knife': <String>['knives'],
      'life': <String>['lives'],
      'wife': <String>['wives'],
      'leaf': <String>['leaves'],
      'loaf': <String>['loaves'],
      'wolf': <String>['wolves'],
      'shelf': <String>['shelves'],
      'calf': <String>['calves'],
      'half': <String>['halves'],
      'self': <String>['selves'],
      'thief': <String>['thieves'],
      'potato': <String>['potatoes'],
      'tomato': <String>['tomatoes'],
      'hero': <String>['heroes'],
      'echo': <String>['echoes'],
      'fish': <String>['fish', 'fishes'],
      'sheep': <String>['sheep'],
      'deer': <String>['deer'],
      'species': <String>['species'],
      'series': <String>['series'],
      'aircraft': <String>['aircraft'],
      'salmon': <String>['salmon', 'salmons'],
      'trout': <String>['trout', 'trouts'],
    };

    final List<String>? irregularForms = irregular[word];

    if (irregularForms != null) {
      return irregularForms.toSet();
    }

    if (word.length > 1 &&
        word.endsWith('y') &&
        !_isVowel(word[word.length - 2])) {
      return <String>{
        '${word.substring(0, word.length - 1)}ies',
      };
    }

    if (word.endsWith('s') ||
        word.endsWith('x') ||
        word.endsWith('z') ||
        word.endsWith('ch') ||
        word.endsWith('sh')) {
      return <String>{'${word}es'};
    }

    return <String>{'${word}s'};
  }

  static bool _isVowel(String character) {
    return 'aeiou'.contains(character);
  }

  static bool _isTooBroadMatch(
    String guess,
    String answer,
  ) {
    if (guess.isEmpty ||
        answer.isEmpty ||
        guess == answer) {
      return false;
    }

    final List<String> guessWords = guess.split(' ');
    final List<String> answerWords = answer.split(' ');

    if (guessWords.length >= answerWords.length) {
      return false;
    }

    // A broad/incomplete answer must consist only of complete words from the
    // required answer. Examples: "bear" -> "black bear",
    // "penguin" -> "emperor penguin", "great shark" ->
    // "great white shark". Exact accepted aliases are handled earlier.
    final List<String> remainingAnswerWords =
        List<String>.from(answerWords);

    for (final String guessWord in guessWords) {
      final int index =
          remainingAnswerWords.indexOf(guessWord);

      if (index == -1) {
        return false;
      }

      remainingAnswerWords.removeAt(index);
    }

    return true;
  }

  static bool _isCloseSpelling(
    String guess,
    String answer,
  ) {
    if (guess.length < 4 || answer.length < 4) {
      return false;
    }

    final int distance = _levenshteinDistance(
      guess,
      answer,
    );

    final int longestLength =
        guess.length > answer.length
            ? guess.length
            : answer.length;

    int maximumDistance;

    if (longestLength <= 5) {
      maximumDistance = 1;
    } else if (longestLength <= 10) {
      maximumDistance = 2;
    } else {
      maximumDistance = 3;
    }

    return distance <= maximumDistance;
  }

  static int _levenshteinDistance(
    String first,
    String second,
  ) {
    if (first == second) {
      return 0;
    }

    if (first.isEmpty) {
      return second.length;
    }

    if (second.isEmpty) {
      return first.length;
    }

    List<int> previousRow = List<int>.generate(
      second.length + 1,
      (index) => index,
    );

    for (
      int firstIndex = 0;
      firstIndex < first.length;
      firstIndex++
    ) {
      final List<int> currentRow = [
        firstIndex + 1,
      ];

      for (
        int secondIndex = 0;
        secondIndex < second.length;
        secondIndex++
      ) {
        final int insertionCost =
            currentRow[secondIndex] + 1;

        final int deletionCost =
            previousRow[secondIndex + 1] + 1;

        final int substitutionCost =
            previousRow[secondIndex] +
            (
              first[firstIndex] ==
                      second[secondIndex]
                  ? 0
                  : 1
            );

        currentRow.add(
          _minimumOfThree(
            insertionCost,
            deletionCost,
            substitutionCost,
          ),
        );
      }

      previousRow = currentRow;
    }

    return previousRow.last;
  }

  static int _minimumOfThree(
    int first,
    int second,
    int third,
  ) {
    int minimum = first;

    if (second < minimum) {
      minimum = second;
    }

    if (third < minimum) {
      minimum = third;
    }

    return minimum;
  }
}

class _ParsedNumberWords {
  final int value;
  final int nextIndex;

  const _ParsedNumberWords({
    required this.value,
    required this.nextIndex,
  });
}

