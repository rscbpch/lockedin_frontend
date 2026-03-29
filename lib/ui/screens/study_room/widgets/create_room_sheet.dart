import 'package:flutter/material.dart';
import 'package:lockedin_frontend/ui/responsive/responsive.dart';
import 'package:lockedin_frontend/ui/widgets/actions/long_button.dart';
import 'package:lockedin_frontend/ui/widgets/inputs/text_field.dart';
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
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
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
              color: AppColors.primary,
              fontSize: Responsive.text(context, size: 12),
              fontWeight: FontWeight.w700,
              fontFamily: 'Nunito'
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Create a Room',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: Responsive.text(context, size: 18),
              fontWeight: FontWeight.bold,
              fontFamily: 'Nunito'
            ),
          ),
          // const SizedBox(height: 2),
          Text(
            'Start a focused session — up to 10 participants.',
            style: TextStyle(
              color: AppColors.grey,
              fontSize: Responsive.text(context, size: 12),
              fontFamily: 'Quicksand',
              fontWeight: FontWeight.w500
            ),
          ),
          const SizedBox(height: 20),
          AppTextField(
            label: 'Room Name',
            hint: 'e.g. Physics Study Group',
            controller: _controller,
            autofocus: true,
            maxLength: 60,
            onSubmitted: (_) => _submit(),
            onChanged: (_) {
              if (_error != null) setState(() => _error = null);
            },
            errorText: _error,
            filled: true,
            fillColor: AppColors.backgroundBox,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: LongButton(
                  text: 'Cancel',
                  isOutlined: true,
                  onPressed: _loading ? null : () => Navigator.pop(context),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: LongButton(
                  text: _loading ? 'Creating...' : 'Create & Join',
                  onPressed: _loading ? null : _submit,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}