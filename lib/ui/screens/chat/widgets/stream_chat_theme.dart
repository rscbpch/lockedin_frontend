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
            fontSize: 14,
          ),
          createdAtStyle: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 11,
          ),
        ),

        // ✅ Received bubbles
        otherMessageTheme: StreamMessageThemeData(
          messageBackgroundColor: AppColors.backgroundBox,
          messageTextStyle: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 14,
          ),
          createdAtStyle: const TextStyle(
            color: AppColors.grey,
            fontSize: 11,
          ),
        ),

        // ✅ Message list background
        messageListViewTheme: const StreamMessageListViewThemeData(
          backgroundColor: AppColors.background,
        ),

        // ✅ Input bar
        messageInputTheme: StreamMessageInputThemeData(
          inputBackgroundColor: AppColors.background,
          borderRadius: BorderRadius.circular(24),
          inputTextStyle: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 14,
          ),
          sendButtonColor: AppColors.primary,
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