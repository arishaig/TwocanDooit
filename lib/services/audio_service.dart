import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:vibration/vibration.dart';
import 'package:audioplayers/audioplayers.dart';
import '../models/app_settings.dart';

class AudioService {
  static bool _isInitialized = false;
  static AudioPlayer? _audioPlayer;
  static AudioPlayer? _countdownPlayer;
  static AudioPlayer? _musicPlayer;
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

  // Built-in music tracks (note: Flutter assets don't include the 'assets/' prefix)
  static const Map<String, String> _builtInMusicTracks = {
    'Binaural Beats': 'music/binauralBeats/676878__wim__binaural-beats-alpha-to-delta-and-back-mp3.mp3',
    'Calm Meditation': 'music/calm/655395__sergequadrado__meditation.wav',
    'Focus Beats': 'music/focusBeats/593786__szegvari__edm-myst-soundscape-cinematic.wav',
  };

  static Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      _audioPlayer = AudioPlayer();
      _countdownPlayer = AudioPlayer();
      _musicPlayer = AudioPlayer();
      
      // Configure sound effects players to use media channel but with transient focus (brief sounds)
      await _audioPlayer!.setAudioContext(AudioContext(
        android: AudioContextAndroid(
          contentType: AndroidContentType.sonification,
          usageType: AndroidUsageType.media,
          audioFocus: AndroidAudioFocus.gainTransientMayDuck, // Brief focus, allow ducking
        ),
      ));
      
      await _countdownPlayer!.setAudioContext(AudioContext(
        android: AudioContextAndroid(
          contentType: AndroidContentType.sonification,
          usageType: AndroidUsageType.media,
          audioFocus: AndroidAudioFocus.gainTransientMayDuck, // Brief focus, allow ducking
        ),
      ));
      
      // Configure music player to use media channel with persistent focus
      await _musicPlayer!.setAudioContext(AudioContext(
        android: AudioContextAndroid(
          contentType: AndroidContentType.music,
          usageType: AndroidUsageType.media,
          audioFocus: AndroidAudioFocus.gain, // Request and maintain audio focus for music
        ),
      ));
      
