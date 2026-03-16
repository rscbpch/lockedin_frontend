import 'package:flutter/material.dart';
import 'package:lockedin_frontend/models/book_summary/book_review.dart';
import 'package:lockedin_frontend/provider/book_provider.dart';
import 'package:lockedin_frontend/services/auth_service.dart';
import 'package:lockedin_frontend/services/book_service.dart';
import 'package:lockedin_frontend/ui/responsive/responsive.dart';
import 'package:lockedin_frontend/ui/screens/book_summary/widgets/add_review_bottom_sheet.dart';
import 'package:lockedin_frontend/ui/screens/book_summary/widgets/review_card.dart';
import 'package:lockedin_frontend/ui/theme/app_theme.dart';
import 'package:lockedin_frontend/ui/widgets/actions/long_button.dart';
import 'package:lockedin_frontend/ui/widgets/display/simple_back_sliver_app_bar.dart';
import 'package:lockedin_frontend/ui/widgets/notifications/app_alert_dialog.dart';
import 'package:lockedin_frontend/ui/widgets/notifications/app_snack_bar.dart';
import 'package:provider/provider.dart';

class BookSummaryReviewsScreen extends StatefulWidget {
  final int bookId;

  const BookSummaryReviewsScreen({super.key, required this.bookId});

  @override
  State<BookSummaryReviewsScreen> createState() => _BookSummaryReviewsScreenState();
}

class _BookSummaryReviewsScreenState extends State<BookSummaryReviewsScreen> {
  List<BookReview> _reviews = [];
  bool _isLoading = true;
  double _averageRating = 0.0;
  String? _currentUserId;
  ReviewFilter _selectedFilter = ReviewFilter.all;

  @override
  void initState() {
    super.initState();
    _loadReviews();
  }

  Future<void> _loadReviews() async {
    final currentUserId = await AuthService.getUserId();

    try {
      final reviews = await BookService.getBookReviews(widget.bookId);
      if (!mounted) return;
      setState(() {
        _currentUserId = currentUserId;
        _reviews = reviews;
        _isLoading = false;
        if (reviews.isNotEmpty) {
          _averageRating = reviews.map((r) => r.rating).reduce((a, b) => a + b) / reviews.length;
        } else {
          _averageRating = 0.0;
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _currentUserId = currentUserId;
        _isLoading = false;
      });
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

  List<BookReview> get _filteredReviews {
    switch (_selectedFilter) {
      case ReviewFilter.my:
        final own = _myReview;
        return own == null ? const [] : [own];
      case ReviewFilter.all:
        return _reviews;
    }
  }

  void _showAddOrEditReviewBottomSheet({BookReview? existingReview}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (sheetCtx) {
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
                await BookService.createReview(bookId: widget.bookId, rating: rating, feedback: feedback);
              } else {
                await BookService.updateReview(reviewId: existingReview.id, rating: rating, feedback: feedback);
              }

              if (!mounted) return;
              Navigator.of(sheetCtx).pop();
              await _loadReviews();

              context.read<BookProvider>().updateRating(widget.bookId, _averageRating);

              if (!mounted) return;
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
      context.read<BookProvider>().updateRating(widget.bookId, _averageRating);
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
      await BookService.createReview(bookId: widget.bookId, rating: rating, feedback: feedback);
      if (!mounted) return;
      await _loadReviews();
      context.read<BookProvider>().updateRating(widget.bookId, _averageRating);
      if (!mounted) return;
      AppSnackBar.show(context, message: 'Review restored');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red.shade400));
    }
  }

  String _timeAgo(DateTime? dt) {
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) {
      final m = diff.inMinutes;
      return '$m ${m == 1 ? 'minute' : 'minutes'} ago';
    }
    if (diff.inHours < 24) {
      final h = diff.inHours;
      return '$h ${h == 1 ? 'hour' : 'hours'} ago';
    }
    if (diff.inDays < 7) {
      final d = diff.inDays;
      return '$d ${d == 1 ? 'day' : 'days'} ago';
    }
    final w = (diff.inDays / 7).floor();
    return '$w ${w == 1 ? 'week' : 'weeks'} ago';
  }

  @override
  Widget build(BuildContext context) {
    final displayedReviews = _filteredReviews;
    final hasMyReview = _myReview != null;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: CustomScrollView(
                slivers: [
                  const SimpleBackSliverAppBar(title: 'Reviews'),

                  SliverToBoxAdapter(
                    child: _isLoading
                        ? const Padding(
                            padding: EdgeInsets.only(top: 100),
                            child: Center(child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2)),
                          )
                        : Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Column(
                              children: [
                                _buildRatingSummary(context),
                                const SizedBox(height: 14),
                                _buildFilterChips(context),
                                const SizedBox(height: 16),
                                const Divider(height: 1, color: Color(0xFFE8E8E8)),
                                const SizedBox(height: 16),

                                if (displayedReviews.isEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 40),
                                    child: Center(
                                      child: Text(
                                        _selectedFilter == ReviewFilter.my ? 'You have not reviewed this book yet.' : 'No reviews yet. Be the first to review!',
                                        style: TextStyle(fontFamily: 'Nunito', fontSize: Responsive.text(context, size: 16), color: AppColors.grey),
                                      ),
                                    ),
                                  )
                                else
                                  ...displayedReviews.map(
                                    (review) => ReviewCard(
                                      review: review,
                                      timeAgoBuilder: _timeAgo,
                                      onEdit: review.userId == _currentUserId ? () => _showAddOrEditReviewBottomSheet(existingReview: review) : null,
                                      onDelete: review.userId == _currentUserId ? () => _deleteReview(review) : null,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: LongButton(
                text: hasMyReview ? 'Edit your review' : 'Add review',
                onPressed: () => _showAddOrEditReviewBottomSheet(existingReview: _myReview),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingSummary(BuildContext context) {
    final ratingDisplay = _averageRating.toStringAsFixed(1);

    return Column(
      children: [
        const SizedBox(height: 8),
        Text(
          ratingDisplay,
          style: TextStyle(fontFamily: 'Nunito', fontSize: Responsive.text(context, size: 36), fontWeight: FontWeight.w700, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(5, (i) {
            return Icon(i < _averageRating.round() ? Icons.star : Icons.star_border, color: const Color(0xFFFFB800), size: 32);
          }),
        ),
        const SizedBox(height: 6),
        Text(
          'Based on ${_reviews.length} ${_reviews.length == 1 ? 'review' : 'reviews'}',
          style: TextStyle(fontFamily: 'Quicksand', fontSize: Responsive.text(context, size: 12), color: AppColors.grey, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildFilterChips(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _FilterChipButton(label: 'All comments', selected: _selectedFilter == ReviewFilter.all, onTap: () => setState(() => _selectedFilter = ReviewFilter.all)),
        const SizedBox(width: 10),
        _FilterChipButton(label: 'My comment', selected: _selectedFilter == ReviewFilter.my, onTap: () => setState(() => _selectedFilter = ReviewFilter.my)),
      ],
    );
  }
}

enum ReviewFilter { all, my }

class _FilterChipButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChipButton({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary.withValues(alpha: 0.12) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: selected ? AppColors.primary : const Color(0xFFDADADA)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Nunito',
            fontSize: Responsive.text(context, size: 13),
            color: selected ? AppColors.primary : AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
