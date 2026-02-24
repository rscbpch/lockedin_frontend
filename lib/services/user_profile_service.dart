import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user/user.dart';
import 'package:lockedin_frontend/config/env.dart';

class UserProfileService {
  static Future<User> fetchMyProfile(String token) async {
    final response = await http.get(
      Uri.parse('${Env.apiBaseUrl}/api/setting/me'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return User.fromJson(jsonDecode(response.body));
    } else {
      throw Exception(
          'Failed to load profile (${response.statusCode})');
    }
  }

  static Future<User> updateMyProfile({
    required String token,
    required String username,
    required String bio,
    required String displayName,
    required String avatar,
  }) async {
    final response = await http.put(
      Uri.parse('${Env.apiBaseUrl}/api/setting/me'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'username': username,
        'bio': bio,
        'displayName': displayName,
        'avatar': avatar,
      }),
    );

    if (response.statusCode == 200) {
      return User.fromJson(jsonDecode(response.body));
    } else {
      throw Exception(
          'Failed to update profile (${response.statusCode})');
    }
  }
}
