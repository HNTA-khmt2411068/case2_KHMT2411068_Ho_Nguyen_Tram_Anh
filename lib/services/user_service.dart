import 'dart:convert';
import 'package:http/http.dart' as http;

class UserService {
  static const String baseUrl = 'http://10.0.2.2:3000/api';

  static Future<List<dynamic>> getUsers(String token, {String? query}) async {
    try {
      final uri = Uri.parse('$baseUrl/users${query != null ? '?q=$query' : ''}');
      final res = await http.get(
        uri,
        headers: {'Authorization': 'Bearer $token'},
      );
      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      }
      return [];
    } catch (e) {
      print('Lỗi UserService.getUsers: $e');
      return [];
    }
  }
}