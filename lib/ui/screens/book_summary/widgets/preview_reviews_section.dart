import 'package:flutter/material.dart';
import 'package:lockedin_frontend/models/book_summary/book_review.dart';
import 'package:lockedin_frontend/ui/responsive/responsive.dart';
import 'package:lockedin_frontend/ui/screens/book_summary/widgets/review_card.dart';
import 'package:lockedin_frontend/ui/theme/app_theme.dart';

class PreviewReviewsSection extends StatelessWidget {
  final bool isLoadingReviews;
  final List<BookReview> reviews;
  final String Function(DateTime? dateTime) timeAgoBuilder;

  const PreviewReviewsSection({super.key, required this.isLoadingReviews, required this.reviews, required this.timeAgoBuilder});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Reviews',
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: Responsive.text(context, size: 16),
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary
              ),
            ),
            const SizedBox(width: 2),
            const Icon(Icons.chevron_right, size: 20, color: AppColors.textPrimary),
          ],
        ),
        const SizedBox(height: 12),
        if (isLoadingReviews)
          const Center(child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2))
        else if (reviews.isEmpty)
          Text(
            'No reviews yet. Be the first to review!',
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: Responsive.text(context, size: 14),
              color: AppColors.grey
            ),
          )
        else
          ...reviews.take(3).map((review) {
            return ReviewCard(review: review, timeAgoBuilder: timeAgoBuilder);
          }),
      ],
    );
  }
}
