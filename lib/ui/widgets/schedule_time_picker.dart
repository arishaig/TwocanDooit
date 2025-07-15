import 'package:flutter/material.dart';

class ScheduleTimePicker extends StatelessWidget {
  final TimeOfDay selectedTime;
  final ValueChanged<TimeOfDay> onChanged;

  const ScheduleTimePicker({
    super.key,
    required this.selectedTime,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _selectTime(context),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).colorScheme.outline),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              Icons.access_time,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 12),
            Text(
              _formatTime(selectedTime),
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const Spacer(),
            Icon(
              Icons.arrow_drop_down,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: selectedTime,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false),
          child: child!,
        );
      },
    );

    if (picked != null && picked != selectedTime) {
      onChanged(picked);
    }
  }

  String _formatTime(TimeOfDay time) {
    final period = time.hour >= 12 ? 'PM' : 'AM';
    final displayHour = time.hour == 0 ? 12 : (time.hour > 12 ? time.hour - 12 : time.hour);
    final displayMinute = time.minute.toString().padLeft(2, '0');
    return '$displayHour:$displayMinute $period';
  }
}