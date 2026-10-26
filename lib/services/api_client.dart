import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiClient {
  static const String baseUrl = 'http://10.0.2.2:3000/api'; // Hoặc IP server backend của bạn
  static String? token;

  static Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (token != null) 'Authorization': 'Bearer $token',
  };

  static Future<http.Response> get(String endpoint) async {
    return await http.get(Uri.parse('$baseUrl$endpoint'), headers: _headers);
  }

  static Future<http.Response> post(String endpoint, {Map<String, dynamic>? body}) async {
    return await http.post(
      Uri.parse('$baseUrl$endpoint'),
      headers: _headers,
      body: body != null ? jsonEncode(body) : null,
    );
  }

  static Future<http.Response> put(String endpoint, {Map<String, dynamic>? body}) async {
    return await http.put(
      Uri.parse('$baseUrl$endpoint'),
      headers: _headers,
      body: body != null ? jsonEncode(body) : null,
    );
  }

  static Future<http.Response> patch(String endpoint, {Map<String, dynamic>? body}) async {
    return await http.patch(
      Uri.parse('$baseUrl$endpoint'),
      headers: _headers,
      body: body != null ? jsonEncode(body) : null,
    );
  }

  static Future<http.Response> delete(String endpoint) async {
    return await http.delete(Uri.parse('$baseUrl$endpoint'), headers: _headers);
  }
}