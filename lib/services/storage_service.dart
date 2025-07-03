import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/routine.dart';
import '../models/routine_run.dart';

class StorageService {
  static const String _routinesKey = 'routines';
  static const String _settingsKey = 'settings';
  static const String _routineRunsPrefix = 'routine_runs_';

  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  // Routines persistence
  static Future<List<Routine>> loadRoutines() async {
    await init();
    final String? routinesJson = _prefs?.getString(_routinesKey);
    
    if (routinesJson == null) {
      return [];
    }

    try {
      final List<dynamic> routinesList = jsonDecode(routinesJson);
      return routinesList
          .map((json) => Routine.fromJson(json))
          .toList();
    } catch (e) {
      print('Error loading routines: $e');
      return [];
    }
  }

  static Future<bool> saveRoutines(List<Routine> routines) async {
    await init();
    try {
      final String routinesJson = jsonEncode(
        routines.map((routine) => routine.toJson()).toList(),
      );
      return await _prefs?.setString(_routinesKey, routinesJson) ?? false;
    } catch (e) {
      print('Error saving routines: $e');
      return false;
    }
  }

  // Settings persistence
  static Future<Map<String, dynamic>> loadSettings() async {
    await init();
    final String? settingsJson = _prefs?.getString(_settingsKey);
    
    if (settingsJson == null) {
      return {};
    }

    try {
      return Map<String, dynamic>.from(jsonDecode(settingsJson));
    } catch (e) {
      print('Error loading settings: $e');
      return {};
    }
  }

  static Future<bool> saveSettings(Map<String, dynamic> settings) async {
    await init();
    try {
      final String settingsJson = jsonEncode(settings);
      return await _prefs?.setString(_settingsKey, settingsJson) ?? false;
    } catch (e) {
      print('Error saving settings: $e');
      return false;
    }
  }

  // Routine run tracking
  static String _getRoutineRunsKey(String routineId) {
    return '$_routineRunsPrefix$routineId';
  }

  /// Save a routine run record
  static Future<bool> saveRoutineRun(RoutineRun run) async {
    await init();
    try {
      final key = _getRoutineRunsKey(run.routineId);
      final existingRuns = await loadRoutineRuns(run.routineId);
      
      // Update existing run or add new one
      final updatedRuns = existingRuns.where((r) => r.id != run.id).toList();
      updatedRuns.add(run);
      
      // Sort by start time (newest first)
      updatedRuns.sort((a, b) => b.startTime.compareTo(a.startTime));
      
      final runsJson = jsonEncode(updatedRuns.map((r) => r.toJson()).toList());
      return await _prefs?.setString(key, runsJson) ?? false;
    } catch (e) {
      print('Error saving routine run: $e');
      return false;
    }
  }

  /// Load all runs for a specific routine
  static Future<List<RoutineRun>> loadRoutineRuns(String routineId) async {
    await init();
    try {
      final key = _getRoutineRunsKey(routineId);
      final runsJson = _prefs?.getString(key);
      
      if (runsJson == null) return [];
      
      final List<dynamic> runsList = jsonDecode(runsJson);
      return runsList.map((json) => RoutineRun.fromJson(json)).toList();
    } catch (e) {
      print('Error loading routine runs for $routineId: $e');
      return [];
    }
  }

  /// Load all routine runs across all routines (for analytics)
  static Future<List<RoutineRun>> loadAllRoutineRuns() async {
    await init();
    try {
      final allRuns = <RoutineRun>[];
      final keys = _prefs?.getKeys() ?? {};
      
      for (final key in keys) {
        if (key.startsWith(_routineRunsPrefix)) {
          final runsJson = _prefs?.getString(key);
          if (runsJson != null) {
            final List<dynamic> runsList = jsonDecode(runsJson);
            final runs = runsList.map((json) => RoutineRun.fromJson(json)).toList();
            allRuns.addAll(runs);
          }
        }
      }
      
      // Sort by start time (newest first)
      allRuns.sort((a, b) => b.startTime.compareTo(a.startTime));
      return allRuns;
    } catch (e) {
      print('Error loading all routine runs: $e');
      return [];
    }
  }

  /// Delete all runs for a specific routine (when routine is deleted)
  static Future<bool> deleteRoutineRuns(String routineId) async {
    await init();
    try {
      final key = _getRoutineRunsKey(routineId);
      await _prefs?.remove(key);
      return true;
    } catch (e) {
      print('Error deleting routine runs for $routineId: $e');
      return false;
    }
  }

  /// Clear all run data for a specific routine (user-initiated)
  static Future<bool> clearRoutineRunData(String routineId) async {
    return await deleteRoutineRuns(routineId);
  }

  /// Get the most recent completed run for a routine
  static Future<RoutineRun?> getLastCompletedRun(String routineId) async {
    final runs = await loadRoutineRuns(routineId);
    try {
      return runs.firstWhere((run) => run.wasCompleted);
    } catch (e) {
      return null; // No completed runs found
    }
  }

  /// Get statistics for a routine
  static Future<Map<String, dynamic>> getRoutineStats(String routineId) async {
    final runs = await loadRoutineRuns(routineId);
    final completedRuns = runs.where((run) => run.wasCompleted).toList();
    
    if (completedRuns.isEmpty) {
      return {
        'timesRun': 0,
        'completionRate': 0.0,
        'averageDuration': null,
        'lastRunAt': null,
      };
    }
    
    final totalDuration = completedRuns
        .map((run) => run.duration ?? Duration.zero)
        .fold<Duration>(Duration.zero, (a, b) => a + b);
    
    return {
      'timesRun': completedRuns.length,
      'completionRate': completedRuns.length / runs.length,
      'averageDuration': completedRuns.isNotEmpty 
          ? Duration(milliseconds: totalDuration.inMilliseconds ~/ completedRuns.length)
          : null,
      'lastRunAt': completedRuns.first.endTime,
    };
  }

  // Clear all data
  static Future<bool> clearAll() async {
    await init();
    try {
      await _prefs?.remove(_routinesKey);
      await _prefs?.remove(_settingsKey);
      
      // Clear all routine run data
      final keys = _prefs?.getKeys() ?? {};
      for (final key in keys) {
        if (key.startsWith(_routineRunsPrefix)) {
          await _prefs?.remove(key);
        }
      }
      
      return true;
    } catch (e) {
      print('Error clearing data: $e');
      return false;
    }
  }
}