import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/notification.dart';

class NotificationService {
  static const String baseUrl = 'http://10.0.2.2:3000/api/notifications';

  static Future<List<NotificationModel>> getNotifications(String token) async {
    final response = await http.get(
      Uri.parse(baseUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((json) => NotificationModel.fromJson(json)).toList();
    }
    return [];
  }

  static Future<bool> markAsRead(String token, String notificationId) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/$notificationId/read'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    return response.statusCode == 200;
  }
}