import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lockedin_frontend/ui/responsive/responsive.dart';
import 'package:lockedin_frontend/ui/theme/app_theme.dart';
import '../../../../services/flashcard_service.dart';

class FlashcardScreen extends StatefulWidget {
  const FlashcardScreen({super.key});

  @override
  State<FlashcardScreen> createState() => _FlashcardState();
}

class _FlashcardState extends State<FlashcardScreen> {
  List<FlashcardSet> _sets = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSets();
  }

  Future<void> _loadSets() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final sets = await FlashcardService.getFlashcardSets();
      setState(() {
        _sets = sets;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }
  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Flashcard',
          style: TextStyle(color:  AppColors.textPrimary, fontFamily: 'Nunito', fontSize: Responsive.text(context, size: 24), fontWeight: FontWeight.w500)
        ),
        centerTitle: true,
        leading: IconButton(
          onPressed: () => context.go('/productivity-hub'),
          icon: Icon(Icons.arrow_back_ios, size: width * 0.06, color: AppColors.textPrimary)
        ),
        backgroundColor: AppColors.background,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              if (_loading)
                Expanded(child: Center(child: CircularProgressIndicator()))
              else if (_error != null)
                Expanded(child: Center(child: Text(_error ?? 'An error occurred', style: TextStyle(color: AppColors.textPrimary))))
              else if (_sets.isEmpty)
                Expanded(child: Center(child: Text('No flashcard sets found', style: TextStyle(color: AppColors.textPrimary))))
              else
                Expanded(
                  child: ListView.separated(
                    itemCount: _sets.length,
                    separatorBuilder: (_, __) => SizedBox(height: 12),
                    itemBuilder: (context, i) {
                      final s = _sets[i];
                      return FlashcardTiles(flashcardTitle: s.title, cardsNumber: s.cardCount);
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
  final String flashcardTitle;
  final int cardsNumber;

  const FlashcardTiles({
    super.key,
    required this.flashcardTitle,
    required this.cardsNumber,
  });

  @override
  Widget build(BuildContext context) {
    final cardText = cardsNumber == 1 ? 'card' : 'cards';

    return GestureDetector(
      onTap: () {},
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