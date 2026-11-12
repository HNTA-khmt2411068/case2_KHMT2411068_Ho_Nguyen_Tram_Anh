import 'dart:convert';
import 'package:flutter/material.dart';
import '../../models/task.dart';
import '../../services/api_client.dart';
import '../../services/notification_service.dart';
import '../tasks/task_detail_screen.dart';

class NotificationScreen extends StatefulWidget {
  final String token;
  const NotificationScreen({super.key, required this.token});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  List<dynamic> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    ApiClient.token = widget.token;
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    setState(() => _isLoading = true);
    try {
      final data = await NotificationService.getNotifications(widget.token);
      if (mounted) {
        setState(() {
          _notifications = data;
        });
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _markAsRead(String id) async {
    await NotificationService.markAsRead(widget.token, id);
    if (mounted) {
      await _fetchNotifications();
    }
  }

  Future<void> _markAllAsRead() async {
    await NotificationService.markAllAsRead(widget.token);
    if (mounted) {
      await _fetchNotifications();
    }
  }

  String _extractTaskId(dynamic rawTaskId) {
    if (rawTaskId is Map) {
      return (rawTaskId['_id'] ?? rawTaskId['id'] ?? '').toString();
    }
    return (rawTaskId ?? '').toString();
  }

  Future<void> _openNotificationDetail(dynamic item) async {
    final String notificationId = (item['_id'] ?? item['id'] ?? '').toString();
    final bool isRead = item['isRead'] ?? false;

    if (!isRead && notificationId.isNotEmpty) {
      await NotificationService.markAsRead(widget.token, notificationId);
    }

    final String taskId = _extractTaskId(item['taskId']);
    if (taskId.isEmpty) {
      if (mounted) _fetchNotifications();
      return;
    }

    try {
      ApiClient.token = widget.token;
      final response = await ApiClient.get('/tasks/$taskId');
      if (!mounted) return;

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final taskJson = decoded is Map<String, dynamic>
            ? (decoded['task'] ?? decoded['data'] ?? decoded)
            : decoded;
        final task = Task.fromJson(Map<String, dynamic>.from(taskJson));

        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TaskDetailScreen(
              task: task,
              token: widget.token,
            ),
          ),
        );
        if (mounted) _fetchNotifications();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Công việc không tồn tại hoặc bạn không còn quyền truy cập')),
        );
        _fetchNotifications();
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không thể mở chi tiết công việc')),
        );
        _fetchNotifications();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thông báo'),
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all),
            tooltip: 'Đánh dấu tất cả đã đọc',
            onPressed: _markAllAsRead,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: _fetchNotifications,
        child: _notifications.isEmpty
            ? ListView(
          children: const [
            SizedBox(height: 200),
            Center(child: Text('Không có thông báo nào!')),
          ],
        )
            : ListView.builder(
          itemCount: _notifications.length,
          itemBuilder: (context, index) {
            final item = _notifications[index];
            final bool isRead = item['isRead'] ?? false;
            final String id = (item['_id'] ?? item['id'] ?? '').toString();

            return Card(
              color: isRead ? Colors.white : Colors.blue.shade50,
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: ListTile(
                onTap: () => _openNotificationDetail(item),
                leading: Icon(
                  isRead ? Icons.notifications_none : Icons.notifications_active,
                  color: isRead ? Colors.grey : Colors.blue,
                ),
                title: Text(
                  item['title'] ?? 'Thông báo',
                  style: TextStyle(
                    fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                  ),
                ),
                subtitle: Text(item['message'] ?? ''),
                trailing: !isRead
                    ? IconButton(
                  icon: const Icon(Icons.check_circle_outline, color: Colors.green),
                  onPressed: () => _markAsRead(id),
                )
                    : const Icon(Icons.chevron_right, color: Colors.grey),
              ),
            );
          },
        ),
      ),
    );
  }
}