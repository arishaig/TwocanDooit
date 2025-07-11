import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core_platform_interface/firebase_core_platform_interface.dart';
import 'package:twocandooit/providers/routine_provider.dart';
import 'package:twocandooit/providers/settings_provider.dart';
import 'package:twocandooit/providers/execution_provider.dart';
import 'package:twocandooit/models/routine.dart';
import 'package:twocandooit/models/step.dart' as DooitStep;
import 'package:twocandooit/models/step_type.dart';
import 'package:twocandooit/models/app_settings.dart';

/// Helper class for creating test fixtures and common test utilities
class TestHelpers {
  /// Sets up Firebase mocks for testing
  static void setupFirebaseMocks() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/firebase_core'),
      (MethodCall methodCall) async {
        return <String, dynamic>{
          'name': 'test',
          'options': <String, dynamic>{
            'apiKey': 'test-api-key',
            'appId': 'test-app-id',
            'messagingSenderId': 'test-sender-id',
            'projectId': 'test-project-id',
          },
        };
      },
    );
  }
  /// Creates a basic test routine with sample steps
  static Routine createTestRoutine({
    String name = 'Test Routine',
    String description = 'A routine for testing',
    String category = 'Test',
    bool includeSteps = true,
  }) {
    final routine = Routine(
      name: name,
      description: description,
      category: category,
      voiceEnabled: false, // Disable voice for tests
      musicEnabled: false, // Disable music for tests
    );

    if (includeSteps) {
      routine.addStep(DooitStep.Step(
        title: 'Basic Step',
        type: StepType.basic,
        description: 'A simple test step',
      ));
      
      routine.addStep(DooitStep.Step(
        title: 'Timer Step',
        type: StepType.timer,
        timerDuration: 30, // Short duration for tests
      ));
      
      routine.addStep(DooitStep.Step(
        title: 'Reps Step',
        type: StepType.reps,
        repsTarget: 5, // Small number for tests
      ));
    }

    return routine;
  }

  /// Creates a test widget tree with all required providers
  static Widget createTestApp({
    required Widget child,
    List<Routine>? initialRoutines,
    AppSettings? initialSettings,
  }) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) {
            final provider = RoutineProvider();
            if (initialRoutines != null) {
              for (final routine in initialRoutines) {
                provider.routines.add(routine);
              }
            }
            return provider;
          },
        ),
        ChangeNotifierProvider(
          create: (_) => SettingsProvider()..loadSettings(),
        ),
        ChangeNotifierProvider(
          create: (_) => ExecutionProvider(),
        ),
      ],
      child: MaterialApp(
        home: child,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        ),
      ),
    );
  }

  /// Creates a routine with music enabled for testing
  static Routine createMusicRoutine() {
    return Routine(
      name: 'Music Routine',
      description: 'A routine with background music',
      musicEnabled: true,
      musicTrack: 'Calm Meditation',
      isBuiltInTrack: true,
    );
  }

  /// Creates a routine with random steps for testing
  static Routine createRandomRoutine() {
    final routine = Routine(
      name: 'Random Routine',
      description: 'A routine with random elements',
    );

    routine.addStep(DooitStep.Step(
      title: 'Random Choice',
      type: StepType.randomChoice,
      choices: ['Option A', 'Option B', 'Option C'],
    ));

    routine.addStep(DooitStep.Step(
      title: 'Random Reps',
      type: StepType.reps,
      randomizeReps: true,
      repsMin: 5,
      repsMax: 15,
      repsTarget: 5, // Starts at min
    ));

    return routine;
  }

  /// Helper to find widgets by text with a timeout
  static Future<void> waitForText(
    WidgetTester tester,
    String text, {
    Duration timeout = const Duration(seconds: 5),
  }) async {
    final endTime = DateTime.now().add(timeout);
    
    while (DateTime.now().isBefore(endTime)) {
      await tester.pump(const Duration(milliseconds: 100));
      
      if (find.text(text).evaluate().isNotEmpty) {
        return;
      }
    }
    
    throw Exception('Text "$text" not found within timeout');
  }

  /// Helper to find widgets by type with a timeout
  static Future<void> waitForWidget<T extends Widget>(
    WidgetTester tester, {
    Duration timeout = const Duration(seconds: 5),
  }) async {
    final endTime = DateTime.now().add(timeout);
    
    while (DateTime.now().isBefore(endTime)) {
      await tester.pump(const Duration(milliseconds: 100));
      
      if (find.byType(T).evaluate().isNotEmpty) {
        return;
      }
    }
    
    throw Exception('Widget of type $T not found within timeout');
  }

  /// Helper to simulate a complete routine execution
  static Future<void> executeRoutineSteps(
    WidgetTester tester,
    int stepCount,
  ) async {
    for (int i = 0; i < stepCount; i++) {
      // Wait for the step to load
      await tester.pumpAndSettle();
      
      // Find and tap the next step button
      final nextButton = find.text('Next Step');
      if (nextButton.evaluate().isNotEmpty) {
        await tester.tap(nextButton);
        await tester.pumpAndSettle();
      }
    }
  }

  /// Creates default app settings for testing
  static AppSettings createTestSettings({
    bool audioEnabled = false, // Disabled for tests
    bool hapticEnabled = false, // Disabled for tests
    bool ttsEnabled = false, // Disabled for tests
    bool nudgeEnabled = false, // Disabled for tests
  }) {
    return AppSettings(
      audioFeedbackEnabled: audioEnabled,
      hapticFeedbackEnabled: hapticEnabled,
      ttsEnabled: ttsEnabled,
      nudgeEnabled: nudgeEnabled,
      nudgeIntervalMinutes: 5,
    );
  }

  /// Test app class that doesn't initialize Firebase
  static Widget createTestTwocanApp() {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => RoutineProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => ExecutionProvider()),
      ],
      child: MaterialApp(
        title: 'TwocanDooit Test',
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        ),
        home: const Scaffold(
          body: Center(child: Text('Test App')),
        ),
      ),
    );
  }
}