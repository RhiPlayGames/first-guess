import 'package:flutter_test/flutter_test.dart';
import 'package:first_guess/models/quiz_item.dart';

void main() {
  group('accepted formatting equivalents', () {
    final pairs = <(String, String)>[
      ('Wright Brothers', 'the wright brothers'),
      ("THIRTY YEARS' WAR", 'thirty years war'),
      ('Ben E. King', 'ben e king'),
      ("Sinéad O'Connor", 'sinead oconnor'),
      ('M.C. Hammer', 'MC Hammer'),
      ('LeAnn Rimes', 'leann rimes'),
      ('A-ha', 'aha'),
      ('A-ha', 'a ha'),
      ('D’Amelio', 'damelio'),
      ('TheOdd1sOut', 'The Odd 1s Out'),
      ('Henry VIII', 'henry 8'),
      ('6', 'six'),
      ('Tower of London', 'Tower London'),
      ('Simon & Garfunkel', 'simon and garfunkel'),
      ('Shakespeare', 'Shakespear'),
      ('Spider-Man', 'spiderman'),
    ];
    for (final (answer, guess) in pairs) {
      test('$guess should match $answer', () {
        expect(QuizItem.acceptsAny(guess, [answer]), isTrue);
      });
    }
  });

  group('important non-equivalents', () {
    final pairs = <(String, String)>[
      ('Henry VIII', 'Henry VII'),
      ('World War I', 'World War II'),
      ('Wright Brothers', 'Wright'),
      ('Ben E. King', 'B. B. King'),
      ("Thirty Years' War", "Hundred Years' War"),
      ('6', '7'),
      ('Paris, Texas', 'Paris'),
    ];
    for (final (answer, guess) in pairs) {
      test('$guess must not match $answer', () {
        expect(QuizItem.acceptsAny(guess, [answer]), isFalse);
      });
    }
  });

  test('explicit aliases always match', () {
    expect(QuizItem.acceptsAny('Cassius Clay', ['Muhammad Ali', 'Cassius Clay']), isTrue);
    expect(QuizItem.acceptsAny('Graham Bell', ['Alexander Graham Bell']), isFalse);
  });
}
