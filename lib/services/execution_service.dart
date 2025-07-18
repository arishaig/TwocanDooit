import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import '../models/routine.dart';
import '../models/step.dart';
import '../models/step_type.dart';
import '../models/app_settings.dart';
import '../models/routine_run.dart';
import 'notification_service.dart';
import 'tts_service.dart';
import 'audio_service.dart';
import 'storage_service.dart';
import '../main.dart';

class ExecutionSession {
  final Routine routine;
  int currentStepIndex;
  bool isPaused;
  DateTime startTime;
  Duration? pausedDuration;

  ExecutionSession({
    required this.routine,
    this.currentStepIndex = 0,
    this.isPaused = false,
    DateTime? startTime,
    this.pausedDuration,
  }) : startTime = startTime ?? DateTime.now();

  Step? get currentStep {
    if (currentStepIndex >= routine.steps.length) return null;
    return routine.steps[currentStepIndex];
  }

  bool get isCompleted => currentStepIndex >= routine.steps.length;

  double get progress {
    if (routine.steps.isEmpty) return 1.0;
    return currentStepIndex / routine.steps.length;
  }

  Duration get totalElapsed {
    final elapsed = DateTime.now().difference(startTime);
    return pausedDuration != null ? elapsed - pausedDuration! : elapsed;
  }
}

class ExecutionService {
  static ExecutionSession? _currentSession;
  static RoutineRun? _currentRun;
  static Timer? _timer;
  static Timer? _sessionTimer;
  static int _remainingSeconds = 0;
  static AppSettings? _currentSettings;
  static DateTime? _pauseStartTime;
  
  // Stream controllers
  static final StreamController<ExecutionSession> _sessionController =
      StreamController<ExecutionSession>.broadcast();
  static final StreamController<int> _timerController =
      StreamController<int>.broadcast();
  static final StreamController<String> _eventController =
      StreamController<String>.broadcast();

  // Streams
  static Stream<ExecutionSession> get sessionStream => _sessionController.stream;
  static Stream<int> get timerStream => _timerController.stream;
  static Stream<String> get eventStream => _eventController.stream;

  static ExecutionSession? get currentSession => _currentSession;
  static bool get isRunning => _currentSession != null;
  static bool get isPaused => _currentSession?.isPaused ?? false;

  static Future<void> startRoutine(Routine routine, {AppSettings? settings}) async {
    await stopExecution();
    
    _currentSettings = settings;
    
    // Reset all steps
    for (var step in routine.steps) {
      step.reset();
    }
    
    // Create run tracking record
    _currentRun = RoutineRun(
      routineId: routine.id,
      totalSteps: routine.steps.length,
    );
    
    _currentSession = ExecutionSession(routine: routine);
    _sessionController.add(_currentSession!);
    _eventController.add('Routine started: ${routine.name}');
    
    // Start session duration timer to update elapsed time display
    _startSessionTimer();
    
    // Start background music if enabled
    if (routine.musicEnabled && routine.musicTrack != null) {
      await AudioService.startBackgroundMusic(
        routine.musicTrack!,
        isBuiltIn: routine.isBuiltInTrack,
        volume: 0.3, // 30% volume so it doesn't interfere with other sounds
      );
    }
    
    // Announce routine start
    if (_currentSettings != null && routine.voiceEnabled) {
      await TTSService.speak('Starting routine: ${routine.name}', _currentSettings!, routine: routine);
    }
    
    await _processCurrentStep();
  }

  static Future<void> pauseExecution() async {
    if (_currentSession == null || _currentSession!.isPaused) return;
    
    _currentSession!.isPaused = true;
    _pauseStartTime = DateTime.now();
    _timer?.cancel();
    _sessionController.add(_currentSession!);
    _eventController.add('Execution paused');
  }

  static Future<void> resumeExecution({AppSettings? settings}) async {
    if (_currentSession == null || !_currentSession!.isPaused) return;
    
    if (settings != null) _currentSettings = settings;
    
    // Calculate and add paused time
    if (_pauseStartTime != null && _currentRun != null) {
      final pausedTime = DateTime.now().difference(_pauseStartTime!);
      _currentRun!.addPausedTime(pausedTime);
      _pauseStartTime = null;
    }
    
    _currentSession!.isPaused = false;
    _sessionController.add(_currentSession!);
    _eventController.add('Execution resumed');
    
    await _processCurrentStep();
  }

