import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../../models/routine.dart';
import '../../models/routine_schedule.dart';
import '../../models/step.dart' as model_step;
import '../../models/step_type.dart';
import '../../providers/routine_provider.dart';
import '../../services/audio_service.dart';
import '../../services/category_service.dart';
import '../../services/schedule_service.dart';
import '../widgets/category_input_field.dart';
import 'routine_schedules_screen.dart';

class RoutineEditorScreen extends StatefulWidget {
  final Routine? routine;

  const RoutineEditorScreen({super.key, this.routine});

  @override
  State<RoutineEditorScreen> createState() => _RoutineEditorScreenState();
}

class _RoutineEditorScreenState extends State<RoutineEditorScreen> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late String _category;
  late List<model_step.Step> _steps;
  late bool _voiceEnabled;
  late bool _musicEnabled;
  late String? _selectedMusicTrack;
  late bool _isBuiltInTrack;
  String? _currentlyPreviewing;
  
  // Focus tracking for clipboard animation
  late final FocusNode _nameFocusNode;
  late final FocusNode _descriptionFocusNode;
  bool _isTopFieldsFocused = false;
  
  // Schedule service for routine reminders
  final ScheduleService _scheduleService = ScheduleService();
  late StreamSubscription<List<RoutineSchedule>> _scheduleSubscription;

  bool get _isEditing => widget.routine != null;

  @override
  void initState() {
    super.initState();
    final routine = widget.routine;
    _nameController = TextEditingController(text: routine?.name ?? '');
    _descriptionController = TextEditingController(text: routine?.description ?? '');
    _category = routine?.category ?? '';
    _steps = routine?.steps.map((s) => s.copyWith()).toList() ?? [];
    _voiceEnabled = routine?.voiceEnabled ?? false;
    _musicEnabled = routine?.musicEnabled ?? false;
    _selectedMusicTrack = routine?.musicTrack;
    _isBuiltInTrack = routine?.isBuiltInTrack ?? true;
    _currentlyPreviewing = null;
    
    // Initialize focus nodes and listeners
    _nameFocusNode = FocusNode();
    _descriptionFocusNode = FocusNode();
    
    _nameFocusNode.addListener(_onFocusChange);
    _descriptionFocusNode.addListener(_onFocusChange);
    
    // Listen to schedule updates and rebuild UI when data changes
    _scheduleSubscription = _scheduleService.schedulesStream.listen((_) {
      if (mounted) {
        setState(() {});
      }
    });
  }
  
  void _onFocusChange() {
    setState(() {
      _isTopFieldsFocused = _nameFocusNode.hasFocus || _descriptionFocusNode.hasFocus;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _nameFocusNode.dispose();
    _descriptionFocusNode.dispose();
    _scheduleSubscription.cancel();
    // Stop any playing preview
    AudioService.stopBackgroundMusic();
    super.dispose();
  }
  
  List<RoutineSchedule> get _filteredSchedules {
    if (widget.routine == null) return [];
    return _scheduleService.schedules
        .where((schedule) => schedule.routineId == widget.routine!.id)
        .toList();
  }
  
  Widget _buildSchedulesList() {
    final schedules = _filteredSchedules;
    
    if (schedules.isEmpty) {
      return Text(
        'No schedules set up yet. Tap "Manage" to create your first schedule.',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      );
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final schedule in schedules.take(3)) ...[
          Row(
            children: [
              Icon(
                schedule.isEnabled ? Icons.check_circle : Icons.circle_outlined,
                size: 16,
                color: schedule.isEnabled 
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  schedule.displayText,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: schedule.isEnabled
                        ? Theme.of(context).colorScheme.onSurface
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          if (schedule != schedules.last) const SizedBox(height: 4),
        ],
        if (schedules.length > 3) ...[
          const SizedBox(height: 4),
          Text(
            'and ${schedules.length - 3} more...',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
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
      body: Stack(
        children: [
          Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20), // Larger padding for mobile
          children: [
            TextFormField(
              controller: _nameController,
              focusNode: _nameFocusNode,
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
              focusNode: _descriptionFocusNode,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
                hintText: 'Enter description',
                border: OutlineInputBorder(),
              ),
              maxLines: 4,
            ),
            const SizedBox(height: 16),
            CategoryInputField(
              initialValue: _category,
              onChanged: (value) {
                setState(() {
                  _category = value;
                });
              },
              labelText: 'Category (optional)',
              hintText: 'e.g., Daily, Health, Work',
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Voice Announcements'),
              subtitle: const Text('Read steps aloud while doing this routine'),
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
              subtitle: const Text('Play music while doing this routine'),
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
                      Column(
                        children: [
                          ...AudioService.builtInMusicTrackNames.map((trackName) {
                            return Row(
                              children: [
                                Expanded(
                                  child: ChoiceChip(
                                    label: Text(trackName),
                                    selected: _isBuiltInTrack && _selectedMusicTrack == trackName,
                                    onSelected: (selected) {
                                      if (selected) {
                                        setState(() {
                                          _selectedMusicTrack = trackName;
                                          _isBuiltInTrack = true;
                                        });
                                      }
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
                          ],
                        ),
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
                            color: Theme.of(context).colorScheme.surfaceContainerHighest,
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
            
            // Schedules section
            if (_isEditing) ...[
              Row(
                children: [
                  Text(
                    'Schedules',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const Spacer(),
                  OutlinedButton.icon(
                    onPressed: _manageSchedules,
                    icon: const Icon(Icons.schedule),
                    label: const Text('Manage'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(120, 48),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.schedule,
                            size: 20,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Routine Reminders',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Set up notifications to remind you when to do this routine.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildSchedulesList(),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
            
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
      // Animated Twocan clipboard
      AnimatedPositioned(
        duration: const Duration(milliseconds: 500),
        curve: Curves.elasticOut,
        top: _isTopFieldsFocused ? null : 20,
        bottom: _isTopFieldsFocused ? 20 : null,
        right: 20,
        child: IgnorePointer(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            curve: Curves.elasticOut,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            transform: Matrix4.identity()
              ..rotateZ(_isTopFieldsFocused ? 0.1 : 0),
            child: AnimatedScale(
              duration: const Duration(milliseconds: 500),
              curve: Curves.elasticOut,
              scale: _isTopFieldsFocused ? 0.9 : 1.0,
              child: Image.asset(
                'assets/twocan/twocan_clipboard.png',
                width: 160,
                height: 160,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(
                    Icons.edit_note,
                    size: 160,
                    color: Theme.of(context).colorScheme.primary,
                  );
                },
              ),
            ),
          ),
        ),
      ),
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

  void _manageSchedules() {
    if (widget.routine == null) return;
    
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => RoutineSchedulesScreen(
          routine: widget.routine!,
        ),
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
        category: _category.trim(),
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
        category: _category.trim(),
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

    // Record category usage for autocomplete
    if (_category.trim().isNotEmpty) {
      await CategoryService.instance.recordCategoryUsage(_category.trim());
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
  late List<double> _choiceWeights;
  late bool _useWeights;
  String _selectedPreset = '';
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
    final hasCustomWeights = step?.choiceWeights != null && step!.choiceWeights!.any((w) => w != 1.0);
    _useWeights = hasCustomWeights;
    _choiceWeights = step?.choiceWeights != null 
        ? List.from(step!.choiceWeights!) 
        : [];
    _voiceEnabled = step?.voiceEnabled ?? true;
    
    // Ensure weights list matches choices list
    while (_choiceWeights.length < _choices.length) {
      _choiceWeights.add(1.0);
    }
    while (_choiceWeights.length > _choices.length) {
      _choiceWeights.removeLast();
    }
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
                // ignore: deprecated_member_use
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
                const SizedBox(height: 16),
                
                // Weighted Dice Toggle
                SwitchListTile(
                  title: const Text('Weighted Dice'),
                  subtitle: const Text('Make some options more or less likely'),
                  value: _useWeights,
                  onChanged: (value) {
                    setState(() {
                      _useWeights = value;
                      if (!value) {
                        // Reset to equal weights when disabled
                        _setEqualWeights();
                        _selectedPreset = '';
                      } else {
                        // Default to equal preset when first enabled
                        _selectedPreset = 'equal';
                        _setEqualWeights();
                      }
                    });
                  },
                ),
                
                const SizedBox(height: 16),
                
                // Choices Section
                Row(
                  children: [
                    Text(
                      'Choices:',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${_choices.length} choices',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                
                if (_choices.length < 2)
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.warning,
                          color: Theme.of(context).colorScheme.error,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Add at least 2 choices for randomization',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                
                // Weight Presets
                if (_useWeights && _choices.length >= 3) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Quick Presets:',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      ActionChip(
                        label: const Text('Equal'),
                        backgroundColor: _selectedPreset == 'equal' 
                            ? Theme.of(context).colorScheme.primaryContainer 
                            : null,
                        onPressed: () {
                          setState(() {
                            _selectedPreset = 'equal';
                          });
                          _setEqualWeights();
                        },
                      ),
                      ActionChip(
                        label: const Text('Bell Curve'),
                        backgroundColor: _selectedPreset == 'bell' 
                            ? Theme.of(context).colorScheme.primaryContainer 
                            : null,
                        onPressed: () {
                          setState(() {
                            _selectedPreset = 'bell';
                          });
                          _setBellCurveWeights();
                        },
                      ),
                      ActionChip(
                        label: const Text('Reverse Bell'),
                        backgroundColor: _selectedPreset == 'reverse_bell' 
                            ? Theme.of(context).colorScheme.primaryContainer 
                            : null,
                        onPressed: () {
                          setState(() {
                            _selectedPreset = 'reverse_bell';
                          });
                          _setReverseBellCurveWeights();
                        },
                      ),
                      ActionChip(
                        label: const Text('Favor First'),
                        backgroundColor: _selectedPreset == 'favor_first' 
                            ? Theme.of(context).colorScheme.primaryContainer 
                            : null,
                        onPressed: () {
                          setState(() {
                            _selectedPreset = 'favor_first';
                          });
                          _setFavorFirstWeights();
                        },
                      ),
                      ActionChip(
                        label: const Text('Favor Last'),
                        backgroundColor: _selectedPreset == 'favor_last' 
                            ? Theme.of(context).colorScheme.primaryContainer 
                            : null,
                        onPressed: () {
                          setState(() {
                            _selectedPreset = 'favor_last';
                          });
                          _setFavorLastWeights();
                        },
                      ),
                    ],
                  ),
                  
                  // Preset Description
                  if (_selectedPreset.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Text(
                        _getPresetDescription(_selectedPreset),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                ],
                
                const SizedBox(height: 8),
                
                // Choice List with or without Weights
                for (int i = 0; i < _choices.length; i++)
                  Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                _choices[i],
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            if (_useWeights) ...[
                              Text(
                                '${_getChoiceProbability(i).toStringAsFixed(1)}%',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 8),
                            ],
                            IconButton(
                              icon: const Icon(Icons.delete, size: 18),
                              onPressed: () {
                                setState(() {
                                  _choices.removeAt(i);
                                  _choiceWeights.removeAt(i);
                                  _normalizeWeights();
                                });
                              },
                            ),
                          ],
                        ),
                        if (_useWeights) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Text(
                                'Weight:',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Slider(
                                  value: _choiceWeights[i],
                                  min: 0.1,
                                  max: 5.0,
                                  divisions: 49,
                                  onChanged: (value) {
                                    setState(() {
                                      _choiceWeights[i] = value;
                                      _selectedPreset = ''; // Clear preset when manually changed
                                    });
                                  },
                                ),
                              ),
                              Text(
                                '${_choiceWeights[i].toStringAsFixed(1)}x',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                
                const SizedBox(height: 8),
                
                // Add Choice Button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _addChoice,
                    icon: const Icon(Icons.add),
                    label: const Text('Add Choice'),
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
                    _choiceWeights.add(1.0); // Default weight
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

  double _getChoiceProbability(int index) {
    if (_choiceWeights.isEmpty) return 0.0;
    final totalWeight = _choiceWeights.fold<double>(0, (sum, weight) => sum + weight);
    if (totalWeight <= 0) return 0.0;
    return (_choiceWeights[index] / totalWeight) * 100;
  }

  void _normalizeWeights() {
    // Ensure weights list matches choices list
    while (_choiceWeights.length < _choices.length) {
      _choiceWeights.add(1.0);
    }
    while (_choiceWeights.length > _choices.length) {
      _choiceWeights.removeLast();
    }
  }

  void _setEqualWeights() {
    setState(() {
      for (int i = 0; i < _choiceWeights.length; i++) {
        _choiceWeights[i] = 1.0;
      }
    });
  }

  void _setBellCurveWeights() {
    setState(() {
      final count = _choiceWeights.length;
      final center = (count - 1) / 2.0;
      for (int i = 0; i < count; i++) {
        final distance = (i - center).abs();
        final maxDistance = count / 2.0;
        final normalizedDistance = distance / maxDistance;
        // Bell curve: higher weight in center, lower at edges
        _choiceWeights[i] = 0.5 + (1.0 - normalizedDistance) * 2.0;
      }
    });
  }

  void _setFavorFirstWeights() {
    setState(() {
      for (int i = 0; i < _choiceWeights.length; i++) {
        // Decreasing weights: first option most likely
        _choiceWeights[i] = (_choiceWeights.length - i) * 0.5 + 0.5;
      }
    });
  }

  void _setFavorLastWeights() {
    setState(() {
      for (int i = 0; i < _choiceWeights.length; i++) {
        // Increasing weights: last option most likely
        _choiceWeights[i] = (i + 1) * 0.5 + 0.5;
      }
    });
  }

  void _setReverseBellCurveWeights() {
    setState(() {
      final count = _choiceWeights.length;
      final center = (count - 1) / 2.0;
      for (int i = 0; i < count; i++) {
        final distance = (i - center).abs();
        final maxDistance = count / 2.0;
        final normalizedDistance = distance / maxDistance;
        // Reverse bell curve: lower weight in center, higher at edges
        _choiceWeights[i] = 0.5 + normalizedDistance * 2.0;
      }
    });
  }



  void _saveStep() {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedType == StepType.randomChoice && _choices.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least 2 choices for randomization'),
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
      choiceWeights: _useWeights && _choiceWeights.isNotEmpty ? List.from(_choiceWeights) : null,
      voiceEnabled: _voiceEnabled,
    );

    widget.onSave(step);
    Navigator.of(context).pop();
  }

  String _getPresetDescription(String preset) {
    switch (preset) {
      case 'equal':
        return 'All choices have the same probability of being selected.';
      case 'bell':
        return 'Middle choices are more likely, options at the edges are less likely.';
      case 'reverse_bell':
        return 'Options at the edges are more likely, middle choices are less likely.';
      case 'favor_first':
        return 'First option is most likely, probability decreases down the list.';
      case 'favor_last':
        return 'Last option is most likely, probability increases down the list.';
      default:
        return '';
    }
  }
}