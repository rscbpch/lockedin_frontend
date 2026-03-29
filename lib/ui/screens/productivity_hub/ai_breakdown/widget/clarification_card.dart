import 'package:flutter/material.dart';
import 'package:lockedin_frontend/ui/responsive/responsive.dart';
import 'package:lockedin_frontend/ui/theme/app_theme.dart';

class ClarificationCard extends StatelessWidget {
  final String? question;

  const ClarificationCard({super.key, this.question});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFBBF24).withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFBBF24).withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.help_outline, color: Color(0xFFF59E0B), size: 16),
              SizedBox(width: 6),
              Text(
                'Clarification Needed',
                style: TextStyle(
                  color: Color(0xFFF59E0B),
                  fontFamily: 'Nunito',
                  fontSize: Responsive.text(context, size: 16),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            question ?? 'Could you provide more details?',
            style:TextStyle(
              color: AppColors.textSecondary,
              fontFamily: 'Nunito',
              fontSize: Responsive.text(context, size: 14),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}