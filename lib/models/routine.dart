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

  Routine({
    String? id,
    required this.name,
    this.description = '',
    this.category = '',
    List<Step>? steps,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.voiceEnabled = false,
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
    );
  }
}