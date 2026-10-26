import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_client.dart';

class AuthService {
  static Future<bool> login(String email, String password) async {
    try {
      final res = await ApiClient.post(
        '/auth/login',
        body: {
          'email': email,
          'password': password,
        },
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final token = data['token'];

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', token);
        ApiClient.token = token;

        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> register(String fullName, String email, String password) async {
    try {
      final res = await ApiClient.post(
        '/auth/register',
        body: {
          'fullName': fullName,
          'email': email,
          'password': password,
        },
      );
      return res.statusCode == 201;
    } catch (e) {
      return false;
    }
  }
}