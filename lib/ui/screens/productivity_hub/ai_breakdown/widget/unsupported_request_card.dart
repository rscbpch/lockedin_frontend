import 'package:flutter/material.dart';
import 'package:lockedin_frontend/ui/responsive/responsive.dart';
import 'package:lockedin_frontend/ui/theme/app_theme.dart';

class UnsupportedRequestCard extends StatelessWidget {
  const UnsupportedRequestCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEF4444).withOpacity(0.7)),
      ),
      child: Row(
        children: [
          Icon(Icons.block, color: Color(0xFFEF4444), size: 24),
          SizedBox(width: 16),
          Expanded(
            child: Text(
              'This request isn\'t related to task breakdown. Please describe a goal or task.',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontFamily: 'Nunito',
                fontSize: Responsive.text(context, size: 16),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}