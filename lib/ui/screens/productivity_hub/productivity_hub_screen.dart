import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:go_router/go_router.dart';
import 'package:lockedin_frontend/provider/streak_provider.dart';
import 'package:lockedin_frontend/ui/responsive/responsive.dart';
import 'package:lockedin_frontend/ui/screens/onboarding/goal_selection_screen.dart';
import 'package:lockedin_frontend/ui/theme/app_theme.dart';
import 'package:lockedin_frontend/ui/widgets/display/lockedin_appbar.dart';
import 'package:provider/provider.dart';

class ProductivityHubScreen extends StatefulWidget {
  const ProductivityHubScreen({super.key});

  @override
  State<ProductivityHubScreen> createState() => _ProductivityHubScreenState();
}

class _ProductivityHubScreenState extends State<ProductivityHubScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final streak = context.read<StreakProvider>();
      await streak.fetchStreak();
      if (!mounted) return;
      if (!streak.hasSetGoal) {
        Navigator.of(context, rootNavigator: true).push(
          PageRouteBuilder(
            pageBuilder: (_, animation, __) => const GoalSelectionScreen(),
            transitionsBuilder: (_, animation, __, child) {
              return SlideTransition(
                position: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut)),
                child: child,
              );
            },
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const LockedInAppBar(),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // features grid
              MasonryGridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: Responsive.isMobile(context) ? 2 : 4,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                itemCount: 4,
                itemBuilder: (context, index) {
                  final items = [
                    FeatureCard(color: const Color(0xFFFFDBDB), label: 'Pomodoro', imagePath: 'assets/images/pomodoro.png', onTap: () => context.go('/pomodoro')),
                    FeatureCard(color: const Color(0xFFAEDEFC), label: 'To-do List', imagePath: 'assets/images/todo-list.png', onTap: () => context.go('/todo-list')),
                    FeatureCard(color: const Color(0xFFFFE893), label: 'Flashcards', imagePath: 'assets/images/flashcard.png', onTap: () => context.go('/flashcard')),
                    FeatureCard(color: const Color(0xFFC8E6C9), label: 'Task Breakdown', imagePath: 'assets/images/task-breakdown.png', onTap: () => context.go('/task-breakdown')),
                  ];
                  return items[index];
                },
              ),
              // productivity stats
              Padding(
                padding: const EdgeInsets.only(top: 24, bottom: 12),
                child: Text(
                  'Productivity Stats',
                  style: TextStyle(fontFamily: 'Nunito', fontSize: Responsive.text(context, size: 18), fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
              ),
              Expanded(child: ProductivityStreakCard()),
            ],
          ),
        ),
      ),
    );
  }
}

class FeatureCard extends StatelessWidget {
  final Color color;
  final String label;
  final String imagePath;
  final VoidCallback onTap;

