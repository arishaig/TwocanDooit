import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import 'package:uuid/uuid.dart';
import '../models/routine_schedule.dart';
import 'notification_service.dart';

class ScheduleService {
  static final ScheduleService _instance = ScheduleService._internal();
  factory ScheduleService() => _instance;
  ScheduleService._internal() {
    _schedulesController = StreamController<List<RoutineSchedule>>.broadcast();
    // Add initial empty data to ensure stream has a value
    _schedulesController.add(_schedules);
  }

  static const String _scheduleStorageKey = 'routine_schedules';
  static const int _maxNotificationsPerSchedule = 30; // Queue next 30 notifications
  static const int _notificationIdBase = 10000; // Base ID for schedule notifications

  final List<RoutineSchedule> _schedules = [];
  late final StreamController<List<RoutineSchedule>> _schedulesController;

  Stream<List<RoutineSchedule>> get schedulesStream => _schedulesController.stream;
  List<RoutineSchedule> get schedules => List.unmodifiable(_schedules);

  /// Initialize the service and load saved schedules
  Future<void> initialize() async {
    await _loadSchedules();
    await _initializeTimezone();
    await _scheduleAllNotifications();
    debugPrint('ScheduleService initialized with ${_schedules.length} schedules');
  }

  /// Initialize timezone data
  Future<void> _initializeTimezone() async {
    try {
      tz_data.initializeTimeZones();
      // Try to use device timezone, fallback to UTC
      tz.setLocalLocation(tz.local);
      debugPrint('Timezone initialized: ${tz.local.name}');
    } catch (e) {
      debugPrint('Timezone initialization failed: $e, using UTC');
      tz.setLocalLocation(tz.UTC);
    }
  }

  /// Load schedules from storage
  Future<void> _loadSchedules() async {
    final prefs = await SharedPreferences.getInstance();
    final schedulesJson = prefs.getString(_scheduleStorageKey);
    
    if (schedulesJson != null) {
      try {
        final List<dynamic> jsonList = jsonDecode(schedulesJson);
        _schedules.clear();
        _schedules.addAll(jsonList.map((json) => RoutineSchedule.fromJson(json)));
      } catch (e) {
        debugPrint('Error loading schedules: $e');
      }
    }
    
    // Always emit initial data to ensure stream has a value
    _schedulesController.add(_schedules);
  }

