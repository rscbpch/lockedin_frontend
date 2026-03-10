import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';

class CreateRoomSheet extends StatefulWidget {
  final Future<void> Function(String name) onSubmit;

  const CreateRoomSheet({super.key, required this.onSubmit});

  @override
  State<CreateRoomSheet> createState() => _CreateRoomSheetState();
}

class _CreateRoomSheetState extends State<CreateRoomSheet> {
  final _controller = TextEditingController();
  bool _loading = false;
  String? _error;

  Future<void> _submit() async {
    final name = _controller.text.trim();
    if (name.isEmpty) return setState(() => _error = 'Room name is required');
    setState(() { _loading = true; _error = null; });
    try {
      await widget.onSubmit(name);
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final insets = MediaQuery.of(context).viewInsets;

    return Container(
      padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + insets.bottom),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border(top: BorderSide(color: AppColors.primary.withOpacity(0.2))),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36, height: 4,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.5),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'NEW SESSION',
            style: TextStyle(
              color: AppColors.accent,
              fontSize: 10,
              letterSpacing: 2,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Create a Room',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Start a focused session — up to 10 participants.',
            style: TextStyle(color: AppColors.grey, fontSize: 13),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _controller,
            autofocus: true,
            maxLength: 60,
            onSubmitted: (_) => _submit(),
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 15),
            cursorColor: AppColors.accent,
            decoration: InputDecoration(
              hintText: 'e.g. Physics Study Group',
              hintStyle: TextStyle(color: AppColors.grey),
              errorText: _error,
              filled: true,
              fillColor: AppColors.backgroundBox,
              counterStyle: TextStyle(color: AppColors.grey, fontSize: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: AppColors.primary.withOpacity(0.2)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: AppColors.primary.withOpacity(0.2)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: AppColors.accent),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: AppColors.primary.withOpacity(0.2)),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _loading ? null : () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.grey,
                    side: BorderSide(color: AppColors.primary.withOpacity(0.2)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: _loading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: Colors.black,
                    disabledBackgroundColor: AppColors.accent.withOpacity(0.4),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                    textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                  ),
                  child: _loading
                      ? const SizedBox(
                          width: 18, height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                        )
                      : const Text('Create & Join'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}