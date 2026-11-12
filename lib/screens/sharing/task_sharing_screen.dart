import 'package:flutter/material.dart';
import '../../models/task_share.dart';
import '../../services/task_share_service.dart';
import '../../services/user_service.dart';

class TaskSharingScreen extends StatefulWidget {
  final String token;
  final String taskId;
  final String taskTitle;

  const TaskSharingScreen({
    Key? key,
    required this.token,
    required this.taskId,
    required this.taskTitle,
  }) : super(key: key);

  @override
  State<TaskSharingScreen> createState() => _TaskSharingScreenState();
}

class _TaskSharingScreenState extends State<TaskSharingScreen> {
  List<TaskShare> _shares = [];
  List<dynamic> _users = [];
  bool _isLoading = true;
  String? _selectedUserId;
  String _selectedPermission = 'viewer';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() async {
    setState(() => _isLoading = true);
    final shares = await TaskShareService.getTaskShares(widget.token, widget.taskId);
    final users = await UserService.getUsers(widget.token);
    if (mounted) {
      setState(() {
        _shares = shares;
        _users = users;
        _isLoading = false;
      });
    }
  }

  void _shareTask() async {
    if (_selectedUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn người cần chia sẻ!')),
      );
      return;
    }

    final res = await TaskShareService.shareTask(
      widget.token,
      widget.taskId,
      userId: _selectedUserId!,
      permission: _selectedPermission,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res['message'] ?? 'Chia sẻ thành công!')),
      );
      _loadData();
    }
  }

  void _revokeShare(String shareId) async {
    final res = await TaskShareService.revokeShare(widget.token, widget.taskId, shareId);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res['message'] ?? 'Đã thu hồi quyền chia sẻ!')),
      );
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Chia sẻ: ${widget.taskTitle}')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Chọn người nhận chia sẻ:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              hint: const Text('Chọn thành viên'),
              initialValue: _selectedUserId,
              items: _users.map((u) {
                return DropdownMenuItem<String>(
                  value: u['_id'],
                  child: Text('${u['fullName']} (${u['email']})'),
                );
              }).toList(),
              onChanged: (val) => setState(() => _selectedUserId = val),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Text('Phân quyền: ', style: TextStyle(fontWeight: FontWeight.w500)),
                Expanded(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: _selectedPermission,
                    items: const [
                      DropdownMenuItem(value: 'viewer', child: Text('Chỉ xem (Viewer)')),
                      DropdownMenuItem(value: 'editor', child: Text('Chỉnh sửa (Editor)')),
                    ],
                    onChanged: (val) => setState(() => _selectedPermission = val!),
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
                onPressed: _shareTask,
                child: const Text('Xác nhận chia sẻ', style: TextStyle(fontSize: 16)),
              ),
            ),
            const Divider(height: 32),
            const Text('Danh sách người được chia sẻ:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Expanded(
              child: _shares.isEmpty
                  ? const Center(child: Text('Chưa chia sẻ cho ai!'))
                  : ListView.builder(
                itemCount: _shares.length,
                itemBuilder: (context, index) {
                  final share = _shares[index];
                  final userInfo = share.user;
                  return ListTile(
                    title: Text(userInfo?['fullName'] ?? userInfo?['email'] ?? 'N/A'),
                    subtitle: Text('Quyền: ${share.permission == 'editor' ? 'Chỉnh sửa' : 'Chỉ xem'}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.remove_circle, color: Colors.red),
                      onPressed: () => _revokeShare(share.id),
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