  /// Save schedules to storage
  Future<void> _saveSchedules() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = _schedules.map((schedule) => schedule.toJson()).toList();
    await prefs.setString(_scheduleStorageKey, jsonEncode(jsonList));
    _schedulesController.add(_schedules);
  }

  /// Create a new schedule
  Future<RoutineSchedule> createSchedule({
    required String routineId,
    required String routineName,
    required ScheduleType type,
    required Set<int> weekdays,
    required int hour,
    required int minute,
    bool useRandomTime = false,
    int? randomStartHour,
    int? randomStartMinute,
    int? randomEndHour,
    int? randomEndMinute,
    bool isEnabled = true,
  }) async {
    final schedule = RoutineSchedule(
      id: const Uuid().v4(),
      routineId: routineId,
      routineName: routineName,
      type: type,
      weekdays: weekdays,
      hour: hour,
      minute: minute,
      useRandomTime: useRandomTime,
      randomStartHour: randomStartHour,
      randomStartMinute: randomStartMinute,
      randomEndHour: randomEndHour,
      randomEndMinute: randomEndMinute,
      isEnabled: isEnabled,
    );

    _schedules.add(schedule);
    await _saveSchedules();
    await _scheduleNotificationsForSchedule(schedule);
    
    debugPrint('Created schedule: ${schedule.displayText}');
    return schedule;
  }

  /// Update an existing schedule
  Future<RoutineSchedule> updateSchedule(RoutineSchedule updatedSchedule) async {
    final index = _schedules.indexWhere((s) => s.id == updatedSchedule.id);
    if (index != -1) {
      // Cancel old notifications
      await _cancelNotificationsForSchedule(_schedules[index]);
      
      // Update schedule
      _schedules[index] = updatedSchedule;
      await _saveSchedules();
      
      // Schedule new notifications
      await _scheduleNotificationsForSchedule(updatedSchedule);
      
      debugPrint('Updated schedule: ${updatedSchedule.displayText}');
      return updatedSchedule;
    }
    throw Exception('Schedule not found: ${updatedSchedule.id}');
  }

  /// Delete a schedule
  Future<void> deleteSchedule(String scheduleId) async {
    final index = _schedules.indexWhere((s) => s.id == scheduleId);
    if (index != -1) {
      final schedule = _schedules[index];
      
      // Cancel notifications
      await _cancelNotificationsForSchedule(schedule);
      
      // Remove from list
      _schedules.removeAt(index);
      await _saveSchedules();
      
      debugPrint('Deleted schedule: ${schedule.displayText}');
    }
  }

  /// Get schedule by ID
  RoutineSchedule? getSchedule(String scheduleId) {
    return _schedules.firstWhere(
      (s) => s.id == scheduleId,
      orElse: () => throw Exception('Schedule not found: $scheduleId'),
    );
  }

  /// Get all schedules for a routine
  List<RoutineSchedule> getSchedulesForRoutine(String routineId) {
    return _schedules.where((s) => s.routineId == routineId).toList();
  }

  /// Enable/disable a schedule
  Future<void> toggleSchedule(String scheduleId, bool enabled) async {
    final index = _schedules.indexWhere((s) => s.id == scheduleId);
    if (index != -1) {
      final schedule = _schedules[index];
      final updatedSchedule = schedule.copyWith(isEnabled: enabled);
      
      if (enabled) {
        // Re-schedule notifications
        await _scheduleNotificationsForSchedule(updatedSchedule);
      } else {
        // Cancel notifications
        await _cancelNotificationsForSchedule(schedule);
      }
      
      _schedules[index] = updatedSchedule;
      await _saveSchedules();
      
      debugPrint('${enabled ? 'Enabled' : 'Disabled'} schedule: ${schedule.displayText}');
    }
  }

  /// Handle schedule trigger (when notification fires)
  Future<void> handleScheduleTrigger(String scheduleId) async {
    final index = _schedules.indexWhere((s) => s.id == scheduleId);
    if (index != -1) {
      final schedule = _schedules[index];
      final updatedSchedule = schedule.copyWith(
        lastTriggeredTime: DateTime.now(),
        currentSnoozeCount: 0, // Reset snooze count
        snoozeUntil: null,
      );
      
      _schedules[index] = updatedSchedule;
      await _saveSchedules();
      
      // Schedule next occurrence
      await _scheduleNotificationsForSchedule(updatedSchedule);
      
      debugPrint('Schedule triggered: ${schedule.displayText}');
    }
  }

  /// Handle snooze action
  Future<void> snoozeSchedule(String scheduleId) async {
    final index = _schedules.indexWhere((s) => s.id == scheduleId);
    if (index != -1) {
      final schedule = _schedules[index];
      
      if (!schedule.canSnooze) {
        debugPrint('Cannot snooze: limit reached for ${schedule.displayText}');
        return;
      }
      
      final snoozeUntil = DateTime.now().add(Duration(minutes: schedule.snoozeMinutes));
      final updatedSchedule = schedule.copyWith(
        currentSnoozeCount: schedule.currentSnoozeCount + 1,
        snoozeUntil: snoozeUntil,
      );
      
      _schedules[index] = updatedSchedule;
      await _saveSchedules();
      
      // Schedule snooze notification
      await _scheduleSnoozeNotification(updatedSchedule);
      
      debugPrint('Snoozed schedule: ${schedule.displayText} until ${snoozeUntil.toString()}');
    }
  }

  /// Handle skip action (dismiss without rescheduling)
  Future<void> skipSchedule(String scheduleId) async {
    final index = _schedules.indexWhere((s) => s.id == scheduleId);
    if (index != -1) {
      final schedule = _schedules[index];
      final updatedSchedule = schedule.copyWith(
        currentSnoozeCount: 0,
        snoozeUntil: null,
      );
      
      _schedules[index] = updatedSchedule;
      await _saveSchedules();
      
      // Cancel current notification, but keep regular schedule
      await NotificationService.cancelScheduledNotification(_getNotificationId(schedule));
      
      debugPrint('Skipped schedule: ${schedule.displayText}');
    }
  }

  /// Calculate next occurrence for a schedule
  tz.TZDateTime? calculateNextOccurrence(RoutineSchedule schedule) {
    if (!schedule.isEnabled) return null;
    
    final now = tz.TZDateTime.now(tz.local);
    
    // If snoozed, return snooze time
    if (schedule.isSnoozed) {
      return tz.TZDateTime.from(schedule.snoozeUntil!, tz.local);
    }
    
    // Calculate base time for today
    final targetHour = schedule.useRandomTime ? _getRandomHour(schedule) : schedule.hour;
    final targetMinute = schedule.useRandomTime ? _getRandomMinute(schedule) : schedule.minute;
    
    switch (schedule.type) {
      case ScheduleType.once:
        final oneTime = tz.TZDateTime(tz.local, now.year, now.month, now.day, targetHour, targetMinute);
        return oneTime.isAfter(now) ? oneTime : null;
        
      case ScheduleType.daily:
        return _getNextDailyOccurrence(now, targetHour, targetMinute);
        
      case ScheduleType.weekly:
        return _getNextWeeklyOccurrence(now, schedule.weekdays.first, targetHour, targetMinute);
        
      case ScheduleType.weekdays:
        return _getNextWeekdayOccurrence(now, targetHour, targetMinute);
        
      case ScheduleType.custom:
        return _getNextCustomOccurrence(now, schedule.weekdays, targetHour, targetMinute);
    }
  }

  /// Get next daily occurrence
  tz.TZDateTime _getNextDailyOccurrence(tz.TZDateTime now, int hour, int minute) {
    final today = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    return today.isAfter(now) ? today : today.add(const Duration(days: 1));
  }

  /// Get next weekly occurrence
  tz.TZDateTime _getNextWeeklyOccurrence(tz.TZDateTime now, int weekday, int hour, int minute) {
    final daysUntilTarget = (weekday - now.weekday) % 7;
    final targetDate = now.add(Duration(days: daysUntilTarget));
    final targetTime = tz.TZDateTime(tz.local, targetDate.year, targetDate.month, targetDate.day, hour, minute);
    
    return targetTime.isAfter(now) ? targetTime : targetTime.add(const Duration(days: 7));
  }

  /// Get next weekday occurrence (Monday-Friday)
  tz.TZDateTime _getNextWeekdayOccurrence(tz.TZDateTime now, int hour, int minute) {
    final weekdays = {1, 2, 3, 4, 5}; // Monday through Friday
    return _getNextCustomOccurrence(now, weekdays, hour, minute);
  }

  /// Get next custom occurrence (specific days)
  tz.TZDateTime _getNextCustomOccurrence(tz.TZDateTime now, Set<int> weekdays, int hour, int minute) {
    // Check today first
    if (weekdays.contains(now.weekday)) {
      final today = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
      if (today.isAfter(now)) {
        return today;
      }
    }
    
    // Find next occurrence
    for (int i = 1; i <= 7; i++) {
      final checkDate = now.add(Duration(days: i));
      if (weekdays.contains(checkDate.weekday)) {
        return tz.TZDateTime(tz.local, checkDate.year, checkDate.month, checkDate.day, hour, minute);
      }
    }
    
    // Should never reach here
    return now.add(const Duration(days: 1));
  }

  /// Get random hour within schedule range
  int _getRandomHour(RoutineSchedule schedule) {
    if (!schedule.useRandomTime) return schedule.hour;
    
    final startHour = schedule.randomStartHour ?? schedule.hour;
    final endHour = schedule.randomEndHour ?? schedule.hour;
    
    if (startHour == endHour) return startHour;
    
    final random = Random();
    return startHour + random.nextInt(endHour - startHour + 1);
  }

  /// Get random minute within schedule range (5-minute increments)
  int _getRandomMinute(RoutineSchedule schedule) {
    if (!schedule.useRandomTime) return schedule.minute;
    
    final startMinute = schedule.randomStartMinute ?? schedule.minute;
    final endMinute = schedule.randomEndMinute ?? schedule.minute;
    
    if (startMinute == endMinute) return startMinute;
    
    // Convert to 5-minute increments
    final startIncrement = startMinute ~/ 5;
    final endIncrement = endMinute ~/ 5;
    
    final random = Random();
    final randomIncrement = startIncrement + random.nextInt(endIncrement - startIncrement + 1);
    
    return randomIncrement * 5;
  }

  /// Schedule notifications for all schedules
  Future<void> _scheduleAllNotifications() async {
    for (final schedule in _schedules) {
      await _scheduleNotificationsForSchedule(schedule);
    }
  }

  /// Schedule notifications for a specific schedule
  Future<void> _scheduleNotificationsForSchedule(RoutineSchedule schedule) async {
    if (!schedule.isEnabled) return;
    
    // Cancel existing notifications for this schedule
    await _cancelNotificationsForSchedule(schedule);
    
    // Generate multiple notifications (up to 30 days ahead)
    final notifications = <tz.TZDateTime>[];
    var nextTime = calculateNextOccurrence(schedule);
    
    for (int i = 0; i < _maxNotificationsPerSchedule && nextTime != null; i++) {
      notifications.add(nextTime);
      
      // Calculate next occurrence after this one
      final tempSchedule = schedule.copyWith(lastTriggeredTime: nextTime.toLocal());
      nextTime = calculateNextOccurrence(tempSchedule);
    }
    
    // Schedule the notifications
    for (int i = 0; i < notifications.length; i++) {
      final notificationId = _getNotificationId(schedule) + i;
      await NotificationService.scheduleRoutineReminder(
        notificationId: notificationId,
        scheduleId: schedule.id,
        routineId: schedule.routineId,
        routineName: schedule.routineName,
        scheduledTime: notifications[i],
      );
    }
    
    debugPrint('Scheduled ${notifications.length} notifications for: ${schedule.displayText}');
  }

  /// Schedule snooze notification
  Future<void> _scheduleSnoozeNotification(RoutineSchedule schedule) async {
    if (schedule.snoozeUntil == null) return;
    
    final notificationId = _getSnoozeNotificationId(schedule);
    await NotificationService.scheduleRoutineReminder(
      notificationId: notificationId,
      scheduleId: schedule.id,
      routineId: schedule.routineId,
      routineName: schedule.routineName,
      scheduledTime: tz.TZDateTime.from(schedule.snoozeUntil!, tz.local),
      isSnooze: true,
    );
    
    debugPrint('Scheduled snooze notification for: ${schedule.displayText}');
  }

  /// Cancel notifications for a schedule
  Future<void> _cancelNotificationsForSchedule(RoutineSchedule schedule) async {
    // Cancel regular notifications
    for (int i = 0; i < _maxNotificationsPerSchedule; i++) {
      final notificationId = _getNotificationId(schedule) + i;
      await NotificationService.cancelScheduledNotification(notificationId);
    }
    
    // Cancel snooze notification
    await NotificationService.cancelScheduledNotification(_getSnoozeNotificationId(schedule));
    
    debugPrint('Cancelled notifications for: ${schedule.displayText}');
  }

  /// Get notification ID for a schedule
  int _getNotificationId(RoutineSchedule schedule) {
    return _notificationIdBase + schedule.id.hashCode.abs() % 1000;
  }

  /// Get snooze notification ID for a schedule
  int _getSnoozeNotificationId(RoutineSchedule schedule) {
    return _getNotificationId(schedule) + 5000; // Offset for snooze notifications
  }

  /// Cleanup old notifications and reschedule
  Future<void> refreshSchedules() async {
    await _scheduleAllNotifications();
    debugPrint('Refreshed all schedules');
  }

  /// Dispose of the service
  void dispose() {
    _schedulesController.close();
  }
}