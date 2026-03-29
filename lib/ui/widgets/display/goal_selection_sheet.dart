import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lockedin_frontend/provider/streak_provider.dart';
import 'package:lockedin_frontend/ui/theme/app_theme.dart';

class GoalSelectionSheet extends StatefulWidget {
  const GoalSelectionSheet({super.key});

  @override
  State<GoalSelectionSheet> createState() => _GoalSelectionSheetState();
}

class _GoalSelectionSheetState extends State<GoalSelectionSheet> {
  int? _selectedMinutes;

  final List<Map<String, dynamic>> _goals = [
    {'minutes': 10, 'label': '10 minutes', 'desc': 'Just getting started'},
    {'minutes': 15, 'label': '15 minutes', 'desc': 'Building momentum'},
    {'minutes': 20, 'label': '20 minutes', 'desc': 'Staying committed'},
  ];

  @override
  void initState() {
    super.initState();
    // Pre-select the current goal if one is already set
    final streak = context.read<StreakProvider>();
    if (streak.dailyGoalSeconds > 0) {
      final currentMinutes = streak.dailyGoalSeconds ~/ 60;
      // Match to one of the preset options
      final match = _goals.any((g) => g['minutes'] == currentMinutes);
      if (match) {
        _selectedMinutes = currentMinutes;
      }
    }
  }

  Future<void> _onSetGoal() async {
    if (_selectedMinutes == null) return;
    final streak = context.read<StreakProvider>();
    final success = await streak.setDailyGoal(minutes: _selectedMinutes!);
    if (!mounted) return;
    if (success) {
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(streak.errorMessage ?? 'Failed to set goal'),
          backgroundColor: AppColors.secondary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final streak = context.watch<StreakProvider>();

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(24, 20, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: AppColors.grey.withOpacity(0.4), borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 20),

          // Icon
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppColors.accent, borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.local_fire_department_rounded, color: AppColors.primary, size: 26),
          ),
          const SizedBox(height: 16),

          // Title
          const Text(
            'Set your daily study goal',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textPrimary, fontFamily: 'Quicksand'),
          ),
          const SizedBox(height: 6),
          const Text(
            'Choose how long you plan to study each day to keep your streak going.',
            style: TextStyle(fontSize: 13, color: AppColors.grey, height: 1.4, fontFamily: 'Quicksand'),
          ),
          const SizedBox(height: 20),

          // Goal options
          ..._goals.map((g) => _buildGoalCard(g['minutes'] as int, g['label'] as String, g['desc'] as String)),

          const SizedBox(height: 16),

          // Set Goal button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: (_selectedMinutes == null || streak.isLoading) ? null : _onSetGoal,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                disabledBackgroundColor: AppColors.grey.withOpacity(0.3),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: streak.isLoading
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text(
                      'Set Goal',
                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700, fontFamily: 'Quicksand'),
                    ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildGoalCard(int minutes, String label, String desc) {
    final isSelected = _selectedMinutes == minutes;
    return GestureDetector(
      onTap: () => setState(() => _selectedMinutes = minutes),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.accent : AppColors.backgroundBox,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? AppColors.primary : Colors.transparent, width: 2),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(color: isSelected ? AppColors.primary : AppColors.grey.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
              alignment: Alignment.center,
              child: Text(
                minutes >= 60 ? '1h' : '${minutes}m',
                style: TextStyle(color: isSelected ? Colors.white : AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 14, fontFamily: 'Quicksand'),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.textPrimary, fontFamily: 'Quicksand'),
                  ),
                  Text(
                    desc,
                    style: const TextStyle(fontSize: 12, color: AppColors.grey, fontFamily: 'Quicksand'),
                  ),
                ],
              ),
            ),
            if (isSelected) const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 20),
          ],
        ),
      ),
    );
  }
}
