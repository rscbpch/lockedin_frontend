import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:lockedin_frontend/ui/theme/app_theme.dart';
import 'package:lockedin_frontend/ui/widgets/display/navbar.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class ProductivityHubScreen extends StatefulWidget {
  const ProductivityHubScreen({super.key});

  @override
  State<ProductivityHubScreen> createState() => _ProductivityHubScreenState();
}

class _ProductivityHubScreenState extends State<ProductivityHubScreen> {
  int _currentIndex = 2;

  void _onTap(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'LockedIn',
          style: TextStyle(
            color: AppColors.textPrimary,
            // fontFamily: 'Quicksand',
            fontFamily: 'Nunito',
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: Icon(PhosphorIconsBold.bell, size: 24, color: AppColors.textPrimary),
            onPressed: () {},
          ),
          IconButton(
            icon: Icon(PhosphorIconsBold.chatsCircle, size: 24, color: AppColors.textPrimary),
            onPressed: () {},
          ),
        ],
        backgroundColor: AppColors.background,
      ),
      body: CustomScrollView(
        physics: const NeverScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverMasonryGrid.count(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childCount: 4,
              itemBuilder: (context, index) {
                final items = [
                  FeatureCard(color: Color(0xFFFFDBDB), label: 'Pomodoro', imagePath: 'assets/images/pomodoro.png'),
                  FeatureCard(color: Color(0xFFAEDEFC), label: 'To-do List', imagePath: 'assets/images/todo-list.png'),
                  FeatureCard(color: Color(0xFFFFE893), label: 'Flashcards', imagePath: 'assets/images/flashcard.png'),
                  FeatureCard(color: Color(0xFFC8E6C9), label: 'Task Breakdown', imagePath: 'assets/images/task-breakdown.png'),
                ];
                return items[index];
              },
            ),
          ),

          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, 20, 16, 12),
              child: Text(
                'Productivity Stats',
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ),
          
          SliverFillRemaining(
            hasScrollBody: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              child: const ProductivityStatsCard(),
            ),
          ),

          const SliverToBoxAdapter(
            child: SizedBox(height: 24),
          ),
        ],
      ),
      bottomNavigationBar: Navbar(currentIndex: _currentIndex, onTap: _onTap),
    );
  }
}

class FeatureCard extends StatelessWidget {
  final Color color;
  final String label;
  final String imagePath;

  const FeatureCard({super.key, required this.color, required this.label, required this.imagePath});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      child: Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.asset(imagePath, height: 64),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.left,
            ),
          ],
        ),
      ),
    );
  }
}

class ProductivityStatsCard extends StatelessWidget {
  const ProductivityStatsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.textPrimary, width: 1.7),
      ),
      child: Column(
        children: [
          Image.asset(
            'assets/images/streak.png',
            height: 140,
          ),
          const SizedBox(height: 4),
          const Text(
            '67',
            style: TextStyle(
              fontSize: 36,
              fontFamily: 'Nunito',
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary
            ),
          ),
          const Text(
            'Current streak',
            style: TextStyle(
              fontFamily: 'Nunito',
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary
            ),
          ),
          const SizedBox(height: 16),
          Row(
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
    return Column(
      children: [
        CircleAvatar(
          radius: 14,
          backgroundColor: active ? AppColors.primary : AppColors.grey,
          child: const Icon(Icons.check, size: 16, color: Colors.white)
        ),
        const SizedBox(height: 4),
        Text(
          label, 
          style: const TextStyle(
            fontSize: 12, 
            fontFamily: 'Quicksand', 
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary
          )
        ),
      ],
    );
  }
}