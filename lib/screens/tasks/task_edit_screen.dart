import 'package:flutter/material.dart';
import '../../services/api_client.dart';
import '../../utils/date_formatter.dart';
import '../../utils/validators.dart';

class TaskEditScreen extends StatefulWidget {
  final dynamic task;

  const TaskEditScreen({super.key, required this.task});

  @override
  State<TaskEditScreen> createState() => _TaskEditScreenState();
}

class _TaskEditScreenState extends State<TaskEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final ApiClient _apiClient = ApiClient();

  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late String _priority;
  late String _status;
  DateTime? _startDate;
  DateTime? _dueDate;
  bool _isSaving = false;

  dynamic _readField(String key) {
    final t = widget.task;
    if (t is Map) return t[key] ?? (key == 'id' ? t['_id'] : null);
    switch (key) {
      case 'id':
        return t.id;
      case 'title':
        return t.title;
      case 'description':
        return t.description;
      case 'priority':
        return t.priority;
      case 'status':
        return t.status;
      case 'startDate':
        return t.startDate;
      case 'dueDate':
        return t.dueDate;
      default:
        return null;
    }
  }

  DateTime? _toDateTime(dynamic val) {
    if (val is DateTime) return val;
    if (val is String && val.isNotEmpty) return DateTime.tryParse(val);
    return null;
  }

  @override
  void initState() {
    super.initState();
    _titleController =
        TextEditingController(text: (_readField('title') ?? '').toString());
    _descriptionController = TextEditingController(
        text: (_readField('description') ?? '').toString());
    _priority = (_readField('priority') ?? 'medium').toString();
    _status = (_readField('status') ?? 'todo').toString();
    _startDate = _toDateTime(_readField('startDate'));
    _dueDate = _toDateTime(_readField('dueDate'));
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickDate(bool isStart) async {
    final initial = (isStart ? _startDate : _dueDate) ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
        } else {
          _dueDate = picked;
        }
      });
    }
  }

  Future<void> _saveTask() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final taskId = _readField('id').toString();
      final response = await _apiClient.put(
        '/tasks/$taskId',
        body: {
          'title': _titleController.text.trim(),
          'description': _descriptionController.text.trim(),
          'priority': _priority,
          'status': _status,
          'startDate': _startDate?.toIso8601String(),
          'dueDate': _dueDate?.toIso8601String(),
        },
      );

      if (!mounted) return;
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cập nhật công việc thành công')),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không có quyền hoặc lỗi cập nhật')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi kết nối: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chỉnh sửa công việc')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Tên công việc',
                border: OutlineInputBorder(),
              ),
              validator: (v) => Validators.validateRequired(v, 'tên công việc'),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Mô tả chi tiết',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              initialValue: _priority,
              decoration: const InputDecoration(
                labelText: 'Mức độ ưu tiên',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'low', child: Text('Thấp')),
                DropdownMenuItem(value: 'medium', child: Text('Trung bình')),
                DropdownMenuItem(value: 'high', child: Text('Cao')),
              ],
              onChanged: (v) {
                if (v != null) setState(() => _priority = v);
              },
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              initialValue: _status,
              decoration: const InputDecoration(
                labelText: 'Trạng thái',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'todo', child: Text('Chưa thực hiện')),
                DropdownMenuItem(
                    value: 'in_progress', child: Text('Đang thực hiện')),
                DropdownMenuItem(
                    value: 'completed', child: Text('Đã hoàn thành')),
              ],
              onChanged: (v) {
                if (v != null) setState(() => _status = v);
              },
            ),
            const SizedBox(height: 14),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Ngày bắt đầu'),
              subtitle: Text(DateFormatter.formatDate(_startDate)),
              trailing: const Icon(Icons.calendar_today),
              onTap: () => _pickDate(true),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Hạn hoàn thành'),
              subtitle: Text(DateFormatter.formatDate(_dueDate)),
              trailing: const Icon(Icons.event),
              onTap: () => _pickDate(false),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isSaving ? null : _saveTask,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Text(_isSaving ? 'Đang lưu...' : 'Lưu thay đổi'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}