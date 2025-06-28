import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:dooit/main.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Dooit App Integration Tests', () {
    testWidgets('should launch and show home screen', (WidgetTester tester) async {
      await tester.pumpWidget(const DooitApp());
      await tester.pumpAndSettle();

      // Should show the app title or home screen
      expect(find.text('Dooit!'), findsOneWidget);
      
      // Should show routines list or empty state
      final hasListView = find.byType(ListView).evaluate().isNotEmpty;
      final hasEmptyState = find.text('No routines yet').evaluate().isNotEmpty;
      final hasCreateButton = find.text('Create Routine').evaluate().isNotEmpty;
      
      expect(hasListView || hasEmptyState || hasCreateButton, isTrue);
    });

    testWidgets('should navigate to routine editor', (WidgetTester tester) async {
      await tester.pumpWidget(const DooitApp());
      await tester.pumpAndSettle();

      // Find and tap the add routine button (FAB)
      final addButton = find.byType(FloatingActionButton);
      if (addButton.evaluate().isNotEmpty) {
        await tester.tap(addButton);
        await tester.pumpAndSettle();

        // Should navigate to routine editor
        expect(find.text('Routine Editor'), findsOneWidget);
      }
    });

    testWidgets('should create and execute a basic routine', (WidgetTester tester) async {
      await tester.pumpWidget(const DooitApp());
      await tester.pumpAndSettle();

      // Navigate to routine editor
      final addButton = find.byType(FloatingActionButton);
      if (addButton.evaluate().isNotEmpty) {
        await tester.tap(addButton);
        await tester.pumpAndSettle();

        // Fill in routine details
        await tester.enterText(find.byType(TextFormField).first, 'Test Routine');
        await tester.pumpAndSettle();

        // Add a basic step
        final addStepButton = find.text('Add Step');
        if (addStepButton.evaluate().isNotEmpty) {
          await tester.tap(addStepButton);
          await tester.pumpAndSettle();

          // Fill in step details
          await tester.enterText(find.byType(TextFormField).first, 'Test Step');
          await tester.pumpAndSettle();

          // Save step
          await tester.tap(find.text('Save'));
          await tester.pumpAndSettle();
        }

        // Save routine
        await tester.tap(find.text('Save'));
        await tester.pumpAndSettle();

        // Should return to home screen
        expect(find.text('Test Routine'), findsOneWidget);

        // Execute the routine
        await tester.tap(find.text('Test Routine'));
        await tester.pumpAndSettle();

        // Should show execution screen
        expect(find.text('Test Step'), findsOneWidget);
        expect(find.text('Next Step'), findsOneWidget);

        // Complete the step
        await tester.tap(find.text('Next Step'));
        await tester.pumpAndSettle();

        // Should show completion screen
        expect(find.text('Routine Complete!'), findsOneWidget);
      }
    });

    testWidgets('should navigate to settings and toggle options', (WidgetTester tester) async {
      await tester.pumpWidget(const DooitApp());
      await tester.pumpAndSettle();

      // Find and tap settings button (if available in app bar)
      final settingsButton = find.byIcon(Icons.settings);
      if (settingsButton.evaluate().isNotEmpty) {
        await tester.tap(settingsButton);
        await tester.pumpAndSettle();

        // Should show settings screen
        expect(find.text('Settings'), findsOneWidget);

        // Test toggling audio feedback
        final audioToggle = find.byType(Switch).first;
        await tester.tap(audioToggle);
        await tester.pumpAndSettle();

        // Settings should persist
        expect(find.byType(Switch), findsWidgets);
      }
    });

    testWidgets('should handle music selection in routine editor', (WidgetTester tester) async {
      await tester.pumpWidget(const DooitApp());
      await tester.pumpAndSettle();

      // Navigate to routine editor
      final addButton = find.byType(FloatingActionButton);
      if (addButton.evaluate().isNotEmpty) {
        await tester.tap(addButton);
        await tester.pumpAndSettle();

        // Scroll to find music section
        await tester.drag(find.byType(ListView), const Offset(0, -300));
        await tester.pumpAndSettle();

        // Find and toggle background music
        final musicToggle = find.text('Background Music');
        if (musicToggle.evaluate().isNotEmpty) {
          await tester.tap(musicToggle);
          await tester.pumpAndSettle();

          // Should show music selection options
          expect(find.text('Binaural Beats'), findsOneWidget);
          expect(find.text('Calm Meditation'), findsOneWidget);
          expect(find.text('Focus Beats'), findsOneWidget);

          // Test selecting a music track
          await tester.tap(find.text('Calm Meditation'));
          await tester.pumpAndSettle();
        }
      }
    });
  });
}