  const FeatureCard({super.key, required this.color, required this.label, required this.imagePath, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(
            Responsive.radius(context, size: 12),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.asset(imagePath, height: width * 0.16, fit: BoxFit.contain),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: Responsive.text(context, size: 16),
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ProductivityStreakCard extends StatefulWidget {
  const ProductivityStreakCard({super.key});

  @override
  State<ProductivityStreakCard> createState() => _ProductivityStreakCardState();
}

class _ProductivityStreakCardState extends State<ProductivityStreakCard> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Tick every second to update the live session counter
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  /// Returns day labels starting from Monday of the current week.
  List<String> get _dayLabels => const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  /// Determines which days of the current week have met the goal,
  /// based on the currentStreak count going backwards from today.
  List<bool> _weekActivity(int currentStreak, bool todayGoalMet) {
    final now = DateTime.now();
    final todayIndex = now.weekday - 1; // 0-based (Mon=0 .. Sun=6)

    final activeDays = List.filled(7, false);

    // Ensure at least 1 so today gets marked when goal is met locally
    int streakRemaining = todayGoalMet ? (currentStreak < 1 ? 1 : currentStreak) : currentStreak;
    int startDay = todayGoalMet ? todayIndex : todayIndex - 1;

    for (int i = startDay; i >= 0 && streakRemaining > 0; i--) {
      activeDays[i] = true;
      streakRemaining--;
    }

    return activeDays;
  }

  String _formatSessionTime(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;
    if (h > 0) {
      return '${h}h ${m.toString().padLeft(2, '0')}m ${s.toString().padLeft(2, '0')}s';
    }
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final streak = context.watch<StreakProvider>();

    final goalSeconds = streak.dailyGoalSeconds;
    final accumulated = streak.todayAccumulatedSeconds;
    final liveSessionSeconds = streak.currentSessionSeconds;
    final totalToday = accumulated + liveSessionSeconds;
    final todayGoalMet = goalSeconds > 0 && totalToday >= goalSeconds;
    final weekActive = _weekActivity(streak.currentStreak, todayGoalMet);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.textPrimary, width: 1.7),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Image.asset('assets/images/streak.png', height: width * 0.22),
          const SizedBox(height: 2),
          Text(
            '${streak.currentStreak}',
            style: TextStyle(fontSize: Responsive.text(context, size: 32), fontFamily: 'Nunito', fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
          const Text(
            'Current streak',
            style: TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w500, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 6),

          // Goal complete or session timer
          if (todayGoalMet) ...[
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.green.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.check_circle, color: Colors.green, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    "Today's goal complete!",
                    style: TextStyle(fontSize: Responsive.text(context, size: 12), fontFamily: 'Nunito', fontWeight: FontWeight.bold, color: Colors.green),
                  ),
                ],
              ),
            ),
          ] else ...[
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: streak.sessionActive ? AppColors.primary.withOpacity(0.08) : AppColors.grey.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: streak.sessionActive ? AppColors.primary.withOpacity(0.3) : AppColors.grey.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(color: streak.sessionActive ? Colors.green : AppColors.grey, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _formatSessionTime(totalToday),
                    style: TextStyle(
                      fontSize: Responsive.text(context, size: 14),
                      fontFamily: 'Nunito',
                      fontWeight: FontWeight.bold,
                      color: streak.sessionActive ? AppColors.primary : AppColors.grey,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    streak.sessionActive ? 'Active' : 'Paused',
                    style: TextStyle(
                      fontSize: Responsive.text(context, size: 11),
                      fontFamily: 'Quicksand',
                      fontWeight: FontWeight.w600,
                      color: streak.sessionActive ? AppColors.primary : AppColors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 6),

          // Today's progress bar
          // if (goalSeconds > 0) ...[
          //   Padding(
          //     padding: const EdgeInsets.symmetric(horizontal: 24),
          //     child: Column(
          //       children: [
          //         Row(
          //           mainAxisAlignment: MainAxisAlignment.spaceBetween,
          //           children: [
          //             Text(
          //               'Today: ${_formatTime(totalToday)}',
          //               style: TextStyle(fontSize: Responsive.text(context, size: 12), fontFamily: 'Quicksand', fontWeight: FontWeight.w600, color: AppColors.textPrimary),
          //             ),
          //             Text(
          //               'Goal: ${_formatTime(goalSeconds)}',
          //               style: TextStyle(fontSize: Responsive.text(context, size: 12), fontFamily: 'Quicksand', fontWeight: FontWeight.w500, color: AppColors.grey),
          //             ),
          //           ],
          //         ),
          //         const SizedBox(height: 6),
          //         ClipRRect(
          //           borderRadius: BorderRadius.circular(6),
          //           child: LinearProgressIndicator(
          //             value: progress,
          //             minHeight: 8,
          //             backgroundColor: AppColors.grey.withOpacity(0.2),
          //             valueColor: AlwaysStoppedAnimation<Color>(todayGoalMet ? Colors.green : AppColors.primary),
          //           ),
          //         ),
          //       ],
          //     ),
          //   ),
          //   const SizedBox(height: 12),
          // ],

          // Weekly day checks
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(7, (i) {
                return DayCheck(label: _dayLabels[i], active: weekActive[i]);
              }),
            ),
          ),
          const SizedBox(height: 8),

          // Stats row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _StatChip(label: 'Longest', value: '${streak.longestStreak}'),
                _StatChip(label: 'Total days', value: '${streak.totalGoalDays}'),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;

  const _StatChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(fontSize: Responsive.text(context, size: 16), fontFamily: 'Nunito', fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        ),
        Text(
          label,
          style: TextStyle(fontSize: Responsive.text(context, size: 11), fontFamily: 'Quicksand', fontWeight: FontWeight.w500, color: AppColors.grey),
        ),
      ],
    );
  }
}

class DayCheck extends StatelessWidget {
  final String label;
  final bool active;

  const DayCheck({super.key, required this.label, required this.active});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return Column(
      children: [
        CircleAvatar(
          radius: width * 0.04,
          backgroundColor: active ? AppColors.primary : AppColors.grey,
          child: Icon(Icons.check, size: width * 0.04, color: Colors.white),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(fontSize: Responsive.text(context, size: 12), fontFamily: 'Quicksand', fontWeight: FontWeight.w500, color: AppColors.textPrimary),
        ),
      ],
    );
  }
}
