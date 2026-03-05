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

  List<Book> get books => _books;
  List<String> get categories => _categories;
  Set<int> get favoriteBookIds => _favoriteBookIds;
  Map<int, double> get bookRatings => _bookRatings;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasFetchedBooks => _hasFetchedBooks;

  /// Load books from API. Uses cache if already fetched and [forceRefresh] is false.
  Future<void> loadBooks({String? search, String? category, bool forceRefresh = false}) async {
    // Use cached data if available and no filters/search applied and not forcing refresh
    if (_hasFetchedBooks && !forceRefresh && search == null && category == null) {
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final books = await BookService.getBooks(search: search, category: category);
      final categories = BookService.extractCategories(books);

      final ratings = <int, double>{};
      for (final book in books) {
        // Preserve existing cached ratings to avoid re-fetching
        if (_bookRatings.containsKey(book.id) && !forceRefresh) {
          ratings[book.id] = _bookRatings[book.id]!;
          continue;
        }
        try {
          final reviews = await BookService.getBookReviews(book.id);
          if (reviews.isNotEmpty) {
            final avg = reviews.map((r) => r.rating).reduce((a, b) => a + b) / reviews.length;
            ratings[book.id] = avg;
          }
        } catch (_) {}
      }

      _books = books;
      _categories = categories;
      _bookRatings = ratings;
      _hasFetchedBooks = (search == null && category == null);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
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
    _isLoading = false;
    _error = null;
    notifyListeners();
  }
}
