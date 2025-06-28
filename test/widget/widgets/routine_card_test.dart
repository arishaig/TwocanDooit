import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dooit/ui/widgets/routine_card.dart';
import 'package:dooit/models/routine.dart';
import 'package:dooit/models/step.dart' as DooitStep;
import 'package:dooit/models/step_type.dart';

void main() {
  group('RoutineCard Tests', () {
    late Routine testRoutine;

    setUp(() {
      testRoutine = Routine(
        name: 'Morning Routine',
        description: 'Start your day right',
        category: 'Daily',
        voiceEnabled: true,
      );
      
      // Add some steps for testing
      testRoutine.addStep(DooitStep.Step(title: 'Brush Teeth', type: StepType.basic));
      testRoutine.addStep(DooitStep.Step(title: 'Exercise', type: StepType.timer, timerDuration: 1800));
      testRoutine.addStep(DooitStep.Step(title: 'Push-ups', type: StepType.reps, repsTarget: 20));
    });

    testWidgets('should display routine information correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RoutineCard(
              routine: testRoutine,
              onTap: () {},
            ),
          ),
        ),
      );

      // Should display routine name
      expect(find.text('Morning Routine'), findsOneWidget);
      
      // Should display description
      expect(find.text('Start your day right'), findsOneWidget);
      
      // Should display step count
      expect(find.text('3 steps'), findsOneWidget);
      
      // Should display category if provided
      expect(find.text('Daily'), findsOneWidget);
    });

    testWidgets('should be tappable', (WidgetTester tester) async {
      bool wasTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RoutineCard(
              routine: testRoutine,
              onTap: () => wasTapped = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(RoutineCard));
      expect(wasTapped, true);
    });

    testWidgets('should show step count correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RoutineCard(
              routine: testRoutine,
              onTap: () {},
            ),
          ),
        ),
      );

      // Should show step count
      expect(find.text('3 steps'), findsOneWidget);
      expect(find.byIcon(Icons.format_list_numbered), findsOneWidget);
    });

    testWidgets('should handle routine without description', (WidgetTester tester) async {
      final routineNoDesc = Routine(name: 'Simple Routine');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RoutineCard(
              routine: routineNoDesc,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('Simple Routine'), findsOneWidget);
      expect(find.text('0 steps'), findsOneWidget);
    });

    testWidgets('should show start button', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RoutineCard(
              routine: testRoutine,
              onTap: () {},
            ),
          ),
        ),
      );

      // Should show start button
      expect(find.text('Start'), findsOneWidget);
      expect(find.byIcon(Icons.play_arrow), findsOneWidget);
    });

    testWidgets('should show menu button and handle actions', (WidgetTester tester) async {
      bool editCalled = false;
      bool deleteCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RoutineCard(
              routine: testRoutine,
              onTap: () {},
              onEdit: () => editCalled = true,
              onDelete: () => deleteCalled = true,
            ),
          ),
        ),
      );

      // Should show popup menu button
      expect(find.byType(PopupMenuButton<String>), findsOneWidget);
    });
  });
}