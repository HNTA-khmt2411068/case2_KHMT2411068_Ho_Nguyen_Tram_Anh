import 'package:flutter/material.dart';
import '../../models/notification.dart';
import '../../services/notification_service.dart';

class NotificationScreen extends StatefulWidget {
  final String token;
  const NotificationScreen({Key? key, required this.token}) : super(key: key);

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  List<NotificationModel> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  void _fetchNotifications() async {
    setState(() => _isLoading = true);
    final notifications = await NotificationService.getNotifications(widget.token);
    setState(() {
      _notifications = notifications;
      _isLoading = false;
    });
  }

  void _markAsRead(String id, int index) async {
    final success = await NotificationService.markAsRead(widget.token, id);
    if (success) {
      setState(() {
        _notifications[index] = NotificationModel(
          id: _notifications[index].id,
          title: _notifications[index].title,
          message: _notifications[index].message,
          type: _notifications[index].type,
          isRead: true,
          createdAt: _notifications[index].createdAt,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Thông báo của tôi')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
          ? const Center(child: Text('Chưa có thông báo nào!'))
          : RefreshIndicator(
        onRefresh: () async => _fetchNotifications(),
        child: ListView.builder(
          itemCount: _notifications.length,
          itemBuilder: (context, index) {
            final noti = _notifications[index];
            return ListTile(
              tileColor: noti.isRead ? Colors.transparent : Colors.blue.withOpacity(0.08),
              leading: Icon(
                noti.type == 'ASSIGNED' ? Icons.assignment_ind : Icons.share,
                color: noti.isRead ? Colors.grey : Colors.blue,
              ),
              title: Text(
                noti.title,
                style: TextStyle(
                  fontWeight: noti.isRead ? FontWeight.normal : FontWeight.bold,
                ),
              ),
              subtitle: Text(noti.message),
              trailing: noti.isRead
                  ? null
                  : IconButton(
                icon: const Icon(Icons.check_circle_outline, color: Colors.blue),
                onPressed: () => _markAsRead(noti.id, index),
              ),
            );
          },
        ),
      ),
    );
  }
}