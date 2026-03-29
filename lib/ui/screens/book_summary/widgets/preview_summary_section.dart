import 'package:flutter/material.dart';
import 'package:lockedin_frontend/ui/responsive/responsive.dart';
import 'package:lockedin_frontend/ui/theme/app_theme.dart';

class PreviewSummarySection extends StatelessWidget {
  final String title;
  final String summary;
  final bool isExpanded;
  final VoidCallback onToggleExpanded;

  const PreviewSummarySection({super.key, required this.title, required this.summary, required this.isExpanded, required this.onToggleExpanded});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Summary of $title',
          style: TextStyle(
            fontFamily: 'Nunito',
            fontSize: Responsive.text(context, size: 18),
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
            height: 1.2
          ),
        ),
        const SizedBox(height: 10),
        Text(
          summary,
          maxLines: isExpanded ? null : 4,
          overflow: isExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
          style: TextStyle(
            fontFamily: 'Quicksand',
            fontSize: Responsive.text(context, size: 16),
            color: AppColors.textPrimary
          ),
        ),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: onToggleExpanded,
          child: Row(
            children: [
              Text(
                isExpanded ? 'Show less' : 'Read more',
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: Responsive.text(context, size: 16),
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary
                ),
              ),
              const SizedBox(width: 2),
              Icon(
                isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                size: 18,
                color: AppColors.textPrimary
              ),
            ],
          ),
        ),
      ],
    );
  }
}
