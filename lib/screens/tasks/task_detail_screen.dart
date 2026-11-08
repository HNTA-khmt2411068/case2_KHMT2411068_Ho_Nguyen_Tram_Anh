import 'package:flutter/material.dart';
import '../../services/task_service.dart';
import '../sharing/task_sharing_screen.dart';

class TaskDetailScreen extends StatefulWidget {
  final String token;
  final String taskId;

  const TaskDetailScreen({
    Key? key,
    required this.token,
    required this.taskId,
  }) : super(key: key);

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  Map<String, dynamic>? _taskData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchTaskDetail();
  }

  void _fetchTaskDetail() async {
    setState(() => _isLoading = true);
    try {
      final tasks = await TaskService.getTasks(widget.token);
      final found = tasks.firstWhere(
            (t) => t.id == widget.taskId,
        orElse: () => tasks.first,
      );
      setState(() {
        _taskData = {
          'id': found.id,
          'title': found.title,
          'description': found.description,
          'priority': found.priority,
          'status': found.status,
        };
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không thể tải chi tiết công việc')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Color _getPriorityColor(String? priority) {
    switch (priority) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      default:
        return Colors.green;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chi tiết công việc')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _taskData == null
          ? const Center(child: Text('Không tìm thấy thông tin công việc'))
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _taskData!['title'] ?? '',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Chip(
                  label: Text(
                    'Ưu tiên: ${_taskData!['priority']}',
                    style: const TextStyle(color: Colors.white),
                  ),
                  backgroundColor: _getPriorityColor(_taskData!['priority']),
                ),
                const SizedBox(width: 8),
                Chip(label: Text('Trạng thái: ${_taskData!['status']}')),
              ],
            ),
            const Divider(height: 30),
            const Text(
              'Mô tả:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(_taskData!['description'] ?? 'Chưa có mô tả', style: const TextStyle(fontSize: 15)),
            const Spacer(),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.share),
                    label: const Text('Chia sẻ công việc'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => TaskSharingScreen(
                            token: widget.token,
                            taskId: widget.taskId,
                            taskTitle: _taskData!['title'] ?? '',
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}