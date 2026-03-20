import 'package:flutter/material.dart';
import 'package:lockedin_frontend/ui/responsive/responsive.dart';
import '../../../../../models/productivity_tools/task_breakdown/breakdown_step.dart';
import '../../../../theme/app_theme.dart';

class PlannedResponseCard extends StatelessWidget {
  final List<BreakdownStep> steps;

  const PlannedResponseCard({super.key, required this.steps});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.secondary.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 14),
          ...steps.map((s) => _StepItem(step: s)),
        ],
      ),
    );
  }
}

class _StepItem extends StatelessWidget {
  final BreakdownStep step;

  const _StepItem({required this.step});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                '${step.step}',
                style: TextStyle(
                  color: Colors.white,
                  fontFamily: 'Nunito',
                  fontSize: Responsive.text(context, size: 16),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  step.title,
                  style: TextStyle(
                    color: Color(0xFF1E293B),
                    fontFamily: 'Nunito',
                    fontSize: Responsive.text(context, size: 16),
                    fontWeight: FontWeight.w700,
                    height: 1.3
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  step.description,
                  style: TextStyle(
                    color: Color(0xFF64748B),
                    fontFamily: 'Quicksand',
                    fontSize: Responsive.text(context, size: 14),
                    fontWeight: FontWeight.w400,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}