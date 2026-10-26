import 'package:flutter/material.dart';
import '../../models/task.dart';
import '../../services/task_service.dart';

class TaskEditScreen extends StatefulWidget {
  final Task task;

  const TaskEditScreen({super.key, required this.task});

  @override
  State<TaskEditScreen> createState() => _TaskEditScreenState();
}

class _TaskEditScreenState extends State<TaskEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  final _taskService = TaskService();

  late String _priority;
  late String _status;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.task.title);
    _descriptionController = TextEditingController(text: widget.task.description);
    _priority = widget.task.priority;
    _status = widget.task.status;
  }

  void _submitData() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final success = await _taskService.updateTask(widget.task.id, {
      'title': _titleController.text.trim(),
      'description': _descriptionController.text.trim(),
      'priority': _priority,
      'status': _status,
    });

    setState(() => _isLoading = false);

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cập nhật công việc thành công!')),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không có quyền hoặc sửa thất bại')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chỉnh sửa công việc')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Tên công việc *'),
                validator: (val) => val == null || val.isEmpty ? 'Không được bỏ trống' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Mô tả công việc'),
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _priority,
                decoration: const InputDecoration(labelText: 'Mức độ ưu tiên'),
                items: const [
                  DropdownMenuItem(value: 'low', child: Text('Thấp')),
                  DropdownMenuItem(value: 'medium', child: Text('Trung bình')),
                  DropdownMenuItem(value: 'high', child: Text('Cao')),
                ],
                onChanged: (val) => setState(() => _priority = val!),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _status,
                decoration: const InputDecoration(labelText: 'Trạng thái'),
                items: const [
                  DropdownMenuItem(value: 'todo', child: Text('Chưa thực hiện')),
                  DropdownMenuItem(value: 'in_progress', child: Text('Đang thực hiện')),
                  DropdownMenuItem(value: 'completed', child: Text('Đã hoàn thành')),
                ],
                onChanged: (val) => setState(() => _status = val!),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _submitData,
                child: const Text('Cập nhật'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}