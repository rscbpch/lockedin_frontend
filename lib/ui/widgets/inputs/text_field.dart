import 'package:flutter/material.dart';
import 'package:lockedin_frontend/ui/theme/app_theme.dart';

class AppTextField extends StatefulWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final bool isPassword;
  final String? Function(String?)? validator;
  final TextInputType keyboardType;
  final bool filled;
  final Color? fillColor;

  const AppTextField({
    super.key,
    required this.label,
    required this.hint,
    required this.controller,
    this.isPassword = false,
    this.validator,
    this.keyboardType = TextInputType.text,
    this.filled = false,
    this.fillColor,
  });

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    final hasText = widget.controller.text.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 6),
        TextFormField(
          controller: widget.controller,
          keyboardType: widget.keyboardType,
          obscureText: widget.isPassword ? _obscureText : false,
          validator: widget.validator,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          onChanged: (_) => setState(() {}),
          cursorColor: AppColors.textPrimary,
          style: const TextStyle(fontSize: 16, color: AppColors.textPrimary, fontFamily: 'Nunito'),
          decoration: InputDecoration(
            labelText: widget.label,
            hintText: widget.hint,
            floatingLabelBehavior: FloatingLabelBehavior.always,
            suffixIcon: _buildSuffixIcon(hasText),
            labelStyle: const TextStyle(color: AppColors.textPrimary, fontFamily: 'Nunito'),
            floatingLabelStyle: const TextStyle(color: AppColors.textPrimary, fontFamily: 'Nunito'),
            hintStyle: const TextStyle(color: AppColors.grey, fontFamily: 'Nunito'),

            filled: widget.filled,
            fillColor: widget.fillColor ?? AppColors.accent,

            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.textPrimary),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.textPrimary),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.textPrimary, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  Widget? _buildSuffixIcon(bool hasText) {
    if (!hasText) return null;

    if (widget.isPassword) {
      return IconButton(
        icon: Icon(_obscureText ? Icons.visibility_off : Icons.visibility),
        onPressed: () {
          setState(() => _obscureText = !_obscureText);
        },
      );
    }

    return IconButton(
      icon: const Icon(Icons.close),
      onPressed: () {
        widget.controller.clear();
        setState(() {});
      },
    );
  }
}
