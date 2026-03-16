import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:lockedin_frontend/config/env.dart';
import 'package:stream_chat_flutter/stream_chat_flutter.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('🔔 Background message: ${message.notification?.title}');
}

class NotificationService {
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'lockedin_high_importance',
    'LockedIn Notifications',
    description: 'Notifications for follows, messages and more',
    importance: Importance.high,
  );

  static bool _initialized = false;

  /// Call once after Firebase.initializeApp() in main()
  static Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(_channel);

    const initSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    );
    await _localNotifications.initialize(initSettings);

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('🔔 Foreground message: ${message.notification?.title}');
      final notification = message.notification;
      if (notification != null) {
        _localNotifications.show(
          notification.hashCode,
          notification.title,
          notification.body,
          NotificationDetails(
            android: AndroidNotificationDetails(
              _channel.id,
              _channel.name,
              channelDescription: _channel.description,
              importance: Importance.high,
              priority: Priority.high,
              icon: '@mipmap/ic_launcher',
            ),
          ),
        );
      }
    });
  }

  /// Call after user connects to Stream — registers FCM token with Stream
  static Future<void> registerWithStream(StreamChatClient streamClient) async {
    try {
      final fcmToken = await FirebaseMessaging.instance.getToken();
      if (fcmToken == null) return;

      await streamClient.addDevice(
        fcmToken,
        PushProvider.firebase,
        pushProviderName: 'LockedIn',
      );
      debugPrint('✅ FCM token registered with Stream');

      FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
        await streamClient.addDevice(
          newToken,
          PushProvider.firebase,
          pushProviderName: 'LockedIn',
        );
        debugPrint('🔄 Stream FCM token refreshed');
      });
    } catch (e) {
      debugPrint('❌ Failed to register token with Stream: $e');
    }
  }

  /// Call on logout — removes FCM token from Stream
  static Future<void> removeFromStream(StreamChatClient streamClient) async {
    try {
      final fcmToken = await FirebaseMessaging.instance.getToken();
      if (fcmToken == null) return;
      await streamClient.removeDevice(fcmToken);
      debugPrint('✅ FCM token removed from Stream');
    } catch (e) {
      debugPrint('❌ Failed to remove token from Stream: $e');
    }
  }

  /// Call after user logs in — saves FCM token to your backend (for follow notifications)
  static Future<void> saveTokenToBackend(
      Future<String?> Function() getAuthToken) async {
    try {
      final fcmToken = await FirebaseMessaging.instance.getToken();
      if (fcmToken == null) return;

      final authToken = await getAuthToken();
      if (authToken == null) return;

      final response = await http.patch(
        Uri.parse('${Env.apiBaseUrl}/user/device-token'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
        body: jsonEncode({'deviceToken': fcmToken}),
      );
      debugPrint('📡 Save device token: ${response.statusCode}');
    } catch (e) {
      debugPrint('❌ Failed to save device token: $e');
    }
  }

  /// Call on logout — clears FCM token from your backend
  static Future<void> removeTokenFromBackend(
      Future<String?> Function() getAuthToken) async {
    try {
      final authToken = await getAuthToken();
      if (authToken == null) return;

      await http.patch(
        Uri.parse('${Env.apiBaseUrl}/user/device-token'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
        body: jsonEncode({'deviceToken': null}),
      );
      await FirebaseMessaging.instance.deleteToken();
      debugPrint('📱 Device token removed from backend');
    } catch (e) {
      debugPrint('❌ Failed to remove device token: $e');
    }
  }
}