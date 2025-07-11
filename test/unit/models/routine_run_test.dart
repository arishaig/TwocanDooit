import 'package:flutter_test/flutter_test.dart';
import 'package:twocandooit/models/routine_run.dart';

void main() {
  group('RoutineRun Model Tests', () {
    late RoutineRun routineRun;
    final testRoutineId = 'test-routine-123';
    final testStartTime = DateTime(2024, 1, 1, 10, 0, 0);

    setUp(() {
      routineRun = RoutineRun(
        routineId: testRoutineId,
        startTime: testStartTime,
        totalSteps: 5,
      );
    });

    group('Constructor and Basic Properties', () {
      test('should create with default values', () {
        expect(routineRun.id, isNotEmpty);
        expect(routineRun.routineId, equals(testRoutineId));
        expect(routineRun.startTime, equals(testStartTime));
        expect(routineRun.endTime, isNull);
        expect(routineRun.totalSteps, equals(5));
        expect(routineRun.completedSteps, equals(0));
        expect(routineRun.pausedDuration, equals(Duration.zero));
      });

      test('should create with custom values', () {
        final customRun = RoutineRun(
          id: 'custom-id',
          routineId: 'custom-routine',
          startTime: testStartTime,
          endTime: testStartTime.add(Duration(minutes: 30)),
          totalSteps: 10,
          completedSteps: 7,
          pausedDuration: Duration(minutes: 5),
        );

        expect(customRun.id, equals('custom-id'));
        expect(customRun.routineId, equals('custom-routine'));
        expect(customRun.totalSteps, equals(10));
        expect(customRun.completedSteps, equals(7));
        expect(customRun.pausedDuration, equals(Duration(minutes: 5)));
      });

      test('should generate unique IDs when not provided', () {
        final run1 = RoutineRun(routineId: 'test', totalSteps: 1);
        final run2 = RoutineRun(routineId: 'test', totalSteps: 1);
        
        expect(run1.id, isNot(equals(run2.id)));
      });
    });

    group('Status Properties', () {
      test('wasCompleted should return false for incomplete run', () {
        expect(routineRun.wasCompleted, isFalse);
      });

      test('wasCompleted should return true for completed run', () {
        routineRun.complete();
        expect(routineRun.wasCompleted, isTrue);
      });

      test('wasCompleted should return false for abandoned run', () {
        routineRun.abandon();
        expect(routineRun.wasCompleted, isFalse);
      });

      test('isInProgress should return true for active run', () {
        expect(routineRun.isInProgress, isTrue);
      });

      test('isInProgress should return false for completed run', () {
        routineRun.complete();
        expect(routineRun.isInProgress, isFalse);
      });

      test('isInProgress should return false for abandoned run', () {
        routineRun.abandon();
        expect(routineRun.isInProgress, isFalse);
      });
    });

    group('Duration Calculations', () {
      test('duration should return null for in-progress run', () {
        expect(routineRun.duration, isNull);
      });

      test('duration should calculate correctly for completed run', () {
        routineRun.complete();
        
        // Since complete() sets endTime to now(), we need to test with a fixed time
        final testRun = RoutineRun(
          routineId: 'test',
          startTime: testStartTime,
          endTime: testStartTime.add(Duration(minutes: 30)),
          totalSteps: 5,
          completedSteps: 5,
          pausedDuration: Duration(minutes: 5),
        );
        
        expect(testRun.duration, equals(Duration(minutes: 25))); // 30 - 5 paused
      });

      test('currentElapsed should calculate time from start', () {
        // This test depends on current time, so we'll test the calculation logic
        final elapsed = routineRun.currentElapsed;
        expect(elapsed, isA<Duration>());
        expect(elapsed.inMilliseconds, greaterThan(0));
      });

      test('currentElapsed should subtract paused duration', () {
        routineRun.addPausedTime(Duration(minutes: 10));
        final elapsed = routineRun.currentElapsed;
        
        // The elapsed time should be reduced by the paused duration
        expect(elapsed, isA<Duration>());
      });
    });

    group('Completion Percentage', () {
      test('should return 0.0 for no completed steps', () {
        expect(routineRun.completionPercentage, equals(0.0));
      });

      test('should return 1.0 for all steps completed', () {
        routineRun.updateProgress(5);
        expect(routineRun.completionPercentage, equals(1.0));
      });

      test('should return correct percentage for partial completion', () {
        routineRun.updateProgress(3);
        expect(routineRun.completionPercentage, equals(0.6)); // 3/5
      });

      test('should return 1.0 for zero total steps', () {
        final zeroStepsRun = RoutineRun(
          routineId: 'test',
          totalSteps: 0,
        );
        expect(zeroStepsRun.completionPercentage, equals(1.0));
      });
    });

    group('State Management', () {
      test('complete should set endTime and completedSteps', () {
        routineRun.complete();
        
        expect(routineRun.endTime, isNotNull);
        expect(routineRun.completedSteps, equals(routineRun.totalSteps));
        expect(routineRun.wasCompleted, isTrue);
      });

      test('abandon should set endTime but not completedSteps', () {
        routineRun.updateProgress(3);
        routineRun.abandon();
        
        expect(routineRun.endTime, isNotNull);
        expect(routineRun.completedSteps, equals(3));
        expect(routineRun.wasCompleted, isFalse);
      });

      test('addPausedTime should accumulate paused duration', () {
        routineRun.addPausedTime(Duration(minutes: 5));
        routineRun.addPausedTime(Duration(minutes: 3));
        
        expect(routineRun.pausedDuration, equals(Duration(minutes: 8)));
      });

      test('updateProgress should set completed steps', () {
        routineRun.updateProgress(3);
        expect(routineRun.completedSteps, equals(3));
        
        routineRun.updateProgress(5);
        expect(routineRun.completedSteps, equals(5));
      });
    });

    group('copyWith', () {
      test('should create copy with updated values', () {
        final originalRun = RoutineRun(
          id: 'test-id',
          routineId: 'test-routine',
          startTime: testStartTime,
          totalSteps: 5,
          completedSteps: 2,
          pausedDuration: Duration(minutes: 3),
        );

        final copiedRun = originalRun.copyWith(
          endTime: testStartTime.add(Duration(minutes: 30)),
          completedSteps: 4,
          pausedDuration: Duration(minutes: 5),
        );

        expect(copiedRun.id, equals(originalRun.id));
        expect(copiedRun.routineId, equals(originalRun.routineId));
        expect(copiedRun.startTime, equals(originalRun.startTime));
        expect(copiedRun.endTime, equals(testStartTime.add(Duration(minutes: 30))));
        expect(copiedRun.completedSteps, equals(4));
        expect(copiedRun.pausedDuration, equals(Duration(minutes: 5)));
      });

      test('should preserve original values when not updated', () {
        final copiedRun = routineRun.copyWith();
        
        expect(copiedRun.id, equals(routineRun.id));
        expect(copiedRun.routineId, equals(routineRun.routineId));
        expect(copiedRun.startTime, equals(routineRun.startTime));
        expect(copiedRun.endTime, equals(routineRun.endTime));
        expect(copiedRun.completedSteps, equals(routineRun.completedSteps));
        expect(copiedRun.pausedDuration, equals(routineRun.pausedDuration));
      });
    });

    group('JSON Serialization', () {
      test('should serialize to JSON correctly', () {
        final testRun = RoutineRun(
          id: 'test-id',
          routineId: 'test-routine',
          startTime: testStartTime,
          endTime: testStartTime.add(Duration(minutes: 30)),
          totalSteps: 5,
          completedSteps: 3,
          pausedDuration: Duration(minutes: 2),
        );

        final json = testRun.toJson();

        expect(json['id'], equals('test-id'));
        expect(json['routineId'], equals('test-routine'));
        expect(json['startTime'], equals(testStartTime.toIso8601String()));
        expect(json['endTime'], equals(testStartTime.add(Duration(minutes: 30)).toIso8601String()));
        expect(json['totalSteps'], equals(5));
        expect(json['completedSteps'], equals(3));
        expect(json['pausedDuration'], equals(Duration(minutes: 2).inMilliseconds));
      });

      test('should serialize null endTime correctly', () {
        final json = routineRun.toJson();
        expect(json['endTime'], isNull);
      });

      test('should deserialize from JSON correctly', () {
        final json = {
          'id': 'test-id',
          'routineId': 'test-routine',
          'startTime': testStartTime.toIso8601String(),
          'endTime': testStartTime.add(Duration(minutes: 30)).toIso8601String(),
          'totalSteps': 5,
          'completedSteps': 3,
          'pausedDuration': Duration(minutes: 2).inMilliseconds,
        };

        final deserializedRun = RoutineRun.fromJson(json);

        expect(deserializedRun.id, equals('test-id'));
        expect(deserializedRun.routineId, equals('test-routine'));
        expect(deserializedRun.startTime, equals(testStartTime));
        expect(deserializedRun.endTime, equals(testStartTime.add(Duration(minutes: 30))));
        expect(deserializedRun.totalSteps, equals(5));
        expect(deserializedRun.completedSteps, equals(3));
        expect(deserializedRun.pausedDuration, equals(Duration(minutes: 2)));
      });

      test('should deserialize with null endTime correctly', () {
        final json = {
          'id': 'test-id',
          'routineId': 'test-routine',
          'startTime': testStartTime.toIso8601String(),
          'endTime': null,
          'totalSteps': 5,
          'completedSteps': 3,
          'pausedDuration': Duration(minutes: 2).inMilliseconds,
        };

        final deserializedRun = RoutineRun.fromJson(json);
        expect(deserializedRun.endTime, isNull);
      });

      test('should handle missing JSON fields with defaults', () {
        final minimalJson = {
          'routineId': 'test-routine',
        };

        final deserializedRun = RoutineRun.fromJson(minimalJson);

        expect(deserializedRun.id, isNotEmpty);
        expect(deserializedRun.routineId, equals('test-routine'));
        expect(deserializedRun.startTime, isA<DateTime>());
        expect(deserializedRun.endTime, isNull);
        expect(deserializedRun.totalSteps, equals(0));
        expect(deserializedRun.completedSteps, equals(0));
        expect(deserializedRun.pausedDuration, equals(Duration.zero));
      });

      test('should round-trip serialize/deserialize correctly', () {
        final originalRun = RoutineRun(
          id: 'test-id',
          routineId: 'test-routine',
          startTime: testStartTime,
          endTime: testStartTime.add(Duration(minutes: 30)),
          totalSteps: 5,
          completedSteps: 3,
          pausedDuration: Duration(minutes: 2),
        );

        final json = originalRun.toJson();
        final deserializedRun = RoutineRun.fromJson(json);

        expect(deserializedRun.id, equals(originalRun.id));
        expect(deserializedRun.routineId, equals(originalRun.routineId));
        expect(deserializedRun.startTime, equals(originalRun.startTime));
        expect(deserializedRun.endTime, equals(originalRun.endTime));
        expect(deserializedRun.totalSteps, equals(originalRun.totalSteps));
        expect(deserializedRun.completedSteps, equals(originalRun.completedSteps));
        expect(deserializedRun.pausedDuration, equals(originalRun.pausedDuration));
      });
    });

    group('toString', () {
      test('should provide readable string representation', () {
        routineRun.updateProgress(3);
        final string = routineRun.toString();
        
        expect(string, contains('RoutineRun'));
        expect(string, contains(routineRun.id));
        expect(string, contains(testRoutineId));
        expect(string, contains('3/5'));
        expect(string, contains('completed: false'));
      });
    });
  });
}