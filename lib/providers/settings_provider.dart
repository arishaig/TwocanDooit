import 'package:flutter/foundation.dart';
import '../models/app_settings.dart';
import '../services/storage_service.dart';
import '../services/tts_service.dart';

class SettingsProvider with ChangeNotifier {
  AppSettings _settings = const AppSettings();
  bool _isLoading = false;
  String? _error;

  AppSettings get settings => _settings;
  bool get isLoading => _isLoading;
  String? get error => _error;

  SettingsProvider() {
    _initializeSettings();
  }

  Future<void> _initializeSettings() async {
    debugPrint('Settings: Starting initialization, loading = true');
    _isLoading = true;
    // Don't notify listeners yet to avoid initial flashing
    
    try {
      final settingsData = await StorageService.loadSettings();
      debugPrint('Settings: Loaded data: ${settingsData.toString()}');
      _settings = settingsData.isNotEmpty 
          ? AppSettings.fromJson(settingsData)
          : const AppSettings();
      debugPrint('Settings: Final settings - hasCompletedOnboarding: ${_settings.hasCompletedOnboarding}, themeMode: ${_settings.themeMode}');
      _error = null;
      
      // Initialize TTS with current settings
      await TTSService.configure(_settings);
    } catch (e) {
      debugPrint('Settings: Error loading: $e');
      _error = 'Failed to load settings: $e';
    } finally {
      debugPrint('Settings: Finished initialization, loading = false');
      _isLoading = false;
      // Only notify listeners once at the end
      notifyListeners();
    }
  }

  Future<void> loadSettings() async {
    _setLoading(true);
    try {
      final settingsData = await StorageService.loadSettings();
      _settings = settingsData.isNotEmpty 
          ? AppSettings.fromJson(settingsData)
          : const AppSettings();
      _error = null;
      
      // Initialize TTS with current settings
      await TTSService.configure(_settings);
    } catch (e) {
      _error = 'Failed to load settings: $e';
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateSettings(AppSettings newSettings) async {
    try {
      _settings = newSettings;
      await StorageService.saveSettings(_settings.toJson());
      
      // Update TTS configuration
      await TTSService.configure(_settings);
      
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to save settings: $e';
      notifyListeners();
    }
  }

  Future<void> updateTTSEnabled(bool enabled) async {
    await updateSettings(_settings.copyWith(ttsEnabled: enabled));
  }

  Future<void> updateTTSRate(double rate) async {
    await updateSettings(_settings.copyWith(ttsRate: rate));
  }

  Future<void> updateTTSPitch(double pitch) async {
    await updateSettings(_settings.copyWith(ttsPitch: pitch));
  }

  Future<void> updateTTSVolume(double volume) async {
    await updateSettings(_settings.copyWith(ttsVolume: volume));
  }

  Future<void> updateTTSLanguage(String language) async {
    await updateSettings(_settings.copyWith(ttsLanguage: language));
  }

  Future<void> updateTTSVoice(String? voice, {String? voiceLocale}) async {
    await updateSettings(_settings.copyWith(
      ttsVoice: voice, 
      ttsVoiceLocale: voiceLocale,
    ));
  }

  Future<void> updateNudgeEnabled(bool enabled) async {
    await updateSettings(_settings.copyWith(nudgeEnabled: enabled));
  }

  Future<void> updateNudgeInterval(int minutes) async {
    await updateSettings(_settings.copyWith(nudgeIntervalMinutes: minutes));
  }

  Future<void> updateMaxNudgeCount(int count) async {
    await updateSettings(_settings.copyWith(maxNudgeCount: count));
  }

  Future<void> updateAudioFeedbackEnabled(bool enabled) async {
    await updateSettings(_settings.copyWith(audioFeedbackEnabled: enabled));
  }

  Future<void> updateHapticFeedbackEnabled(bool enabled) async {
    await updateSettings(_settings.copyWith(hapticFeedbackEnabled: enabled));
  }

  Future<void> updateThemeMode(AppThemeMode themeMode) async {
    await updateSettings(_settings.copyWith(themeMode: themeMode));
  }

  Future<void> updateReducedAnimations(bool enabled) async {
    await updateSettings(_settings.copyWith(reducedAnimations: enabled));
  }

  Future<void> updateFocusMode(bool enabled) async {
    await updateSettings(_settings.copyWith(focusMode: enabled));
  }

  Future<void> updateSimplifiedUI(bool enabled) async {
    await updateSettings(_settings.copyWith(simplifiedUI: enabled));
  }

  Future<void> updateUserName(String userName) async {
    await updateSettings(_settings.copyWith(userName: userName));
  }

  Future<void> completeOnboarding() async {
    await updateSettings(_settings.copyWith(hasCompletedOnboarding: true));
  }

  Future<void> resetOnboarding() async {
    await updateSettings(_settings.copyWith(hasCompletedOnboarding: false));
  }

  // Tutorial state methods
  Future<void> markBasicStepTutorialSeen() async {
    await updateSettings(_settings.copyWith(hasSeenBasicStepTutorial: true));
  }

  Future<void> markTimerStepTutorialSeen() async {
    await updateSettings(_settings.copyWith(hasSeenTimerStepTutorial: true));
  }

  Future<void> markRepsStepTutorialSeen() async {
    await updateSettings(_settings.copyWith(hasSeenRepsStepTutorial: true));
  }

  Future<void> markRandomRepsStepTutorialSeen() async {
    await updateSettings(_settings.copyWith(hasSeenRandomRepsStepTutorial: true));
  }

  Future<void> markRandomChoiceStepTutorialSeen() async {
    await updateSettings(_settings.copyWith(hasSeenRandomChoiceStepTutorial: true));
  }

  Future<void> resetAllTutorials() async {
    await updateSettings(_settings.copyWith(
      hasSeenBasicStepTutorial: false,
      hasSeenTimerStepTutorial: false,
      hasSeenRepsStepTutorial: false,
      hasSeenRandomRepsStepTutorial: false,
      hasSeenRandomChoiceStepTutorial: false,
    ));
  }

  // Shake detection settings
  Future<void> updateShakeToRollEnabled(bool enabled) async {
    await updateSettings(_settings.copyWith(shakeToRollEnabled: enabled));
  }

  Future<void> updateShakeInitialSensitivity(double sensitivity) async {
    await updateSettings(_settings.copyWith(shakeInitialSensitivity: sensitivity));
  }

  Future<void> updateShakeRerollSensitivity(double sensitivity) async {
    await updateSettings(_settings.copyWith(shakeRerollSensitivity: sensitivity));
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