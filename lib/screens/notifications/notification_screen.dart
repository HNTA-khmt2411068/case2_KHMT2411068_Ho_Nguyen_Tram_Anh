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

  static const Color _bgTaroMilk = Color(0xFFF5F0FF);
  static const Color _taroLight = Color(0xFFEBE0FF);
  static const Color _taroPrimary = Color(0xFF8367D8);
  static const Color _taroDark = Color(0xFF3E2D6B);
  static const Color _taroMuted = Color(0xFF7B6F99);
  static const Color _taroBorder = Color(0xFFE2D7FA);

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
          const SnackBar(
            content: Text(
              'Công việc không tồn tại hoặc bạn không còn quyền truy cập',
            ),
          ),
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
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Thông báo',
          style: TextStyle(
            color: _taroDark,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: Tooltip(
              message: 'Đánh dấu tất cả đã đọc',
              child: Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: _markAllAsRead,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: _taroBorder),
                    ),
                    child: const Icon(
                      Icons.done_all_rounded,
                      color: _taroPrimary,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
        child: CircularProgressIndicator(color: _taroPrimary),
      )
          : RefreshIndicator(
        color: _taroPrimary,
        onRefresh: _fetchNotifications,
        child: _notifications.isEmpty
            ? ListView(
          children: [
            const SizedBox(height: 160),
            Center(
              child: Column(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: _taroLight,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.notifications_off_outlined,
                      color: _taroPrimary,
                      size: 30,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Không có thông báo nào!',
                    style: TextStyle(
                      color: _taroMuted,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        )
            : ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
          itemCount: _notifications.length,
          itemBuilder: (context, index) {
            final item = _notifications[index];
            final bool isRead = item['isRead'] ?? false;
            final String id =
            (item['_id'] ?? item['id'] ?? '').toString();

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: isRead
                    ? Colors.white
                    : const Color(0xFFF3ECFF),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isRead
                      ? const Color(0xFFEDE6FC)
                      : const Color(0xFFD5C4F7),
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x108367D8),
                    blurRadius: 14,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => _openNotificationDetail(item),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 13,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: isRead
                                ? const Color(0xFFF6F2FF)
                                : _taroPrimary,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            isRead
                                ? Icons.notifications_none_rounded
                                : Icons.notifications_active_rounded,
                            color: isRead
                                ? _taroMuted
                                : Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                            CrossAxisAlignment.start,
                            children: [
                              Text(
                                item['title'] ?? 'Thông báo',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: isRead
                                      ? FontWeight.w600
                                      : FontWeight.bold,
                                  color: _taroDark,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                item['message'] ?? '',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: _taroMuted,
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        !isRead
                            ? IconButton(
                          icon: const Icon(
                            Icons.check_circle_outline_rounded,
                            color: _taroPrimary,
                            size: 22,
                          ),
                          tooltip: 'Đánh dấu đã đọc',
                          onPressed: () => _markAsRead(id),
                        )
                            : const Icon(
                          Icons.chevron_right_rounded,
                          color: Color(0xFFA799C7),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}