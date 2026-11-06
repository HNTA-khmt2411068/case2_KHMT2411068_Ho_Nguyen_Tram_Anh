import 'dart:convert';
import 'api_client.dart';

class StatisticsService {
  static Future getTaskStatistics() async {
    try {
      final response = await ApiClient.get('/statistics/tasks');
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return {};
    } catch (e) {
      return {};
    }
  }
}