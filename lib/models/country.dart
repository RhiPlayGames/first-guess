import 'quiz_item.dart';

class Country extends QuizItem {
  const Country({
    super.id,
    required String name,
    required super.imagePath,
    required super.clues,
    super.acceptedAnswers = const [],
  }) : super(answer: name);

  String get name => answer;
}