import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:twocandooit/services/storage_service.dart';
import 'package:twocandooit/models/routine.dart';
import 'package:twocandooit/models/routine_run.dart';
import 'package:twocandooit/models/step.dart';
import 'package:twocandooit/models/step_type.dart';
import '../../test_helpers.dart';

void main() {
  setUpAll(() {
    TestHelpers.setupAllPluginMocks();
  });

  group('StorageService Tests', () {
    late List<Routine> testRoutines;
    late Map<String, dynamic> testSettings;
    late RoutineRun testRun;

    setUpAll(() async {
      // Mock SharedPreferences
      SharedPreferences.setMockInitialValues({});
    });

    setUp(() async {
      // Clear all stored data before each test
      await StorageService.clearAll();
      
      // Create test data
      testRoutines = [
        TestHelpers.createTestRoutine(name: 'Test Routine 1'),
        TestHelpers.createTestRoutine(name: 'Test Routine 2'),
      ];
      
      testSettings = {
        'soundEnabled': true,
        'voiceEnabled': false,
        'nudgeEnabled': true,
        'nudgeInterval': 30,
      };
      
      testRun = RoutineRun(
        routineId: testRoutines[0].id,
        totalSteps: 5,
        completedSteps: 3,
        startTime: DateTime(2024, 1, 1, 10, 0, 0),
        endTime: DateTime(2024, 1, 1, 10, 30, 0),
        pausedDuration: Duration(minutes: 5),
      );
    });

    group('Initialization', () {
      test('should initialize without errors', () async {
        expect(() => StorageService.init(), returnsNormally);
      });
    });

    group('Routine Persistence', () {
      test('should save and load routines correctly', () async {
        final saveResult = await StorageService.saveRoutines(testRoutines);
        expect(saveResult, isTrue);
        
        final loadedRoutines = await StorageService.loadRoutines();
        expect(loadedRoutines, hasLength(testRoutines.length));
        expect(loadedRoutines[0].name, equals(testRoutines[0].name));
        expect(loadedRoutines[1].name, equals(testRoutines[1].name));
      });

      test('should return empty list when no routines stored', () async {
        final loadedRoutines = await StorageService.loadRoutines();
        expect(loadedRoutines, isEmpty);
      });

      test('should handle corrupted routine data gracefully', () async {
        // Mock corrupted data
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('routines', 'invalid json');
        
        final loadedRoutines = await StorageService.loadRoutines();
        expect(loadedRoutines, isEmpty);
      });

      test('should preserve routine structure when saving/loading', () async {
        final routine = TestHelpers.createTestRoutine(name: 'Complex Routine');
        routine.addStep(Step(
          title: 'Timer Step',
          type: StepType.timer,
          timerDuration: 120,
          description: 'Test description',
        ));
        
        await StorageService.saveRoutines([routine]);
        final loadedRoutines = await StorageService.loadRoutines();
        
        expect(loadedRoutines, hasLength(1));
        final loadedRoutine = loadedRoutines[0];
        expect(loadedRoutine.name, equals(routine.name));
        expect(loadedRoutine.steps, hasLength(routine.steps.length));
        expect(loadedRoutine.steps.last.title, equals('Timer Step'));
        expect(loadedRoutine.steps.last.type, equals(StepType.timer));
        expect(loadedRoutine.steps.last.timerDuration, equals(120));
      });
    });

    group('Settings Persistence', () {
      test('should save and load settings correctly', () async {
        final saveResult = await StorageService.saveSettings(testSettings);
        expect(saveResult, isTrue);
        
        final loadedSettings = await StorageService.loadSettings();
        expect(loadedSettings['soundEnabled'], isTrue);
        expect(loadedSettings['voiceEnabled'], isFalse);
        expect(loadedSettings['nudgeEnabled'], isTrue);
        expect(loadedSettings['nudgeInterval'], equals(30));
      });

      test('should return empty map when no settings stored', () async {
        final loadedSettings = await StorageService.loadSettings();
        expect(loadedSettings, isEmpty);
      });

      test('should handle corrupted settings data gracefully', () async {
        // Mock corrupted data
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('settings', 'invalid json');
        
        final loadedSettings = await StorageService.loadSettings();
        expect(loadedSettings, isEmpty);
      });

      test('should preserve settings types when saving/loading', () async {
        final complexSettings = {
          'stringValue': 'test',
          'intValue': 42,
          'doubleValue': 3.14,
          'boolValue': true,
          'listValue': ['a', 'b', 'c'],
          'mapValue': {'nested': 'value'},
        };
        
        await StorageService.saveSettings(complexSettings);
        final loadedSettings = await StorageService.loadSettings();
        
        expect(loadedSettings['stringValue'], equals('test'));
        expect(loadedSettings['intValue'], equals(42));
        expect(loadedSettings['doubleValue'], equals(3.14));
        expect(loadedSettings['boolValue'], isTrue);
        expect(loadedSettings['listValue'], equals(['a', 'b', 'c']));
        expect(loadedSettings['mapValue'], equals({'nested': 'value'}));
      });
    });

    group('Routine Run Tracking', () {
      test('should save and load routine runs correctly', () async {
        final saveResult = await StorageService.saveRoutineRun(testRun);
        expect(saveResult, isTrue);
        
        final loadedRuns = await StorageService.loadRoutineRuns(testRun.routineId);
        expect(loadedRuns, hasLength(1));
        expect(loadedRuns[0].id, equals(testRun.id));
        expect(loadedRuns[0].routineId, equals(testRun.routineId));
        expect(loadedRuns[0].completedSteps, equals(testRun.completedSteps));
      });

      test('should update existing run when saving with same ID', () async {
        await StorageService.saveRoutineRun(testRun);
        
        // Update the run
        final updatedRun = testRun.copyWith(completedSteps: 5);
        await StorageService.saveRoutineRun(updatedRun);
        
        final loadedRuns = await StorageService.loadRoutineRuns(testRun.routineId);
        expect(loadedRuns, hasLength(1));
        expect(loadedRuns[0].completedSteps, equals(5));
      });

      test('should store multiple runs for same routine', () async {
        final run1 = testRun;
        final run2 = RoutineRun(
          routineId: testRun.routineId,
          totalSteps: 3,
          completedSteps: 2,
          startTime: DateTime(2024, 1, 2, 10, 0, 0),
        );
        
        await StorageService.saveRoutineRun(run1);
        await StorageService.saveRoutineRun(run2);
        
        final loadedRuns = await StorageService.loadRoutineRuns(testRun.routineId);
        expect(loadedRuns, hasLength(2));
      });

      test('should sort runs by start time (newest first)', () async {
        final oldRun = RoutineRun(
          routineId: testRun.routineId,
          totalSteps: 3,
          startTime: DateTime(2024, 1, 1, 9, 0, 0),
        );
        final newRun = RoutineRun(
          routineId: testRun.routineId,
          totalSteps: 3,
          startTime: DateTime(2024, 1, 1, 11, 0, 0),
        );
        
        await StorageService.saveRoutineRun(oldRun);
        await StorageService.saveRoutineRun(newRun);
        
        final loadedRuns = await StorageService.loadRoutineRuns(testRun.routineId);
        expect(loadedRuns[0].startTime, equals(newRun.startTime));
        expect(loadedRuns[1].startTime, equals(oldRun.startTime));
      });

      test('should return empty list when no runs exist', () async {
        final loadedRuns = await StorageService.loadRoutineRuns('nonexistent-id');
        expect(loadedRuns, isEmpty);
      });

      test('should handle corrupted run data gracefully', () async {
        // Mock corrupted data
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('routine_runs_test-id', 'invalid json');
        
        final loadedRuns = await StorageService.loadRoutineRuns('test-id');
        expect(loadedRuns, isEmpty);
      });
    });

    group('All Routine Runs', () {
      test('should load all runs across all routines', () async {
        final run1 = RoutineRun(
          routineId: 'routine-1',
          totalSteps: 3,
          startTime: DateTime(2024, 1, 1, 10, 0, 0),
        );
        final run2 = RoutineRun(
          routineId: 'routine-2',
          totalSteps: 5,
          startTime: DateTime(2024, 1, 1, 11, 0, 0),
        );
        
        await StorageService.saveRoutineRun(run1);
        await StorageService.saveRoutineRun(run2);
        
        final allRuns = await StorageService.loadAllRoutineRuns();
        expect(allRuns, hasLength(2));
        expect(allRuns.any((r) => r.routineId == 'routine-1'), isTrue);
        expect(allRuns.any((r) => r.routineId == 'routine-2'), isTrue);
      });

      test('should sort all runs by start time (newest first)', () async {
        final oldRun = RoutineRun(
          routineId: 'routine-1',
          totalSteps: 3,
          startTime: DateTime(2024, 1, 1, 9, 0, 0),
        );
        final newRun = RoutineRun(
          routineId: 'routine-2',
          totalSteps: 3,
          startTime: DateTime(2024, 1, 1, 11, 0, 0),
        );
        
        await StorageService.saveRoutineRun(oldRun);
        await StorageService.saveRoutineRun(newRun);
        
        final allRuns = await StorageService.loadAllRoutineRuns();
        expect(allRuns[0].startTime, equals(newRun.startTime));
        expect(allRuns[1].startTime, equals(oldRun.startTime));
      });

      test('should return empty list when no runs exist', () async {
        final allRuns = await StorageService.loadAllRoutineRuns();
        expect(allRuns, isEmpty);
      });
    });

    group('Routine Run Management', () {
      test('should delete all runs for a routine', () async {
        await StorageService.saveRoutineRun(testRun);
        
        final result = await StorageService.deleteRoutineRuns(testRun.routineId);
        expect(result, isTrue);
        
        final loadedRuns = await StorageService.loadRoutineRuns(testRun.routineId);
        expect(loadedRuns, isEmpty);
      });

      test('should clear run data for a routine', () async {
        await StorageService.saveRoutineRun(testRun);
        
        final result = await StorageService.clearRoutineRunData(testRun.routineId);
        expect(result, isTrue);
        
        final loadedRuns = await StorageService.loadRoutineRuns(testRun.routineId);
        expect(loadedRuns, isEmpty);
      });
    });

    group('Routine Statistics', () {
      test('should get last completed run', () async {
        final completedRun = RoutineRun(
          routineId: testRun.routineId,
          totalSteps: 5,
          completedSteps: 5,
          startTime: DateTime(2024, 1, 1, 10, 0, 0),
          endTime: DateTime(2024, 1, 1, 10, 30, 0),
        );
        final incompleteRun = RoutineRun(
          routineId: testRun.routineId,
          totalSteps: 5,
          completedSteps: 3,
          startTime: DateTime(2024, 1, 1, 11, 0, 0),
        );
        
        await StorageService.saveRoutineRun(completedRun);
        await StorageService.saveRoutineRun(incompleteRun);
        
        final lastCompleted = await StorageService.getLastCompletedRun(testRun.routineId);
        expect(lastCompleted, isNotNull);
        expect(lastCompleted!.wasCompleted, isTrue);
        expect(lastCompleted.id, equals(completedRun.id));
      });

      test('should return null when no completed runs exist', () async {
        final incompleteRun = RoutineRun(
          routineId: testRun.routineId,
          totalSteps: 5,
          completedSteps: 3,
          startTime: DateTime(2024, 1, 1, 11, 0, 0),
        );
        
        await StorageService.saveRoutineRun(incompleteRun);
        
        final lastCompleted = await StorageService.getLastCompletedRun(testRun.routineId);
        expect(lastCompleted, isNull);
      });

      test('should calculate routine statistics correctly', () async {
        final completedRun1 = RoutineRun(
          routineId: testRun.routineId,
          totalSteps: 5,
          completedSteps: 5,
          startTime: DateTime(2024, 1, 1, 10, 0, 0),
          endTime: DateTime(2024, 1, 1, 10, 30, 0),
        );
        final completedRun2 = RoutineRun(
          routineId: testRun.routineId,
          totalSteps: 5,
          completedSteps: 5,
          startTime: DateTime(2024, 1, 1, 11, 0, 0),
          endTime: DateTime(2024, 1, 1, 11, 20, 0),
        );
        final incompleteRun = RoutineRun(
          routineId: testRun.routineId,
          totalSteps: 5,
          completedSteps: 3,
          startTime: DateTime(2024, 1, 1, 12, 0, 0),
        );
        
        await StorageService.saveRoutineRun(completedRun1);
        await StorageService.saveRoutineRun(completedRun2);
        await StorageService.saveRoutineRun(incompleteRun);
        
        final stats = await StorageService.getRoutineStats(testRun.routineId);
        
        expect(stats['timesRun'], equals(2));
        expect(stats['completionRate'], equals(2.0 / 3.0));
        expect(stats['averageDuration'], isA<Duration>());
        expect(stats['lastRunAt'], isNotNull);
      });

      test('should return empty stats when no runs exist', () async {
        final stats = await StorageService.getRoutineStats('nonexistent-id');
        
        expect(stats['timesRun'], equals(0));
        expect(stats['completionRate'], equals(0.0));
        expect(stats['averageDuration'], isNull);
        expect(stats['lastRunAt'], isNull);
      });

      test('should handle zero completed runs in statistics', () async {
        final incompleteRun = RoutineRun(
          routineId: testRun.routineId,
          totalSteps: 5,
          completedSteps: 3,
          startTime: DateTime(2024, 1, 1, 12, 0, 0),
        );
        
        await StorageService.saveRoutineRun(incompleteRun);
        
        final stats = await StorageService.getRoutineStats(testRun.routineId);
        
        expect(stats['timesRun'], equals(0));
        expect(stats['completionRate'], equals(0.0));
        expect(stats['averageDuration'], isNull);
        expect(stats['lastRunAt'], isNull);
      });
    });

    group('Data Clearing', () {
      test('should clear all data', () async {
        await StorageService.saveRoutines(testRoutines);
        await StorageService.saveSettings(testSettings);
        await StorageService.saveRoutineRun(testRun);
        
        final result = await StorageService.clearAll();
        expect(result, isTrue);
        
        final loadedRoutines = await StorageService.loadRoutines();
        final loadedSettings = await StorageService.loadSettings();
        final loadedRuns = await StorageService.loadRoutineRuns(testRun.routineId);
        
        expect(loadedRoutines, isEmpty);
        expect(loadedSettings, isEmpty);
        expect(loadedRuns, isEmpty);
      });
    });

    group('Error Handling', () {
      test('should handle save failures gracefully', () async {
        // This test would need to mock SharedPreferences to return false
        // For now, we just verify the method doesn't throw
        final result = await StorageService.saveRoutines(testRoutines);
        expect(result, isA<bool>());
      });

      test('should handle load failures gracefully', () async {
        // These methods should not throw exceptions
        final routines = await StorageService.loadRoutines();
        final settings = await StorageService.loadSettings();
        final runs = await StorageService.loadRoutineRuns('test-id');
        
        expect(routines, isA<List<Routine>>());
        expect(settings, isA<Map<String, dynamic>>());
        expect(runs, isA<List<RoutineRun>>());
      });
    });
  });
}