import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/env.dart';
import '../services/auth_service.dart';

class FlashcardCard {
  final String id;
  final String flashcardSetId;
  final String front;
  final String back;

  const FlashcardCard({required this.id, required this.flashcardSetId, required this.front, required this.back});

  factory FlashcardCard.fromJson(Map<String, dynamic> json) =>
    FlashcardCard(
      id: json['_id']?.toString() ?? '',
      flashcardSetId: json['flashcardSetId']?.toString() ?? '',
      front: json['front'] ?? '',
      back: json['back'] ?? ''
    );

  Map<String, dynamic> toJson() => {'front': front, 'back': back};
}

class FlashcardSet {
  final String id;
  final String title;
  final int cardCount;
  final DateTime? updatedAt;
  final List<FlashcardCard> cards;

  const FlashcardSet({required this.id, required this.title, this.cardCount = 0, this.updatedAt, this.cards = const []});

  factory FlashcardSet.fromListJson(Map<String, dynamic> json) => FlashcardSet(
    id: json['_id']?.toString() ?? '',
    title: json['title'] ?? '',
    cardCount: (json['cardCount'] as num?)?.toInt() ?? 0,
    updatedAt: json['updatedAt'] != null ? DateTime.tryParse(json['updatedAt']) : null,
  );

  factory FlashcardSet.fromDetailJson(Map<String, dynamic> json) {
  final rawCards = json['cards'] as List<dynamic>? ?? [];

  return FlashcardSet(
    id: json['_id']?.toString() ?? '',
    title: json['title'] ?? '',
    cardCount: (json['cardCount'] as num?)?.toInt() ?? rawCards.length,
    updatedAt: json['updatedAt'] != null ? DateTime.tryParse(json['updatedAt']) : null,
    cards: rawCards.map((c) => FlashcardCard.fromJson(c as Map<String, dynamic>)).toList(),
  );
}
}

class FlashcardTestResult {
  final String id;
  final String flashcardSetId;
  final int correctCount;
  final int wrongCount;
  final int totalCards;
  final DateTime? createdAt;

  const FlashcardTestResult({required this.id, required this.flashcardSetId, required this.correctCount, required this.wrongCount, required this.totalCards, this.createdAt});

  factory FlashcardTestResult.fromJson(Map<String, dynamic> json) => FlashcardTestResult(
    id: json['_id']?.toString() ?? '',
    flashcardSetId: json['flashcardSetId']?.toString() ?? '',
    correctCount: (json['correctCount'] as num?)?.toInt() ?? 0,
    wrongCount: (json['wrongCount'] as num?)?.toInt() ?? 0,
    totalCards: (json['totalCards'] as num?)?.toInt() ?? 0,
    createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt']) : null,
  );
}

// services
class FlashcardService {
  static String get _base => '${Env.apiBaseUrl}/flashcards';

