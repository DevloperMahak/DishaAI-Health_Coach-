import 'package:disha_ai/features/reminders/presentation/controller/reminder_controller.dart';
import 'package:disha_ai/features/reminders/presentation/screens/create_reminder_screen.dart';
import 'package:disha_ai/features/reminders/presentation/screens/reminder_settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/theme/app_colors.dart';
import '../../data/models/reminder_model.dart';
import '../../data/services/reminder_service.dart';

class RemindersScreen extends StatelessWidget {
  const RemindersScreen({super.key, this.initialModule});

  final String? initialModule;

  ReminderController _controller() {
    if (Get.isRegistered<ReminderController>()) {
      return Get.find<ReminderController>();
    }

    return Get.put(ReminderController(service: ReminderService()));
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller();

    if (initialModule != null && initialModule!.trim().isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        controller.selectedModule.value = initialModule!;
        controller.fetchReminders(module: initialModule);
      });
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.background,
        centerTitle: false,
        leading: IconButton(
          onPressed: Get.back,
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.primary,
          ),
        ),
        title: const Text(
          'Reminders',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Reminder Settings',
            onPressed: () {
              Get.to(() => const ReminderSettingsScreen());
            },
            icon: const Icon(Icons.settings_outlined, color: AppColors.primary),
          ),
          const SizedBox(width: 6),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.black,
        elevation: 4,
        onPressed: () async {
          final result = await Get.to(
            () => CreateReminderScreen(initialModule: initialModule),
          );

          if (result == true) {
            await controller.fetchReminders();
          }
        },
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'Add Reminder',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: controller.fetchReminders,
          child: Obx(() {
            if (controller.isLoading.value && controller.reminders.isEmpty) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              );
            }

            if (controller.errorMessage.value.isNotEmpty &&
                controller.reminders.isEmpty) {
              return _ErrorState(
                message: controller.errorMessage.value,
                onRetry: controller.fetchReminders,
              );
            }

            return CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                  sliver: SliverToBoxAdapter(
                    child: _ReminderHeader(
                      onSettingsTap: () {
                        Get.to(() => const ReminderSettingsScreen());
                      },
                    ),
                  ),
                ),

                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverToBoxAdapter(
                    child: _FilterBar(controller: controller),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 18)),

                if (controller.reminders.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _EmptyState(
                      onAddReminder: () async {
                        final result = await Get.to(
                          () => const CreateReminderScreen(),
                        );

                        if (result == true) {
                          await controller.fetchReminders();
                        }
                      },
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 110),
                    sliver: SliverList.separated(
                      itemCount: controller.reminders.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final reminder = controller.reminders[index];

                        return _ReminderCard(
                          reminder: reminder,
                          controller: controller,
                        );
                      },
                    ),
                  ),
              ],
            );
          }),
        ),
      ),
    );
  }
}

class _ReminderHeader extends StatelessWidget {
  const _ReminderHeader({required this.onSettingsTap});

