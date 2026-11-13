import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../services/task_service.dart';
import '../../services/user_service.dart';

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
  List<String> _selectedUserIds = [];
  String? _primaryUserId;
  bool _isLoading = true;

  static const String baseUrl = 'http://10.0.2.2:5000/api';

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  void _fetchData() async {
    setState(() => _isLoading = true);

    final users = await UserService.getUsers(widget.token);

    List<String> currentAssignees = [];
    String? currentPrimary;

    try {
      final res = await http.get(
        Uri.parse('$baseUrl/tasks/${widget.taskId}'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );
      if (res.statusCode == 200) {
        final taskData = jsonDecode(res.body);
        if (taskData['assigneeIds'] != null) {
          final List<dynamic> assignees = taskData['assigneeIds'];
          currentAssignees = assignees.map((e) {
            if (e is Map) return (e['_id'] ?? e['id']).toString();
            return e.toString();
          }).toList();
        }
        if (taskData['primaryAssigneeId'] != null) {
          final primary = taskData['primaryAssigneeId'];
          final parsedPrimary = primary is Map
              ? (primary['_id'] ?? primary['id']).toString()
              : primary.toString();
          if (currentAssignees.contains(parsedPrimary)) {
            currentPrimary = parsedPrimary;
          }
        }
      }
    } catch (e) {
      print('Lỗi tải chi tiết task: $e');
    }

    if (mounted) {
      setState(() {
        _users = users;
        _selectedUserIds = currentAssignees;
        _primaryUserId = currentPrimary ??
            (currentAssignees.isNotEmpty ? currentAssignees.first : null);
        _isLoading = false;
      });
    }
  }

  void _submitAssignment() async {
    final String primaryId = _selectedUserIds.isEmpty
        ? ''
        : (_primaryUserId ?? _selectedUserIds.first);

    final res = await TaskService.assignTask(
      widget.token,
      widget.taskId,
      assigneeIds: _selectedUserIds,
      primaryAssigneeId: primaryId,
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
            child: _users.isEmpty
                ? const Center(
                child: Text('Chưa có thành viên nào trong hệ thống!'))
                : ListView.builder(
              itemCount: _users.length,
              itemBuilder: (context, index) {
                final user = _users[index];
                final userId =
                (user['_id'] ?? user['id']).toString();
                final isSelected =
                _selectedUserIds.contains(userId);
                final isPrimary =
                    isSelected && (_primaryUserId == userId);

                return CheckboxListTile(
                  title: Text(
                      user['fullName'] ?? user['email'] ?? ''),
                  subtitle: Text(
                    isPrimary
                        ? 'Phụ trách chính ⭐'
                        : (user['email'] ?? ''),
                    style: TextStyle(
                      color: isPrimary
                          ? Colors.amber[800]
                          : Colors.grey[700],
                      fontWeight: isPrimary
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                  value: isSelected,
                  secondary: isSelected
                      ? IconButton(
                    icon: Icon(
                      isPrimary
                          ? Icons.star
                          : Icons.star_border,
                      color: isPrimary
                          ? Colors.amber
                          : Colors.grey,
                    ),
                    tooltip:
                    'Đặt làm người phụ trách chính',
                    onPressed: () {
                      setState(() => _primaryUserId = userId);
                    },
                  )
                      : null,
                  onChanged: (bool? checked) {
                    setState(() {
                      if (checked == true) {
                        if (!_selectedUserIds.contains(userId)) {
                          _selectedUserIds.add(userId);
                        }
                        if (_primaryUserId == null) {
                          _primaryUserId = userId;
                        }
                      } else {
                        _selectedUserIds.remove(userId);
                        if (_primaryUserId == userId) {
                          _primaryUserId =
                          _selectedUserIds.isNotEmpty
                              ? _selectedUserIds.first
                              : null;
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
              style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50)),
              child: const Text('Xác nhận giao việc'),
            ),
          ),
        ],
      ),
    );
  }
}