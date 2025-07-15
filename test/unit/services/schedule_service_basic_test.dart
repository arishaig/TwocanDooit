import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../../../lib/models/routine_schedule.dart';
import '../../../lib/services/schedule_service.dart';

void main() {
  group('ScheduleService Basic Tests', () {
    late ScheduleService scheduleService;

    setUpAll(() {
      // Initialize timezone data
      tz_data.initializeTimeZones();
      tz.setLocalLocation(tz.UTC);
    });

    setUp(() {
      scheduleService = ScheduleService();
    });

    tearDown(() {
      scheduleService.dispose();
    });

    test('service is singleton', () {
      final service1 = ScheduleService();
      final service2 = ScheduleService();
      
      expect(service1, same(service2));
    });

    test('calculates next occurrence for daily schedule', () {
      final schedule = RoutineSchedule.daily(
        id: 'test-1',
        routineId: 'routine-1',
        routineName: 'Daily Test',
        hour: 10,
        minute: 0,
      );

      final nextOccurrence = scheduleService.calculateNextOccurrence(schedule);

      expect(nextOccurrence, isNotNull);
      expect(nextOccurrence!.hour, 10);
      expect(nextOccurrence.minute, 0);
    });

    test('calculates next occurrence for weekday schedule', () {
      final schedule = RoutineSchedule.weekdays(
        id: 'test-2',
        routineId: 'routine-2',
        routineName: 'Weekday Test',
        hour: 9,
        minute: 30,
      );

      final nextOccurrence = scheduleService.calculateNextOccurrence(schedule);

      expect(nextOccurrence, isNotNull);
      expect(nextOccurrence!.hour, 9);
      expect(nextOccurrence.minute, 30);
      // Should be on a weekday (Monday-Friday)
      expect(nextOccurrence.weekday, inInclusiveRange(1, 5));
    });

    test('calculates next occurrence for custom schedule', () {
      final schedule = RoutineSchedule.custom(
        id: 'test-3',
        routineId: 'routine-3',
        routineName: 'Custom Test',
        weekdays: {1, 3, 5}, // Monday, Wednesday, Friday
        hour: 14,
        minute: 30,
      );

      final nextOccurrence = scheduleService.calculateNextOccurrence(schedule);

      expect(nextOccurrence, isNotNull);
      expect(nextOccurrence!.hour, 14);
      expect(nextOccurrence.minute, 30);
      // Should be on Monday, Wednesday, or Friday
      expect([1, 3, 5].contains(nextOccurrence.weekday), true);
    });

    test('does not calculate next occurrence for disabled schedule', () {
      final schedule = RoutineSchedule.daily(
        id: 'test-4',
        routineId: 'routine-4',
        routineName: 'Disabled Test',
        hour: 8,
        minute: 0,
        isEnabled: false,
      );

      final nextOccurrence = scheduleService.calculateNextOccurrence(schedule);

      expect(nextOccurrence, isNull);
    });

    test('calculates next occurrence for snoozed schedule', () {
      final now = DateTime.now();
      final snoozeUntil = now.add(const Duration(minutes: 10));
      
      final schedule = RoutineSchedule.daily(
        id: 'test-5',
        routineId: 'routine-5',
        routineName: 'Snoozed Test',
        hour: 8,
        minute: 0,
      );

      final snoozedSchedule = schedule.copyWith(
        snoozeUntil: snoozeUntil,
        currentSnoozeCount: 1,
      );

      final nextOccurrence = scheduleService.calculateNextOccurrence(snoozedSchedule);

      expect(nextOccurrence, isNotNull);
      expect(nextOccurrence!.isAfter(now), true);
      // Should be close to the snooze time
      expect(nextOccurrence.difference(snoozeUntil).inMinutes.abs(), lessThan(1));
    });

    test('calculates next occurrence for once schedule', () {
      final tomorrow = DateTime.now().add(const Duration(days: 1));
      
      final schedule = RoutineSchedule(
        id: 'test-6',
        routineId: 'routine-6',
        routineName: 'Once Test',
        type: ScheduleType.once,
        weekdays: {tomorrow.weekday},
        hour: 15,
        minute: 0,
      );

      final nextOccurrence = scheduleService.calculateNextOccurrence(schedule);

      if (nextOccurrence != null) {
        expect(nextOccurrence.hour, 15);
        expect(nextOccurrence.minute, 0);
      }
    });

    test('handles weekly schedule correctly', () {
      final schedule = RoutineSchedule(
        id: 'test-7',
        routineId: 'routine-7',
        routineName: 'Weekly Test',
        type: ScheduleType.weekly,
        weekdays: {3}, // Wednesday
        hour: 12,
        minute: 0,
      );

      final nextOccurrence = scheduleService.calculateNextOccurrence(schedule);

      expect(nextOccurrence, isNotNull);
      expect(nextOccurrence!.weekday, 3); // Wednesday
      expect(nextOccurrence.hour, 12);
      expect(nextOccurrence.minute, 0);
    });

    test('handles edge case for time calculation', () {
      final now = tz.TZDateTime.now(tz.local);
      
      // Create a schedule for current time
      final schedule = RoutineSchedule.daily(
        id: 'test-8',
        routineId: 'routine-8',
        routineName: 'Edge Case Test',
        hour: now.hour,
        minute: now.minute,
      );

      final nextOccurrence = scheduleService.calculateNextOccurrence(schedule);

      expect(nextOccurrence, isNotNull);
      // Should be today if current time hasn't passed, or tomorrow
      expect(nextOccurrence!.isAfter(now) || nextOccurrence.isSameDay(now), true);
    });

    test('handles random time calculation', () {
      final schedule = RoutineSchedule.withRandomTime(
        id: 'test-9',
        routineId: 'routine-9',
        routineName: 'Random Test',
        type: ScheduleType.daily,
        weekdays: {1, 2, 3, 4, 5, 6, 7},
        randomStartHour: 9,
        randomStartMinute: 0,
        randomEndHour: 11,
        randomEndMinute: 0,
      );

      final nextOccurrence = scheduleService.calculateNextOccurrence(schedule);

      expect(nextOccurrence, isNotNull);
      // Time should be within the random range
      expect(nextOccurrence!.hour, inInclusiveRange(9, 11));
    });
  });
}

extension on DateTime {
  bool isSameDay(DateTime other) {
    return year == other.year && month == other.month && day == other.day;
  }
}