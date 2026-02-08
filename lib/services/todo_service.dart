import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:lockedin_frontend/config/env.dart';
import 'package:lockedin_frontend/models/productivity_tools/todo_list/todo_task.dart';

class TodoService {
  static String get _baseUrl => '${Env.apiBaseUrl}/todo';
  static final _storage = FlutterSecureStorage();

  static Future<String> _getToken() async {
    final token = await _storage.read(key: 'token');
    if (token == null) throw Exception('No auth token');
    return token;
  }

  static Future<String> _getUserId() async {
    final userId = await _storage.read(key: 'userId');
    if (userId == null) throw Exception('No userId found');
    return userId;
  }

  /// GET /tasks?userId=...
  static Future<List<TodoTask>> fetchTodos() async {
    final token = await _getToken();
    final userId = await _getUserId();

    final response = await http.get(
      Uri.parse('$_baseUrl/tasks?userId=$userId'),
      headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'}
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to load todos');
    }

    final List data = json.decode(response.body);
    return data.map((j) => _fromJson(j)).toList();
  }

  /// PATCH /tasks/:id
  static Future<void> updateTodo(String id, {String? title, String? description, Status? status, DateTime? dueDate}) async {
    final token = await _getToken();

    final body = <String, dynamic>{};
    if (title != null) body['title'] = title;
    if (description != null) body['description'] = description;
    if (status != null) body['status'] = status.name;
    if (dueDate != null) body['dueDate'] = dueDate.toIso8601String();

    final response = await http.patch(
      Uri.parse('$_baseUrl/tasks/$id'),
      headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
      body: json.encode(body)
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update todo');
    }
  }

  /// POST /tasks
  static Future<TodoTask> createTodo({required String title, String description = '', DateTime? dueDate}) async {
    final token = await _getToken();
    final userId = await _getUserId();

    final response = await http.post(
      Uri.parse('$_baseUrl/tasks'),
      headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
      body: json.encode(
        {
          'userId': userId,
          'title': title,
          'description': description,
          'dueDate': dueDate?.toIso8601String()
        }
      ),
    );

    if (response.statusCode != 201) {
      throw Exception('Failed to create todo');
    }

    return _fromJson(json.decode(response.body));
  }

  /// DELETE /tasks/:id
  static Future<void> deleteTodo(String id) async {
    final token = await _getToken();

    final response = await http.delete(
      Uri.parse('$_baseUrl/tasks/$id'),
      headers: {'Authorization': 'Bearer $token'}
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete todo');
    }
  }

  // json mapper
  static TodoTask _fromJson(Map<String, dynamic> j) {
    final dueDateTime = j['dueDate'] != null ? DateTime.parse(j['dueDate']) : null;

    return TodoTask(
      id: j['_id'],
      userId: j['userId'],
      title: j['title'],
      description: j['description'] ?? '',
      status: j['status'] == 'completed' ? Status.completed : Status.pending,
      dueDateTime: dueDateTime,
      dueDate: dueDateTime,
      dueTime: dueDateTime != null ? TimeOfDay.fromDateTime(dueDateTime) : null,
    );
  }
}
