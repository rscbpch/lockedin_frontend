import 'package:flutter/material.dart';
import 'package:lockedin_frontend/ui/responsive/responsive.dart';
import 'package:lockedin_frontend/ui/theme/app_theme.dart';

class PreviewRatingSection extends StatelessWidget {
  final double rating;
  final bool isLoadingReviews;
  final int reviewCount;

  const PreviewRatingSection({super.key, required this.rating, required this.isLoadingReviews, required this.reviewCount});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Rating',
          style: TextStyle(
            fontFamily: 'Nunito',
            fontSize: Responsive.text(context, size: 18),
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary
          ),
        ),
        const SizedBox(height: 4),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              children: List.generate(5, (i) {
                if (i < rating.floor()) {
                  return Icon(Icons.star, color: const Color(0xFFFFB800), size: Responsive.icon(context, size: 28));
                }
                if (rating - i >= 0.5) {
                  return Icon(Icons.star_half, color: const Color(0xFFFFB800), size: Responsive.icon(context, size: 28));
                }
                return Icon(Icons.star_border, color: const Color(0xFFFFB800), size: Responsive.icon(context, size: 28));
              }),
            ),
            const Spacer(),
            Text(
              rating.toStringAsFixed(1),
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: Responsive.text(context, size: 24),
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary
              ),
            ),
          ],
        ),
        if (!isLoadingReviews && reviewCount > 0)
          Text(
            'Based on $reviewCount review${reviewCount == 1 ? '' : 's'}',
            style: TextStyle(
              fontFamily: 'Quicksand',
              fontSize: Responsive.text(context, size: 12),
              color: AppColors.grey,
              fontWeight: FontWeight.w500
            ),
          ),
      ],
    );
  }
}
