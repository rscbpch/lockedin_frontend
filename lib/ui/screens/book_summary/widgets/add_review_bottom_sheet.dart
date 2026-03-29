import 'package:flutter/material.dart';
import 'package:lockedin_frontend/ui/responsive/responsive.dart';
import 'package:lockedin_frontend/ui/theme/app_theme.dart';
import 'package:lockedin_frontend/ui/widgets/actions/long_button.dart';

class AddReviewBottomSheet extends StatefulWidget {
  final Future<void> Function(int rating, String feedback) onSubmit;
  final String title;
  final String submitLabel;
  final int initialRating;
  final String initialFeedback;

  const AddReviewBottomSheet({super.key, required this.onSubmit, this.title = 'Add Review', this.submitLabel = 'Submit Review', this.initialRating = 0, this.initialFeedback = ''});

  @override
  State<AddReviewBottomSheet> createState() => _AddReviewBottomSheetState();
}

class _AddReviewBottomSheetState extends State<AddReviewBottomSheet> {
  late final TextEditingController _feedbackController;
  late int _selectedRating;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _selectedRating = widget.initialRating;
    _feedbackController = TextEditingController(text: widget.initialFeedback);
  }

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isSubmitting || _selectedRating == 0) {
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await widget.onSubmit(_selectedRating, _feedbackController.text.trim());
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(context).viewInsets.bottom + 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            widget.title,
            style: TextStyle(fontFamily: 'Nunito', fontSize: Responsive.text(context, size: 18), fontWeight: FontWeight.w600, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 16),
          Row(
            children: List.generate(5, (index) {
              return GestureDetector(
                onTap: () => setState(() => _selectedRating = index + 1),
                child: Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Icon(index < _selectedRating ? Icons.star : Icons.star_border, color: const Color(0xFFFFB800), size: 36),
                ),
              );
            }),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _feedbackController,
            maxLines: 4,
            style: TextStyle(fontFamily: 'Quicksand', fontSize: Responsive.text(context, size: 16), color: AppColors.textPrimary),
            decoration: InputDecoration(
              hintText: 'Share your thoughts about the book...',
              hintStyle: TextStyle(fontFamily: 'Quicksand', color: AppColors.grey, fontSize: Responsive.text(context, size: 16)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 20),
          LongButton(text: _isSubmitting ? 'Submitting...' : widget.submitLabel, onPressed: _isSubmitting || _selectedRating == 0 ? null : _submit),
        ],
      ),
    );
  }
}
