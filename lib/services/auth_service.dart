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
        // If server already provides a `success` flag, return it unchanged.
        if (parsed.containsKey('success')) return parsed;
        // Otherwise wrap the response so callers can check `success`.
        return {'success': true, 'data': parsed};
      }
      return {'success': true, 'data': parsed};
    }

    // Non-success status: extract message if available
    String message = 'Registration failed';
    if (parsed is Map && parsed['message'] != null) {
      message = parsed['message'].toString();
    } else if (body.isNotEmpty) {
      message = body;
    }

    return {
      'success': false,
      'message': message,
      'statusCode': status,
    };
  }
}
