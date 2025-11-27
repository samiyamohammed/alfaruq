// lib/src/core/services/fcm_service.dart
import 'package:al_faruk_app/src/features/notifications/logic/notification_provider.dart';
import 'package:al_faruk_app/src/features/notifications/models/notification_model.dart';
import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // Needed for WidgetRef

class FCMService {
  final Dio _dio;
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  FCMService({required Dio dio}) : _dio = dio;

  /// 1. Initialize Notifications
  // UPDATED: Accepts WidgetRef to interact with Riverpod
  Future<void> initialize(WidgetRef ref) async {
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('User granted permission');

      // A. Get Token & Send to Backend
      String? token = await _firebaseMessaging.getToken();
      if (token != null) {
        debugPrint("🔥 FCM Token: $token");
        await _registerDeviceOnBackend(token);
      }

      // B. Listen for Token Refresh
      _firebaseMessaging.onTokenRefresh.listen((newToken) {
        _registerDeviceOnBackend(newToken);
      });

      // C. Listen for Foreground Messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('Got a message whilst in the foreground!');

        if (message.notification != null) {
          // Convert to our AppNotification model
          final notification = AppNotification.fromRemoteMessage(message);

          // Add to the Provider (Updates UI instantly)
          ref
              .read(notificationListProvider.notifier)
              .addNotification(notification);
        }
      });
    } else {
      debugPrint('User declined or has not accepted permission');
    }
  }

  /// 2. Send Token to Backend
  Future<void> _registerDeviceOnBackend(String fcmToken) async {
    try {
      const endpoint = '/devices';
      final data = {
        "fcmToken": fcmToken,
      };

      final response = await _dio.post(endpoint, data: data);

      if (response.statusCode == 201 || response.statusCode == 200) {
        debugPrint("✅ Device Registered Successfully on Backend");
      } else {
        debugPrint("⚠️ Failed to register device: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("❌ Error registering device on backend: $e");
    }
  }
}
