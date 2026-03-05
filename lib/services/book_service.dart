import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/env.dart';
import '../models/book_summary/book.dart';
import '../models/book_summary/book_favorite.dart';
import '../models/book_summary/book_review.dart';
import 'auth_service.dart';

class BookService {
  static String get _base => '${Env.apiBaseUrl}/books';

  // ─── Auth helper ───────────────────────────────────────────────
  static Future<Map<String, String>> _authHeaders() async {
    final token = await AuthService.getToken();
    if (token == null) throw Exception('Not authenticated');
    return {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'};
  }

  // ─── Books ─────────────────────────────────────────────────────

  /// Fetch books with optional [search] query and [category] filter.
  static Future<List<Book>> getBooks({String? search, String? category}) async {
    final queryParams = <String, String>{};
    if (search != null && search.isNotEmpty) queryParams['search'] = search;
    if (category != null && category.isNotEmpty) {
      queryParams['category'] = category;
    }

    final uri = Uri.parse(_base).replace(queryParameters: queryParams.isNotEmpty ? queryParams : null);

    final response = await http.get(uri).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Book.fromJson(json as Map<String, dynamic>)).toList();
    } else {
      throw Exception('Failed to fetch books (${response.statusCode})');
    }
  }

  /// Extract distinct, sorted categories from a list of books.
  static List<String> extractCategories(List<Book> books) {
    final categorySet = <String>{};
    for (final book in books) {
      categorySet.addAll(book.categories);
    }
    final sorted = categorySet.toList()..sort();
    return sorted;
  }

  // ─── Favorites ─────────────────────────────────────────────────

  /// Get authenticated user's favorite books.
  static Future<List<BookFavorite>> getFavorites() async {
    final headers = await _authHeaders();
    final uri = Uri.parse('$_base/favorites');

    final response = await http.get(uri, headers: headers).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => BookFavorite.fromJson(json as Map<String, dynamic>)).toList();
    } else {
      throw Exception('Failed to fetch favorites (${response.statusCode})');
    }
  }

  /// Add a book to favorites.
  static Future<void> addFavorite(int bookId) async {
    final headers = await _authHeaders();
    final uri = Uri.parse('$_base/favorites');

    final response = await http.post(uri, headers: headers, body: jsonEncode({'bookId': bookId})).timeout(const Duration(seconds: 30));

    if (response.statusCode != 201) {
      final body = jsonDecode(response.body);
      throw Exception(body['message'] ?? 'Failed to add favorite');
    }
  }

  /// Remove a book from favorites.
  static Future<void> removeFavorite(int bookId) async {
    final headers = await _authHeaders();
    final uri = Uri.parse('$_base/favorites/$bookId');

    final response = await http.delete(uri, headers: headers).timeout(const Duration(seconds: 30));

    if (response.statusCode != 200) {
      final body = jsonDecode(response.body);
      throw Exception(body['message'] ?? 'Failed to remove favorite');
    }
  }

  // ─── Reviews ───────────────────────────────────────────────────

  /// Get all reviews for a book (public, no auth needed).
  static Future<List<BookReview>> getBookReviews(int bookId) async {
    final uri = Uri.parse('$_base/$bookId/reviews');

    final response = await http.get(uri).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => BookReview.fromJson(json as Map<String, dynamic>)).toList();
    } else {
      throw Exception('Failed to fetch reviews (${response.statusCode})');
    }
  }

  /// Create a review for a book.
  static Future<BookReview> createReview({required int bookId, required int rating, required String feedback}) async {
    final headers = await _authHeaders();
    final uri = Uri.parse('$_base/$bookId/reviews');

    final response = await http.post(uri, headers: headers, body: jsonEncode({'rating': rating, 'feedback': feedback})).timeout(const Duration(seconds: 30));

    if (response.statusCode == 201) {
      return BookReview.fromJson(jsonDecode(response.body));
    } else {
      final body = jsonDecode(response.body);
      throw Exception(body['message'] ?? 'Failed to create review');
    }
  }

  /// Update an existing review.
  static Future<BookReview> updateReview({required String reviewId, int? rating, String? feedback}) async {
    final headers = await _authHeaders();
    final uri = Uri.parse('$_base/reviews/$reviewId');

    final bodyMap = <String, dynamic>{};
    if (rating != null) bodyMap['rating'] = rating;
    if (feedback != null) bodyMap['feedback'] = feedback;

    final response = await http.patch(uri, headers: headers, body: jsonEncode(bodyMap)).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      return BookReview.fromJson(jsonDecode(response.body));
    } else {
      final body = jsonDecode(response.body);
      throw Exception(body['message'] ?? 'Failed to update review');
    }
  }

  /// Delete a review.
  static Future<void> deleteReview(String reviewId) async {
    final headers = await _authHeaders();
    final uri = Uri.parse('$_base/reviews/$reviewId');

    final response = await http.delete(uri, headers: headers).timeout(const Duration(seconds: 30));

    if (response.statusCode != 200) {
      final body = jsonDecode(response.body);
      throw Exception(body['message'] ?? 'Failed to delete review');
    }
  }
}
