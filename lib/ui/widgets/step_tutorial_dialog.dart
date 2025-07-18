import 'package:flutter/material.dart';
import '../../models/step_type.dart';

class StepTutorialDialog extends StatelessWidget {
  final StepType stepType;
  final bool isRandomReps;
  final VoidCallback onDismiss;

  const StepTutorialDialog({
    super.key,
    required this.stepType,
    required this.onDismiss,
    this.isRandomReps = false,
  });

  @override
  Widget build(BuildContext context) {
    final tutorialContent = _getTutorialContent(stepType, isRandomReps);

    return AlertDialog(
      title: Row(
        children: [
          Icon(
            _getStepIcon(stepType),
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              tutorialContent.title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            tutorialContent.description,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          if (tutorialContent.tips.isNotEmpty) ...[
            const SizedBox(height: 16),
            ...tutorialContent.tips.map((tip) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.lightbulb_outline,
                    size: 16,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      tip,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            )),
          ],
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 16,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'This tutorial only shows once for each step type.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        FilledButton(
          onPressed: onDismiss,
          child: const Text('Got it!'),
        ),
      ],
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
    }
  }

  TutorialContent _getTutorialContent(StepType stepType, bool isRandomReps) {
    switch (stepType) {
      case StepType.basic:
        return TutorialContent(
          title: 'Basic Task',
          description: 'This is a simple task - just complete it at your own pace.',
          tips: [
            'When you\'re done, tap "Next Step" to continue',
            'Take your time - there\'s no rush!',
          ],
        );

      case StepType.timer:
        return TutorialContent(
          title: 'Timer Step',
          description: 'This step has a timer that counts down automatically.',
          tips: [
            'You can pause the routine if you need a break',
            'The timer will notify you when it\'s done',
            'Focus on the task while the timer runs',
          ],
        );

      case StepType.reps:
        if (isRandomReps) {
          return TutorialContent(
            title: 'Random Reps',
            description: 'This step has a random number of repetitions.',
            tips: [
              'First, tap the die to roll for how many reps to do',
              'Then tap "Complete Rep" each time you finish one',
              'The counter will show your progress',
            ],
          );
        } else {
          return TutorialContent(
            title: 'Repetition Step',
            description: 'This step tracks a fixed number of repetitions.',
            tips: [
              'Tap "Complete Rep" each time you finish one',
              'The counter will show your progress',
              'Complete all reps to finish the step',
            ],
          );
        }

      case StepType.randomChoice:
        return TutorialContent(
          title: 'Random Choice',
          description: 'This step randomly picks from multiple options.',
          tips: [
            'Tap anywhere to roll the die',
            'Don\'t like the result? Tap the die to roll again',
            'This helps when you can\'t decide what to do',
          ],
        );
    }
  }
}

class TutorialContent {
  final String title;
  final String description;
  final List<String> tips;

  TutorialContent({
    required this.title,
    required this.description,
    this.tips = const [],
  });
}