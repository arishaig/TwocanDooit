
/// Types of schedule recurrence patterns
enum ScheduleType {
  once,       // One-time schedule
  daily,      // Every day
  weekly,     // Specific day of week
  weekdays,   // Monday through Friday
  custom,     // Custom days (e.g., MWF)
}

/// Represents a scheduled reminder for a routine
class RoutineSchedule {
  final String id;
  final String routineId;
  final String routineName; // Cached for display
  
  // Schedule configuration
  final ScheduleType type;
  final Set<int> weekdays; // 1=Monday, 2=Tuesday, ..., 7=Sunday
  final int hour;          // 0-23
  final int minute;        // 0-59
  
  // Random time configuration
  final bool useRandomTime;
  final int? randomStartHour;
  final int? randomStartMinute;
  final int? randomEndHour;
  final int? randomEndMinute;
  
  // State
  final bool isEnabled;
  final DateTime? nextScheduledTime;
  final DateTime? lastTriggeredTime;
  
  // Snooze settings
  final int snoozeMinutes;
  final int maxSnoozeCount;
  
  // Tracking
  final int currentSnoozeCount;
  final DateTime? snoozeUntil;
  
  const RoutineSchedule({
    required this.id,
    required this.routineId,
    required this.routineName,
    required this.type,
    required this.weekdays,
    required this.hour,
    required this.minute,
    this.useRandomTime = false,
    this.randomStartHour,
    this.randomStartMinute,
    this.randomEndHour,
    this.randomEndMinute,
    this.isEnabled = true,
    this.nextScheduledTime,
    this.lastTriggeredTime,
    this.snoozeMinutes = 10,
    this.maxSnoozeCount = 3,
    this.currentSnoozeCount = 0,
    this.snoozeUntil,
  });

  /// Copy constructor for updates
  RoutineSchedule copyWith({
    String? routineName,
    ScheduleType? type,
    Set<int>? weekdays,
    int? hour,
    int? minute,
    bool? useRandomTime,
    int? randomStartHour,
    int? randomStartMinute,
    int? randomEndHour,
    int? randomEndMinute,
    bool? isEnabled,
    DateTime? nextScheduledTime,
    DateTime? lastTriggeredTime,
    int? snoozeMinutes,
    int? maxSnoozeCount,
    int? currentSnoozeCount,
    DateTime? snoozeUntil,
  }) {
    return RoutineSchedule(
      id: id,
      routineId: routineId,
      routineName: routineName ?? this.routineName,
      type: type ?? this.type,
      weekdays: weekdays ?? this.weekdays,
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
      useRandomTime: useRandomTime ?? this.useRandomTime,
      randomStartHour: randomStartHour ?? this.randomStartHour,
      randomStartMinute: randomStartMinute ?? this.randomStartMinute,
      randomEndHour: randomEndHour ?? this.randomEndHour,
      randomEndMinute: randomEndMinute ?? this.randomEndMinute,
      isEnabled: isEnabled ?? this.isEnabled,
      nextScheduledTime: nextScheduledTime ?? this.nextScheduledTime,
      lastTriggeredTime: lastTriggeredTime ?? this.lastTriggeredTime,
      snoozeMinutes: snoozeMinutes ?? this.snoozeMinutes,
      maxSnoozeCount: maxSnoozeCount ?? this.maxSnoozeCount,
      currentSnoozeCount: currentSnoozeCount ?? this.currentSnoozeCount,
      snoozeUntil: snoozeUntil ?? this.snoozeUntil,
    );
  }

  /// Check if the schedule is currently snoozed
  bool get isSnoozed {
    if (snoozeUntil == null) return false;
    return DateTime.now().isBefore(snoozeUntil!);
  }

  /// Check if snooze limit has been reached
  bool get canSnooze => currentSnoozeCount < maxSnoozeCount;

  /// Get display text for the schedule
  String get displayText {
    final timeStr = useRandomTime
        ? 'between ${_formatTime(randomStartHour!, randomStartMinute!)} and ${_formatTime(randomEndHour!, randomEndMinute!)}'
        : 'at ${_formatTime(hour, minute)}';
    
    switch (type) {
      case ScheduleType.once:
        return 'Once $timeStr';
      case ScheduleType.daily:
        return 'Daily $timeStr';
      case ScheduleType.weekly:
        final dayName = _getDayName(weekdays.first);
        return 'Every $dayName $timeStr';
      case ScheduleType.weekdays:
        return 'Weekdays $timeStr';
      case ScheduleType.custom:
        final dayNames = weekdays.map(_getDayName).join(', ');
        return '$dayNames $timeStr';
    }
  }

  /// Get short display text for the schedule
  String get shortDisplayText {
    switch (type) {
      case ScheduleType.once:
        return 'Once';
      case ScheduleType.daily:
        return 'Daily';
      case ScheduleType.weekly:
        return _getDayName(weekdays.first);
      case ScheduleType.weekdays:
        return 'Weekdays';
      case ScheduleType.custom:
        final dayNames = weekdays.map(_getDayAbbreviation).join(' ');
        return dayNames;
    }
  }

  /// Helper to format time as HH:MM AM/PM
  String _formatTime(int hour, int minute) {
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    final displayMinute = minute.toString().padLeft(2, '0');
    return '$displayHour:$displayMinute $period';
  }

