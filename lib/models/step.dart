import 'dart:math';
import 'package:uuid/uuid.dart';
import 'step_type.dart';

class Step {
  final String id;
  String title;
  String description;
  StepType type;
  
  // Timer-specific properties
  int timerDuration; // in seconds
  
  // Reps-specific properties  
  int repsTarget;
  int repsCompleted;
  int? repDurationSeconds; // null means manual button completion
  
  // Random reps properties
  bool randomizeReps;
  int repsMin; // minimum reps for randomization
  int repsMax; // maximum reps for randomization
  
  // Random choice properties
  List<String> choices;
  List<double>? choiceWeights; // null means equal weights, otherwise same length as choices
  String? selectedChoice;
  
  // Variable parameter properties
  String variableName;
  List<String> variableOptions;
  String? selectedVariable;
  
  // Completion state
  bool isCompleted;
  
  // Voice announcement for this step
  bool voiceEnabled;

  Step({
    String? id,
    required this.title,
    this.description = '',
    this.type = StepType.basic,
    this.timerDuration = 60,
    this.repsTarget = 1,
    this.repsCompleted = 0,
    this.repDurationSeconds,
    this.randomizeReps = false,
    this.repsMin = 1,
    this.repsMax = 10,
    this.choices = const [],
    this.choiceWeights,
    this.selectedChoice,
    this.variableName = '',
    this.variableOptions = const [],
    this.selectedVariable,
    this.isCompleted = false,
    this.voiceEnabled = true,
  }) : id = id ?? const Uuid().v4();

  Step copyWith({
    String? title,
    String? description,
    StepType? type,
    int? timerDuration,
    int? repsTarget,
    int? repsCompleted,
    int? repDurationSeconds,
    bool? randomizeReps,
    int? repsMin,
    int? repsMax,
    List<String>? choices,
    List<double>? choiceWeights,
    String? selectedChoice,
    String? variableName,
    List<String>? variableOptions,
    String? selectedVariable,
    bool? isCompleted,
    bool? voiceEnabled,
  }) {
    return Step(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      timerDuration: timerDuration ?? this.timerDuration,
      repsTarget: repsTarget ?? this.repsTarget,
      repsCompleted: repsCompleted ?? this.repsCompleted,
      repDurationSeconds: repDurationSeconds ?? this.repDurationSeconds,
      randomizeReps: randomizeReps ?? this.randomizeReps,
      repsMin: repsMin ?? this.repsMin,
      repsMax: repsMax ?? this.repsMax,
      choices: choices ?? this.choices,
      choiceWeights: choiceWeights ?? this.choiceWeights,
      selectedChoice: selectedChoice ?? this.selectedChoice,
      variableName: variableName ?? this.variableName,
      variableOptions: variableOptions ?? this.variableOptions,
      selectedVariable: selectedVariable ?? this.selectedVariable,
      isCompleted: isCompleted ?? this.isCompleted,
      voiceEnabled: voiceEnabled ?? this.voiceEnabled,
    );
  }

  void complete() {
    isCompleted = true;
  }

  void reset() {
    isCompleted = false;
    repsCompleted = 0;
    selectedChoice = null;
    selectedVariable = null;
    
    // Reset random reps to unrolled state
    if (randomizeReps) {
      repsTarget = repsMin;
    }
  }

  void randomizeRepsTarget() {
    if (randomizeReps && repsMin <= repsMax) {
      final random = Random();
      repsTarget = repsMin + random.nextInt(repsMax - repsMin + 1);
    }
  }

  String? selectRandomChoice() {
    if (choices.isEmpty) return null;
    
    final random = Random();
    
    // If no weights provided or weights don't match choices, use equal probability
    if (choiceWeights == null || choiceWeights!.length != choices.length) {
      final index = random.nextInt(choices.length);
      return choices[index];
    }
    
    // Use weighted selection
    final totalWeight = choiceWeights!.fold<double>(0, (sum, weight) => sum + weight);
    if (totalWeight <= 0) {
      // Fallback to equal probability if weights are invalid
      final index = random.nextInt(choices.length);
      return choices[index];
    }
    
    double randomValue = random.nextDouble() * totalWeight;
    double cumulativeWeight = 0;
    
    for (int i = 0; i < choices.length; i++) {
      cumulativeWeight += choiceWeights![i];
      if (randomValue <= cumulativeWeight) {
        return choices[i];
      }
    }
    
    // Fallback (should never reach here)
    return choices.last;
  }

  String get displayText {
    switch (type) {
      case StepType.timer:
        final minutes = timerDuration ~/ 60;
        final seconds = timerDuration % 60;
        return '$title (${minutes}:${seconds.toString().padLeft(2, '0')})';
      case StepType.reps:
        final durationText = repDurationSeconds != null ? ' (${repDurationSeconds}s each)' : '';
        if (randomizeReps) {
          return '$title (${repsCompleted}/$repsTarget random)$durationText';
        }
        return '$title (${repsCompleted}/${repsTarget})$durationText';
      case StepType.randomChoice:
        if (selectedChoice != null) {
          return '$title → $selectedChoice';
        }
        return '$title (${choices.length} options)';
      case StepType.variableParameter:
        if (selectedVariable != null) {
          return '$title ($variableName: $selectedVariable)';
        }
        return '$title ($variableName: ${variableOptions.length} options)';
      case StepType.basic:
      default:
        return title;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'type': type.name,
      'timerDuration': timerDuration,
      'repsTarget': repsTarget,
      'repsCompleted': repsCompleted,
      'repDurationSeconds': repDurationSeconds,
      'randomizeReps': randomizeReps,
      'repsMin': repsMin,
      'repsMax': repsMax,
      'choices': choices,
      'choiceWeights': choiceWeights,
      'selectedChoice': selectedChoice,
      'variableName': variableName,
      'variableOptions': variableOptions,
      'selectedVariable': selectedVariable,
      'isCompleted': isCompleted,
      'voiceEnabled': voiceEnabled,
    };
  }

  factory Step.fromJson(Map<String, dynamic> json) {
    return Step(
      id: json['id'],
      title: json['title'],
      description: json['description'] ?? '',
      type: StepType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => StepType.basic,
      ),
      timerDuration: json['timerDuration'] ?? 60,
      repsTarget: json['repsTarget'] ?? 1,
      repsCompleted: json['repsCompleted'] ?? 0,
      repDurationSeconds: json['repDurationSeconds'],
      randomizeReps: json['randomizeReps'] ?? false,
      repsMin: json['repsMin'] ?? 1,
      repsMax: json['repsMax'] ?? 10,
      choices: List<String>.from(json['choices'] ?? []),
      choiceWeights: json['choiceWeights'] != null ? List<double>.from(json['choiceWeights']) : null,
      selectedChoice: json['selectedChoice'],
      variableName: json['variableName'] ?? '',
      variableOptions: List<String>.from(json['variableOptions'] ?? []),
      selectedVariable: json['selectedVariable'],
      isCompleted: json['isCompleted'] ?? false,
      voiceEnabled: json['voiceEnabled'] ?? true,
    );
  }
}