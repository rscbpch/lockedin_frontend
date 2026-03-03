import 'package:flutter/material.dart';
import 'package:lockedin_frontend/ui/theme/app_theme.dart';

/// Temporary placeholder for tabs that are not yet implemented.
class PlaceholderScreen extends StatelessWidget {
  final String title;
  final IconData icon;

  const PlaceholderScreen({super.key, required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: AppColors.grey),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontFamily: 'Nunito', fontWeight: FontWeight.w600, color: AppColors.grey),
            ),
            const SizedBox(height: 4),
            const Text(
              'Coming soon',
              style: TextStyle(fontSize: 14, fontFamily: 'Quicksand', color: AppColors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
