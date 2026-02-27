import 'package:flutter/material.dart';
import '../services/flashcard_service.dart';

class CardEntry {
  static int _nextId = 0;
  final int id;
  final TextEditingController questionController = TextEditingController();
  final TextEditingController definitionController = TextEditingController();

  CardEntry() : id = _nextId++;

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

  // ── edit mode state ──
  String? _editSetId;
  String? get editSetId => _editSetId;
  bool get isEditing => _editSetId != null;

  // track original card IDs for update/delete
  List<String?> _originalCardIds = [];
  List<String> _deletedCardIds = [];

  bool _formLoading = false;
  bool get formLoading => _formLoading;

  // ── view set state ──
  FlashcardSet? _viewSet;
  FlashcardSet? get viewSet => _viewSet;

  bool _viewLoading = false;
  bool get viewLoading => _viewLoading;

  String? _viewError;
  String? get viewError => _viewError;

  int _currentCardIndex = 0;
  int get currentCardIndex => _currentCardIndex;

  bool _showingFront = true;
  bool get showingFront => _showingFront;

  // ── load single set for viewing ──
  Future<void> loadFlashcardSet(String id) async {
    _viewLoading = true;
    _viewError = null;
    _viewSet = null;
    _currentCardIndex = 0;
    _showingFront = true;
    notifyListeners();

    try {
      _viewSet = await FlashcardService.getFlashcardSet(id);
    } catch (e) {
      _viewError = e.toString();
    }

    _viewLoading = false;
    notifyListeners();
  }

  void nextCard() {
    if (_viewSet != null && _currentCardIndex < _viewSet!.cards.length - 1) {
      _currentCardIndex++;
      _showingFront = true;
      notifyListeners();
    }
  }

  void previousCard() {
    if (_currentCardIndex > 0) {
      _currentCardIndex--;
      _showingFront = true;
      notifyListeners();
    }
  }

  void flipCard() {
    _showingFront = !_showingFront;
    notifyListeners();
  }

  // ── load all sets ──
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
    _originalCardIds.add(null);
    notifyListeners();
  }

  void removeCard(int index) {
    if (_cards.length > 1) {
      // track deleted card IDs for the update API
      if (index < _originalCardIds.length && _originalCardIds[index] != null) {
        _deletedCardIds.add(_originalCardIds[index]!);
        _originalCardIds.removeAt(index);
      } else if (index < _originalCardIds.length) {
        _originalCardIds.removeAt(index);
      }
      _cards[index].dispose();
      _cards.removeAt(index);
      notifyListeners();
    }
  }

  void resetCreateForm() {
    _editSetId = null;
    _originalCardIds = [];
    _deletedCardIds = [];
    _formLoading = false;
    titleController.clear();
    for (final c in _cards) {
      c.dispose();
    }
    _cards = [CardEntry()];
    _saveError = null;
    _saving = false;
    notifyListeners();
  }

  /// Load an existing set into the form for editing
  Future<void> loadForEdit(String id) async {
    _formLoading = true;
    _saving = false;
    _saveError = null;
    _editSetId = id;
    _deletedCardIds = [];
    notifyListeners();

    try {
      final set = await FlashcardService.getFlashcardSet(id);
      titleController.text = set.title;

      for (final c in _cards) {
        c.dispose();
      }

      _cards = set.cards.map((c) {
        final entry = CardEntry();
        entry.questionController.text = c.front;
        entry.definitionController.text = c.back;
        return entry;
      }).toList();

      _originalCardIds = set.cards.map((c) => c.id).toList();

      if (_cards.isEmpty) {
        _cards = [CardEntry()];
        _originalCardIds = [null];
      }
    } catch (e) {
      _saveError = e.toString();
    }

    _formLoading = false;
    notifyListeners();
  }

  Future<bool> saveFlashcardSet() async {
    _saving = true;
    _saveError = null;
    notifyListeners();

    final title = titleController.text.trim();

    Map<String, dynamic> result;

    if (isEditing) {
      // Build update/add card lists
      final updateCards = <Map<String, String>>[];
      final addCards = <Map<String, String>>[];

      for (var i = 0; i < _cards.length; i++) {
        final front = _cards[i].questionController.text.trim();
        final back = _cards[i].definitionController.text.trim();
        if (front.isEmpty && back.isEmpty) continue;

        final id = (i < _originalCardIds.length) ? _originalCardIds[i] : null;

        if (id != null && id.isNotEmpty) {
          updateCards.add({'_id': id, 'front': front, 'back': back});
        } else {
          addCards.add({'front': front, 'back': back});
        }
      }

      result = await FlashcardService.updateFlashcardSet(
        _editSetId!,
        title: title,
        addCards: addCards.isNotEmpty ? addCards : null,
        updateCards: updateCards.isNotEmpty ? updateCards : null,
        deleteCardIds: _deletedCardIds.isNotEmpty ? _deletedCardIds : null,
      );
    } else {
      final cardMaps = _cards
          .map((c) => {'front': c.questionController.text.trim(), 'back': c.definitionController.text.trim()})
          .where((c) => c['front']!.isNotEmpty || c['back']!.isNotEmpty)
          .toList();

      result = await FlashcardService.createFlashcardSet(title: title, cards: cardMaps);
    }

    _saving = false;

    if (result['success'] == true) {
      final wasEditing = isEditing;
      final editId = _editSetId;
      resetCreateForm();
      await loadSets();
      if (wasEditing && editId != null) {
        // refresh the view set as well
        await loadFlashcardSet(editId);
      }
      return true;
    } else {
      _saveError = result['message'] ?? 'Failed to save flashcard set.';
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
