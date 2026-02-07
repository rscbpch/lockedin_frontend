import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'api_client.dart';

class AuthService {
  static Future<Map<String, dynamic>> register({
    required String email,
    required String username,
    required String password,
    required String confirmPassword,
  }) async {
    try {
      final response = await ApiClient.post(
        ApiConfig.register,
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
      // Network, timeout, or other error
      String errorMessage = _getErrorMessage(e);
      return {'success': false, 'message': errorMessage};
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
      final response = await ApiClient.post(
        ApiConfig.login,
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
      String errorMessage = _getErrorMessage(e);
      return {'success': false, 'message': errorMessage};
    }
  }

  static Future<Map<String, dynamic>> sendOTP({required String email}) async {
    try {
      final response = await ApiClient.post(
        ApiConfig.sendOTP,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );

      final status = response.statusCode;
      final body = response.body;
      // Log for debugging
      // ignore: avoid_print
      print('AuthService.sendOTP -> status: $status body: $body');

      dynamic parsed;
      try {
        parsed = jsonDecode(body);
      } catch (_) {
        parsed = null;
      }

      if (status >= 200 && status < 300) {
        if (parsed is Map<String, dynamic>) {
          if (parsed.containsKey('success')) return parsed;
          return {'success': true, 'message': parsed['message'] ?? 'OTP sent successfully'};
        }
        return {'success': true, 'message': 'OTP sent successfully'};
      }

      String message = 'Failed to send OTP';
      if (parsed is Map && parsed['message'] != null) {
        message = parsed['message'].toString();
      } else if (body.isNotEmpty) {
        message = body;
      }

      return {'success': false, 'message': message, 'statusCode': status};
    } catch (e) {
      String errorMessage = _getErrorMessage(e);
      return {'success': false, 'message': errorMessage};
    }
  }

  static Future<Map<String, dynamic>> resetPasswordWithOTP({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    try {
      final response = await ApiClient.post(
        ApiConfig.resetPasswordWithOTP,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'otp': otp,
          'newPassword': newPassword,
        }),
      );

      final status = response.statusCode;
      final body = response.body;
      // Log for debugging
      // ignore: avoid_print
      print('AuthService.resetPasswordWithOTP -> status: $status body: $body');

      dynamic parsed;
      try {
        parsed = jsonDecode(body);
      } catch (_) {
        parsed = null;
      }

      if (status >= 200 && status < 300) {
        if (parsed is Map<String, dynamic>) {
          if (parsed.containsKey('success')) return parsed;
          return {'success': true, 'message': parsed['message'] ?? 'Password reset successfully'};
        }
        return {'success': true, 'message': 'Password reset successfully'};
      }

      String message = 'Failed to reset password';
      if (parsed is Map && parsed['message'] != null) {
        message = parsed['message'].toString();
      } else if (body.isNotEmpty) {
        message = body;
      }

      return {'success': false, 'message': message, 'statusCode': status};
    } catch (e) {
      String errorMessage = _getErrorMessage(e);
      return {'success': false, 'message': errorMessage};
    }
  }

  // Helper method to provide user-friendly error messages
  static String _getErrorMessage(dynamic error) {
    String errorStr = error.toString();
    
    if (errorStr.contains('No internet connection')) {
      return 'No internet connection. Please check your network and try again.';
    }
    
    if (errorStr.contains('Request timed out') || 
        errorStr.contains('Connection timed out') ||
        errorStr.contains('TimeoutException')) {
      return 'Connection timed out. Please check your internet connection and try again.';
    }
    
    if (errorStr.contains('SocketException') ||
        errorStr.contains('Failed host lookup')) {
      return 'Unable to connect to server. Please check your internet connection.';
    }
    
    if (errorStr.contains('Connection refused')) {
      return 'Server is currently unavailable. Please try again later.';
    }
    
    // Return a generic but user-friendly message for other errors
    return 'Network error occurred. Please check your connection and try again.';
  }
}
