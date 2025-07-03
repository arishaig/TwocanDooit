import 'package:uuid/uuid.dart';

/// Represents a single execution/run of a routine
/// Contains detailed metrics for analytics and trends
class RoutineRun {
  final String id;
  final String routineId;
  final DateTime startTime;
  DateTime? endTime;
  final int totalSteps;
  int completedSteps;
  Duration pausedDuration;
  
  RoutineRun({
    String? id,
    required this.routineId,
    DateTime? startTime,
    this.endTime,
    required this.totalSteps,
    this.completedSteps = 0,
    Duration? pausedDuration,
  }) : id = id ?? const Uuid().v4(),
       startTime = startTime ?? DateTime.now(),
       pausedDuration = pausedDuration ?? Duration.zero;

  /// Whether this run was completed (all steps finished)
  bool get wasCompleted => endTime != null && completedSteps >= totalSteps;
  
  /// Whether this run is currently in progress
  bool get isInProgress => endTime == null;
  
  /// Total duration of the run (if completed)
  Duration? get duration {
    if (endTime == null) return null;
    return endTime!.difference(startTime) - pausedDuration;
  }
  
  /// Current elapsed time (for in-progress runs)
  Duration get currentElapsed {
    final now = DateTime.now();
    return now.difference(startTime) - pausedDuration;
  }
  
  /// Completion percentage (0.0 to 1.0)
  double get completionPercentage {
    if (totalSteps == 0) return 1.0;
    return completedSteps / totalSteps;
  }

  /// Mark the run as completed
  void complete() {
    endTime = DateTime.now();
    completedSteps = totalSteps;
  }
  
  /// Mark the run as abandoned (not completed)
  void abandon() {
    endTime = DateTime.now();
  }
  
  /// Add paused time to the total
  void addPausedTime(Duration duration) {
    pausedDuration += duration;
  }
  
  /// Update the number of completed steps
  void updateProgress(int steps) {
    completedSteps = steps;
  }

  /// Create a copy with updated values
  RoutineRun copyWith({
    DateTime? endTime,
    int? completedSteps,
    Duration? pausedDuration,
  }) {
    return RoutineRun(
      id: id,
      routineId: routineId,
      startTime: startTime,
      endTime: endTime ?? this.endTime,
      totalSteps: totalSteps,
      completedSteps: completedSteps ?? this.completedSteps,
      pausedDuration: pausedDuration ?? this.pausedDuration,
    );
  }

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'routineId': routineId,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'totalSteps': totalSteps,
      'completedSteps': completedSteps,
      'pausedDuration': pausedDuration.inMilliseconds,
    };
  }

  /// Create from JSON
  factory RoutineRun.fromJson(Map<String, dynamic> json) {
    return RoutineRun(
      id: json['id'] ?? const Uuid().v4(),
      routineId: json['routineId'] ?? '',
      startTime: json['startTime'] != null 
          ? DateTime.parse(json['startTime']) 
          : DateTime.now(),
      endTime: json['endTime'] != null 
          ? DateTime.parse(json['endTime']) 
          : null,
      totalSteps: json['totalSteps'] ?? 0,
      completedSteps: json['completedSteps'] ?? 0,
      pausedDuration: Duration(
        milliseconds: json['pausedDuration'] ?? 0,
      ),
    );
  }

  @override
  String toString() {
    return 'RoutineRun(id: $id, routineId: $routineId, completed: $wasCompleted, steps: $completedSteps/$totalSteps)';
  }
}