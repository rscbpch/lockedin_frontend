import 'package:flutter/material.dart';
import 'package:lockedin_frontend/ui/responsive/responsive.dart';
import 'package:lockedin_frontend/ui/theme/app_theme.dart';

class StreakBadge extends StatelessWidget {
  final int? streakDays;

  const StreakBadge({super.key, this.streakDays});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFBF2C0),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        '🔥 ${streakDays ?? 0} ${(streakDays ?? 0) == 1 ? 'Day' : 'Days'} streak',
        style: TextStyle(
          fontSize: Responsive.text(context, size: 14),
          fontFamily: 'Quicksand',
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary
        ),
      ),
    );
  }
}
