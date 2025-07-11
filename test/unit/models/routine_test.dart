import 'package:flutter_test/flutter_test.dart';
import 'package:twocandooit/models/routine.dart';
import 'package:twocandooit/models/step.dart';
import 'package:twocandooit/models/step_type.dart';

void main() {
  group('Routine Model Tests', () {
    late Routine testRoutine;

    setUp(() {
      testRoutine = Routine(
        name: 'Test Routine',
        description: 'A test routine',
        category: 'Testing',
        voiceEnabled: true,
        musicEnabled: true,
        musicTrack: 'Calm Meditation',
        isBuiltInTrack: true,
      );
    });

    test('should create routine with correct properties', () {
      expect(testRoutine.name, 'Test Routine');
      expect(testRoutine.description, 'A test routine');
      expect(testRoutine.category, 'Testing');
      expect(testRoutine.voiceEnabled, true);
      expect(testRoutine.musicEnabled, true);
      expect(testRoutine.musicTrack, 'Calm Meditation');
      expect(testRoutine.isBuiltInTrack, true);
      expect(testRoutine.id, isNotEmpty);
      expect(testRoutine.steps, isEmpty);
    });

    test('should add steps correctly', () {
      final step = Step(title: 'Test Step', type: StepType.basic);
      testRoutine.addStep(step);

      expect(testRoutine.steps.length, 1);
      expect(testRoutine.steps.first.title, 'Test Step');
      expect(testRoutine.stepCount, 1);
    });

    test('should calculate progress correctly', () {
      final step1 = Step(title: 'Step 1', type: StepType.basic);
      final step2 = Step(title: 'Step 2', type: StepType.basic);
      
      testRoutine.addStep(step1);
      testRoutine.addStep(step2);

      expect(testRoutine.progressPercentage, 0.0);

      step1.complete();
      expect(testRoutine.progressPercentage, 0.5);

      step2.complete();
      expect(testRoutine.progressPercentage, 1.0);
      expect(testRoutine.isCompleted, true);
    });

    test('should serialize to/from JSON correctly', () {
      final step = Step(title: 'Test Step', type: StepType.timer, timerDuration: 120);
      testRoutine.addStep(step);

      final json = testRoutine.toJson();
      final recreatedRoutine = Routine.fromJson(json);

      expect(recreatedRoutine.name, testRoutine.name);
      expect(recreatedRoutine.description, testRoutine.description);
      expect(recreatedRoutine.musicEnabled, testRoutine.musicEnabled);
      expect(recreatedRoutine.musicTrack, testRoutine.musicTrack);
      expect(recreatedRoutine.steps.length, 1);
      expect(recreatedRoutine.steps.first.title, 'Test Step');
      expect(recreatedRoutine.steps.first.timerDuration, 120);
    });

    test('should reset progress correctly', () {
      final step1 = Step(title: 'Step 1', type: StepType.basic);
      final step2 = Step(title: 'Step 2', type: StepType.reps, repsTarget: 5);
      
      testRoutine.addStep(step1);
      testRoutine.addStep(step2);

      step1.complete();
      step2.repsCompleted = 3;

      testRoutine.resetProgress();

      expect(step1.isCompleted, false);
      expect(step2.repsCompleted, 0);
      expect(testRoutine.progressPercentage, 0.0);
    });

    test('should handle copyWith correctly', () {
      final copied = testRoutine.copyWith(
        name: 'Updated Routine',
        musicEnabled: false,
      );

      expect(copied.name, 'Updated Routine');
      expect(copied.musicEnabled, false);
      expect(copied.description, testRoutine.description); // Unchanged
      expect(copied.id, testRoutine.id); // Should preserve ID
    });
  });
}