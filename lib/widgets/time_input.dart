import 'package:flutter/material.dart';

class TimeInput extends StatelessWidget {
  final String label;
  final Function(TimeOfDay) onTimeChanged;
  final Color? color;

  const TimeInput({
    super.key,
    required this.label,
    required this.onTimeChanged,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: ListTile(
        onTap: () async {
          final TimeOfDay? time = await showTimePicker(
            context: context,
            initialTime: TimeOfDay.now(),
          );
          if (time != null) {
            onTimeChanged(time);
          }
        },
        leading: Icon(Icons.access_time, color: color ?? Colors.grey),
        title: Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 16,
          ),
        ),
        trailing: Icon(Icons.arrow_forward_ios, color: color ?? Colors.grey, size: 16),
      ),
    );
  }
}
