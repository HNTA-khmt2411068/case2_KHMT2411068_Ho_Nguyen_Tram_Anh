import 'package:flutter/material.dart';
import '../../services/notification_service.dart';

class NotificationScreen extends StatefulWidget {
  final String token;
  const NotificationScreen({Key? key, required this.token}) : super(key: key);

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  List<dynamic> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
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
    } catch (e) {
      print('Lỗi fetch notifications: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _markAsRead(String id) async {
    await NotificationService.markAsRead(widget.token, id);
    if (mounted) _fetchNotifications();
  }

  void _markAllAsRead() async {
    await NotificationService.markAllAsRead(widget.token);
    if (mounted) _fetchNotifications();
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
            return Card(
              color: isRead ? Colors.white : Colors.blue.shade50,
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: ListTile(
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
                  onPressed: () => _markAsRead(item['_id']),
                )
                    : null,
              ),
            );
          },
        ),
      ),
    );
  }
}