import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:lockedin_frontend/config/env.dart';
import 'package:lockedin_frontend/models/user/search_user_model.dart';


class UserService {
  final http.Client _client;
  final Future<String?> Function() _getAuthToken;

  UserService({
    http.Client? client,
    required Future<String?> Function() getAuthToken,
  })  : _client = client ?? http.Client(),
        _getAuthToken = getAuthToken;

  Future<Map<String, String>> _headers() async {
    final token = await _getAuthToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// GET /api/search/users?q=<query>
  Future<List<SearchUserResult>> searchUsers(String query) async {
    final uri = Uri.parse('${Env.apiBaseUrl}/user/search')
        .replace(queryParameters: {'q': query});

    final response = await _client.get(uri, headers: await _headers());

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final list = body['results'] as List<dynamic>;
      return list
          .map((u) => SearchUserResult.fromJson(u as Map<String, dynamic>))
          .toList();
    }
    throw Exception('Failed to search users: ${response.statusCode}');
  }

  /// POST /api/follow  body: { targetUserId }
  Future<void> followUser(String targetUserId) async {
    final response = await _client.post(
      Uri.parse('${Env.apiBaseUrl}/follow'),
      headers: await _headers(),
      body: jsonEncode({'targetUserId': targetUserId}),
    );
    if (response.statusCode != 201) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(body['message'] ?? 'Failed to follow');
    }
  }

  /// DELETE /api/follow/:targetUserId
  Future<void> unfollowUser(String targetUserId) async {
    final response = await _client.delete(
      Uri.parse('${Env.apiBaseUrl}/follow/$targetUserId'),
      headers: await _headers(),
    );
    if (response.statusCode != 200) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(body['message'] ?? 'Failed to unfollow');
    }
  }
}