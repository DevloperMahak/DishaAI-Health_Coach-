import 'dart:async';

import 'package:disha_ai/app/theme/app_colors.dart';
import 'package:disha_ai/features/reminders/data/models/reminder_model.dart';
import 'package:disha_ai/features/reminders/data/services/reminder_service.dart';
// TODO: Make sure to import your LocalAlarmService here
import 'package:disha_ai/features/reminders/data/services/local_alarm_service.dart';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AlarmScreen extends StatefulWidget {
  const AlarmScreen({super.key, required this.reminder});

  final ReminderModel reminder;

  @override
  State<AlarmScreen> createState() => _AlarmScreenState();
}

class _AlarmScreenState extends State<AlarmScreen>
    with SingleTickerProviderStateMixin {
  // ============================================================
  // SERVICES
  // ============================================================

  final ReminderService _reminderService = ReminderService();

  // ============================================================
  // STATE
  // ============================================================

  bool _isCompleting = false;
  bool _isSnoozing = false;

  String? _errorMessage;

  // ============================================================
  // ANIMATION
  // ============================================================

  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  Timer? _clockTimer;

  DateTime _currentTime = DateTime.now();

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    // OPTIONAL: Keep the screen awake while the alarm is ringing
    // WakelockPlus.enable();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );

    _pulseAnimation = Tween<double>(begin: 0.96, end: 1.04).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _pulseController.repeat(reverse: true);

    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _currentTime = DateTime.now();
      });
    });
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    _pulseController.dispose();

    // OPTIONAL: Allow the screen to sleep normally again
    // WakelockPlus.disable();

    super.dispose();
  }

  // ============================================================
  // COMPLETE
  // ============================================================

  Future<void> _completeReminder() async {
    if (_isCompleting || _isSnoozing) {
      return;
    }

    setState(() {
      _isCompleting = true;
      _errorMessage = null;
    });

    try {
      debugPrint('🔔 Completing reminder: ${widget.reminder.reminderId}');

      // UPDATED: This marks it complete on the backend AND cancels the looping local alarm
      await LocalAlarmService.instance.completeReminder(
        widget.reminder.reminderId,
      );

      debugPrint('✅ Reminder completed: ${widget.reminder.reminderId}');

      if (!mounted) {
        return;
      }

      // The API guide specifies that after completion the frontend
      // should stop the alarm, dismiss the alarm screen and refresh
      // dashboard/streak information.
      Navigator.of(context).pop(true);
    } catch (e) {
      debugPrint('❌ Could not complete reminder: $e');

      if (!mounted) {
        return;
      }

      setState(() {
        _isCompleting = false;
        _errorMessage = _cleanError(e);
      });
    }
  }

  // ============================================================
  // SNOOZE
  // ============================================================

  Future<void> _snoozeReminder(int minutes) async {
    if (_isCompleting || _isSnoozing) {
      return;
    }

    setState(() {
      _isSnoozing = true;
      _errorMessage = null;
    });

    try {
      debugPrint(
        '😴 Snoozing reminder '
        '${widget.reminder.reminderId} '
        'for $minutes minutes',
      );

      // 1. Notify the backend
      await _reminderService.snoozeReminder(
        widget.reminder.reminderId,
        minutes,
      );

      // 2. UPDATED: Cancel the current ringing alarm and schedule the snooze locally
      await LocalAlarmService.instance.scheduleSnooze(
        reminder: widget.reminder,
        minutes: minutes,
      );

      debugPrint('✅ Reminder snoozed for $minutes minutes');

      if (!mounted) {
        return;
      }

      // The backend snooze endpoint is complete here.
      //
      // The local alarm service should additionally reschedule
      // the device alarm for +minutes.
      Navigator.of(context).pop(AlarmScreenResult.snoozed(minutes));
    } catch (e) {
      debugPrint('❌ Could not snooze reminder: $e');

      if (!mounted) {
        return;
      }

      setState(() {
        _isSnoozing = false;
        _errorMessage = _cleanError(e);
      });
    }
  }

  // ============================================================
  // SNOOZE SHEET
  // ============================================================

  Future<void> _showSnoozeOptions() async {
    if (_isCompleting || _isSnoozing) {
      return;
    }

    final selectedMinutes = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: false,
      builder: (context) {
        return _SnoozeBottomSheet(defaultMinutes: _defaultSnoozeMinutes);
      },
    );

    if (selectedMinutes == null) {
      return;
    }

    await _snoozeReminder(selectedMinutes);
  }

  // ============================================================
  // DEFAULT SNOOZE
  // ============================================================

  int get _defaultSnoozeMinutes {
    // Your reminder settings API supports default_snooze_minutes.
    //
    // AlarmScreen itself receives only ReminderModel, so the
    // currently selected/default value is not available here unless
    // the settings controller/service is also loaded.
    //
    // Keep 10 minutes as the alarm-guide default.
    return 10;
  }

  // ============================================================
  // ERROR CLEANUP
  // ============================================================

  String _cleanError(Object error) {
    final value = error.toString();

    if (value.startsWith('Exception: ')) {
      return value.substring('Exception: '.length);
    }

    return value;
  }

  // ============================================================
  // MODULE
  // ============================================================

  String get _module {
    return widget.reminder.module.trim().toLowerCase();
  }

  // ============================================================
  // MODULE TITLE
  // ============================================================

  String get _moduleTitle {
    switch (_module) {
      case 'sleep':
        return 'Sleep Reminder';

      case 'hydration':
        return 'Hydration Reminder';

      case 'exercise':
        return 'Exercise Reminder';

      case 'medication':
        return 'Medication Reminder';

      case 'meditation':
        return 'Meditation Reminder';

      case 'nutrition':
        return 'Nutrition Reminder';

      case 'habit':
        return 'Habit Reminder';

      case 'goal':
        return 'Goal Reminder';

      default:
        return 'RheaAI Reminder';
    }
  }

  // ============================================================
  // MODULE ICON
  // ============================================================

  IconData get _moduleIcon {
    switch (_module) {
      case 'sleep':
        return Icons.bedtime_rounded;

      case 'hydration':
        return Icons.water_drop_rounded;

      case 'exercise':
        return Icons.fitness_center_rounded;

      case 'medication':
        return Icons.medication_rounded;

      case 'meditation':
        return Icons.self_improvement_rounded;

      case 'nutrition':
        return Icons.restaurant_rounded;

      case 'habit':
        return Icons.check_circle_outline_rounded;

      case 'goal':
        return Icons.flag_rounded;

      default:
        return Icons.notifications_active_rounded;
    }
  }

  // ============================================================
  // MODULE COLOR
  // ============================================================

  Color get _moduleColor {
    // Keep the application within the existing RheaAI black/gold
    // visual language. Module differentiation is done subtly.
    return AppColors.primary;
  }

  // ============================================================
  // CLOCK
  // ============================================================

  String get _formattedTime {
    final hour = _currentTime.hour;

    final displayHour = hour == 0
        ? 12
        : hour > 12
        ? hour - 12
        : hour;

    final minute = _currentTime.minute.toString().padLeft(2, '0');

    final period = hour >= 12 ? 'PM' : 'AM';

    return '$displayHour:$minute$period';
  }

  // ============================================================
  // DATE
  // ============================================================

  String get _formattedDate {
    const months = <String>[
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    const weekdays = <String>[
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];

    // UPDATED: Fixed syntax error by adding `- 1` for 0-indexed arrays
    return '${weekdays[_currentTime.weekday - 1]}, '
        '${months[_currentTime.month - 1]} '
        '${_currentTime.day}';
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Stack(
            children: [
              const _BackgroundGlow(),

              Positioned.fill(
                child: Column(
                  children: [
                    _buildTopBar(),

                    Expanded(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(24, 12, 24, 30),
                        child: Column(
                          children: [
                            const SizedBox(height: 14),

                            _buildDate(),

                            const SizedBox(height: 8),

                            _buildClock(),

                            const SizedBox(height: 28),

                            _buildAlarmIcon(),

                            const SizedBox(height: 26),

                            _buildReminderContent(),

                            if (_errorMessage != null) ...[
                              const SizedBox(height: 20),
                              _buildError(),
                            ],

                            const SizedBox(height: 34),

                            _buildActionButtons(),

                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // TOP BAR
  // ============================================================

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 18, 22, 0),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.10),
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.25),
              ),
            ),
            child: Icon(
              Icons.notifications_active_rounded,
              color: AppColors.primary,
              size: 21,
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'RHEAAI',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2.2,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Active Reminder',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
            decoration: BoxDecoration(
              color: Colors.redAccent.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.redAccent.withValues(alpha: 0.28),
              ),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.circle, color: Colors.redAccent, size: 8),
                SizedBox(width: 6),
                Text(
                  'NOW',
                  style: TextStyle(
                    color: Colors.redAccent,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // DATE
  // ============================================================

  Widget _buildDate() {
    return Text(
      _formattedDate.toUpperCase(),
      textAlign: TextAlign.center,
      style: const TextStyle(
        color: Colors.white54,
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.8,
      ),
    );
  }

  // ============================================================
  // CLOCK
  // ============================================================

  Widget _buildClock() {
    return Text(
      _formattedTime,
      textAlign: TextAlign.center,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 48,
        fontWeight: FontWeight.w800,
        letterSpacing: -1.5,
        height: 1.05,
      ),
    );
  }

  // ============================================================
  // ALARM ICON
  // ============================================================

  Widget _buildAlarmIcon() {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(scale: _pulseAnimation.value, child: child);
      },
      child: Container(
        width: 112,
        height: 112,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              AppColors.primary.withValues(alpha: 0.28),
              AppColors.primary.withValues(alpha: 0.08),
              Colors.transparent,
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.18),
              blurRadius: 40,
              spreadRadius: 8,
            ),
          ],
        ),
        child: Container(
          margin: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.primary.withValues(alpha: 0.12),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.35),
              width: 1.4,
            ),
          ),
          child: Icon(_moduleIcon, color: _moduleColor, size: 42),
        ),
      ),
    );
  }

  // ============================================================
  // REMINDER CONTENT
  // ============================================================

  Widget _buildReminderContent() {
    final title = widget.reminder.title.trim().isNotEmpty
        ? widget.reminder.title.trim()
        : _moduleTitle;

    final message = widget.reminder.message.trim().isNotEmpty
        ? widget.reminder.message.trim()
        : _defaultMessage;

    return Column(
      children: [
        Text(
          _moduleTitle,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.primary,
            fontSize: 13,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.4,
          ),
        ),

        const SizedBox(height: 12),

        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.w800,
            height: 1.15,
          ),
        ),

        const SizedBox(height: 12),

        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white60,
              fontSize: 15,
              height: 1.55,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // DEFAULT MESSAGE
  // ============================================================

  String get _defaultMessage {
    switch (_module) {
      case 'sleep':
        return 'It is time to wind down and prepare for restful sleep.';

      case 'hydration':
        return 'Take a moment to drink some water and stay hydrated.';

      case 'exercise':
        return 'It is time to move your body and complete your activity.';

      case 'medication':
        return 'It is time for your medication reminder.';

      case 'meditation':
        return 'Take a few minutes to pause, breathe and reset.';

      case 'nutrition':
        return 'It is time to check in with your nutrition plan.';

      case 'habit':
        return 'Stay consistent with your healthy habit.';

      case 'goal':
        return 'Take the next step toward your goal.';

      default:
        return 'You have an active RheaAI reminder.';
    }
  }

  // ============================================================
  // ERROR
  // ============================================================

  Widget _buildError() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.redAccent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.redAccent.withValues(alpha: 0.20)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: Colors.redAccent,
            size: 20,
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Text(
              _errorMessage!,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ACTION BUTTONS
  // ============================================================

  Widget _buildActionButtons() {
    final busy = _isCompleting || _isSnoozing;

    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 58,
          child: ElevatedButton(
            onPressed: busy ? null : _completeReminder,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              disabledBackgroundColor: AppColors.primary.withValues(
                alpha: 0.35,
              ),
              foregroundColor: Colors.black,
              disabledForegroundColor: Colors.black54,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            child: _isCompleting
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      color: Colors.black,
                    ),
                  )
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_rounded, size: 24),
                      SizedBox(width: 9),
                      Text(
                        'MARK AS DONE',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
          ),
        ),

        const SizedBox(height: 12),

        SizedBox(
          width: double.infinity,
          height: 54,
          child: OutlinedButton(
            onPressed: busy ? null : _showSnoozeOptions,
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              disabledForegroundColor: Colors.white30,
              side: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            child: _isSnoozing
                ? const SizedBox(
                    width: 21,
                    height: 21,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: Colors.white,
                    ),
                  )
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.snooze_rounded, size: 22),
                      SizedBox(width: 9),
                      Text(
                        'SNOOZE',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.7,
                        ),
                      ),
                    ],
                  ),
          ),
        ),

        const SizedBox(height: 18),

        Text(
          'This reminder will stay active until you choose an action.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.38),
            fontSize: 11,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// BACKGROUND GLOW
// ============================================================================

class _BackgroundGlow extends StatelessWidget {
  const _BackgroundGlow();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: [
          Positioned(
            top: -180,
            left: -120,
            child: Container(
              width: 420,
              height: 420,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.primary.withValues(alpha: 0.10),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -200,
            right: -140,
            child: Container(
              width: 460,
              height: 460,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.primary.withValues(alpha: 0.06),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// SNOOZE BOTTOM SHEET
// ============================================================================

class _SnoozeBottomSheet extends StatelessWidget {
  const _SnoozeBottomSheet({required this.defaultMinutes});

  final int defaultMinutes;

  @override
  Widget build(BuildContext context) {
    const options = <int>[5, 10, 15, 30, 60];

    return SafeArea(
      top: false,
      child: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF111111),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(22, 12, 22, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(10),
              ),
            ),

            const SizedBox(height: 22),

            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.10),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.snooze_rounded,
                    color: AppColors.primary,
                    size: 22,
                  ),
                ),

                const SizedBox(width: 12),

                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Snooze reminder',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        'Choose when to remind you again',
                        style: TextStyle(color: Colors.white54, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 22),

            ...options.map((minutes) {
              final isDefault = minutes == defaultMinutes;

              return Padding(
                padding: const EdgeInsets.only(bottom: 9),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    Navigator.of(context).pop(minutes);
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 17,
                      vertical: 15,
                    ),
                    decoration: BoxDecoration(
                      color: isDefault
                          ? AppColors.primary.withValues(alpha: 0.10)
                          : Colors.white.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDefault
                            ? AppColors.primary.withValues(alpha: 0.28)
                            : Colors.white.withValues(alpha: 0.07),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.schedule_rounded,
                          color: isDefault ? AppColors.primary : Colors.white60,
                          size: 20,
                        ),

                        const SizedBox(width: 12),

                        Expanded(
                          child: Text(
                            _formatMinutes(minutes),
                            style: TextStyle(
                              color: isDefault ? Colors.white : Colors.white70,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),

                        if (isDefault)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'DEFAULT',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontSize: 8,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  String _formatMinutes(int minutes) {
    if (minutes == 60) {
      return '1 hour';
    }

    return '$minutes minutes';
  }
}

// ============================================================================
// RESULT
// ============================================================================

class AlarmScreenResult {
  const AlarmScreenResult._({required this.snoozed, this.minutes});

  final bool snoozed;
  final int? minutes;

  factory AlarmScreenResult.snoozed(int minutes) {
    return AlarmScreenResult._(snoozed: true, minutes: minutes);
  }
}
