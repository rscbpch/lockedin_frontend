import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:lockedin_frontend/provider/flashcard_provider.dart';
import 'package:lockedin_frontend/ui/responsive/responsive.dart';
import 'package:lockedin_frontend/ui/theme/app_theme.dart';
import 'package:lockedin_frontend/ui/widgets/actions/square_button.dart';

class FlashcardScreen extends StatefulWidget {
  const FlashcardScreen({super.key});

  @override
  State<FlashcardScreen> createState() => _FlashcardState();
}

class _FlashcardState extends State<FlashcardScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<FlashcardProvider>().loadSets());
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final provider = context.watch<FlashcardProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Flashcard',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontFamily: 'Nunito',
            fontSize: Responsive.text(context, size: 24),
            fontWeight: FontWeight.w500
          )
        ),
        centerTitle: true,
        leading: IconButton(
          onPressed: () => context.go('/productivity-hub'),
          icon: Icon(Icons.arrow_back_ios, size: width * 0.06, color: AppColors.textPrimary)
        ),
        backgroundColor: AppColors.background,
        elevation: 0,
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 16, right: 8),
        child: SquareButton(
          icon: Icons.add,
          onPressed: () => context.go('/flashcard/create'),
        ),
      ),
      body: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              if (provider.loading)
                Expanded(child: Center(child: CircularProgressIndicator()))
              else if (provider.error != null)
                Expanded(child: Center(child: Text(provider.error ?? 'An error occurred', style: TextStyle(color: AppColors.textPrimary))))
              else if (provider.sets.isEmpty)
                Expanded(child: Center(child: Text('No flashcard sets found', style: TextStyle(color: AppColors.textPrimary))))
              else
                Expanded(
                  child: ListView.separated(
                    itemCount: provider.sets.length,
                    separatorBuilder: (_, _) => SizedBox(height: 12),
                    itemBuilder: (context, i) {
                      final s = provider.sets[i];
                      return FlashcardTiles(flashcardId: s.id, flashcardTitle: s.title, cardsNumber: s.cardCount);
                    },
                  ),
                ),
            ],
          ),
        )
      ),
    );
  }
}

class FlashcardTiles extends StatelessWidget {
  final String flashcardId;
  final String flashcardTitle;
  final int cardsNumber;

  const FlashcardTiles({
    super.key,
    required this.flashcardId,
    required this.flashcardTitle,
    required this.cardsNumber,
  });

  @override
  Widget build(BuildContext context) {
    final cardText = cardsNumber == 1 ? 'card' : 'cards';

    return GestureDetector(
      onTap: () => context.go('/flashcard/$flashcardId'),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.backgroundBox,
          borderRadius: BorderRadius.circular(
            Responsive.radius(context, size: 12),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              flashcardTitle,
              style: TextStyle(
                fontSize: Responsive.text(context, size: 18),
                fontFamily: 'Nunito',
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '$cardsNumber $cardText',
              style: TextStyle(
                fontSize: Responsive.text(context, size: 12),
                fontFamily: 'Quicksand',
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