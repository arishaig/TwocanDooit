import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/routine.dart';

/// Service for managing routine categories with autocomplete and usage tracking
class CategoryService {
  static const String _categoriesKey = 'routine_categories';
  static const String _categoryStatsKey = 'category_statistics';
  
  static CategoryService? _instance;
  static CategoryService get instance => _instance ??= CategoryService._();
  CategoryService._();

  /// Get all categories that have been used, sorted by usage frequency
  Future<List<String>> getUsedCategories() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final categoriesJson = prefs.getString(_categoriesKey);
      if (categoriesJson == null) return [];
      
      final categoriesData = jsonDecode(categoriesJson) as Map<String, dynamic>;
      final categories = Map<String, int>.from(categoriesData);
      
      // Sort by usage count (descending), then alphabetically
      final sortedEntries = categories.entries.toList()
        ..sort((a, b) {
          final countComparison = b.value.compareTo(a.value);
          if (countComparison != 0) return countComparison;
          return a.key.toLowerCase().compareTo(b.key.toLowerCase());
        });
      
      return sortedEntries.map((entry) => entry.key).toList();
    } catch (e) {
      print('Error loading categories: $e');
      return [];
    }
  }

  /// Get category suggestions based on input text
  Future<List<String>> getCategorySuggestions(String input) async {
    final allCategories = await getUsedCategories();
    
    if (input.isEmpty) {
      // Return most frequently used categories
      return allCategories.take(8).toList();
    }
    
    final inputLower = input.toLowerCase();
    
    // Filter categories that contain the input text
    final filtered = allCategories.where((category) =>
      category.toLowerCase().contains(inputLower)
    ).toList();
    
    // Add exact input if it's not already in the list and not empty
    final trimmedInput = input.trim();
    if (trimmedInput.isNotEmpty && !filtered.contains(trimmedInput)) {
      filtered.insert(0, trimmedInput);
    }
    
    return filtered.take(8).toList();
  }

  /// Record that a category was used (increment usage count)
  Future<void> recordCategoryUsage(String category) async {
    if (category.trim().isEmpty) return;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final categoriesJson = prefs.getString(_categoriesKey);
      
      Map<String, int> categories;
      if (categoriesJson != null) {
        final categoriesData = jsonDecode(categoriesJson) as Map<String, dynamic>;
        categories = Map<String, int>.from(categoriesData);
      } else {
        categories = {};
      }
      
      final trimmedCategory = category.trim();
      categories[trimmedCategory] = (categories[trimmedCategory] ?? 0) + 1;
      
      await prefs.setString(_categoriesKey, jsonEncode(categories));
      await _updateCategoryStats();
    } catch (e) {
      print('Error recording category usage: $e');
    }
  }

  /// Remove a category from usage tracking
  Future<void> removeCategory(String category) async {
    if (category.trim().isEmpty) return;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final categoriesJson = prefs.getString(_categoriesKey);
      if (categoriesJson == null) return;
      
      final categoriesData = jsonDecode(categoriesJson) as Map<String, dynamic>;
      final categories = Map<String, int>.from(categoriesData);
      
      categories.remove(category.trim());
      
      await prefs.setString(_categoriesKey, jsonEncode(categories));
      await _updateCategoryStats();
    } catch (e) {
      print('Error removing category: $e');
    }
  }

  /// Get category usage statistics
  Future<Map<String, int>> getCategoryStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final categoriesJson = prefs.getString(_categoriesKey);
      if (categoriesJson == null) return {};
      
      final categoriesData = jsonDecode(categoriesJson) as Map<String, dynamic>;
      return Map<String, int>.from(categoriesData);
    } catch (e) {
      print('Error loading category stats: $e');
      return {};
    }
  }

  /// Update category statistics (for future analytics)
  Future<void> _updateCategoryStats() async {
    try {
      final stats = await getCategoryStats();
      final totalUsage = stats.values.fold(0, (sum, count) => sum + count);
      final uniqueCategories = stats.length;
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_categoryStatsKey, jsonEncode({
        'totalUsage': totalUsage,
        'uniqueCategories': uniqueCategories,
        'lastUpdated': DateTime.now().toIso8601String(),
      }));
    } catch (e) {
      print('Error updating category stats: $e');
    }
  }

  /// Initialize categories from existing routines
  Future<void> initializeCategoriesFromRoutines(List<Routine> routines) async {
    for (final routine in routines) {
      if (routine.category.isNotEmpty) {
        await recordCategoryUsage(routine.category);
      }
    }
  }

  /// Get popular category suggestions (most frequently used)
  Future<List<String>> getPopularCategories({int limit = 5}) async {
    final categories = await getUsedCategories();
    return categories.take(limit).toList();
  }

  /// Clean up unused categories (categories with 0 usage)
  Future<void> cleanupUnusedCategories() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final categoriesJson = prefs.getString(_categoriesKey);
      if (categoriesJson == null) return;
      
      final categoriesData = jsonDecode(categoriesJson) as Map<String, dynamic>;
      final categories = Map<String, int>.from(categoriesData);
      
      // Remove categories with 0 usage
      categories.removeWhere((category, count) => count <= 0);
      
      await prefs.setString(_categoriesKey, jsonEncode(categories));
      await _updateCategoryStats();
    } catch (e) {
      print('Error cleaning up categories: $e');
    }
  }

  /// Reset all category data (for testing or user preference)
  Future<void> resetAllCategories() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_categoriesKey);
      await prefs.remove(_categoryStatsKey);
    } catch (e) {
      print('Error resetting categories: $e');
    }
  }
}