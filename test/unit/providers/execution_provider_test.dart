import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:twocandooit/providers/execution_provider.dart';
import 'package:twocandooit/models/routine.dart';
import 'package:twocandooit/models/step.dart';
import 'package:twocandooit/models/step_type.dart';
import 'package:twocandooit/models/app_settings.dart';
import 'package:twocandooit/services/execution_service.dart';
import '../../test_helpers.dart';

void main() {
  group('ExecutionProvider Tests', () {
    late ExecutionProvider provider;
    late Routine testRoutine;
    late AppSettings testSettings;

    setUpAll(() async {
      // Mock SharedPreferences
      SharedPreferences.setMockInitialValues({});
    });

    setUp(() async {
      provider = ExecutionProvider();
      testRoutine = TestHelpers.createTestRoutine();
      testSettings = TestHelpers.createTestSettings();
      
      // Clean up any existing execution state
      await ExecutionService.stopExecution();
    });

    tearDown(() async {
      await ExecutionService.stopExecution();
      provider.dispose();
    });

    group('Initial State', () {
      test('should have correct initial state', () {
        expect(provider.currentSession, isNull);
        expect(provider.isRunning, isFalse);
        expect(provider.isPaused, isFalse);
        expect(provider.isRolling, isFalse);
        expect(provider.remainingSeconds, equals(0));
        expect(provider.lastEvent, isEmpty);
        expect(provider.currentRoutine, isNull);
        expect(provider.currentStep, isNull);
        expect(provider.currentStepIndex, equals(0));
        expect(provider.progress, equals(0.0));
      });

      test('should initialize stream subscriptions', () {
        // Verify that provider is listening to streams
        expect(provider, isNotNull);
        // Stream subscriptions are private, so we can't directly test them
        // but we can test that they work by triggering events
      });
    });

    group('Routine Execution', () {
      test('should start routine and update state', () async {
        var notificationCount = 0;
        provider.addListener(() {
          notificationCount++;
        });
        
        await provider.startRoutine(testRoutine, settings: testSettings);
        
        // Wait for stream updates
        await Future.delayed(Duration(milliseconds: 100));
        
        expect(provider.isRunning, isTrue);
        expect(provider.currentSession, isNotNull);
        expect(provider.currentRoutine, equals(testRoutine));
        expect(provider.currentStep, isNotNull);
        expect(notificationCount, greaterThan(0));
      });

      test('should pause and resume execution', () async {
        await provider.startRoutine(testRoutine, settings: testSettings);
        await Future.delayed(Duration(milliseconds: 100));
        
        await provider.pauseExecution();
        expect(provider.isPaused, isTrue);
        
        await provider.resumeExecution(settings: testSettings);
        expect(provider.isPaused, isFalse);
      });

      test('should stop execution and clear state', () async {
        await provider.startRoutine(testRoutine, settings: testSettings);
        await Future.delayed(Duration(milliseconds: 100));
        
        expect(provider.isRunning, isTrue);
        
        await provider.stopExecution();
        
        expect(provider.isRunning, isFalse);
        expect(provider.currentSession, isNull);
        expect(provider.remainingSeconds, equals(0));
        expect(provider.lastEvent, isEmpty);
        expect(provider.isRolling, isFalse);
      });
    });

    group('Step Navigation', () {
      test('should navigate to next step', () async {
        await provider.startRoutine(testRoutine, settings: testSettings);
        await Future.delayed(Duration(milliseconds: 100));
        
        final initialStepIndex = provider.currentStepIndex;
        
        await provider.nextStep(settings: testSettings);
        await Future.delayed(Duration(milliseconds: 100));
        
        expect(provider.currentStepIndex, equals(initialStepIndex + 1));
      });

      test('should navigate to previous step', () async {
        await provider.startRoutine(testRoutine, settings: testSettings);
        await Future.delayed(Duration(milliseconds: 100));
        
        // Go to next step first
        await provider.nextStep(settings: testSettings);
        await Future.delayed(Duration(milliseconds: 100));
        
        final currentStepIndex = provider.currentStepIndex;
        
        await provider.previousStep(settings: testSettings);
        await Future.delayed(Duration(milliseconds: 100));
        
        expect(provider.currentStepIndex, equals(currentStepIndex - 1));
      });

      test('should complete current step', () async {
        await provider.startRoutine(testRoutine, settings: testSettings);
        await Future.delayed(Duration(milliseconds: 100));
        
        await provider.completeCurrentStep(settings: testSettings);
        
        // This should trigger some state change
        expect(provider.currentSession, isNotNull);
      });
    });

    group('Random Selection', () {
      test('should select random choice with rolling animation', () async {
        final choices = ['Option A', 'Option B', 'Option C'];
        
        var notificationCount = 0;
        provider.addListener(() {
          notificationCount++;
        });
        
        final resultFuture = provider.selectRandomChoice(choices);
        
        // Should be rolling immediately
        expect(provider.isRolling, isTrue);
        
        final result = await resultFuture;
        
        expect(provider.isRolling, isFalse);
        expect(choices.contains(result), isTrue);
        expect(notificationCount, greaterThan(0));
      });

      test('should select random reps with rolling animation', () async {
        const minReps = 5;
        const maxReps = 15;
        
        var notificationCount = 0;
        provider.addListener(() {
          notificationCount++;
        });
        
        final resultFuture = provider.selectRandomReps(minReps, maxReps);
        
        // Should be rolling immediately
        expect(provider.isRolling, isTrue);
        
        final result = await resultFuture;
        
        expect(provider.isRolling, isFalse);
        expect(result, greaterThanOrEqualTo(minReps));
        expect(result, lessThanOrEqualTo(maxReps));
        expect(notificationCount, greaterThan(0));
      });

      test('should manually set rolling state', () {
        var notificationCount = 0;
        provider.addListener(() {
          notificationCount++;
        });
        
        provider.setRolling(true);
        expect(provider.isRolling, isTrue);
        expect(notificationCount, equals(1));
        
        provider.setRolling(false);
        expect(provider.isRolling, isFalse);
        expect(notificationCount, equals(2));
      });
    });

    group('Timer Display', () {
      test('should format timer display correctly', () {
        // Test various time formats
        provider.setRolling(true); // Use this to trigger a state change and set internal timer
        
        // We can't directly set _remainingSeconds, but we can test the format logic
        expect(provider.timerDisplay, matches(RegExp(r'^\d{2}:\d{2}$')));
      });

      test('should format session duration display correctly', () {
        expect(provider.sessionDurationDisplay, equals('00:00'));
      });

      test('should format session duration when session is active', () async {
        await provider.startRoutine(testRoutine, settings: testSettings);
        await Future.delayed(Duration(milliseconds: 100));
        
        final display = provider.sessionDurationDisplay;
        expect(display, matches(RegExp(r'^\d{2}:\d{2}$')));
      });
    });

    group('Stream Updates', () {
      test('should update state when session stream emits', () async {
        var notificationCount = 0;
        provider.addListener(() {
          notificationCount++;
        });
        
        await provider.startRoutine(testRoutine, settings: testSettings);
        await Future.delayed(Duration(milliseconds: 100));
        
        expect(provider.currentSession, isNotNull);
        expect(notificationCount, greaterThan(0));
      });

      test('should update timer when timer stream emits', () async {
        // Create a routine with a timer step
        final timerStep = Step(
          title: 'Timer Test',
          type: StepType.timer,
          timerDuration: 5, // 5 seconds
        );
        final timerRoutine = Routine(name: 'Timer Test');
        timerRoutine.addStep(timerStep);
        
        var timerUpdates = <int>[];
        provider.addListener(() {
          timerUpdates.add(provider.remainingSeconds);
        });
        
        await provider.startRoutine(timerRoutine, settings: testSettings);
        await Future.delayed(Duration(milliseconds: 200));
        
        expect(timerUpdates, isNotEmpty);
      });

      test('should update event when event stream emits', () async {
        var eventUpdates = <String>[];
        provider.addListener(() {
          if (provider.lastEvent.isNotEmpty) {
            eventUpdates.add(provider.lastEvent);
          }
        });
        
        await provider.startRoutine(testRoutine, settings: testSettings);
        await Future.delayed(Duration(milliseconds: 100));
        
        expect(eventUpdates, isNotEmpty);
        expect(eventUpdates.any((event) => event.contains('started')), isTrue);
      });
    });

    group('State Properties', () {
      test('should derive properties from current session', () async {
        await provider.startRoutine(testRoutine, settings: testSettings);
        await Future.delayed(Duration(milliseconds: 100));
        
        expect(provider.currentRoutine, equals(testRoutine));
        expect(provider.currentStep, isNotNull);
        expect(provider.currentStepIndex, isA<int>());
        expect(provider.progress, isA<double>());
        expect(provider.progress, greaterThanOrEqualTo(0.0));
        expect(provider.progress, lessThanOrEqualTo(1.0));
      });

      test('should return default values when no session', () {
        expect(provider.currentRoutine, isNull);
        expect(provider.currentStep, isNull);
        expect(provider.currentStepIndex, equals(0));
        expect(provider.progress, equals(0.0));
      });
    });

    group('Listener Management', () {
      test('should notify listeners on state changes', () async {
        var notificationCount = 0;
        provider.addListener(() {
          notificationCount++;
        });
        
        await provider.startRoutine(testRoutine, settings: testSettings);
        await Future.delayed(Duration(milliseconds: 100));
        
        await provider.pauseExecution();
        await provider.resumeExecution(settings: testSettings);
        await provider.stopExecution();
        
        expect(notificationCount, greaterThan(3));
      });

      test('should stop notifications when listener is removed', () async {
        var notificationCount = 0;
        void listener() {
          notificationCount++;
        }
        
        provider.addListener(listener);
        await provider.startRoutine(testRoutine, settings: testSettings);
        await Future.delayed(Duration(milliseconds: 100));
        
        provider.removeListener(listener);
        await provider.stopExecution();
        
        // Should have some notifications from the start but not from stop
        expect(notificationCount, greaterThan(0));
      });
    });

    group('Disposal', () {
      test('should clean up resources on dispose', () {
        // This should not throw exceptions
        expect(() => provider.dispose(), returnsNormally);
      });

      test('should cancel stream subscriptions on dispose', () {
        provider.dispose();
        
        // After disposal, the provider should still be in a valid state
        expect(provider.currentSession, isNull);
        expect(provider.isRunning, isFalse);
      });
    });

    group('Error Handling', () {
      test('should handle execution service errors gracefully', () async {
        // These operations should not throw exceptions
        await provider.startRoutine(testRoutine, settings: testSettings);
        await provider.pauseExecution();
        await provider.resumeExecution(settings: testSettings);
        await provider.nextStep(settings: testSettings);
        await provider.previousStep(settings: testSettings);
        await provider.completeCurrentStep(settings: testSettings);
        await provider.stopExecution();
        
        expect(provider.isRunning, isFalse);
      });

      test('should handle random selection with empty choices', () async {
        final result = await provider.selectRandomChoice([]);
        expect(result, isEmpty);
        expect(provider.isRolling, isFalse);
      });
    });
  });
}