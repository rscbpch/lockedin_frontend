import 'package:flutter/material.dart';
import '../services/flashcard_service.dart';

/// Slim provider – only manages the shared flashcard-set list.
/// View and form state live in local StatefulWidgets.
class FlashcardProvider extends ChangeNotifier {
  List<FlashcardSet> _sets = [];
  List<FlashcardSet> get sets => _sets;

  bool _loading = false;
  bool get loading => _loading;

  String? _error;
  String? get error => _error;

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
}
