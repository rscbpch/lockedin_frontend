import 'package:flutter/material.dart';
import 'package:lockedin_frontend/ui/responsive/responsive.dart';
import 'package:lockedin_frontend/ui/theme/app_theme.dart';

/// A reusable sliver app bar with a back button, centered title,
/// and optional right-side action icon.
class SimpleBackSliverAppBar extends StatelessWidget {
  final String title;
  final Widget? action;
  final VoidCallback? onBack;

  const SimpleBackSliverAppBar({super.key, required this.title, this.action, this.onBack});

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      pinned: true,
      elevation: 0,
      backgroundColor: AppColors.background,
      surfaceTintColor: Colors.transparent,
      centerTitle: true,
      title: Text(
        title,
        style: TextStyle(
          fontFamily: 'Nunito',
          fontSize: Responsive.text(context, size: 20),
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary
        ),
      ),
      leading: IconButton(
        icon: const Icon(Icons.chevron_left, color: AppColors.textPrimary, size: 32),
        onPressed: onBack ?? () => Navigator.of(context).pop(),
      ),
      actions: action != null ? [action!] : null,
    );
  }
}
