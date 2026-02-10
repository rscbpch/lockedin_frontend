import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/api_config.dart';
import '../config/env.dart';

class AuthService {
  static const _storage = FlutterSecureStorage();

  static Future<String?> getToken() async {
    return await _storage.read(key: 'auth_token');
  }

  static Future<void> _saveToken(dynamic responseData) async {
    if (responseData is Map) {
      String? token;
      if (responseData['token'] != null) {
        token = responseData['token'];
      } else if (responseData['data'] != null && 
                 responseData['data'] is Map && 
                 responseData['data']['token'] != null) {
        token = responseData['data']['token'];
      }
      
      if (token != null) {
        await _storage.write(key: 'auth_token', value: token);
      }
    }
  }

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
          await _saveToken(parsed);
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
          await _saveToken(parsed);
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

  static Future<Map<String, dynamic>> signInWithGoogle() async {
    try {
      // For Google Cloud Console (not Firebase), explicitly specify client ID
      final GoogleSignIn googleSignIn = GoogleSignIn(
        scopes: ['email', 'profile'],
        clientId: Env.googleClientId, // Platform-specific client ID
        serverClientId: Env
            .googleWebClientId, // Web client ID for backend token verification
      );

      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        return {'success': false, 'message': 'Google sign-in cancelled'};
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final String? idToken = googleAuth.idToken;

      if (idToken == null) {
        return {'success': false, 'message': 'Failed to get Google ID token'};
      }

      // Send to backend
      final response = await http.post(
        Uri.parse('${Env.apiBaseUrl}/auth/google'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'idToken': idToken}),
      );

      final status = response.statusCode;
      final body = response.body;

      // ignore: avoid_print
      print('AuthService.signInWithGoogle -> status: $status body: $body');

      dynamic parsed;
      try {
        parsed = jsonDecode(body);
      } catch (_) {
        parsed = null;
      }

      if (status >= 200 && status < 300) {
        if (parsed is Map<String, dynamic>) {
          await _saveToken(parsed);
          if (parsed.containsKey('success')) return parsed;
          return {'success': true, 'data': parsed};
        }
        return {'success': true, 'data': parsed};
      }

      String message = 'Google sign-in failed';
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

  static Future<Map<String, dynamic>> sendOTP({required String email}) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.sendOTP),
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
          return {
            'success': true,
            'message': parsed['message'] ?? 'OTP sent successfully',
          };
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
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> resetPasswordWithOTP({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.resetPasswordWithOTP),
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
          return {
            'success': true,
            'message': parsed['message'] ?? 'Password reset successfully',
          };
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
      return {'success': false, 'message': e.toString()};
    }
  }
}
