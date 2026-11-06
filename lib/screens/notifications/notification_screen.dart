import 'package:flutter/material.dart' hide Notification;
import 'package:intl/intl.dart';
import '../../models/notification.dart';
import '../../services/notification_service.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  List<Notification> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() => _isLoading = true);
    final list = await NotificationService.getNotifications();
    if (mounted) {
      setState(() {
        _notifications = list;
        _isLoading = false;
      });
    }
  }

  Future<void> _markRead(Notification item) async {
    if (item.isRead) return;
    final success = await NotificationService.markAsRead(item.id);
    if (success && mounted) {
      _loadNotifications();
    }
  }

  IconData _getNotificationIcon(String title) {
    final t = title.toLowerCase();
    if (t.contains('thu hồi') || t.contains('xóa')) return Icons.delete_outline_rounded;
    if (t.contains('chia sẻ')) return Icons.share_rounded;
    if (t.contains('giao')) return Icons.assignment_ind_rounded;
    if (t.contains('tạo')) return Icons.add_task_rounded;
    if (t.contains('cập nhật')) return Icons.edit_note_rounded;
    return Icons.notifications_rounded;
  }

  Color _getNotificationColor(String title) {
    final t = title.toLowerCase();
    if (t.contains('thu hồi') || t.contains('xóa')) return const Color(0xFFEA580C);
    if (t.contains('chia sẻ')) return const Color(0xFF0284C7);
    if (t.contains('giao')) return const Color(0xFF7C3AED);
    if (t.contains('tạo')) return const Color(0xFF059669);
    if (t.contains('cập nhật')) return const Color(0xFFD97706);
    return const Color(0xFF2563EB);
  }

  Color _getNotificationBgColor(String title) {
    final t = title.toLowerCase();
    if (t.contains('thu hồi') || t.contains('xóa')) return const Color(0xFFFFEDD5);
    if (t.contains('chia sẻ')) return const Color(0xFFE0F2FE);
    if (t.contains('giao')) return const Color(0xFFF3E8FF);
    if (t.contains('tạo')) return const Color(0xFFD1FAE5);
    if (t.contains('cập nhật')) return const Color(0xFFFEF3C7);
    return const Color(0xFFDBEAFE);
  }

  @override
  Widget build(BuildContext context) {
    final DateFormat formatter = DateFormat('HH:mm - dd/MM/yyyy');

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: const Text(
          'Thông báo',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F172A),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        shadowColor: Colors.black.withOpacity(0.1),
        iconTheme: const IconThemeData(color: Color(0xFF0F172A)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notifications_off_outlined, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(
              'Chưa có thông báo nào!',
              style: TextStyle(fontSize: 15, color: Colors.grey.shade600),
            ),
          ],
        ),
      )
          : RefreshIndicator(
        onRefresh: _loadNotifications,
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          itemCount: _notifications.length,
          itemBuilder: (context, index) {
            final item = _notifications[index];
            final icon = _getNotificationIcon(item.title);
            final color = _getNotificationColor(item.title);
            final bgColor = _getNotificationBgColor(item.title);

            return Container(
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                color: item.isRead ? Colors.white : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: item.isRead ? const Color(0xFFE2E8F0) : color.withOpacity(0.4),
                  width: item.isRead ? 1 : 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  decoration: BoxDecoration(
                    border: Border(
                      left: BorderSide(
                        color: color,
                        width: 5,
                      ),
                    ),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _markRead(item),
                      child: Padding(
                        padding: const EdgeInsets.all(14.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: bgColor,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(icon, color: color, size: 22),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          item.title,
                                          style: TextStyle(
                                            fontWeight: item.isRead ? FontWeight.w600 : FontWeight.bold,
                                            fontSize: 15,
                                            color: const Color(0xFF0F172A),
                                          ),
                                        ),
                                      ),
                                      if (!item.isRead)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: color.withOpacity(0.15),
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: Text(
                                            'MỚI',
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: color,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    item.message,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Color(0xFF475569),
                                      height: 1.35,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    children: [
                                      const Icon(Icons.access_time_rounded, size: 13, color: Color(0xFF94A3B8)),
                                      const SizedBox(width: 4),
                                      Text(
                                        formatter.format(item.createdAt),
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: Color(0xFF94A3B8),
                                          fontWeight: FontWeight.w400,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
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