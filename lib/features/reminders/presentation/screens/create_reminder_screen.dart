import 'package:disha_ai/features/reminders/presentation/controller/reminder_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/theme/app_colors.dart';
import '../../data/services/reminder_service.dart';

class CreateReminderScreen extends StatefulWidget {
  const CreateReminderScreen({super.key, this.initialModule});

  final String? initialModule;

  @override
  State<CreateReminderScreen> createState() => _CreateReminderScreenState();
}

class _CreateReminderScreenState extends State<CreateReminderScreen> {
  late final ReminderController _controller;

  final TextEditingController _titleController = TextEditingController();

  final TextEditingController _messageController = TextEditingController();

  String _module = 'hydration';
  String _type = 'interval';
  String _priority = 'normal';

  TimeOfDay _selectedTime = const TimeOfDay(hour: 18, minute: 0);

  int _intervalMinutes = 120;

  final Set<String> _selectedDays = <String>{};

  final List<String> _days = const [
    'MON',
    'TUE',
    'WED',
    'THU',
    'FRI',
    'SAT',
    'SUN',
  ];

  @override
  void initState() {
    super.initState();

    _module = _validModule(widget.initialModule)
        ? widget.initialModule!
        : 'hydration';

    _controller = Get.isRegistered<ReminderController>()
        ? Get.find<ReminderController>()
        : Get.put(ReminderController(service: ReminderService()));
  }

  bool _validModule(String? value) {
    const modules = [
      'hydration',
      'sleep',
      'exercise',
      'meditation',
      'medication',
      'nutrition',
      'custom',
      'goal',
      'habit',
    ];

    return value != null && modules.contains(value);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _selectTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );

    if (picked != null) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;

    final minute = time.minute.toString().padLeft(2, '0');

    final period = time.period == DayPeriod.am ? 'AM' : 'PM';

