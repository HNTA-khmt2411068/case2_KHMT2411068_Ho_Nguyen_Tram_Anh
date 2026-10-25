import 'dart:convert';
import 'api_client.dart';
import '../models/task.dart';

class TaskService {
  final ApiClient _apiClient = ApiClient();


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
}