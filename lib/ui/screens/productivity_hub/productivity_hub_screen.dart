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
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(Responsive.radius(context, size: 12))),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.asset(imagePath, height: width * 0.16, fit: BoxFit.contain),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(fontFamily: 'Nunito', fontSize: Responsive.text(context, size: 16), fontWeight: FontWeight.w500, color: AppColors.textPrimary),
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
  bool _hasRefreshedOnCompletion = false;
  DateTime? _lastTrackedDate;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {});
        final streak = context.read<StreakProvider>();

        // Reset refresh flag each new calendar day
        final todayDate = DateTime.now();
        final todayDay = DateTime(todayDate.year, todayDate.month, todayDate.day);
        if (_lastTrackedDate != null && _lastTrackedDate != todayDay) {
          _hasRefreshedOnCompletion = false;
        }
        _lastTrackedDate = todayDay;

        // Only fetch once when goal is completed, not every second
        if (streak.hasCompletedTodayGoal && !streak.sessionActive && !_hasRefreshedOnCompletion) {
          _hasRefreshedOnCompletion = true;
          streak.fetchStreak(forceRefresh: true);
        }

      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }


  /// Returns day labels starting from Monday of the current week.
  List<String> get _dayLabels => const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  List<bool> _weekActivity(int currentStreak, bool todayGoalMet) {
    final now = DateTime.now();
    final todayIndex = now.weekday - 1; // 0-based (Mon=0 .. Sun=6)

    final activeDays = List.filled(7, false);

    final bool countToday = todayGoalMet && currentStreak > 0;

    int streakRemaining = currentStreak;
    int startDay = countToday ? todayIndex : todayIndex - 1;

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

    final totalToday = streak.todayTrackedSeconds;
    final todayGoalMet = streak.hasCompletedTodayGoal;
    final weekActive = _weekActivity(streak.currentStreak, todayGoalMet);
    final streakImagePath = todayGoalMet
        ? 'assets/images/streak.png'
        : 'assets/images/bw-streak.png';

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
          const SizedBox(height: 12),

          // Image with timer overlaid at the bottom
          Stack(
            alignment: Alignment.bottomCenter,
            clipBehavior: Clip.none,
            children: [
              Image.asset(streakImagePath, height: width * 0.22),

              // Timer pill — only shown when goal is NOT met
              if (!todayGoalMet)
                Positioned(
                  bottom: -(width * 0.035), // float it slightly below the image
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: streak.sessionActive
                            ? AppColors.primary.withOpacity(0.3)
                            : AppColors.grey.withOpacity(0.3),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: streak.sessionActive ? Colors.green : AppColors.grey,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          _formatSessionTime(totalToday),
                          style: TextStyle(
                            fontSize: Responsive.text(context, size: 13),
                            fontFamily: 'Nunito',
                            fontWeight: FontWeight.bold,
                            color: streak.sessionActive ? AppColors.primary : AppColors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),

          // Extra gap when timer pill is shown so it doesn't overlap the streak number
          SizedBox(height: todayGoalMet ? 2 : width * 0.045),

          Text(
            '${streak.currentStreak}',
            style: TextStyle(
              fontSize: Responsive.text(context, size: 32),
              fontFamily: 'Nunito',
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          
          Text(
            'Current streak',
            style: TextStyle(
              fontFamily: 'Nunito',
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
              fontSize: Responsive.text(context, size: 16)
            ),
          ),
          // const SizedBox(height: 8),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              'Longest streak: ${streak.longestStreak}',
              style: const TextStyle(fontFamily: 'Nunito'),
            ),
          ),
          const SizedBox(height: 10),

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
        ],
      ),
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
