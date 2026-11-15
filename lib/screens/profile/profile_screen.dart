import 'package:flutter/material.dart';
import '../../models/task.dart';
import '../../services/api_client.dart';
import '../../services/auth_service.dart';
import '../../services/statistics_service.dart';
import '../auth/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  final String token;
  final List<Task> tasks;

  const ProfileScreen({
    super.key,
    required this.token,
    this.tasks = const [],
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nameController = TextEditingController();
  final _currentPassController = TextEditingController();
  final _newPassController = TextEditingController();
  final StatisticsService _statisticsService = StatisticsService();

  String _email = '';
  bool _isLoading = true;

  Map<String, dynamic> _taskStats = {};
  Map<String, dynamic> _assignmentStats = {};
  Map<String, dynamic> _deadlineStats = {};

  @override
  void initState() {
    super.initState();
    ApiClient.token = widget.token;
    _loadData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _currentPassController.dispose();
    _newPassController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final res = await AuthService.getMe(widget.token);
      final userData = res['user'] is Map<String, dynamic>
          ? res['user'] as Map<String, dynamic>
          : (res['data'] is Map<String, dynamic>
          ? res['data'] as Map<String, dynamic>
          : res);

      if (userData['_id'] != null || userData['id'] != null || userData['email'] != null) {
        _nameController.text = userData['fullName'] ?? '';
        _email = userData['email'] ?? '';
      }

      final results = await Future.wait([
        _statisticsService.getTaskStatistics().catchError((_) => <String, dynamic>{}),
        _statisticsService.getAssignmentStatistics().catchError((_) => <String, dynamic>{}),
        _statisticsService.getDeadlineStatistics().catchError((_) => <String, dynamic>{}),
      ]);

      if (mounted) {
        setState(() {
          _taskStats = results[0];
          _assignmentStats = results[1];
          _deadlineStats = results[2];
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  int _pickInt(Map<String, dynamic> map, List<String> keys, int fallback) {
    for (final k in keys) {
      final val = map[k];
      if (val is int) return val;
      if (val is num) return val.toInt();
      if (val is String && int.tryParse(val) != null) return int.parse(val);
    }
    if (map['data'] is Map<String, dynamic>) {
      return _pickInt(map['data'] as Map<String, dynamic>, keys, fallback);
    }
    return fallback;
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

  void _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Đăng xuất'),
        content: const Text('Bạn có chắc chắn muốn đăng xuất không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    ApiClient.token = null;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final int fallbackTotal = widget.tasks.length;
    final int fallbackTodo = widget.tasks.where((t) => t.status == 'todo').length;
    final int fallbackInProgress = widget.tasks.where((t) => t.status == 'in_progress').length;
    final int fallbackCompleted = widget.tasks.where((t) => t.status == 'completed').length;

    final int total = _pickInt(_taskStats, ['total', 'totalTasks'], fallbackTotal);
    final int todo = _pickInt(_taskStats, ['todo'], fallbackTodo);
    final int inProgress = _pickInt(_taskStats, ['in_progress', 'inProgress'], fallbackInProgress);
    final int completed = _pickInt(_taskStats, ['completed'], fallbackCompleted);

    final int assigned = _pickInt(_assignmentStats, ['assignedToMe', 'assigned', 'myTasks', 'totalAssigned'], 0);
    final int shared = _pickInt(_assignmentStats, ['sharedWithMe', 'shared', 'totalShared'], 0);
    final int upcoming = _pickInt(_deadlineStats, ['upcoming', 'dueSoon', 'dueIn24h'], 0);
    final int overdue = _pickInt(_deadlineStats, ['overdue', 'expired'], 0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hồ sơ & Thống kê'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Làm mới dữ liệu',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Đăng xuất',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: _loadData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
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
                'Thống kê trạng thái công việc',
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
              const SizedBox(height: 20),
              const Text(
                'Thống kê phân công & thời hạn',
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
                  _buildStatCard('Được giao', '$assigned', Colors.indigo),
                  _buildStatCard('Được chia sẻ', '$shared', Colors.teal),
                  _buildStatCard('Sắp đến hạn', '$upcoming', Colors.orange),
                  _buildStatCard('Quá hạn', '$overdue', Colors.red),
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
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return Card(
      color: color.withValues(alpha: 0.1),
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