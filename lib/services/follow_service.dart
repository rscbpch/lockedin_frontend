import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:lockedin_frontend/config/env.dart';
import 'package:lockedin_frontend/models/user/follow_user_model.dart';

class FollowService {
  final http.Client _client;
  final Future<String?> Function() _getAuthToken;

  FollowService({
    http.Client? client,
    required Future<String?> Function() getAuthToken,
  }) : _client = client ?? http.Client(),
       _getAuthToken = getAuthToken;

  Future<Map<String, String>> _headers() async {
    final token = await _getAuthToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// POST /api/follow
  Future<void> followUser(String targetUserId) async {
    final response = await _client.post(
      Uri.parse('${Env.apiBaseUrl}/follow'),
      headers: await _headers(),
      body: jsonEncode({'targetUserId': targetUserId}),
    );
    

    debugPrint('📡 followUser: ${response.statusCode} - ${response.body}');

    if (response.statusCode != 201) {
      final body = jsonDecode(response.body);
      throw Exception(body['message'] ?? 'Failed to follow user');
    }
  }

  /// DELETE /api/follow/:targetUserId
  Future<void> unfollowUser(String targetUserId) async {
    final response = await _client.delete(
      Uri.parse('${Env.apiBaseUrl}/follow/$targetUserId'),
      headers: await _headers(),
    );

    debugPrint('📡 unfollowUser: ${response.statusCode} - ${response.body}');

    if (response.statusCode != 200) {
      final body = jsonDecode(response.body);
      throw Exception(body['message'] ?? 'Failed to unfollow user');
    }
  }

  /// GET /api/follow/followers
  Future<List<FollowUser>> getFollowers() async {
    final response = await _client.get(
      Uri.parse('${Env.apiBaseUrl}/follow/followers'),
      headers: await _headers(),
    );

    debugPrint('📡 getFollowers: ${response.statusCode}');

    if (response.statusCode == 200) {
      return (jsonDecode(response.body) as List<dynamic>)
          .map((u) => FollowUser.fromJson(u as Map<String, dynamic>))
          .toList();
    }
    throw Exception('Failed to fetch followers: ${response.statusCode}');
  }

  /// GET /api/follow/following
  Future<List<FollowUser>> getFollowing() async {
    final response = await _client.get(
      Uri.parse('${Env.apiBaseUrl}/follow/following'),
      headers: await _headers(),
    );

    debugPrint('📡 getFollowing: ${response.statusCode}');

    if (response.statusCode == 200) {
      return (jsonDecode(response.body) as List<dynamic>)
          .map((u) => FollowUser.fromJson(u as Map<String, dynamic>))
          .toList();
    }
    throw Exception('Failed to fetch following: ${response.statusCode}');
  }
}