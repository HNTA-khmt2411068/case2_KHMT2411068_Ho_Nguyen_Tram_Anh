import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/task.dart';
import '../../models/task_activity.dart';
import '../../services/task_service.dart';
import 'task_edit_screen.dart';
import '../sharing/task_sharing_screen.dart';
import '../assignment/assign_task_screen.dart';

class TaskDetailScreen extends StatefulWidget {
  final Task task;

  const TaskDetailScreen({super.key, required this.task});

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  late Task _task;
  bool _isUpdatingStatus = false;
  List<TaskActivity> _activities = [];
  bool _isLoadingActivities = true;

  @override
  void initState() {
    super.initState();
    _task = widget.task;
    _loadActivities();
  }

  Future<void> _loadActivities() async {
    setState(() => _isLoadingActivities = true);
    final list = await TaskService.getTaskActivities(_task.id);
    if (mounted) {
      setState(() {
        _activities = list;
        _isLoadingActivities = false;
      });
    }
  }

  Future<void> _updateStatus(String newStatus) async {
    if (_task.status == newStatus) return;
    setState(() => _isUpdatingStatus = true);

    try {
      final success = await TaskService.updateTask(_task.id, {
        'status': newStatus,
      });

      if (mounted && success) {
        setState(() {
          _task = Task(
            id: _task.id,
            title: _task.title,
            description: _task.description,
            status: newStatus,
            priority: _task.priority,
            dueDate: _task.dueDate,
          );
          _isUpdatingStatus = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cập nhật trạng thái thành công!')),
        );
        _loadActivities();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUpdatingStatus = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không thể cập nhật trạng thái')),
        );
      }
    }
  }

  Future<void> _deleteTask() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: const Text('Bạn có chắc chắn muốn xóa công việc này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await TaskService.deleteTask(_task.id);
        if (mounted) {
          Navigator.pop(context, true);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Lỗi khi xóa công việc!')),
          );
        }
      }
    }
  }

  Widget _buildActivitySection() {
    final DateFormat formatter = DateFormat('HH:mm - dd/MM/yyyy');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.history_rounded, size: 20, color: Color(0xFF0F172A)),
            SizedBox(width: 8),
            Text(
              'Lịch sử hoạt động',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _isLoadingActivities
            ? const Center(child: Padding(
          padding: EdgeInsets.all(16.0),
          child: CircularProgressIndicator(),
        ))
            : _activities.isEmpty
            ? Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: const Text(
            'Chưa có lịch sử hoạt động nào.',
            style: TextStyle(color: Colors.grey, fontSize: 13),
          ),
        )
            : ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _activities.length,
          itemBuilder: (context, index) {
            final act = _activities[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.record_voice_over_rounded, size: 16, color: Colors.blue.shade700),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        RichText(
                          text: TextSpan(
                            style: const TextStyle(fontSize: 13, color: Colors.black87),
                            children: [
                              TextSpan(
                                text: act.userName,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              TextSpan(text: ' đã ${act.action.toLowerCase()}'),
                            ],
                          ),
                        ),
                        if (act.details.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            act.details,
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                          ),
                        ],
                        const SizedBox(height: 6),
                        Text(
                          formatter.format(act.createdAt),
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Chi tiết công việc'),
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: Colors.black87),
        titleTextStyle: const TextStyle(color: Colors.black87, fontSize: 18, fontWeight: FontWeight.bold),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.blue),
            tooltip: 'Chỉnh sửa',
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TaskEditScreen(task: _task),
                ),
              );
              if (result == true && mounted) {
                Navigator.pop(context, true);
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            tooltip: 'Xóa',
            onPressed: _deleteTask,
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _task.title,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Ưu tiên: ${_task.priority.toUpperCase()}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange.shade900,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _task.status,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade900,
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(height: 32),
              const Text(
                'Mô tả:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 6),
              Text(_task.description ?? 'Không có mô tả chi tiết.'),
              const Divider(height: 32),

              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1976D2),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => TaskSharingScreen(taskId: _task.id),
                          ),
                        );
                        if (mounted) {
                          _loadActivities();
                        }
                      },
                      icon: const Icon(Icons.share, size: 20),
                      label: const Text('Chia sẻ'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AssignTaskScreen(taskId: _task.id),
                          ),
                        );
                        if (mounted) {
                          _loadActivities();
                        }
                      },
                      icon: const Icon(Icons.person_add_alt_1, size: 20),
                      label: const Text('Giao việc'),
                    ),
                  ),
                ],
              ),

              const Divider(height: 32),
              const Text(
                'Đổi trạng thái:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text('Chưa thực hiện'),
                    selected: _task.status == 'todo' || _task.status == 'chua_thuc_hien',
                    onSelected: (selected) => _updateStatus('todo'),
                  ),
                  ChoiceChip(
                    label: const Text('Đang thực hiện'),
                    selected: _task.status == 'in_progress' || _task.status == 'dang_thuc_hien',
                    onSelected: (selected) => _updateStatus('in_progress'),
                  ),
                  ChoiceChip(
                    label: const Text('Đã hoàn thành'),
                    selected: _task.status == 'completed' || _task.status == 'da_hoan_thanh',
                    onSelected: (selected) => _updateStatus('completed'),
                  ),
                ],
              ),
              const Divider(height: 32),
              _buildActivitySection(),
            ],
          ),
        ),
      ),
    );
  }
}