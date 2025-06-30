import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/routine.dart';
import '../models/step.dart';
import '../models/app_settings.dart';
import '../services/execution_service.dart';

class ExecutionProvider with ChangeNotifier {
  ExecutionSession? _currentSession;
  int _remainingSeconds = 0;
  String _lastEvent = '';
  bool _isRolling = false;
  
  StreamSubscription<ExecutionSession>? _sessionSubscription;
  StreamSubscription<int>? _timerSubscription;
  StreamSubscription<String>? _eventSubscription;

  ExecutionSession? get currentSession => _currentSession;
  bool get isRunning => ExecutionService.isRunning;
  bool get isPaused => ExecutionService.isPaused;
  bool get isRolling => _isRolling;
  int get remainingSeconds => _remainingSeconds;
  String get lastEvent => _lastEvent;
  
  Routine? get currentRoutine => _currentSession?.routine;
  Step? get currentStep => _currentSession?.currentStep;
  int get currentStepIndex => _currentSession?.currentStepIndex ?? 0;
  double get progress => _currentSession?.progress ?? 0.0;

  ExecutionProvider() {
    _subscribeToStreams();
  }

  void _subscribeToStreams() {
    _sessionSubscription = ExecutionService.sessionStream.listen((session) {
      _currentSession = session;
      notifyListeners();
    });

    _timerSubscription = ExecutionService.timerStream.listen((seconds) {
      _remainingSeconds = seconds;
      notifyListeners();
    });

    _eventSubscription = ExecutionService.eventStream.listen((event) {
      _lastEvent = event;
      notifyListeners();
    });
  }

  Future<void> startRoutine(Routine routine, {AppSettings? settings}) async {
    await ExecutionService.startRoutine(routine, settings: settings);
  }

  Future<void> pauseExecution() async {
    await ExecutionService.pauseExecution();
  }

  Future<void> resumeExecution({AppSettings? settings}) async {
    await ExecutionService.resumeExecution(settings: settings);
  }

  Future<void> nextStep({AppSettings? settings}) async {
    await ExecutionService.nextStep(settings: settings);
  }

  Future<void> previousStep({AppSettings? settings}) async {
    await ExecutionService.previousStep(settings: settings);
  }

  Future<void> stopExecution() async {
    await ExecutionService.stopExecution();
    _currentSession = null;
    _remainingSeconds = 0;
    _lastEvent = '';
    _isRolling = false;
    notifyListeners();
  }

  Future<void> completeCurrentStep({AppSettings? settings}) async {
    await ExecutionService.completeCurrentStep(settings: settings);
  }

  Future<String> selectRandomChoice(List<String> choices) async {
    _isRolling = true;
    notifyListeners();
    
    // Add a delay for the rolling animation
    await Future.delayed(const Duration(milliseconds: 1500));
    
    final result = await ExecutionService.selectRandomChoice(choices);
    
    _isRolling = false;
    notifyListeners();
    
    return result;
  }

  Future<int> selectRandomReps(int minReps, int maxReps) async {
    _isRolling = true;
    notifyListeners();
    
    // Add a delay for the rolling animation
    await Future.delayed(const Duration(milliseconds: 1500));
    
    final result = await ExecutionService.selectRandomReps(minReps, maxReps);
    
    _isRolling = false;
    notifyListeners();
    
    return result;
  }

  void setRolling(bool rolling) {
    _isRolling = rolling;
    notifyListeners();
  }

  String get timerDisplay {
    final minutes = _remainingSeconds ~/ 60;
    final seconds = _remainingSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  String get sessionDurationDisplay {
    if (_currentSession == null) return '00:00';
    
    final duration = _currentSession!.totalElapsed;
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _sessionSubscription?.cancel();
    _timerSubscription?.cancel();
    _eventSubscription?.cancel();
    super.dispose();
  }
}