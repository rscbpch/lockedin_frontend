import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:lockedin_frontend/ui/responsive/responsive.dart';
import 'package:lockedin_frontend/ui/theme/app_theme.dart';
import 'package:lockedin_frontend/ui/widgets/display/lockedin_appbar.dart';
import 'package:lockedin_frontend/ui/widgets/display/navbar.dart';

class ProductivityHubScreen extends StatefulWidget {
  const ProductivityHubScreen({super.key});

  @override
  State<ProductivityHubScreen> createState() => _ProductivityHubScreenState();
}

class _ProductivityHubScreenState extends State<ProductivityHubScreen> {
  int _currentIndex = 2;

  void _onTap(int index) {
    setState(() => _currentIndex = index);
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
                    FeatureCard(color: const Color(0xFFFFDBDB), label: 'Pomodoro', imagePath: 'assets/images/pomodoro.png'),
                    FeatureCard(color: const Color(0xFFAEDEFC), label: 'To-do List', imagePath: 'assets/images/todo-list.png'),
                    FeatureCard(color: const Color(0xFFFFE893), label: 'Flashcards', imagePath: 'assets/images/flashcard.png'),
                    FeatureCard(color: const Color(0xFFC8E6C9), label: 'Task Breakdown', imagePath: 'assets/images/task-breakdown.png'),
                  ];
                  return items[index];
                },
              ),
              // productivity stats
              Padding(
                padding: const EdgeInsets.only(top: 24, bottom: 12),
                child: Text(
                  'Productivity Stats',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: Responsive.text(context, size: 18),
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Expanded(
                child: ProductivityStatsCard(),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar:
          Navbar(currentIndex: _currentIndex, onTap: _onTap),
    );
  }
}

class FeatureCard extends StatelessWidget {
  final Color color;
  final String label;
  final String imagePath;

  const FeatureCard({
    super.key,
    required this.color,
    required this.label,
    required this.imagePath,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(Responsive.radius(context, size: 12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Image.asset(
            imagePath,
            height: width * 0.16,
            fit: BoxFit.contain,
          ),
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
    );
  }
}

class ProductivityStatsCard extends StatelessWidget {
  const ProductivityStatsCard({super.key});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

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
          Image.asset(
            'assets/images/streak.png',
            height: width * 0.40,
          ),
          const SizedBox(height: 2),
          Text(
            '67',
            style: TextStyle(
              fontSize: Responsive.text(context, size: 36),
              fontFamily: 'Nunito',
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const Text(
            'Current streak',
            style: TextStyle(
              fontFamily: 'Nunito',
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                DayCheck(label: 'Sun', active: true),
                DayCheck(label: 'Mon', active: true),
                DayCheck(label: 'Tue', active: true),
                DayCheck(label: 'Wed', active: true),
                DayCheck(label: 'Thu', active: false),
                DayCheck(label: 'Fri', active: false),
                DayCheck(label: 'Sat', active: false),
              ],
            ),
          )
        ],
      ),
    );
  }
}

class DayCheck extends StatelessWidget {
  final String label;
  final bool active;

  const DayCheck({
    super.key,
    required this.label,
    required this.active,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return Column(
      children: [
        CircleAvatar(
          radius: width * 0.04,
          backgroundColor: active ? AppColors.primary : AppColors.grey,
          child: Icon(
            Icons.check,
            size: width * 0.04,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: Responsive.text(context, size: 12),
            fontFamily: 'Quicksand',
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}