import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/task_share.dart';

class TaskShareService {
  static const String baseUrl = 'http://10.0.2.2:3000/api/tasks';

  static Future shareTask(
      String token,
      String taskId, {
        required String userId,
        required String permission,
      }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/$taskId/shares'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'userId': userId,
        'permission': permission,
      }),
    );
    return jsonDecode(response.body);
  }

  static Future<List<TaskShare>> getTaskShares(String token, String taskId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/$taskId/shares'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((json) => TaskShare.fromJson(json)).toList();
    }
    return [];
  }

  static Future revokeShare(
      String token,
      String taskId,
      String shareId,
      ) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/$taskId/shares/$shareId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    return jsonDecode(response.body);
  }
}