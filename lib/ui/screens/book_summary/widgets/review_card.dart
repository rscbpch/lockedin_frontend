import 'package:flutter/material.dart';
import 'package:lockedin_frontend/models/book_summary/book_review.dart';
import 'package:lockedin_frontend/ui/responsive/responsive.dart';
import 'package:lockedin_frontend/ui/theme/app_theme.dart';

class ReviewCard extends StatelessWidget {
  final BookReview review;
  final String Function(DateTime? dateTime) timeAgoBuilder;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const ReviewCard({super.key, required this.review, required this.timeAgoBuilder, this.onEdit, this.onDelete});

  @override
  Widget build(BuildContext context) {
    final displayName = review.user?.displayName.isNotEmpty == true ? review.user!.displayName : (review.user?.username ?? 'User');
    final avatarUrl = review.user?.avatar;
    final initials = displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U';

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.backgroundBox,
                backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
                child: avatarUrl == null
                    ? Text(
                        initials,
                        style: TextStyle(fontFamily: 'Nunito', color: AppColors.primary, fontWeight: FontWeight.w500, fontSize: Responsive.text(context, size: 18)),
                      )
                    : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            displayName,
                            style: TextStyle(fontFamily: 'Nunito', fontSize: Responsive.text(context, size: 16), fontWeight: FontWeight.w500, color: AppColors.textPrimary),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: List.generate(5, (i) {
                              return Icon(i < review.rating ? Icons.star : Icons.star_border, color: const Color(0xFFFFB800), size: 16);
                            }),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          timeAgoBuilder(review.createdAt),
                          style: TextStyle(fontFamily: 'Nunito', fontSize: Responsive.text(context, size: 12), color: AppColors.grey),
                        ),
                        if (onEdit != null || onDelete != null) ...[
                          const SizedBox(height: 4),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (onEdit != null)
                                GestureDetector(
                                  onTap: onEdit,
                                  child: Icon(Icons.edit_outlined, size: 20, color: AppColors.grey),
                                ),
                              if (onEdit != null && onDelete != null)
                                const SizedBox(width: 8),
                              if (onDelete != null)
                                GestureDetector(
                                  onTap: onDelete,
                                  child: Icon(Icons.delete_outline, size: 20, color: Colors.red.shade400),
                                ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            review.feedback,
            style: TextStyle(fontFamily: 'Quicksand', fontSize: Responsive.text(context, size: 16), color: AppColors.textPrimary),
          ),
        ],
      ),
    );
  }
}
