import 'package:flutter/material.dart';
import '../../models/user.dart';
import '../../services/user_service.dart';
import '../../services/task_share_service.dart';

class AssignTaskScreen extends StatefulWidget {
  final String taskId;

  const AssignTaskScreen({super.key, required this.taskId});

  @override
  State<AssignTaskScreen> createState() => _AssignTaskScreenState();
}

class _AssignTaskScreenState extends State<AssignTaskScreen> {
  final UserService _userService = UserService();
  final TaskShareService _shareService = TaskShareService();

  List<User> _searchResults = [];
  final List<User> _selectedUsers = [];
  User? _primaryUser;
  bool _isLoading = false;

  void _onSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() => _searchResults = []);
      return;
    }
    final users = await _userService.searchUsers(query);
    setState(() => _searchResults = users);
  }

  void _toggleSelectUser(User user) {
    setState(() {
      if (_selectedUsers.any((u) => u.id == user.id)) {
        _selectedUsers.removeWhere((u) => u.id == user.id);
        if (_primaryUser?.id == user.id) {
          _primaryUser = null;
        }
      } else {
        _selectedUsers.add(user);
      }
    });
  }

  void _submitAssignment() async {
    if (_selectedUsers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn ít nhất 1 người để giao việc')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final assigneeIds = _selectedUsers.map((u) => u.id).toList();
    final success = await _shareService.assignTask(
      widget.taskId,
      assigneeIds,
      primaryAssigneeId: _primaryUser?.id,
    );

    setState(() => _isLoading = false);

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Giao việc thành công!')),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Thất bại: Cần quyền Editor trở lên để giao việc')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Giao việc')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [

            TextField(
              decoration: const InputDecoration(
                labelText: 'Tìm người được giao việc (email/tên)...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: _onSearch,
            ),
            const SizedBox(height: 12),


            if (_searchResults.isNotEmpty) ...[
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('Kết quả tìm kiếm:', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              Expanded(
                flex: 1,
                child: ListView.builder(
                  itemCount: _searchResults.length,
                  itemBuilder: (context, index) {
                    final user = _searchResults[index];
                    final isSelected = _selectedUsers.any((u) => u.id == user.id);
                    return ListTile(
                      title: Text(user.fullName),
                      subtitle: Text(user.email),
                      trailing: Icon(
                        isSelected ? Icons.check_circle : Icons.circle_outlined,
                        color: isSelected ? Colors.green : null,
                      ),
                      onTap: () => _toggleSelectUser(user),
                    );
                  },
                ),
              ),
              const Divider(),
            ],

            const Align(
              alignment: Alignment.centerLeft,
              child: Text('Danh sách người được giao việc:', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 8),
            Expanded(
              flex: 2,
              child: _selectedUsers.isEmpty
                  ? const Center(child: Text('Chưa chọn người nào'))
                  : ListView.builder(
                itemCount: _selectedUsers.length,
                itemBuilder: (context, index) {
                  final user = _selectedUsers[index];
                  final isPrimary = _primaryUser?.id == user.id;

                  return ListTile(
                    title: Text(user.fullName),
                    subtitle: Text(user.email),
                    leading: ChoiceChip(
                      label: Text(isPrimary ? 'Phụ trách chính' : 'Chọn làm chính'),
                      selected: isPrimary,
                      onSelected: (selected) {
                        setState(() {
                          _primaryUser = selected ? user : null;
                        });
                      },
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                      onPressed: () => _toggleSelectUser(user),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _submitAssignment,
                child: const Text('Xác nhận giao việc'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}