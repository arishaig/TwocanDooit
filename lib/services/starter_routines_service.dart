import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/routine.dart';

class StarterCategory {
  final String id;
  final String title;
  final String description;
  final String emoji;
  final int routineCount;
  final List<String> highlights;
  final bool isTopLevel;
  final int order;

  const StarterCategory({
    required this.id,
    required this.title,
    required this.description,
    required this.emoji,
    required this.routineCount,
    required this.highlights,
    required this.isTopLevel,
    required this.order,
  });

  factory StarterCategory.fromJson(Map<String, dynamic> json) {
    return StarterCategory(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      emoji: json['emoji'] as String,
      routineCount: json['routineCount'] as int,
      highlights: List<String>.from(json['highlights'] as List),
      isTopLevel: json['isTopLevel'] as bool? ?? false,
      order: json['order'] as int? ?? 0,
    );
  }
}

class StarterRoutinesService {
  static StarterRoutinesService? _instance;
  static StarterRoutinesService get instance => _instance ??= StarterRoutinesService._();
  StarterRoutinesService._();

  /// Load all available starter categories
  Future<List<StarterCategory>> loadCategories() async {
    try {
      final String jsonString = await rootBundle.loadString('assets/starter_routines/categories.json');
      final Map<String, dynamic> data = jsonDecode(jsonString);
      final List<dynamic> categoriesData = data['categories'] as List;
      
      final categories = categoriesData
          .map((categoryJson) => StarterCategory.fromJson(categoryJson as Map<String, dynamic>))
          .toList();
      
      // Sort by order
      categories.sort((a, b) => a.order.compareTo(b.order));
      
      return categories;
    } catch (e) {
      print('Error loading starter categories: $e');
      return [];
    }
  }

  /// Load only top-level categories (for initial display)
  Future<List<StarterCategory>> loadTopLevelCategories() async {
    final allCategories = await loadCategories();
    return allCategories.where((category) => category.isTopLevel).toList();
  }

  /// Load additional categories (for "Show More")
  Future<List<StarterCategory>> loadAdditionalCategories() async {
    final allCategories = await loadCategories();
    return allCategories.where((category) => !category.isTopLevel).toList();
  }

  /// Load routines for specific categories
  Future<List<Routine>> loadRoutinesForCategories(List<String> categoryIds) async {
    final List<Routine> allRoutines = [];
    
    for (final categoryId in categoryIds) {
      try {
        final routines = await _loadRoutinesForCategory(categoryId);
        allRoutines.addAll(routines);
      } catch (e) {
        print('Error loading routines for category $categoryId: $e');
        // Continue loading other categories even if one fails
      }
    }
    
    return allRoutines;
  }

  /// Load routines for a single category
  Future<List<Routine>> _loadRoutinesForCategory(String categoryId) async {
    final String assetPath = 'assets/starter_routines/$categoryId.json';
    
    try {
      final String jsonString = await rootBundle.loadString(assetPath);
      final Map<String, dynamic> data = jsonDecode(jsonString);
      
      // Validate format
      if (data['format'] != 'TwocanDooit-Routines') {
        throw Exception('Invalid format for starter routines file: $categoryId');
      }
      
      final List<dynamic> routinesData = data['routines'] as List;
      final List<Routine> routines = [];
      
      for (final routineJson in routinesData) {
        final routine = Routine.fromJson(routineJson as Map<String, dynamic>);
        routines.add(routine);
      }
      
      return routines;
    } catch (e) {
      print('Error loading routines from $assetPath: $e');
      return [];
    }
  }

  /// Get a preview of routines for a category (just names and descriptions)
  Future<List<Map<String, String>>> getRoutinePreview(String categoryId) async {
    try {
      final String assetPath = 'assets/starter_routines/$categoryId.json';
      final String jsonString = await rootBundle.loadString(assetPath);
      final Map<String, dynamic> data = jsonDecode(jsonString);
      final List<dynamic> routinesData = data['routines'] as List;
      
      return routinesData.map((routineJson) {
        final routine = routineJson as Map<String, dynamic>;
        return {
          'name': routine['name'] as String,
          'description': routine['description'] as String,
        };
      }).toList();
    } catch (e) {
      print('Error loading routine preview for $categoryId: $e');
      return [];
    }
  }
}