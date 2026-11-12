import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';

class ApiClient {
  static String? token;

  Map<String, String> _headers() {
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    if (token != null && token!.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  Uri _buildUri(String endpoint, [Map<String, String>? queryParams]) {
    final uri = Uri.parse('${AppConstants.baseUrl}$endpoint');
    if (queryParams != null && queryParams.isNotEmpty) {
      return uri.replace(queryParameters: queryParams);
    }
    return uri;
  }

  Future<http.Response> get(String endpoint, {Map<String, String>? query}) {
    return http.get(_buildUri(endpoint, query), headers: _headers());
  }

  Future<http.Response> post(String endpoint, {Map<String, dynamic>? body}) {
    return http.post(
      _buildUri(endpoint),
      headers: _headers(),
      body: body != null ? jsonEncode(body) : null,
    );
  }

  Future<http.Response> put(String endpoint, {Map<String, dynamic>? body}) {
    return http.put(
      _buildUri(endpoint),
      headers: _headers(),
      body: body != null ? jsonEncode(body) : null,
    );
  }

  Future<http.Response> patch(String endpoint, {Map<String, dynamic>? body}) {
    return http.patch(
      _buildUri(endpoint),
      headers: _headers(),
      body: body != null ? jsonEncode(body) : null,
    );
  }

  Future<http.Response> delete(String endpoint) {
    return http.delete(_buildUri(endpoint), headers: _headers());
  }
}