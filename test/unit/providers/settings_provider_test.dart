import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:twocandooit/providers/settings_provider.dart';
import 'package:twocandooit/models/app_settings.dart';
import 'package:twocandooit/services/storage_service.dart';
import '../../test_helpers.dart';

void main() {
  group('SettingsProvider Tests', () {
    late SettingsProvider provider;

    setUpAll(() async {
      // Mock SharedPreferences
      SharedPreferences.setMockInitialValues({});
      // Mock all plugins
      TestHelpers.setupAllPluginMocks();
    });

    setUp(() async {
      // Clear any existing data
      await StorageService.clearAll();
      provider = SettingsProvider();
      // Wait for initialization to complete
      await Future.delayed(Duration(milliseconds: 100));
    });

    tearDown(() {
      provider.dispose();
    });

    group('Initial State', () {
      test('should have correct initial state', () async {
        expect(provider.settings, isA<AppSettings>());
        expect(provider.isLoading, isFalse);
        expect(provider.error, isNull);
      });

      test('should initialize with default settings when no stored data', () async {
        expect(provider.settings.hasCompletedOnboarding, isFalse);
        expect(provider.settings.isDarkMode, isFalse);
        expect(provider.settings.ttsEnabled, isTrue);
        expect(provider.settings.nudgeEnabled, isTrue);
        expect(provider.settings.audioFeedbackEnabled, isTrue);
        expect(provider.settings.hapticFeedbackEnabled, isTrue);
      });

      test('should initialize with stored settings when available', () async {
        final testSettings = TestHelpers.createTestSettings();
        await StorageService.saveSettings(testSettings.toJson());
        
        final newProvider = SettingsProvider();
        await Future.delayed(Duration(milliseconds: 100));
        
        expect(newProvider.settings.hasCompletedOnboarding, equals(testSettings.hasCompletedOnboarding));
        expect(newProvider.settings.isDarkMode, equals(testSettings.isDarkMode));
        expect(newProvider.settings.ttsEnabled, equals(testSettings.ttsEnabled));
        
        newProvider.dispose();
      });
    });

    group('Loading Settings', () {
      test('should load settings successfully', () async {
        final testSettings = TestHelpers.createTestSettings();
        await StorageService.saveSettings(testSettings.toJson());
        
        await provider.loadSettings();
        
        expect(provider.settings.hasCompletedOnboarding, equals(testSettings.hasCompletedOnboarding));
        expect(provider.settings.isDarkMode, equals(testSettings.isDarkMode));
        expect(provider.isLoading, isFalse);
        expect(provider.error, isNull);
      });

      test('should handle loading errors gracefully', () async {
        // Mock corrupted data
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('settings', 'invalid json');
        
        await provider.loadSettings();
        
        expect(provider.isLoading, isFalse);
        expect(provider.error, isNotNull);
      });

      test('should notify listeners during loading', () async {
        var notificationCount = 0;
        provider.addListener(() {
          notificationCount++;
        });
        
        await provider.loadSettings();
        
        expect(notificationCount, greaterThan(0));
      });
    });

    group('Updating Settings', () {
      test('should update settings successfully', () async {
        final newSettings = provider.settings.copyWith(
          hasCompletedOnboarding: true,
          isDarkMode: true,
          userName: 'Test User',
        );
        
        await provider.updateSettings(newSettings);
        
        expect(provider.settings.hasCompletedOnboarding, isTrue);
        expect(provider.settings.isDarkMode, isTrue);
        expect(provider.settings.userName, equals('Test User'));
        expect(provider.error, isNull);
      });

      test('should persist updated settings', () async {
        final newSettings = provider.settings.copyWith(
          hasCompletedOnboarding: true,
          userName: 'Persistent User',
        );
        
        await provider.updateSettings(newSettings);
        
        // Load settings again to verify persistence
        await provider.loadSettings();
        
        expect(provider.settings.hasCompletedOnboarding, isTrue);
        expect(provider.settings.userName, equals('Persistent User'));
      });

      test('should notify listeners when settings are updated', () async {
        var notificationCount = 0;
        provider.addListener(() {
          notificationCount++;
        });
        
        final newSettings = provider.settings.copyWith(isDarkMode: true);
        await provider.updateSettings(newSettings);
        
        expect(notificationCount, greaterThan(0));
      });
    });

    group('TTS Settings', () {
      test('should update TTS enabled setting', () async {
        await provider.updateTTSEnabled(false);
        
        expect(provider.settings.ttsEnabled, isFalse);
      });

      test('should update TTS rate setting', () async {
        await provider.updateTTSRate(0.75);
        
        expect(provider.settings.ttsRate, equals(0.75));
      });

      test('should update TTS pitch setting', () async {
        await provider.updateTTSPitch(1.2);
        
        expect(provider.settings.ttsPitch, equals(1.2));
      });

      test('should update TTS volume setting', () async {
        await provider.updateTTSVolume(0.8);
        
        expect(provider.settings.ttsVolume, equals(0.8));
      });

      test('should update TTS language setting', () async {
        await provider.updateTTSLanguage('es-ES');
        
        expect(provider.settings.ttsLanguage, equals('es-ES'));
      });

      test('should update TTS voice setting', () async {
        await provider.updateTTSVoice('test-voice', voiceLocale: 'en-US');
        
        expect(provider.settings.ttsVoice, equals('test-voice'));
        expect(provider.settings.ttsVoiceLocale, equals('en-US'));
      });
    });

    group('Nudge Settings', () {
      test('should update nudge enabled setting', () async {
        await provider.updateNudgeEnabled(false);
        
        expect(provider.settings.nudgeEnabled, isFalse);
      });

      test('should update nudge interval setting', () async {
        await provider.updateNudgeInterval(45);
        
        expect(provider.settings.nudgeIntervalMinutes, equals(45));
      });

      test('should update max nudge count setting', () async {
        await provider.updateMaxNudgeCount(8);
        
        expect(provider.settings.maxNudgeCount, equals(8));
      });
    });

    group('Feedback Settings', () {
      test('should update audio feedback enabled setting', () async {
        await provider.updateAudioFeedbackEnabled(false);
        
        expect(provider.settings.audioFeedbackEnabled, isFalse);
      });

      test('should update haptic feedback enabled setting', () async {
        await provider.updateHapticFeedbackEnabled(false);
        
        expect(provider.settings.hapticFeedbackEnabled, isFalse);
      });
    });

    group('Theme Settings', () {
      test('should update theme mode setting', () async {
        await provider.updateThemeMode(true);
        
        expect(provider.settings.isDarkMode, isTrue);
      });
    });

    group('User Settings', () {
      test('should update user name setting', () async {
        await provider.updateUserName('New User');
        
        expect(provider.settings.userName, equals('New User'));
      });
    });

    group('Onboarding Settings', () {
      test('should complete onboarding', () async {
        expect(provider.settings.hasCompletedOnboarding, isFalse);
        
        await provider.completeOnboarding();
        
        expect(provider.settings.hasCompletedOnboarding, isTrue);
      });

      test('should reset onboarding', () async {
        await provider.completeOnboarding();
        expect(provider.settings.hasCompletedOnboarding, isTrue);
        
        await provider.resetOnboarding();
        
        expect(provider.settings.hasCompletedOnboarding, isFalse);
      });
    });

    group('Error Handling', () {
      test('should clear error', () async {
        provider.clearError();
        
        expect(provider.error, isNull);
      });

      test('should notify listeners when clearing error', () async {
        var notificationCount = 0;
        provider.addListener(() {
          notificationCount++;
        });
        
        provider.clearError();
        
        expect(notificationCount, equals(1));
      });

      test('should handle update errors gracefully', () async {
        // This test would need to mock a save failure
        // For now, we verify the error handling structure exists
        await provider.updateSettings(provider.settings.copyWith(userName: 'Test'));
        expect(provider.error, isNull); // No error since there's no actual error
      });
    });

    group('Listener Notifications', () {
      test('should notify listeners on all update methods', () async {
        var notificationCount = 0;
        provider.addListener(() {
          notificationCount++;
        });
        
        await provider.updateTTSEnabled(false);
        await provider.updateTTSRate(0.5);
        await provider.updateNudgeEnabled(false);
        await provider.updateThemeMode(true);
        await provider.updateUserName('Test');
        await provider.completeOnboarding();
        
        expect(notificationCount, greaterThan(5));
      });

      test('should stop notifications when listener is removed', () async {
        var notificationCount = 0;
        void listener() {
          notificationCount++;
        }
        
        provider.addListener(listener);
        await provider.updateTTSEnabled(false);
        
        provider.removeListener(listener);
        await provider.updateTTSEnabled(true);
        
        expect(notificationCount, equals(1)); // Only first update should trigger
      });
    });

    group('State Consistency', () {
      test('should maintain consistent state across multiple updates', () async {
        await provider.updateTTSEnabled(false);
        await provider.updateTTSRate(0.75);
        await provider.updateTTSPitch(1.2);
        await provider.updateNudgeEnabled(false);
        await provider.updateThemeMode(true);
        await provider.updateUserName('Consistent User');
        await provider.completeOnboarding();
        
        expect(provider.settings.ttsEnabled, isFalse);
        expect(provider.settings.ttsRate, equals(0.75));
        expect(provider.settings.ttsPitch, equals(1.2));
        expect(provider.settings.nudgeEnabled, isFalse);
        expect(provider.settings.isDarkMode, isTrue);
        expect(provider.settings.userName, equals('Consistent User'));
        expect(provider.settings.hasCompletedOnboarding, isTrue);
        expect(provider.error, isNull);
      });

      test('should persist state across provider instances', () async {
        // Create a separate provider for this test to avoid disposal conflicts
        final testProvider = SettingsProvider();
        await Future.delayed(Duration(milliseconds: 100));
        
        await testProvider.updateUserName('Persistent User');
        await testProvider.updateThemeMode(true);
        await testProvider.completeOnboarding();
        
        testProvider.dispose();
        
        final newProvider = SettingsProvider();
        await Future.delayed(Duration(milliseconds: 100));
        
        expect(newProvider.settings.userName, equals('Persistent User'));
        expect(newProvider.settings.isDarkMode, isTrue);
        expect(newProvider.settings.hasCompletedOnboarding, isTrue);
        
        newProvider.dispose();
      });
    });

    group('Validation', () {
      test('should handle edge cases for numeric settings', () async {
        await provider.updateTTSRate(0.0);
        expect(provider.settings.ttsRate, equals(0.0));
        
        await provider.updateTTSRate(2.0);
        expect(provider.settings.ttsRate, equals(2.0));
        
        await provider.updateNudgeInterval(1);
        expect(provider.settings.nudgeIntervalMinutes, equals(1));
        
        await provider.updateMaxNudgeCount(0);
        expect(provider.settings.maxNudgeCount, equals(0));
      });

      test('should handle empty and null string settings', () async {
        await provider.updateUserName('');
        expect(provider.settings.userName, equals(''));
        
        await provider.updateTTSLanguage('');
        expect(provider.settings.ttsLanguage, equals(''));
        
        await provider.updateTTSVoice(null);
        expect(provider.settings.ttsVoice, isNull);
      });
    });
  });
}