import 'dart:convert';
import 'package:flutter/material.dart';
import '../../services/api_client.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _fullName = 'Người dùng';
  int _totalTasks = 0;
  int _todoTasks = 0;
  int _inProgressTasks = 0;
  int _completedTasks = 0;
  int _overdueTasks = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchProfileAndStats();
  }

  Future<void> _fetchProfileAndStats() async {
    try {
      final profileRes = await ApiClient.get('/auth/profile');
      if (profileRes.statusCode == 200) {
        final profileData = jsonDecode(profileRes.body);
        _fullName = profileData['fullName'] ?? 'Người dùng';
      }

      final tasksRes = await ApiClient.get('/tasks');
      if (tasksRes.statusCode == 200) {
        final List tasks = jsonDecode(tasksRes.body);
        final now = DateTime.now();

        _totalTasks = tasks.length;
        _todoTasks = tasks.where((t) => t['status'] == 'todo' || t['status'] == 'chua_thuc_hien').length;
        _inProgressTasks = tasks.where((t) => t['status'] == 'in_progress' || t['status'] == 'dang_thuc_hien').length;
        _completedTasks = tasks.where((t) => t['status'] == 'completed' || t['status'] == 'da_hoan_thanh').length;

        _overdueTasks = tasks.where((t) {
          if (t['dueDate'] == null) return false;
          final due = DateTime.tryParse(t['dueDate'].toString());
          if (due == null) return false;
          final isDone = t['status'] == 'completed' || t['status'] == 'da_hoan_thanh';
          return due.isBefore(now) && !isDone;
        }).length;
      }

      if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildStatCard({
    required IconData icon,
    required Color iconBgColor,
    required Color iconColor,
    required String title,
    required int count,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: iconBgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 4),
                Text(
                  '$count',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Cá nhân & Thống kê'),
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
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: Colors.blue.shade100,
                      child: Text(
                        _fullName.isNotEmpty ? _fullName[0].toUpperCase() : 'U',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade900,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      _fullName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Thống kê công việc',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 12),
              _buildStatCard(
                icon: Icons.bar_chart,
                iconBgColor: Colors.blue.shade50,
                iconColor: Colors.blue.shade700,
                title: 'Tổng số công việc',
                count: _totalTasks,
              ),
              _buildStatCard(
                icon: Icons.assignment_outlined,
                iconBgColor: Colors.orange.shade50,
                iconColor: Colors.orange.shade700,
                title: 'Chưa thực hiện',
                count: _todoTasks,
              ),
              _buildStatCard(
                icon: Icons.sync,
                iconBgColor: Colors.purple.shade50,
                iconColor: Colors.purple.shade700,
                title: 'Đang thực hiện',
                count: _inProgressTasks,
              ),
              _buildStatCard(
                icon: Icons.check_circle_outline,
                iconBgColor: Colors.green.shade50,
                iconColor: Colors.green.shade700,
                title: 'Đã hoàn thành',
                count: _completedTasks,
              ),
              _buildStatCard(
                icon: Icons.warning_amber_rounded,
                iconBgColor: Colors.red.shade50,
                iconColor: Colors.red.shade700,
                title: 'Quá hạn hoàn thành',
                count: _overdueTasks,
              ),
            ],
          ),
        ),
      ),
    );
  }
}