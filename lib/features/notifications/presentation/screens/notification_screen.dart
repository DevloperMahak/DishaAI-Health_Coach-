import 'package:disha_ai/features/notifications/data/models/notification_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/theme/app_colors.dart';
import '../controllers/notification_controller.dart';
import '../widgets/notification_app_bar.dart';
import '../widgets/notification_card.dart';
import '../widgets/notification_empty_state.dart';
import '../widgets/notification_section_title.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  late final NotificationController _controller;

  @override
  void initState() {
    super.initState();

    _controller = Get.isRegistered<NotificationController>()
        ? Get.find<NotificationController>()
        : Get.put(NotificationController());
  }

  // ============================================================
  // REFRESH
  // ============================================================

  Future<void> _refresh() async {
    await _controller.refreshNotifications();
  }

  // ============================================================
  // ICON
  // ============================================================

  IconData _getIconForNotification(NotificationModel notification) {
    final type = notification.type.toLowerCase();

    final text = '${notification.title} ${notification.message}'.toLowerCase();

    if (type.contains('coach') ||
        type.contains('ai') ||
        text.contains('coach') ||
        text.contains('ai')) {
      return Icons.smart_toy_rounded;
    }

    if (type.contains('water') ||
        type.contains('hydration') ||
        text.contains('water') ||
        text.contains('hydrate')) {
      return Icons.water_drop_rounded;
    }

    if (type.contains('workout') ||
        type.contains('exercise') ||
        text.contains('workout') ||
        text.contains('exercise')) {
      return Icons.fitness_center_rounded;
    }

    if (type.contains('plan') ||
        type.contains('update') ||
        text.contains('plan') ||
        text.contains('update')) {
      return Icons.calendar_month_rounded;
    }

    if (type.contains('reminder') || text.contains('reminder')) {
      return Icons.notifications_active_rounded;
    }

    return Icons.notifications_active_rounded;
  }

  // ============================================================
  // COLOR
  // ============================================================

  Color _getColorForNotification(NotificationModel notification) {
    final type = notification.type.toLowerCase();

    final text = '${notification.title} ${notification.message}'.toLowerCase();

    if (type.contains('coach') ||
        type.contains('ai') ||
        text.contains('coach') ||
        text.contains('ai')) {
      return Colors.blue;
    }

    if (type.contains('water') ||
        type.contains('hydration') ||
        text.contains('water') ||
        text.contains('hydrate')) {
      return Colors.cyan;
    }

    if (type.contains('workout') ||
        type.contains('exercise') ||
        text.contains('workout') ||
        text.contains('exercise')) {
      return Colors.orange;
    }

    if (type.contains('achievement') ||
        type.contains('streak') ||
        text.contains('achievement') ||
        text.contains('streak')) {
      return Colors.amber;
    }

    if (type.contains('plan') ||
        type.contains('update') ||
        text.contains('plan') ||
        text.contains('update')) {
      return Colors.green;
    }

    return AppColors.primary;
  }

  // ============================================================
  // SECTION
  // ============================================================

  String _getSection(DateTime? date) {
    if (date == null) {
      return 'Earlier';
    }

    final now = DateTime.now();

    final today = DateTime(now.year, now.month, now.day);

    final notificationDate = DateTime(date.year, date.month, date.day);

    if (notificationDate == today) {
      return 'Today';
    }

    if (notificationDate == today.subtract(const Duration(days: 1))) {
      return 'Yesterday';
    }

    return 'Earlier';
  }

  // ============================================================
  // TIME
  // ============================================================

  String _getTimeString(NotificationModel notification) {
    if (notification.timeAgo != null &&
        notification.timeAgo!.trim().isNotEmpty) {
      return notification.timeAgo!;
    }

    final date = notification.createdAt;

    if (date == null) {
      return '';
    }

    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) {
      return 'Just now';
    }

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} min ago';
    }

    if (difference.inHours < 24) {
      return '${difference.inHours} hr ago';
    }

    if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    }

    return '${date.day}/${date.month}/${date.year}';
  }

  // ============================================================
  // SECTION BUILDER
  // ============================================================

  Widget _buildSection(String title, List<NotificationModel> notificationList) {
    final data = notificationList
        .where((notification) => _getSection(notification.createdAt) == title)
        .toList();

    if (data.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        NotificationSectionTitle(title: title, count: data.length),
        ...data.map((item) {
          return NotificationCard(
            title: item.title,
            message: item.message,
            time: _getTimeString(item),
            icon: _getIconForNotification(item),
            iconColor: _getColorForNotification(item),
            isUnread: !item.isRead,

            // MARK AS READ
            onTap: () async {
              if (!item.isRead) {
                await _controller.markAsRead(item.id);
              }
            },

            // DELETE
            onDelete: () async {
              await _controller.deleteNotification(item.id);
            },
          );
        }),
      ],
    );
  }

  // ============================================================
  // CLEAR ALL CONFIRMATION
  // ============================================================

  void _showClearAllDialog() {
    if (_controller.notifications.isEmpty) {
      Get.snackbar(
        'Notifications',
        'There are no notifications to clear.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.surface,
        colorText: AppColors.textPrimary,
      );

      return;
    }

    Get.defaultDialog(
      title: 'Clear Notifications',
      middleText: 'Are you sure you want to delete all loaded notifications?',
      textConfirm: 'Clear All',
      textCancel: 'Cancel',
      confirmTextColor: Colors.white,
      buttonColor: Colors.redAccent,
      onConfirm: () async {
        Get.back();
        await _controller.clearAllNotifications();
      },
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final tablet = width >= 700;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          backgroundColor: AppColors.surface,
          onRefresh: _refresh,
          child: Obx(() {
            final isLoading = _controller.isLoading.value;
            final isLoadingMore = _controller.isLoadingMore.value;

            // IMPORTANT: RxInt -> int
            final int unreadCount = _controller.unreadCount.value;

            // Convert RxList to a normal list for display.
            final List<NotificationModel> displayList = _controller
                .notifications
                .toList();

            final hasError = _controller.errorMessage.value.isNotEmpty;

            return NotificationListener<ScrollNotification>(
              onNotification: (notification) {
                if (notification is ScrollEndNotification &&
                    notification.metrics.extentAfter < 250) {
                  _controller.loadMoreNotifications();
                }

                return false;
              },
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                padding: EdgeInsets.symmetric(
                  horizontal: tablet ? 40 : 20,
                  vertical: 18,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 850),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // APP BAR
                        NotificationAppBar(
                          unreadCount: unreadCount,
                          onBack: () => Get.back(),
                          onSettings: _showClearAllDialog,
                          onMarkAllRead: () async {
                            await _controller.markAllAsRead();
                          },
                        ),

                        const SizedBox(height: 16),

                        // ERROR MESSAGE
                        if (hasError)
                          Container(
                            width: double.infinity,
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.redAccent.withOpacity(.08),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.error_outline_rounded,
                                  color: Colors.redAccent,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _controller.errorMessage.value,
                                    style: const TextStyle(
                                      color: Colors.redAccent,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  onPressed: _controller.clearError,
                                  icon: const Icon(Icons.close, size: 18),
                                ),
                              ],
                            ),
                          ),

                        // INITIAL LOADING
                        if (isLoading && displayList.isEmpty)
                          const Padding(
                            padding: EdgeInsets.only(top: 100),
                            child: Center(
                              child: CircularProgressIndicator(
                                color: AppColors.primary,
                              ),
                            ),
                          )
                        // EMPTY STATE
                        else if (displayList.isEmpty)
                          const Padding(
                            padding: EdgeInsets.only(top: 100),
                            child: Center(child: NotificationEmptyState()),
                          )
                        // NOTIFICATION SECTIONS
                        else ...[
                          _buildSection('Today', displayList),
                          _buildSection('Yesterday', displayList),
                          _buildSection('Earlier', displayList),
                        ],

                        // PAGINATION LOADER
                        if (isLoadingMore)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 20),
                            child: Center(
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.primary,
                              ),
                            ),
                          ),

                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
