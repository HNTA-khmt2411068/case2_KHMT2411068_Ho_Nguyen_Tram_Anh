import 'package:flutter/material.dart';
import '../../models/task.dart';
import '../../services/auth_service.dart';
import '../auth/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  final String token;
  final List<Task> tasks;

  const ProfileScreen({
    Key? key,
    required this.token,
    this.tasks = const [],
  }) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nameController = TextEditingController();
  final _currentPassController = TextEditingController();
  final _newPassController = TextEditingController();

  String _email = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  void _loadProfile() async {
    final res = await AuthService.getMe(widget.token);
    if (res['_id'] != null || res['id'] != null) {
      setState(() {
        _nameController.text = res['fullName'] ?? '';
        _email = res['email'] ?? '';
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  void _updateProfile() async {
    final res = await AuthService.updateMe(widget.token, _nameController.text.trim(), null);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res['message'] ?? 'Cập nhật thành công!')),
      );
    }
  }

  void _changePassword() async {
    if (_currentPassController.text.isEmpty || _newPassController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập đầy đủ mật khẩu!')),
      );
      return;
    }

    final res = await AuthService.changePassword(
      widget.token,
      _currentPassController.text,
      _newPassController.text,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res['message'] ?? 'Đổi mật khẩu thất bại!')),
      );
      if (res['message'] == 'Đổi mật khẩu thành công!') {
        _currentPassController.clear();
        _newPassController.clear();
      }
    }
  }

  void _logout() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final int total = widget.tasks.length;
    final int todo = widget.tasks.where((t) => t.status == 'todo').length;
    final int inProgress = widget.tasks.where((t) => t.status == 'in_progress').length;
    final int completed = widget.tasks.where((t) => t.status == 'completed').length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hồ sơ & Thống kê'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Đăng xuất',
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Email: $_email', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Họ và tên', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _updateProfile,
              child: const Text('Cập nhật hồ sơ'),
            ),
            const Divider(height: 32),
            const Text(
              '📊 Thống kê công việc',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.5,
              children: [
                _buildStatCard('Tổng công việc', '$total', Colors.purple),
                _buildStatCard('Chưa thực hiện', '$todo', Colors.grey),
                _buildStatCard('Đang thực hiện', '$inProgress', Colors.blue),
                _buildStatCard('Đã hoàn thành', '$completed', Colors.green),
              ],
            ),
            const Divider(height: 32),
            const Text('Đổi mật khẩu', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            TextFormField(
              controller: _currentPassController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Mật khẩu hiện tại', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _newPassController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Mật khẩu mới', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _changePassword,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              child: const Text('Đổi mật khẩu', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return Card(
      color: color.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        side: BorderSide(color: color, width: 1.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 4),
            Text(title, textAlign: TextAlign.center, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}