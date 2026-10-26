import 'package:flutter/material.dart';
import '../../services/task_service.dart';

class TaskCreateScreen extends StatefulWidget {
  const TaskCreateScreen({super.key});

  @override
  State<TaskCreateScreen> createState() => _TaskCreateScreenState();
}

class _TaskCreateScreenState extends State<TaskCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _taskService = TaskService();

  String _priority = 'medium';
  String _status = 'todo';
  bool _isLoading = false;

  void _submitData() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final success = await _taskService.createTask({
      'title': _titleController.text.trim(),
      'description': _descriptionController.text.trim(),
      'priority': _priority,
      'status': _status,
    });

    setState(() => _isLoading = false);

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tạo công việc thành công!')),
        );
        Navigator.pop(context, true); // Trả về true để load lại danh sách
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tạo công việc thất bại')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Thêm công việc mới')),
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
                validator: (val) =>
                val == null || val.isEmpty ? 'Vui lòng nhập tên công việc' : null,
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
                decoration: const InputDecoration(labelText: 'Độ ưu tiên'),
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
                child: const Text('Tạo công việc'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}