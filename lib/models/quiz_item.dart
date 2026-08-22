enum GuessMatch {
  correct,
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
              _withoutSpaces(normalisedAnswer)) {
        return GuessMatch.correct;
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
        .replaceAll(
          RegExp(r'[^a-z0-9\s]'),
          '',
        )
        .replaceAll(
          RegExp(r'\s+'),
          ' ',
        )
        .trim();

    if (normalised.startsWith('the ')) {
      normalised = normalised.substring(4);
    }

    return normalised;
  }

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