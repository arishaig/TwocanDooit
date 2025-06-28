import 'package:flutter/foundation.dart';
import '../models/routine.dart';
import '../models/step.dart';
import '../services/routine_service.dart';

class RoutineProvider with ChangeNotifier {
  List<Routine> _routines = [];
  bool _isLoading = false;
  String? _error;

  List<Routine> get routines => List.unmodifiable(_routines);
  bool get isLoading => _isLoading;
  String? get error => _error;

  List<String> get categories => RoutineService.getCategories();

  Future<void> loadRoutines() async {
    _setLoading(true);
    try {
      await RoutineService.loadRoutines();
      _routines = RoutineService.routines;
      _error = null;
    } catch (e) {
      _error = 'Failed to load routines: $e';
    } finally {
      _setLoading(false);
    }
  }

  Future<void> createRoutine({
    required String name,
    String description = '',
    String category = '',
    bool voiceEnabled = false,
    bool musicEnabled = false,
    String? musicTrack,
    bool isBuiltInTrack = true,
  }) async {
    try {
      final routine = await RoutineService.createRoutine(
        name: name,
        description: description,
        category: category,
        voiceEnabled: voiceEnabled,
        musicEnabled: musicEnabled,
        musicTrack: musicTrack,
        isBuiltInTrack: isBuiltInTrack,
      );
      _routines = RoutineService.routines;
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to create routine: $e';
      notifyListeners();
    }
  }

  Future<void> updateRoutine(Routine routine) async {
    try {
      await RoutineService.updateRoutine(routine);
      _routines = RoutineService.routines;
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to update routine: $e';
      notifyListeners();
    }
  }

  Future<void> deleteRoutine(String routineId) async {
    try {
      await RoutineService.deleteRoutine(routineId);
      _routines = RoutineService.routines;
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to delete routine: $e';
      notifyListeners();
    }
  }

  Future<void> addStepToRoutine(String routineId, Step step) async {
    try {
      final routine = RoutineService.getRoutineById(routineId);
      if (routine != null) {
        routine.addStep(step);
        await RoutineService.updateRoutine(routine);
        _routines = RoutineService.routines;
        notifyListeners();
      }
    } catch (e) {
      _error = 'Failed to add step: $e';
      notifyListeners();
    }
  }

  Future<void> removeStepFromRoutine(String routineId, String stepId) async {
    try {
      final routine = RoutineService.getRoutineById(routineId);
      if (routine != null) {
        routine.removeStep(stepId);
        await RoutineService.updateRoutine(routine);
        _routines = RoutineService.routines;
        notifyListeners();
      }
    } catch (e) {
      _error = 'Failed to remove step: $e';
      notifyListeners();
    }
  }

  Future<void> updateStepInRoutine(String routineId, Step step) async {
    try {
      final routine = RoutineService.getRoutineById(routineId);
      if (routine != null) {
        routine.updateStep(step);
        await RoutineService.updateRoutine(routine);
        _routines = RoutineService.routines;
        notifyListeners();
      }
    } catch (e) {
      _error = 'Failed to update step: $e';
      notifyListeners();
    }
  }

  Future<void> reorderStepsInRoutine(String routineId, int oldIndex, int newIndex) async {
    try {
      final routine = RoutineService.getRoutineById(routineId);
      if (routine != null) {
        routine.reorderSteps(oldIndex, newIndex);
        await RoutineService.updateRoutine(routine);
        _routines = RoutineService.routines;
        notifyListeners();
      }
    } catch (e) {
      _error = 'Failed to reorder steps: $e';
      notifyListeners();
    }
  }

  Routine? getRoutineById(String id) {
    return RoutineService.getRoutineById(id);
  }

  List<Routine> getRoutinesByCategory(String category) {
    return _routines.where((routine) => routine.category == category).toList();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
}