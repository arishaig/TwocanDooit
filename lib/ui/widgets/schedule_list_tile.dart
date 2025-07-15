import 'package:flutter/material.dart';
import '../../models/routine_schedule.dart';
import '../../services/schedule_service.dart';

class ScheduleListTile extends StatelessWidget {
  final RoutineSchedule schedule;
  final VoidCallback onEdit;
  final ValueChanged<bool> onToggle;
  final VoidCallback onDelete;

  const ScheduleListTile({
    super.key,
    required this.schedule,
    required this.onEdit,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: _buildLeadingIcon(context),
        title: Text(
          schedule.displayText,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: schedule.isEnabled
                ? Theme.of(context).colorScheme.onSurface
                : Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        subtitle: _buildSubtitle(context),
        trailing: _buildTrailing(context),
        onTap: onEdit,
      ),
    );
  }

  Widget _buildLeadingIcon(BuildContext context) {
    IconData icon;
    Color color;

    if (!schedule.isEnabled) {
      icon = Icons.schedule_outlined;
      color = Theme.of(context).colorScheme.onSurfaceVariant;
    } else if (schedule.isSnoozed) {
      icon = Icons.snooze;
      color = Theme.of(context).colorScheme.secondary;
    } else {
      icon = Icons.schedule;
      color = Theme.of(context).colorScheme.primary;
    }

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Icon(
        icon,
        color: color,
        size: 20,
      ),
    );
  }

  Widget? _buildSubtitle(BuildContext context) {
    final List<String> subtitleParts = [];

    // Add status info
    if (!schedule.isEnabled) {
      subtitleParts.add('Disabled');
    } else if (schedule.isSnoozed) {
      subtitleParts.add('Snoozed until ${_formatTime(schedule.snoozeUntil!)}');
    } else {
      // Add next occurrence info
      final nextOccurrence = ScheduleService().calculateNextOccurrence(schedule);
      if (nextOccurrence != null) {
        subtitleParts.add('Next: ${_formatNextOccurrence(nextOccurrence)}');
      }
    }

    // Add snooze info
    if (schedule.currentSnoozeCount > 0) {
      subtitleParts.add('Snoozed ${schedule.currentSnoozeCount}/${schedule.maxSnoozeCount} times');
    }

    if (subtitleParts.isEmpty) {
      return null;
    }

    return Text(
      subtitleParts.join(' • '),
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }

  Widget _buildTrailing(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Switch(
          value: schedule.isEnabled,
          onChanged: onToggle,
        ),
        PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'edit':
                onEdit();
                break;
              case 'delete':
                onDelete();
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: ListTile(
                leading: Icon(Icons.edit),
                title: Text('Edit'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: ListTile(
                leading: Icon(Icons.delete),
                title: Text('Delete'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour;
    final minute = dateTime.minute;
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    final displayMinute = minute.toString().padLeft(2, '0');
    return '$displayHour:$displayMinute $period';
  }

  String _formatNextOccurrence(DateTime dateTime) {
    final now = DateTime.now();
    final difference = dateTime.difference(now);

    if (difference.inDays > 0) {
      if (difference.inDays == 1) {
        return 'Tomorrow at ${_formatTime(dateTime)}';
      } else if (difference.inDays < 7) {
        return '${_getDayName(dateTime.weekday)} at ${_formatTime(dateTime)}';
      } else {
        return '${dateTime.month}/${dateTime.day} at ${_formatTime(dateTime)}';
      }
    } else if (difference.inHours > 0) {
      return 'In ${difference.inHours}h ${difference.inMinutes % 60}m';
    } else if (difference.inMinutes > 0) {
      return 'In ${difference.inMinutes}m';
    } else {
      return 'Now';
    }
  }

  String _getDayName(int weekday) {
    switch (weekday) {
      case 1: return 'Monday';
      case 2: return 'Tuesday';
      case 3: return 'Wednesday';
      case 4: return 'Thursday';
      case 5: return 'Friday';
      case 6: return 'Saturday';
      case 7: return 'Sunday';
      default: return 'Unknown';
    }
  }
}