  final VoidCallback onSettingsTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary.withOpacity(.18), AppColors.surface],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withOpacity(.25)),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(.13),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.notifications_active_outlined,
              color: AppColors.primary,
              size: 27,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Stay on track',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'Manage your personalized health reminders.',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12.5,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onSettingsTap,
            icon: const Icon(Icons.tune_rounded, color: AppColors.primary),
          ),
        ],
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({required this.controller});

  final ReminderController controller;

  @override
  Widget build(BuildContext context) {
    const modules = <String>[
      '',
      'hydration',
      'sleep',
      'exercise',
      'meditation',
      'medication',
      'nutrition',
      'habit',
      'goal',
      'custom',
    ];

    return Obx(
      () => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: modules.map((String module) {
            final selected = controller.selectedModule.value == module;

            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                selected: selected,
                label: Text(module.isEmpty ? 'All' : _moduleName(module)),
                selectedColor: AppColors.primary.withOpacity(.18),
                backgroundColor: AppColors.surface,
                side: BorderSide(
                  color: selected
                      ? AppColors.primary
                      : AppColors.primary.withOpacity(.14),
                ),
                labelStyle: TextStyle(
                  color: selected ? AppColors.primary : AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
                onSelected: (_) async {
                  controller.selectedModule.value = module;

                  await controller.fetchReminders(
                    module: module.isEmpty ? null : module,
                  );
                },
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  static String _moduleName(String module) {
    return module
        .replaceAll('_', ' ')
        .split(' ')
        .map(
          (String word) =>
              word.isEmpty ? word : word[0].toUpperCase() + word.substring(1),
        )
        .join(' ');
  }
}

class _ReminderCard extends StatelessWidget {
  const _ReminderCard({required this.reminder, required this.controller});

  final ReminderModel reminder;
  final ReminderController controller;

  @override
  Widget build(BuildContext context) {
    final icon = _iconForModule(reminder.module);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.primary.withOpacity(.14)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.05),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(.11),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: AppColors.primary, size: 23),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        reminder.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    _StatusBadge(status: reminder.status),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  reminder.scheduleText,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (reminder.message.trim().isNotEmpty) ...[
                  const SizedBox(height: 5),
                  Text(
                    reminder.message,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      height: 1.35,
                    ),
                  ),
                ],
                const SizedBox(height: 9),
                Row(
                  children: [
                    _SmallTag(icon: icon, label: reminder.displayModule),
                    const Spacer(),
                    PopupMenuButton<String>(
                      padding: EdgeInsets.zero,
                      icon: const Icon(
                        Icons.more_horiz_rounded,
                        color: AppColors.textSecondary,
                      ),
                      onSelected: (String value) async {
                        await _handleAction(context, value);
                      },
                      itemBuilder: (_) => [
                        if (reminder.isActive)
                          const PopupMenuItem(
                            value: 'pause',
                            child: Text('Pause'),
                          ),
                        if (reminder.isPaused)
                          const PopupMenuItem(
                            value: 'resume',
                            child: Text('Resume'),
                          ),
                        const PopupMenuItem(
                          value: 'snooze',
                          child: Text('Snooze'),
                        ),
                        const PopupMenuItem(
                          value: 'complete',
                          child: Text('Complete'),
                        ),
                        const PopupMenuItem(value: 'skip', child: Text('Skip')),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Text('Delete'),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleAction(BuildContext context, String action) async {
    switch (action) {
      case 'pause':
        await controller.pause(reminder);
        break;

      case 'resume':
        await controller.resume(reminder);
        break;

      case 'complete':
        await controller.complete(reminder);
        break;

      case 'skip':
        await controller.skip(reminder);
        break;

      case 'delete':
        await _confirmDelete(context);
        break;

      case 'snooze':
        await _showSnoozeSheet(context);
        break;
    }
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text(
          'Delete reminder?',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: const Text(
          'This reminder will be removed from your active reminders.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(onPressed: Get.back, child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await controller.delete(reminder);
    }
  }

  Future<void> _showSnoozeSheet(BuildContext context) async {
    final minutes = await Get.bottomSheet<int>(
      Container(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 30),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textSecondary.withOpacity(.3),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Snooze reminder',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 16),
            ...[5, 10, 15, 30, 60].map(
              (int value) => ListTile(
                leading: const Icon(
                  Icons.snooze_rounded,
                  color: AppColors.primary,
                ),
                title: Text(
                  '$value minutes',
                  style: const TextStyle(color: AppColors.textPrimary),
                ),
                onTap: () => Get.back(result: value),
              ),
            ),
          ],
        ),
      ),
      isScrollControlled: true,
    );

    if (minutes != null) {
      await controller.snooze(reminder, minutes);
    }
  }

  static IconData _iconForModule(String module) {
    switch (module) {
      case 'hydration':
        return Icons.water_drop_rounded;
      case 'sleep':
        return Icons.nightlight_round;
      case 'exercise':
        return Icons.fitness_center_rounded;
      case 'meditation':
        return Icons.self_improvement_rounded;
      case 'medication':
        return Icons.medication_rounded;
      case 'nutrition':
        return Icons.restaurant_rounded;
      case 'habit':
        return Icons.repeat_rounded;
      case 'goal':
        return Icons.flag_rounded;
      default:
        return Icons.notifications_active_rounded;
    }
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final Color color;

    switch (status) {
      case 'paused':
        color = Colors.orange;
        break;
      case 'completed':
        color = Colors.green;
        break;
      case 'snoozed':
        color = Colors.blue;
        break;
      default:
        color = AppColors.primary;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.capitalizeFirst ?? status,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _SmallTag extends StatelessWidget {
  const _SmallTag({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(.07),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppColors.primary),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onAddReminder});

  final VoidCallback onAddReminder;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 78,
              height: 78,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(.10),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.notifications_none_rounded,
                color: AppColors.primary,
                size: 38,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'No reminders yet',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 7),
            const Text(
              'Create a reminder to stay consistent with your health routine.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: onAddReminder,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Create Reminder'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.black,
                elevation: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: Colors.redAccent,
              size: 44,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
