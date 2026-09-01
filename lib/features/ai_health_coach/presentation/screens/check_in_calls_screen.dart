import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:disha_ai/features/ai_health_coach/presentation/controllers/ai_controller.dart';
import 'package:disha_ai/features/ai_health_coach/presentation/screens/rheaai_call_screen.dart';
import '../../../../app/theme/app_colors.dart';

class CheckInCallsScreen extends StatefulWidget {
  const CheckInCallsScreen({
    super.key,
    this.onStartCheckIn,
    this.onScheduleCheckIn,
    this.onBack,
  });

  final VoidCallback? onStartCheckIn;
  final VoidCallback? onScheduleCheckIn;
  final VoidCallback? onBack;

  @override
  State<CheckInCallsScreen> createState() => _CheckInCallsScreenState();
}

class _CheckInCallsScreenState extends State<CheckInCallsScreen> {
  // ==============================================================
  // CONTROLLER
  // ==============================================================
  AiController get _aiController {
    if (Get.isRegistered<AiController>()) {
      return Get.find<AiController>();
    }
    return Get.put(AiController());
  }

  // ==============================================================
  // STATE
  // ==============================================================
  bool checkInEnabled = true;
  String selectedScheduleDay = 'Every day';
  TimeOfDay selectedScheduleTime = const TimeOfDay(hour: 18, minute: 30);
  bool scheduleReminderEnabled = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchScheduleData();
    });
  }

  Future<void> _fetchScheduleData() async {
    final success = await _aiController.getCheckinSchedule();
    if (success && _aiController.checkinScheduleResponse.value?.data != null) {
      final data = _aiController.checkinScheduleResponse.value!.data;
      if (data is Map<String, dynamic>) {
        final timeStr = data['time']?.toString();
        final daysList = data['days'];

        if (timeStr != null && timeStr.contains(':')) {
          final parts = timeStr.split(':');
          final hour = int.tryParse(parts[0]) ?? 18;
          final minute = int.tryParse(parts[1]) ?? 30;
          setState(() {
            selectedScheduleTime = TimeOfDay(hour: hour, minute: minute);
          });
        }

        if (daysList is List && daysList.isNotEmpty) {
          if (daysList.length >= 5) {
            setState(() {
              selectedScheduleDay = 'Weekdays';
            });
          } else if (daysList.length == 7) {
            setState(() {
              selectedScheduleDay = 'Every day';
            });
          } else {
            setState(() {
              selectedScheduleDay =
                  daysList.first.toString().capitalizeFirst ?? 'Every day';
            });
          }
        }
      }
    }
  }

  // ==============================================================
  // RESPONSIVE HELPERS
  // ==============================================================

  double _scale(double width) {
    return (width / 390).clamp(.88, 1.15);
  }

  double _horizontalPadding(double width) {
    if (width < 340) return 16;
    if (width < 390) return 20;
    if (width < 600) return 24;
    if (width < 900) return 40;
    return 60;
  }

  // ==============================================================
  // BUILD
  // ==============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final scale = _scale(width);
            final padding = _horizontalPadding(width);

            return RefreshIndicator(
              color: AppColors.primary,
              backgroundColor: AppColors.surface,
              onRefresh: _fetchScheduleData,
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 700),
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        padding,
                        18 * scale,
                        padding,
                        30 * scale,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHeader(scale: scale),
                          SizedBox(height: 24 * scale),
                          _buildCheckInHero(scale: scale),
                          SizedBox(height: 24 * scale),
                          _buildNextCheckIn(scale: scale),
                          SizedBox(height: 24 * scale),
                          _buildRecentCheckIns(scale: scale),
                          SizedBox(height: 24 * scale),
                          _buildCheckInSettings(scale: scale),
                          SizedBox(height: 24 * scale),
                          _buildPrivacyNote(scale: scale),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // ==============================================================
  // HEADER
  // ==============================================================

  Widget _buildHeader({required double scale}) {
    return Row(
      children: [
        Material(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12 * scale),
          child: InkWell(
            borderRadius: BorderRadius.circular(12 * scale),
            onTap: widget.onBack ?? () => Get.back(),
            child: SizedBox(
              width: (44 * scale).clamp(40.0, 50.0),
              height: (44 * scale).clamp(40.0, 50.0),
              child: Icon(
                Icons.arrow_back_rounded,
                color: AppColors.textPrimary,
                size: 22 * scale,
              ),
            ),
          ),
        ),
        SizedBox(width: 14 * scale),
        Expanded(
          child: Text(
            'Check-in Calls',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: (22 * scale).clamp(20.0, 26.0),
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }

  // ==============================================================
  // HERO
  // ==============================================================

  Widget _buildCheckInHero({required double scale}) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(24 * scale),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(28 * scale),
        border: Border.all(color: AppColors.primary.withOpacity(.20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.22),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildAIAvatar(scale: scale),
          SizedBox(height: 20 * scale),
          Text(
            'Your daily check-in',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: (22 * scale).clamp(20.0, 26.0),
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 8 * scale),
          Text(
            'Take a few minutes to talk with RheaAI\nabout how you are feeling today.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: (12.5 * scale).clamp(11.0, 14.0),
              height: 1.5,
            ),
          ),
          SizedBox(height: 22 * scale),
          SizedBox(
            width: double.infinity,
            height: (52 * scale).clamp(48.0, 58.0),
            child: ElevatedButton.icon(
              onPressed: widget.onStartCheckIn ?? _startCheckIn,
              icon: Icon(Icons.call_rounded, size: 19 * scale),
              label: Text(
                'Start Check-in',
                style: TextStyle(
                  fontSize: (14 * scale).clamp(13.0, 16.0),
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.black,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12 * scale),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==============================================================
  // AI AVATAR
  // ==============================================================

  Widget _buildAIAvatar({required double scale}) {
    final outerSize = (118 * scale).clamp(100.0, 135.0);

    return Container(
      width: outerSize,
      height: outerSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.background,
        border: Border.all(
          color: AppColors.primary.withOpacity(.30),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(.10),
            blurRadius: 30,
            spreadRadius: 4,
          ),
        ],
      ),
      child: Center(
        child: Container(
          width: outerSize * .68,
          height: outerSize * .68,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.primary.withOpacity(.12),
          ),
          child: Icon(
            Icons.auto_awesome_rounded,
            color: AppColors.primary,
            size: outerSize * .32,
          ),
        ),
      ),
    );
  }

  // ==============================================================
  // NEXT CHECK-IN
  // ==============================================================

  Widget _buildNextCheckIn({required double scale}) {
    return _SectionCard(
      scale: scale,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(
            icon: Icons.schedule_rounded,
            title: 'Next Check-in',
            subtitle: 'Your upcoming AI conversation',
            scale: scale,
          ),
          SizedBox(height: 20 * scale),
          Container(
            padding: EdgeInsets.all(16 * scale),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(18 * scale),
              border: Border.all(color: AppColors.primary.withOpacity(.12)),
            ),
            child: Row(
              children: [
                Container(
                  width: (52 * scale).clamp(46.0, 58.0),
                  height: (52 * scale).clamp(46.0, 58.0),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primary.withOpacity(.12),
                  ),
                  child: Icon(
                    Icons.calendar_today_rounded,
                    color: AppColors.primary,
                    size: 23 * scale,
                  ),
                ),
                SizedBox(width: 14 * scale),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        selectedScheduleDay,
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: (15 * scale).clamp(14.0, 17.0),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 4 * scale),
                      Text(
                        _formatTime(selectedScheduleTime),
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: (12 * scale).clamp(11.0, 14.0),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 14 * scale),
          SizedBox(
            width: double.infinity,
            height: (44 * scale).clamp(40.0, 50.0),
            child: OutlinedButton(
              onPressed: widget.onScheduleCheckIn ?? _scheduleCheckIn,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: BorderSide(color: AppColors.primary.withOpacity(.45)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(11 * scale),
                ),
              ),
              child: Text(
                'Change Schedule',
                style: TextStyle(
                  fontSize: (12.5 * scale).clamp(11.0, 14.0),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==============================================================
  // RECENT CHECK-INS
  // ==============================================================

  Widget _buildRecentCheckIns({required double scale}) {
    return _SectionCard(
      scale: scale,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(
            icon: Icons.history_rounded,
            title: 'Recent Check-ins',
            subtitle: 'Your previous conversations',
            scale: scale,
          ),
          SizedBox(height: 20 * scale),
          const _CheckInHistoryItem(
            date: 'Yesterday',
            time: '6:32 PM',
            duration: '8 min',
            mood: 'Feeling good',
            scale: 1.0,
          ),
          SizedBox(height: 10 * scale),
          const _CheckInHistoryItem(
            date: 'Aug 6',
            time: '7:04 PM',
            duration: '6 min',
            mood: 'A little tired',
            scale: 1.0,
          ),
        ],
      ),
    );
  }

  // ==============================================================
  // CHECK-IN SETTINGS
  // ==============================================================

  Widget _buildCheckInSettings({required double scale}) {
    return _SectionCard(
      scale: scale,
      child: Row(
        children: [
          Container(
            width: (48 * scale).clamp(44.0, 54.0),
            height: (48 * scale).clamp(44.0, 54.0),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary.withOpacity(.12),
            ),
            child: Icon(
              Icons.notifications_active_rounded,
              color: AppColors.primary,
              size: 23 * scale,
            ),
          ),
          SizedBox(width: 14 * scale),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Daily Check-ins',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: (15 * scale).clamp(14.0, 17.0),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 4 * scale),
                Text(
                  'Receive a reminder for your daily call',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: (11.5 * scale).clamp(10.0, 13.0),
                  ),
                ),
              ],
            ),
          ),
          Transform.scale(
            scale: .85,
            child: Switch.adaptive(
              value: checkInEnabled,
              onChanged: (value) {
                setState(() {
                  checkInEnabled = value;
                });
              },
              activeColor: Colors.white,
              activeTrackColor: AppColors.primary,
              inactiveThumbColor: Colors.white,
              inactiveTrackColor: Colors.white.withOpacity(.35),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ],
      ),
    );
  }

  // ==============================================================
  // PRIVACY
  // ==============================================================

  Widget _buildPrivacyNote({required double scale}) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16 * scale),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.lock_outline_rounded,
              color: AppColors.textSecondary,
              size: 15 * scale,
            ),
            SizedBox(width: 7 * scale),
            Flexible(
              child: Text(
                'Your conversations are private and secure with RheaAI.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: (10.5 * scale).clamp(9.5, 12.0),
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==============================================================
  // SECTION HEADER
  // ==============================================================

  Widget _sectionHeader({
    required IconData icon,
    required String title,
    required String subtitle,
    required double scale,
  }) {
    return Row(
      children: [
        Container(
          width: (46 * scale).clamp(42.0, 52.0),
          height: (46 * scale).clamp(42.0, 52.0),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.primary.withOpacity(.12),
          ),
          child: Icon(icon, color: AppColors.primary, size: 22 * scale),
        ),
        SizedBox(width: 13 * scale),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: (17 * scale).clamp(16.0, 20.0),
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: 3 * scale),
              Text(
                subtitle,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: (11.5 * scale).clamp(10.0, 13.0),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ==============================================================
  // NAVIGATION & ACTIONS
  // ==============================================================

  void _startCheckIn() {
    Get.to(() => const RheaCheckInCallScreen());
  }

  void _scheduleCheckIn() {
    _showScheduleCheckInModal();
  }

  void _showScheduleCheckInModal() {
    String tempDay = selectedScheduleDay;
    TimeOfDay tempTime = selectedScheduleTime;
    bool tempReminder = scheduleReminderEnabled;

    Get.bottomSheet(
      StatefulBuilder(
        builder: (context, setModalState) {
          final mediaQuery = MediaQuery.of(context);
          final bottomPadding = mediaQuery.viewInsets.bottom;

          return Container(
            width: double.infinity,
            constraints: const BoxConstraints(maxWidth: 700),
            padding: EdgeInsets.fromLTRB(22, 12, 22, 20 + bottomPadding),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
            ),
            child: SafeArea(
              top: false,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 42,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(.18),
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),
                    Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(.10),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.edit_calendar_rounded,
                            color: AppColors.primary,
                            size: 23,
                          ),
                        ),
                        const SizedBox(width: 13),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Change Schedule',
                                style: TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 19,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              SizedBox(height: 3),
                              Text(
                                'Choose when Rhea AI checks in with you',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: Get.back,
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: const BoxDecoration(
                              color: AppColors.background,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close_rounded,
                              color: AppColors.textSecondary,
                              size: 19,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),
                    const Text(
                      'CHECK-IN DAYS',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children:
                          [
                            'Every day',
                            'Weekdays',
                            'Weekends',
                            'Monday',
                            'Tuesday',
                            'Wednesday',
                            'Thursday',
                            'Friday',
                            'Saturday',
                            'Sunday',
                          ].map((day) {
                            final isSelected = tempDay == day;

                            return GestureDetector(
                              onTap: () {
                                setModalState(() {
                                  tempDay = day;
                                });
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 13,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppColors.primary
                                      : AppColors.background,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isSelected
                                        ? AppColors.primary
                                        : AppColors.primary.withOpacity(.12),
                                  ),
                                ),
                                child: Text(
                                  day,
                                  style: TextStyle(
                                    color: isSelected
                                        ? Colors.black
                                        : AppColors.textPrimary,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                    ),
                    const SizedBox(height: 26),
                    const Text(
                      'CHECK-IN TIME',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: () async {
                        final pickedTime = await showTimePicker(
                          context: context,
                          initialTime: tempTime,
                          builder: (context, child) {
                            return Theme(
                              data: Theme.of(context).copyWith(
                                colorScheme: const ColorScheme.dark(
                                  primary: AppColors.primary,
                                  surface: AppColors.surface,
                                  onPrimary: Colors.black,
                                  onSurface: AppColors.textPrimary,
                                ),
                              ),
                              child: child!,
                            );
                          },
                        );

                        if (pickedTime != null) {
                          setModalState(() {
                            tempTime = pickedTime;
                          });
                        }
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(17),
                          border: Border.all(
                            color: AppColors.primary.withOpacity(.12),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(.10),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(
                                Icons.access_time_rounded,
                                color: AppColors.primary,
                                size: 23,
                              ),
                            ),
                            const SizedBox(width: 13),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _formatTime(tempTime),
                                    style: const TextStyle(
                                      color: AppColors.textPrimary,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  const Text(
                                    'Tap to change the time',
                                    style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 10.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.chevron_right_rounded,
                              color: AppColors.textSecondary,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: () async {
                          // Format time as HH:mm
                          final hourStr = tempTime.hour.toString().padLeft(
                            2,
                            '0',
                          );
                          final minuteStr = tempTime.minute.toString().padLeft(
                            2,
                            '0',
                          );
                          final formattedTime = '$hourStr:$minuteStr';

                          // Map day selection to API format
                          List<String> daysPayload = [];
                          switch (tempDay.toLowerCase()) {
                            case 'every day':
                              daysPayload = [
                                'monday',
                                'tuesday',
                                'wednesday',
                                'thursday',
                                'friday',
                                'saturday',
                                'sunday',
                              ];
                              break;
                            case 'weekdays':
                              daysPayload = [
                                'monday',
                                'tuesday',
                                'wednesday',
                                'thursday',
                                'friday',
                              ];
                              break;
                            case 'weekends':
                              daysPayload = ['saturday', 'sunday'];
                              break;
                            default:
                              daysPayload = [tempDay.toLowerCase()];
                              break;
                          }

                          // Call API via AiController
                          final success = await _aiController.scheduleCheckin(
                            time: formattedTime,
                            days: daysPayload,
                          );

                          if (success) {
                            setState(() {
                              selectedScheduleDay = tempDay;
                              selectedScheduleTime = tempTime;
                              scheduleReminderEnabled = tempReminder;
                            });

                            Get.back();

                            Get.snackbar(
                              'Schedule Updated',
                              '${tempDay} at ${_formatTimeOnly(tempTime)}',
                              snackPosition: SnackPosition.BOTTOM,
                              backgroundColor: AppColors.surface,
                              colorText: AppColors.textPrimary,
                              margin: const EdgeInsets.all(16),
                              borderRadius: 14,
                            );
                          } else {
                            Get.snackbar(
                              'Error',
                              _aiController.errorMessage.value.isNotEmpty
                                  ? _aiController.errorMessage.value
                                  : 'Failed to update schedule',
                              snackPosition: SnackPosition.BOTTOM,
                              backgroundColor: AppColors.surface,
                              colorText: Colors.redAccent,
                              margin: const EdgeInsets.all(16),
                              borderRadius: 14,
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.black,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        child: Obx(() {
                          if (_aiController.isSchedulingCheckin.value) {
                            return const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.black,
                              ),
                            );
                          }
                          return const Text(
                            'Save Schedule',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                            ),
                          );
                        }),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period • 5–10 minutes';
  }

  String _formatTimeOnly(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }
}

// ==================================================================
// SECTION CARD
// ==================================================================

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.child, required this.scale});

  final Widget child;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20 * scale),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(26 * scale),
        border: Border.all(color: AppColors.primary.withOpacity(.14)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.18),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

// ==================================================================
// HISTORY ITEM
// ==================================================================

class _CheckInHistoryItem extends StatelessWidget {
  const _CheckInHistoryItem({
    required this.date,
    required this.time,
    required this.duration,
    required this.mood,
    required this.scale,
  });

  final String date;
  final String time;
  final String duration;
  final String mood;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(14 * scale),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(17 * scale),
        border: Border.all(color: AppColors.primary.withOpacity(.10)),
      ),
      child: Row(
        children: [
          Container(
            width: (42 * scale).clamp(38.0, 48.0),
            height: (42 * scale).clamp(38.0, 48.0),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary.withOpacity(.10),
            ),
            child: Icon(
              Icons.call_rounded,
              color: AppColors.primary,
              size: 19 * scale,
            ),
          ),
          SizedBox(width: 12 * scale),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  date,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: (13 * scale).clamp(12.0, 15.0),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 3 * scale),
                Text(
                  '$time • $duration',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: (10.5 * scale).clamp(10.0, 12.0),
                  ),
                ),
              ],
            ),
          ),
          Flexible(
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: 9 * scale,
                vertical: 6 * scale,
              ),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(.08),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                mood,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: (9.5 * scale).clamp(8.5, 11.0),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
