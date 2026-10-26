import 'package:flutter/material.dart';
import '../../models/user.dart';
import '../../models/task_share.dart';
import '../../services/user_service.dart';
import '../../services/task_share_service.dart';

class TaskSharingScreen extends StatefulWidget {
  final String taskId;

  const TaskSharingScreen({super.key, required this.taskId});

  @override
  State<TaskSharingScreen> createState() => _TaskSharingScreenState();
}

class _TaskSharingScreenState extends State<TaskSharingScreen> {
  final UserService _userService = UserService();
  final TaskShareService _shareService = TaskShareService();

  List<User> _searchResults = [];
  List<TaskShare> _currentShares = [];
  bool _isLoading = false;
  String _selectedPermission = 'viewer';

  @override
  void initState() {
    super.initState();
    _loadShares();
  }

  void _loadShares() async {
    try {
      final shares = await _shareService.getShares(widget.taskId);
      setState(() => _currentShares = shares);
    } catch (_) {}
  }

  void _onSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() => _searchResults = []);
      return;
    }
    final users = await _userService.searchUsers(query);
    setState(() => _searchResults = users);
  }

  void _shareToUser(User user) async {
    setState(() => _isLoading = true);
    final success = await _shareService.shareTask(widget.taskId, user.id, _selectedPermission);
    setState(() => _isLoading = false);

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Đã chia sẻ cho ${user.fullName}')),
        );
        _loadShares();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Thất bại: Chỉ Owner mới có quyền chia sẻ')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chia sẻ công việc')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Ô tìm kiếm & Chọn quyền
            TextField(
              decoration: const InputDecoration(
                labelText: 'Tìm người dùng theo email hoặc tên...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: _onSearch,
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Text('Quyền cấp: '),
                ChoiceChip(
                  label: const Text('Xem (Viewer)'),
                  selected: _selectedPermission == 'viewer',
                  onSelected: (val) => setState(() => _selectedPermission = 'viewer'),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('Sửa (Editor)'),
                  selected: _selectedPermission == 'editor',
                  onSelected: (val) => setState(() => _selectedPermission = 'editor'),
                ),
              ],
            ),
            const Divider(height: 24),

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
                    final u = _searchResults[index];
                    return ListTile(
                      title: Text(u.fullName),
                      subtitle: Text(u.email),
                      trailing: IconButton(
                        icon: const Icon(Icons.person_add, color: Colors.blue),
                        onPressed: () => _shareToUser(u),
                      ),
                    );
                  },
                ),
              ),
              const Divider(),
            ],

            const Align(
              alignment: Alignment.centerLeft,
              child: Text('Đã chia sẻ với:', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            Expanded(
              flex: 2,
              child: _currentShares.isEmpty
                  ? const Center(child: Text('Chưa chia sẻ với ai'))
                  : ListView.builder(
                itemCount: _currentShares.length,
                itemBuilder: (context, index) {
                  final share = _currentShares[index];
                  return ListTile(
                    title: Text('User ID: ${share.userId}'),
                    subtitle: Text('Quyền: ${share.permission.toUpperCase()}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () async {
                        await _shareService.revokeShare(widget.taskId, share.id);
                        _loadShares();
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}