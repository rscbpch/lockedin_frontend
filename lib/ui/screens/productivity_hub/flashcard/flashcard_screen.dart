import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lockedin_frontend/ui/responsive/responsive.dart';
import 'package:lockedin_frontend/ui/theme/app_theme.dart';

class FlashcardScreen extends StatefulWidget {
  const FlashcardScreen({super.key});

  @override
  State<FlashcardScreen> createState() => _FlashcardState();
}

class _FlashcardState extends State<FlashcardScreen> {
  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Flashcard',
          style: TextStyle(color:  AppColors.textPrimary, fontFamily: 'Nunito', fontSize: Responsive.text(context, size: 24), fontWeight: FontWeight.w500)
        ),
        centerTitle: true,
        leading: IconButton(
          onPressed: () => context.go('/productivity-hub'),
          icon: Icon(Icons.arrow_back_ios, size: width * 0.06, color: AppColors.textPrimary)
        ),
        backgroundColor: AppColors.background,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16)
        )
      ),
    );
  }
}