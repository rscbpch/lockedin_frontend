import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lockedin_frontend/services/flashcard_service.dart';
import 'package:lockedin_frontend/ui/responsive/responsive.dart';
import 'package:lockedin_frontend/ui/theme/app_theme.dart';
import 'package:lockedin_frontend/ui/widgets/actions/long_button.dart';
import 'package:lockedin_frontend/ui/widgets/display/simple_back_sliver_app_bar.dart';
import 'package:lockedin_frontend/ui/screens/productivity_hub/flashcard/widgets/flip_card.dart';

class FlashcardViewScreen extends StatefulWidget {
  final String setId;
  const FlashcardViewScreen({super.key, required this.setId});

  @override
  State<FlashcardViewScreen> createState() => _FlashcardViewScreenState();
}

class _FlashcardViewScreenState extends State<FlashcardViewScreen> {
  FlashcardSet? _viewSet;
  bool _viewLoading = true;
  String? _viewError;
  int _currentCardIndex = 0;
  int _slideDirection = 1;

  @override
  void initState() {
    super.initState();
    _loadSet();
  }

  Future<void> _loadSet() async {
    setState(() {
      _viewLoading = true;
      _viewError = null;
      _viewSet = null;
      _currentCardIndex = 0;
    });

    try {
      final set = await FlashcardService.getFlashcardSet(widget.setId);
      if (!mounted) return;
      setState(() {
        _viewSet = set;
        _viewLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _viewError = e.toString();
        _viewLoading = false;
      });
    }
  }

  void _nextCard() {
    if (_viewSet != null && _currentCardIndex < _viewSet!.cards.length - 1) {
      setState(() {
        _slideDirection = 1;
        _currentCardIndex++;
      });
    }
  }

  void _previousCard() {
    if (_currentCardIndex > 0) {
      setState(() {
        _slideDirection = -1;
        _currentCardIndex--;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cards = _viewSet?.cards ?? [];
    final total = cards.length;
    final index = _currentCardIndex;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SimpleBackSliverAppBar(title: _viewSet?.title ?? '', onBack: () => context.go('/flashcard')),
          if (_viewLoading)
            const SliverFillRemaining(hasScrollBody: false, child: Center(child: CircularProgressIndicator()))
          else if (_viewError != null)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Text(_viewError!, style: const TextStyle(color: AppColors.textPrimary)),
              ),
            )
          else if (cards.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Text('No cards in this set', style: TextStyle(color: AppColors.textPrimary)),
              ),
            )
          else
            SliverFillRemaining(
              hasScrollBody: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    const SizedBox(height: 12),
                    Expanded(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        transitionBuilder: (child, animation) {
                          final offsetAnimation = Tween<Offset>(begin: Offset(_slideDirection.toDouble(), 0), end: Offset.zero).animate(animation);
                          return SlideTransition(position: offsetAnimation, child: child);
                        },
                        child: FlipCard(key: ValueKey(index), frontText: cards[index].front, backText: cards[index].back),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          onPressed: index > 0 ? _previousCard : null,
                          icon: Icon(Icons.chevron_left, color: index > 0 ? AppColors.textPrimary : AppColors.grey, size: 28),
                        ),
                        Text(
                          '${index + 1}/$total',
                          style: TextStyle(fontFamily: 'Nunito', fontSize: Responsive.text(context, size: 16), color: AppColors.textPrimary),
                        ),
                        IconButton(
                          onPressed: index < total - 1 ? _nextCard : null,
                          icon: Icon(Icons.chevron_right, color: index < total - 1 ? AppColors.textPrimary : AppColors.grey, size: 28),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    LongButton(text: 'Edit', isOutlined: true, onPressed: () => context.go('/flashcard/edit/${widget.setId}')),
                    const SizedBox(height: 12),
                    LongButton(text: 'Take a test', onPressed: () => context.go('/flashcard/${widget.setId}/test')),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
