import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:lockedin_frontend/config/env.dart';

class GoalService {
  /// POST /streak/start — mark the beginning of a productive session
  static Future<void> startSession({required String token}) async {
    final url = '${Env.apiBaseUrl}/streak/start';
    debugPrint('[GoalService] POST $url');

    final response = await http.post(Uri.parse(url), headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'});

    debugPrint('[GoalService] startSession status: ${response.statusCode} body: ${response.body}');

    if (response.statusCode == 401 || response.statusCode == 403) {
      throw Exception('UNAUTHORIZED');
    }
    // 400 = session already active — safe to ignore
  }

  /// POST /streak/end — end the productive session, returns durationSeconds
  static Future<Map<String, dynamic>> endSession({required String token}) async {
    final url = '${Env.apiBaseUrl}/streak/end';
    debugPrint('[GoalService] POST $url');

    final response = await http.post(Uri.parse(url), headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'});

    debugPrint('[GoalService] endSession status: ${response.statusCode} body: ${response.body}');

    if (response.statusCode == 401 || response.statusCode == 403) {
      throw Exception('UNAUTHORIZED');
    }

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }

    // 400 = no active session — return empty
    return {};
  }

  static Future<void> setDailyGoal({required String token, required int minutes}) async {
    final url = '${Env.apiBaseUrl}/streak/goal';
    final seconds = minutes * 60;
    debugPrint('[GoalService] POST $url dailyGoalSeconds: $seconds');

    final response = await http.post(
      Uri.parse(url),
      headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
      body: jsonEncode({'dailyGoalSeconds': seconds}),
    );

    debugPrint('[GoalService] status: ${response.statusCode} body: ${response.body}');

    if (response.statusCode != 200 && response.statusCode != 201) {
      if (response.statusCode == 401 || response.statusCode == 403) {
        throw Exception('UNAUTHORIZED');
      }
      try {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        throw Exception(data['message'] ?? 'Failed to set goal');
      } catch (e) {
        if (e is Exception) rethrow;
        throw Exception('Failed to set goal (${response.statusCode})');
      }
    }
  }

  static Future<Map<String, dynamic>> getStreak({required String token}) async {
    final url = '${Env.apiBaseUrl}/streak';
    debugPrint('[GoalService] GET $url');

    final response = await http.get(Uri.parse(url), headers: {'Authorization': 'Bearer ${token}', 'Content-Type': 'application/json'});
    debugPrint('[GoalService] status: ${response.statusCode} body: ${response.body}');

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      if (response.statusCode == 401 || response.statusCode == 403) {
        throw Exception('UNAUTHORIZED');
      }
      try {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        throw Exception(data['message'] ?? 'Failed to fetch streak');
      } catch (e) {
        if (e is Exception) rethrow;
        throw Exception('Failed to fetch streak (${response.statusCode})');
      }
    }
  }
}
