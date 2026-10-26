import 'dart:convert';
import 'api_client.dart';
import '../models/task_share.dart';

class TaskShareService {
  
  Future<bool> assignTask(String taskId, List<String> assigneeIds, {String? primaryAssigneeId}) async {
    final response = await ApiClient.post(
      '/tasks/$taskId/assignees',
      body: {
        'assigneeIds': assigneeIds,
        if (primaryAssigneeId != null) 'primaryAssigneeId': primaryAssigneeId,
      },
    );
    return response.statusCode == 200;
  }


  Future<List<TaskShare>> getShares(String taskId) async {
    final response = await ApiClient.get('/tasks/$taskId/shares');
    if (response.statusCode == 200) {
      List<dynamic> body = jsonDecode(response.body);
      return body.map((item) => TaskShare.fromJson(item)).toList();
    } else {
      throw Exception('Không thể tải danh sách chia sẻ');
    }
  }


  Future<bool> shareTask(String taskId, String userId, String permission) async {
    final response = await ApiClient.post(
      '/tasks/$taskId/shares',
      body: {
        'userId': userId,
        'permission': permission,
      },
    );
    return response.statusCode == 200;
  }


  Future<bool> revokeShare(String taskId, String shareId) async {
    final response = await ApiClient.delete('/tasks/$taskId/shares/$shareId');
    return response.statusCode == 200;
  }
}