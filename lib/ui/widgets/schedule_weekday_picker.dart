import 'package:flutter/material.dart';

class ScheduleWeekdayPicker extends StatelessWidget {
  final Set<int> selectedWeekdays;
  final ValueChanged<Set<int>>? onChanged;

  const ScheduleWeekdayPicker({
    super.key,
    required this.selectedWeekdays,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outline),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildDayButton(context, 1, 'M'),
              _buildDayButton(context, 2, 'T'),
              _buildDayButton(context, 3, 'W'),
              _buildDayButton(context, 4, 'T'),
              _buildDayButton(context, 5, 'F'),
              _buildDayButton(context, 6, 'S'),
              _buildDayButton(context, 7, 'S'),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _getSelectedDaysText(),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDayButton(BuildContext context, int weekday, String label) {
    final isSelected = selectedWeekdays.contains(weekday);
    final isEnabled = onChanged != null;

    return GestureDetector(
      onTap: isEnabled ? () => _toggleWeekday(weekday) : null,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.surface,
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.outline,
          ),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Center(
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: isSelected
                  ? Theme.of(context).colorScheme.onPrimary
                  : isEnabled
                      ? Theme.of(context).colorScheme.onSurface
                      : Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  void _toggleWeekday(int weekday) {
    if (onChanged == null) return;

    final newSelection = Set<int>.from(selectedWeekdays);
    if (newSelection.contains(weekday)) {
      newSelection.remove(weekday);
    } else {
      newSelection.add(weekday);
    }

    // Ensure at least one day is selected
    if (newSelection.isNotEmpty) {
      onChanged!(newSelection);
    }
  }

  String _getSelectedDaysText() {
    if (selectedWeekdays.isEmpty) {
      return 'No days selected';
    }

    final dayNames = selectedWeekdays.map(_getDayName).toList();
    dayNames.sort();

    if (dayNames.length == 7) {
      return 'Every day';
    } else if (dayNames.length == 5 && 
               selectedWeekdays.containsAll([1, 2, 3, 4, 5])) {
      return 'Weekdays (Mon-Fri)';
    } else if (dayNames.length == 2 && 
               selectedWeekdays.containsAll([6, 7])) {
      return 'Weekends (Sat-Sun)';
    } else {
      return dayNames.join(', ');
    }
  }

  String _getDayName(int weekday) {
    switch (weekday) {
      case 1: return 'Mon';
      case 2: return 'Tue';
      case 3: return 'Wed';
      case 4: return 'Thu';
      case 5: return 'Fri';
      case 6: return 'Sat';
      case 7: return 'Sun';
      default: return '?';
    }
  }
}