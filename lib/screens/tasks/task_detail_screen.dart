import 'package:flutter/material.dart';
import '../../models/task.dart';
import '../../services/task_service.dart';

class TaskDetailScreen extends StatelessWidget {
  final String taskId;
  const TaskDetailScreen({super.key, required this.taskId});

  @override
  Widget build(BuildContext context) {
    final TaskService taskService = TaskService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết công việc'),
      ),
      body: FutureBuilder<Task>(
        future: taskService.getTaskById(taskId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Lỗi: ${snapshot.error}'));
          } else if (!snapshot.hasData) {
            return const Center(child: Text('Không tìm thấy công việc'));
          }

          final task = snapshot.data!;
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                Text('Trạng thái: ${task.status}'),
                Text('Mức độ ưu tiên: ${task.priority}'),
                Text('Hạn hoàn thành: ${task.dueDate ?? "Không có"}'),
                const Divider(),
                Text(task.description ?? 'Không có mô tả'),
              ],
            ),
          );
        },
      ),
    );
  }
}