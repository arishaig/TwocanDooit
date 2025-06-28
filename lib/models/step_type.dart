enum StepType {
  basic,
  timer,
  reps,
  randomChoice,
  variableParameter,
}

extension StepTypeExtension on StepType {
  String get displayName {
    switch (this) {
      case StepType.basic:
        return 'Basic Task';
      case StepType.timer:
        return 'Timer';
      case StepType.reps:
        return 'Repetitions';
      case StepType.randomChoice:
        return 'Random Choice';
      case StepType.variableParameter:
        return 'Variable Parameter';
    }
  }

  String get description {
    switch (this) {
      case StepType.basic:
        return 'A simple task to complete';
      case StepType.timer:
        return 'A timed activity';
      case StepType.reps:
        return 'An activity with repetitions to count';
      case StepType.randomChoice:
        return 'Randomly select from multiple options';
      case StepType.variableParameter:
        return 'A task with random variable substitution';
    }
  }
}