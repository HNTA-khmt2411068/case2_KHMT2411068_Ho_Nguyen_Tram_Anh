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
  String _selectedRole = 'member';
  bool _isLoading = true;
  bool _hasChanged = false;

  static const Color _bgTaroMilk = Color(0xFFF5F0FF);
  static const Color _taroLight = Color(0xFFEBE0FF);
  static const Color _taroPrimary = Color(0xFF8367D8);
  static const Color _taroDark = Color(0xFF3E2D6B);
  static const Color _taroMuted = Color(0xFF7B6F99);
  static const Color _taroBorder = Color(0xFFE2D7FA);

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
        const SnackBar(
          content: Text('Vui lòng chọn thành viên cần giao việc!'),
        ),
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

  InputDecoration _buildDropdownDecoration(IconData icon) {
    return InputDecoration(
      prefixIcon: Icon(icon, color: _taroPrimary, size: 20),
      filled: true,
      fillColor: const Color(0xFFFAF8FF),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
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
        backgroundColor: _bgTaroMilk,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          titleSpacing: 0,
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: _taroDark,
            ),
            onPressed: () => Navigator.pop(context, _hasChanged),
          ),
          title: Text(
            'Giao việc: ${widget.taskTitle}',
            style: const TextStyle(
              color: _taroDark,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        body: _isLoading
            ? const Center(
          child: CircularProgressIndicator(color: _taroPrimary),
        )
            : Padding(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x148367D8),
                      blurRadius: 22,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Chọn người được giao việc',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: _taroDark,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      dropdownColor: Colors.white,
                      icon: const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: _taroPrimary,
                      ),
                      decoration: _buildDropdownDecoration(
                        Icons.person_search_outlined,
                      ),
                      hint: Text(
                        availableUsers.isEmpty
                            ? 'Đã giao cho tất cả thành viên'
                            : 'Chọn thành viên',
                        style: const TextStyle(
                          color: _taroMuted,
                          fontSize: 14,
                        ),
                      ),
                      initialValue: _selectedUserId,
                      items: availableUsers.map((u) {
                        final id = (u['_id'] ?? u['id']).toString();
                        return DropdownMenuItem<String>(
                          value: id,
                          child: Text(
                            '${u['fullName']} (${u['email']})',
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: _taroDark,
                              fontSize: 14,
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: availableUsers.isEmpty
                          ? null
                          : (val) =>
                          setState(() => _selectedUserId = val),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Vai trò thực hiện',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: _taroDark,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      dropdownColor: Colors.white,
                      icon: const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: _taroPrimary,
                      ),
                      decoration: _buildDropdownDecoration(
                        Icons.badge_outlined,
                      ),
                      initialValue: _selectedRole,
                      items: const [
                        DropdownMenuItem(
                          value: 'member',
                          child: Text(
                            'Thành viên thực hiện',
                            style: TextStyle(
                              color: _taroDark,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'primary',
                          child: Text(
                            'Phụ trách chính ⭐',
                            style: TextStyle(
                              color: _taroDark,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                      onChanged: (val) =>
                          setState(() => _selectedRole = val!),
                    ),
                    const SizedBox(height: 18),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _taroPrimary,
                        foregroundColor: Colors.white,
                        elevation: 3,
                        shadowColor: const Color(0x558367D8),
                        minimumSize: const Size.fromHeight(50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: _assignUser,
                      child: const Text(
                        'Xác nhận giao việc',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  'Danh sách người được giao (${_assignedUserIds.length})',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: _taroDark,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: _assignedUserIds.isEmpty
                    ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: _taroLight,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(
                          Icons.group_off_rounded,
                          color: _taroPrimary,
                          size: 28,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Chưa giao việc cho ai!',
                        style: TextStyle(
                          color: _taroMuted,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
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

                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: isPrimary
                              ? const Color(0xFFF5D47A)
                              : const Color(0xFFEDE6FC),
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x0D8367D8),
                            blurRadius: 12,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: isPrimary
                                ? const Color(0xFFFFF4DB)
                                : _taroLight,
                            child: Text(
                              displayName.toString().isNotEmpty
                                  ? displayName
                                  .toString()[0]
                                  .toUpperCase()
                                  : 'U',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isPrimary
                                    ? const Color(0xFF9A6700)
                                    : _taroPrimary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                              CrossAxisAlignment.start,
                              children: [
                                Text(
                                  displayName.toString(),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: _taroDark,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  isPrimary
                                      ? 'Phụ trách chính ⭐${email.isNotEmpty ? ' • $email' : ''}'
                                      : 'Thành viên thực hiện${email.isNotEmpty ? ' • $email' : ''}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isPrimary
                                        ? const Color(0xFF9A6700)
                                        : _taroMuted,
                                    fontWeight: isPrimary
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              isPrimary
                                  ? Icons.star_rounded
                                  : Icons.star_border_rounded,
                              color: isPrimary
                                  ? const Color(0xFFF59E0B)
                                  : _taroMuted,
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
                              Icons.remove_circle_outline_rounded,
                              color: Colors.redAccent,
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