import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:lockedin_frontend/config/env.dart';
import '../models/chat/group_model.dart';

class GroupChatService {
  final http.Client _client;
  final Future<String?> Function() _getAuthToken;

  static const _timeout = Duration(seconds: 15);

  GroupChatService({
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

  /// POST /api/groupchat
  Future<Map<String, String>> createGroup({
    required String name,
    required List<String> memberIds,
  }) async {
    final response = await _client
        .post(
          Uri.parse('${Env.apiBaseUrl}/groupchat'),
          headers: await _headers(),
          body: jsonEncode({'name': name, 'memberIds': memberIds}),
        )
        .timeout(_timeout, onTimeout: () => throw Exception('Request timed out. Check your connection.'));

    debugPrint('📡 createGroup: ${response.statusCode} - ${response.body}');

    if (response.statusCode == 201) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      return {
        'groupId': body['groupId'] as String,
        'channelId': body['channelId'] as String,
      };
    }
    throw Exception('Failed to create group: ${response.statusCode}');
  }

  /// GET /api/groupchat
  Future<List<GroupModel>> getUserGroups() async {
    final response = await _client
        .get(
          Uri.parse('${Env.apiBaseUrl}/groupchat'),
          headers: await _headers(),
        )
        .timeout(_timeout, onTimeout: () => throw Exception('Request timed out. Check your connection.'));

    if (response.statusCode == 200) {
      final list = jsonDecode(response.body) as List<dynamic>;
      return list
          .map((g) => GroupModel.fromJson(g as Map<String, dynamic>))
          .toList();
    }
    throw Exception('Failed to fetch groups: ${response.statusCode}');
  }

  /// GET /api/groupchat/:groupId
  Future<GroupModel> getGroupDetails(String groupId) async {
  final response = await _client
      .get(
        Uri.parse('${Env.apiBaseUrl}/groupchat/$groupId'),
        headers: await _headers(),
      )
      .timeout(_timeout, onTimeout: () => throw Exception('Request timed out'));

  debugPrint('📡 getGroupDetails: ${response.statusCode} - ${response.body}');

  if (response.statusCode == 200) {
    return GroupModel.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }
  throw Exception('Failed to get group details: ${response.statusCode}');
}

  /// POST /api/groupchat/:groupId/members
  Future<Map<String, dynamic>> addMembers({
    required String groupId,
    required List<String> userIds,
  }) async {
    final response = await _client
        .post(
          Uri.parse('${Env.apiBaseUrl}/groupchat/$groupId/members'),
          headers: await _headers(),
          body: jsonEncode({'userIds': userIds}),
        )
        .timeout(_timeout, onTimeout: () => throw Exception('Request timed out. Check your connection.'));

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception('Failed to add members: ${response.statusCode}');
  }

  /// DELETE /api/groupchat/:groupId/members
  Future<Map<String, dynamic>> removeMembers({
    required String groupId,
    required List<String> userIds,
  }) async {
    final request = http.Request(
      'DELETE',
      Uri.parse('${Env.apiBaseUrl}/groupchat/$groupId/members'),
    );
    request.headers.addAll(await _headers());
    request.body = jsonEncode({'userIds': userIds});

    final streamedResponse = await _client
        .send(request)
        .timeout(_timeout, onTimeout: () => throw Exception('Request timed out. Check your connection.'));
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception('Failed to remove members: ${response.statusCode}');
  }

  /// PATCH /api/groupchat/:groupId/rename
  Future<void> renameGroup({
    required String groupId,
    required String name,
  }) async {
    final response = await _client
        .patch(
          Uri.parse('${Env.apiBaseUrl}/groupchat/$groupId/rename'),
          headers: await _headers(),
          body: jsonEncode({'name': name}),
        )
        .timeout(_timeout, onTimeout: () => throw Exception('Request timed out. Check your connection.'));

    if (response.statusCode != 200) {
      throw Exception('Failed to rename group: ${response.statusCode}');
    }
  }

  /// POST /api/groupchat/:groupId/leave
  Future<void> leaveGroup(String groupId) async {
    final response = await _client
        .post(
          Uri.parse('${Env.apiBaseUrl}/groupchat/$groupId/leave'),
          headers: await _headers(),
        )
        .timeout(_timeout, onTimeout: () => throw Exception('Request timed out. Check your connection.'));

    if (response.statusCode != 200) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(body['message'] ?? 'Failed to leave group');
    }
  }

  /// DELETE /api/groupchat/:groupId
  Future<void> deleteGroup(String groupId) async {
    final response = await _client
        .delete(
          Uri.parse('${Env.apiBaseUrl}/groupchat/$groupId'),
          headers: await _headers(),
        )
        .timeout(_timeout, onTimeout: () => throw Exception('Request timed out. Check your connection.'));

    if (response.statusCode != 200) {
      throw Exception('Failed to delete group: ${response.statusCode}');
    }
  }
}