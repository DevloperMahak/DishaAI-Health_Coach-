import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../data/models/notification_model.dart';
import '../../data/services/notification_service.dart';
import '../../../../core/notifications/local_notification_service.dart';

class NotificationController extends GetxController
    with WidgetsBindingObserver {
  // ============================================================
  // SERVICES
  // ============================================================

  final NotificationService _notificationService = NotificationService();

  final LocalNotificationService _localNotificationService =
      LocalNotificationService.instance;

  // ============================================================
  // REACTIVE STATE
  // ============================================================

  final RxList<NotificationModel> notifications = <NotificationModel>[].obs;

  final RxBool isLoading = false.obs;
  final RxBool isLoadingMore = false.obs;
  final RxBool isMarkingAllRead = false.obs;
  final RxBool isDeletingAll = false.obs;

  final RxSet<String> isDeleting = <String>{}.obs;

  final RxInt unreadCount = 0.obs;

  final RxString errorMessage = ''.obs;

  // ============================================================
  // PAGINATION
  // ============================================================

  int _currentPage = 1;
  int _perPage = 20;
  int _lastPage = 1;
  int _total = 0;

  bool _hasMore = true;

  bool get hasMore => _hasMore;

  int get currentPage => _currentPage;

  int get totalNotifications => _total;

  // ============================================================
  // LIFECYCLE
  // ============================================================

  @override
  void onInit() {
    super.onInit();

    WidgetsBinding.instance.addObserver(this);

    fetchNotifications();
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);

    super.onClose();
  }

  /// Refresh the notification inbox when the app returns
  /// from background.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      refreshNotifications();
    }
  }

  // ============================================================
  // SORT NOTIFICATIONS
  // ============================================================

  void _sortNotifications() {
    notifications.sort((a, b) {
      final aDate = a.createdAt;
      final bDate = b.createdAt;

      if (aDate == null && bDate == null) return 0;
      if (aDate == null) return 1;
      if (bDate == null) return -1;

      return bDate.compareTo(aDate);
    });
  }

  // ============================================================
  // CLEAR ERROR MESSAGE
  // ============================================================

  void clearError() {
    errorMessage.value = '';
  }
  // ============================================================
  // FETCH NOTIFICATIONS
  // ============================================================

  Future<void> fetchNotifications({bool showLoader = true}) async {
    if (isLoading.value) return;

    try {
      if (showLoader) {
        isLoading.value = true;
      }

      errorMessage.value = '';

      final result = await _notificationService.getNotifications(
        page: 1,
        perPage: _perPage,
      );

      notifications.assignAll(result.notifications);

      _currentPage = result.currentPage;
      _perPage = result.perPage;
      _lastPage = result.lastPage;
      _total = result.total;
      _hasMore = result.hasMore;

      unreadCount.value = result.unreadCount;

      _sortNotifications();

      _log(
        'Notifications fetched: ${notifications.length}, '
        'Unread: ${unreadCount.value}',
      );
    } catch (e, stackTrace) {
      errorMessage.value = 'Unable to load notifications.';

      _log('FETCH NOTIFICATIONS ERROR: $e');
      debugPrintStack(stackTrace: stackTrace);
    } finally {
      isLoading.value = false;
    }
  }

  // ============================================================
  // REFRESH NOTIFICATIONS
  // ============================================================

  Future<void> refreshNotifications() async {
    _log('Refreshing notification inbox...');

    await fetchNotifications(showLoader: false);
  }

  // ============================================================
  // LOAD MORE NOTIFICATIONS
  // ============================================================

  Future<void> loadMoreNotifications() async {
    if (isLoadingMore.value || isLoading.value || !_hasMore) {
      return;
    }

    if (_currentPage >= _lastPage) {
      _hasMore = false;
      return;
    }

    try {
      isLoadingMore.value = true;

      errorMessage.value = '';

      final nextPage = _currentPage + 1;

      final result = await _notificationService.getNotifications(
        page: nextPage,
        perPage: _perPage,
      );

      // Avoid duplicate notification IDs.
      final existingIds = notifications.map((item) => item.id).toSet();

      final newNotifications = result.notifications.where(
        (item) => !existingIds.contains(item.id),
      );

      notifications.addAll(newNotifications);

      _currentPage = result.currentPage;
      _lastPage = result.lastPage;
      _total = result.total;
      _hasMore = result.hasMore;

      unreadCount.value = result.unreadCount;

      _sortNotifications();

      _log('Loaded notification page: $_currentPage');
    } catch (e, stackTrace) {
      errorMessage.value = 'Unable to load more notifications.';

      _log('LOAD MORE NOTIFICATIONS ERROR: $e');
      debugPrintStack(stackTrace: stackTrace);
    } finally {
      isLoadingMore.value = false;
    }
  }

  // ============================================================
  // MARK SINGLE NOTIFICATION AS READ
  // ============================================================

  Future<void> markAsRead(String id) async {
    final index = notifications.indexWhere((item) => item.id == id);

    if (index == -1) return;

    final notification = notifications[index];

    if (notification.isRead) return;

    try {
      // Optimistic UI update.
      notifications[index] = notification.copyWith(isRead: true);

      if (unreadCount.value > 0) {
        unreadCount.value--;
      }

      final success = await _notificationService.markAsRead(id);

      if (!success) {
        // Restore original state if API fails.
        notifications[index] = notification;
        unreadCount.value++;
        _log('MARK AS READ FAILED: $id');
        return;
      }

      _log('Notification marked as read: $id');
    } catch (e, stackTrace) {
      notifications[index] = notification;
      unreadCount.value++;

      _log('MARK AS READ ERROR: $e');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  // ============================================================
  // MARK ALL NOTIFICATIONS AS READ
  // ============================================================

  Future<void> markAllAsRead() async {
    if (isMarkingAllRead.value || unreadCount.value == 0) {
      return;
    }

    try {
      isMarkingAllRead.value = true;

      final success = await _notificationService.markAllAsRead();

      if (!success) {
        _log('MARK ALL AS READ FAILED');
        return;
      }

      for (int i = 0; i < notifications.length; i++) {
        if (!notifications[i].isRead) {
          notifications[i] = notifications[i].copyWith(isRead: true);
        }
      }

      unreadCount.value = 0;

      _log('All notifications marked as read.');
    } catch (e, stackTrace) {
      _log('MARK ALL AS READ ERROR: $e');
      debugPrintStack(stackTrace: stackTrace);
    } finally {
      isMarkingAllRead.value = false;
    }
  }

  // ============================================================
  // DELETE SINGLE NOTIFICATION
  // ============================================================

  Future<void> deleteNotification(String id) async {
    if (isDeleting.contains(id)) return;

    final index = notifications.indexWhere((item) => item.id == id);

    if (index == -1) return;

    final notification = notifications[index];

    try {
      isDeleting.add(id);

      final success = await _notificationService.deleteNotification(id);

      if (!success) {
        _log('DELETE NOTIFICATION FAILED: $id');
        return;
      }

      notifications.removeWhere((item) => item.id == id);

      if (!notification.isRead && unreadCount.value > 0) {
        unreadCount.value--;
      }

      if (_total > 0) {
        _total--;
      }

      _log('Notification deleted: $id');
    } catch (e, stackTrace) {
      _log('DELETE NOTIFICATION ERROR: $e');
      debugPrintStack(stackTrace: stackTrace);
    } finally {
      isDeleting.remove(id);
    }
  }

  // ============================================================
  // CLEAR ALL NOTIFICATIONS
  // ============================================================

  Future<void> clearAllNotifications() async {
    if (isDeletingAll.value || notifications.isEmpty) {
      return;
    }

    try {
      isDeletingAll.value = true;

      // Use the existing single-delete API for each notification.
      final currentNotifications = List<NotificationModel>.from(notifications);

      final results = await Future.wait(
        currentNotifications.map((notification) async {
          try {
            final success = await _notificationService.deleteNotification(
              notification.id,
            );

            return success ? notification.id : null;
          } catch (_) {
            return null;
          }
        }),
      );

      final deletedIds = results.whereType<String>().toSet();

      notifications.removeWhere((item) => deletedIds.contains(item.id));

      final deletedUnreadCount = currentNotifications
          .where((item) => deletedIds.contains(item.id) && !item.isRead)
          .length;

      unreadCount.value = (unreadCount.value - deletedUnreadCount).clamp(
        0,
        999999999,
      );

      _total = (_total - deletedIds.length).clamp(0, 999999999);

      _log(
        'Clear all completed. '
        'Deleted: ${deletedIds.length}, '
        'Failed: ${currentNotifications.length - deletedIds.length}',
      );
    } catch (e, stackTrace) {
      _log('CLEAR ALL NOTIFICATIONS ERROR: $e');
      debugPrintStack(stackTrace: stackTrace);
    } finally {
      isDeletingAll.value = false;
    }
  }

  // ============================================================
  // INCOMING FOREGROUND FCM NOTIFICATION
  // ============================================================

  Future<void> showIncomingNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    try {
      _log('Incoming FCM notification received.');
      _log('Title: $title');

      // Display using the existing notification service.
      // Do not call this again from FcmNotificationService.
      await _localNotificationService.showFcmNotification(
        title: title,
        body: body,
        payload: payload,
      );

      _log('Incoming local notification displayed.');
    } catch (e, stackTrace) {
      _log('SHOW INCOMING NOTIFICATION ERROR: $e');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  // ============================================================
  // DEBUG LOGGER
  // ============================================================

  void _log(String message) {
    debugPrint('[RHEAAI NOTIFICATIONS] $message');
  }
}
