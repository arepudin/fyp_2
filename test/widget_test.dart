import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fyp_2/main.dart';

void main() {
  testWidgets('App should load without errors', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Wait for splash screen and initialization
    await tester.pumpAndSettle();

    // Verify that the app loads (should show splash screen or sign in)
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
