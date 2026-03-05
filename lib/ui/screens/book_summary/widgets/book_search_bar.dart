import 'package:flutter/material.dart';
import 'package:lockedin_frontend/ui/theme/app_theme.dart';
import 'package:lockedin_frontend/ui/responsive/responsive.dart';

class BookSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onSubmitted;
  final VoidCallback? onClear;

  const BookSearchBar({super.key, required this.controller, required this.onSubmitted, this.onClear});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(Responsive.radius(context, size: 30)),
        border: Border.all(
          color: AppColors.textPrimary,
          width: 1.5
        ),
      ),
      child: TextField(
        controller: controller,
        onSubmitted: onSubmitted,
        style: TextStyle(
          fontFamily: 'Nunito',
          fontSize: Responsive.text(context, size: 14),
          color: AppColors.textPrimary
        ),
        decoration: InputDecoration(
          isDense: true,
          hintText: 'Search books',
          hintStyle: TextStyle(
            fontFamily: 'Nunito',
            fontSize: Responsive.text(context, size: 14),
            color: AppColors.grey
          ),
          prefixIcon: Icon(Icons.search, color: AppColors.grey, size: Responsive.icon(context, size: 18)),
          suffixIcon: controller.text.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.close, color: AppColors.grey, size: Responsive.icon(context, size: 18)),
                  onPressed: onClear,
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }
}
