import 'package:flutter/material.dart';
import 'package:lockedin_frontend/models/book_summary/book.dart';
import 'package:lockedin_frontend/ui/responsive/responsive.dart';
import 'package:lockedin_frontend/ui/theme/app_theme.dart';

class PreviewHeader extends StatelessWidget {
  final Book book;
  final VoidCallback onBack;
  final VoidCallback onOpenBook;

  const PreviewHeader({super.key, required this.book, required this.onBack, required this.onOpenBook});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.backgroundBox,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(4, 4, 16, 20),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(onPressed: onBack, icon: const Icon(Icons.chevron_left, size: 28), color: AppColors.textPrimary),
                  IconButton(onPressed: onOpenBook, icon: const Icon(Icons.ios_share, size: 22), color: AppColors.textPrimary),
                ],
              ),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: book.coverImageUrl != null
                          ? Image.network(book.coverImageUrl!, width: 100, height: 140, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _placeholderCover())
                          : _placeholderCover(),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text(
                            book.title,
                            style: TextStyle(
                              fontFamily: 'Nunito',
                              fontSize: Responsive.text(context, size: 22),
                              fontWeight: FontWeight.w500,
                              color: AppColors.textPrimary,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            book.author,
                            style: TextStyle(
                              fontFamily: 'Quicksand',
                              fontSize: Responsive.text(context, size: 14),
                              color: AppColors.grey,
                              fontWeight: FontWeight.w500
                            ),
                          ),
                          // const SizedBox(height: 10),
                          // if (book.categories.isNotEmpty)
                          //   Wrap(
                          //     spacing: 6,
                          //     runSpacing: 4,
                          //     children: book.categories.take(2).map((cat) {
                          //       return Container(
                          //         padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          //         decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(20)),
                          //         child: Text(
                          //           cat,
                          //           style: TextStyle(fontFamily: 'Nunito', fontSize: Responsive.text(context, size: 12), color: AppColors.textPrimary, fontWeight: FontWeight.w500),
                          //         ),
                          //       );
                          //     }).toList(),
                          //   ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _placeholderCover() {
    return Container(
      width: 100,
      height: 140,
      color: Colors.grey.shade200,
      child: Icon(Icons.menu_book_rounded, color: Colors.grey.shade400, size: 36),
    );
  }
}
