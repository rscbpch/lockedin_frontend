import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';

class ErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const ErrorBanner({super.key, required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, color: AppColors.primary, size: 36),
          const SizedBox(height: 10),
          Text(
            message,
            style: TextStyle(color: AppColors.grey, fontSize: 14),
            textAlign: TextAlign.center,
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 14),
            OutlinedButton(
              onPressed: onRetry,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.accent,
                side: BorderSide(color: AppColors.accent),
              ),
              child: const Text('Retry'),
            ),
          ],
        ],
      ),
    );
  }
}