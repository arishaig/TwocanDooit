import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vibration/vibration.dart';
import '../../models/routine.dart';
import '../../models/step_type.dart';
import '../../models/app_settings.dart';
import '../../providers/execution_provider.dart';
import '../../providers/settings_provider.dart';
import '../../services/audio_service.dart';
import '../widgets/dice_widget.dart';

class ExecutionScreen extends StatefulWidget {
  final Routine routine;

  const ExecutionScreen({super.key, required this.routine});

  @override
  State<ExecutionScreen> createState() => _ExecutionScreenState();
}

class _ExecutionScreenState extends State<ExecutionScreen> {
  bool _showRollResult = false;
  Timer? _rollResultTimer;
  
  // Helper method to get current settings
  AppSettings get _currentSettings => context.read<SettingsProvider>().settings;
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final settings = context.read<SettingsProvider>().settings;
      context.read<ExecutionProvider>().startRoutine(widget.routine, settings: settings);
    });
  }

  @override
  void dispose() {
    _rollResultTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.routine.name),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => _showExitDialog(context),
        ),
      ),
      body: Consumer<ExecutionProvider>(
        builder: (context, executionProvider, child) {
          final session = executionProvider.currentSession;
          if (session == null) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (session.isCompleted) {
            // Reset roll result state when routine completes
            if (_showRollResult) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                setState(() {
                  _showRollResult = false;
                });
              });
            }
            return _buildCompletionView(context);
          }

          final currentStep = session.currentStep;
          if (currentStep == null) {
            return const Center(
              child: Text('No current step'),
            );
          }

          return Stack(
            children: [
              Column(
                children: [
              // Progress indicator with larger height for mobile
              Container(
                height: 6,
                child: LinearProgressIndicator(
                  value: session.progress,
                  backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
                ),
              ),
              
              // Progress info with larger text and padding
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                color: Theme.of(context).colorScheme.surfaceVariant,
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Step ${session.currentStepIndex + 1} of ${session.routine.steps.length}',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '${executionProvider.sessionDurationDisplay}',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: (session.currentStepIndex + 1) / session.routine.steps.length,
                      backgroundColor: Colors.transparent,
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.7),
                    ),
                  ],
                ),
              ),
              
              // Main content with better mobile spacing
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Expanded(
                        child: _buildStepContent(context, currentStep, executionProvider),
                      ),
                      const SizedBox(height: 20),
                      _buildControls(context, executionProvider),
                    ],
                  ),
                ),
              ),
                ],
              ),
              
              // Floating Action Buttons for Navigation
              _buildNavigationFABs(context, executionProvider, session, currentStep),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStepContent(BuildContext context, currentStep, ExecutionProvider executionProvider) {
    final isRandomChoiceWaitingForRoll = currentStep.type == StepType.randomChoice && 
                                        currentStep.selectedChoice == null && 
                                        !executionProvider.isRolling;
    
    final isRandomRepsWaitingForRoll = currentStep.type == StepType.reps &&
                                      currentStep.randomizeReps &&
                                      currentStep.repsTarget == currentStep.repsMin &&
                                      !executionProvider.isRolling;
    
    Widget content = Card(
      child: Padding(
        padding: const EdgeInsets.all(28), // Larger padding for mobile
        child: Column(
          children: [
            Icon(
              _getStepIcon(currentStep.type),
              size: 56, // Larger icon for mobile
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 20),
            Text(
              currentStep.title,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith( // Larger text
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            if (currentStep.description.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                currentStep.description,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontSize: 18, // Larger description text
                ),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 32),
            
            // Step-specific content
            Expanded(
              child: Center(
                child: _buildTypeSpecificContent(context, currentStep, executionProvider),
              ),
            ),
          ],
        ),
      ),
    );

    // Wrap with GestureDetector for full viewport tapping when waiting for initial roll
    if (isRandomChoiceWaitingForRoll) {
      return GestureDetector(
        onTap: () => _rollForChoice(context, currentStep, executionProvider),
        child: content,
      );
    }
    
    if (isRandomRepsWaitingForRoll) {
      return GestureDetector(
        onTap: () => _rollForReps(context, currentStep, executionProvider),
        child: content,
      );
    }
    
    return content;
  }

  Widget _buildTypeSpecificContent(BuildContext context, currentStep, ExecutionProvider executionProvider) {
    switch (currentStep.type) {
      case StepType.timer:
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              executionProvider.timerDisplay,
              style: Theme.of(context).textTheme.displayLarge?.copyWith(
                fontWeight: FontWeight.bold,
                fontFeatures: [const FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Timer running...',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        );
        
      case StepType.reps:
        // Check if this is a random reps step that hasn't been rolled yet
        if (currentStep.randomizeReps && currentStep.repsTarget == currentStep.repsMin) {
          // Show dice interface for rolling random reps
          final isRolling = executionProvider.isRolling;
          final optionCount = currentStep.repsMax - currentStep.repsMin + 1;
          
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isRolling) ...[
                DiceWidget(
                  isRolling: true,
                  result: null,
                  optionCount: optionCount,
                ),
                const SizedBox(height: 24),
                Text(
                  'Rolling for reps...',
                  style: Theme.of(context).textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
              ] else ...[
                DiceWidget(
                  isRolling: false,
                  result: null,
                  optionCount: optionCount,
                ),
                const SizedBox(height: 24),
                Text(
                  'Roll for ${currentStep.repsMin}-${currentStep.repsMax} reps',
                  style: Theme.of(context).textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Tap the dice to roll',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          );
        } else if (currentStep.randomizeReps && _showRollResult) {
          // Show the rolled result prominently before transitioning to rep counting
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${currentStep.repsTarget}',
                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                  fontSize: 72,
                ),
              ).animate().scale(
                duration: 2000.ms,
                begin: const Offset(1.5, 1.5),
                end: const Offset(1.0, 1.0),
                curve: Curves.elasticOut,
              ),
              const SizedBox(height: 16),
              Text(
                'You rolled ${currentStep.repsTarget} reps!',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ).animate().fadeIn(delay: 500.ms, duration: 1000.ms),
              const SizedBox(height: 32),
              Text(
                'Starting rep counting...',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ).animate().fadeIn(delay: 1500.ms, duration: 500.ms),
            ],
          );
        } else {
          // Normal reps display (either non-random or ready for rep counting)
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${currentStep.repsCompleted}',
                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              Text(
                'of ${currentStep.repsTarget}${currentStep.randomizeReps ? ' (rolled)' : ''}',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () => executionProvider.completeCurrentStep(settings: _currentSettings),
                icon: const Icon(Icons.add),
                label: const Text('Complete Rep'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(200, 56),
                ),
              ),
            ],
          );
        }
        
      case StepType.randomChoice:
        final isRolling = executionProvider.isRolling;
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isRolling) ...[
              // Show rolling animation whether it's initial roll or reroll
              DiceWidget(
                isRolling: true,
                result: null,
                optionCount: currentStep.choices.length,
              ),
              const SizedBox(height: 24),
              Text(
                'Rolling dice...',
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
            ] else if (currentStep.selectedChoice == null) ...[
              // Initial state - no choice selected yet
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.primary,
                    width: 2,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.casino,
                      size: 48,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Tap anywhere to roll',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Choose from: ${currentStep.choices.join(', ')}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ] else ...[
              // Result state - choice has been selected
              Column(
                children: [
                  GestureDetector(
                    onTap: () => _reroll(context, currentStep, executionProvider),
                    child: DiceWidget(
                      isRolling: false,
                      result: currentStep.choices.indexOf(currentStep.selectedChoice!) + 1,
                      optionCount: currentStep.choices.length,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Selected:',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    currentStep.selectedChoice!,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Tap the dice to reroll',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ],
          ],
        );
        
      case StepType.basic:
      default:
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.task_alt,
              size: 80,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Complete this task when ready',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
          ],
        );
    }
  }

  Widget _buildControls(BuildContext context, ExecutionProvider executionProvider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20), // Larger padding for mobile
        child: Column(
          children: [
            // Navigation buttons on top row
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: executionProvider.currentStepIndex > 0
                        ? () async {
                            await AudioService.playGoBack(_currentSettings);
                            executionProvider.previousStep(settings: _currentSettings);
                          }
                        : null,
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 56),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.arrow_back),
                        SizedBox(width: 8),
                        Text('Previous'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: FilledButton(
                    onPressed: () async {
                      await AudioService.playSubtleClick(_currentSettings);
                      executionProvider.nextStep(settings: _currentSettings);
                    },
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 56),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Next Step'),
                        SizedBox(width: 8),
                        Icon(Icons.arrow_forward),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Pause/Resume button on bottom
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () async {
                  await AudioService.playButtonClick(_currentSettings);
                  if (executionProvider.isPaused) {
                    executionProvider.resumeExecution(settings: _currentSettings);
                  } else {
                    executionProvider.pauseExecution();
                  }
                },
                style: FilledButton.styleFrom(
                  minimumSize: const Size(0, 56), // Larger touch target
                  backgroundColor: executionProvider.isPaused 
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.secondary,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(executionProvider.isPaused ? Icons.play_arrow : Icons.pause),
                    const SizedBox(width: 8),
                    Text(executionProvider.isPaused ? 'Resume' : 'Pause'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompletionView(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.celebration,
            size: 80,
            color: Theme.of(context).colorScheme.primary,
          ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),
          const SizedBox(height: 24),
          Text(
            'Routine Complete!',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ).animate().fadeIn(delay: 300.ms),
          const SizedBox(height: 8),
          Text(
            'Great job completing "${widget.routine.name}"',
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 600.ms),
          const SizedBox(height: 32),
          FilledButton.icon(
            onPressed: () async {
              await AudioService.playGoBack(_currentSettings);
              Navigator.of(context).pop();
            },
            icon: const Icon(Icons.home),
            label: const Text('Back to Home'),
            style: FilledButton.styleFrom(
              minimumSize: const Size(200, 56),
            ),
          ).animate().fadeIn(delay: 900.ms),
        ],
      ),
    );
  }

  IconData _getStepIcon(StepType type) {
    switch (type) {
      case StepType.basic:
        return Icons.task_alt;
      case StepType.timer:
        return Icons.timer;
      case StepType.reps:
        return Icons.repeat;
      case StepType.randomChoice:
        return Icons.casino;
      case StepType.variableParameter:
        return Icons.tune;
    }
  }

  Future<void> _rollForChoice(BuildContext context, currentStep, ExecutionProvider executionProvider) async {
    // Play dice roll sound
    await AudioService.playDiceRoll(_currentSettings);
    
    // Set rolling state
    executionProvider.setRolling(true);
    
    // Add delay for animation
    await Future.delayed(const Duration(milliseconds: 1500));
    
    // Use the step's weighted selection method
    final choice = currentStep.selectRandomChoice();
    currentStep.selectedChoice = choice;
    
    executionProvider.setRolling(false);
    
    // Force UI update
    setState(() {});
  }

  Future<void> _rollForReps(BuildContext context, currentStep, ExecutionProvider executionProvider) async {
    // Play dice roll sound
    await AudioService.playDiceRoll(_currentSettings);
    
    final reps = await executionProvider.selectRandomReps(currentStep.repsMin, currentStep.repsMax);
    currentStep.repsTarget = reps;
    
    // Show the roll result animation
    setState(() {
      _showRollResult = true;
    });
    
    // Hide the roll result after 2.5 seconds and transition to rep counting
    _rollResultTimer?.cancel();
    _rollResultTimer = Timer(const Duration(milliseconds: 2500), () {
      if (mounted) {
        setState(() {
          _showRollResult = false;
        });
      }
    });
  }

  Future<void> _reroll(BuildContext context, currentStep, ExecutionProvider executionProvider) async {
    // Play dice roll sound
    await AudioService.playDiceRoll(_currentSettings);
    
    // Set rolling state
    executionProvider.setRolling(true);
    
    // Add delay for animation
    await Future.delayed(const Duration(milliseconds: 1500));
    
    // Use the step's weighted selection method
    final choice = currentStep.selectRandomChoice();
    currentStep.selectedChoice = choice;
    
    executionProvider.setRolling(false);
    
    // Force UI update
    setState(() {});
  }

  void _showExitDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              const Expanded(child: Text('Exit Routine?')),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          content: const Text('Are you sure you want to exit this routine? Your progress will be lost.'),
          actions: [
            FilledButton(
              onPressed: () async {
                await AudioService.playGoBack(_currentSettings);
                context.read<ExecutionProvider>().stopExecution();
                Navigator.of(context).pop(); // Close dialog
                Navigator.of(context).pop(); // Close execution screen
              },
              child: const Text('Exit'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildNavigationFABs(BuildContext context, ExecutionProvider executionProvider, dynamic session, dynamic currentStep) {
    // Don't show FABs during dice animations or timer countdowns
    final shouldHideFABs = executionProvider.isRolling || 
                          (currentStep.type == StepType.timer && executionProvider.remainingSeconds <= 5 && executionProvider.remainingSeconds > 0);
    
    if (shouldHideFABs) {
      return const SizedBox.shrink();
    }
    
    return Stack(
      children: [
        // Left side tap zone - Previous Step
        if (session.currentStepIndex > 0)
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: GestureDetector(
              onTap: () async {
                await AudioService.playSubtleClick(_currentSettings);
                await executionProvider.previousStep(settings: _currentSettings);
              },
              child: Container(
                width: 80, // Wide tap zone
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      Theme.of(context).colorScheme.primary.withOpacity(0.1),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface.withOpacity(0.8),
                      borderRadius: const BorderRadius.only(
                        topRight: Radius.circular(12),
                        bottomRight: Radius.circular(12),
                      ),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Icon(
                      Icons.chevron_left,
                      color: Theme.of(context).colorScheme.primary,
                      size: 24,
                    ),
                  ),
                ),
              ),
            ),
          ),
        
        // Right side tap zone - Next Step  
        if (session.currentStepIndex < session.routine.steps.length - 1)
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            child: GestureDetector(
              onTap: () async {
                await AudioService.playSubtleClick(_currentSettings);
                await executionProvider.nextStep(settings: _currentSettings);
              },
              child: Container(
                width: 80, // Wide tap zone
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerRight,
                    end: Alignment.centerLeft,
                    colors: [
                      Theme.of(context).colorScheme.primary.withOpacity(0.1),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface.withOpacity(0.8),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(12),
                        bottomLeft: Radius.circular(12),
                      ),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Icon(
                      Icons.chevron_right,
                      color: Theme.of(context).colorScheme.primary,
                      size: 24,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}