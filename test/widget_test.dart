import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:beat_guess/main.dart';

void main() {
  testWidgets('BeatGuess App startet korrekt', (WidgetTester tester) async {
    // Baue unsere App und löse einen Frame aus
    await tester.pumpWidget(const BeatGuessApp());

    // Prüfe, ob unsere App korrekt geladen wurde, indem wir nach einem Text suchen
    expect(find.text('Welches Jahr?'), findsOneWidget);
  });
}