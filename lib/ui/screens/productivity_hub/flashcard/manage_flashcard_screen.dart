import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lockedin_frontend/services/flashcard_service.dart';
import 'package:lockedin_frontend/ui/theme/app_theme.dart';
import 'package:lockedin_frontend/ui/widgets/actions/long_button.dart';
import 'package:lockedin_frontend/ui/widgets/inputs/text_field.dart';
import 'package:lockedin_frontend/ui/widgets/display/simple_back_sliver_app_bar.dart';
import 'package:lockedin_frontend/utils/activity_tracker.dart';

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

class ManageFlashcardScreen extends StatefulWidget {
  final String? editSetId;
  const ManageFlashcardScreen({super.key, this.editSetId});

  @override
  State<ManageFlashcardScreen> createState() => _CreateFlashcardScreenState();
}

class _CreateFlashcardScreenState extends State<ManageFlashcardScreen> with ActivityTracker {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  List<CardEntry> _cards = [CardEntry()];

  bool _saving = false;
  String? _saveError;

  // ── edit mode state ──
  String? _editSetId;
  bool get _isEditing => _editSetId != null;
  List<String?> _originalCardIds = [];
  List<String> _deletedCardIds = [];
  bool _formLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.editSetId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadForEdit(widget.editSetId!);
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    for (final c in _cards) {
      c.dispose();
    }
    super.dispose();
  }

  void _addCard() {
    setState(() {
      _cards.add(CardEntry());
      _originalCardIds.add(null);
    });
  }

  void _removeCard(int index) {
    if (_cards.length > 1) {
      if (index < _originalCardIds.length && _originalCardIds[index] != null) {
        _deletedCardIds.add(_originalCardIds[index]!);
        _originalCardIds.removeAt(index);
      } else if (index < _originalCardIds.length) {
        _originalCardIds.removeAt(index);
      }
      _cards[index].dispose();
      setState(() {
        _cards.removeAt(index);
      });
    }
  }

  Future<void> _loadForEdit(String id) async {
    setState(() {
      _formLoading = true;
      _saving = false;
      _saveError = null;
      _editSetId = id;
      _deletedCardIds = [];
    });

    try {
      final set = await FlashcardService.getFlashcardSet(id);
      if (!mounted) return;

      _titleController.text = set.title;

      for (final c in _cards) {
        c.dispose();
      }

      final newCards = set.cards.map((c) {
        final entry = CardEntry();
        entry.questionController.text = c.front;
        entry.definitionController.text = c.back;
        return entry;
      }).toList();

      setState(() {
        _cards = newCards.isEmpty ? [CardEntry()] : newCards;
        _originalCardIds = newCards.isEmpty ? <String?>[null] : set.cards.map<String?>((c) => c.id).toList();
        _formLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saveError = e.toString();
        _formLoading = false;
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _saving = true;
      _saveError = null;
    });

    final title = _titleController.text.trim();
    Map<String, dynamic> result;

    if (_isEditing) {
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

    if (!mounted) return;

    if (result['success'] == true) {
      if (!mounted) return;
      context.go('/flashcard');
    } else {
      setState(() {
        _saving = false;
        _saveError = result['message'] ?? 'Failed to save flashcard set.';
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_saveError ?? 'Failed to save flashcard set.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: _formLoading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                SimpleBackSliverAppBar(
                  title: _isEditing ? 'Edit Flashcard Set' : 'Create Flashcard Set',
                  onBack: () => context.go('/flashcard'),
                  action: _saving
                      ? const SizedBox(
                          width: 48,
                          height: 48,
                          child: Center(
                            child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.textPrimary)),
                          ),
                        )
                      : IconButton(
                          icon: const Icon(Icons.check, color: AppColors.textPrimary),
                          onPressed: _save,
                        ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      const SizedBox(height: 8),
                      Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            AppTextField(
                              label: 'Title',
                              hint: 'Enter title',
                              controller: _titleController,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) return 'Title is required';
                                return null;
                              },
                            ),
                            const SizedBox(height: 20),
                            ..._cards.asMap().entries.map(
                              (entry) => Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: _FlashcardEntryCard(entry: entry.value, index: entry.key + 1, onRemove: _cards.length > 1 ? () => _removeCard(entry.key) : null),
                              ),
                            ),
                            LongButton(text: 'Add card', isOutlined: true, onPressed: _addCard),
                            const SizedBox(height: 32),
                          ],
                        ),
                      ),
                    ]),
                  ),
                ),
              ],
            ),
    );
  }
}

class _FlashcardEntryCard extends StatelessWidget {
  final CardEntry entry;
  final int index;
  final VoidCallback? onRemove;
  const _FlashcardEntryCard({required this.entry, required this.index, this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(color: AppColors.backgroundBox, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Card $index',
                style: const TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w500, fontSize: 18, color: AppColors.textPrimary),
              ),
              if (onRemove != null)
                GestureDetector(
                  onTap: onRemove,
                  child: const Icon(Icons.close, color: AppColors.textPrimary, size: 20),
                ),
            ],
          ),
          const SizedBox(height: 20),
          AppTextField(
            controller: entry.questionController,
            label: 'Question',
            hint: 'Enter question',
            filled: true,
            fillColor: AppColors.background,
            validator: (value) {
              if (value == null || value.trim().isEmpty) return 'Question is required';
              return null;
            },
          ),
          const SizedBox(height: 16),
          AppTextField(
            controller: entry.definitionController,
            label: 'Answer',
            hint: 'Enter answer',
            filled: true,
            fillColor: AppColors.background,
            validator: (value) {
              if (value == null || value.trim().isEmpty) return 'Answer is required';
              return null;
            },
          ),
        ],
      ),
    );
  }
}
