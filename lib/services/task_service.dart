import 'dart:convert';
import 'dart:convert';
import 'api_client.dart';
import '../models/task.dart';

class TaskService {
  Future<List<Task>> getTasks() async {
    final response = await ApiClient.get('/tasks');
    if (response.statusCode == 200) {
      List<dynamic> body = jsonDecode(response.body);
      return body.map((dynamic item) => Task.fromJson(item)).toList();
    } else {
      throw Exception('Không thể tải danh sách công việc');
    }
  }


  Future<Task> getTaskById(String id) async {
    final response = await ApiClient.get('/tasks/$id');
    if (response.statusCode == 200) {
      return Task.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Không thể tải chi tiết công việc');
    }
  }

  Future<bool> createTask(Map<String, dynamic> taskData) async {
    final response = await ApiClient.post('/tasks', body: taskData);
    return response.statusCode == 201;
  }

  Future<bool> updateTask(String id, Map<String, dynamic> taskData) async {
    final response = await ApiClient.put('/tasks/$id', body: taskData);
    return response.statusCode == 200;
  }

  Future<bool> updateTaskStatus(String id, String status) async {
    final response = await ApiClient.patch('/tasks/$id/status', body: {'status': status});
    return response.statusCode == 200;
  }

  Future<bool> deleteTask(String id) async {
    final response = await ApiClient.delete('/tasks/$id');
    return response.statusCode == 200;
  }
}