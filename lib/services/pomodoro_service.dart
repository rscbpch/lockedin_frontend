import 'dart:convert';
import '../config/api_config.dart';
import 'auth_service.dart';
import 'api_client.dart';

class PomodoroService {
  static Future<Map<String, dynamic>> createSession({
    required int durationSeconds,
    required String type,
  }) async {
    try {
      final token = await AuthService.getToken();

      final headers = {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

      final body = jsonEncode({
        'type': type,
        'durationSeconds': durationSeconds,
      });

      final response = await ApiClient.post(
        ApiConfig.pomodoro,
        headers: headers,
        body: body,
      );

      final status = response.statusCode;
      final responseBody = response.body;


      dynamic parsed;
      try {
        parsed = jsonDecode(responseBody);
      } catch (_) {
        parsed = null;
      }

      if (status >= 200 && status < 300) {
        if (parsed is Map<String, dynamic>) {
          return parsed;
        }
        return {'success': true, 'message': 'Session saved successfully'};
      }

      String message = 'Failed to save session';
      if (parsed is Map && parsed['message'] != null) {
        message = parsed['message'].toString();
      } else if (responseBody.isNotEmpty) {
        message = responseBody;
      }

      return {'success': false, 'message': message};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> getMyStats() async {
    try {
      final token = await AuthService.getToken();

      final headers = {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

      final response = await ApiClient.get(
        ApiConfig.pomodoroStats,
        headers: headers,
      );

      final status = response.statusCode;
      final body = response.body;

      if (status >= 200 && status < 300) {
        return jsonDecode(body); // ← IMPORTANT: return raw backend JSON
      }

      return {'error': 'Failed to fetch stats'};
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  static Future<List<dynamic>> getRanking() async {
    try {
      final token = await AuthService.getToken();

      final headers = {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

      final response = await ApiClient.get(
        ApiConfig.pomodoroRanking,
        headers: headers,
      );

      final status = response.statusCode;
      final body = response.body;

      if (status >= 200 && status < 300) {
        return jsonDecode(body); // ← returns List
      }

      return [];
    } catch (e) {
      return [];
    }
  }
}
