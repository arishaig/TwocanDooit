import 'package:flutter/material.dart';
import '../../models/routine.dart';
import '../../models/routine_schedule.dart';
import '../../services/schedule_service.dart';
import '../widgets/schedule_list_tile.dart';
import 'schedule_config_screen.dart';

class RoutineSchedulesScreen extends StatefulWidget {
  final Routine routine;

  const RoutineSchedulesScreen({
    super.key,
    required this.routine,
  });

  @override
  State<RoutineSchedulesScreen> createState() => _RoutineSchedulesScreenState();
}

class _RoutineSchedulesScreenState extends State<RoutineSchedulesScreen> {
  late Stream<List<RoutineSchedule>> _schedulesStream;
  final ScheduleService _scheduleService = ScheduleService();

  @override
  void initState() {
    super.initState();
    _schedulesStream = _scheduleService.schedulesStream.map(
      (allSchedules) => allSchedules
          .where((schedule) => schedule.routineId == widget.routine.id)
          .toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.routine.name} Schedules'),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: _showHelpDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: StreamBuilder<List<RoutineSchedule>>(
              stream: _schedulesStream,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text('Error: ${snapshot.error}'),
                  );
                }

                if (!snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                final schedules = snapshot.data!;

                if (schedules.isEmpty) {
                  return _buildEmptyState();
                }

                return ListView.builder(
                  itemCount: schedules.length,
                  itemBuilder: (context, index) {
                    final schedule = schedules[index];
                    return ScheduleListTile(
                      schedule: schedule,
                      onEdit: () => _editSchedule(schedule),
                      onToggle: (enabled) => _toggleSchedule(schedule, enabled),
                      onDelete: () => _deleteSchedule(schedule),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addSchedule,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildHeader() {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.routine.name,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if (widget.routine.description.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                widget.routine.description,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.schedule,
                  size: 16,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Text(
                  'Set up reminders to help you stay on track',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.schedule_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'No Schedules',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Create your first schedule to get reminded about this routine.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _addSchedule,
              icon: const Icon(Icons.add),
              label: const Text('Add Schedule'),
            ),
          ],
        ),
      ),
    );
  }

  void _addSchedule() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ScheduleConfigScreen(
          routine: widget.routine,
        ),
      ),
    );
  }

  void _editSchedule(RoutineSchedule schedule) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ScheduleConfigScreen(
          routine: widget.routine,
          existingSchedule: schedule,
        ),
      ),
    );
  }

  Future<void> _toggleSchedule(RoutineSchedule schedule, bool enabled) async {
    try {
      await _scheduleService.toggleSchedule(schedule.id, enabled);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(enabled ? 'Schedule enabled' : 'Schedule disabled'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating schedule: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _deleteSchedule(RoutineSchedule schedule) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Schedule'),
        content: Text('Are you sure you want to delete the schedule "${schedule.displayText}"?'),
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
      await _scheduleService.deleteSchedule(schedule.id);
      if (mounted) {
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

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Schedule Help'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Schedule Types:', style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Text('• Daily: Every day at the same time'),
              Text('• Weekly: Same day each week'),
              Text('• Weekdays: Monday through Friday'),
              Text('• Custom: Select specific days'),
              SizedBox(height: 16),
              Text('Random Time:', style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Text('Choose a time range for notifications to be sent at random times within that range (in 5-minute increments).'),
              SizedBox(height: 16),
              Text('Snooze:', style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Text('Set how long to snooze notifications and how many times you can snooze before the notification expires.'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }
}