import 'dart:convert';
import 'package:http/http.dart' as http;

class NotificationService {
  static const String baseUrl = 'http://10.0.2.2:3000/api';

  static Future<List<dynamic>> getNotifications(String token) async {
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/notifications'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      }
      return [];
    } catch (e) {
      print('Lỗi getNotifications: $e');
      return [];
    }
  }

  static Future<void> markAsRead(String token, String notificationId) async {
    try {
      await http.patch(
        Uri.parse('$baseUrl/notifications/$notificationId/read'),
        headers: {'Authorization': 'Bearer $token'},
      );
    } catch (e) {
      print('Lỗi markAsRead: $e');
    }
  }

  static Future<void> markAllAsRead(String token) async {
    try {
      await http.patch(
        Uri.parse('$baseUrl/notifications/read-all'),
        headers: {'Authorization': 'Bearer $token'},
      );
    } catch (e) {
      print('Lỗi markAllAsRead: $e');
    }
  }
}