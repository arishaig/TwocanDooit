import 'package:flutter/material.dart';
import '../../models/routine.dart';
import '../../models/routine_schedule.dart';
import '../../services/schedule_service.dart';
import '../widgets/schedule_time_picker.dart';
import '../widgets/schedule_weekday_picker.dart';

class ScheduleConfigScreen extends StatefulWidget {
  final Routine routine;
  final RoutineSchedule? existingSchedule;

  const ScheduleConfigScreen({
    super.key,
    required this.routine,
    this.existingSchedule,
  });

  @override
  State<ScheduleConfigScreen> createState() => _ScheduleConfigScreenState();
}

class _ScheduleConfigScreenState extends State<ScheduleConfigScreen> {
  late ScheduleType _selectedType;
  late Set<int> _selectedWeekdays;
  late TimeOfDay _selectedTime;
  late bool _useRandomTime;
  late TimeOfDay _randomStartTime;
  late TimeOfDay _randomEndTime;
  late bool _isEnabled;
  late int _snoozeMinutes;
  late int _maxSnoozeCount;

  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeFields();
  }

  void _initializeFields() {
    if (widget.existingSchedule != null) {
      final schedule = widget.existingSchedule!;
      _selectedType = schedule.type;
      _selectedWeekdays = Set.from(schedule.weekdays);
      _selectedTime = TimeOfDay(hour: schedule.hour, minute: schedule.minute);
      _useRandomTime = schedule.useRandomTime;
      _randomStartTime = TimeOfDay(
        hour: schedule.randomStartHour ?? schedule.hour,
        minute: schedule.randomStartMinute ?? schedule.minute,
      );
      _randomEndTime = TimeOfDay(
        hour: schedule.randomEndHour ?? schedule.hour,
        minute: schedule.randomEndMinute ?? schedule.minute,
      );
      _isEnabled = schedule.isEnabled;
      _snoozeMinutes = schedule.snoozeMinutes;
      _maxSnoozeCount = schedule.maxSnoozeCount;
    } else {
      _selectedType = ScheduleType.daily;
      _selectedWeekdays = {1, 2, 3, 4, 5, 6, 7};
      _selectedTime = const TimeOfDay(hour: 8, minute: 0);
      _useRandomTime = false;
      _randomStartTime = const TimeOfDay(hour: 8, minute: 0);
      _randomEndTime = const TimeOfDay(hour: 10, minute: 0);
      _isEnabled = true;
      _snoozeMinutes = 10;
      _maxSnoozeCount = 3;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existingSchedule != null ? 'Edit Schedule' : 'Add Schedule'),
        actions: [
          if (widget.existingSchedule != null)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _deleteSchedule,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildRoutineHeader(),
            const SizedBox(height: 24),
            _buildScheduleTypeSection(),
            const SizedBox(height: 24),
            _buildWeekdaySection(),
            const SizedBox(height: 24),
            _buildTimeSection(),
            const SizedBox(height: 24),
            _buildRandomTimeSection(),
            const SizedBox(height: 24),
            _buildSnoozeSection(),
            const SizedBox(height: 24),
            _buildEnabledSection(),
            const SizedBox(height: 32),
            _buildSaveButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildRoutineHeader() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Routine',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Text(
              widget.routine.name,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if (widget.routine.description.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                widget.routine.description,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildScheduleTypeSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Schedule Type',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 12),
            ...ScheduleType.values.map((type) => RadioListTile<ScheduleType>(
              title: Text(_getScheduleTypeDisplayName(type)),
              subtitle: Text(_getScheduleTypeDescription(type)),
              value: type,
              groupValue: _selectedType,
              onChanged: (value) {
                setState(() {
                  _selectedType = value!;
                  _updateWeekdaysForType(value);
                });
              },
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildWeekdaySection() {
    if (_selectedType == ScheduleType.daily) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Days',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 12),
            ScheduleWeekdayPicker(
              selectedWeekdays: _selectedWeekdays,
              onChanged: _selectedType == ScheduleType.custom
                  ? (weekdays) {
                      setState(() {
                        _selectedWeekdays = weekdays;
                      });
                    }
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _useRandomTime ? 'Default Time' : 'Time',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 12),
            ScheduleTimePicker(
              selectedTime: _selectedTime,
              onChanged: (time) {
                setState(() {
                  _selectedTime = time;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRandomTimeSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Random Time',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                Switch(
                  value: _useRandomTime,
                  onChanged: (value) {
                    setState(() {
                      _useRandomTime = value;
                    });
                  },
                ),
              ],
            ),
            if (_useRandomTime) ...[
              const SizedBox(height: 12),
              Text(
                'Schedule notifications at random times within this range (5-minute increments)',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Start Time',
                          style: Theme.of(context).textTheme.labelMedium,
                        ),
                        const SizedBox(height: 8),
                        ScheduleTimePicker(
                          selectedTime: _randomStartTime,
                          onChanged: (time) {
                            setState(() {
                              _randomStartTime = time;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'End Time',
                          style: Theme.of(context).textTheme.labelMedium,
                        ),
                        const SizedBox(height: 8),
                        ScheduleTimePicker(
                          selectedTime: _randomEndTime,
                          onChanged: (time) {
                            setState(() {
                              _randomEndTime = time;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSnoozeSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Snooze Settings',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Snooze Duration',
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<int>(
                        initialValue: _snoozeMinutes,
                        decoration: const InputDecoration(
                          suffix: Text('minutes'),
                        ),
                        items: [5, 10, 15, 20, 30]
                            .map((minutes) => DropdownMenuItem(
                                  value: minutes,
                                  child: Text('$minutes'),
                                ))
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            _snoozeMinutes = value!;
                          });
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Max Snoozes',
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<int>(
                        initialValue: _maxSnoozeCount,
                        decoration: const InputDecoration(
                          suffix: Text('times'),
                        ),
                        items: [1, 2, 3, 4, 5]
                            .map((count) => DropdownMenuItem(
                                  value: count,
                                  child: Text('$count'),
                                ))
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            _maxSnoozeCount = value!;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnabledSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Enable Schedule',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Schedule will only send notifications when enabled',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: _isEnabled,
              onChanged: (value) {
                setState(() {
                  _isEnabled = value;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return FilledButton(
      onPressed: _isLoading ? null : _saveSchedule,
      child: _isLoading
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Text(widget.existingSchedule != null ? 'Update Schedule' : 'Create Schedule'),
    );
  }

  String _getScheduleTypeDisplayName(ScheduleType type) {
    switch (type) {
      case ScheduleType.once:
        return 'Once';
      case ScheduleType.daily:
        return 'Daily';
      case ScheduleType.weekly:
        return 'Weekly';
      case ScheduleType.weekdays:
        return 'Weekdays';
      case ScheduleType.custom:
        return 'Custom Days';
    }
  }

  String _getScheduleTypeDescription(ScheduleType type) {
    switch (type) {
      case ScheduleType.once:
        return 'One-time notification';
      case ScheduleType.daily:
        return 'Every day';
      case ScheduleType.weekly:
        return 'Same day each week';
      case ScheduleType.weekdays:
        return 'Monday through Friday';
      case ScheduleType.custom:
        return 'Select specific days';
    }
  }

  void _updateWeekdaysForType(ScheduleType type) {
    switch (type) {
      case ScheduleType.daily:
        _selectedWeekdays = {1, 2, 3, 4, 5, 6, 7};
        break;
      case ScheduleType.weekly:
        _selectedWeekdays = {1}; // Default to Monday
        break;
      case ScheduleType.weekdays:
        _selectedWeekdays = {1, 2, 3, 4, 5};
        break;
      case ScheduleType.custom:
        // Keep current selection
        break;
      case ScheduleType.once:
        _selectedWeekdays = {DateTime.now().weekday};
        break;
    }
  }

  Future<void> _saveSchedule() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      if (widget.existingSchedule != null) {
        // Update existing schedule
        final updatedSchedule = widget.existingSchedule!.copyWith(
          type: _selectedType,
          weekdays: _selectedWeekdays,
          hour: _selectedTime.hour,
          minute: _selectedTime.minute,
          useRandomTime: _useRandomTime,
          randomStartHour: _useRandomTime ? _randomStartTime.hour : null,
          randomStartMinute: _useRandomTime ? _randomStartTime.minute : null,
          randomEndHour: _useRandomTime ? _randomEndTime.hour : null,
          randomEndMinute: _useRandomTime ? _randomEndTime.minute : null,
          isEnabled: _isEnabled,
          snoozeMinutes: _snoozeMinutes,
          maxSnoozeCount: _maxSnoozeCount,
        );

        await ScheduleService().updateSchedule(updatedSchedule);
      } else {
        // Create new schedule
        await ScheduleService().createSchedule(
          routineId: widget.routine.id,
          routineName: widget.routine.name,
          type: _selectedType,
          weekdays: _selectedWeekdays,
          hour: _selectedTime.hour,
          minute: _selectedTime.minute,
          useRandomTime: _useRandomTime,
          randomStartHour: _useRandomTime ? _randomStartTime.hour : null,
          randomStartMinute: _useRandomTime ? _randomStartTime.minute : null,
          randomEndHour: _useRandomTime ? _randomEndTime.hour : null,
          randomEndMinute: _useRandomTime ? _randomEndTime.minute : null,
          isEnabled: _isEnabled,
        );
      }

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.existingSchedule != null
                ? 'Schedule updated successfully'
                : 'Schedule created successfully'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving schedule: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _deleteSchedule() async {
    if (widget.existingSchedule == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Schedule'),
        content: const Text('Are you sure you want to delete this schedule?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await ScheduleService().deleteSchedule(widget.existingSchedule!.id);
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Schedule deleted successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting schedule: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }
}