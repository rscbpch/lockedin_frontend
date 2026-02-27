import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:lockedin_frontend/provider/flashcard_provider.dart';
import 'package:lockedin_frontend/ui/responsive/responsive.dart';
import 'package:lockedin_frontend/ui/theme/app_theme.dart';
import 'package:lockedin_frontend/ui/widgets/actions/long_button.dart';
import 'package:lockedin_frontend/ui/widgets/inputs/text_field.dart';

class CreateFlashcardScreen extends StatefulWidget {
  const CreateFlashcardScreen({super.key});

  @override
  State<CreateFlashcardScreen> createState() => _CreateFlashcardScreenState();
}

class _CreateFlashcardScreenState extends State<CreateFlashcardScreen> {
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<FlashcardProvider>().resetCreateForm());
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<FlashcardProvider>();
    final success = await provider.saveFlashcardSet();

    if (!mounted) return;
    if (success) {
      context.go('/flashcard');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(provider.saveError ?? 'Failed to create flashcard set.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final provider = context.watch<FlashcardProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Create Flashcard Set',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontFamily: 'Nunito',
            fontSize: Responsive.text(context, size: 22),
            fontWeight: FontWeight.w500,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          onPressed: () => context.go('/flashcard'),
          icon: Icon(Icons.arrow_back_ios, size: width * 0.06, color: AppColors.textPrimary),
        ),
        actions: [
          provider.saving
              ? const Padding(
                  padding: EdgeInsets.only(right: 16),
                  child: Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.textPrimary),
                    ),
                  ),
                )
              : IconButton(
                  icon: const Icon(Icons.check, color: AppColors.textPrimary),
                  onPressed: _save,
                ),
        ],
        backgroundColor: AppColors.background,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          children: [
            AppTextField(
              label: 'Title',
              hint: 'Enter title',
              controller: provider.titleController,
              validator: (value) {
                if (value == null || value.trim().isEmpty) return 'Title is required';
                return null;
              },
            ),
            const SizedBox(height: 20),
            ...provider.cards.asMap().entries.map((entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _FlashcardEntryCard(
                    entry: entry.value,
                    index: entry.key + 1,
                    onRemove: provider.cards.length > 1
                        ? () => provider.removeCard(entry.key)
                        : null,
                  ),
                )),
            LongButton(
              text: 'Add card',
              isOutlined: true,
              onPressed: provider.addCard,
            ),
            const SizedBox(height: 32),
          ],
        ),
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
      decoration: BoxDecoration(
        color: AppColors.accent,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
            fillColor: AppColors.backgroundBox,
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
            fillColor: AppColors.backgroundBox,
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
