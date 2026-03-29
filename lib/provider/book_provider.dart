import 'package:flutter/foundation.dart';
import 'package:lockedin_frontend/models/book_summary/book.dart';
import 'package:lockedin_frontend/services/book_service.dart';

class BookProvider extends ChangeNotifier {
  List<Book> _books = [];
  List<String> _categories = [];
  Set<int> _favoriteBookIds = {};
  Map<int, double> _bookRatings = {};
  bool _isLoading = false;
  String? _error;
  bool _hasFetchedBooks = false;
  bool _hasFetchedFavorites = false;
  bool _hasFetchedCategories = false;

  List<Book> get books => _books;
  List<String> get categories => _categories;
  Set<int> get favoriteBookIds => _favoriteBookIds;
  Map<int, double> get bookRatings => _bookRatings;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasFetchedBooks => _hasFetchedBooks;

  /// Books that the user has favorited.
  List<Book> get favoriteBooks => _books.where((b) => _favoriteBookIds.contains(b.id)).toList();

  /// Load books from API. Uses cache if already fetched and [forceRefresh] is false.
  Future<void> loadBooks({String? search, String? category, bool forceRefresh = false}) async {
    if (_hasFetchedBooks && !forceRefresh && search == null && category == null) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final books = await BookService.getBooks(search: search, category: category);

      // ✅ Fetch all reviews in parallel
      final reviewFutures = books.map((book) async {
        if (_bookRatings.containsKey(book.id) && !forceRefresh) {
          return MapEntry(book.id, _bookRatings[book.id]!);
        }
        try {
          final reviews = await BookService.getBookReviews(book.id);
          if (reviews.isNotEmpty) {
            final avg = reviews.map((r) => r.rating).reduce((a, b) => a + b) / reviews.length;
            return MapEntry(book.id, avg);
          }
        } catch (_) {}
        return null;
      });

      final results = await Future.wait(reviewFutures);
      final ratings = <int, double>{};
      for (final entry in results) {
        if (entry != null) ratings[entry.key] = entry.value;
      }

      _books = books;
      _bookRatings = ratings;
      _hasFetchedBooks = (search == null && category == null);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load categories from backend API. Uses cache if already fetched.
  Future<void> loadCategories({bool forceRefresh = false}) async {
    if (_hasFetchedCategories && !forceRefresh) return;

    try {
      final categories = await BookService.getCategories();
      _categories = categories;
      _hasFetchedCategories = true;
      notifyListeners();
    } catch (_) {}
  }

  /// Load favorites from API. Uses cache if already fetched.
  Future<void> loadFavorites({bool forceRefresh = false}) async {
    if (_hasFetchedFavorites && !forceRefresh) return;

    try {
      final favorites = await BookService.getFavorites();
      _favoriteBookIds = favorites.map((f) => f.bookId).toSet();
      _hasFetchedFavorites = true;
      notifyListeners();
    } catch (_) {}
  }

  /// Toggle favorite with optimistic update.
  Future<void> toggleFavorite(int bookId) async {
    final wasFav = _favoriteBookIds.contains(bookId);

    // Optimistic update
    if (wasFav) {
      _favoriteBookIds.remove(bookId);
    } else {
      _favoriteBookIds.add(bookId);
    }
    notifyListeners();

    try {
      if (wasFav) {
        await BookService.removeFavorite(bookId);
      } else {
        await BookService.addFavorite(bookId);
      }
    } catch (_) {
      // Revert on failure
      if (wasFav) {
        _favoriteBookIds.add(bookId);
      } else {
        _favoriteBookIds.remove(bookId);
      }
      notifyListeners();
      rethrow;
    }
  }

  /// Update a single book's rating in cache.
  void updateRating(int bookId, double rating) {
    _bookRatings[bookId] = rating;
    notifyListeners();
  }

  /// Clear all cached data (e.g. on logout).
  void clear() {
    _books = [];
    _categories = [];
    _favoriteBookIds = {};
    _bookRatings = {};
    _hasFetchedBooks = false;
    _hasFetchedFavorites = false;
    _hasFetchedCategories = false;
    _isLoading = false;
    _error = null;
    notifyListeners();
  }
}
