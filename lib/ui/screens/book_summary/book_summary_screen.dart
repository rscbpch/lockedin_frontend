import 'package:flutter/material.dart';
import 'package:lockedin_frontend/models/book_summary/book.dart';
import 'package:lockedin_frontend/provider/book_provider.dart';
import 'package:lockedin_frontend/ui/theme/app_theme.dart';
import 'package:lockedin_frontend/ui/responsive/responsive.dart';
import 'package:lockedin_frontend/ui/widgets/display/lockedin_appbar.dart';
import 'package:lockedin_frontend/ui/widgets/inputs/search_bar_widget.dart';
import 'package:lockedin_frontend/ui/screens/book_summary/widgets/category_chips.dart';
import 'package:lockedin_frontend/ui/widgets/display/book_card.dart';
import 'package:lockedin_frontend/ui/screens/book_summary/book_summary_preview_screen.dart';
import 'package:provider/provider.dart';

class BookSummaryScreen extends StatefulWidget {
  const BookSummaryScreen({super.key});

  @override
  State<BookSummaryScreen> createState() => _BookSummaryScreenState();
}

class _BookSummaryScreenState extends State<BookSummaryScreen> {
  final _searchController = TextEditingController();
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<BookProvider>();
      provider.loadBooks();
      provider.loadCategories();
      provider.loadFavorites();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearch(String query) {
    context.read<BookProvider>().loadBooks(search: query.isNotEmpty ? query : null, category: _selectedCategory, forceRefresh: true);
  }

  void _onClearSearch() {
    _searchController.clear();
    context.read<BookProvider>().loadBooks(category: _selectedCategory, forceRefresh: true);
  }

  void _onCategorySelected(String? category) {
    setState(() => _selectedCategory = category);
    context.read<BookProvider>().loadBooks(search: _searchController.text.isNotEmpty ? _searchController.text : null, category: category, forceRefresh: true);
  }

  Future<void> _toggleFavorite(Book book) async {
    try {
      await context.read<BookProvider>().toggleFavorite(book.id);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red.shade400));
      }
    }
  }

  void _onReadNow(Book book) {
    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(
        builder: (_) => BookSummaryPreviewScreen(book: book, averageRating: context.read<BookProvider>().bookRatings[book.id]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BookProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const LockedInAppBar(),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              const SizedBox(height: 4),
              SearchBarWidget(controller: _searchController, onSubmitted: _onSearch, onClear: _onClearSearch, hintText: 'Search books'),
              const SizedBox(height: 16),
              CategoryChips(categories: provider.categories, selectedCategory: _selectedCategory, onSelected: _onCategorySelected),
              const SizedBox(height: 12),
              Expanded(child: _buildBody(provider)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(BookProvider provider) {
    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

    if (provider.error != null && provider.books.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, color: Colors.red.shade300, size: 48),
            const SizedBox(height: 12),
            Text(
              'Failed to load books',
              style: TextStyle(fontFamily: 'Nunito', fontSize: Responsive.text(context, size: 16), fontWeight: FontWeight.w600, color: AppColors.grey),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => provider.loadBooks(search: _searchController.text.isNotEmpty ? _searchController.text : null, category: _selectedCategory, forceRefresh: true),
              child: Text(
                'Retry',
                style: TextStyle(fontFamily: 'Nunito', color: AppColors.primary, fontSize: Responsive.text(context, size: 16)),
              ),
            ),
          ],
        ),
      );
    }

    if (provider.books.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.menu_book_rounded, color: AppColors.grey, size: 40),
            const SizedBox(height: 12),
            Text(
              'No books found',
              style: TextStyle(fontFamily: 'Nunito', fontSize: Responsive.text(context, size: 16), fontWeight: FontWeight.w600, color: AppColors.grey),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () => provider.loadBooks(search: _searchController.text.isNotEmpty ? _searchController.text : null, category: _selectedCategory, forceRefresh: true),
      child: ListView.builder(
        itemCount: provider.books.length,
        itemBuilder: (context, index) {
          final book = provider.books[index];
          return BookCard(
            book: book,
            averageRating: provider.bookRatings[book.id],
            isFavorite: provider.favoriteBookIds.contains(book.id),
            onReadNow: () => _onReadNow(book),
            onToggleFavorite: () => _toggleFavorite(book),
          );
        },
      ),
    );
  }
}