  static Future<void> nextStep({AppSettings? settings}) async {
    if (_currentSession == null) return;
    
    if (settings != null) _currentSettings = settings;
    
    final currentStep = _currentSession!.currentStep;
    currentStep?.complete();
    
    // Play step completion feedback
    if (_currentSettings != null) {
      await AudioService.playStepComplete(_currentSettings!);
    }
    
    _currentSession!.currentStepIndex++;
    _timer?.cancel();
    await AudioService.stopCountdown(); // Stop countdown sound if playing
    NotificationService.stopNudgeTimer();
    
    // Update run progress
    if (_currentRun != null) {
      _currentRun!.updateProgress(_currentSession!.currentStepIndex);
      await StorageService.saveRoutineRun(_currentRun!);
    }
    
    if (_currentSession!.isCompleted) {
      _eventController.add('Routine completed!');
      
      // Mark run as completed and save
      if (_currentRun != null) {
        _currentRun!.complete();
        await StorageService.saveRoutineRun(_currentRun!);
      }
      
      // Stop background music immediately (no fade) and play completion sound simultaneously
      if (AudioService.isMusicPlaying) {
        await AudioService.stopBackgroundMusic();
      }
      
      // Start completion sound and voice announcement simultaneously
      if (_currentSettings != null) {
        AudioService.playCompletion(_currentSettings!); // Don't await - let it play async
      }
      if (_currentSettings != null && _currentSession!.routine.voiceEnabled) {
        await TTSService.speak('Routine completed! Great job!', _currentSettings!, routine: _currentSession!.routine);
      }
      
      await stopExecution();
    } else {
      _sessionController.add(_currentSession!);
      await _processCurrentStep();
    }
  }

  static Future<void> previousStep({AppSettings? settings}) async {
    if (_currentSession == null || _currentSession!.currentStepIndex <= 0) return;
    
    if (settings != null) _currentSettings = settings;
    
    _currentSession!.currentStepIndex--;
    _timer?.cancel();
    await AudioService.stopCountdown(); // Stop countdown sound if playing
    NotificationService.stopNudgeTimer();
    
    final currentStep = _currentSession!.currentStep;
    currentStep?.reset();
    
    _sessionController.add(_currentSession!);
    await _processCurrentStep();
  }

  static Future<void> stopExecution() async {
    // Save abandoned run if there was one in progress
    if (_currentRun != null && _currentSession != null && !_currentSession!.isCompleted) {
      _currentRun!.updateProgress(_currentSession!.currentStepIndex);
      _currentRun!.abandon();
      await StorageService.saveRoutineRun(_currentRun!);
    }
    
    _timer?.cancel();
    _timer = null;
    _sessionTimer?.cancel();
    _sessionTimer = null;
    await AudioService.stopCountdown(); // Stop countdown sound if playing
    await AudioService.stopBackgroundMusic(); // Stop background music if playing
    _currentSession = null;
    _currentRun = null;
    _pauseStartTime = null;
    _remainingSeconds = 0;
    if (!_eventController.isClosed) {
      _eventController.add('Execution stopped');
    }
  }

  static Future<void> completeCurrentStep({AppSettings? settings}) async {
    if (_currentSession == null) return;
    
    if (settings != null) _currentSettings = settings;
    
    final currentStep = _currentSession!.currentStep;
    if (currentStep == null) return;
    
    switch (currentStep.type) {
      case StepType.reps:
        currentStep.repsCompleted++;
        if (currentStep.repsCompleted >= currentStep.repsTarget) {
          await nextStep();
        } else {
          _sessionController.add(_currentSession!);
        }
        break;
      default:
        await nextStep();
        break;
    }
  }