    return '$hour:$minute $period';
  }

  String _apiTime(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:'
        '${time.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _createReminder() async {
    if (_type == 'recurring' && _selectedDays.isEmpty) {
      _showError('Please select at least one day.');
      return;
    }

    if (_type == 'interval' && _intervalMinutes <= 0) {
      _showError('Please select a valid interval.');
      return;
    }

    final success = await _controller.createReminder(
      module: _module,
      type: _type,
      title: _titleController.text.trim().isEmpty
          ? null
          : _titleController.text.trim(),
      message: _messageController.text.trim().isEmpty
          ? null
          : _messageController.text.trim(),
      priority: _priority,
      time: _type == 'fixed_time' || _type == 'recurring'
          ? _apiTime(_selectedTime)
          : null,
      days: _type == 'recurring'
          ? _days.where((String day) => _selectedDays.contains(day)).toList()
          : null,
      intervalMinutes: _type == 'interval' ? _intervalMinutes : null,
    );

    if (success && mounted) {
      Get.back(result: true);

      Get.snackbar(
        'Reminder Created',
        'Your reminder has been scheduled successfully.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.surface,
        colorText: AppColors.textPrimary,
        margin: const EdgeInsets.all(16),
        borderRadius: 14,
      );
    }
  }

  void _showError(String message) {
    Get.snackbar(
      'Reminder',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.redAccent,
      colorText: Colors.white,
      margin: const EdgeInsets.all(16),
      borderRadius: 14,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          onPressed: Get.back,
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.primary,
          ),
        ),
        title: const Text(
          'Create Reminder',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        child: Obx(
          () => SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 35),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 700),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionTitle('What should we remind you about?'),
                    const SizedBox(height: 12),
                    _moduleSelector(),

                    const SizedBox(height: 24),

                    _sectionTitle('Reminder type'),
                    const SizedBox(height: 12),
                    _typeSelector(),

                    const SizedBox(height: 24),

                    _textField(
                      controller: _titleController,
                      label: 'Title',
                      hint: 'e.g. Drink Water',
                    ),

                    const SizedBox(height: 16),

                    _textField(
                      controller: _messageController,
                      label: 'Message',
                      hint: 'Optional notification message',
                      maxLines: 3,
                    ),

                    const SizedBox(height: 22),

                    _sectionTitle('Priority'),
                    const SizedBox(height: 10),
                    _prioritySelector(),

                    if (_type == 'fixed_time' || _type == 'recurring') ...[
                      const SizedBox(height: 22),
                      _sectionTitle('Time'),
                      const SizedBox(height: 10),
                      _timeSelector(),
                    ],

                    if (_type == 'recurring') ...[
                      const SizedBox(height: 22),
                      _sectionTitle('Repeat on'),
                      const SizedBox(height: 10),
                      _daySelector(),
                    ],

                    if (_type == 'interval') ...[
                      const SizedBox(height: 22),
                      _sectionTitle('Remind me every'),
                      const SizedBox(height: 10),
                      _intervalSelector(),
                    ],

                    if (_type == 'ai_smart') ...[
                      const SizedBox(height: 18),
                      _aiInfoCard(),
                    ],

                    if (_type == 'goal_based') ...[
                      const SizedBox(height: 18),
                      _goalInfoCard(),
                    ],

                    const SizedBox(height: 30),

                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: _controller.isSaving.value
                            ? null
                            : _createReminder,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.black,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        child: _controller.isSaving.value
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.black,
                                ),
                              )
                            : const Text(
                                'Create Reminder',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _moduleSelector() {
    const modules = [
      ('hydration', 'Hydration', Icons.water_drop),
      ('sleep', 'Sleep', Icons.nightlight_round),
      ('exercise', 'Exercise', Icons.fitness_center),
      ('meditation', 'Meditation', Icons.self_improvement),
      ('medication', 'Medication', Icons.medication),
      ('nutrition', 'Nutrition', Icons.restaurant),
      ('habit', 'Habit', Icons.repeat),
      ('goal', 'Goal', Icons.flag),
      ('custom', 'Custom', Icons.edit_note),
    ];

    return Wrap(
      spacing: 9,
      runSpacing: 9,
      children: modules.map((item) {
        final selected = _module == item.$1;

        return GestureDetector(
          onTap: () {
            setState(() {
              _module = item.$1;
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: selected
                  ? AppColors.primary.withOpacity(.14)
                  : AppColors.surface,
              borderRadius: BorderRadius.circular(13),
              border: Border.all(
                color: selected
                    ? AppColors.primary
                    : AppColors.primary.withOpacity(.13),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  item.$3,
                  size: 17,
                  color: selected ? AppColors.primary : AppColors.textSecondary,
                ),
                const SizedBox(width: 7),
                Text(
                  item.$2,
                  style: TextStyle(
                    color: selected
                        ? AppColors.primary
                        : AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _typeSelector() {
    const types = [
      ('fixed_time', 'Fixed Time'),
      ('recurring', 'Recurring'),
      ('interval', 'Interval'),
      ('ai_smart', 'AI Smart'),
      ('goal_based', 'Goal Based'),
    ];

    return Column(
      children: types.map((item) {
        final selected = _type == item.$1;

        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () {
              setState(() {
                _type = item.$1;
              });
            },
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: selected
                      ? AppColors.primary
                      : AppColors.primary.withOpacity(.12),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    selected
                        ? Icons.radio_button_checked
                        : Icons.radio_button_off,
                    color: selected
                        ? AppColors.primary
                        : AppColors.textSecondary,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    item.$2,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _prioritySelector() {
    const priorities = ['low', 'normal', 'high', 'urgent'];

    return Wrap(
      spacing: 8,
      children: priorities.map((String priority) {
        final selected = _priority == priority;

        return ChoiceChip(
          selected: selected,
          label: Text(priority.capitalizeFirst ?? priority),
          selectedColor: AppColors.primary.withOpacity(.16),
          backgroundColor: AppColors.surface,
          side: BorderSide(
            color: selected
                ? AppColors.primary
                : AppColors.primary.withOpacity(.12),
          ),
          labelStyle: TextStyle(
            color: selected ? AppColors.primary : AppColors.textSecondary,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
          onSelected: (_) {
            setState(() {
              _priority = priority;
            });
          },
        );
      }).toList(),
    );
  }

  Widget _timeSelector() {
    return InkWell(
      borderRadius: BorderRadius.circular(15),
      onTap: _selectTime,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(17),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: AppColors.primary.withOpacity(.14)),
        ),
        child: Row(
          children: [
            const Icon(Icons.schedule_rounded, color: AppColors.primary),
            const SizedBox(width: 12),
            Text(
              _formatTime(_selectedTime),
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
            const Spacer(),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _daySelector() {
    return Wrap(
      spacing: 7,
      runSpacing: 8,
      children: _days.map((String day) {
        final selected = _selectedDays.contains(day);

        return GestureDetector(
          onTap: () {
            setState(() {
              if (selected) {
                _selectedDays.remove(day);
              } else {
                _selectedDays.add(day);
              }
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected ? AppColors.primary : AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selected
                    ? AppColors.primary
                    : AppColors.primary.withOpacity(.12),
              ),
            ),
            child: Text(
              day.substring(0, 1),
              style: TextStyle(
                color: selected ? Colors.black : AppColors.textSecondary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _intervalSelector() {
    const intervals = [30, 60, 120, 180, 240];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: intervals.map((int value) {
        final selected = _intervalMinutes == value;

        final label = value < 60
            ? '$value min'
            : value == 60
            ? '1 hour'
            : '${value ~/ 60} hours';

        return ChoiceChip(
          selected: selected,
          label: Text(label),
          selectedColor: AppColors.primary.withOpacity(.16),
          backgroundColor: AppColors.surface,
          side: BorderSide(
            color: selected
                ? AppColors.primary
                : AppColors.primary.withOpacity(.12),
          ),
          labelStyle: TextStyle(
            color: selected ? AppColors.primary : AppColors.textSecondary,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
          onSelected: (_) {
            setState(() {
              _intervalMinutes = value;
            });
          },
        );
      }).toList(),
    );
  }

  Widget _aiInfoCard() {
    return _InfoCard(
      icon: Icons.auto_awesome_rounded,
      title: 'AI Smart Reminder',
      message:
          'Rhea AI can generate reminder times based on your routine and health module.',
    );
  }

  Widget _goalInfoCard() {
    return _InfoCard(
      icon: Icons.flag_rounded,
      title: 'Goal Based Reminder',
      message: 'This reminder can be linked to one of your health goals.',
    );
  }

  Widget _textField({
    required TextEditingController controller,
    required String label,
    required String hint,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: AppColors.textSecondary.withOpacity(.55),
            ),
            filled: true,
            fillColor: AppColors.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: AppColors.primary.withOpacity(.12)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: AppColors.primary.withOpacity(.12)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: AppColors.primary,
                width: 1.2,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: AppColors.textPrimary,
        fontSize: 14,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(.08),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppColors.primary.withOpacity(.18)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
