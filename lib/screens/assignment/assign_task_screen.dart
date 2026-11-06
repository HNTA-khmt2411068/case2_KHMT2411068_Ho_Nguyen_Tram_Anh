import 'dart:convert';
import 'package:flutter/material.dart';
import '../../services/api_client.dart';
import '../../services/task_service.dart';

class AssignTaskScreen extends StatefulWidget {
  final String taskId;

  const AssignTaskScreen({super.key, required this.taskId});

  @override
  State<AssignTaskScreen> createState() => _AssignTaskScreenState();
}

class _AssignTaskScreenState extends State<AssignTaskScreen> {
  List<dynamic> _users = [];
  List<dynamic> _filteredUsers = [];
  final List<String> _selectedUserIds = [];
  bool _isLoading = true;
  bool _isSubmitting = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      final usersResponse = await ApiClient.get('/users');
      final taskResponse = await ApiClient.get('/tasks/${widget.taskId}');

      if (usersResponse.statusCode == 200) {
        final data = jsonDecode(usersResponse.body);
        final List list = data is List ? data : (data['users'] ?? []);
        _users = list;
        _filteredUsers = list;
      }

      if (taskResponse.statusCode == 200) {
        final taskData = jsonDecode(taskResponse.body);
        final List existingAssignees = taskData['assigneeIds'] ?? [];
        _selectedUserIds.clear();
        _selectedUserIds.addAll(existingAssignees.map((e) => e.toString()));
      }

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _filterUsers(String query) {
    if (query.isEmpty) {
      setState(() => _filteredUsers = _users);
    } else {
      setState(() {
        _filteredUsers = _users.where((user) {
          final name = (user['fullName'] ?? '').toString().toLowerCase();
          final email = (user['email'] ?? '').toString().toLowerCase();
          final q = query.toLowerCase();
          return name.contains(q) || email.contains(q);
        }).toList();
      });
    }
  }

  Future<void> _submitAssign() async {
    setState(() => _isSubmitting = true);

    try {
      final success = await TaskService.assignTask(widget.taskId, _selectedUserIds);
      if (mounted) {
        setState(() => _isSubmitting = false);
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Cập nhật phân công việc thành công!')),
          );
          Navigator.pop(context, true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Giao việc thất bại. Vui lòng thử lại!')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Có lỗi xảy ra khi giao việc')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Giao việc'),
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: Colors.black87),
        titleTextStyle: const TextStyle(
          color: Colors.black87,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _searchController,
                onChanged: _filterUsers,
                decoration: InputDecoration(
                  hintText: 'Tìm (email/tên)...',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Danh sách người được giao việc:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _filteredUsers.isEmpty
                    ? const Center(
                  child: Text(
                    'Không tìm thấy người dùng phù hợp',
                    style: TextStyle(color: Colors.grey),
                  ),
                )
                    : ListView.builder(
                  itemCount: _filteredUsers.length,
                  itemBuilder: (context, index) {
                    final user = _filteredUsers[index];
                    final String userId = (user['_id'] ?? user['id'] ?? '').toString();
                    final String fullName = user['fullName'] ?? 'Người dùng';
                    final String email = user['email'] ?? '';
                    final bool isSelected = _selectedUserIds.contains(userId);

                    return Card(
                      elevation: 0,
                      margin: const EdgeInsets.only(bottom: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: BorderSide(
                          color: isSelected ? Colors.blue.shade300 : Colors.grey.shade200,
                          width: isSelected ? 1.5 : 1,
                        ),
                      ),
                      color: isSelected ? Colors.blue.shade50.withOpacity(0.4) : Colors.white,
                      child: CheckboxListTile(
                        value: isSelected,
                        activeColor: Colors.blue.shade700,
                        onChanged: (bool? checked) {
                          setState(() {
                            if (checked == true) {
                              _selectedUserIds.add(userId);
                            } else {
                              _selectedUserIds.remove(userId);
                            }
                          });
                        },
                        title: Text(
                          fullName,
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                        ),
                        subtitle: Text(email, style: const TextStyle(fontSize: 13)),
                        secondary: CircleAvatar(
                          backgroundColor: Colors.blue.shade100,
                          child: Text(
                            fullName.isNotEmpty ? fullName[0].toUpperCase() : 'U',
                            style: TextStyle(color: Colors.blue.shade900, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1976D2),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: _isSubmitting ? null : _submitAssign,
                  child: _isSubmitting
                      ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                      : const Text(
                    'Xác nhận giao việc',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}