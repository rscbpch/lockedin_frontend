import 'package:flutter/material.dart';
import 'package:lockedin_frontend/models/book_summary/book.dart';
import 'package:lockedin_frontend/provider/book_provider.dart';
import 'package:lockedin_frontend/ui/screens/book_summary/book_summary_preview_screen.dart';
import 'package:lockedin_frontend/ui/theme/app_theme.dart';
import 'package:lockedin_frontend/ui/widgets/display/book_card.dart';
import 'package:provider/provider.dart';

class FavoriteBooksScreen extends StatefulWidget {
  const FavoriteBooksScreen({super.key});

  @override
  State<FavoriteBooksScreen> createState() => _FavoriteBooksScreenState();
}

class _FavoriteBooksScreenState extends State<FavoriteBooksScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<BookProvider>();
      provider.loadBooks();
      provider.loadFavorites();
    });
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
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BookSummaryPreviewScreen(book: book, averageRating: context.read<BookProvider>().bookRatings[book.id]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BookProvider>();
    final favorites = provider.favoriteBooks;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Favorites',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, fontFamily: 'Quicksand', color: AppColors.textPrimary),
        ),
        centerTitle: true,
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : favorites.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.favorite_border_rounded, size: 48, color: AppColors.grey.withOpacity(0.5)),
                  const SizedBox(height: 12),
                  const Text(
                    'No favorite books yet',
                    style: TextStyle(fontFamily: 'Quicksand', fontSize: 15, color: AppColors.grey),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: favorites.length,
              itemBuilder: (context, index) {
                final book = favorites[index];
                return BookCard(
                  book: book,
                  averageRating: provider.bookRatings[book.id],
                  isFavorite: true,
                  onReadNow: () => _onReadNow(book),
                  onToggleFavorite: () => _toggleFavorite(book),
                );
              },
            ),
    );
  }
}
