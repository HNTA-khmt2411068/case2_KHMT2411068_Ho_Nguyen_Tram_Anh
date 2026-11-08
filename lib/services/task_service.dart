import 'dart:convert';
import 'package:http/http.dart' as http;

class TaskService {
  static const String baseUrl = 'http://10.0.2.2:3000/api';

  static Future<List<dynamic>> getTasks(String token) async {
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/tasks'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      }
      return [];
    } catch (e) {
      return [];
    }
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
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/tasks'),
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
      final data = jsonDecode(res.body);
      if (res.statusCode == 201 || res.statusCode == 200) {
        return {'success': true, 'data': data};
      }
      return {'success': false, 'message': data['message'] ?? 'Tạo công việc thất bại'};
    } catch (e) {
      return {'success': false, 'message': 'Không thể kết nối máy chủ'};
    }
  }

  static Future updateTaskStatus(
      String token,
      String taskId,
      String status,
      ) async {
    try {
      final res = await http.patch(
        Uri.parse('$baseUrl/tasks/$taskId/status'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'status': status}),
      );

      final data = jsonDecode(res.body);
      if (res.statusCode == 200) {
        return {'success': true, 'data': data};
      }
      return {'success': false, 'message': data['message'] ?? 'Lỗi cập nhật'};
    } catch (e) {
      return {'success': false, 'message': 'Không thể kết nối máy chủ'};
    }
  }

  static Future deleteTask(
      String token,
      String taskId,
      ) async {
    try {
      final res = await http.delete(
        Uri.parse('$baseUrl/tasks/$taskId'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      final data = jsonDecode(res.body);
      if (res.statusCode == 200) {
        return {'success': true, 'data': data};
      }
      return {'success': false, 'message': data['message'] ?? 'Lỗi xóa công việc'};
    } catch (e) {
      return {'success': false, 'message': 'Không thể kết nối máy chủ'};
    }
  }

  static Future assignTask(
      String token,
      String taskId, {
        required List<String> assigneeIds,
        String? primaryAssigneeId,
      }) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/tasks/$taskId/assignees'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'assigneeIds': assigneeIds,
          'primaryAssigneeId': primaryAssigneeId,
        }),
      );

      final data = jsonDecode(res.body);
      if (res.statusCode == 200 || res.statusCode == 201) {
        return {
          'success': true,
          'data': data,
          'message': data['message'] ?? 'Phân công thành công!'
        };
      }
      return {'success': false, 'message': data['message'] ?? 'Phân công thất bại'};
    } catch (e) {
      return {'success': false, 'message': 'Không thể kết nối máy chủ'};
    }
  }
}