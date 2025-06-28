import 'package:uuid/uuid.dart';
import 'step.dart';

class Routine {
  final String id;
  String name;
  String description;
  String category;
  List<Step> steps;
  final DateTime createdAt;
  DateTime updatedAt;
  
  // Voice announcements for this routine
  bool voiceEnabled; // Simple on/off toggle
  
  // Background music for this routine
  bool musicEnabled; // Enable/disable music for this routine
  String? musicTrack; // Path or name of the music track
  bool isBuiltInTrack; // True for built-in tracks, false for user-added

  Routine({
    String? id,
    required this.name,
    this.description = '',
    this.category = '',
    List<Step>? steps,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.voiceEnabled = false,
    this.musicEnabled = false,
    this.musicTrack,
    this.isBuiltInTrack = true,
  })  : id = id ?? const Uuid().v4(),
        steps = steps ?? [],
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Routine copyWith({
    String? name,
    String? description,
    String? category,
    List<Step>? steps,
    DateTime? updatedAt,
    bool? voiceEnabled,
    bool? musicEnabled,
    String? musicTrack,
    bool? isBuiltInTrack,
  }) {
    return Routine(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      steps: steps ?? this.steps,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      voiceEnabled: voiceEnabled ?? this.voiceEnabled,
      musicEnabled: musicEnabled ?? this.musicEnabled,
      musicTrack: musicTrack ?? this.musicTrack,
      isBuiltInTrack: isBuiltInTrack ?? this.isBuiltInTrack,
    );
  }

  void addStep(Step step) {
    steps.add(step);
    updatedAt = DateTime.now();
  }

  void removeStep(String stepId) {
    steps.removeWhere((step) => step.id == stepId);
    updatedAt = DateTime.now();
  }

  void updateStep(Step updatedStep) {
    final index = steps.indexWhere((step) => step.id == updatedStep.id);
    if (index != -1) {
      steps[index] = updatedStep;
      updatedAt = DateTime.now();
    }
  }

  void reorderSteps(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final Step step = steps.removeAt(oldIndex);
    steps.insert(newIndex, step);
    updatedAt = DateTime.now();
  }

  int get stepCount => steps.length;

  int get completedStepsCount => steps.where((step) => step.isCompleted).length;

  double get progressPercentage {
    if (steps.isEmpty) return 0.0;
    return completedStepsCount / stepCount;
  }

  bool get isCompleted => steps.isNotEmpty && completedStepsCount == stepCount;

  void resetProgress() {
    for (var step in steps) {
      step.reset();
    }
    updatedAt = DateTime.now();
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'category': category,
      'steps': steps.map((step) => step.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'voiceEnabled': voiceEnabled,
      'musicEnabled': musicEnabled,
      'musicTrack': musicTrack,
      'isBuiltInTrack': isBuiltInTrack,
    };
  }

  factory Routine.fromJson(Map<String, dynamic> json) {
    return Routine(
      id: json['id'],
      name: json['name'],
      description: json['description'] ?? '',
      category: json['category'] ?? '',
      steps: (json['steps'] as List<dynamic>?)
              ?.map((stepJson) => Step.fromJson(stepJson))
              .toList() ??
          [],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      voiceEnabled: json['voiceEnabled'] ?? false,
      musicEnabled: json['musicEnabled'] ?? false,
      musicTrack: json['musicTrack'],
      isBuiltInTrack: json['isBuiltInTrack'] ?? true,
    );
  }
}