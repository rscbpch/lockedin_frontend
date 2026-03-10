import 'package:flutter/material.dart';
import 'package:lockedin_frontend/models/book_summary/book_review.dart';
import 'package:lockedin_frontend/provider/book_provider.dart';
import 'package:lockedin_frontend/services/book_service.dart';
import 'package:lockedin_frontend/ui/responsive/responsive.dart';
import 'package:lockedin_frontend/ui/screens/book_summary/widgets/add_review_bottom_sheet.dart';
import 'package:lockedin_frontend/ui/screens/book_summary/widgets/review_card.dart';
import 'package:lockedin_frontend/ui/theme/app_theme.dart';
import 'package:lockedin_frontend/ui/widgets/actions/long_button.dart';
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

  @override
  void initState() {
    super.initState();
    _loadReviews();
  }

  Future<void> _loadReviews() async {
    try {
      final reviews = await BookService.getBookReviews(widget.bookId);
      if (!mounted) return;
      setState(() {
        _reviews = reviews;
        _isLoading = false;
        if (reviews.isNotEmpty) {
          _averageRating = reviews.map((r) => r.rating).reduce((a, b) => a + b) / reviews.length;
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  void _showAddReviewBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (sheetCtx) {
        return AddReviewBottomSheet(
          onSubmit: (rating, feedback) async {
            try {
              await BookService.createReview(bookId: widget.bookId, rating: rating, feedback: feedback);
              if (!mounted) return;
              Navigator.of(sheetCtx).pop();
              await _loadReviews();

              if (_reviews.isNotEmpty) {
                context.read<BookProvider>().updateRating(widget.bookId, _averageRating);
              }

              if (!mounted) return;
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
    return Scaffold(
      backgroundColor: AppColors.background,
      // body: SafeArea(
      //   child: Column(
      //     children: [
      //       Padding(
      //         padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      //         child: Stack(
      //           alignment: Alignment.center,
      //           children: [
      //             Align(
      //               alignment: Alignment.centerLeft,
      //               child: IconButton(
      //                 icon: const Icon(Icons.chevron_left, color: AppColors.textPrimary, size: 28),
      //                 onPressed: () => Navigator.of(context).pop(),
      //               ),
      //             ),
      //             Text(
      //               'Reviews',
      //               style: TextStyle(fontFamily: 'Nunito', fontSize: Responsive.text(context, size: 18), fontWeight: FontWeight.w700, color: AppColors.textPrimary),
      //             ),
      //           ],
      //         ),
      //       ),
      //       Expanded(
      //         child: _isLoading
      //             ? const Center(child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2))
      //             : ListView(
      //                 padding: const EdgeInsets.symmetric(horizontal: 20),
      //                 children: [
      //                   // ─── Rating summary ──────────────────
      //                   _buildRatingSummary(context),
      //                   const SizedBox(height: 16),
      //                   const Divider(height: 1, color: Color(0xFFE8E8E8)),
      //                   const SizedBox(height: 16),
      //                   // ─── Reviews list ────────────────────
      //                   if (_reviews.isEmpty)
      //                     Padding(
      //                       padding: const EdgeInsets.only(top: 40),
      //                       child: Center(
      //                         child: Text(
      //                           'No reviews yet. Be the first to review!',
      //                           style: TextStyle(fontFamily: 'Nunito', fontSize: Responsive.text(context, size: 14), color: AppColors.grey),
      //                         ),
      //                       ),
      //                     )
      //                   else
      //                     ..._reviews.map((review) => ReviewCard(review: review, timeAgoBuilder: _timeAgo)),
      //                 ],
      //               ),
      //       ),

      //       // ─── Bottom button ───────────────────────────────
      //       Padding(
      //         padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      //         child: LongButton(text: 'Add review', onPressed: _showAddReviewBottomSheet),
      //       ),
      //     ],
      //   ),
      // ),

      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: CustomScrollView(
                slivers: [
                  _buildSliverAppBar(),

                  SliverToBoxAdapter(
                    child: _isLoading
                        ? const Padding(
                            padding: EdgeInsets.only(top: 100),
                            child: Center(
                              child: CircularProgressIndicator(
                                color: AppColors.primary,
                                strokeWidth: 2,
                              ),
                            ),
                          )
                        : Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Column(
                              children: [
                                _buildRatingSummary(context),
                                const SizedBox(height: 16),
                                const Divider(height: 1, color: Color(0xFFE8E8E8)),
                                const SizedBox(height: 16),

                                if (_reviews.isEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 40),
                                    child: Center(
                                      child: Text(
                                        'No reviews yet. Be the first to review!',
                                        style: TextStyle(
                                          fontFamily: 'Nunito',
                                          fontSize: Responsive.text(context, size: 14),
                                          color: AppColors.grey,
                                        ),
                                      ),
                                    ),
                                  )
                                else
                                  ..._reviews.map(
                                    (review) => ReviewCard(
                                      review: review,
                                      timeAgoBuilder: _timeAgo,
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
                text: 'Add review',
                onPressed: _showAddReviewBottomSheet,
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
          style: TextStyle(fontFamily: 'Nunito', fontSize: Responsive.text(context, size: 13), color: AppColors.grey),
        ),
      ],
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      pinned: true,
      elevation: 0,
      backgroundColor: AppColors.background,
      surfaceTintColor: Colors.transparent,

      title: Text(
        'Reviews',
        style: TextStyle(
          fontFamily: 'Nunito',
          fontSize: Responsive.text(context, size: 18),
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
      ),

      leading: IconButton(
        icon: const Icon(
          Icons.chevron_left,
          color: AppColors.textPrimary,
          size: 28,
        ),
        onPressed: () => Navigator.of(context).pop(),
      ),
    );
  }
}
