import 'package:flutter/material.dart';
import 'package:lockedin_frontend/ui/theme/app_theme.dart';
import 'package:lockedin_frontend/ui/responsive/responsive.dart';

class CategoryChips extends StatelessWidget {
  final List<String> categories;
  final String? selectedCategory;
  final ValueChanged<String?> onSelected;

  const CategoryChips({super.key, required this.categories, required this.selectedCategory, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 32,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length + 1,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          if (index == 0) {
            return _chip(context, label: 'All', isSelected: selectedCategory == null);
          }
          final cat = categories[index - 1];
          return _chip(context, label: cat, isSelected: selectedCategory == cat);
        },
      ),
    );
  }

  Widget _chip(BuildContext context, {required String label, required bool isSelected}) {
    return GestureDetector(
      onTap: () => onSelected(isSelected && label == 'All' ? null : (label == 'All' ? null : label)),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.accent : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? AppColors.primary : AppColors.grey, width: 1),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: Responsive.text(context, size: 12),
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}
