import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class AuthService {
  static Future<Map<String, dynamic>> register({
    required String email,
    required String username,
    required String password,
    required String confirmPassword,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.register),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'username': username,
          'password': password,
          'confirmPassword': confirmPassword,
        }),
      );

      final status = response.statusCode;
      final body = response.body;
      // Log for debugging
      // ignore: avoid_print
      print('AuthService.register -> status: $status body: $body');

      // Try to parse JSON response, but tolerate non-JSON error bodies
      dynamic parsed;
      try {
        parsed = jsonDecode(body);
      } catch (_) {
        parsed = null;
      }

      if (status >= 200 && status < 300) {
        if (parsed is Map<String, dynamic>) {
          if (parsed.containsKey('success')) return parsed;
          return {'success': true, 'data': parsed};
        }
        return {'success': true, 'data': parsed};
      }

      String message = 'Registration failed';
      if (parsed is Map && parsed['message'] != null) {
        message = parsed['message'].toString();
      } else if (body.isNotEmpty) {
        message = body;
      }

      return {'success': false, 'message': message, 'statusCode': status};
    } catch (e) {
      // Network or other error (DNS, connection refused, TLS, etc.)
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final payload = {'email': email, 'username': email, 'password': password};
      // ignore: avoid_print
      print('AuthService.login -> request body: ${jsonEncode(payload)}');
      final response = await http.post(
        Uri.parse(ApiConfig.login),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      final status = response.statusCode;
      final body = response.body;
      // Log for debugging
      // ignore: avoid_print
      print('AuthService.login -> status: $status body: $body');

      dynamic parsed;
      try {
        parsed = jsonDecode(body);
      } catch (_) {
        parsed = null;
      }

      if (status >= 200 && status < 300) {
        if (parsed is Map<String, dynamic>) {
          if (parsed.containsKey('success')) return parsed;
          return {'success': true, 'data': parsed};
        }
        return {'success': true, 'data': parsed};
      }

      String message = 'Login failed';
      if (parsed is Map && parsed['message'] != null) {
        message = parsed['message'].toString();
      } else if (body.isNotEmpty) {
        message = body;
      }

      return {'success': false, 'message': message, 'statusCode': status};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }
}
