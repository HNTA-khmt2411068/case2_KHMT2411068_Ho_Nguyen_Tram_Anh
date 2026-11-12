import 'package:flutter/material.dart';

class PriorityBadge extends StatelessWidget {
  final String priority;

  const PriorityBadge({super.key, required this.priority});

  @override
  Widget build(BuildContext context) {
    String label;
    Color color;

    switch (priority) {
      case 'high':
        label = 'Cao';
        color = Colors.red;
        break;
      case 'low':
        label = 'Thấp';
        color = Colors.teal;
        break;
      default:
        label = 'Trung bình';
        color = Colors.amber.shade800;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}