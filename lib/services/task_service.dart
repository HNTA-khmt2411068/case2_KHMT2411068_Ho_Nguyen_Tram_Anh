import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/task.dart';

class TaskService {
  static const String baseUrl = 'http://10.0.2.2:3000/api/tasks';

  static Future<List<Task>> getTasks(String token) async {
    final response = await http.get(
      Uri.parse(baseUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((json) => Task.fromJson(json)).toList();
    }
    return [];
  }

  static Future createTask(
      String token, {
        required String title,
        required String description,
        required String priority,
        required String status,
        DateTime? startDate,
        DateTime? dueDate,
      }) async {
    final response = await http.post(
      Uri.parse(baseUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'title': title,
        'description': description,
        'priority': priority,
        'status': status,
        'startDate': startDate?.toIso8601String(),
        'dueDate': dueDate?.toIso8601String(),
      }),
    );
    return jsonDecode(response.body);
  }

  static Future updateStatus(String token, String taskId, String status) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/$taskId/status'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'status': status}),
    );
    return jsonDecode(response.body);
  }

  static Future deleteTask(String token, String taskId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/$taskId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    return jsonDecode(response.body);
  }
}