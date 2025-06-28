import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../../models/routine.dart';
import '../../models/step.dart' as model_step;
import '../../models/step_type.dart';
import '../../providers/routine_provider.dart';
import '../../services/audio_service.dart';

class RoutineEditorScreen extends StatefulWidget {
  final Routine? routine;

  const RoutineEditorScreen({super.key, this.routine});

  @override
  State<RoutineEditorScreen> createState() => _RoutineEditorScreenState();
}

class _RoutineEditorScreenState extends State<RoutineEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _categoryController;
  late List<model_step.Step> _steps;
  late bool _voiceEnabled;
  late bool _musicEnabled;
  late String? _selectedMusicTrack;
  late bool _isBuiltInTrack;
  String? _currentlyPreviewing;

  bool get _isEditing => widget.routine != null;

  @override
  void initState() {
    super.initState();
    final routine = widget.routine;
    _nameController = TextEditingController(text: routine?.name ?? '');
    _descriptionController = TextEditingController(text: routine?.description ?? '');
    _categoryController = TextEditingController(text: routine?.category ?? '');
    _steps = routine?.steps.map((s) => s.copyWith()).toList() ?? [];
    _voiceEnabled = routine?.voiceEnabled ?? false;
    _musicEnabled = routine?.musicEnabled ?? false;
    _selectedMusicTrack = routine?.musicTrack;
    _isBuiltInTrack = routine?.isBuiltInTrack ?? true;
    _currentlyPreviewing = null;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _categoryController.dispose();
    // Stop any playing preview
    AudioService.stopBackgroundMusic();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Routine' : 'New Routine'),
        actions: [
          TextButton(
            onPressed: _saveRoutine,
            child: const Text('Save'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20), // Larger padding for mobile
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Routine Name',
                hintText: 'Enter routine name',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a routine name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
                hintText: 'Enter description',
                border: OutlineInputBorder(),
              ),
              maxLines: 4,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _categoryController,
              decoration: const InputDecoration(
                labelText: 'Category (optional)',
                hintText: 'e.g., Daily, Health, Work',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Voice Announcements'),
              subtitle: const Text('Read steps aloud during execution'),
              value: _voiceEnabled,
              onChanged: (value) {
                setState(() {
                  _voiceEnabled = value;
                });
              },
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Background Music'),
              subtitle: const Text('Play music during routine execution'),
              value: _musicEnabled,
              onChanged: (value) {
                setState(() {
                  _musicEnabled = value;
                });
              },
            ),
            if (_musicEnabled) ...[
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Music Selection',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Built-in Tracks',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...AudioService.builtInMusicTrackNames.map((trackName) {
                        return Row(
                          children: [
                            Expanded(
                              child: RadioListTile<String>(
                                title: Text(trackName),
                                value: trackName,
                                groupValue: _isBuiltInTrack ? _selectedMusicTrack : null,
                                onChanged: (value) {
                                  setState(() {
                                    _selectedMusicTrack = value;
                                    _isBuiltInTrack = true;
                                  });
                                },
                              ),
                            ),
                            IconButton(
                              onPressed: () => _togglePreview(trackName),
                              icon: Icon(_currentlyPreviewing == trackName ? Icons.stop : Icons.play_arrow),
                              tooltip: _currentlyPreviewing == trackName ? 'Stop preview' : 'Preview $trackName',
                            ),
                          ],
                        );
                      }),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Text(
                            'Custom Track',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const Spacer(),
                          TextButton.icon(
                            onPressed: _pickMusicFile,
                            icon: const Icon(Icons.music_note),
                            label: const Text('Choose File'),
                          ),
                        ],
                      ),
                      if (!_isBuiltInTrack && _selectedMusicTrack != null) ...[
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surfaceVariant,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Selected:',
                                      style: Theme.of(context).textTheme.bodySmall,
                                    ),
                                    Text(
                                      _selectedMusicTrack!.split('/').last,
                                      style: Theme.of(context).textTheme.bodyMedium,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                onPressed: () => _togglePreview(_selectedMusicTrack!),
                                icon: Icon(_currentlyPreviewing == _selectedMusicTrack ? Icons.stop : Icons.play_arrow),
                                tooltip: _currentlyPreviewing == _selectedMusicTrack ? 'Stop preview' : 'Preview track',
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 24),
            Row(
              children: [
                Text(
                  'Steps',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const Spacer(),
                FilledButton.icon(
                  onPressed: _addStep,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Step'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(120, 48),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_steps.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Icon(
                        Icons.list_alt,
                        size: 48,
                        color: Theme.of(context).colorScheme.outline,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'No steps added yet',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Add steps to build your routine',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              ReorderableListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _steps.length,
                onReorder: _reorderSteps,
                itemBuilder: (context, index) {
                  final step = _steps[index];
                  return Card(
                    key: ValueKey(step.id),
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: Icon(_getStepIcon(step.type)),
                      title: Text(step.title),
                      subtitle: Text(step.displayText),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () => _editStep(index),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () => _deleteStep(index),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
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

  void _addStep() {
    showDialog(
      context: context,
      builder: (context) => _StepEditorDialog(
        onSave: (step) {
          setState(() {
            _steps.add(step);
          });
        },
      ),
    );
  }

  void _editStep(int index) {
    showDialog(
      context: context,
      builder: (context) => _StepEditorDialog(
        step: _steps[index],
        onSave: (step) {
          setState(() {
            _steps[index] = step;
          });
        },
      ),
    );
  }

  void _deleteStep(int index) {
    setState(() {
      _steps.removeAt(index);
    });
  }

  void _reorderSteps(int oldIndex, int newIndex) {
    setState(() {
      if (oldIndex < newIndex) {
        newIndex -= 1;
      }
      final model_step.Step step = _steps.removeAt(oldIndex);
      _steps.insert(newIndex, step);
    });
  }

  Future<void> _pickMusicFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.audio,
        allowMultiple: false,
      );

      if (result != null) {
        setState(() {
          _selectedMusicTrack = result.files.single.path;
          _isBuiltInTrack = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick music file: $e'),
          ),
        );
      }
    }
  }

  void _togglePreview(String trackName) {
    if (_currentlyPreviewing == trackName) {
      // Stop current preview
      AudioService.stopBackgroundMusic();
      setState(() {
        _currentlyPreviewing = null;
      });
    } else {
      // Start new preview
      final isBuiltIn = AudioService.builtInMusicTrackNames.contains(trackName);
      AudioService.playMusicPreview(trackName, isBuiltIn: isBuiltIn);
      setState(() {
        _currentlyPreviewing = trackName;
      });
      
      // Auto-stop preview after 10 seconds and update UI
      Timer(const Duration(seconds: 10), () {
        if (mounted && _currentlyPreviewing == trackName) {
          setState(() {
            _currentlyPreviewing = null;
          });
        }
      });
    }
  }

  void _saveRoutine() async {
    if (!_formKey.currentState!.validate()) return;

    if (_steps.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one step to the routine'),
        ),
      );
      return;
    }

    final routineProvider = context.read<RoutineProvider>();

    if (_isEditing) {
      final updatedRoutine = widget.routine!.copyWith(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _categoryController.text.trim(),
        steps: _steps,
        voiceEnabled: _voiceEnabled,
        musicEnabled: _musicEnabled,
        musicTrack: _selectedMusicTrack,
        isBuiltInTrack: _isBuiltInTrack,
      );
      await routineProvider.updateRoutine(updatedRoutine);
    } else {
      await routineProvider.createRoutine(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _categoryController.text.trim(),
        voiceEnabled: _voiceEnabled,
        musicEnabled: _musicEnabled,
        musicTrack: _selectedMusicTrack,
        isBuiltInTrack: _isBuiltInTrack,
      );
      
      // Get the created routine and add steps
      final newRoutine = routineProvider.routines.last;
      final updatedRoutine = newRoutine.copyWith(steps: _steps);
      await routineProvider.updateRoutine(updatedRoutine);
    }

    if (mounted) {
      Navigator.of(context).pop();
    }
  }
}

class _StepEditorDialog extends StatefulWidget {
  final model_step.Step? step;
  final Function(model_step.Step) onSave;

  const _StepEditorDialog({
    this.step,
    required this.onSave,
  });

  @override
  State<_StepEditorDialog> createState() => _StepEditorDialogState();
}

class _StepEditorDialogState extends State<_StepEditorDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late StepType _selectedType;
  late int _timerDuration;
  late int _repsTarget;
  late int? _repDurationSeconds;
  late bool _randomizeReps;
  late int _repsMin;
  late int _repsMax;
  late List<String> _choices;
  late String _variableName;
  late List<String> _variableOptions;
  late bool _voiceEnabled;

  @override
  void initState() {
    super.initState();
    final step = widget.step;
    _titleController = TextEditingController(text: step?.title ?? '');
    _descriptionController = TextEditingController(text: step?.description ?? '');
    _selectedType = step?.type ?? StepType.basic;
    _timerDuration = step?.timerDuration ?? 60;
    _repsTarget = step?.repsTarget ?? 1;
    _repDurationSeconds = step?.repDurationSeconds;
    _randomizeReps = step?.randomizeReps ?? false;
    _repsMin = step?.repsMin ?? 1;
    _repsMax = step?.repsMax ?? 10;
    _choices = List.from(step?.choices ?? []);
    _variableName = step?.variableName ?? '';
    _variableOptions = List.from(step?.variableOptions ?? []);
    _voiceEnabled = step?.voiceEnabled ?? true;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.step == null ? 'Add Step' : 'Edit Step'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Step Title',
                  hintText: 'Enter step title',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a step title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                  hintText: 'Enter description',
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<StepType>(
                value: _selectedType,
                decoration: const InputDecoration(
                  labelText: 'Step Type',
                ),
                items: StepType.values.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(type.displayName),
                  );
                }).toList(),
                onChanged: (type) {
                  setState(() {
                    _selectedType = type!;
                  });
                },
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Voice Announcement'),
                subtitle: const Text('Read this step aloud'),
                value: _voiceEnabled,
                onChanged: (value) {
                  setState(() {
                    _voiceEnabled = value;
                  });
                },
              ),
              const SizedBox(height: 16),
              if (_selectedType == StepType.timer) ...[
                Text('Timer Duration: ${_timerDuration}s'),
                Slider(
                  value: _timerDuration.toDouble(),
                  min: 10,
                  max: 600,
                  divisions: 59,
                  onChanged: (value) {
                    setState(() {
                      _timerDuration = value.round();
                    });
                  },
                ),
              ],
              if (_selectedType == StepType.reps) ...[
                SwitchListTile(
                  title: const Text('Randomize Reps'),
                  subtitle: const Text('Roll dice for random number of reps'),
                  value: _randomizeReps,
                  onChanged: (value) {
                    setState(() {
                      _randomizeReps = value;
                      // When enabling randomization, set repsTarget to repsMin so dice shows
                      if (value) {
                        _repsTarget = _repsMin;
                      }
                    });
                  },
                ),
                const SizedBox(height: 16),
                if (_randomizeReps) ...[
                  Text('Minimum Reps: $_repsMin'),
                  Slider(
                    value: _repsMin.toDouble(),
                    min: 1,
                    max: 20,
                    divisions: 19,
                    onChanged: (value) {
                      setState(() {
                        _repsMin = value.round();
                        if (_repsMin > _repsMax) {
                          _repsMax = _repsMin;
                        }
                        // Keep repsTarget synced with repsMin for dice detection
                        _repsTarget = _repsMin;
                      });
                    },
                  ),
                  const SizedBox(height: 8),
                  Text('Maximum Reps: $_repsMax'),
                  Slider(
                    value: _repsMax.toDouble(),
                    min: _repsMin.toDouble(),
                    max: 50,
                    divisions: (50 - _repsMin),
                    onChanged: (value) {
                      setState(() {
                        _repsMax = value.round();
                      });
                    },
                  ),
                ] else ...[
                  Text('Target Reps: $_repsTarget'),
                  Slider(
                    value: _repsTarget.toDouble(),
                    min: 1,
                    max: 50,
                    divisions: 49,
                    onChanged: (value) {
                      setState(() {
                        _repsTarget = value.round();
                      });
                    },
                  ),
                ],
                const SizedBox(height: 16),
                Row(
                  children: [
                    Checkbox(
                      value: _repDurationSeconds != null,
                      onChanged: (value) {
                        setState(() {
                          _repDurationSeconds = value == true ? 30 : null;
                        });
                      },
                    ),
                    const Text('Auto-advance each rep'),
                  ],
                ),
                if (_repDurationSeconds != null) ...[
                  const SizedBox(height: 8),
                  Text('Rep Duration: ${_repDurationSeconds}s'),
                  Slider(
                    value: _repDurationSeconds!.toDouble(),
                    min: 5,
                    max: 120,
                    divisions: 23,
                    onChanged: (value) {
                      setState(() {
                        _repDurationSeconds = value.round();
                      });
                    },
                  ),
                ],
              ],
              if (_selectedType == StepType.randomChoice) ...[
                const Text('Choices:'),
                ..._choices.asMap().entries.map((entry) {
                  final index = entry.key;
                  final choice = entry.value;
                  return ListTile(
                    title: Text(choice),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () {
                        setState(() {
                          _choices.removeAt(index);
                        });
                      },
                    ),
                  );
                }),
                TextButton.icon(
                  onPressed: _addChoice,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Choice'),
                  style: TextButton.styleFrom(
                    minimumSize: const Size(120, 40),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _saveStep,
          style: FilledButton.styleFrom(
            minimumSize: const Size(80, 40),
          ),
          child: const Text('Save'),
        ),
      ],
    );
  }

  void _addChoice() {
    showDialog(
      context: context,
      builder: (context) {
        final controller = TextEditingController();
        return AlertDialog(
          title: const Text('Add Choice'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              hintText: 'Enter choice',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (controller.text.trim().isNotEmpty) {
                  setState(() {
                    _choices.add(controller.text.trim());
                  });
                  Navigator.of(context).pop();
                }
              },
              style: FilledButton.styleFrom(
                minimumSize: const Size(80, 40),
              ),
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  void _addVariableOption() {
    showDialog(
      context: context,
      builder: (context) {
        final controller = TextEditingController();
        return AlertDialog(
          title: const Text('Add Variable Option'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              hintText: 'Enter option value',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (controller.text.trim().isNotEmpty) {
                  setState(() {
                    _variableOptions.add(controller.text.trim());
                  });
                  Navigator.of(context).pop();
                }
              },
              style: FilledButton.styleFrom(
                minimumSize: const Size(80, 40),
              ),
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  void _saveStep() {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedType == StepType.randomChoice && _choices.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one choice'),
        ),
      );
      return;
    }

    final step = model_step.Step(
      id: widget.step?.id,
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      type: _selectedType,
      timerDuration: _timerDuration,
      repsTarget: _repsTarget,
      repDurationSeconds: _repDurationSeconds,
      randomizeReps: _randomizeReps,
      repsMin: _repsMin,
      repsMax: _repsMax,
      choices: _choices,
      variableName: _variableName,
      variableOptions: _variableOptions,
      voiceEnabled: _voiceEnabled,
    );

    widget.onSave(step);
    Navigator.of(context).pop();
  }
}