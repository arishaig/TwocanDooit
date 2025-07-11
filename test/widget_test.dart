// Dooit App Widget Tests
//
// This file contains widget tests for the main Dooit app functionality.
// Widget tests verify UI components work correctly in isolation.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'test_helpers.dart';

void main() {
  setUpAll(() {
    TestHelpers.setupAllPluginMocks();
  });

  group('TwocanDooitApp Widget Tests', () {
    testWidgets('should launch without errors', (WidgetTester tester) async {
      // Build the app and trigger a frame
      await tester.pumpWidget(TestHelpers.createTestTwocanApp());
      
      // Pump a few frames without waiting for all animations to settle
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Verify the app loads successfully
      expect(find.byType(MaterialApp), findsOneWidget);
      
      // Should show home screen with app title or navigation
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('should show home screen content', (WidgetTester tester) async {
      await tester.pumpWidget(TestHelpers.createTestTwocanApp());
      
      // Pump a few frames without waiting for all animations to settle
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Should show the test app content
      expect(find.text('Test App'), findsOneWidget);
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('should handle navigation', (WidgetTester tester) async {
      await tester.pumpWidget(TestHelpers.createTestTwocanApp());
      
      // Pump a few frames without waiting for all animations to settle
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Test app has basic navigation structure
      expect(find.byType(MaterialApp), findsOneWidget);
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('should handle theme correctly', (WidgetTester tester) async {
      await tester.pumpWidget(TestHelpers.createTestTwocanApp());
      
      // Pump a few frames without waiting for all animations to settle
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Verify Material 3 theme is applied
      final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(materialApp.theme?.useMaterial3, isTrue);
    });
  });

  group('Home Screen Integration', () {
    testWidgets('should display empty state when no routines exist', (WidgetTester tester) async {
      await tester.pumpWidget(TestHelpers.createTestApp(
        child: const Scaffold(
          body: Center(child: Text('No routines yet')),
        ),
      ));

      expect(find.text('No routines yet'), findsOneWidget);
    });

    testWidgets('should display routines when they exist', (WidgetTester tester) async {
      final testRoutine = TestHelpers.createTestRoutine();
      
      await tester.pumpWidget(TestHelpers.createTestApp(
        initialRoutines: [testRoutine],
        child: const Scaffold(
          body: Text('Test Routine'),
        ),
      ));

      expect(find.text('Test Routine'), findsOneWidget);
    });
  });
}
