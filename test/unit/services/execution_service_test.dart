import 'package:flutter_test/flutter_test.dart';
import 'package:twocandooit/services/execution_service.dart';
import 'package:twocandooit/models/routine.dart';
import 'package:twocandooit/models/step.dart';
import 'package:twocandooit/models/step_type.dart';
import 'package:twocandooit/models/app_settings.dart';
import 'package:twocandooit/models/routine_run.dart';
import '../../test_helpers.dart';

void main() {
  group('ExecutionService Tests', () {
    late Routine testRoutine;
    late AppSettings testSettings;

    setUp(() {
      testRoutine = TestHelpers.createTestRoutine();
      testSettings = TestHelpers.createTestSettings();
    });

    tearDown(() async {
      await ExecutionService.stopExecution();
    });

    group('ExecutionSession', () {
      test('should create session with default values', () {
        final session = ExecutionSession(routine: testRoutine);
        
        expect(session.routine, equals(testRoutine));
        expect(session.currentStepIndex, equals(0));
        expect(session.isPaused, isFalse);
        expect(session.startTime, isA<DateTime>());
        expect(session.pausedDuration, isNull);
      });

      test('should create session with custom values', () {
        final startTime = DateTime(2024, 1, 1, 10, 0, 0);
        final pausedDuration = Duration(minutes: 5);
        
        final session = ExecutionSession(
          routine: testRoutine,
          currentStepIndex: 2,
          isPaused: true,
          startTime: startTime,
          pausedDuration: pausedDuration,
        );
        
        expect(session.currentStepIndex, equals(2));
        expect(session.isPaused, isTrue);
        expect(session.startTime, equals(startTime));
        expect(session.pausedDuration, equals(pausedDuration));
      });

      test('should return correct current step', () {
        final session = ExecutionSession(routine: testRoutine);
        
        expect(session.currentStep, equals(testRoutine.steps[0]));
        
        session.currentStepIndex = 1;
        expect(session.currentStep, equals(testRoutine.steps[1]));
      });

      test('should return null for current step when index exceeds steps', () {
        final session = ExecutionSession(routine: testRoutine);
        session.currentStepIndex = testRoutine.steps.length + 1;
        
        expect(session.currentStep, isNull);
      });

      test('should calculate completion status correctly', () {
        final session = ExecutionSession(routine: testRoutine);
        
        expect(session.isCompleted, isFalse);
        
        session.currentStepIndex = testRoutine.steps.length;
        expect(session.isCompleted, isTrue);
      });

      test('should calculate progress correctly', () {
        final session = ExecutionSession(routine: testRoutine);
        
        expect(session.progress, equals(0.0));
        
        session.currentStepIndex = 1;
        expect(session.progress, equals(1.0 / testRoutine.steps.length));
        
        session.currentStepIndex = testRoutine.steps.length;
        expect(session.progress, equals(1.0));
      });

      test('should handle empty routine for progress', () {
        final emptyRoutine = Routine(name: 'Empty');
        final session = ExecutionSession(routine: emptyRoutine);
        
        expect(session.progress, equals(1.0));
      });

      test('should calculate total elapsed time', () {
        final session = ExecutionSession(routine: testRoutine);
        
        final elapsed = session.totalElapsed;
        expect(elapsed, isA<Duration>());
        expect(elapsed.inMilliseconds, greaterThan(0));
      });

      test('should calculate total elapsed time with paused duration', () {
        final session = ExecutionSession(
          routine: testRoutine,
          pausedDuration: Duration(minutes: 5),
        );
        
        final elapsed = session.totalElapsed;
        expect(elapsed, isA<Duration>());
      });
    });

    group('Service State Management', () {
      test('should track service state correctly', () {
        expect(ExecutionService.currentSession, isNull);
        expect(ExecutionService.isRunning, isFalse);
        expect(ExecutionService.isPaused, isFalse);
      });

      test('should update state when routine starts', () async {
        await ExecutionService.startRoutine(testRoutine, settings: testSettings);
        
        expect(ExecutionService.currentSession, isNotNull);
        expect(ExecutionService.isRunning, isTrue);
        expect(ExecutionService.isPaused, isFalse);
        expect(ExecutionService.currentSession!.routine, equals(testRoutine));
      });

      test('should update state when execution is paused', () async {
        await ExecutionService.startRoutine(testRoutine, settings: testSettings);
        await ExecutionService.pauseExecution();
        
        expect(ExecutionService.isRunning, isTrue);
        expect(ExecutionService.isPaused, isTrue);
      });

      test('should update state when execution is resumed', () async {
        await ExecutionService.startRoutine(testRoutine, settings: testSettings);
        await ExecutionService.pauseExecution();
        await ExecutionService.resumeExecution(settings: testSettings);
        
        expect(ExecutionService.isRunning, isTrue);
        expect(ExecutionService.isPaused, isFalse);
      });

      test('should clear state when execution stops', () async {
        await ExecutionService.startRoutine(testRoutine, settings: testSettings);
        await ExecutionService.stopExecution();
        
        expect(ExecutionService.currentSession, isNull);
        expect(ExecutionService.isRunning, isFalse);
        expect(ExecutionService.isPaused, isFalse);
      });
    });

    group('Routine Execution', () {
      test('should start routine with correct initial state', () async {
        await ExecutionService.startRoutine(testRoutine, settings: testSettings);
        
        final session = ExecutionService.currentSession!;
        expect(session.routine, equals(testRoutine));
        expect(session.currentStepIndex, equals(0));
        expect(session.isPaused, isFalse);
        expect(session.currentStep, equals(testRoutine.steps[0]));
      });

      test('should reset all steps when starting routine', () async {
        // Mark a step as completed
        testRoutine.steps[0].complete();
        expect(testRoutine.steps[0].isCompleted, isTrue);
        
        await ExecutionService.startRoutine(testRoutine, settings: testSettings);
        
        // Step should be reset
        expect(testRoutine.steps[0].isCompleted, isFalse);
      });

      test('should stop previous execution when starting new routine', () async {
        await ExecutionService.startRoutine(testRoutine, settings: testSettings);
        expect(ExecutionService.isRunning, isTrue);
        
        final anotherRoutine = TestHelpers.createTestRoutine(name: 'Another');
        await ExecutionService.startRoutine(anotherRoutine, settings: testSettings);
        
        expect(ExecutionService.currentSession!.routine, equals(anotherRoutine));
      });
    });

    group('Step Navigation', () {
      test('should advance to next step', () async {
        await ExecutionService.startRoutine(testRoutine, settings: testSettings);
        
        expect(ExecutionService.currentSession!.currentStepIndex, equals(0));
        
        await ExecutionService.nextStep(settings: testSettings);
        
        expect(ExecutionService.currentSession!.currentStepIndex, equals(1));
      });

      test('should complete routine when reaching last step', () async {
        await ExecutionService.startRoutine(testRoutine, settings: testSettings);
        
        // Navigate to last step
        final session = ExecutionService.currentSession!;
        session.currentStepIndex = testRoutine.steps.length - 1;
        
        await ExecutionService.nextStep(settings: testSettings);
        
        expect(ExecutionService.currentSession, isNull);
        expect(ExecutionService.isRunning, isFalse);
      });

      test('should go back to previous step', () async {
        await ExecutionService.startRoutine(testRoutine, settings: testSettings);
        
        // Go to next step first
        await ExecutionService.nextStep(settings: testSettings);
        expect(ExecutionService.currentSession!.currentStepIndex, equals(1));
        
        // Go back to previous step
        await ExecutionService.previousStep(settings: testSettings);
        expect(ExecutionService.currentSession!.currentStepIndex, equals(0));
      });

      test('should not go back from first step', () async {
        await ExecutionService.startRoutine(testRoutine, settings: testSettings);
        
        expect(ExecutionService.currentSession!.currentStepIndex, equals(0));
        
        await ExecutionService.previousStep(settings: testSettings);
        
        expect(ExecutionService.currentSession!.currentStepIndex, equals(0));
      });

      test('should reset step when going back', () async {
        await ExecutionService.startRoutine(testRoutine, settings: testSettings);
        
        // Complete current step and go to next
        testRoutine.steps[0].complete();
        await ExecutionService.nextStep(settings: testSettings);
        
        // Go back - previous step should be reset
        await ExecutionService.previousStep(settings: testSettings);
        
        expect(testRoutine.steps[0].isCompleted, isFalse);
      });
    });

    group('Pause and Resume', () {
      test('should pause execution', () async {
        await ExecutionService.startRoutine(testRoutine, settings: testSettings);
        
        await ExecutionService.pauseExecution();
        
        expect(ExecutionService.isPaused, isTrue);
      });

      test('should not pause if not running', () async {
        await ExecutionService.pauseExecution();
        
        expect(ExecutionService.isPaused, isFalse);
      });

      test('should not pause if already paused', () async {
        await ExecutionService.startRoutine(testRoutine, settings: testSettings);
        await ExecutionService.pauseExecution();
        
        expect(ExecutionService.isPaused, isTrue);
        
        await ExecutionService.pauseExecution();
        
        expect(ExecutionService.isPaused, isTrue);
      });

      test('should resume execution', () async {
        await ExecutionService.startRoutine(testRoutine, settings: testSettings);
        await ExecutionService.pauseExecution();
        
        await ExecutionService.resumeExecution(settings: testSettings);
        
        expect(ExecutionService.isPaused, isFalse);
      });

      test('should not resume if not paused', () async {
        await ExecutionService.startRoutine(testRoutine, settings: testSettings);
        
        await ExecutionService.resumeExecution(settings: testSettings);
        
        expect(ExecutionService.isPaused, isFalse);
      });

      test('should not resume if not running', () async {
        await ExecutionService.resumeExecution(settings: testSettings);
        
        expect(ExecutionService.isRunning, isFalse);
      });
    });

    group('Rep Steps', () {
      test('should handle rep step completion', () async {
        // Create routine with rep step
        final repStep = Step(
          title: 'Push-ups',
          type: StepType.reps,
          repsTarget: 10,
        );
        final repRoutine = Routine(name: 'Rep Test');
        repRoutine.addStep(repStep);
        
        await ExecutionService.startRoutine(repRoutine, settings: testSettings);
        
        // Complete one rep
        await ExecutionService.completeCurrentStep(settings: testSettings);
        
        expect(repStep.repsCompleted, equals(1));
        expect(ExecutionService.currentSession!.currentStepIndex, equals(0)); // Still on same step
      });

      test('should advance after completing all reps', () async {
        // Create routine with rep step
        final repStep = Step(
          title: 'Push-ups',
          type: StepType.reps,
          repsTarget: 2,
        );
        final basicStep = Step(title: 'Next Step', type: StepType.basic);
        final repRoutine = Routine(name: 'Rep Test');
        repRoutine.addStep(repStep);
        repRoutine.addStep(basicStep);
        
        await ExecutionService.startRoutine(repRoutine, settings: testSettings);
        
        // Complete first rep
        await ExecutionService.completeCurrentStep(settings: testSettings);
        expect(ExecutionService.currentSession!.currentStepIndex, equals(0));
        
        // Complete second rep - should advance to next step
        await ExecutionService.completeCurrentStep(settings: testSettings);
        expect(ExecutionService.currentSession!.currentStepIndex, equals(1));
      });
    });

    group('Random Selection', () {
      test('should select random choice from list', () async {
        final choices = ['Option A', 'Option B', 'Option C'];
        
        final selected = await ExecutionService.selectRandomChoice(choices);
        
        expect(choices.contains(selected), isTrue);
      });

      test('should handle empty choices list', () async {
        final selected = await ExecutionService.selectRandomChoice([]);
        
        expect(selected, equals(''));
      });

      test('should select random reps within range', () async {
        const minReps = 5;
        const maxReps = 15;
        
        final selectedReps = await ExecutionService.selectRandomReps(minReps, maxReps);
        
        expect(selectedReps, greaterThanOrEqualTo(minReps));
        expect(selectedReps, lessThanOrEqualTo(maxReps));
      });

      test('should handle invalid rep range', () async {
        const minReps = 15;
        const maxReps = 5;
        
        final selectedReps = await ExecutionService.selectRandomReps(minReps, maxReps);
        
        expect(selectedReps, equals(minReps));
      });
    });

    group('Streams', () {
      test('should emit session updates on session stream', () async {
        final sessionUpdates = <ExecutionSession>[];
        ExecutionService.sessionStream.listen((session) {
          sessionUpdates.add(session);
        });
        
        await ExecutionService.startRoutine(testRoutine, settings: testSettings);
        await Future.delayed(Duration(milliseconds: 100)); // Wait for stream
        
        expect(sessionUpdates, isNotEmpty);
        expect(sessionUpdates.last.routine, equals(testRoutine));
      });

      test('should emit events on event stream', () async {
        final events = <String>[];
        ExecutionService.eventStream.listen((event) {
          events.add(event);
        });
        
        await ExecutionService.startRoutine(testRoutine, settings: testSettings);
        await Future.delayed(Duration(milliseconds: 100)); // Wait for stream
        
        expect(events, contains('Routine started: ${testRoutine.name}'));
      });

      test('should emit timer updates on timer stream', () async {
        // Create routine with timer step
        final timerStep = Step(
          title: 'Timer Test',
          type: StepType.timer,
          timerDuration: 2, // 2 seconds
        );
        final timerRoutine = Routine(name: 'Timer Test');
        timerRoutine.addStep(timerStep);
        
        final timerUpdates = <int>[];
        ExecutionService.timerStream.listen((remainingSeconds) {
          timerUpdates.add(remainingSeconds);
        });
        
        await ExecutionService.startRoutine(timerRoutine, settings: testSettings);
        await Future.delayed(Duration(milliseconds: 100)); // Wait for initial timer
        
        expect(timerUpdates, isNotEmpty);
        expect(timerUpdates.first, equals(2));
      });
    });

    group('Error Handling', () {
      test('should handle null session gracefully', () async {
        // These should not throw exceptions
        await ExecutionService.nextStep(settings: testSettings);
        await ExecutionService.previousStep(settings: testSettings);
        await ExecutionService.pauseExecution();
        await ExecutionService.resumeExecution(settings: testSettings);
        await ExecutionService.completeCurrentStep(settings: testSettings);
        
        expect(ExecutionService.isRunning, isFalse);
      });

      test('should handle routine with no steps', () async {
        final emptyRoutine = Routine(name: 'Empty');
        
        await ExecutionService.startRoutine(emptyRoutine, settings: testSettings);
        
        expect(ExecutionService.currentSession!.isCompleted, isTrue);
        expect(ExecutionService.currentSession!.currentStep, isNull);
      });
    });

    group('Cleanup', () {
      test('should dispose resources properly', () {
        // This should not throw exceptions
        expect(() => ExecutionService.dispose(), returnsNormally);
      });
    });
  });
}