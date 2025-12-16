import 'dart:convert';
import 'package:al_faruk_app/src/features/auth/data/auth_providers.dart';
import 'package:al_faruk_app/src/features/notifications/models/notification_model.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// --- NEW HELPER PROVIDER ---
// This provider triggers the fetch and allows the UI to watch the status (Loading/Error/Success)
final notificationFetchProvider = FutureProvider.autoDispose<void>((ref) async {
  final notifier = ref.read(notificationListProvider.notifier);
  await notifier.fetchNotifications();
});

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
        final data =
            response.data is Map ? response.data['data'] : response.data;

        if (data is List) {
          final List<AppNotification> apiNotifications =
              data.map((json) => AppNotification.fromApiJson(json)).toList();
          _mergeNotifications(apiNotifications);
        }
      }
    } on DioException catch (e) {
      // --- FIX: DETECT GUEST ACCESS (403) ---
      if (e.response?.statusCode == 403) {
        // 1. Clear local data (Security: Guests shouldn't see old cached notifications)
        state = [];
        _clearPrefs();

        // 2. Rethrow so the UI knows to show the Restricted Screen
        rethrow;
      }

      // For other errors (offline, server error), we just print and keep cached data
      print("Error fetching notifications: $e");
    } catch (e) {
      print("Unexpected error: $e");
    }
  }

  // --- API: POST /notifications/{id}/read ---
  Future<void> markAsRead(String id) async {
    state = [
      for (final n in state)
        if (n.id == id) n.copyWith(isRead: true) else n
    ];
    _saveToPrefs();

    try {
      await _dio.post('/notifications/$id/read');
    } catch (e) {
      print("Error marking as read: $e");
    }
  }

  // --- API: POST /notifications/{id}/clear ---
  Future<void> clearNotification(String id) async {
    final previousState = state;
    state = state.where((n) => n.id != id).toList();
    _saveToPrefs();

    try {
      await _dio.post('/notifications/$id/clear');
    } catch (e) {
      print("Error clearing notification: $e");
    }
  }

  // --- API: POST /notifications/clear-all ---
  Future<void> clearAll() async {
    final previousState = state;
    state = [];
    _saveToPrefs();

    try {
      await _dio.post('/notifications/clear-all');
    } catch (e) {
      print("Error clearing all: $e");
      state = previousState;
    }
  }

  // Internal Logic
  void _mergeNotifications(List<AppNotification> apiList) {
    List<AppNotification> localList = List.from(state);
    List<AppNotification> finalList = [];

    for (var apiItem in apiList) {
      int existingIndex = localList.indexWhere((n) => n.id == apiItem.id);

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
        final mergedItem =
            apiItem.copyWith(isRead: localItem.isRead || apiItem.isRead);
        finalList.add(mergedItem);
        localList.removeAt(existingIndex);
      } else {
        finalList.add(apiItem);
      }
    }

    finalList.addAll(localList);
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

  Future<void> _clearPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('saved_notifications');
  }
}
