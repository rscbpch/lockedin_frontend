import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:lockedin_frontend/config/env.dart';

// ✅ Must be top-level — handles notifications when app is killed
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

    // Background handler
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // Create Android notification channel
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);

    // Init local notifications
    const darwinSettings = DarwinInitializationSettings();
    const initSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: darwinSettings,
    );
    await _localNotifications.initialize(initSettings);

    await _localNotifications
      .resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>()
      ?.requestPermissions(alert: true, badge: true, sound: true);

    await _localNotifications
      .resolvePlatformSpecificImplementation<
        MacOSFlutterLocalNotificationsPlugin>()
      ?.requestPermissions(alert: true, badge: true, sound: true);

    _initialized = true;

    // Show notification when app is in FOREGROUND
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
            iOS: const DarwinNotificationDetails(
              presentAlert: true,
              presentBadge: true,
              presentSound: true,
            ),
          ),
        );
      }
    });
  }

  /// Call this after user logs in — saves FCM token to backend
  static Future<void> saveTokenToBackend(
      Future<String?> Function() getAuthToken) async {
    try {
      final fcmToken = await FirebaseMessaging.instance.getToken();
      if (fcmToken == null) return;

      debugPrint('📱 Saving FCM token to backend...');

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

  /// Call on logout — clears token from backend
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
      debugPrint('📱 Device token removed');
    } catch (e) {
      debugPrint('❌ Failed to remove device token: $e');
    }
  }
}