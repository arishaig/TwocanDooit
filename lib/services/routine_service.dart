import '../models/routine.dart';
import '../models/step.dart';
import '../models/step_type.dart';
import 'storage_service.dart';

class RoutineService {
  static List<Routine> _routines = [];

  static List<Routine> get routines => List.unmodifiable(_routines);

  static Future<void> loadRoutines() async {
    _routines = await StorageService.loadRoutines();
    // Note: Sample data is now loaded selectively during onboarding
    // No automatic sample data creation
  }

  static Future<void> saveRoutines() async {
    await StorageService.saveRoutines(_routines);
  }

  static Future<void> saveStarterRoutines(List<Routine> starterRoutines) async {
    _routines.addAll(starterRoutines);
    await saveRoutines();
  }

  static Future<Routine> createRoutine({
    required String name,
    String description = '',
    String category = '',
    bool voiceEnabled = false,
    bool musicEnabled = false,
    String? musicTrack,
    bool isBuiltInTrack = true,
  }) async {
    final routine = Routine(
      name: name,
      description: description,
      category: category,
      voiceEnabled: voiceEnabled,
      musicEnabled: musicEnabled,
      musicTrack: musicTrack,
      isBuiltInTrack: isBuiltInTrack,
    );
    
    _routines.add(routine);
    await saveRoutines();
    return routine;
  }

  static Future<void> updateRoutine(Routine updatedRoutine) async {
    final index = _routines.indexWhere((r) => r.id == updatedRoutine.id);
    if (index != -1) {
      _routines[index] = updatedRoutine.copyWith(updatedAt: DateTime.now());
      await saveRoutines();
    }
  }

  static Future<void> deleteRoutine(String routineId) async {
    _routines.removeWhere((routine) => routine.id == routineId);
    await saveRoutines();
    
    // Also delete all run records for this routine
    await StorageService.deleteRoutineRuns(routineId);
  }

  static Future<void> importRoutine(Routine routine) async {
    _routines.add(routine);
    await saveRoutines();
  }

  static Routine? getRoutineById(String id) {
    try {
      return _routines.firstWhere((routine) => routine.id == id);
    } catch (e) {
      return null;
    }
  }

  static List<Routine> getRoutinesByCategory(String category) {
    return _routines.where((routine) => routine.category == category).toList();
  }

  static List<String> getCategories() {
    final categories = _routines.map((routine) => routine.category).toSet();
    categories.remove(''); // Remove empty categories
    return categories.toList()..sort();
  }

  static Future<void> _createSampleData() async {
    // Morning Routine
    final morningRoutine = Routine(
      name: 'Morning Routine',
      description: 'Start your day right',
      category: 'Daily',
    );

    morningRoutine.addStep(Step(
      title: 'Wake up and stretch',
      description: 'Take a moment to stretch and wake up your body',
      type: StepType.basic,
    ));

    morningRoutine.addStep(Step(
      title: 'Brush teeth',
      description: 'Maintain good oral hygiene',
      type: StepType.timer,
      timerDuration: 120, // 2 minutes
    ));

    morningRoutine.addStep(Step(
      title: 'Choose breakfast',
      description: 'Pick a healthy breakfast option',
      type: StepType.randomChoice,
      choices: ['Cereal', 'Toast', 'Eggs', 'Fruit & Yogurt', 'Smoothie'],
    ));

    // Exercise Routine
    final exerciseRoutine = Routine(
      name: 'Quick Exercise',
      description: '5 minute energy boost',
      category: 'Health',
    );

    exerciseRoutine.addStep(Step(
      title: 'Push-ups',
      description: 'Do push-ups at your own pace',
      type: StepType.reps,
      repsTarget: 10,
    ));

    exerciseRoutine.addStep(Step(
      title: 'Jumping jacks',
      description: 'Get your heart rate up',
      type: StepType.timer,
      timerDuration: 60, // 1 minute
    ));

    exerciseRoutine.addStep(Step(
      title: 'Cool down stretch',
      description: 'Stretch your muscles after exercise',
      type: StepType.timer,
      timerDuration: 120, // 2 minutes
    ));

    // Study Break Routine
    final studyBreakRoutine = Routine(
      name: 'Study Break',
      description: 'Refresh your mind during study sessions',
      category: 'Productivity',
    );

    studyBreakRoutine.addStep(Step(
      title: 'Deep breathing',
      description: 'Take deep breaths to center yourself',
      type: StepType.timer,
      timerDuration: 60,
    ));

    studyBreakRoutine.addStep(Step(
      title: 'Choose activity',
      description: 'Pick a refreshing break activity',
      type: StepType.randomChoice,
      choices: ['Walk around', 'Drink water', 'Look out window', 'Stretch', 'Quick snack'],
    ));

    _routines.addAll([morningRoutine, exerciseRoutine, studyBreakRoutine]);
    await saveRoutines();
  }

  static Future<void> clearAll() async {
    _routines.clear();
    await StorageService.clearAll();
  }
}