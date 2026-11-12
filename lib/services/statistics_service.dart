import 'dart:convert';
import 'api_client.dart';

class StatisticsService {
  final ApiClient _client = ApiClient();

  Future getTaskStatistics() async {
    final response = await _client.get('/statistics/tasks');
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception('Không thể tải thống kê trạng thái công việc');
  }

  Future getAssignmentStatistics() async {
    final response = await _client.get('/statistics/assignments');
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception('Không thể tải thống kê phân công');
  }

  Future getDeadlineStatistics() async {
    final response = await _client.get('/statistics/deadlines');
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception('Không thể tải thống kê thời hạn');
  }
}