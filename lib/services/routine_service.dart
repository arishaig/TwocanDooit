import '../models/routine.dart';
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


  static Future<void> clearAll() async {
    _routines.clear();
    await StorageService.clearAll();
  }
}