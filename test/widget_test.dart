import 'package:flutter_test/flutter_test.dart';
import 'package:first_guess/main.dart';

void main() {
  testWidgets('App loads', (WidgetTester tester) async {
    await tester.pumpWidget(const FirstGuessApp());

    expect(find.text('FIRST GUESS'), findsOneWidget);
  });
}