import 'package:flutter/material.dart';
import '../../models/task.dart';
import '../../services/task_service.dart';
import '../assignment/assign_task_screen.dart';
import '../sharing/task_sharing_screen.dart';

class TaskDetailScreen extends StatefulWidget {
  final String token;
  final Task task;

  const TaskDetailScreen({
    Key? key,
    required this.token,
    required this.task,
  }) : super(key: key);

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  late String _title;
  late String _description;
  late String _priority;
  late String _status;
  DateTime? _startDate;
  DateTime? _dueDate;

  @override
  void initState() {
    super.initState();
    _title = widget.task.title;
    _description = widget.task.description;
    _priority = widget.task.priority;
    _status = widget.task.status;
    _startDate = widget.task.startDate;
    _dueDate = widget.task.dueDate;
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      default:
        return Colors.green;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'completed':
        return Colors.green;
      case 'in_progress':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'completed':
        return 'Đã hoàn thành';
      case 'in_progress':
        return 'Đang thực hiện';
      default:
        return 'Chưa thực hiện';
    }
  }

  void _showActivitiesDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return FutureBuilder<List<dynamic>>(
          future: TaskService.getTaskActivities(widget.token, widget.task.id),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(
                height: 300,
                child: Center(child: CircularProgressIndicator()),
              );
            }

            final activities = snapshot.data ?? [];

            return Container(
              height: 400,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '📜 Lịch sử hoạt động',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Divider(),
                  Expanded(
                    child: activities.isEmpty
                        ? const Center(child: Text('Chưa có lịch sử hoạt động.'))
                        : ListView.builder(
                      itemCount: activities.length,
                      itemBuilder: (context, index) {
                        final item = activities[index];
                        return ListTile(
                          leading: const Icon(Icons.history_toggle_off, color: Colors.teal),
                          title: Text(item['action'] ?? 'Thao tác'),
                          subtitle: Text(
                            item['createdAt'] != null
                                ? item['createdAt'].toString().split('T')[0]
                                : '',
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showEditDialog() {
    final titleController = TextEditingController(text: _title);
    final descController = TextEditingController(text: _description);
    String editPriority = _priority;
    String editStatus = _status;
    DateTime? editStartDate = _startDate;
    DateTime? editDueDate = _dueDate;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Chỉnh sửa công việc'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(labelText: 'Tên công việc'),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: descController,
                      decoration: const InputDecoration(labelText: 'Mô tả'),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: editPriority,
                      decoration: const InputDecoration(labelText: 'Mức độ ưu tiên'),
                      items: const [
                        DropdownMenuItem(value: 'low', child: Text('Thấp (Low)')),
                        DropdownMenuItem(value: 'medium', child: Text('Trung bình (Medium)')),
                        DropdownMenuItem(value: 'high', child: Text('Cao (High)')),
                      ],
                      onChanged: (val) {
                        if (val != null) setDialogState(() => editPriority = val);
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: editStatus,
                      decoration: const InputDecoration(labelText: 'Trạng thái'),
                      items: const [
                        DropdownMenuItem(value: 'todo', child: Text('Chưa thực hiện')),
                        DropdownMenuItem(value: 'in_progress', child: Text('Đang thực hiện')),
                        DropdownMenuItem(value: 'completed', child: Text('Đã hoàn thành')),
                      ],
                      onChanged: (val) {
                        if (val != null) setDialogState(() => editStatus = val);
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.calendar_today, size: 16),
                            label: Text(
                              editStartDate == null
                                  ? 'Bắt đầu'
                                  : '${editStartDate!.year}-${editStartDate!.month.toString().padLeft(2, '0')}-${editStartDate!.day.toString().padLeft(2, '0')}',
                              style: const TextStyle(fontSize: 12),
                            ),
                            onPressed: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: editStartDate ?? DateTime.now(),
                                firstDate: DateTime(2020),
                                lastDate: DateTime(2030),
                              );
                              if (picked != null) {
                                setDialogState(() => editStartDate = picked);
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.event, size: 16),
                            label: Text(
                              editDueDate == null
                                  ? 'Hạn chót'
                                  : '${editDueDate!.year}-${editDueDate!.month.toString().padLeft(2, '0')}-${editDueDate!.day.toString().padLeft(2, '0')}',
                              style: const TextStyle(fontSize: 12),
                            ),
                            onPressed: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: editDueDate ?? DateTime.now(),
                                firstDate: DateTime(2020),
                                lastDate: DateTime(2030),
                              );
                              if (picked != null) {
                                setDialogState(() => editDueDate = picked);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Hủy'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (titleController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Vui lòng nhập tên công việc!')),
                      );
                      return;
                    }

                    final res = await TaskService.updateTask(
                      widget.token,
                      widget.task.id,
                      title: titleController.text.trim(),
                      description: descController.text.trim(),
                      priority: editPriority,
                      status: editStatus,
                      startDate: editStartDate,
                      dueDate: editDueDate,
                    );

                    if (mounted) {
                      Navigator.pop(context);
                      if (res['success'] == true) {
                        setState(() {
                          _title = titleController.text.trim();
                          _description = descController.text.trim();
                          _priority = editPriority;
                          _status = editStatus;
                          _startDate = editStartDate;
                          _dueDate = editDueDate;
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Cập nhật công việc thành công!')),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(res['message'] ?? 'Cập nhật thất bại')),
                        );
                      }
                    }
                  },
                  child: const Text('Lưu'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: const Text('Bạn có chắc chắn muốn xóa công việc này không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(context);
              final res = await TaskService.deleteTask(widget.token, widget.task.id);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(res['message'] ?? 'Đã xóa công việc')),
                );
                Navigator.pop(context, true);
              }
            },
            child: const Text('Xóa', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history, color: Colors.teal),
            tooltip: 'Lịch sử hoạt động',
            onPressed: _showActivitiesDialog,
          ),
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.orange),
            tooltip: 'Chỉnh sửa công việc',
            onPressed: _showEditDialog,
          ),
          IconButton(
            icon: const Icon(Icons.person_add, color: Colors.blue),
            tooltip: 'Giao việc',
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AssignTaskScreen(
                    token: widget.token,
                    taskId: widget.task.id,
                    taskTitle: _title,
                  ),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.share, color: Colors.purple),
            tooltip: 'Chia sẻ',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TaskSharingScreen(
                    token: widget.token,
                    taskId: widget.task.id,
                    taskTitle: _title,
                  ),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            tooltip: 'Xóa công việc',
            onPressed: _confirmDelete,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            Text(
              _title,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Chip(
                  label: Text(
                    'Ưu tiên: ${_priority.toUpperCase()}',
                    style: const TextStyle(color: Colors.white),
                  ),
                  backgroundColor: _getPriorityColor(_priority),
                ),
                const SizedBox(width: 8),
                Chip(
                  label: Text(
                    _getStatusText(_status),
                    style: const TextStyle(color: Colors.white),
                  ),
                  backgroundColor: _getStatusColor(_status),
                ),
              ],
            ),
            const Divider(height: 30),
            const Text(
              'Mô tả công việc:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 6),
            Text(
              _description.isEmpty ? 'Không có mô tả.' : _description,
              style: const TextStyle(fontSize: 15),
            ),
            const SizedBox(height: 20),
            if (_startDate != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Text(
                  '📅 Ngày bắt đầu: ${_startDate.toString().split(' ')[0]}',
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            if (_dueDate != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Text(
                  '⏰ Hạn hoàn thành: ${_dueDate.toString().split(' ')[0]}',
                  style: const TextStyle(fontSize: 14),
                ),
              ),
          ],
        ),
      ),
    );
  }
}