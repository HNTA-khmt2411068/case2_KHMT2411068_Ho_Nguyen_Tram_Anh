import 'dart:convert';
import '../models/task.dart';
import '../models/task_activity.dart';
import 'api_client.dart';

class TaskService {
  static Future<List<Task>> getTasks({String scope = 'all', String search = ''}) async {
    String endpoint = '/tasks?scope=$scope';
    if (search.isNotEmpty) {
      endpoint += '&q=${Uri.encodeComponent(search)}';
    }

    final response = await ApiClient.get(endpoint);

    print("📥 [GET TASKS] Status: ${response.statusCode}");
    print("📥 [GET TASKS] Body: ${response.body}");

    if (response.statusCode == 200) {
      final dynamic decoded = jsonDecode(response.body);

      final List<dynamic> data = (decoded is List)
          ? decoded
          : (decoded['tasks'] ?? decoded['data'] ?? []);

      return data.map((json) => Task.fromJson(json)).toList();
    } else {
      throw Exception('Không thể tải danh sách (Mã lỗi: ${response.statusCode})');
    }
  }

  static Future<dynamic> getTaskById(String taskId) async {
    try {
      final response = await ApiClient.get('/tasks/$taskId');
      print("📥 [GET TASK BY ID] Status: ${response.statusCode}");
      print("📥 [GET TASK BY ID] Body: ${response.body}");

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      print("❌ [GET TASK BY ID ERROR] $e");
      return null;
    }
  }

  static Future<bool> createTask(Map<String, dynamic> taskData) async {
    print("🚀 Đang gửi dữ liệu tạo Task: $taskData");
    print("🔑 Token hiện tại trong ApiClient: ${ApiClient.token}");

    final response = await ApiClient.post('/tasks', body: taskData);

    print("📥 Response Status: ${response.statusCode}");
    print("📥 Response Body: ${response.body}");

    return response.statusCode == 201 || response.statusCode == 200;
  }

  static Future<bool> deleteTask(String taskId) async {
    final response = await ApiClient.delete('/tasks/$taskId');
    return response.statusCode == 200;
  }

  static Future<bool> updateStatus(String taskId, String status) async {
    final response = await ApiClient.patch('/tasks/$taskId/status', body: {'status': status});
    return response.statusCode == 200;
  }

  static Future<bool> updateTask(String taskId, Map<String, dynamic> taskData) async {
    final response = await ApiClient.put('/tasks/$taskId', body: taskData);
    return response.statusCode == 200;
  }

  static Future<bool> assignTask(String taskId, List<dynamic> userIds) async {
    print("🚀 [ASSIGN TASK] Gửi request giao việc cho Task: $taskId");
    print("🚀 [ASSIGN TASK] Danh sách userIds: $userIds");

    final response = await ApiClient.post('/tasks/$taskId/assignees', body: {
      'assigneeIds': userIds,
    });

    print("📥 [ASSIGN TASK] Status Code: ${response.statusCode}");
    print("📥 [ASSIGN TASK] Response Body: ${response.body}");

    return response.statusCode == 200 || response.statusCode == 201;
  }
  static Future<List<TaskActivity>> getTaskActivities(String taskId) async {
    try {
      final response = await ApiClient.get('/tasks/$taskId/activities');
      if (response.statusCode == 200) {
        final List list = jsonDecode(response.body);
        return list.map((item) => TaskActivity.fromJson(item)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }
}