  static Future<String> selectRandomChoice(List<String> choices) async {
    if (choices.isEmpty) return '';
    
    final random = Random();
    final selectedChoice = choices[random.nextInt(choices.length)];
    
    _eventController.add('Selected: $selectedChoice');
    
    // Announce the selected choice
    if (_currentSettings != null && _currentSession?.routine.voiceEnabled == true) {
      await TTSService.speak('Selected: $selectedChoice', _currentSettings!, routine: _currentSession?.routine);
    }
    
    return selectedChoice;
  }

  static Future<int> selectRandomReps(int minReps, int maxReps) async {
    if (minReps > maxReps) return minReps;
    
    final random = Random();
    final selectedReps = minReps + random.nextInt(maxReps - minReps + 1);
    
    _eventController.add('Rolled: $selectedReps reps');
    
    // Announce the selected reps
    if (_currentSettings != null && _currentSession?.routine.voiceEnabled == true) {
      await TTSService.speak('Rolled $selectedReps reps', _currentSettings!, routine: _currentSession?.routine);
    }
    
    return selectedReps;
  }

  static Future<void> _processCurrentStep() async {
    if (_currentSession == null || _currentSession!.isPaused) return;
    
    final currentStep = _currentSession!.currentStep;
    if (currentStep == null) return;
    
    // Announce the current step
    if (_currentSettings != null && _currentSession!.routine.voiceEnabled && currentStep.voiceEnabled) {
      String stepText = currentStep.title;
      if (currentStep.description.isNotEmpty) {
        stepText += '. ${currentStep.description}';
      }
      await TTSService.speak(stepText, _currentSettings!, routine: _currentSession!.routine);
    }
    
    // Start nudge timer for this step if settings available (but not for timer steps)
    if (_currentSettings != null && _currentSettings!.nudgeEnabled && currentStep.type != StepType.timer) {
      await NotificationService.startNudgeTimer(_currentSettings!, currentStep);
    }
    
    switch (currentStep.type) {
      case StepType.timer:
        await _startTimer(currentStep.timerDuration);
        break;
      case StepType.reps:
        // Check if reps need to be randomized
        if (currentStep.randomizeReps) {
          // Don't auto-select, wait for user to roll dice
        }
        break;
      case StepType.randomChoice:
        // Don't auto-select, wait for user to roll
        break;
      default:
        break;
    }
  }

  static Future<void> _startTimer(int seconds) async {
    _remainingSeconds = seconds;
    _timerController.add(_remainingSeconds);
    
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_currentSession?.isPaused ?? false) {
        return;
      }
      
      _remainingSeconds--;
      _timerController.add(_remainingSeconds);
      
      // Play countdown sound when 5 seconds remaining
      if (_remainingSeconds == 5 && _currentSettings != null) {
        debugPrint('Starting countdown sound for last 5 seconds');
        AudioService.playCountdown(_currentSettings!);
      }
      
      if (_remainingSeconds <= 0) {
        timer.cancel();
        AudioService.stopCountdown(); // Stop countdown sound
        _eventController.add('Timer finished');
        
        final currentStep = _currentSession?.currentStep;
        
        // Send notification if app is not in foreground
        if (currentStep != null && !TwocanDooitApp.isAppInForeground) {
          debugPrint('App is in background, sending timer completion notification for: ${currentStep.title}');
          NotificationService.showTimerCompletedNotification(currentStep.title);
        } else {
          debugPrint('App is in foreground, skipping notification');
        }
        
        // Announce timer completion
        if (_currentSettings != null && _currentSession?.routine.voiceEnabled == true) {
          TTSService.speak('Timer finished', _currentSettings!, routine: _currentSession?.routine);
        }
        
        nextStep();
      }
    });
  }

  static void _startSessionTimer() {
    _sessionTimer?.cancel(); // Cancel any existing session timer
    
    // Emit session updates every second to keep elapsed time display current
    _sessionTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_currentSession != null && !(_currentSession?.isPaused ?? false)) {
        // Only emit if session is active and not paused
        _sessionController.add(_currentSession!);
      }
    });
  }

  static void dispose() {
    _timer?.cancel();
    _sessionTimer?.cancel();
    NotificationService.dispose();
    AudioService.dispose();
    _sessionController.close();
    _timerController.close();
    _eventController.close();
  }
}