import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../../../lib/models/routine_schedule.dart';

void main() {
  setUpAll(() {
    // Initialize timezone data for tests
    tz_data.initializeTimeZones();
    tz.setLocalLocation(tz.UTC);
  });

  group('RoutineSchedule Model Tests', () {
    test('creates daily schedule with correct properties', () {
      final schedule = RoutineSchedule.daily(
        id: 'test-1',
        routineId: 'routine-1',
        routineName: 'Morning Routine',
        hour: 8,
        minute: 0,
      );

      expect(schedule.type, ScheduleType.daily);
      expect(schedule.hour, 8);
      expect(schedule.minute, 0);
      expect(schedule.weekdays, {1, 2, 3, 4, 5, 6, 7});
      expect(schedule.isEnabled, true);
      expect(schedule.useRandomTime, false);
      expect(schedule.snoozeMinutes, 10);
      expect(schedule.maxSnoozeCount, 3);
      expect(schedule.currentSnoozeCount, 0);
      expect(schedule.isSnoozed, false);
      expect(schedule.canSnooze, true);
    });

    test('creates weekday schedule with correct properties', () {
      final schedule = RoutineSchedule.weekdays(
        id: 'test-2',
        routineId: 'routine-2',
        routineName: 'Work Routine',
        hour: 9,
        minute: 30,
      );

      expect(schedule.type, ScheduleType.weekdays);
      expect(schedule.weekdays, {1, 2, 3, 4, 5});
      expect(schedule.hour, 9);
      expect(schedule.minute, 30);
    });

    test('creates custom schedule with specific weekdays', () {
      final schedule = RoutineSchedule.custom(
        id: 'test-3',
        routineId: 'routine-3',
        routineName: 'Custom Routine',
        weekdays: {1, 3, 5}, // Monday, Wednesday, Friday
        hour: 18,
        minute: 15,
      );

      expect(schedule.type, ScheduleType.custom);
      expect(schedule.weekdays, {1, 3, 5});
      expect(schedule.hour, 18);
      expect(schedule.minute, 15);
    });

    test('creates random time schedule with correct properties', () {
      final schedule = RoutineSchedule.withRandomTime(
        id: 'test-4',
        routineId: 'routine-4',
        routineName: 'Random Time Routine',
        type: ScheduleType.daily,
        weekdays: {1, 2, 3, 4, 5, 6, 7},
        randomStartHour: 9,
        randomStartMinute: 0,
        randomEndHour: 11,
        randomEndMinute: 0,
      );

      expect(schedule.useRandomTime, true);
      expect(schedule.randomStartHour, 9);
      expect(schedule.randomStartMinute, 0);
      expect(schedule.randomEndHour, 11);
      expect(schedule.randomEndMinute, 0);
    });

    test('displays correct text for daily schedule', () {
      final schedule = RoutineSchedule.daily(
        id: 'test-5',
        routineId: 'routine-5',
        routineName: 'Test',
        hour: 8,
        minute: 0,
      );

      expect(schedule.displayText, 'Daily at 8:00 AM');
    });

    test('displays correct text for weekday schedule', () {
      final schedule = RoutineSchedule.weekdays(
        id: 'test-6',
        routineId: 'routine-6',
        routineName: 'Test',
        hour: 9,
        minute: 30,
      );

      expect(schedule.displayText, 'Weekdays at 9:30 AM');
    });

    test('displays correct text for custom schedule', () {
      final schedule = RoutineSchedule.custom(
        id: 'test-7',
        routineId: 'routine-7',
        routineName: 'Test',
        weekdays: {1, 3, 5},
        hour: 18,
        minute: 15,
      );

      expect(schedule.displayText, 'Monday, Wednesday, Friday at 6:15 PM');
    });

    test('displays correct text for random time schedule', () {
      final schedule = RoutineSchedule.withRandomTime(
        id: 'test-8',
        routineId: 'routine-8',
        routineName: 'Test',
        type: ScheduleType.daily,
        weekdays: {1, 2, 3, 4, 5, 6, 7},
        randomStartHour: 9,
        randomStartMinute: 0,
        randomEndHour: 11,
        randomEndMinute: 0,
      );

      expect(schedule.displayText, 'Daily between 9:00 AM and 11:00 AM');
    });

    test('displays correct short text for different schedule types', () {
      final dailySchedule = RoutineSchedule.daily(
        id: 'test-9a',
        routineId: 'routine-9a',
        routineName: 'Test',
        hour: 8,
        minute: 0,
      );

      final weekdaySchedule = RoutineSchedule.weekdays(
        id: 'test-9b',
        routineId: 'routine-9b',
        routineName: 'Test',
        hour: 9,
        minute: 0,
      );

      final customSchedule = RoutineSchedule.custom(
        id: 'test-9c',
        routineId: 'routine-9c',
        routineName: 'Test',
        weekdays: {1, 3, 5},
        hour: 10,
        minute: 0,
      );

      expect(dailySchedule.shortDisplayText, 'Daily');
      expect(weekdaySchedule.shortDisplayText, 'Weekdays');
      expect(customSchedule.shortDisplayText, 'M W F');
    });

    test('handles time formatting correctly', () {
      final morningSchedule = RoutineSchedule.daily(
        id: 'test-10a',
        routineId: 'routine-10a',
        routineName: 'Test',
        hour: 6,
        minute: 30,
      );

      final eveningSchedule = RoutineSchedule.daily(
        id: 'test-10b',
        routineId: 'routine-10b',
        routineName: 'Test',
        hour: 18,
        minute: 15,
      );

      final midnightSchedule = RoutineSchedule.daily(
        id: 'test-10c',
        routineId: 'routine-10c',
        routineName: 'Test',
        hour: 0,
        minute: 0,
      );

      final noonSchedule = RoutineSchedule.daily(
        id: 'test-10d',
        routineId: 'routine-10d',
        routineName: 'Test',
        hour: 12,
        minute: 0,
      );

      expect(morningSchedule.displayText, 'Daily at 6:30 AM');
      expect(eveningSchedule.displayText, 'Daily at 6:15 PM');
      expect(midnightSchedule.displayText, 'Daily at 12:00 AM');
      expect(noonSchedule.displayText, 'Daily at 12:00 PM');
    });

    test('handles snooze functionality correctly', () {
      final now = DateTime.now();
      final snoozeUntil = now.add(const Duration(minutes: 10));
      
      final schedule = RoutineSchedule.daily(
        id: 'test-11',
        routineId: 'routine-11',
        routineName: 'Test',
        hour: 8,
        minute: 0,
      );

      final snoozedSchedule = schedule.copyWith(
        snoozeUntil: snoozeUntil,
        currentSnoozeCount: 1,
      );

      expect(schedule.isSnoozed, false);
      expect(schedule.canSnooze, true);
      expect(snoozedSchedule.isSnoozed, true);
      expect(snoozedSchedule.currentSnoozeCount, 1);
      expect(snoozedSchedule.canSnooze, true);
    });

    test('handles snooze limit correctly', () {
      final schedule = RoutineSchedule.daily(
        id: 'test-12',
        routineId: 'routine-12',
        routineName: 'Test',
        hour: 8,
        minute: 0,
      );

      final maxSnoozedSchedule = schedule.copyWith(
        currentSnoozeCount: 3,
        maxSnoozeCount: 3,
      );

      expect(schedule.canSnooze, true);
      expect(maxSnoozedSchedule.canSnooze, false);
    });

    test('copyWith works correctly', () {
      final originalSchedule = RoutineSchedule.daily(
        id: 'test-13',
        routineId: 'routine-13',
        routineName: 'Original',
        hour: 8,
        minute: 0,
      );

      final updatedSchedule = originalSchedule.copyWith(
        routineName: 'Updated',
        hour: 9,
        minute: 30,
        isEnabled: false,
        currentSnoozeCount: 2,
      );

      expect(updatedSchedule.id, originalSchedule.id);
      expect(updatedSchedule.routineId, originalSchedule.routineId);
      expect(updatedSchedule.routineName, 'Updated');
      expect(updatedSchedule.hour, 9);
      expect(updatedSchedule.minute, 30);
      expect(updatedSchedule.isEnabled, false);
      expect(updatedSchedule.currentSnoozeCount, 2);
      expect(updatedSchedule.type, originalSchedule.type);
    });

    test('JSON serialization works correctly', () {
      final originalSchedule = RoutineSchedule.daily(
        id: 'test-14',
        routineId: 'routine-14',
        routineName: 'JSON Test',
        hour: 10,
        minute: 45,
      );

      final json = originalSchedule.toJson();
      final deserializedSchedule = RoutineSchedule.fromJson(json);

      expect(deserializedSchedule.id, originalSchedule.id);
      expect(deserializedSchedule.routineId, originalSchedule.routineId);
      expect(deserializedSchedule.routineName, originalSchedule.routineName);
      expect(deserializedSchedule.type, originalSchedule.type);
      expect(deserializedSchedule.weekdays, originalSchedule.weekdays);
      expect(deserializedSchedule.hour, originalSchedule.hour);
      expect(deserializedSchedule.minute, originalSchedule.minute);
      expect(deserializedSchedule.useRandomTime, originalSchedule.useRandomTime);
      expect(deserializedSchedule.isEnabled, originalSchedule.isEnabled);
      expect(deserializedSchedule.snoozeMinutes, originalSchedule.snoozeMinutes);
      expect(deserializedSchedule.maxSnoozeCount, originalSchedule.maxSnoozeCount);
    });

    test('JSON serialization handles random time schedules', () {
      final originalSchedule = RoutineSchedule.withRandomTime(
        id: 'test-15',
        routineId: 'routine-15',
        routineName: 'Random JSON Test',
        type: ScheduleType.custom,
        weekdays: {1, 3, 5},
        randomStartHour: 9,
        randomStartMinute: 0,
        randomEndHour: 11,
        randomEndMinute: 30,
      );

      final json = originalSchedule.toJson();
      final deserializedSchedule = RoutineSchedule.fromJson(json);

      expect(deserializedSchedule.useRandomTime, true);
      expect(deserializedSchedule.randomStartHour, 9);
      expect(deserializedSchedule.randomStartMinute, 0);
      expect(deserializedSchedule.randomEndHour, 11);
      expect(deserializedSchedule.randomEndMinute, 30);
      expect(deserializedSchedule.weekdays, {1, 3, 5});
    });

    test('JSON serialization handles nullable fields', () {
      final now = DateTime.now();
      final schedule = RoutineSchedule.daily(
        id: 'test-16',
        routineId: 'routine-16',
        routineName: 'Nullable Test',
        hour: 8,
        minute: 0,
      );

      final scheduleWithDates = schedule.copyWith(
        nextScheduledTime: now,
        lastTriggeredTime: now.subtract(const Duration(hours: 24)),
        snoozeUntil: now.add(const Duration(minutes: 10)),
      );

      final json = scheduleWithDates.toJson();
      final deserializedSchedule = RoutineSchedule.fromJson(json);

      expect(deserializedSchedule.nextScheduledTime?.millisecondsSinceEpoch,
          scheduleWithDates.nextScheduledTime?.millisecondsSinceEpoch);
      expect(deserializedSchedule.lastTriggeredTime?.millisecondsSinceEpoch,
          scheduleWithDates.lastTriggeredTime?.millisecondsSinceEpoch);
      expect(deserializedSchedule.snoozeUntil?.millisecondsSinceEpoch,
          scheduleWithDates.snoozeUntil?.millisecondsSinceEpoch);
    });

    test('JSON deserialization handles missing fields gracefully', () {
      final json = {
        'id': 'test-17',
        'routineId': 'routine-17',
        'routineName': 'Minimal Test',
        'type': 'daily',
        'weekdays': [1, 2, 3, 4, 5, 6, 7],
        'hour': 8,
        'minute': 0,
      };

      final schedule = RoutineSchedule.fromJson(json);

      expect(schedule.id, 'test-17');
      expect(schedule.routineId, 'routine-17');
      expect(schedule.routineName, 'Minimal Test');
      expect(schedule.type, ScheduleType.daily);
      expect(schedule.useRandomTime, false);
      expect(schedule.isEnabled, true);
      expect(schedule.snoozeMinutes, 10);
      expect(schedule.maxSnoozeCount, 3);
      expect(schedule.currentSnoozeCount, 0);
    });

    test('JSON deserialization handles unknown schedule type', () {
      final json = {
        'id': 'test-18',
        'routineId': 'routine-18',
        'routineName': 'Unknown Type Test',
        'type': 'unknown_type',
        'weekdays': [1, 2, 3, 4, 5, 6, 7],
        'hour': 8,
        'minute': 0,
      };

      final schedule = RoutineSchedule.fromJson(json);

      expect(schedule.type, ScheduleType.daily); // Should default to daily
    });
  });
}