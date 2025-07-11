import 'package:flutter_test/flutter_test.dart';
import 'package:twocandooit/models/app_settings.dart';

void main() {
  group('AppSettings Model Tests', () {
    group('Constructor and Default Values', () {
      test('should create with default values', () {
        const settings = AppSettings();
        
        expect(settings.ttsEnabled, isFalse);
        expect(settings.ttsRate, equals(0.5));
        expect(settings.ttsPitch, equals(1.0));
        expect(settings.ttsVolume, equals(1.0));
        expect(settings.ttsLanguage, equals('en-US'));
        expect(settings.ttsVoice, isNull);
        expect(settings.ttsVoiceLocale, isNull);
        expect(settings.nudgeEnabled, isTrue);
        expect(settings.nudgeIntervalMinutes, equals(5));
        expect(settings.maxNudgeCount, equals(3));
        expect(settings.audioFeedbackEnabled, isTrue);
        expect(settings.hapticFeedbackEnabled, isTrue);
        expect(settings.isDarkMode, isTrue);
        expect(settings.userName, equals(''));
        expect(settings.hasCompletedOnboarding, isFalse);
      });

      test('should create with custom values', () {
        const settings = AppSettings(
          ttsEnabled: true,
          ttsRate: 0.75,
          ttsPitch: 1.2,
          ttsVolume: 0.8,
          ttsLanguage: 'es-ES',
          ttsVoice: 'custom-voice',
          ttsVoiceLocale: 'es-ES',
          nudgeEnabled: false,
          nudgeIntervalMinutes: 10,
          maxNudgeCount: 5,
          audioFeedbackEnabled: false,
          hapticFeedbackEnabled: false,
          isDarkMode: false,
          userName: 'Test User',
          hasCompletedOnboarding: true,
        );
        
        expect(settings.ttsEnabled, isTrue);
        expect(settings.ttsRate, equals(0.75));
        expect(settings.ttsPitch, equals(1.2));
        expect(settings.ttsVolume, equals(0.8));
        expect(settings.ttsLanguage, equals('es-ES'));
        expect(settings.ttsVoice, equals('custom-voice'));
        expect(settings.ttsVoiceLocale, equals('es-ES'));
        expect(settings.nudgeEnabled, isFalse);
        expect(settings.nudgeIntervalMinutes, equals(10));
        expect(settings.maxNudgeCount, equals(5));
        expect(settings.audioFeedbackEnabled, isFalse);
        expect(settings.hapticFeedbackEnabled, isFalse);
        expect(settings.isDarkMode, isFalse);
        expect(settings.userName, equals('Test User'));
        expect(settings.hasCompletedOnboarding, isTrue);
      });
    });

    group('copyWith Method', () {
      test('should create copy with updated TTS settings', () {
        const originalSettings = AppSettings();
        
        final updatedSettings = originalSettings.copyWith(
          ttsEnabled: true,
          ttsRate: 0.8,
          ttsPitch: 1.5,
          ttsVolume: 0.9,
          ttsLanguage: 'fr-FR',
          ttsVoice: 'french-voice',
          ttsVoiceLocale: 'fr-FR',
        );
        
        expect(updatedSettings.ttsEnabled, isTrue);
        expect(updatedSettings.ttsRate, equals(0.8));
        expect(updatedSettings.ttsPitch, equals(1.5));
        expect(updatedSettings.ttsVolume, equals(0.9));
        expect(updatedSettings.ttsLanguage, equals('fr-FR'));
        expect(updatedSettings.ttsVoice, equals('french-voice'));
        expect(updatedSettings.ttsVoiceLocale, equals('fr-FR'));
        
        // Other settings should remain unchanged
        expect(updatedSettings.nudgeEnabled, equals(originalSettings.nudgeEnabled));
        expect(updatedSettings.isDarkMode, equals(originalSettings.isDarkMode));
        expect(updatedSettings.userName, equals(originalSettings.userName));
      });

      test('should create copy with updated nudge settings', () {
        const originalSettings = AppSettings();
        
        final updatedSettings = originalSettings.copyWith(
          nudgeEnabled: false,
          nudgeIntervalMinutes: 15,
          maxNudgeCount: 7,
        );
        
        expect(updatedSettings.nudgeEnabled, isFalse);
        expect(updatedSettings.nudgeIntervalMinutes, equals(15));
        expect(updatedSettings.maxNudgeCount, equals(7));
        
        // Other settings should remain unchanged
        expect(updatedSettings.ttsEnabled, equals(originalSettings.ttsEnabled));
        expect(updatedSettings.audioFeedbackEnabled, equals(originalSettings.audioFeedbackEnabled));
      });

      test('should create copy with updated feedback settings', () {
        const originalSettings = AppSettings();
        
        final updatedSettings = originalSettings.copyWith(
          audioFeedbackEnabled: false,
          hapticFeedbackEnabled: false,
        );
        
        expect(updatedSettings.audioFeedbackEnabled, isFalse);
        expect(updatedSettings.hapticFeedbackEnabled, isFalse);
        
        // Other settings should remain unchanged
        expect(updatedSettings.ttsEnabled, equals(originalSettings.ttsEnabled));
        expect(updatedSettings.nudgeEnabled, equals(originalSettings.nudgeEnabled));
      });

      test('should create copy with updated theme settings', () {
        const originalSettings = AppSettings();
        
        final updatedSettings = originalSettings.copyWith(
          isDarkMode: false,
        );
        
        expect(updatedSettings.isDarkMode, isFalse);
        
        // Other settings should remain unchanged
        expect(updatedSettings.ttsEnabled, equals(originalSettings.ttsEnabled));
        expect(updatedSettings.nudgeEnabled, equals(originalSettings.nudgeEnabled));
      });

      test('should create copy with updated user settings', () {
        const originalSettings = AppSettings();
        
        final updatedSettings = originalSettings.copyWith(
          userName: 'Updated User',
          hasCompletedOnboarding: true,
        );
        
        expect(updatedSettings.userName, equals('Updated User'));
        expect(updatedSettings.hasCompletedOnboarding, isTrue);
        
        // Other settings should remain unchanged
        expect(updatedSettings.ttsEnabled, equals(originalSettings.ttsEnabled));
        expect(updatedSettings.isDarkMode, equals(originalSettings.isDarkMode));
      });

      test('should preserve original values when not specified', () {
        const originalSettings = AppSettings(
          ttsEnabled: true,
          ttsRate: 0.7,
          userName: 'Original User',
          isDarkMode: false,
        );
        
        final updatedSettings = originalSettings.copyWith(
          ttsEnabled: false,
        );
        
        expect(updatedSettings.ttsEnabled, isFalse);
        expect(updatedSettings.ttsRate, equals(0.7));
        expect(updatedSettings.userName, equals('Original User'));
        expect(updatedSettings.isDarkMode, isFalse);
      });

      test('should handle null values correctly', () {
        const originalSettings = AppSettings(
          ttsVoice: 'original-voice',
          ttsVoiceLocale: 'en-US',
        );
        
        final updatedSettings = originalSettings.copyWith(
          ttsVoice: null,
          ttsVoiceLocale: null,
        );
        
        expect(updatedSettings.ttsVoice, isNull);
        expect(updatedSettings.ttsVoiceLocale, isNull);
      });
    });

    group('JSON Serialization', () {
      test('should serialize to JSON correctly', () {
        const settings = AppSettings(
          ttsEnabled: true,
          ttsRate: 0.8,
          ttsPitch: 1.2,
          ttsVolume: 0.9,
          ttsLanguage: 'es-ES',
          ttsVoice: 'test-voice',
          ttsVoiceLocale: 'es-ES',
          nudgeEnabled: false,
          nudgeIntervalMinutes: 10,
          maxNudgeCount: 5,
          audioFeedbackEnabled: false,
          hapticFeedbackEnabled: false,
          isDarkMode: false,
          userName: 'Test User',
          hasCompletedOnboarding: true,
        );
        
        final json = settings.toJson();
        
        expect(json['ttsEnabled'], isTrue);
        expect(json['ttsRate'], equals(0.8));
        expect(json['ttsPitch'], equals(1.2));
        expect(json['ttsVolume'], equals(0.9));
        expect(json['ttsLanguage'], equals('es-ES'));
        expect(json['ttsVoice'], equals('test-voice'));
        expect(json['ttsVoiceLocale'], equals('es-ES'));
        expect(json['nudgeEnabled'], isFalse);
        expect(json['nudgeIntervalMinutes'], equals(10));
        expect(json['maxNudgeCount'], equals(5));
        expect(json['audioFeedbackEnabled'], isFalse);
        expect(json['hapticFeedbackEnabled'], isFalse);
        expect(json['isDarkMode'], isFalse);
        expect(json['userName'], equals('Test User'));
        expect(json['hasCompletedOnboarding'], isTrue);
      });

      test('should serialize null values correctly', () {
        const settings = AppSettings(
          ttsVoice: null,
          ttsVoiceLocale: null,
        );
        
        final json = settings.toJson();
        
        expect(json['ttsVoice'], isNull);
        expect(json['ttsVoiceLocale'], isNull);
      });

      test('should deserialize from JSON correctly', () {
        final json = {
          'ttsEnabled': true,
          'ttsRate': 0.8,
          'ttsPitch': 1.2,
          'ttsVolume': 0.9,
          'ttsLanguage': 'es-ES',
          'ttsVoice': 'test-voice',
          'ttsVoiceLocale': 'es-ES',
          'nudgeEnabled': false,
          'nudgeIntervalMinutes': 10,
          'maxNudgeCount': 5,
          'audioFeedbackEnabled': false,
          'hapticFeedbackEnabled': false,
          'isDarkMode': false,
          'userName': 'Test User',
          'hasCompletedOnboarding': true,
        };
        
        final settings = AppSettings.fromJson(json);
        
        expect(settings.ttsEnabled, isTrue);
        expect(settings.ttsRate, equals(0.8));
        expect(settings.ttsPitch, equals(1.2));
        expect(settings.ttsVolume, equals(0.9));
        expect(settings.ttsLanguage, equals('es-ES'));
        expect(settings.ttsVoice, equals('test-voice'));
        expect(settings.ttsVoiceLocale, equals('es-ES'));
        expect(settings.nudgeEnabled, isFalse);
        expect(settings.nudgeIntervalMinutes, equals(10));
        expect(settings.maxNudgeCount, equals(5));
        expect(settings.audioFeedbackEnabled, isFalse);
        expect(settings.hapticFeedbackEnabled, isFalse);
        expect(settings.isDarkMode, isFalse);
        expect(settings.userName, equals('Test User'));
        expect(settings.hasCompletedOnboarding, isTrue);
      });

      test('should deserialize with null values correctly', () {
        final json = {
          'ttsVoice': null,
          'ttsVoiceLocale': null,
        };
        
        final settings = AppSettings.fromJson(json);
        
        expect(settings.ttsVoice, isNull);
        expect(settings.ttsVoiceLocale, isNull);
      });

      test('should handle missing JSON fields with defaults', () {
        final minimalJson = <String, dynamic>{};
        
        final settings = AppSettings.fromJson(minimalJson);
        
        expect(settings.ttsEnabled, isFalse);
        expect(settings.ttsRate, equals(0.5));
        expect(settings.ttsPitch, equals(1.0));
        expect(settings.ttsVolume, equals(1.0));
        expect(settings.ttsLanguage, equals('en-US'));
        expect(settings.ttsVoice, isNull);
        expect(settings.ttsVoiceLocale, isNull);
        expect(settings.nudgeEnabled, isTrue);
        expect(settings.nudgeIntervalMinutes, equals(5));
        expect(settings.maxNudgeCount, equals(3));
        expect(settings.audioFeedbackEnabled, isTrue);
        expect(settings.hapticFeedbackEnabled, isTrue);
        expect(settings.isDarkMode, isTrue);
        expect(settings.userName, equals(''));
        expect(settings.hasCompletedOnboarding, isFalse);
      });

      test('should handle type conversion for numeric fields', () {
        final json = {
          'ttsRate': 0.8, // double
          'ttsPitch': 1, // int that should become double
          'ttsVolume': '0.9', // string that should become double
          'nudgeIntervalMinutes': 10.0, // double that should become int
          'maxNudgeCount': '5', // string that should become int
        };
        
        final settings = AppSettings.fromJson(json);
        
        expect(settings.ttsRate, equals(0.8));
        expect(settings.ttsPitch, equals(1.0));
        expect(settings.ttsVolume, equals(0.9));
        expect(settings.nudgeIntervalMinutes, equals(10));
        expect(settings.maxNudgeCount, equals(5));
      });

      test('should round-trip serialize/deserialize correctly', () {
        const originalSettings = AppSettings(
          ttsEnabled: true,
          ttsRate: 0.75,
          ttsPitch: 1.25,
          ttsVolume: 0.85,
          ttsLanguage: 'fr-FR',
          ttsVoice: 'french-voice',
          ttsVoiceLocale: 'fr-FR',
          nudgeEnabled: false,
          nudgeIntervalMinutes: 15,
          maxNudgeCount: 7,
          audioFeedbackEnabled: false,
          hapticFeedbackEnabled: false,
          isDarkMode: false,
          userName: 'Round Trip User',
          hasCompletedOnboarding: true,
        );
        
        final json = originalSettings.toJson();
        final deserializedSettings = AppSettings.fromJson(json);
        
        expect(deserializedSettings.ttsEnabled, equals(originalSettings.ttsEnabled));
        expect(deserializedSettings.ttsRate, equals(originalSettings.ttsRate));
        expect(deserializedSettings.ttsPitch, equals(originalSettings.ttsPitch));
        expect(deserializedSettings.ttsVolume, equals(originalSettings.ttsVolume));
        expect(deserializedSettings.ttsLanguage, equals(originalSettings.ttsLanguage));
        expect(deserializedSettings.ttsVoice, equals(originalSettings.ttsVoice));
        expect(deserializedSettings.ttsVoiceLocale, equals(originalSettings.ttsVoiceLocale));
        expect(deserializedSettings.nudgeEnabled, equals(originalSettings.nudgeEnabled));
        expect(deserializedSettings.nudgeIntervalMinutes, equals(originalSettings.nudgeIntervalMinutes));
        expect(deserializedSettings.maxNudgeCount, equals(originalSettings.maxNudgeCount));
        expect(deserializedSettings.audioFeedbackEnabled, equals(originalSettings.audioFeedbackEnabled));
        expect(deserializedSettings.hapticFeedbackEnabled, equals(originalSettings.hapticFeedbackEnabled));
        expect(deserializedSettings.isDarkMode, equals(originalSettings.isDarkMode));
        expect(deserializedSettings.userName, equals(originalSettings.userName));
        expect(deserializedSettings.hasCompletedOnboarding, equals(originalSettings.hasCompletedOnboarding));
      });
    });

    group('Edge Cases', () {
      test('should handle extreme numeric values', () {
        const settings = AppSettings(
          ttsRate: 0.0,
          ttsPitch: 0.0,
          ttsVolume: 0.0,
          nudgeIntervalMinutes: 0,
          maxNudgeCount: 0,
        );
        
        expect(settings.ttsRate, equals(0.0));
        expect(settings.ttsPitch, equals(0.0));
        expect(settings.ttsVolume, equals(0.0));
        expect(settings.nudgeIntervalMinutes, equals(0));
        expect(settings.maxNudgeCount, equals(0));
      });

      test('should handle very large numeric values', () {
        const settings = AppSettings(
          ttsRate: 999.9,
          ttsPitch: 999.9,
          ttsVolume: 999.9,
          nudgeIntervalMinutes: 999999,
          maxNudgeCount: 999999,
        );
        
        expect(settings.ttsRate, equals(999.9));
        expect(settings.ttsPitch, equals(999.9));
        expect(settings.ttsVolume, equals(999.9));
        expect(settings.nudgeIntervalMinutes, equals(999999));
        expect(settings.maxNudgeCount, equals(999999));
      });

      test('should handle very long strings', () {
        final longString = 'a' * 1000;
        final settings = AppSettings(
          ttsLanguage: longString,
          ttsVoice: longString,
          ttsVoiceLocale: longString,
          userName: longString,
        );
        
        expect(settings.ttsLanguage, equals(longString));
        expect(settings.ttsVoice, equals(longString));
        expect(settings.ttsVoiceLocale, equals(longString));
        expect(settings.userName, equals(longString));
      });
    });
  });
}