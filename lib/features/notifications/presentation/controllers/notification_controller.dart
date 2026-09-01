import 'package:get/get.dart';
import '../../data/models/notification_model.dart';
import '../../data/services/notification_service.dart';

class NotificationController extends GetxController {
  final NotificationService _service = NotificationService();

  // ============================================================
  // STATE
  // ============================================================
  final RxList<NotificationModel> notifications = <NotificationModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;

  // Automatically calculates how many notifications are unread
  int get unreadCount => notifications.where((n) => !n.isRead).length;

  @override
  void onInit() {
    super.onInit();
    fetchNotifications();
  }

  // ============================================================
  // FETCH
  // ============================================================
  Future<void> fetchNotifications() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final results = await _service.getNotifications();

      // Sort by newest first
      results.sort((a, b) {
        if (a.createdAt == null || b.createdAt == null) return 0;
        return b.createdAt!.compareTo(a.createdAt!);
      });

      notifications.assignAll(results);
    } catch (e) {
      errorMessage.value = _cleanError(e);
    } finally {
      isLoading.value = false;
    }
  }

  // ============================================================
  // MARK AS READ
  // ============================================================
  Future<void> markAllAsRead() async {
    // If there are no unread notifications, skip the API call
    if (unreadCount == 0) return;

    try {
      final success = await _service.markAllAsRead();

      if (success) {
        // Update local state instantly without refetching
        final updatedList = notifications.map((n) {
          return NotificationModel(
            id: n.id,
            title: n.title,
            message: n.message,
            isRead: true, // Mark true locally
            createdAt: n.createdAt,
            extraData: n.extraData,
          );
        }).toList();

        notifications.assignAll(updatedList);
      }
    } catch (e) {
      errorMessage.value = _cleanError(e);
    }
  }

  // ============================================================
  // DELETE ALL
  // ============================================================
  Future<void> clearAllNotifications() async {
    if (notifications.isEmpty) return;

    try {
      isLoading.value = true;
      final success = await _service.deleteNotifications();

      if (success) {
        notifications.clear();
      }
    } catch (e) {
      errorMessage.value = _cleanError(e);
    } finally {
      isLoading.value = false;
    }
  }

  // ============================================================
  // ERROR CLEANUP
  // ============================================================
  String _cleanError(Object error) {
    final message = error.toString();
    if (message.startsWith('Exception: ')) {
      return message.substring('Exception: '.length);
    }
    return message;
  }
}
