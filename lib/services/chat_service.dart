import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:lockedin_frontend/config/env.dart';
import '../models/chat/chat_token_model.dart';
import '../models/chat/private_channel_model.dart';

class ChatService {
  final http.Client _client;
  final Future<String?> Function() _getAuthToken;

  ChatService({
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

  /// POST /api/privatechat/token
  Future<ChatTokenModel> fetchChatToken() async {
    final response = await _client.post(
      Uri.parse('${Env.apiBaseUrl}/privatechat/token'),
      headers: await _headers(),
    );

    if (response.statusCode == 200) {
      return ChatTokenModel.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    }

    throw Exception('Failed to fetch chat token: ${response.statusCode}');
  }

  /// POST /api/privatechat/channel
  Future<PrivateChannelModel> createPrivateChannel(String targetUserId) async {
    final response = await _client.post(
      Uri.parse('${Env.apiBaseUrl}/privatechat/channel'),
      headers: await _headers(),
      body: jsonEncode({'targetUserId': targetUserId}),
    );

    if (response.statusCode == 200) {
      return PrivateChannelModel.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    }

    if (response.statusCode == 403) {
      throw Exception('You must mutually follow this user to start a chat.');
    }

    throw Exception('Failed to create channel: ${response.statusCode}');
  }
}