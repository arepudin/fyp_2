import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fyp_2/screens/measurement/measurement_guide_screen.dart';
import 'package:fyp_2/models/measurement_result.dart';

void main() {
  group('MeasurementGuideScreen Tests', () {
    testWidgets('should display guide steps correctly', (WidgetTester tester) async {
      // Build the widget
      await tester.pumpWidget(MaterialApp(
        home: MeasurementGuideScreen(),
      ));

      // Verify the initial screen content
      expect(find.text('Welcome to Window Measurement'), findsOneWidget);
      expect(find.text('1 of 3'), findsOneWidget);
      expect(find.text('Next'), findsOneWidget);

      // Navigate to next step
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      // Verify second step
      expect(find.text('Measure Window Width'), findsOneWidget);
      expect(find.text('2 of 3'), findsOneWidget);
      expect(find.text('Previous'), findsOneWidget);

      // Navigate to final step
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      // Verify final step
      expect(find.text('Measure Window Height'), findsOneWidget);
      expect(find.text('3 of 3'), findsOneWidget);
      expect(find.text('Enter Measurements'), findsOneWidget);
    });

    testWidgets('should show manual input dialog', (WidgetTester tester) async {
      // Build the widget
      await tester.pumpWidget(MaterialApp(
        home: MeasurementGuideScreen(),
      ));

      // Navigate to final step
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      // Tap on Enter Measurements
      await tester.tap(find.text('Enter Measurements'));
      await tester.pumpAndSettle();

      // Verify dialog appears
      expect(find.text('Enter Measurements'), findsOneWidget);
      expect(find.text('Width (m)'), findsOneWidget);
      expect(find.text('Height (m)'), findsOneWidget);
      expect(find.text('Save'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
    });

    testWidgets('should handle unit switching in dialog', (WidgetTester tester) async {
      // Build the widget
      await tester.pumpWidget(MaterialApp(
        home: MeasurementGuideScreen(),
      ));

      // Navigate to final step and open dialog
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Enter Measurements'));
      await tester.pumpAndSettle();

      // Verify initial unit is meters
      expect(find.text('Width (m)'), findsOneWidget);
      expect(find.text('Height (m)'), findsOneWidget);

      // Switch to inches
      await tester.tap(find.text('Meters'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Inches'));
      await tester.pumpAndSettle();

      // Verify unit changed to inches
      expect(find.text('Width (in)'), findsOneWidget);
      expect(find.text('Height (in)'), findsOneWidget);
    });
  });
}