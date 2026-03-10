import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/exceptions.dart';
import '../models/study_room/study_room.dart';
import 'package:lockedin_frontend/config/env.dart';

class StudyRoomApiService {
  final String baseUrl = Env.apiBaseUrl;
  final String? Function() getToken;
  final String jaasAppId; // e.g. "vpaas-magic-cookie-xxxxx"

  StudyRoomApiService({
    required this.getToken,
    required this.jaasAppId,
  });

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (getToken() != null) 'Authorization': 'Bearer ${getToken()}',
      };

  Future<T> _handleResponse<T>(
    http.Response res,
    T Function(dynamic) parser,
  ) async {
    final body = jsonDecode(res.body);
    if (res.statusCode >= 200 && res.statusCode < 300) return parser(body);
    throw ApiException(
      body['message'] ?? 'Request failed',
      statusCode: res.statusCode,
    );
  }

  Future<List<StudyRoom>> getActiveRooms() async {
    final res = await http.get(
      Uri.parse('$baseUrl/study-rooms'),
      headers: _headers,
    );
    return _handleResponse(
      res,
      (body) {
        final list = body is List ? body : (body['data'] ?? body) as List;
        return list.map((e) => StudyRoom.fromJson(e as Map<String, dynamic>)).toList();
      },
    );
  }

  Future<StudyRoom> createRoom(String name) async {
    final res = await http.post(
      Uri.parse('$baseUrl/study-rooms'),
      headers: _headers,
      body: jsonEncode({'name': name}),
    );
    return _handleResponse(res, (body) {
      final data = (body is Map && body['data'] is Map) ? body['data'] : body;
      return StudyRoom.fromJson(data as Map<String, dynamic>);
    });
  }

  Future<StudyRoom> joinRoom(String roomId) async {
    final res = await http.post(
      Uri.parse('$baseUrl/study-rooms/$roomId/join'),
      headers: _headers,
    );
    return _handleResponse(res, (body) {
      final data = (body is Map && body['data'] is Map) ? body['data'] : body;
      return StudyRoom.fromJson(data as Map<String, dynamic>);
    });
  }

  Future<void> leaveRoom(String roomId) async {
    final res = await http.post(
      Uri.parse('$baseUrl/study-rooms/$roomId/leave'),
      headers: _headers,
    );
    _handleResponse(res, (_) => null);
  }

  // Fetches a JaaS JWT token from your backend
  // The backend signs it with RS256 and sets moderator: true
  Future<String> getJitsiToken({
    required String roomId,
    required String displayName,
    required String email,
    required String avatar, 
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/study-rooms/jitsi-token'),
      headers: _headers,
      body: jsonEncode({
        'roomId': roomId,
        'displayName': displayName,
        'email': email,
        'avatar': avatar,
      }),
    );
    return _handleResponse(res, (body) {
      final data = (body is Map && body['data'] is Map) ? body['data'] : body;
      final token = data['token']?.toString();
      if (token == null || token.isEmpty) {
        throw ApiException('No token received from server');
      }
      return token;
    });
  }
}