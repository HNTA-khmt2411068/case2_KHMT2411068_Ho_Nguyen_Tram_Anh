import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/task_service.dart';

class TaskCreateScreen extends StatefulWidget {
  final String token;
  const TaskCreateScreen({Key? key, required this.token}) : super(key: key);

  @override
  State<TaskCreateScreen> createState() => _TaskCreateScreenState();
}

class _TaskCreateScreenState extends State<TaskCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  String _priority = 'medium';
  String _status = 'todo';
  DateTime? _startDate;
  DateTime? _dueDate;
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
        } else {
          _dueDate = picked;
        }
      });
    }
  }

  void _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_startDate == null || _dueDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn ngày bắt đầu và hạn hoàn thành')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final res = await TaskService.createTask(
      widget.token,
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      priority: _priority,
      status: _status,
      startDate: _startDate,
      dueDate: _dueDate,
    );

    setState(() => _isLoading = false);

    if (mounted) {
      if (res['success'] == true || res['_id'] != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tạo công việc mới thành công!')),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res['message'] ?? 'Tạo công việc thất bại')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy');

    return Scaffold(
      appBar: AppBar(title: const Text('Thêm công việc mới')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Tên công việc',
                  border: OutlineInputBorder(),
                ),
                validator: (val) => (val == null || val.isEmpty) ? 'Vui lòng nhập tên công việc' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Mô tả công việc',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _priority,
                decoration: const InputDecoration(
                  labelText: 'Mức độ ưu tiên',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'low', child: Text('Thấp (Low)')),
                  DropdownMenuItem(value: 'medium', child: Text('Trung bình (Medium)')),
                  DropdownMenuItem(value: 'high', child: Text('Cao (High)')),
                ],
                onChanged: (val) => setState(() => _priority = val!),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _status,
                decoration: const InputDecoration(
                  labelText: 'Trạng thái ban đầu',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'todo', child: Text('Chưa thực hiện')),
                  DropdownMenuItem(value: 'in_progress', child: Text('Đang thực hiện')),
                  DropdownMenuItem(value: 'completed', child: Text('Đã hoàn thành')),
                ],
                onChanged: (val) => setState(() => _status = val!),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.calendar_today),
                      label: Text(_startDate == null ? 'Ngày bắt đầu' : dateFormat.format(_startDate!)),
                      onPressed: () => _selectDate(context, true),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.event),
                      label: Text(_dueDate == null ? 'Hạn hoàn thành' : dateFormat.format(_dueDate!)),
                      onPressed: () => _selectDate(context, false),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                onPressed: _handleSubmit,
                style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
                child: const Text('Lưu công việc'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}