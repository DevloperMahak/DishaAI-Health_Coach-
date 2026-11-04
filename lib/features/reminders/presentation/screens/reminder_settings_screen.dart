import 'package:disha_ai/features/reminders/data/models/reminder_settings_model.dart';
import 'package:disha_ai/features/reminders/data/services/reminder_service.dart';
import 'package:disha_ai/features/reminders/presentation/controller/reminder_settings_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/theme/app_colors.dart';

class ReminderSettingsScreen extends StatelessWidget {
  const ReminderSettingsScreen({super.key});

  // ============================================================
  // CONTROLLER
  // ============================================================

  ReminderSettingsController _controller() {
    if (Get.isRegistered<ReminderSettingsController>()) {
      return Get.find<ReminderSettingsController>();
    }

    return Get.put(ReminderSettingsController(service: ReminderService()));
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final controller = _controller();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.background,
        leading: IconButton(
          onPressed: Get.back,
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.primary,
          ),
        ),
        title: const Text(
          'Reminder Settings',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        child: Obx(() {
          final settings = controller.settings.value;

          // ----------------------------------------------------
          // INITIAL LOADING
          // ----------------------------------------------------

          if (controller.isLoading.value && settings == null) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          // ----------------------------------------------------
          // ERROR / EMPTY STATE
          // ----------------------------------------------------

          if (settings == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(.10),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.notifications_off_outlined,
                        color: AppColors.primary,
                        size: 30,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Unable to load reminder settings',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 7),
                    const Text(
                      'Please check your connection and try again.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 18),
                    OutlinedButton.icon(
                      onPressed: controller.fetchSettings,
                      icon: const Icon(Icons.refresh_rounded, size: 18),
                      label: const Text('Retry'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: BorderSide(
                          color: AppColors.primary.withOpacity(.35),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          // ----------------------------------------------------
          // CONTENT
          // ----------------------------------------------------

          return RefreshIndicator(
            color: AppColors.primary,
            backgroundColor: AppColors.surface,
            onRefresh: controller.fetchSettings,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 35),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 700),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ==================================================
                      // MASTER
                      // ==================================================
                      _MasterCard(
                        enabled: settings.remindersEnabled,
                        onChanged: controller.toggleMaster,
                      ),

                      const SizedBox(height: 20),

                      // ==================================================
                      // AI REMINDERS
                      // ==================================================
                      _section(
                        title: 'AI REMINDERS',
                        children: [
                          _SwitchTile(
                            icon: Icons.auto_awesome_rounded,
                            title: 'AI Smart Reminders',
                            subtitle:
                                'Allow Rhea AI to optimize reminder timing.',
                            value: settings.aiRemindersEnabled,
                            onChanged: controller.toggleAi,
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // ==================================================
                      // NOTIFICATION
                      // ==================================================
                      // _section(
                      //   title: 'NOTIFICATION',
                      //   children: [
                      //     _ChoiceTile(
                      //       icon: Icons.graphic_eq_rounded,
                      //       title: 'Sound',
                      //       value: _soundLabel(settings.sound),
                      //       onTap: () => _selectSound(
                      //         context,
                      //         controller,
                      //         settings.sound,
                      //       ),
                      //     ),
                      //     _SwitchTile(
                      //       icon: Icons.vibration_rounded,
                      //       title: 'Vibration',
                      //       subtitle: 'Vibrate for reminder notifications.',
                      //       value: settings.vibration,
                      //       onChanged: controller.toggleVibration,
                      //     ),
                      //     _ChoiceTile(
                      //       icon: Icons.snooze_rounded,
                      //       title: 'Default Snooze',
                      //       value: '${settings.defaultSnoozeMinutes} minutes',
                      //       onTap: () => _selectSnooze(
                      //         context,
                      //         controller,
                      //         settings.defaultSnoozeMinutes,
                      //       ),
                      //     ),
                      //   ],
                      // ),

                      // const SizedBox(height: 16),

                      // ==================================================
                      // QUIET HOURS
                      // ==================================================
                      // _section(
                      //   title: 'QUIET HOURS',
                      //   children: [
                      //     _SwitchTile(
                      //       icon: Icons.do_not_disturb_on_outlined,
                      //       title: 'Quiet Hours',
                      //       subtitle:
                      //           'Delay non-urgent reminders during this period.',
                      //       value: settings.quietHoursEnabled,
                      //       onChanged: controller.toggleQuietHours,
                      //     ),
                      //     if (settings.quietHoursEnabled) ...[
                      //       _ChoiceTile(
                      //         icon: Icons.bedtime_outlined,
                      //         title: 'Start',
                      //         value: settings.quietStart,
                      //         onTap: () => _selectTime(
                      //           context,
                      //           controller,
                      //           isStart: true,
                      //           current: settings.quietStart,
                      //         ),
                      //       ),
                      //       _ChoiceTile(
                      //         icon: Icons.wb_sunny_outlined,
                      //         title: 'End',
                      //         value: settings.quietEnd,
                      //         onTap: () => _selectTime(
                      //           context,
                      //           controller,
                      //           isStart: false,
                      //           current: settings.quietEnd,
                      //         ),
                      //       ),
                      //     ],
                      //   ],
                      // ),

                      // const SizedBox(height: 16),

                      // ==================================================
                      // DELIVERY CHANNELS
                      // ==================================================
                      _section(
                        title: 'DELIVERY CHANNELS',
                        children: [
                          _SwitchTile(
                            icon: Icons.notifications_active_outlined,
                            title: 'Push Notifications',
                            subtitle:
                                'Receive reminders even when the app is closed.',
                            value: settings.channels.contains('push'),
                            onChanged: controller.togglePushChannel,
                          ),
                          _SwitchTile(
                            icon: Icons.notifications_none_rounded,
                            title: 'In-App Notifications',
                            subtitle: 'Show reminders inside Rhea AI.',
                            value: settings.channels.contains('in_app'),
                            onChanged: controller.toggleInAppChannel,
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // ==================================================
                      // CATEGORIES
                      // ==================================================
                      _section(
                        title: 'REMINDER CATEGORIES',
                        children: [
                          _categoryTile(
                            controller,
                            settings,
                            'hydration',
                            'Hydration',
                            Icons.water_drop_rounded,
                          ),
                          _categoryTile(
                            controller,
                            settings,
                            'sleep',
                            'Sleep',
                            Icons.nightlight_round,
                          ),
                          _categoryTile(
                            controller,
                            settings,
                            'exercise',
                            'Exercise',
                            Icons.fitness_center_rounded,
                          ),
                          _categoryTile(
                            controller,
                            settings,
                            'meditation',
                            'Meditation',
                            Icons.self_improvement_rounded,
                          ),
                          _categoryTile(
                            controller,
                            settings,
                            'medication',
                            'Medication',
                            Icons.medication_rounded,
                          ),
                          _categoryTile(
                            controller,
                            settings,
                            'nutrition',
                            'Nutrition',
                            Icons.restaurant_rounded,
                          ),
                          _categoryTile(
                            controller,
                            settings,
                            'habit',
                            'Habits',
                            Icons.repeat_rounded,
                          ),
                          _categoryTile(
                            controller,
                            settings,
                            'goal',
                            'Goals',
                            Icons.flag_rounded,
                          ),
                          _categoryTile(
                            controller,
                            settings,
                            'custom',
                            'Custom',
                            Icons.edit_note_rounded,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  // ============================================================
  // CATEGORY TILE
  // ============================================================

  Widget _categoryTile(
    ReminderSettingsController controller,
    ReminderSettingsModel settings,
    String key,
    String title,
    IconData icon,
  ) {
    return _SwitchTile(
      icon: icon,
      title: title,
      subtitle: null,
      value: settings.categories[key] ?? true,
      onChanged: (value) {
        controller.toggleCategory(key, value);
      },
    );
  }

  // ============================================================
  // SOUND SELECTOR
  // ============================================================

  Future<void> _selectSound(
    BuildContext context,
    ReminderSettingsController controller,
    String current,
  ) async {
    const sounds = [
      'gentle_bell',
      'chime',
      'water_drop',
      'meditation_tone',
      'silent',
    ];

    final selected = await Get.bottomSheet<String>(
      _SelectionSheet<String>(
        title: 'Notification Sound',
        values: sounds,
        selected: current,
        labelBuilder: _soundLabel,
      ),
    );

    if (selected != null) {
      await controller.changeSound(selected);
    }
  }

  // ============================================================
  // SNOOZE SELECTOR
  // ============================================================

  Future<void> _selectSnooze(
    BuildContext context,
    ReminderSettingsController controller,
    int current,
  ) async {
    const values = [5, 10, 15, 30, 60];

    final selected = await Get.bottomSheet<int>(
      _SelectionSheet<int>(
        title: 'Default Snooze',
        values: values,
        selected: current,
        labelBuilder: (value) => '$value minutes',
      ),
    );

    if (selected != null) {
      await controller.changeDefaultSnooze(selected);
    }
  }

  // ============================================================
  // TIME SELECTOR
  // ============================================================

  Future<void> _selectTime(
    BuildContext context,
    ReminderSettingsController controller, {
    required bool isStart,
    required String current,
  }) async {
    final parts = current.split(':');

    final initial = TimeOfDay(
      hour: int.tryParse(parts.isNotEmpty ? parts[0] : '22') ?? 22,
      minute: int.tryParse(parts.length > 1 ? parts[1] : '00') ?? 0,
    );

    final picked = await showTimePicker(context: context, initialTime: initial);

    if (picked == null) {
      return;
    }

    final value =
        '${picked.hour.toString().padLeft(2, '0')}:'
        '${picked.minute.toString().padLeft(2, '0')}';

    if (isStart) {
      await controller.changeQuietHours(start: value);
    } else {
      await controller.changeQuietHours(end: value);
    }
  }

  // ============================================================
  // SOUND LABEL
  // ============================================================

  String _soundLabel(String value) {
    switch (value) {
      case 'gentle_bell':
        return 'Gentle Bell';

      case 'water_drop':
        return 'Water Drop';

      case 'meditation_tone':
        return 'Meditation Tone';

      case 'silent':
        return 'Silent';

      case 'chime':
        return 'Chime';

      default:
        return value;
    }
  }

  // ============================================================
  // SECTION
  // ============================================================

  Widget _section({required String title, required List<Widget> children}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: .8,
          ),
        ),
        const SizedBox(height: 9),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.primary.withOpacity(.12)),
          ),
          child: Column(children: _withDividers(children)),
        ),
      ],
    );
  }

  // ============================================================
  // DIVIDERS
  // ============================================================

  List<Widget> _withDividers(List<Widget> children) {
    final result = <Widget>[];

    for (var i = 0; i < children.length; i++) {
      result.add(children[i]);

      if (i != children.length - 1) {
        result.add(
          Divider(height: 1, color: AppColors.primary.withOpacity(.08)),
        );
      }
    }

    return result;
  }
}

// ==================================================================
// MASTER CARD
// ==================================================================

class _MasterCard extends StatelessWidget {
  const _MasterCard({required this.enabled, required this.onChanged});

  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary.withOpacity(.17), AppColors.surface],
        ),
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: AppColors.primary.withOpacity(.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.notifications_active_rounded,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 13),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Health Reminders',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Control all scheduled health reminders.',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: enabled,
            activeColor: AppColors.primary,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

// ==================================================================
// SWITCH TILE
// ==================================================================

class _SwitchTile extends StatelessWidget {
  const _SwitchTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 21),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    subtitle!,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11.5,
                      height: 1.35,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            activeColor: AppColors.primary,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

// ==================================================================
// CHOICE TILE
// ==================================================================

class _ChoiceTile extends StatelessWidget {
  const _ChoiceTile({
    required this.icon,
    required this.title,
    required this.value,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary, size: 21),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 5),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textSecondary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

// ==================================================================
// SELECTION SHEET
// ==================================================================

class _SelectionSheet<T> extends StatelessWidget {
  const _SelectionSheet({
    required this.title,
    required this.values,
    required this.selected,
    required this.labelBuilder,
  });

  final String title;
  final List<T> values;
  final T selected;
  final String Function(T value) labelBuilder;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 30),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
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
            Text(
              title,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            ...values.map(
              (value) => RadioListTile<T>(
                value: value,
                groupValue: selected,
                activeColor: AppColors.primary,
                title: Text(
                  labelBuilder(value),
                  style: const TextStyle(color: AppColors.textPrimary),
                ),
                onChanged: (value) {
                  if (value != null) {
                    Get.back(result: value);
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
