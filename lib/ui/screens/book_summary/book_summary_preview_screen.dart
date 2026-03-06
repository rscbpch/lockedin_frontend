import 'package:flutter/material.dart';
import 'package:lockedin_frontend/models/book_summary/book.dart';
import 'package:lockedin_frontend/models/book_summary/book_review.dart';
import 'package:lockedin_frontend/provider/book_provider.dart';
import 'package:lockedin_frontend/services/book_service.dart';
import 'package:lockedin_frontend/ui/screens/book_summary/widgets/add_review_bottom_sheet.dart';
import 'package:lockedin_frontend/ui/screens/book_summary/widgets/preview_header.dart';
import 'package:lockedin_frontend/ui/screens/book_summary/widgets/preview_rating_section.dart';
import 'package:lockedin_frontend/ui/screens/book_summary/widgets/preview_reviews_section.dart';
import 'package:lockedin_frontend/ui/screens/book_summary/widgets/preview_summary_section.dart';
import 'package:lockedin_frontend/ui/theme/app_theme.dart';
import 'package:lockedin_frontend/ui/widgets/actions/long_button.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class BookSummaryPreviewScreen extends StatefulWidget {
  final Book book;
  final double? averageRating;

  const BookSummaryPreviewScreen({super.key, required this.book, this.averageRating});

  @override
  State<BookSummaryPreviewScreen> createState() => _BookSummaryPreviewScreenState();
}

class _BookSummaryPreviewScreenState extends State<BookSummaryPreviewScreen> {
  List<BookReview> _reviews = [];
  bool _isLoadingReviews = true;
  bool _summaryExpanded = false;
  double? _currentRating;

  @override
  void initState() {
    super.initState();
    _currentRating = widget.averageRating;
    _loadReviews();
  }

  Future<void> _loadReviews() async {
    try {
      final reviews = await BookService.getBookReviews(widget.book.id);
      if (mounted) {
        setState(() {
          _reviews = reviews;
          _isLoadingReviews = false;
          if (reviews.isNotEmpty) {
            _currentRating = reviews.map((r) => r.rating).reduce((a, b) => a + b) / reviews.length;
          }
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingReviews = false);
    }
  }

  Future<void> _openBook() async {
    final url = widget.book.formats['text/html'] ?? widget.book.formats['text/plain; charset=utf-8'];
    if (url != null) {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    }
  }

  void _showAddReviewBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return AddReviewBottomSheet(
          onSubmit: (rating, feedback) async {
            try {
              await BookService.createReview(bookId: widget.book.id, rating: rating, feedback: feedback);
              if (!mounted) {
                return;
              }

              Navigator.of(ctx).pop();
              await _loadReviews();

              if (_currentRating != null) {
                context.read<BookProvider>().updateRating(widget.book.id, _currentRating!);
              }

              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Review submitted!')));
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red.shade400));
              }
              rethrow;
            }
          },
        );
      },
    );
  }

  String _timeAgo(DateTime? dt) {
    if (dt == null) return '';

    String withUnit(int value, String unit) {
      final suffix = value == 1 ? '' : 's';
      return '$value $unit$suffix ago';
    }

    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return withUnit(diff.inMinutes, 'minute');
    if (diff.inHours < 24) return withUnit(diff.inHours, 'hour');
    if (diff.inDays < 7) return withUnit(diff.inDays, 'day');
    return withUnit((diff.inDays / 7).floor(), 'week');
  }

  @override
  Widget build(BuildContext context) {
    final rating = _currentRating ?? 0.0;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  PreviewSummarySection(
                    title: widget.book.title,
                    summary: widget.book.summary,
                    isExpanded: _summaryExpanded,
                    onToggleExpanded: () => setState(() => _summaryExpanded = !_summaryExpanded),
                  ),
                  const SizedBox(height: 24),
                  PreviewRatingSection(rating: rating, isLoadingReviews: _isLoadingReviews, reviewCount: _reviews.length),
                  const SizedBox(height: 24),
                  PreviewReviewsSection(isLoadingReviews: _isLoadingReviews, reviews: _reviews, timeAgoBuilder: _timeAgo),
                  const SizedBox(height: 24),
                  LongButton(text: 'Add review', onPressed: _showAddReviewBottomSheet),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return PreviewHeader(book: widget.book, onBack: () => Navigator.of(context, rootNavigator: true).pop(), onOpenBook: _openBook);
  }
}
