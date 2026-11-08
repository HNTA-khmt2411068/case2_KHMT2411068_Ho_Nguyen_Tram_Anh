import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/task_service.dart';

class TaskDetailScreen extends StatefulWidget {
  final Map<String, dynamic> task;
  final String token;

  const TaskDetailScreen({Key? key, required this.task, required this.token}) : super(key: key);

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  late String _currentStatus;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _currentStatus = widget.task['status'] ?? 'todo';
  }

  Future<void> _updateStatus(String newStatus) async {
    setState(() => _isUpdating = true);
    final res = await TaskService.updateTaskStatus(widget.token, widget.task['_id'], newStatus);
    setState(() => _isUpdating = false);

    if (mounted) {
      if (res['success'] == true) {
        setState(() => _currentStatus = newStatus);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cập nhật trạng thái thành công!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res['message'] ?? 'Cập nhật thất bại')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final task = widget.task;
    final dateFormat = DateFormat('dd/MM/yyyy');
    final startDateStr = task['startDate'] != null ? dateFormat.format(DateTime.parse(task['startDate'])) : 'Chưa thiết lập';
    final dueDateStr = task['dueDate'] != null ? dateFormat.format(DateTime.parse(task['dueDate'])) : 'Chưa thiết lập';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết công việc'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Xác nhận xóa'),
                  content: const Text('Bạn có chắc muốn xóa công việc này?'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
                    TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Xóa')),
                  ],
                ),
              );
              if (confirm == true) {
                await TaskService.deleteTask(widget.token, task['_id']);
                if (mounted) Navigator.pop(context, true);
              }
            },
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            Text(
              task['title'] ?? '',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Mô tả: ${task['description'] ?? 'Không có mô tả'}', style: const TextStyle(fontSize: 16)),
                    const Divider(),
                    Text('Ưu tiên: ${task['priority'] ?? 'medium'}'),
                    Text('Ngày bắt đầu: $startDateStr'),
                    Text('Hạn hoàn thành: $dueDateStr'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text('Cập nhật trạng thái:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            _isUpdating
                ? const LinearProgressIndicator()
                : SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'todo', label: Text('Chưa làm')),
                ButtonSegment(value: 'in_progress', label: Text('Đang làm')),
                ButtonSegment(value: 'completed', label: Text('Hoàn thành')),
              ],
              selected: {_currentStatus},
              onSelectionChanged: (Set<String> newSelection) {
                _updateStatus(newSelection.first);
              },
            ),
          ],
        ),
      ),
    );
  }
}