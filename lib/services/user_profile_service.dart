import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/user/user.dart';
import 'package:lockedin_frontend/config/env.dart';

class UserProfileService {
  static Future<User> fetchMyProfile(String token) async {
    final url = '${Env.apiBaseUrl}/setting/me';
    debugPrint('[UserProfileService] GET $url');
    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
    debugPrint(
      '[UserProfileService] status: ${response.statusCode} body: ${response.body}',
    );

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      // Handle both {username:...} and wrapped {data:{username:...}}
      final data = (body is Map && body['data'] is Map)
          ? body['data'] as Map<String, dynamic>
          : body as Map<String, dynamic>;
      return User.fromJson(data);
    } else {
      throw Exception('Failed to load profile (${response.statusCode})');
    }
  }

  static Future<void> updateMyProfile({
    required String token,
    required String username,
    required String bio,
    required String displayName,
    String? avatar, // Cloudinary URL — only set when a new image was uploaded
  }) async {
    final url = '${Env.apiBaseUrl}/setting/profile';
    final body = <String, dynamic>{
      'username': username,
      'bio': bio,
      'displayName': displayName,
    };
    if (avatar != null) body['avatar'] = avatar;
    debugPrint('[UserProfileService] PATCH $url body: $body');
    final response = await http.patch(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );
    debugPrint(
      '[UserProfileService] update status: ${response.statusCode} body: ${response.body}',
    );
    if (response.statusCode != 200) {
      throw Exception(
        'Failed to update profile (${response.statusCode}): ${response.body}',
      );
    }
  }

  // Upload image to Cloudinary and return the resulting URL.
  static Future<String> uploadAvatar({
    required String token,
    required File imageFile,
  }) async {
    final url = '${Env.apiBaseUrl}/setting/profile/avatar';
    debugPrint('[UserProfileService] PATCH $url (multipart)');
    final request = http.MultipartRequest('PATCH', Uri.parse(url))
      ..headers['Authorization'] = 'Bearer $token'
      ..files.add(await http.MultipartFile.fromPath('avatar', imageFile.path));
    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    debugPrint(
      '[UserProfileService] avatar upload status: ${response.statusCode} body: ${response.body}',
    );
    if (response.statusCode != 200) {
      throw Exception(
        'Failed to upload avatar (${response.statusCode}): ${response.body}',
      );
    }
    // Backend returns { message: "Avatar updated", avatar: "https://..." }
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return data['avatar'] as String;
  }
}
