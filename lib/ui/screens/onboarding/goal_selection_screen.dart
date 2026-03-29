import 'package:flutter/material.dart';
import 'package:lockedin_frontend/ui/widgets/notifications/app_alert_dialog.dart';
import 'package:provider/provider.dart';
import 'package:lockedin_frontend/provider/streak_provider.dart';
import 'package:lockedin_frontend/ui/theme/app_theme.dart';

class GoalSelectionScreen extends StatefulWidget {
  const GoalSelectionScreen({super.key});

  @override
  State<GoalSelectionScreen> createState() => _GoalSelectionScreenState();
}

class _GoalSelectionScreenState extends State<GoalSelectionScreen> {
  int? _selectedMinutes;
  bool _hasShownCooldownDialog = false;

  final List<Map<String, dynamic>> _goals = [
    {'minutes': 10, 'label': '10 minutes', 'desc': 'Just getting started'},
    {'minutes': 15, 'label': '15 minutes', 'desc': 'Building momentum'},
    {'minutes': 20, 'label': '20 minutes', 'desc': 'Staying committed'},
  ];

  @override
  void initState() {
    super.initState();
    _syncSelectedGoalFromProvider();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshGoalStatus();
    });
  }

  void _syncSelectedGoalFromProvider() {
    final streak = context.read<StreakProvider>();
    if (streak.dailyGoalSeconds > 0) {
      final currentMinutes = streak.dailyGoalSeconds ~/ 60;
      final match = _goals.any((g) => g['minutes'] == currentMinutes);
      if (match) {
        _selectedMinutes = currentMinutes;
      }
    }
  }

  Future<void> _refreshGoalStatus() async {
    final streak = context.read<StreakProvider>();
    await streak.fetchStreak(forceRefresh: true);
    if (!mounted) return;

    setState(() {
      _syncSelectedGoalFromProvider();
    });

    final isReturningUser = streak.hasSetGoal;
    final cooldownActive = !streak.canUpdateGoal && isReturningUser;
    if (cooldownActive && !_hasShownCooldownDialog) {
      _hasShownCooldownDialog = true;
      await _showCooldownDialog(streak.goalUpdateDaysRemaining);
    }
  }

  String _cooldownMessage(int daysRemaining) {
    return 'You can only change your goal once per week. Try again in $daysRemaining day${daysRemaining == 1 ? '' : 's'}.';
  }

  Future<void> _showCooldownDialog(int daysRemaining) {
    return showDialog<void>(
      context: context,
      builder: (ctx) {
        return AppAlertDialog(
          title: 'Goal update locked',
          message: _cooldownMessage(daysRemaining),
          confirmLabel: 'Close',
        );
      },
    );
  }

  Future<void> _onSetGoal() async {
    if (_selectedMinutes == null) return;
    final streak = context.read<StreakProvider>();

    final isReturningUser = streak.hasSetGoal;
    final cooldownActive = !streak.canUpdateGoal && isReturningUser;
    if (cooldownActive) {
      await _showCooldownDialog(streak.goalUpdateDaysRemaining);
      return;
    }

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
    final isFirstTimeUser = !streak.hasSetGoal;
    final cooldownActive = !streak.canUpdateGoal && !isFirstTimeUser;
    final canSubmit = _selectedMinutes != null && !streak.isLoading && !cooldownActive;

    return PopScope(
      canPop: !isFirstTimeUser,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 12),
                if (!isFirstTimeUser)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      onPressed: () => Navigator.of(context).maybePop(),
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary),
                    ),
                  )
                else
                  const SizedBox(height: 36),

                const SizedBox(height: 8),

                // Fire icon
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(color: AppColors.accent, borderRadius: BorderRadius.circular(20)),
                  child: const Icon(Icons.local_fire_department_rounded, color: AppColors.primary, size: 40),
                ),

                const SizedBox(height: 24),

                // Title
                const Text(
                  'Set your daily goal',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.textPrimary, fontFamily: 'Quicksand'),
                ),

                const SizedBox(height: 8),

                // Subtitle
                const Text(
                  'How long do you want to study each day?',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: AppColors.grey, fontFamily: 'Quicksand'),
                ),

                const SizedBox(height: 36),

                // Goal cards
                ..._goals.map((g) => _buildGoalCard(g['minutes'] as int, g['label'] as String, g['desc'] as String)),

                const Spacer(),

                // Set Goal button
                SizedBox(
                  width: double.infinity,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: cooldownActive ? () => _showCooldownDialog(streak.goalUpdateDaysRemaining) : null,
                    child: AbsorbPointer(
                      absorbing: cooldownActive,
                      child: ElevatedButton(
                        onPressed: canSubmit ? _onSetGoal : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          disabledBackgroundColor: AppColors.primary.withOpacity(0.35),
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                  ),
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.accent : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isSelected ? AppColors.primary : Colors.transparent, width: 2),
          boxShadow: [BoxShadow(color: AppColors.grey.withOpacity(0.1), blurRadius: 6, offset: const Offset(0, 2))],
        ),
        child: Row(
          children: [
            // Minutes badge
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(color: isSelected ? AppColors.primary.withOpacity(0.12) : AppColors.backgroundBox, borderRadius: BorderRadius.circular(12)),
              child: Center(
                child: Text(
                  '${minutes}m',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: isSelected ? AppColors.primary : AppColors.textPrimary, fontFamily: 'Quicksand'),
                ),
              ),
            ),
            const SizedBox(width: 14),
            // Labels
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.textPrimary, fontFamily: 'Quicksand'),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    desc,
                    style: const TextStyle(fontSize: 12, color: AppColors.grey, fontFamily: 'Quicksand'),
                  ),
                ],
              ),
            ),
            // Check icon
            AnimatedOpacity(
              opacity: isSelected ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 180),
              child: const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 22),
            ),
          ],
        ),
      ),
    );
  }
}
