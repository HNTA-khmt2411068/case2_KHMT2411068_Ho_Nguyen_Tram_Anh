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
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late String _priority;
  late String _status;
  DateTime? _startDate;
  DateTime? _dueDate;
  bool _isSaving = false;

  static const Color _bgTaroMilk = Color(0xFFF5F0FF);
  static const Color _taroLight = Color(0xFFEBE0FF);
  static const Color _taroPrimary = Color(0xFF8367D8);
  static const Color _taroDark = Color(0xFF3E2D6B);
  static const Color _taroMuted = Color(0xFF7B6F99);
  static const Color _taroBorder = Color(0xFFE2D7FA);

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
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: _taroPrimary,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: _taroDark,
            ),
          ),
          child: child!,
        );
      },
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
      final response = await ApiClient.put(
        '/tasks/$taskId',
        {
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

  InputDecoration _buildInputDecoration({
    required String label,
    required IconData icon,
    bool alignLabelWithHint = false,
  }) {
    return InputDecoration(
      labelText: label,
      alignLabelWithHint: alignLabelWithHint,
      labelStyle: const TextStyle(color: _taroMuted, fontSize: 14),
      prefixIcon: Padding(
        padding: EdgeInsets.only(bottom: alignLabelWithHint ? 42 : 0),
        child: Icon(icon, color: _taroPrimary, size: 20),
      ),
      filled: true,
      fillColor: const Color(0xFFFAF8FF),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _taroBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _taroBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _taroPrimary, width: 1.6),
      ),
    );
  }

  Widget _buildDateBox({
    required String title,
    required DateTime? date,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final hasDate = date != null;
    return Material(
      color: hasDate ? _taroLight.withValues(alpha: 0.45) : const Color(0xFFFAF8FF),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: hasDate ? _taroPrimary : _taroBorder,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: hasDate ? _taroPrimary : _taroLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  size: 16,
                  color: hasDate ? Colors.white : _taroPrimary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 11,
                        color: _taroMuted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      DateFormatter.formatDate(date),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: hasDate ? _taroDark : _taroPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgTaroMilk,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _taroDark),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Chỉnh sửa công việc',
          style: TextStyle(
            color: _taroDark,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 6, 18, 24),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x148367D8),
                  blurRadius: 24,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _titleController,
                    style: const TextStyle(color: _taroDark, fontSize: 15),
                    decoration: _buildInputDecoration(
                      label: 'Tên công việc',
                      icon: Icons.edit_note_rounded,
                    ),
                    validator: (v) =>
                        Validators.validateRequired(v, 'tên công việc'),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _descriptionController,
                    maxLines: 3,
                    style: const TextStyle(color: _taroDark, fontSize: 14),
                    decoration: _buildInputDecoration(
                      label: 'Mô tả chi tiết',
                      icon: Icons.description_outlined,
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: _priority,
                    dropdownColor: Colors.white,
                    icon: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: _taroPrimary,
                    ),
                    style: const TextStyle(color: _taroDark, fontSize: 14),
                    decoration: _buildInputDecoration(
                      label: 'Mức độ ưu tiên',
                      icon: Icons.flag_outlined,
                    ),
                    items: const [
                      DropdownMenuItem(value: 'low', child: Text('Thấp')),
                      DropdownMenuItem(
                        value: 'medium',
                        child: Text('Trung bình'),
                      ),
                      DropdownMenuItem(value: 'high', child: Text('Cao')),
                    ],
                    onChanged: (v) {
                      if (v != null) setState(() => _priority = v);
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: _status,
                    dropdownColor: Colors.white,
                    icon: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: _taroPrimary,
                    ),
                    style: const TextStyle(color: _taroDark, fontSize: 14),
                    decoration: _buildInputDecoration(
                      label: 'Trạng thái',
                      icon: Icons.donut_large_rounded,
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'todo',
                        child: Text('Chưa thực hiện'),
                      ),
                      DropdownMenuItem(
                        value: 'in_progress',
                        child: Text('Đang thực hiện'),
                      ),
                      DropdownMenuItem(
                        value: 'completed',
                        child: Text('Đã hoàn thành'),
                      ),
                    ],
                    onChanged: (v) {
                      if (v != null) setState(() => _status = v);
                    },
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: _buildDateBox(
                          title: 'Ngày bắt đầu',
                          date: _startDate,
                          icon: Icons.calendar_today_rounded,
                          onTap: () => _pickDate(true),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildDateBox(
                          title: 'Hạn hoàn thành',
                          date: _dueDate,
                          icon: Icons.event_available_rounded,
                          onTap: () => _pickDate(false),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _isSaving
                      ? const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: CircularProgressIndicator(
                        color: _taroPrimary,
                      ),
                    ),
                  )
                      : ElevatedButton(
                    onPressed: _saveTask,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _taroPrimary,
                      foregroundColor: Colors.white,
                      elevation: 3,
                      shadowColor: const Color(0x558367D8),
                      minimumSize: const Size.fromHeight(52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Lưu thay đổi',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}