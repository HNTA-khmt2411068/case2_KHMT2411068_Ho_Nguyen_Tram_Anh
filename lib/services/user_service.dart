import 'dart:convert';
import 'api_client.dart';
import '../models/user.dart';

class UserService {
  Future<List<User>> searchUsers(String query) async {
    if (query.isEmpty) return [];

    final response = await ApiClient.get('/users/search?q=$query');
    if (response.statusCode == 200) {
      List<dynamic> body = jsonDecode(response.body);
      return body.map((item) => User.fromJson(item)).toList();
    } else {
      throw Exception('Không thể tìm kiếm người dùng');
    }
  }
}