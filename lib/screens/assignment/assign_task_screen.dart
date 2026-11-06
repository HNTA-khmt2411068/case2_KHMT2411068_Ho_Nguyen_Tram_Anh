import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/task_service.dart';

class AssignTaskScreen extends StatefulWidget {
  final String token;
  final String taskId;
  final String taskTitle;

  const AssignTaskScreen({
    Key? key,
    required this.token,
    required this.taskId,
    required this.taskTitle,
  }) : super(key: key);

  @override
  State<AssignTaskScreen> createState() => _AssignTaskScreenState();
}

class _AssignTaskScreenState extends State<AssignTaskScreen> {
  List<dynamic> _users = [];
  final List<String> _selectedUserIds = [];
  String? _primaryUserId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  void _fetchUsers() async {
    final users = await AuthService.getUsers(widget.token);
    setState(() {
      _users = users;
      _isLoading = false;
    });
  }

  void _submitAssignment() async {
    if (_selectedUserIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn ít nhất một người phụ trách!')),
      );
      return;
    }

    final res = await TaskService.assignTask(
      widget.token,
      widget.taskId,
      assigneeIds: _selectedUserIds,
      primaryAssigneeId: _primaryUserId ?? _selectedUserIds.first,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res['message'] ?? 'Phân công thành công!')),
      );
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Giao việc: ${widget.taskTitle}')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(12.0),
            child: Text(
              'Chọn danh sách thành viên thực hiện:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _users.length,
              itemBuilder: (context, index) {
                final user = _users[index];
                final userId = user['_id'];
                final isSelected = _selectedUserIds.contains(userId);
                final isPrimary = _primaryUserId == userId;

                return CheckboxListTile(
                  title: Text(user['fullName'] ?? user['email']),
                  subtitle: Text(isPrimary ? 'Phụ trách chính' : user['email']),
                  value: isSelected,
                  secondary: Radio<String>(
                    value: userId,
                    groupValue: _primaryUserId,
                    onChanged: isSelected
                        ? (val) {
                      setState(() => _primaryUserId = val);
                    }
                        : null,
                  ),
                  onChanged: (bool? checked) {
                    setState(() {
                      if (checked == true) {
                        _selectedUserIds.add(userId);
                        if (_primaryUserId == null) _primaryUserId = userId;
                      } else {
                        _selectedUserIds.remove(userId);
                        if (_primaryUserId == userId) {
                          _primaryUserId = _selectedUserIds.isNotEmpty ? _selectedUserIds.first : null;
                        }
                      }
                    });
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: _submitAssignment,
              style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
              child: const Text('Xác nhận giao việc'),
            ),
          ),
        ],
      ),
    );
  }
}