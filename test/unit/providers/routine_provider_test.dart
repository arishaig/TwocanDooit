import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:twocandooit/providers/routine_provider.dart';
import 'package:twocandooit/models/routine.dart';
import 'package:twocandooit/models/step.dart';
import 'package:twocandooit/models/step_type.dart';
import 'package:twocandooit/services/routine_service.dart';
import '../../test_helpers.dart';

void main() {
  group('RoutineProvider Tests', () {
    late RoutineProvider provider;
    late Routine testRoutine;
    late Step testStep;

    setUpAll(() async {
      // Mock SharedPreferences
      SharedPreferences.setMockInitialValues({});
      // Mock Firebase
      TestHelpers.setupFirebaseMocks();
    });

    setUp(() async {
      provider = RoutineProvider();
      testRoutine = TestHelpers.createTestRoutine(name: 'Test Routine');
      testStep = Step(
        title: 'Test Step',
        type: StepType.basic,
        description: 'Test description',
      );
      
      // Clear any existing data
      await RoutineService.clearAll();
    });

    group('Initial State', () {
      test('should have correct initial state', () {
        expect(provider.routines, isEmpty);
        expect(provider.isLoading, isFalse);
        expect(provider.error, isNull);
      });

      test('should return immutable list of routines', () {
        expect(() => provider.routines.add(testRoutine), throwsUnsupportedError);
      });
    });

    group('Loading Routines', () {
      test('should load routines successfully', () async {
        // Pre-populate with test data
        await RoutineService.createRoutine(name: 'Pre-existing Routine');
        
        var loadingStates = <bool>[];
        provider.addListener(() {
          loadingStates.add(provider.isLoading);
        });
        
        await provider.loadRoutines();
        
        expect(provider.routines, hasLength(1));
        expect(provider.routines[0].name, equals('Pre-existing Routine'));
        expect(provider.isLoading, isFalse);
        expect(provider.error, isNull);
        
        // Check that loading state was set and unset
        expect(loadingStates, contains(true));
        expect(loadingStates.last, isFalse);
      });

      test('should handle loading errors gracefully', () async {
        // This test would need to mock an error scenario
        // For now, we verify that error handling structure is in place
        await provider.loadRoutines();
        
        expect(provider.isLoading, isFalse);
        expect(provider.error, isNull); // No error since there's no actual error
      });

      test('should notify listeners during loading', () async {
        var notificationCount = 0;
        provider.addListener(() {
          notificationCount++;
        });
        
        await provider.loadRoutines();
        
        expect(notificationCount, greaterThan(0));
      });
    });

    group('Creating Routines', () {
      test('should create routine with basic parameters', () async {
        await provider.createRoutine(
          name: 'New Routine',
          description: 'Test description',
          category: 'Test Category',
        );
        
        expect(provider.routines, hasLength(1));
        expect(provider.routines[0].name, equals('New Routine'));
        expect(provider.routines[0].description, equals('Test description'));
        expect(provider.routines[0].category, equals('Test Category'));
        expect(provider.error, isNull);
      });

      test('should create routine with advanced parameters', () async {
        await provider.createRoutine(
          name: 'Advanced Routine',
          description: 'Advanced description',
          category: 'Advanced Category',
          voiceEnabled: true,
          musicEnabled: true,
          musicTrack: 'test-track',
          isBuiltInTrack: false,
        );
        
        expect(provider.routines, hasLength(1));
        final routine = provider.routines[0];
        expect(routine.name, equals('Advanced Routine'));
        expect(routine.voiceEnabled, isTrue);
        expect(routine.musicEnabled, isTrue);
        expect(routine.musicTrack, equals('test-track'));
        expect(routine.isBuiltInTrack, isFalse);
      });

      test('should notify listeners after creating routine', () async {
        var notificationCount = 0;
        provider.addListener(() {
          notificationCount++;
        });
        
        await provider.createRoutine(name: 'Test Routine');
        
        expect(notificationCount, greaterThan(0));
      });
    });

    group('Updating Routines', () {
      test('should update routine successfully', () async {
        await provider.createRoutine(name: 'Original Name');
        
        final routine = provider.routines[0];
        final updatedRoutine = routine.copyWith(name: 'Updated Name');
        
        await provider.updateRoutine(updatedRoutine);
        
        expect(provider.routines[0].name, equals('Updated Name'));
        expect(provider.error, isNull);
      });

      test('should notify listeners after updating routine', () async {
        await provider.createRoutine(name: 'Test Routine');
        
        var notificationCount = 0;
        provider.addListener(() {
          notificationCount++;
        });
        
        final routine = provider.routines[0];
        await provider.updateRoutine(routine.copyWith(name: 'Updated'));
        
        expect(notificationCount, greaterThan(0));
      });
    });

    group('Deleting Routines', () {
      test('should delete routine successfully', () async {
        await provider.createRoutine(name: 'To Delete');
        expect(provider.routines, hasLength(1));
        
        final routineId = provider.routines[0].id;
        await provider.deleteRoutine(routineId);
        
        expect(provider.routines, isEmpty);
        expect(provider.error, isNull);
      });

      test('should notify listeners after deleting routine', () async {
        await provider.createRoutine(name: 'Test Routine');
        
        var notificationCount = 0;
        provider.addListener(() {
          notificationCount++;
        });
        
        final routineId = provider.routines[0].id;
        await provider.deleteRoutine(routineId);
        
        expect(notificationCount, greaterThan(0));
      });
    });

    group('Importing Routines', () {
      test('should import routine successfully', () async {
        await provider.importRoutine(testRoutine);
        
        expect(provider.routines, hasLength(1));
        expect(provider.routines[0].name, equals(testRoutine.name));
        expect(provider.error, isNull);
      });

      test('should notify listeners after importing routine', () async {
        var notificationCount = 0;
        provider.addListener(() {
          notificationCount++;
        });
        
        await provider.importRoutine(testRoutine);
        
        expect(notificationCount, greaterThan(0));
      });
    });

    group('Step Management', () {
      test('should add step to routine', () async {
        await provider.createRoutine(name: 'Test Routine');
        final routineId = provider.routines[0].id;
        
        await provider.addStepToRoutine(routineId, testStep);
        
        expect(provider.routines[0].steps, hasLength(1));
        expect(provider.routines[0].steps[0].title, equals(testStep.title));
      });

      test('should remove step from routine', () async {
        await provider.createRoutine(name: 'Test Routine');
        final routineId = provider.routines[0].id;
        
        await provider.addStepToRoutine(routineId, testStep);
        expect(provider.routines[0].steps, hasLength(1));
        
        final stepId = provider.routines[0].steps[0].id;
        await provider.removeStepFromRoutine(routineId, stepId);
        
        expect(provider.routines[0].steps, isEmpty);
      });

      test('should update step in routine', () async {
        await provider.createRoutine(name: 'Test Routine');
        final routineId = provider.routines[0].id;
        
        await provider.addStepToRoutine(routineId, testStep);
        
        final updatedStep = provider.routines[0].steps[0].copyWith(title: 'Updated Step');
        await provider.updateStepInRoutine(routineId, updatedStep);
        
        expect(provider.routines[0].steps[0].title, equals('Updated Step'));
      });

      test('should reorder steps in routine', () async {
        await provider.createRoutine(name: 'Test Routine');
        final routineId = provider.routines[0].id;
        
        final step1 = Step(title: 'Step 1', type: StepType.basic);
        final step2 = Step(title: 'Step 2', type: StepType.basic);
        
        await provider.addStepToRoutine(routineId, step1);
        await provider.addStepToRoutine(routineId, step2);
        
        expect(provider.routines[0].steps[0].title, equals('Step 1'));
        expect(provider.routines[0].steps[1].title, equals('Step 2'));
        
        await provider.reorderStepsInRoutine(routineId, 0, 1);
        
        expect(provider.routines[0].steps[0].title, equals('Step 2'));
        expect(provider.routines[0].steps[1].title, equals('Step 1'));
      });

      test('should handle non-existent routine gracefully', () async {
        await provider.addStepToRoutine('non-existent-id', testStep);
        
        // Should not throw an error
        expect(provider.routines, isEmpty);
      });
    });

    group('Routine Retrieval', () {
      test('should get routine by ID', () async {
        await provider.createRoutine(name: 'Test Routine');
        final routineId = provider.routines[0].id;
        
        final retrievedRoutine = provider.getRoutineById(routineId);
        
        expect(retrievedRoutine, isNotNull);
        expect(retrievedRoutine!.name, equals('Test Routine'));
      });

      test('should return null for non-existent routine ID', () {
        final retrievedRoutine = provider.getRoutineById('non-existent-id');
        expect(retrievedRoutine, isNull);
      });

      test('should get routines by category', () async {
        await provider.createRoutine(name: 'Routine 1', category: 'Category A');
        await provider.createRoutine(name: 'Routine 2', category: 'Category B');
        await provider.createRoutine(name: 'Routine 3', category: 'Category A');
        
        final categoryARoutines = provider.getRoutinesByCategory('Category A');
        final categoryBRoutines = provider.getRoutinesByCategory('Category B');
        
        expect(categoryARoutines, hasLength(2));
        expect(categoryBRoutines, hasLength(1));
        expect(categoryARoutines[0].name, equals('Routine 1'));
        expect(categoryARoutines[1].name, equals('Routine 3'));
        expect(categoryBRoutines[0].name, equals('Routine 2'));
      });

      test('should return empty list for non-existent category', () {
        final routines = provider.getRoutinesByCategory('Non-existent Category');
        expect(routines, isEmpty);
      });
    });

    group('Error Handling', () {
      test('should clear error', () async {
        // Set an error state (this would normally happen from a failed operation)
        provider.clearError();
        
        expect(provider.error, isNull);
      });

      test('should notify listeners when clearing error', () async {
        var notificationCount = 0;
        provider.addListener(() {
          notificationCount++;
        });
        
        provider.clearError();
        
        expect(notificationCount, equals(1));
      });
    });

    group('Categories', () {
      test('should return categories from service', () async {
        await provider.createRoutine(name: 'Test', category: 'Test Category');
        
        final categories = provider.categories;
        expect(categories, isA<List<String>>());
      });
    });

    group('Listener Notifications', () {
      test('should notify listeners on state changes', () async {
        var notificationCount = 0;
        provider.addListener(() {
          notificationCount++;
        });
        
        await provider.createRoutine(name: 'Test');
        await provider.loadRoutines();
        provider.clearError();
        
        expect(notificationCount, greaterThan(2));
      });

      test('should stop notifications when listener is removed', () async {
        var notificationCount = 0;
        void listener() {
          notificationCount++;
        }
        
        provider.addListener(listener);
        await provider.createRoutine(name: 'Test 1');
        
        provider.removeListener(listener);
        await provider.createRoutine(name: 'Test 2');
        
        expect(notificationCount, equals(1)); // Only first creation should trigger
      });
    });

    group('State Consistency', () {
      test('should maintain consistent state across operations', () async {
        await provider.createRoutine(name: 'Routine 1');
        await provider.createRoutine(name: 'Routine 2');
        
        expect(provider.routines, hasLength(2));
        expect(provider.isLoading, isFalse);
        expect(provider.error, isNull);
        
        await provider.deleteRoutine(provider.routines[0].id);
        
        expect(provider.routines, hasLength(1));
        expect(provider.routines[0].name, equals('Routine 2'));
        expect(provider.error, isNull);
      });
    });
  });
}