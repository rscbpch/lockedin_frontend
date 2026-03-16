import 'package:flutter/material.dart';
import 'package:lockedin_frontend/models/book_summary/book.dart';
import 'package:lockedin_frontend/models/book_summary/book_review.dart';
import 'package:lockedin_frontend/provider/book_provider.dart';
import 'package:lockedin_frontend/services/auth_service.dart';
import 'package:lockedin_frontend/services/book_service.dart';
import 'package:lockedin_frontend/ui/responsive/responsive.dart';
import 'package:lockedin_frontend/ui/screens/book_summary/widgets/add_review_bottom_sheet.dart';
import 'package:lockedin_frontend/ui/screens/book_summary/widgets/preview_header.dart';
import 'package:lockedin_frontend/ui/screens/book_summary/widgets/preview_rating_section.dart';
import 'package:lockedin_frontend/ui/screens/book_summary/book_summary_reviews.dart';
import 'package:lockedin_frontend/ui/screens/book_summary/widgets/preview_reviews_section.dart';
import 'package:lockedin_frontend/ui/screens/book_summary/widgets/preview_summary_section.dart';
import 'package:lockedin_frontend/ui/theme/app_theme.dart';
import 'package:lockedin_frontend/ui/widgets/actions/long_button.dart';
import 'package:lockedin_frontend/ui/widgets/notifications/app_alert_dialog.dart';
import 'package:lockedin_frontend/ui/widgets/notifications/app_snack_bar.dart';
import 'package:lockedin_frontend/utils/activity_tracker.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class BookSummaryPreviewScreen extends StatefulWidget {
  final Book book;
  final double? averageRating;

  const BookSummaryPreviewScreen({super.key, required this.book, this.averageRating});

  @override
  State<BookSummaryPreviewScreen> createState() => _BookSummaryPreviewScreenState();
}

class _BookSummaryPreviewScreenState extends State<BookSummaryPreviewScreen> with ActivityTracker {
  List<BookReview> _reviews = [];
  bool _isLoadingReviews = true;
  bool _summaryExpanded = false;
  double? _currentRating;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _currentRating = widget.averageRating;
    _loadReviews();
  }

  Future<void> _loadReviews() async {
    final currentUserId = await AuthService.getUserId();

    try {
      final reviews = await BookService.getBookReviews(widget.book.id);
      if (mounted) {
        setState(() {
          _currentUserId = currentUserId;
          _reviews = reviews;
          _isLoadingReviews = false;
          if (reviews.isNotEmpty) {
            _currentRating = reviews.map((r) => r.rating).reduce((a, b) => a + b) / reviews.length;
          }
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _currentUserId = currentUserId;
          _isLoadingReviews = false;
        });
      }
    }
  }

  BookReview? get _myReview {
    final userId = _currentUserId;
    if (userId == null || userId.isEmpty) return null;
    for (final review in _reviews) {
      if (review.userId == userId) {
        return review;
      }
    }
    return null;
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

  void _showAddOrEditReviewBottomSheet({BookReview? existingReview}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return AddReviewBottomSheet(
          title: existingReview == null ? 'Add Review' : 'Edit Review',
          submitLabel: existingReview == null ? 'Submit Review' : 'Save Changes',
          initialRating: existingReview?.rating ?? 0,
          initialFeedback: existingReview?.feedback ?? '',
          onSubmit: (rating, feedback) async {
            try {
              if (existingReview == null) {
                if (_myReview != null) {
                  throw Exception('You can only add one review for this book. Edit your existing review instead.');
                }
                await BookService.createReview(bookId: widget.book.id, rating: rating, feedback: feedback);
              } else {
                await BookService.updateReview(reviewId: existingReview.id, rating: rating, feedback: feedback);
              }

              if (!mounted) {
                return;
              }

              Navigator.of(ctx).pop();
              await _loadReviews();

              if (_currentRating != null) {
                context.read<BookProvider>().updateRating(widget.book.id, _currentRating!);
              }

              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(existingReview == null ? 'Review submitted!' : 'Review updated!')));
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

  Future<void> _deleteReview(BookReview review) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => const AppAlertDialog(title: 'Delete review', message: 'Are you sure you want to delete your review?', cancelLabel: 'Cancel', confirmLabel: 'Delete'),
    );

    if (confirmed != true) return;

    final deletedRating = review.rating;
    final deletedFeedback = review.feedback;

    try {
      await BookService.deleteReview(review.id);
      if (!mounted) return;
      await _loadReviews();

      if (_currentRating != null) {
        context.read<BookProvider>().updateRating(widget.book.id, _currentRating!);
      }

      if (!mounted) return;
      AppSnackBar.show(
        context,
        message: 'Review deleted',
        actionLabel: 'Undo',
        onAction: () => _undoDeleteReview(rating: deletedRating, feedback: deletedFeedback),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red.shade400));
    }
  }

  Future<void> _undoDeleteReview({required int rating, required String feedback}) async {
    try {
      await BookService.createReview(bookId: widget.book.id, rating: rating, feedback: feedback);
      if (!mounted) return;
      await _loadReviews();

      if (_currentRating != null) {
        context.read<BookProvider>().updateRating(widget.book.id, _currentRating!);
      }

      if (!mounted) return;
      AppSnackBar.show(context, message: 'Review restored');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red.shade400));
    }
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
    final hasMyReview = _myReview != null;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          _buildSliverHeader(),

          SliverToBoxAdapter(
            child: Padding(
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

                  PreviewReviewsSection(
                    isLoadingReviews: _isLoadingReviews,
                    reviews: _reviews,
                    timeAgoBuilder: _timeAgo,
                    currentUserId: _currentUserId,
                    onEditReview: (review) => _showAddOrEditReviewBottomSheet(existingReview: review),
                    onDeleteReview: _deleteReview,
                    onViewAll: () {
                      Navigator.of(context).push(MaterialPageRoute(builder: (_) => BookSummaryReviewsScreen(bookId: widget.book.id)));
                    },
                  ),

                  const SizedBox(height: 24),

                  LongButton(
                    text: hasMyReview ? 'Edit your comment' : 'Add review',
                    onPressed: () => _showAddOrEditReviewBottomSheet(existingReview: _myReview),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverHeader() {
    return SliverAppBar(
      pinned: true,
      expandedHeight: 240,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      backgroundColor: AppColors.background,

      leading: IconButton(
        icon: const Icon(Icons.chevron_left, size: 32, color: AppColors.textPrimary),
        onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
      ),

      actions: [
        IconButton(
          icon: const Icon(Icons.ios_share, size: 22, color: AppColors.textPrimary),
          onPressed: _openBook,
        ),
      ],

      flexibleSpace: LayoutBuilder(
        builder: (context, constraints) {
          final settings = context.dependOnInheritedWidgetOfExactType<FlexibleSpaceBarSettings>();

          final collapsed = settings != null && settings.currentExtent <= settings.minExtent + 5;

          return Stack(
            fit: StackFit.expand,
            children: [
              FlexibleSpaceBar(background: PreviewHeader(book: widget.book)),

              if (collapsed)
                Positioned(
                  left: 56,
                  right: 56,
                  top: MediaQuery.of(context).padding.top,
                  height: kToolbarHeight,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      widget.book.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontFamily: 'Nunito', fontSize: Responsive.text(context, size: 20), fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
