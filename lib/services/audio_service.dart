import 'dart:math';
import 'package:vibration/vibration.dart';
import 'package:audioplayers/audioplayers.dart';
import '../models/app_settings.dart';

class AudioService {
  static bool _isInitialized = false;
  static AudioPlayer? _audioPlayer;
  static AudioPlayer? _countdownPlayer;
  static final Random _random = Random();

  // Audio file paths
  static const String _buttonClickSound = 'audio/buttonClick/click.mp3';
  static const String _subtleClickSound = 'audio/subtleButtonClick/subtleClick.wav';
  static const String _goBackSound = 'audio/goBack/goBack.mp3';
  static const String _routineCompleteSound = 'audio/routineComplete/complete.mp3';
  static const String _countdownSound = 'audio/countdown/countdown.mp3';
  static const List<String> _diceSounds = [
    'audio/dice/647921__bw2801__roll-dice-d.mp3',
    'audio/dice/647922__bw2801__roll-dice-c.mp3',
    'audio/dice/647923__bw2801__roll-dice-b.mp3',
    'audio/dice/647924__bw2801__roll-dice-a.mp3',
  ];

  static Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      _audioPlayer = AudioPlayer();
      _countdownPlayer = AudioPlayer();
      _isInitialized = true;
      print('AudioService initialized with custom sounds');
    } catch (e) {
      print('Failed to initialize AudioService: $e');
    }
  }

  static Future<void> _playSound(String assetPath, AppSettings settings, {AudioPlayer? player, double volume = 1.0}) async {
    if (!settings.audioFeedbackEnabled) return;
    
    try {
      await initialize();
      final playerToUse = player ?? _audioPlayer!;
      await playerToUse.setVolume(volume);
      await playerToUse.play(AssetSource(assetPath));
      print('Played sound: $assetPath at volume: $volume');
    } catch (e) {
      print('Failed to play sound $assetPath: $e');
    }
  }

  // Forward movement sounds (buttonClick.mp3)
  static Future<void> playButtonClick(AppSettings settings) async {
    try {
      await initialize();
      
      print('Button click - Audio enabled: ${settings.audioFeedbackEnabled}, Haptic enabled: ${settings.hapticFeedbackEnabled}');
      
      if (settings.hapticFeedbackEnabled && await Vibration.hasVibrator() == true) {
        Vibration.vibrate(duration: 30, amplitude: 80);
        print('Haptic feedback played for button click');
      }
      
      await _playSound(_buttonClickSound, settings);
    } catch (e) {
      print('Failed to play button click: $e');
    }
  }

  // Subtle click for next step progression (subtleClick.wav at reduced volume, .mp3 file failed to play)
  static Future<void> playSubtleClick(AppSettings settings) async {
    try {
      await initialize();
      
      print('Subtle click - Audio enabled: ${settings.audioFeedbackEnabled}, Haptic enabled: ${settings.hapticFeedbackEnabled}');
      
      if (settings.hapticFeedbackEnabled && await Vibration.hasVibrator() == true) {
        Vibration.vibrate(duration: 30, amplitude: 80);
        print('Haptic feedback played for subtle click');
      }
      
      await _playSound(_subtleClickSound, settings, volume: 0.2); // 20% volume
    } catch (e) {
      print('Failed to play subtle click: $e');
    }
  }

  // Backward movement sounds (goBack.mp3)
  static Future<void> playGoBack(AppSettings settings) async {
    try {
      await initialize();
      
      if (settings.hapticFeedbackEnabled && await Vibration.hasVibrator() == true) {
        Vibration.vibrate(duration: 40, amplitude: 90);
        print('Haptic feedback played for go back');
      }
      
      await _playSound(_goBackSound, settings);
    } catch (e) {
      print('Failed to play go back sound: $e');
    }
  }

  // Step completion (subtle click sound)
  static Future<void> playStepComplete(AppSettings settings) async {
    try {
      await initialize();
      
      if (settings.hapticFeedbackEnabled && await Vibration.hasVibrator() == true) {
        Vibration.vibrate(duration: 60, amplitude: 100);
        print('Haptic feedback played for step complete');
      }
      
      await _playSound(_subtleClickSound, settings);
    } catch (e) {
      print('Failed to play step complete: $e');
    }
  }

  // Routine completion (complete.mp3)
  static Future<void> playCompletion(AppSettings settings) async {
    try {
      await initialize();
      
      if (settings.hapticFeedbackEnabled && await Vibration.hasVibrator() == true) {
        // Triple tap for completion
        for (int i = 0; i < 3; i++) {
          Vibration.vibrate(duration: 80, amplitude: 150);
          if (i < 2) await Future.delayed(const Duration(milliseconds: 100));
        }
        print('Haptic feedback played for completion');
      }
      
      await _playSound(_routineCompleteSound, settings);
    } catch (e) {
      print('Failed to play completion sound: $e');
    }
  }

  // Dice roll (random from 4 dice sounds)
  static Future<void> playDiceRoll(AppSettings settings) async {
    try {
      await initialize();
      
      if (settings.hapticFeedbackEnabled && await Vibration.hasVibrator() == true) {
        Vibration.vibrate(duration: 100, amplitude: 120);
        print('Haptic feedback played for dice roll');
      }
      
      final randomDiceSound = _diceSounds[_random.nextInt(_diceSounds.length)];
      await _playSound(randomDiceSound, settings);
    } catch (e) {
      print('Failed to play dice roll sound: $e');
    }
  }

  // Timer countdown (countdown.mp3 - 5 seconds long)
  static Future<void> playCountdown(AppSettings settings) async {
    try {
      await initialize();
      
      if (settings.hapticFeedbackEnabled && await Vibration.hasVibrator() == true) {
        Vibration.vibrate(duration: 50, amplitude: 100);
        print('Haptic feedback played for countdown start');
      }
      
      await _playSound(_countdownSound, settings, player: _countdownPlayer);
    } catch (e) {
      print('Failed to play countdown sound: $e');
    }
  }

  // Stop countdown if timer is interrupted
  static Future<void> stopCountdown() async {
    try {
      await _countdownPlayer?.stop();
      print('Countdown sound stopped');
    } catch (e) {
      print('Failed to stop countdown: $e');
    }
  }

  // Legacy method for backward compatibility (uses countdown now)
  static Future<void> playTickSound([AppSettings? settings]) async {
    if (settings == null) return;
    await playCountdown(settings);
  }

  static void dispose() {
    _audioPlayer?.dispose();
    _countdownPlayer?.dispose();
    _audioPlayer = null;
    _countdownPlayer = null;
    _isInitialized = false;
  }
}