import 'dart:convert';
import 'package:http/http.dart' as http;

class AuthService {
  static const String baseUrl = 'http://10.0.2.2:5000/api/auth';

  static Future register(
      String fullName,
      String email,
      String password,
      ) async {
    try {
      final response = await http
          .post(
        Uri.parse('$baseUrl/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'fullName': fullName,
          'email': email,
          'password': password,
        }),
      )
          .timeout(const Duration(seconds: 10));

      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e) {
      return {'message': 'Lỗi kết nối máy chủ: $e'};
    }
  }

  static Future login(
      String email,
      String password,
      ) async {
    try {
      final response = await http
          .post(
        Uri.parse('$baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      )
          .timeout(const Duration(seconds: 10));

      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e) {
      return {'message': 'Lỗi kết nối máy chủ: $e'};
    }
  }

  static Future getMe(String token) async {
    try {
      final response = await http
          .get(
        Uri.parse('$baseUrl/me'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      )
          .timeout(const Duration(seconds: 10));

      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e) {
      return {'message': 'Lỗi tải thông tin người dùng: $e'};
    }
  }

  static Future updateMe(
      String token,
      String fullName,
      String? avatarUrl,
      ) async {
    try {
      final response = await http
          .put(
        Uri.parse('$baseUrl/me'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'fullName': fullName,
          if (avatarUrl != null) 'avatarUrl': avatarUrl,
        }),
      )
          .timeout(const Duration(seconds: 10));

      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e) {
      return {'message': 'Lỗi cập nhật hồ sơ: $e'};
    }
  }

  static Future changePassword(
      String token,
      String oldPassword,
      String newPassword,
      ) async {
    try {
      final response = await http
          .put(
        Uri.parse('$baseUrl/change-password'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'oldPassword': oldPassword,
          'newPassword': newPassword,
        }),
      )
          .timeout(const Duration(seconds: 10));

      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e) {
      return {'message': 'Lỗi đổi mật khẩu: $e'};
    }
  }
}