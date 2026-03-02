import 'dart:math';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lockedin_frontend/services/flashcard_service.dart';
import 'package:lockedin_frontend/ui/responsive/responsive.dart';
import 'package:lockedin_frontend/ui/theme/app_theme.dart';
import 'package:lockedin_frontend/ui/screens/productivity_hub/flashcard/widgets/flip_card.dart';

class FlashcardTestScreen extends StatefulWidget {
  final String setId;
  const FlashcardTestScreen({super.key, required this.setId});

  @override
  State<FlashcardTestScreen> createState() => _FlashcardTestScreenState();
}

class _FlashcardTestScreenState extends State<FlashcardTestScreen> {
  FlashcardSet? _set;
  bool _loading = true;
  String? _error;

  int _currentIndex = 0;
  int _correctCount = 0;
  int _wrongCount = 0;
  List<bool> _results = [];

  // swipe animation
  double _dragX = 0;
  double _dragY = 0;

  @override
  void initState() {
    super.initState();
    _loadSet();
  }

  Future<void> _loadSet() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final set = await FlashcardService.getFlashcardSet(widget.setId);
      if (!mounted) return;
      setState(() {
        _set = set;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      _dragX += details.delta.dx;
      _dragY += details.delta.dy;
    });
  }

  void _onPanEnd(DragEndDetails details) {
    final screenWidth = MediaQuery.of(context).size.width;
    final threshold = screenWidth * 0.3;

    if (_dragX.abs() > threshold) {
      final isCorrect = _dragX > 0;
      _recordAnswer(isCorrect);
    } else {
      setState(() {
        _dragX = 0;
        _dragY = 0;
      });
    }
  }

  void _recordAnswer(bool isCorrect) {
    if (isCorrect) {
      _correctCount++;
    } else {
      _wrongCount++;
    }
    _results.add(isCorrect);

    final cards = _set!.cards;

    if (_currentIndex < cards.length - 1) {
      setState(() {
        _currentIndex++;
        _dragX = 0;
        _dragY = 0;
      });
    } else {
      _finishTest();
    }
  }

  Future<void> _finishTest() async {
    final totalCards = _set!.cards.length;

    FlashcardService.saveTestResult(setId: widget.setId, correctCount: _correctCount, wrongCount: _wrongCount, totalCards: totalCards);

    if (!mounted) return;
    context.go(
      '/flashcard/${widget.setId}/test/result',
      extra: {'correctCount': _correctCount, 'wrongCount': _wrongCount, 'totalCards': totalCards, 'setId': widget.setId, 'cards': _set!.cards, 'results': _results},
    );
  }

  void _resetTest() {
    setState(() {
      _currentIndex = 0;
      _correctCount = 0;
      _wrongCount = 0;
      _results = [];
      _dragX = 0;
      _dragY = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final cards = _set?.cards ?? [];
    final total = cards.length;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
            ? Center(
                child: Text(_error!, style: const TextStyle(color: AppColors.textPrimary)),
              )
            : cards.isEmpty
            ? const Center(
                child: Text('No cards to test', style: TextStyle(color: AppColors.textPrimary)),
              )
            : Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    const SizedBox(height: 16),
                    Text(
                      '${_currentIndex + 1}/$total',
                      style: TextStyle(fontFamily: 'Nunito', fontSize: Responsive.text(context, size: 24), fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _CounterBadge(count: _wrongCount, color: Colors.red),
                        _CounterBadge(count: _correctCount, color: Colors.green),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: GestureDetector(
                        onPanUpdate: _onPanUpdate,
                        onPanEnd: _onPanEnd,
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 250),
                          child: Transform.translate(
                            key: ValueKey(_currentIndex),
                            offset: Offset(_dragX, _dragY * 0.3),
                            child: Transform.rotate(
                              angle: _dragX / (width * 2) * (pi / 6),
                              child: Stack(
                                children: [
                                  FlipCard(key: ValueKey('card_$_currentIndex'), frontText: cards[_currentIndex].front, backText: cards[_currentIndex].back),
                                  if (_dragX < -20)
                                    Positioned.fill(
                                      child: Container(
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(20),
                                          color: Colors.red.withValues(alpha: (_dragX.abs() / (width * 0.4)).clamp(0, 0.3)),
                                        ),
                                      ),
                                    ),
                                  if (_dragX > 20)
                                    Positioned.fill(
                                      child: Container(
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(20),
                                          color: Colors.green.withValues(alpha: (_dragX.abs() / (width * 0.4)).clamp(0, 0.3)),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          onPressed: _resetTest,
                          icon: Icon(Icons.refresh, size: 28, color: AppColors.textPrimary),
                        ),
                        IconButton(
                          onPressed: () => context.go('/flashcard/${widget.setId}'),
                          icon: Icon(Icons.chevron_right, size: 28, color: AppColors.textPrimary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
      ),
    );
  }
}

class _CounterBadge extends StatelessWidget {
  final int count;
  final Color color;
  const _CounterBadge({required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color, width: 1.5),
      ),
      child: Text(
        '$count',
        style: TextStyle(fontFamily: 'Nunito', fontSize: Responsive.text(context, size: 16), fontWeight: FontWeight.w600, color: AppColors.textPrimary),
      ),
    );
  }
}
