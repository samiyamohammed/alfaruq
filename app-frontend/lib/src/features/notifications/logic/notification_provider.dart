import 'dart:convert';
import 'package:al_faruk_app/src/features/auth/data/auth_providers.dart';
import 'package:al_faruk_app/src/features/notifications/models/notification_model.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final unreadNotificationCountProvider = Provider<int>((ref) {
  final notifications = ref.watch(notificationListProvider);
  return notifications.where((n) => !n.isRead).length;
});

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

  // --- API: GET /notifications ---
  Future<void> fetchNotifications() async {
    try {
      final response = await _dio.get('/notifications');

      if (response.statusCode == 200) {
        // Handle "data": [...] structure if present, otherwise direct list
        final data =
            response.data is Map ? response.data['data'] : response.data;

        if (data is List) {
          final List<AppNotification> apiNotifications =
              data.map((json) => AppNotification.fromApiJson(json)).toList();
          _mergeNotifications(apiNotifications);
        }
      }
    } catch (e) {
      print("Error fetching notifications: $e");
    }
  }

  // --- API: POST /notifications/{id}/read ---
  Future<void> markAsRead(String id) async {
    // 1. Optimistic Update (UI updates instantly)
    state = [
      for (final n in state)
        if (n.id == id) n.copyWith(isRead: true) else n
    ];
    _saveToPrefs();

    // 2. Call API
    try {
      await _dio.post('/notifications/$id/read');
    } catch (e) {
      print("Error marking as read: $e");
    }
  }

  // --- API: POST /notifications/{id}/clear ---
  Future<void> clearNotification(String id) async {
    final previousState = state;

    // 1. Optimistic Update
    state = state.where((n) => n.id != id).toList();
    _saveToPrefs();

    // 2. Call API
    try {
      await _dio.post('/notifications/$id/clear');
    } catch (e) {
      print("Error clearing notification: $e");
      // Optional: Revert if you want strict sync
      // state = previousState;
    }
  }

  // --- API: POST /notifications/clear-all ---
  Future<void> clearAll() async {
    final previousState = state;

    // 1. Optimistic Update
    state = [];
    _saveToPrefs();

    // 2. Call API
    try {
      await _dio.post('/notifications/clear-all');
    } catch (e) {
      print("Error clearing all: $e");
      state = previousState; // Revert on failure
    }
  }

  // Internal Logic to merge API data with local cache
  void _mergeNotifications(List<AppNotification> apiList) {
    List<AppNotification> localList = List.from(state);
    List<AppNotification> finalList = [];

    for (var apiItem in apiList) {
      int existingIndex = localList.indexWhere((n) => n.id == apiItem.id);

      // Fuzzy match for FCM vs API consistency
      if (existingIndex == -1) {
        existingIndex = localList.indexWhere((n) {
          final timeDiff =
              n.timestamp.difference(apiItem.timestamp).inMinutes.abs();
          return n.title == apiItem.title &&
              n.body == apiItem.body &&
              timeDiff < 15;
        });
      }

      if (existingIndex != -1) {
        final localItem = localList[existingIndex];
        // Merge: Use API ID but keep Local Read Status if true
        final mergedItem =
            apiItem.copyWith(isRead: localItem.isRead || apiItem.isRead);
        finalList.add(mergedItem);
        localList.removeAt(existingIndex);
      } else {
        finalList.add(apiItem);
      }
    }

    // Add remaining local items (e.g. recent pushes not yet on server)
    finalList.addAll(localList);
    // Sort Newest First
    finalList.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    state = finalList;
    _saveToPrefs();
  }

  void addNotification(AppNotification notification) {
    if (!state.any((n) => n.id == notification.id)) {
      state = [notification, ...state];
      _saveToPrefs();
    }
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
