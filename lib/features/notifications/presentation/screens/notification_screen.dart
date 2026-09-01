import 'package:disha_ai/features/notifications/data/models/notification_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/theme/app_colors.dart';
import '../controllers/notification_controller.dart';
import '../widgets/notification_app_bar.dart';
import '../widgets/notification_card.dart';
import '../widgets/notification_empty_state.dart';
import '../widgets/notification_filter_chip.dart';
import '../widgets/notification_section_title.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  //------------------------------------------------------------
  // Controller
  //------------------------------------------------------------
  late final NotificationController _controller;

  //------------------------------------------------------------
  // Selected Filter
  //------------------------------------------------------------
  int _selectedFilter = 0;

  @override
  void initState() {
    super.initState();
    if (Get.isRegistered<NotificationController>()) {
      _controller = Get.find<NotificationController>();
    } else {
      _controller = Get.put(NotificationController());
    }
  }

  //------------------------------------------------------------
  // Refresh
  //------------------------------------------------------------
  Future<void> _refresh() async {
    await _controller.fetchNotifications();
  }

  //------------------------------------------------------------
  // Dynamic UI Helpers
  //------------------------------------------------------------

  // 1. Map API Title to specific Icons
  IconData _getIconForTitle(String title) {
    final t = title.toLowerCase();
    if (t.contains('coach') || t.contains('ai')) return Icons.smart_toy_rounded;
    if (t.contains('hydration') || t.contains('water'))
      return Icons.water_drop_rounded;
    if (t.contains('workout') || t.contains('exercise'))
      return Icons.fitness_center_rounded;
    if (t.contains('achievement') || t.contains('streak'))
      return Icons.workspace_premium_rounded;
    if (t.contains('plan') || t.contains('update'))
      return Icons.calendar_month_rounded;
    return Icons.notifications_active_rounded;
  }

  // 2. Map API Title to specific Colors
  Color _getColorForTitle(String title) {
    final t = title.toLowerCase();
    if (t.contains('coach') || t.contains('ai')) return Colors.blue;
    if (t.contains('hydration') || t.contains('water')) return Colors.cyan;
    if (t.contains('workout') || t.contains('exercise')) return Colors.orange;
    if (t.contains('achievement') || t.contains('streak')) return Colors.amber;
    if (t.contains('plan') || t.contains('update')) return Colors.green;
    return AppColors.primary;
  }

  // 3. Convert DateTime to Section Headers
  String _getSection(DateTime? date) {
    if (date == null) return "Earlier";
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final aDate = DateTime(date.year, date.month, date.day);

    if (aDate == today) return "Today";
    if (aDate == today.subtract(const Duration(days: 1))) return "Yesterday";
    return "Earlier";
  }

  // 4. Convert DateTime to Time Ago string
  String _getTimeString(DateTime? date) {
    if (date == null) return '';
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} hr ago';
    if (diff.inDays < 7) return '${diff.inDays} days ago';

    return '${date.day}/${date.month}/${date.year}';
  }

  //------------------------------------------------------------
  // Filter Logic
  //------------------------------------------------------------
  List<NotificationModel> get _filteredNotifications {
    final list = _controller.notifications;
    if (_selectedFilter == 0) return list; // All

    return list.where((n) {
      final t = n.title.toLowerCase();
      if (_selectedFilter == 1) {
        // AI Coach
        return t.contains('coach') || t.contains('ai');
      }
      if (_selectedFilter == 2) {
        // Reminders
        return t.contains('reminder') ||
            t.contains('water') ||
            t.contains('workout');
      }
      if (_selectedFilter == 3) {
        // Achievements
        return t.contains('achievement') ||
            t.contains('streak') ||
            t.contains('goal');
      }
      if (_selectedFilter == 4) {
        // Plans
        return t.contains('plan') || t.contains('update');
      }
      return true;
    }).toList();
  }

  //------------------------------------------------------------
  // Build Notification List by Section
  //------------------------------------------------------------
  Widget _buildSection(String title, List<NotificationModel> allFiltered) {
    final data = allFiltered
        .where((e) => _getSection(e.createdAt) == title)
        .toList();

    if (data.isEmpty) return const SizedBox();

    return Column(
      children: [
        NotificationSectionTitle(title: title, count: data.length),
        ...data.map(
          (item) => NotificationCard(
            title: item.title,
            message: item.message,
            time: _getTimeString(item.createdAt),
            icon: _getIconForTitle(item.title),
            iconColor: _getColorForTitle(item.title),
            isUnread: !item.isRead,
            onTap: () {
              // Action on tap (e.g., mark single as read if endpoint existed)
            },
            onDelete: () {
              // Local removal (since API is bulk delete only)
              _controller.notifications.remove(item);
            },
          ),
        ),
      ],
    );
  }

  //------------------------------------------------------------
  // Build
  //------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final tablet = width >= 700;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: _refresh,
          child: Obx(() {
            // Listen to controller reactively
            final isLoading = _controller.isLoading.value;
            final unreadCount = _controller.unreadCount;
            final displayList = _filteredNotifications;

            return SingleChildScrollView(
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
                      //--------------------------------------------------
                      // APP BAR
                      //--------------------------------------------------
                      NotificationAppBar(
                        unreadCount: unreadCount,
                        onBack: () => Get.back(),
                        onSettings: () {
                          // Using settings button to Clear All Notifications
                          Get.defaultDialog(
                            title: "Clear Notifications",
                            middleText:
                                "Are you sure you want to delete all notifications?",
                            textConfirm: "Clear All",
                            textCancel: "Cancel",
                            confirmTextColor: Colors.white,
                            buttonColor: Colors.redAccent,
                            onConfirm: () {
                              _controller.clearAllNotifications();
                              Get.back();
                            },
                          );
                        },
                        onMarkAllRead: () {
                          _controller.markAllAsRead();
                        },
                      ),

                      //--------------------------------------------------
                      // FILTERS
                      //--------------------------------------------------
                      SizedBox(
                        height: 46,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: [
                            NotificationFilterChip(
                              label: "All",
                              icon: Icons.apps_rounded,
                              selected: _selectedFilter == 0,
                              onTap: () => setState(() => _selectedFilter = 0),
                            ),
                            NotificationFilterChip(
                              label: "AI Coach",
                              icon: Icons.smart_toy_rounded,
                              selected: _selectedFilter == 1,
                              onTap: () => setState(() => _selectedFilter = 1),
                            ),
                            NotificationFilterChip(
                              label: "Reminders",
                              icon: Icons.notifications_active_rounded,
                              selected: _selectedFilter == 2,
                              onTap: () => setState(() => _selectedFilter = 2),
                            ),
                            NotificationFilterChip(
                              label: "Achievements",
                              icon: Icons.workspace_premium_rounded,
                              selected: _selectedFilter == 3,
                              onTap: () => setState(() => _selectedFilter = 3),
                            ),
                            NotificationFilterChip(
                              label: "Plans",
                              icon: Icons.calendar_month_rounded,
                              selected: _selectedFilter == 4,
                              onTap: () => setState(() => _selectedFilter = 4),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      //--------------------------------------------------
                      // CONTENT
                      //--------------------------------------------------
                      if (isLoading && _controller.notifications.isEmpty)
                        const Padding(
                          padding: EdgeInsets.only(top: 100.0),
                          child: Center(
                            child: CircularProgressIndicator(
                              color: AppColors.primary,
                            ),
                          ),
                        )
                      else if (_controller.notifications.isEmpty)
                        // ✅ Wrapped in Center and Padding
                        const Padding(
                          padding: EdgeInsets.only(top: 100.0),
                          child: Center(child: NotificationEmptyState()),
                        )
                      else if (displayList.isEmpty)
                        // ✅ Wrapped in Center and Padding
                        const Padding(
                          padding: EdgeInsets.only(top: 100.0),
                          child: Center(
                            child: Text(
                              "No notifications found for this filter.",
                              style: TextStyle(color: AppColors.textSecondary),
                            ),
                          ),
                        )
                      else ...[
                        _buildSection("Today", displayList),
                        _buildSection("Yesterday", displayList),
                        _buildSection("Earlier", displayList),
                      ],

                      const SizedBox(height: 30),
                    ],
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