      _isInitialized = true;
      debugPrint('AudioService initialized with ducking: transient focus (sounds) + persistent focus (music)');
    } catch (e) {
      debugPrint('Failed to initialize AudioService: $e');
    }
  }

  static Future<void> _playSound(String assetPath, AppSettings settings, {AudioPlayer? player, double volume = 1.0}) async {
    if (!settings.audioFeedbackEnabled) return;
    
    try {
      await initialize();
      final playerToUse = player ?? _audioPlayer!;
      
      // Don't interfere with background music - use a different player
      if (playerToUse == _audioPlayer && _musicPlayer?.state == PlayerState.playing) {
        debugPrint('Background music playing, using separate player for sound effects');
      }
      
      await playerToUse.setVolume(volume);
      await playerToUse.play(AssetSource(assetPath));
      debugPrint('Played sound: $assetPath at volume: $volume, music still playing: ${_musicPlayer?.state == PlayerState.playing}');
    } catch (e) {
      debugPrint('Failed to play sound $assetPath: $e');
    }
  }

  // Forward movement sounds (buttonClick.mp3)
  static Future<void> playButtonClick(AppSettings settings) async {
    try {
      await initialize();
      
      debugPrint('Button click - Audio enabled: ${settings.audioFeedbackEnabled}, Haptic enabled: ${settings.hapticFeedbackEnabled}');
      
      if (settings.hapticFeedbackEnabled && await Vibration.hasVibrator() == true) {
        Vibration.vibrate(duration: 30, amplitude: 80);
        debugPrint('Haptic feedback played for button click');
      }
      
      await _playSound(_buttonClickSound, settings);
    } catch (e) {
      debugPrint('Failed to play button click: $e');
    }
  }

  // Subtle click for next step progression (subtleClick.wav at reduced volume, .mp3 file failed to play)
  static Future<void> playSubtleClick(AppSettings settings) async {
    try {
      await initialize();
      
      debugPrint('Subtle click - Audio enabled: ${settings.audioFeedbackEnabled}, Haptic enabled: ${settings.hapticFeedbackEnabled}');
      
      if (settings.hapticFeedbackEnabled && await Vibration.hasVibrator() == true) {
        Vibration.vibrate(duration: 30, amplitude: 80);
        debugPrint('Haptic feedback played for subtle click');
      }
      
      await _playSound(_subtleClickSound, settings, volume: 0.2); // 20% volume
    } catch (e) {
      debugPrint('Failed to play subtle click: $e');
    }
  }

  // Backward movement sounds (goBack.mp3)
  static Future<void> playGoBack(AppSettings settings) async {
    try {
      await initialize();
      
      if (settings.hapticFeedbackEnabled && await Vibration.hasVibrator() == true) {
        Vibration.vibrate(duration: 40, amplitude: 90);
        debugPrint('Haptic feedback played for go back');
      }
      
      await _playSound(_goBackSound, settings);
    } catch (e) {
      debugPrint('Failed to play go back sound: $e');
    }
  }

  // Step completion (subtle click sound)
  static Future<void> playStepComplete(AppSettings settings) async {
    try {
      await initialize();
      
      if (settings.hapticFeedbackEnabled && await Vibration.hasVibrator() == true) {
        Vibration.vibrate(duration: 60, amplitude: 100);
        debugPrint('Haptic feedback played for step complete');
      }
      
      await _playSound(_subtleClickSound, settings);
    } catch (e) {
      debugPrint('Failed to play step complete: $e');
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
        debugPrint('Haptic feedback played for completion');
      }
      
      await _playSound(_routineCompleteSound, settings);
    } catch (e) {
      debugPrint('Failed to play completion sound: $e');
    }
  }

  // Dice roll (random from 4 dice sounds)
  static Future<void> playDiceRoll(AppSettings settings) async {
    try {
      await initialize();
      
      if (settings.hapticFeedbackEnabled && await Vibration.hasVibrator() == true) {
        Vibration.vibrate(duration: 100, amplitude: 120);
        debugPrint('Haptic feedback played for dice roll');
      }
      
      final randomDiceSound = _diceSounds[_random.nextInt(_diceSounds.length)];
      await _playSound(randomDiceSound, settings);
    } catch (e) {
      debugPrint('Failed to play dice roll sound: $e');
    }
  }


  // Timer countdown (countdown.mp3 - 5 seconds long)
  static Future<void> playCountdown(AppSettings settings) async {
    try {
      await initialize();
      
      if (settings.hapticFeedbackEnabled && await Vibration.hasVibrator() == true) {
        Vibration.vibrate(duration: 50, amplitude: 100);
        debugPrint('Haptic feedback played for countdown start');
      }
      
      await _playSound(_countdownSound, settings, player: _countdownPlayer);
    } catch (e) {
      debugPrint('Failed to play countdown sound: $e');
    }
  }

  // Stop countdown if timer is interrupted
  static Future<void> stopCountdown() async {
    try {
      await _countdownPlayer?.stop();
      debugPrint('Countdown sound stopped');
    } catch (e) {
      debugPrint('Failed to stop countdown: $e');
    }
  }

  // Legacy method for backward compatibility (uses countdown now)
  static Future<void> playTickSound([AppSettings? settings]) async {
    if (settings == null) return;
    await playCountdown(settings);
  }

  // Background music methods
  static List<String> get builtInMusicTrackNames => _builtInMusicTracks.keys.toList();

  static Future<void> startBackgroundMusic(String trackName, {bool isBuiltIn = true, double volume = 0.3}) async {
    try {
      await initialize();
      await stopBackgroundMusic(); // Stop any current music
      
      if (isBuiltIn) {
        final assetPath = _builtInMusicTracks[trackName] ?? _builtInMusicTracks.values.first;
        debugPrint('Playing built-in track: $trackName -> $assetPath');
        await _musicPlayer!.setVolume(volume);
        await _musicPlayer!.setReleaseMode(ReleaseMode.loop);
        await _musicPlayer!.play(AssetSource(assetPath));
      } else {
        // For user-added tracks, trackName would be the file path
        debugPrint('Playing custom track: $trackName');
        await _musicPlayer!.setVolume(volume);
        await _musicPlayer!.setReleaseMode(ReleaseMode.loop);
        await _musicPlayer!.play(DeviceFileSource(trackName));
      }
      
      debugPrint('Started background music: $trackName at volume: $volume, state: ${_musicPlayer!.state}');
      
      // Reset mute state when starting new music
      _isMusicMuted = false;
      _previousMusicVolume = volume;
    } catch (e) {
      debugPrint('Failed to start background music: $e');
    }
  }

  static Future<void> fadeOutBackgroundMusic({Duration fadeDuration = const Duration(seconds: 2)}) async {
    try {
      if (_musicPlayer == null) return;
      
      const steps = 20;
      const stepDuration = Duration(milliseconds: 100);
      const initialVolume = 0.3; // Use the volume we set when starting music
      final volumeStep = initialVolume / steps;
      
      for (int i = steps; i > 0; i--) {
        await _musicPlayer!.setVolume(volumeStep * i);
        await Future.delayed(stepDuration);
      }
      
      await _musicPlayer!.stop();
      // Reset mute state when music fades out
      _isMusicMuted = false;
      debugPrint('Background music faded out');
    } catch (e) {
      debugPrint('Failed to fade out background music: $e');
    }
  }

  static Future<void> stopBackgroundMusic() async {
    try {
      await _musicPlayer?.stop();
      // Reset mute state when music stops
      _isMusicMuted = false;
      debugPrint('Background music stopped');
    } catch (e) {
      debugPrint('Failed to stop background music: $e');
    }
  }

  static Future<void> playMusicPreview(String trackName, {bool isBuiltIn = true, double volume = 0.5}) async {
    try {
      await initialize();
      await stopBackgroundMusic(); // Stop any current music
      
      String assetPath;
      if (isBuiltIn) {
        assetPath = _builtInMusicTracks[trackName] ?? _builtInMusicTracks.values.first;
        debugPrint('Previewing built-in track: $trackName -> $assetPath');
        await _musicPlayer!.setSource(AssetSource(assetPath));
      } else {
        debugPrint('Previewing custom track: $trackName');
        await _musicPlayer!.setSource(DeviceFileSource(trackName));
      }
      
      await _musicPlayer!.setVolume(volume);
      await _musicPlayer!.setReleaseMode(ReleaseMode.stop); // Don't loop for preview
      await _musicPlayer!.resume();
      
      debugPrint('Started music preview: $trackName at volume: $volume');
      
      // Stop preview after 10 seconds
      Timer(const Duration(seconds: 10), () async {
        await stopBackgroundMusic();
        debugPrint('Preview stopped after 10 seconds');
      });
    } catch (e) {
      debugPrint('Failed to play music preview: $e');
    }
  }

  static bool get isMusicPlaying {
    return _musicPlayer?.state == PlayerState.playing;
  }

  static bool _isMusicMuted = false;
  static double _previousMusicVolume = 0.3;

  static bool get isMusicMuted => _isMusicMuted;

  static Future<void> muteMusic() async {
    try {
      if (_musicPlayer == null || !isMusicPlaying) return;
      
      // Store current volume before muting (use the volume we set when starting music)
      await _musicPlayer!.setVolume(0.0);
      _isMusicMuted = true;
      debugPrint('Music muted, previous volume: $_previousMusicVolume');
    } catch (e) {
      debugPrint('Failed to mute music: $e');
    }
  }

  static Future<void> unmuteMusic() async {
    try {
      if (_musicPlayer == null || !isMusicPlaying) return;
      
      await _musicPlayer!.setVolume(_previousMusicVolume);
      _isMusicMuted = false;
      debugPrint('Music unmuted, restored volume: $_previousMusicVolume');
    } catch (e) {
      debugPrint('Failed to unmute music: $e');
    }
  }

  static Future<void> toggleMusicMute() async {
    if (_isMusicMuted) {
      await unmuteMusic();
    } else {
      await muteMusic();
    }
  }

  static void dispose() {
    _audioPlayer?.dispose();
    _countdownPlayer?.dispose();
    _musicPlayer?.dispose();
    _audioPlayer = null;
    _countdownPlayer = null;
    _musicPlayer = null;
    _isInitialized = false;
  }
}