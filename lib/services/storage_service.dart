import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/routine.dart';

class StorageService {
  static const String _routinesKey = 'routines';
  static const String _settingsKey = 'settings';

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

  // Clear all data
  static Future<bool> clearAll() async {
    await init();
    try {
      await _prefs?.remove(_routinesKey);
      await _prefs?.remove(_settingsKey);
      return true;
    } catch (e) {
      print('Error clearing data: $e');
      return false;
    }
  }
}