  static Future<Map<String, String>> _authHeaders() async {
    final token = await AuthService.getToken();
    if (token == null) throw Exception('Not authenticated');
    return {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'};
  }

  // flashcard sets ──────────────────────────

  // POST /api/flashcards
  static Future<Map<String, dynamic>> createFlashcardSet({required String title, required List<Map<String, String>> cards}) async {
    try {
      final headers = await _authHeaders();
      final response = await http.post(Uri.parse(_base), headers: headers, body: jsonEncode({'title': title, 'cards': cards}));

      final parsed = _tryDecode(response.body);
      if (response.statusCode == 201) {
        return {'success': true, 'data': parsed};
      }
      return {'success': false, 'message': _extractMessage(parsed, response.body, 'Failed to create flashcard set'), 'statusCode': response.statusCode};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // GET /api/flashcards?search=...
  static Future<List<FlashcardSet>> getFlashcardSets({String? search}) async {
    final headers = await _authHeaders();
    final uri = Uri.parse(_base).replace(queryParameters: search != null && search.isNotEmpty ? {'search': search} : null);

    final response = await http.get(uri, headers: headers);
    if (response.statusCode != 200) {
      throw Exception('Failed to load flashcard sets (${response.statusCode})');
    }

    final List data = jsonDecode(response.body) as List;
    return data.map((e) => FlashcardSet.fromListJson(e as Map<String, dynamic>)).toList();
  }

  // GET /api/flashcards/:id
  static Future<FlashcardSet> getFlashcardSet(String id) async {
    final headers = await _authHeaders();
    final response = await http.get(Uri.parse('$_base/$id'), headers: headers);

    if (response.statusCode != 200) {
      throw Exception('Failed to load flashcard set (${response.statusCode})');
    }

    return FlashcardSet.fromDetailJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  /// PUT /api/flashcards/:id
  static Future<Map<String, dynamic>> updateFlashcardSet(
    String id, {
    String? title,
    List<Map<String, String>>? addCards,
    List<Map<String, String>>? updateCards,
    List<String>? deleteCardIds,
  }) async {
    try {
      final headers = await _authHeaders();
      final body = <String, dynamic>{};
      if (title != null) body['title'] = title;
      if (addCards != null) body['addCards'] = addCards;
      if (updateCards != null) body['updateCards'] = updateCards;
      if (deleteCardIds != null) body['deleteCardIds'] = deleteCardIds;

      final response = await http.put(Uri.parse('$_base/$id'), headers: headers, body: jsonEncode(body));

      final parsed = _tryDecode(response.body);
      if (response.statusCode == 200) {
        return {'success': true, 'message': _extractMessage(parsed, response.body, 'Updated')};
      }
      return {'success': false, 'message': _extractMessage(parsed, response.body, 'Failed to update flashcard set'), 'statusCode': response.statusCode};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // DELETE /api/flashcards/:id
  static Future<Map<String, dynamic>> deleteFlashcardSet(String id) async {
    try {
      final headers = await _authHeaders();
      final response = await http.delete(Uri.parse('$_base/$id'), headers: headers);

      final parsed = _tryDecode(response.body);
      if (response.statusCode == 200) {
        return {'success': true, 'message': _extractMessage(parsed, response.body, 'Deleted')};
      }
      return {'success': false, 'message': _extractMessage(parsed, response.body, 'Failed to delete flashcard set'), 'statusCode': response.statusCode};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // test results ────────────────────────────

  // GET /api/flashcards/test-results
  static Future<List<FlashcardTestResult>> getTestResults() async {
    final headers = await _authHeaders();
    final response = await http.get(Uri.parse('$_base/test-results'), headers: headers);

    if (response.statusCode != 200) {
      throw Exception('Failed to load test results (${response.statusCode})');
    }

    final List data = jsonDecode(response.body) as List;
    return data.map((e) => FlashcardTestResult.fromJson(e as Map<String, dynamic>)).toList();
  }

  // GET /api/flashcards/:id/test-results
  static Future<List<FlashcardTestResult>> getTestResultsBySet(String setId) async {
    final headers = await _authHeaders();
    final response = await http.get(Uri.parse('$_base/$setId/test-results'), headers: headers);

    if (response.statusCode != 200) {
      throw Exception('Failed to load test results (${response.statusCode})');
    }

    final List data = jsonDecode(response.body) as List;
    return data.map((e) => FlashcardTestResult.fromJson(e as Map<String, dynamic>)).toList();
  }

  // POST /api/flashcards/:id/test-result
  static Future<Map<String, dynamic>> saveTestResult({
    required String setId,
    required int correctCount,
    required int wrongCount,
    required int totalCards
  }) async {
    try {
      final headers = await _authHeaders();
      final response = await http.post(
        Uri.parse('$_base/$setId/test-result'),
        headers: headers,
        body: jsonEncode({'correctCount': correctCount, 'wrongCount': wrongCount, 'totalCards': totalCards}),
      );

      final parsed = _tryDecode(response.body);
      if (response.statusCode == 201) {
        return {'success': true, 'data': parsed};
      }
      return {'success': false, 'message': _extractMessage(parsed, response.body, 'Failed to save test result'), 'statusCode': response.statusCode};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // helpers ─────────────────────────────────

  static dynamic _tryDecode(String body) {
    try {
      return jsonDecode(body);
    } catch (_) {
      return null;
    }
  }

  static String _extractMessage(dynamic parsed, String rawBody, String fallback) {
    if (parsed is Map && parsed['message'] != null) {
      return parsed['message'].toString();
    }
    if (rawBody.isNotEmpty) return rawBody;
    return fallback;
  }
}
