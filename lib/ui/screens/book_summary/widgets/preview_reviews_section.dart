import 'package:flutter/material.dart';
import 'package:lockedin_frontend/models/book_summary/book_review.dart';
import 'package:lockedin_frontend/ui/responsive/responsive.dart';
import 'package:lockedin_frontend/ui/screens/book_summary/widgets/review_card.dart';
import 'package:lockedin_frontend/ui/theme/app_theme.dart';

class PreviewReviewsSection extends StatelessWidget {
  final bool isLoadingReviews;
  final List<BookReview> reviews;
  final String Function(DateTime? dateTime) timeAgoBuilder;
  final VoidCallback? onViewAll;

  const PreviewReviewsSection({super.key, required this.isLoadingReviews, required this.reviews, required this.timeAgoBuilder, this.onViewAll});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: onViewAll,
          child: Row(
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
              if (reviews.length > 1) ...[
                const SizedBox(width: 4),
                Text(
                  '+${reviews.length - 1}',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: Responsive.text(context, size: 14),
                    fontWeight: FontWeight.w500,
                    color: AppColors.grey,
                  ),
                ),
              ],
              const SizedBox(width: 2),
              const Icon(Icons.chevron_right, size: 20, color: AppColors.textPrimary),
            ],
          ),
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
              color: AppColors.grey),
          )
        else
          ReviewCard(review: reviews.first, timeAgoBuilder: timeAgoBuilder),
      ],
    );
  }
}
