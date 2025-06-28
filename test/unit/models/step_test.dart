import 'package:flutter_test/flutter_test.dart';
import 'package:dooit/models/step.dart';
import 'package:dooit/models/step_type.dart';

void main() {
  group('Step Model Tests', () {
    test('should create basic step with default values', () {
      final step = Step(title: 'Basic Step');

      expect(step.title, 'Basic Step');
      expect(step.type, StepType.basic);
      expect(step.isCompleted, false);
      expect(step.voiceEnabled, true);
      expect(step.id, isNotEmpty);
    });

    test('should create timer step correctly', () {
      final step = Step(
        title: 'Timer Step',
        type: StepType.timer,
        timerDuration: 300, // 5 minutes
      );

      expect(step.type, StepType.timer);
      expect(step.timerDuration, 300);
      expect(step.displayText, 'Timer Step (5:00)');
    });

    test('should create reps step correctly', () {
      final step = Step(
        title: 'Push-ups',
        type: StepType.reps,
        repsTarget: 20,
      );

      expect(step.type, StepType.reps);
      expect(step.repsTarget, 20);
      expect(step.repsCompleted, 0);
      expect(step.displayText, 'Push-ups (0/20)');
    });

    test('should handle random reps correctly', () {
      final step = Step(
        title: 'Random Push-ups',
        type: StepType.reps,
        randomizeReps: true,
        repsMin: 5,
        repsMax: 15,
        repsTarget: 5, // Should start at min
      );

      expect(step.randomizeReps, true);
      expect(step.repsMin, 5);
      expect(step.repsMax, 15);
      expect(step.repsTarget, 5);

      step.randomizeRepsTarget();
      expect(step.repsTarget, greaterThanOrEqualTo(5));
      expect(step.repsTarget, lessThanOrEqualTo(15));
    });

    test('should create random choice step correctly', () {
      final step = Step(
        title: 'Choose Exercise',
        type: StepType.randomChoice,
        choices: ['Push-ups', 'Squats', 'Burpees'],
      );

      expect(step.type, StepType.randomChoice);
      expect(step.choices, ['Push-ups', 'Squats', 'Burpees']);
      expect(step.selectedChoice, isNull);
      expect(step.displayText, 'Choose Exercise (3 options)');

      step.selectedChoice = 'Push-ups';
      expect(step.displayText, 'Choose Exercise → Push-ups');
    });

    test('should reset step correctly', () {
      final step = Step(
        title: 'Test Step',
        type: StepType.reps,
        repsTarget: 10,
        randomizeReps: true,
        repsMin: 5,
        repsMax: 15,
      );

      // Simulate step progress
      step.repsCompleted = 7;
      step.complete();

      expect(step.isCompleted, true);
      expect(step.repsCompleted, 7);

      // Reset should restore initial state
      step.reset();

      expect(step.isCompleted, false);
      expect(step.repsCompleted, 0);
      expect(step.repsTarget, 5); // Should reset to repsMin for random reps
    });

    test('should serialize to/from JSON correctly', () {
      final step = Step(
        title: 'JSON Test Step',
        description: 'A step for testing JSON',
        type: StepType.timer,
        timerDuration: 180,
        voiceEnabled: false,
      );

      final json = step.toJson();
      final recreatedStep = Step.fromJson(json);

      expect(recreatedStep.title, step.title);
      expect(recreatedStep.description, step.description);
      expect(recreatedStep.type, step.type);
      expect(recreatedStep.timerDuration, step.timerDuration);
      expect(recreatedStep.voiceEnabled, step.voiceEnabled);
    });

    test('should handle copyWith correctly', () {
      final step = Step(
        title: 'Original Step',
        type: StepType.basic,
        voiceEnabled: true,
      );

      final copied = step.copyWith(
        title: 'Updated Step',
        voiceEnabled: false,
      );

      expect(copied.title, 'Updated Step');
      expect(copied.voiceEnabled, false);
      expect(copied.type, step.type); // Unchanged
      expect(copied.id, step.id); // Should preserve ID
    });

    test('should calculate timer display text correctly', () {
      final step1 = Step(title: 'Short Timer', type: StepType.timer, timerDuration: 65);
      expect(step1.displayText, 'Short Timer (1:05)');

      final step2 = Step(title: 'Long Timer', type: StepType.timer, timerDuration: 3600);
      expect(step2.displayText, 'Long Timer (60:00)');

      final step3 = Step(title: 'Exact Minute', type: StepType.timer, timerDuration: 300);
      expect(step3.displayText, 'Exact Minute (5:00)');
    });
  });
}