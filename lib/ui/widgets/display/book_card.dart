import 'package:flutter/material.dart';
import 'package:lockedin_frontend/models/book_summary/book.dart';
import 'package:lockedin_frontend/ui/theme/app_theme.dart';
import 'package:lockedin_frontend/ui/responsive/responsive.dart';

class BookCard extends StatelessWidget {
  final Book book;
  final double? averageRating;
  final bool isFavorite;
  final VoidCallback onReadNow;
  final VoidCallback onToggleFavorite;

  const BookCard({super.key, required this.book, this.averageRating, this.isFavorite = false, required this.onReadNow, required this.onToggleFavorite});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(Responsive.radius(context, size: 16)),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Book cover
          ClipRRect(
            child: book.coverImageUrl != null
                ? Image.network(
                    book.coverImageUrl!,
                    width: 80,
                    height: 120,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _placeholderCover(),
                    loadingBuilder: (_, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return _placeholderCover(
                        child: const Center(
                          child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary)),
                        ),
                      );
                    },
                  )
                : _placeholderCover(),
          ),
          const SizedBox(width: 14),

          // Book info
          Expanded(
            child: SizedBox(
              height: 120,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Title + rating row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: Responsive.text(context, size: 15) * 1.3 * 2,
                          child: Text(
                            book.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: 'Nunito',
                              fontSize: Responsive.text(context, size: 15),
                              fontWeight: FontWeight.w500,
                              color: AppColors.textPrimary,
                              height: 1.3,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      _ratingBadge(context),
                    ],
                  ),

                  // Author
                  Text(
                    book.author,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontFamily: 'Nunito', fontSize: Responsive.text(context, size: 12), color: AppColors.grey),
                  ),

                  // Read now button + favorite
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 36,
                          child: ElevatedButton(
                            onPressed: onReadNow,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Responsive.radius(context, size: 12))),
                              elevation: 0,
                            ),
                            child: Text(
                              'Read now',
                              style: TextStyle(fontFamily: 'Nunito', fontSize: Responsive.text(context, size: 13), fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      GestureDetector(
                        onTap: onToggleFavorite,
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(Responsive.radius(context, size: 12)),
                            border: Border.all(color: Colors.grey.shade400, width: 1.5),
                            color: isFavorite ? AppColors.primary.withOpacity(0.1) : Colors.transparent,
                          ),
                          child: Icon(
                            isFavorite ? Icons.favorite : Icons.favorite_border,
                            color: isFavorite ? Colors.red : AppColors.grey,
                            size: Responsive.icon(context, size: 18),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _ratingBadge(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.star, color: const Color(0xFFFFB800), size: Responsive.icon(context, size: 20)),
        const SizedBox(width: 2),
        Text(
          (averageRating ?? 0.0).toStringAsFixed(1),
          style: TextStyle(fontFamily: 'Nunito', fontSize: Responsive.text(context, size: 12), color: AppColors.textPrimary),
        ),
      ],
    );
  }

  Widget _placeholderCover({Widget? child}) {
    return Container(
      width: 80,
      height: 120,
      color: Colors.grey.shade200,
      child: child ?? Icon(Icons.menu_book_rounded, color: Colors.grey.shade400, size: 36),
    );
  }
}
