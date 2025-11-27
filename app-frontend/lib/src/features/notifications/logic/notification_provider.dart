// lib/src/features/notifications/logic/notification_provider.dart

import 'dart:convert';
import 'package:al_faruk_app/src/features/auth/data/auth_providers.dart';
import 'package:al_faruk_app/src/features/notifications/models/notification_model.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Helper Provider to count unread messages
final unreadNotificationCountProvider = Provider<int>((ref) {
  final notifications = ref.watch(notificationListProvider);
  return notifications.where((n) => !n.isRead).length;
});

// Update Provider to pass Dio
final notificationListProvider =
    StateNotifierProvider<NotificationNotifier, List<AppNotification>>((ref) {
  final dio = ref.read(dioProvider);
  return NotificationNotifier(dio);
});

class NotificationNotifier extends StateNotifier<List<AppNotification>> {
  final Dio _dio;

  NotificationNotifier(this._dio) : super([]) {
    _loadFromPrefs();
  }

  Future<void> fetchNotifications() async {
    try {
      final response = await _dio.get('/notifications');

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        final List<AppNotification> apiNotifications =
            data.map((json) => AppNotification.fromApiJson(json)).toList();

        _mergeNotifications(apiNotifications);
      }
    } catch (e) {
      print("Error fetching notifications: $e");
    }
  }

  // --- FIX: SMART MERGE LOGIC ---
  void _mergeNotifications(List<AppNotification> apiList) {
    // 1. Create a mutable copy of the current local list
    List<AppNotification> localList = List.from(state);
    List<AppNotification> finalList = [];

    for (var apiItem in apiList) {
      int existingIndex = -1;

      // A. Try to find by Exact ID Match
      existingIndex = localList.indexWhere((n) => n.id == apiItem.id);

      // B. If not found, try "Fuzzy Match" (Same Content & close time)
      // This handles the case where FCM ID != API ID
      if (existingIndex == -1) {
        existingIndex = localList.indexWhere((n) {
          // Check if time difference is less than 15 minutes
          final timeDiff =
              n.timestamp.difference(apiItem.timestamp).inMinutes.abs();
          return n.title == apiItem.title &&
              n.body == apiItem.body &&
              timeDiff < 15;
        });
      }

      if (existingIndex != -1) {
        // MATCH FOUND:
        // Use the API item (to ensure we have the correct server ID)
        // But keep the 'isRead' status from the local item.
        final localItem = localList[existingIndex];

        final mergedItem = AppNotification(
          id: apiItem.id,
          title: apiItem.title,
          body: apiItem.body,
          type: apiItem.type,
          timestamp: apiItem.timestamp,
          isRead: localItem.isRead, // Preserve Read Status
        );

        finalList.add(mergedItem);
        // Remove from localList so we don't duplicate it later
        localList.removeAt(existingIndex);
      } else {
        // NEW ITEM: Add straight from API
        finalList.add(apiItem);
      }
    }

    // 2. Add any remaining local items (e.g., recent FCM messages not yet in API)
    finalList.addAll(localList);

    // 3. Sort by Newest First
    finalList.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    state = finalList;
    _saveToPrefs();
  }

  void addNotification(AppNotification notification) {
    // Prevent immediate duplicates based on ID
    if (!state.any((n) => n.id == notification.id)) {
      state = [notification, ...state];
      _saveToPrefs();
    }
  }

  void markAsRead(String id) {
    state = [
      for (final n in state)
        if (n.id == id)
          AppNotification(
              id: n.id,
              title: n.title,
              body: n.body,
              type: n.type,
              timestamp: n.timestamp,
              isRead: true)
        else
          n
    ];
    _saveToPrefs();
  }

  Future<void> _saveToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final String encodedData =
        jsonEncode(state.map((e) => e.toJson()).toList());
    await prefs.setString('saved_notifications', encodedData);
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final String? encodedData = prefs.getString('saved_notifications');
    if (encodedData != null) {
      final List<dynamic> decodedData = jsonDecode(encodedData);
      state = decodedData.map((e) => AppNotification.fromJson(e)).toList();
    }
  }
}
