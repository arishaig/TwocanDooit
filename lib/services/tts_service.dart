import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../models/app_settings.dart';
import '../models/routine.dart';

class TTSService {
  static final FlutterTts _flutterTts = FlutterTts();
  static bool _isInitialized = false;

  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await _flutterTts.setSharedInstance(true);
      
      // Only set iOS audio category on iOS platform
      try {
        await _flutterTts.setIosAudioCategory(
          IosTextToSpeechAudioCategory.playback,
          [
            IosTextToSpeechAudioCategoryOptions.allowBluetooth,
            IosTextToSpeechAudioCategoryOptions.allowBluetoothA2DP,
            IosTextToSpeechAudioCategoryOptions.mixWithOthers,
          ],
          IosTextToSpeechAudioMode.spokenAudio,
        );
      } catch (e) {
        // iOS audio category setting failed - this is normal on non-iOS platforms
        debugPrint('iOS audio category not available (normal on non-iOS): $e');
      }
      
      _isInitialized = true;
      debugPrint('TTS initialization completed successfully');
    } catch (e) {
      debugPrint('TTS initialization failed: $e');
    }
  }

  static Future<void> configure(AppSettings settings, {Routine? routine}) async {
    await initialize();

    try {
      // Use global settings for rate, pitch, volume, and language
      await _flutterTts.setSpeechRate(settings.ttsRate);
      await _flutterTts.setPitch(settings.ttsPitch);
      await _flutterTts.setVolume(settings.ttsVolume);
      await _flutterTts.setLanguage(settings.ttsLanguage);
      
      // Set voice if specified
      if (settings.ttsVoice != null && settings.ttsVoice!.isNotEmpty) {
        final voiceLocale = settings.ttsVoiceLocale ?? settings.ttsLanguage;
        await _flutterTts.setVoice({"name": settings.ttsVoice!, "locale": voiceLocale});
      }
    } catch (e) {
      debugPrint('TTS configuration failed: $e');
    }
  }

  static Future<void> speak(String text, AppSettings settings, {Routine? routine}) async {
    // Check if TTS is globally enabled and routine voice is enabled
    if (!settings.ttsEnabled || text.trim().isEmpty) return;
    if (routine != null && !routine.voiceEnabled) return;

    try {
      await configure(settings, routine: routine);
      await _flutterTts.speak(text);
    } catch (e) {
      debugPrint('TTS speak failed: $e');
    }
  }

  static Future<void> stop() async {
    try {
      await _flutterTts.stop();
    } catch (e) {
      debugPrint('TTS stop failed: $e');
    }
  }

  static Future<void> pause() async {
    try {
      await _flutterTts.pause();
    } catch (e) {
      debugPrint('TTS pause failed: $e');
    }
  }

  static Future<List<dynamic>> getLanguages() async {
    try {
      return await _flutterTts.getLanguages ?? [];
    } catch (e) {
      debugPrint('TTS getLanguages failed: $e');
      return [];
    }
  }

  static Future<List<dynamic>> getVoices() async {
    try {
      return await _flutterTts.getVoices ?? [];
    } catch (e) {
      debugPrint('TTS getVoices failed: $e');
      return [];
    }
  }

  static bool get isPlaying => false;

  static void setCompletionHandler(VoidCallback callback) {
    _flutterTts.setCompletionHandler(() => callback());
  }

  static void setErrorHandler(Function(String) callback) {
    _flutterTts.setErrorHandler((msg) => callback(msg));
  }

  static void dispose() {
    _flutterTts.stop();
  }
}