import 'package:flutter/material.dart';
import '../utils/date_formatter.dart';
import 'priority_badge.dart';
import 'status_badge.dart';

class TaskCard extends StatelessWidget {
  final dynamic task;
  final VoidCallback? onTap;

  const TaskCard({super.key, required this.task, this.onTap});

  dynamic _readField(String key) {
    if (task is Map) return task[key];
    switch (key) {
      case 'title':
        return task.title;
      case 'description':
        return task.description;
      case 'status':
        return task.status;
      case 'priority':
        return task.priority;
      case 'dueDate':
        return task.dueDate;
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = (_readField('title') ?? '').toString();
    final description = (_readField('description') ?? '').toString();
    final status = (_readField('status') ?? 'todo').toString();
    final priority = (_readField('priority') ?? 'medium').toString();
    final dueDate = _readField('dueDate');
    final overdue = DateFormatter.isOverdue(dueDate, status: status);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  PriorityBadge(priority: priority),
                ],
              ),
              if (description.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.black54, fontSize: 13),
                ),
              ],
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  StatusBadge(status: status),
                  Row(
                    children: [
                      Icon(
                        Icons.schedule,
                        size: 15,
                        color: overdue ? Colors.red : Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        DateFormatter.formatDate(dueDate),
                        style: TextStyle(
                          fontSize: 12,
                          color: overdue ? Colors.red : Colors.grey.shade700,
                          fontWeight:
                          overdue ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}