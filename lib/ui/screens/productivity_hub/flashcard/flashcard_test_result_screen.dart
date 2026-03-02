import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lockedin_frontend/services/flashcard_service.dart';
import 'package:lockedin_frontend/ui/responsive/responsive.dart';
import 'package:lockedin_frontend/ui/theme/app_theme.dart';
import 'package:lockedin_frontend/ui/widgets/actions/long_button.dart';

class FlashcardTestResultScreen extends StatelessWidget {
  final int correctCount;
  final int wrongCount;
  final int totalCards;
  final String setId;
  final List<FlashcardCard> cards;
  final List<bool> results;

  const FlashcardTestResultScreen({
    super.key,
    required this.correctCount,
    required this.wrongCount,
    required this.totalCards,
    required this.setId,
    required this.cards,
    required this.results,
  });

  @override
  Widget build(BuildContext context) {
    final percentage =
        totalCards > 0 ? (correctCount / totalCards * 100).round() : 0;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Test Result',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontFamily: 'Nunito',
            fontSize: Responsive.text(context, size: 22),
            fontWeight: FontWeight.w500,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          onPressed: () => context.go('/flashcard/$setId'),
          icon: Icon(Icons.arrow_back_ios,
              size: MediaQuery.of(context).size.width * 0.06,
              color: AppColors.textPrimary),
        ),
        backgroundColor: AppColors.background,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        children: [
          const SizedBox(height: 16),
          Center(
            child: Image.asset(
              'assets/images/badge.png',
              width: 160,
              height: 160,
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              '$correctCount/$totalCards',
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: Responsive.text(context, size: 20),
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            )
          ),
          Center(
            child: Text(
              _message(percentage),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Quicksand',
                fontSize: Responsive.text(context, size: 20),
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          // score
          Center(
            child: Text(
              'You\'ve mastered',
              style: TextStyle(
                fontFamily: 'Quicksand',
                fontSize: Responsive.text(context, size: 14),
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Center(
            child: Text(
              '$percentage%',
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: Responsive.text(context, size: 28),
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: 16),
          // stats row
          // Row(
          //   mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          //   children: [
          //     _StatCard(
          //         label: 'Correct',
          //         value: '$correctCount',
          //         color: Colors.green),
          //     _StatCard(
          //         label: 'Wrong', value: '$wrongCount', color: Colors.red),
          //     _StatCard(
          //         label: 'Total',
          //         value: '$totalCards',
          //         color: AppColors.primary),
          //   ],
          // ),
          const SizedBox(height: 32),
          // card list
          ...List.generate(cards.length, (i) {
            final isCorrect = i < results.length ? results[i] : false;
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _ResultCard(
                index: i + 1,
                question: cards[i].front,
                definition: cards[i].back,
                isCorrect: isCorrect,
              ),
            );
          }),
          const SizedBox(height: 8),
          // actions
          LongButton(
            text: 'Retake Test',
            onPressed: () => context.go('/flashcard/$setId/test'),
          ),
          const SizedBox(height: 12),
          LongButton(
            text: 'Back to Flashcard',
            isOutlined: true,
            onPressed: () => context.go('/flashcard'),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  String _message(int pct) {
    if (pct == 100) return 'Perfect score!';
    if (pct >= 80) return 'Great work!';
    if (pct >= 50) return 'Good effort!';
    return 'Keep practicing!';
  }
}

class _ResultCard extends StatelessWidget {
  final int index;
  final String question;
  final String definition;
  final bool isCorrect;

  const _ResultCard({
    required this.index,
    required this.question,
    required this.definition,
    required this.isCorrect,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = isCorrect
        ? Colors.green.withValues(alpha: 0.15)
        : Colors.red.withValues(alpha: 0.15);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Card $index',
            style: const TextStyle(
              fontFamily: 'Nunito',
              fontWeight: FontWeight.w500,
              fontSize: 18,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.backgroundBox,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Question',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontWeight: FontWeight.w500,
                    fontSize: Responsive.text(context, size: 12),
                    color: AppColors.grey,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  question,
                  style: TextStyle(
                    fontFamily: 'Quicksand',
                    fontWeight: FontWeight.w500,
                    fontSize: Responsive.text(context, size: 14),
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.backgroundBox,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Answer',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontWeight: FontWeight.w500,
                    fontSize: Responsive.text(context, size: 12),
                    color: AppColors.grey,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  definition,
                  style: TextStyle(
                    fontFamily: 'Quicksand',
                    fontWeight: FontWeight.w500,
                    fontSize: Responsive.text(context, size: 14),
                    color: AppColors.textPrimary,
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

// class _StatCard extends StatelessWidget {
//   final String label;
//   final String value;
//   final Color color;
//   const _StatCard(
//       {required this.label, required this.value, required this.color});

//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       children: [
//         Container(
//           width: 64,
//           height: 64,
//           decoration: BoxDecoration(
//             borderRadius: BorderRadius.circular(16),
//             color: color.withValues(alpha: 0.1),
//           ),
//           child: Center(
//             child: Text(
//               value,
//               style: TextStyle(
//                 fontFamily: 'Nunito',
//                 fontSize: Responsive.text(context, size: 22),
//                 fontWeight: FontWeight.w700,
//                 color: color,
//               ),
//             ),
//           ),
//         ),
//         const SizedBox(height: 6),
//         Text(
//           label,
//           style: TextStyle(
//             fontFamily: 'Nunito',
//             fontSize: Responsive.text(context, size: 13),
//             fontWeight: FontWeight.w500,
//             color: AppColors.grey,
//           ),
//         ),
//       ],
//     );
//   }
// }
