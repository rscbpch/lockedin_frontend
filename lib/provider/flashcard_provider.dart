import 'package:flutter/material.dart';
import '../services/flashcard_service.dart';

class CardEntry {
  final TextEditingController questionController = TextEditingController();
  final TextEditingController definitionController = TextEditingController();

  void dispose() {
    questionController.dispose();
    definitionController.dispose();
  }
}

class FlashcardProvider extends ChangeNotifier {
  List<FlashcardSet> _sets = [];
  List<FlashcardSet> get sets => _sets;

  bool _loading = false;
  bool get loading => _loading;

  String? _error;
  String? get error => _error;

  final TextEditingController titleController = TextEditingController();
  List<CardEntry> _cards = [CardEntry()];
  List<CardEntry> get cards => _cards;

  bool _saving = false;
  bool get saving => _saving;

  String? _saveError;
  String? get saveError => _saveError;

  Future<void> loadSets() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      _sets = await FlashcardService.getFlashcardSets();
    } catch (e) {
      _error = e.toString();
    }

    _loading = false;
    notifyListeners();
  }

  void addCard() {
    _cards.add(CardEntry());
    notifyListeners();
  }

  void removeCard(int index) {
    if (_cards.length > 1) {
      _cards[index].dispose();
      _cards.removeAt(index);
      notifyListeners();
    }
  }

  void resetCreateForm() {
    titleController.clear();
    for (final c in _cards) {
      c.dispose();
    }
    _cards = [CardEntry()];
    _saveError = null;
    _saving = false;
    notifyListeners();
  }

  Future<bool> saveFlashcardSet() async {
    _saving = true;
    _saveError = null;
    notifyListeners();

    final title = titleController.text.trim();
    final cardMaps = _cards
        .map((c) => {'front': c.questionController.text.trim(), 'back': c.definitionController.text.trim()})
        .where((c) => c['front']!.isNotEmpty || c['back']!.isNotEmpty)
        .toList();

    final result = await FlashcardService.createFlashcardSet(title: title, cards: cardMaps);

    _saving = false;

    if (result['success'] == true) {
      resetCreateForm();
      await loadSets();
      return true;
    } else {
      _saveError = result['message'] ?? 'Failed to create flashcard set.';
      notifyListeners();
      return false;
    }
  }

  @override
  void dispose() {
    titleController.dispose();
    for (final c in _cards) {
      c.dispose();
    }
    super.dispose();
  }
}
