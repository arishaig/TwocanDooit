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

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
}