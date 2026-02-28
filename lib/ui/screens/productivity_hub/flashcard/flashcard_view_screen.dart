import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lockedin_frontend/services/flashcard_service.dart';
import 'package:lockedin_frontend/ui/responsive/responsive.dart';
import 'package:lockedin_frontend/ui/theme/app_theme.dart';
import 'package:lockedin_frontend/ui/widgets/actions/long_button.dart';

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
  bool _showingFront = true;

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
      _showingFront = true;
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
        _currentCardIndex++;
        _showingFront = true;
      });
    }
  }

  void _previousCard() {
    if (_currentCardIndex > 0) {
      setState(() {
        _currentCardIndex--;
        _showingFront = true;
      });
    }
  }

  void _flipCard() {
    setState(() {
      _showingFront = !_showingFront;
    });
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final cards = _viewSet?.cards ?? [];
    final total = cards.length;
    final index = _currentCardIndex;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          _viewSet?.title ?? '',
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: AppColors.textPrimary, fontFamily: 'Nunito', fontSize: Responsive.text(context, size: 22), fontWeight: FontWeight.w500),
        ),
        centerTitle: true,
        leading: IconButton(
          onPressed: () => context.go('/flashcard'),
          icon: Icon(Icons.arrow_back_ios, size: width * 0.06, color: AppColors.textPrimary),
        ),
        backgroundColor: AppColors.background,
        elevation: 0,
      ),
      body: _viewLoading
          ? const Center(child: CircularProgressIndicator())
          : _viewError != null
          ? Center(
              child: Text(_viewError!, style: const TextStyle(color: AppColors.textPrimary)),
            )
          : cards.isEmpty
          ? const Center(
              child: Text('No cards in this set', style: TextStyle(color: AppColors.textPrimary)),
            )
          : Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const SizedBox(height: 24),
                  Expanded(
                    child: GestureDetector(
                      onTap: _flipCard,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(color: AppColors.accent, borderRadius: BorderRadius.circular(20)),
                        child: Center(
                          child: Text(
                            _showingFront ? cards[index].front : cards[index].back,
                            textAlign: TextAlign.center,
                            style: TextStyle(fontFamily: 'Nunito', fontSize: Responsive.text(context, size: 20), fontWeight: FontWeight.w500, color: AppColors.textPrimary),
                          ),
                        ),
                      ),
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
                  LongButton(text: 'Edit', isOutlined: true, onPressed: () => context.go('')),
                  const SizedBox(height: 12),
                  LongButton(text: 'Take a test', onPressed: () {}),
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }
}
