import 'package:flutter/material.dart';
import 'package:stream_chat_flutter/stream_chat_flutter.dart';
import '../../../theme/app_theme.dart';

class StreamChatAppTheme {
  static StreamChatThemeData get theme => StreamChatThemeData(
        // ✅ Your sent bubbles
        ownMessageTheme: StreamMessageThemeData(
          messageBackgroundColor: AppColors.primary,
          messageTextStyle: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontFamily: 'Quicksand',
            fontWeight: FontWeight.w500
          ),
          createdAtStyle: TextStyle(
            color: AppColors.grey,
            fontSize: 12,
            fontFamily: 'Quicksand',
            fontWeight: FontWeight.w500
          ),
        ),

        // ✅ Received bubbles
        otherMessageTheme: StreamMessageThemeData(
          messageBackgroundColor: AppColors.backgroundBox,
          messageTextStyle: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 16,
            fontFamily: 'Quicksand',
            fontWeight: FontWeight.w500
          ),
          createdAtStyle: const TextStyle(
            color: AppColors.grey,
            fontSize: 12,
            fontFamily: 'Quicksand',
            fontWeight: FontWeight.w500
          ),
        ),

        // ✅ Message list background
        messageListViewTheme: const StreamMessageListViewThemeData(
          backgroundColor: AppColors.background,
        ),

        // ✅ Input bar
        messageInputTheme: StreamMessageInputThemeData(
          inputBackgroundColor: AppColors.background,
          borderRadius: BorderRadius.circular(40),
          
          // Match the outline border style
          inputDecoration: InputDecoration(
            hintText: 'Type a message',
            hintStyle: const TextStyle(
              fontFamily: 'Quicksand',
              color: AppColors.grey,
              fontSize: 16,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(40),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(40),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(40),
              borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            filled: true,
            fillColor: AppColors.background,
          ),
          
          inputTextStyle: const TextStyle(
            fontFamily: 'Quicksand',
            color: AppColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
          
          actionButtonColor: AppColors.secondary,
        ),

        // ✅ Global accent colors
        colorTheme: StreamColorTheme.light(
          accentPrimary: AppColors.primary,
          accentError: Colors.red,
          highlight: AppColors.accent,
          borders: AppColors.grey,
        ),
      );
}