import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:lockedin_frontend/config/env.dart';
import 'package:provider/provider.dart';
import '../provider/auth_provider.dart';

class AiBreakdownService {
  static String get _baseUrl => '${Env.apiBaseUrl}/ai';

  final BuildContext context;

  AiBreakdownService(this.context);

  // -----------------------------
  // HEADERS (TOKEN FROM PROVIDER)
  // -----------------------------
  Map<String, String> _headers() {
    final auth = context.read<AuthProvider>();
    final token = auth.token;

    if (token == null || token.isEmpty) {
      throw Exception('User not authenticated');
    }

    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // -----------------------------
  // POST /ai/task-breakdown/chat
  // -----------------------------
  Future<Map<String, dynamic>> sendMessage({
    required String message,
    String? chatId,
  }) async {
    final uri = Uri.parse('$_baseUrl/task-breakdown/chat');

    final body = {'message': message, if (chatId != null) 'chatId': chatId};

    final response = await http.post(
      uri,
      headers: _headers(),
      body: jsonEncode(body),
    );

    return _handleMapResponse(response);
  }

  // -----------------------------
  // GET /ai/chats
  // Backend returns a plain JSON array: [{...}, {...}]
  // -----------------------------
  Future<List<Map<String, dynamic>>> getChats({
    int limit = 20,
    int skip = 0,
  }) async {
    final uri = Uri.parse('$_baseUrl/chats?limit=$limit&skip=$skip');
    final response = await http.get(uri, headers: _headers());

    debugPrint('GET /ai/chats status: ${response.statusCode}');
    debugPrint('GET /ai/chats body: ${response.body}');

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final data = jsonDecode(response.body);
      throw Exception(
        data['error'] ?? 'Request failed (${response.statusCode})',
      );
    }

    final decoded = jsonDecode(response.body);

    // Backend returns a raw array
    if (decoded is List) {
      return decoded.cast<Map<String, dynamic>>();
    }

    // Fallback if backend ever wraps it: { "chats": [...] }
    if (decoded is Map<String, dynamic>) {
      final chats = decoded['chats'];
      if (chats is List) return chats.cast<Map<String, dynamic>>();
    }

    debugPrint('[AiBreakdownService] Unexpected getChats format: $decoded');
    return [];
  }

  // -----------------------------
  // GET /ai/chats/:chatId
  // -----------------------------
  Future<Map<String, dynamic>> getChatById(String chatId) async {
    final uri = Uri.parse('$_baseUrl/chats/$chatId');

    final response = await http.get(uri, headers: _headers());

    return _handleMapResponse(response);
  }

  // -----------------------------
  // RESPONSE HANDLER (Map only)
  // -----------------------------
  Map<String, dynamic> _handleMapResponse(http.Response response) {
    final data = jsonDecode(response.body);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return data as Map<String, dynamic>;
    }

    throw Exception(data['error'] ?? 'Request failed (${response.statusCode})');
  }
}