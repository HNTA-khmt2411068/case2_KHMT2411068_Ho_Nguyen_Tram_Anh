import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../services/task_service.dart';
import '../../services/user_service.dart';
import '../../utils/constants.dart';

class AssignTaskScreen extends StatefulWidget {
  final String token;
  final String taskId;
  final String taskTitle;

  const AssignTaskScreen({
    super.key,
    required this.token,
    required this.taskId,
    required this.taskTitle,
  });

  @override
  State<AssignTaskScreen> createState() => _AssignTaskScreenState();
}

class _AssignTaskScreenState extends State<AssignTaskScreen> {
  List<dynamic> _users = [];
  List<String> _assignedUserIds = [];
  Map<String, Map<String, dynamic>> _populatedUsers = {};
  String? _primaryUserId;

  String? _selectedUserId;
  String _selectedRole = 'member'; // 'member' hoặc 'primary'
  bool _isLoading = true;
  bool _hasChanged = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final users = await UserService.getUsers(widget.token);

    List<String> currentAssignees = [];
    Map<String, Map<String, dynamic>> populatedMap = {};
    String? currentPrimary;

    try {
      final res = await http.get(
        Uri.parse('${AppConstants.baseUrl}/tasks/${widget.taskId}'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );
      if (res.statusCode == 200) {
        final taskData = jsonDecode(res.body);
        if (taskData['assigneeIds'] != null) {
          final List<dynamic> assignees = taskData['assigneeIds'];
          for (var e in assignees) {
            if (e is Map) {
              final id = (e['_id'] ?? e['id']).toString();
              currentAssignees.add(id);
              populatedMap[id] = Map<String, dynamic>.from(e);
            } else {
              currentAssignees.add(e.toString());
            }
          }
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
      debugPrint('Lỗi tải chi tiết task: $e');
    }

    if (mounted) {
      setState(() {
        _users = users;
        _assignedUserIds = currentAssignees;
        _populatedUsers = populatedMap;
        _primaryUserId = currentPrimary ??
            (currentAssignees.isNotEmpty ? currentAssignees.first : null);
        _selectedUserId = null;
        _selectedRole = 'member';
        _isLoading = false;
      });
    }
  }

  Map<String, dynamic>? _findUserInfo(String userId) {
    for (var u in _users) {
      if ((u['_id'] ?? u['id']).toString() == userId) {
        return Map<String, dynamic>.from(u);
      }
    }
    return _populatedUsers[userId];
  }

  Future<void> _saveAssignments({
    required List<String> updatedAssignees,
    required String? updatedPrimary,
    required String fallbackSuccessMsg,
  }) async {
    final String primaryId = updatedAssignees.isEmpty
        ? ''
        : (updatedPrimary != null && updatedAssignees.contains(updatedPrimary)
        ? updatedPrimary
        : updatedAssignees.first);

    final res = await TaskService.assignTask(
      widget.token,
      widget.taskId,
      assigneeIds: updatedAssignees,
      primaryAssigneeId: primaryId,
    );

    if (mounted) {
      _hasChanged = true;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res['message'] ?? fallbackSuccessMsg)),
      );
      await _loadData();
    }
  }

  void _assignUser() async {
    if (_selectedUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn thành viên cần giao việc!')),
      );
      return;
    }

    final updatedList = List<String>.from(_assignedUserIds);
    if (!updatedList.contains(_selectedUserId!)) {
      updatedList.add(_selectedUserId!);
    }

    String? nextPrimary = _primaryUserId;
    if (_selectedRole == 'primary' || nextPrimary == null) {
      nextPrimary = _selectedUserId!;
    }

    await _saveAssignments(
      updatedAssignees: updatedList,
      updatedPrimary: nextPrimary,
      fallbackSuccessMsg: 'Giao việc thành công!',
    );
  }

  void _setPrimaryAssignee(String userId) async {
    if (_primaryUserId == userId) return;

    await _saveAssignments(
      updatedAssignees: _assignedUserIds,
      updatedPrimary: userId,
      fallbackSuccessMsg: 'Đã cập nhật người phụ trách chính!',
    );
  }

  void _removeAssignee(String userId) async {
    final updatedList = List<String>.from(_assignedUserIds)..remove(userId);
    final String? nextPrimary = (_primaryUserId == userId)
        ? (updatedList.isNotEmpty ? updatedList.first : null)
        : _primaryUserId;

    await _saveAssignments(
      updatedAssignees: updatedList,
      updatedPrimary: nextPrimary,
      fallbackSuccessMsg: 'Đã hủy giao việc cho thành viên!',
    );
  }

  @override
  Widget build(BuildContext context) {
    final availableUsers = _users.where((u) {
      final id = (u['_id'] ?? u['id']).toString();
      return !_assignedUserIds.contains(id);
    }).toList();

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          Navigator.pop(context, _hasChanged);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('Giao việc: ${widget.taskTitle}'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context, _hasChanged),
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Chọn người được giao việc:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                isExpanded: true,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding:
                  EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                hint: Text(
                  availableUsers.isEmpty
                      ? 'Đã giao cho tất cả thành viên'
                      : 'Chọn thành viên',
                ),
                initialValue: _selectedUserId,
                items: availableUsers.map((u) {
                  final id = (u['_id'] ?? u['id']).toString();
                  return DropdownMenuItem<String>(
                    value: id,
                    child: Text(
                      '${u['fullName']} (${u['email']})',
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
                onChanged: availableUsers.isEmpty
                    ? null
                    : (val) => setState(() => _selectedUserId = val),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Text(
                    'Vai trò: ',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  Expanded(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: _selectedRole,
                      items: const [
                        DropdownMenuItem(
                          value: 'member',
                          child: Text('Thành viên thực hiện'),
                        ),
                        DropdownMenuItem(
                          value: 'primary',
                          child: Text('Phụ trách chính ⭐'),
                        ),
                      ],
                      onChanged: (val) =>
                          setState(() => _selectedRole = val!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: _assignUser,
                  child: const Text(
                    'Xác nhận giao việc',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
              const Divider(height: 32),
              const Text(
                'Danh sách người được giao:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: _assignedUserIds.isEmpty
                    ? const Center(
                  child: Text('Chưa giao việc cho ai!'),
                )
                    : ListView.builder(
                  itemCount: _assignedUserIds.length,
                  itemBuilder: (context, index) {
                    final userId = _assignedUserIds[index];
                    final userInfo = _findUserInfo(userId);
                    final isPrimary = (_primaryUserId == userId);

                    final displayName = userInfo?['fullName'] ??
                        userInfo?['email'] ??
                        'Thành viên';
                    final email = userInfo?['email'] ?? '';

                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(displayName),
                      subtitle: Text(
                        isPrimary
                            ? 'Phụ trách chính ⭐${email.isNotEmpty ? ' • $email' : ''}'
                            : 'Thành viên thực hiện${email.isNotEmpty ? ' • $email' : ''}',
                        style: TextStyle(
                          color: isPrimary
                              ? Colors.amber[800]
                              : Colors.grey[700],
                          fontWeight: isPrimary
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
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
                            onPressed: isPrimary
                                ? null
                                : () =>
                                _setPrimaryAssignee(userId),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.remove_circle,
                              color: Colors.red,
                            ),
                            tooltip: 'Hủy giao việc',
                            onPressed: () =>
                                _removeAssignee(userId),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}