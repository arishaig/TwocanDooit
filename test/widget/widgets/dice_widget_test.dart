import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dooit/ui/widgets/dice_widget.dart';

void main() {
  group('DiceWidget Tests', () {
    testWidgets('should display static dice when not rolling', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DiceWidget(
              isRolling: false,
              result: null,
              optionCount: 6,
            ),
          ),
        ),
      );
      
      // Allow animations to settle
      await tester.pumpAndSettle();

      // Should find the dice widget
      expect(find.byType(DiceWidget), findsOneWidget);
      
      // Should show the tap instruction
      expect(find.text('TAP'), findsOneWidget);
    });

    testWidgets('should show result when provided', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DiceWidget(
              isRolling: false,
              result: 4,
              optionCount: 6,
            ),
          ),
        ),
      );
      
      // Allow animations to settle
      await tester.pumpAndSettle();

      // Should display the result
      expect(find.text('4'), findsOneWidget);
    });

    testWidgets('should handle different option counts', (WidgetTester tester) async {
      // Test D4 (4-sided die)
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DiceWidget(
              isRolling: false,
              result: 3,
              optionCount: 4,
            ),
          ),
        ),
      );
      
      await tester.pumpAndSettle();
      expect(find.byType(DiceWidget), findsOneWidget);
      expect(find.text('3'), findsOneWidget);

      // Test D20 (20-sided die)
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DiceWidget(
              isRolling: false,
              result: 15,
              optionCount: 20,
            ),
          ),
        ),
      );
      
      await tester.pumpAndSettle();
      expect(find.text('15'), findsOneWidget);
    });

    testWidgets('should be tappable', (WidgetTester tester) async {
      bool wasTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GestureDetector(
              onTap: () => wasTapped = true,
              child: const DiceWidget(
                isRolling: false,
                result: null,
                optionCount: 6,
              ),
            ),
          ),
        ),
      );
      
      await tester.pumpAndSettle();
      
      // Tap on the GestureDetector instead of the DiceWidget
      await tester.tap(find.byType(GestureDetector));
      expect(wasTapped, true);
    });

    testWidgets('should handle rolling state', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DiceWidget(
              isRolling: true,
              result: null,
              optionCount: 6,
            ),
          ),
        ),
      );
      
      // Pump a few frames to start the animation
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Should show some indication of rolling (animation controller active)
      expect(find.byType(DiceWidget), findsOneWidget);
      expect(find.byType(AnimatedBuilder), findsWidgets);
      
      // When rolling, TAP instruction should not be shown
      expect(find.text('TAP'), findsNothing);
      
      // Dispose of the widget to stop timers
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    });
  });
}