  /// Helper to get day name from weekday number
  String _getDayName(int weekday) {
    switch (weekday) {
      case 1: return 'Monday';
      case 2: return 'Tuesday';
      case 3: return 'Wednesday';
      case 4: return 'Thursday';
      case 5: return 'Friday';
      case 6: return 'Saturday';
      case 7: return 'Sunday';
      default: return 'Unknown';
    }
  }

  /// Helper to get day abbreviation from weekday number
  String _getDayAbbreviation(int weekday) {
    switch (weekday) {
      case 1: return 'M';
      case 2: return 'T';
      case 3: return 'W';
      case 4: return 'T';
      case 5: return 'F';
      case 6: return 'S';
      case 7: return 'S';
      default: return '?';
    }
  }

  /// Convert to JSON for persistence
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'routineId': routineId,
      'routineName': routineName,
      'type': type.name,
      'weekdays': weekdays.toList(),
      'hour': hour,
      'minute': minute,
      'useRandomTime': useRandomTime,
      'randomStartHour': randomStartHour,
      'randomStartMinute': randomStartMinute,
      'randomEndHour': randomEndHour,
      'randomEndMinute': randomEndMinute,
      'isEnabled': isEnabled,
      'nextScheduledTime': nextScheduledTime?.toIso8601String(),
      'lastTriggeredTime': lastTriggeredTime?.toIso8601String(),
      'snoozeMinutes': snoozeMinutes,
      'maxSnoozeCount': maxSnoozeCount,
      'currentSnoozeCount': currentSnoozeCount,
      'snoozeUntil': snoozeUntil?.toIso8601String(),
    };
  }

  /// Create from JSON
  factory RoutineSchedule.fromJson(Map<String, dynamic> json) {
    return RoutineSchedule(
      id: json['id'],
      routineId: json['routineId'],
      routineName: json['routineName'],
      type: ScheduleType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => ScheduleType.daily,
      ),
      weekdays: Set<int>.from(json['weekdays'] ?? []),
      hour: json['hour'] ?? 0,
      minute: json['minute'] ?? 0,
      useRandomTime: json['useRandomTime'] ?? false,
      randomStartHour: json['randomStartHour'],
      randomStartMinute: json['randomStartMinute'],
      randomEndHour: json['randomEndHour'],
      randomEndMinute: json['randomEndMinute'],
      isEnabled: json['isEnabled'] ?? true,
      nextScheduledTime: json['nextScheduledTime'] != null
          ? DateTime.parse(json['nextScheduledTime'])
          : null,
      lastTriggeredTime: json['lastTriggeredTime'] != null
          ? DateTime.parse(json['lastTriggeredTime'])
          : null,
      snoozeMinutes: json['snoozeMinutes'] ?? 10,
      maxSnoozeCount: json['maxSnoozeCount'] ?? 3,
      currentSnoozeCount: json['currentSnoozeCount'] ?? 0,
      snoozeUntil: json['snoozeUntil'] != null
          ? DateTime.parse(json['snoozeUntil'])
          : null,
    );
  }

  /// Create a schedule for daily reminders
  factory RoutineSchedule.daily({
    required String id,
    required String routineId,
    required String routineName,
    required int hour,
    required int minute,
    bool isEnabled = true,
  }) {
    return RoutineSchedule(
      id: id,
      routineId: routineId,
      routineName: routineName,
      type: ScheduleType.daily,
      weekdays: {1, 2, 3, 4, 5, 6, 7}, // All days
      hour: hour,
      minute: minute,
      isEnabled: isEnabled,
    );
  }

  /// Create a schedule for weekday reminders
  factory RoutineSchedule.weekdays({
    required String id,
    required String routineId,
    required String routineName,
    required int hour,
    required int minute,
    bool isEnabled = true,
  }) {
    return RoutineSchedule(
      id: id,
      routineId: routineId,
      routineName: routineName,
      type: ScheduleType.weekdays,
      weekdays: {1, 2, 3, 4, 5}, // Monday through Friday
      hour: hour,
      minute: minute,
      isEnabled: isEnabled,
    );
  }

  /// Create a schedule for custom days (e.g., MWF)
  factory RoutineSchedule.custom({
    required String id,
    required String routineId,
    required String routineName,
    required Set<int> weekdays,
    required int hour,
    required int minute,
    bool isEnabled = true,
  }) {
    return RoutineSchedule(
      id: id,
      routineId: routineId,
      routineName: routineName,
      type: ScheduleType.custom,
      weekdays: weekdays,
      hour: hour,
      minute: minute,
      isEnabled: isEnabled,
    );
  }

  /// Create a schedule with random time range
  factory RoutineSchedule.withRandomTime({
    required String id,
    required String routineId,
    required String routineName,
    required ScheduleType type,
    required Set<int> weekdays,
    required int randomStartHour,
    required int randomStartMinute,
    required int randomEndHour,
    required int randomEndMinute,
    bool isEnabled = true,
  }) {
    return RoutineSchedule(
      id: id,
      routineId: routineId,
      routineName: routineName,
      type: type,
      weekdays: weekdays,
      hour: randomStartHour, // Default to start time
      minute: randomStartMinute,
      useRandomTime: true,
      randomStartHour: randomStartHour,
      randomStartMinute: randomStartMinute,
      randomEndHour: randomEndHour,
      randomEndMinute: randomEndMinute,
      isEnabled: isEnabled,
    );
  }
}