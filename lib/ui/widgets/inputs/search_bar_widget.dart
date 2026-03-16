import 'package:flutter/material.dart';
import 'package:lockedin_frontend/ui/theme/app_theme.dart';
import 'package:lockedin_frontend/ui/responsive/responsive.dart';

class SearchBarWidget extends StatefulWidget {
  final TextEditingController controller;
  final ValueChanged<String>? onSubmitted;
  final ValueChanged<String>? onChanged; // 👈 added for live search
  final VoidCallback? onClear;
  final String hintText;

  const SearchBarWidget({
    super.key,
    required this.controller,
    this.onSubmitted,
    this.onChanged,
    this.onClear,
    this.hintText = 'Search',
  });

  @override
  State<SearchBarWidget> createState() => _SearchBarWidgetState();
}

class _SearchBarWidgetState extends State<SearchBarWidget> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged); // 👈 to rebuild suffixIcon
  }

  void _onTextChanged() {
    setState(() {}); // just rebuild to show/hide clear button
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(Responsive.radius(context, size: 30)),
        border: Border.all(color: AppColors.textPrimary, width: 1.5),
      ),
      child: TextField(
        controller: widget.controller,
        onSubmitted: widget.onSubmitted,
        onChanged: widget.onChanged, // 👈 live search like onChanged: provider.search
        style: TextStyle(
          fontFamily: 'Nunito',
          fontSize: Responsive.text(context, size: 14),
          color: AppColors.textPrimary,
        ),
        decoration: InputDecoration(
          isDense: true,
          hintText: widget.hintText,
          hintStyle: TextStyle(
            fontFamily: 'Nunito',
            fontSize: Responsive.text(context, size: 14),
            color: AppColors.grey,
          ),
          prefixIcon: Icon(Icons.search, color: AppColors.grey, size: Responsive.icon(context, size: 18)),
          suffixIcon: widget.controller.text.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.close, color: AppColors.grey, size: Responsive.icon(context, size: 18)),
                  onPressed: widget.onClear,
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }
}