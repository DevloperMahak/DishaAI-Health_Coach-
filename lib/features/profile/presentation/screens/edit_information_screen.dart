import 'package:disha_ai/features/onboarding/presentation/controllers/health_profile_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/theme/app_colors.dart';
import '../widgets/profile_save_button.dart';

class EditHealthDataScreen extends StatefulWidget {
  const EditHealthDataScreen({super.key});

  @override
  State<EditHealthDataScreen> createState() => _EditHealthDataScreenState();
}

class _EditHealthDataScreenState extends State<EditHealthDataScreen> {
  //------------------------------------------------------------
  // Controller
  //------------------------------------------------------------
  late final HealthProfileController _controller;

  //------------------------------------------------------------
  // Text Controllers
  //------------------------------------------------------------
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  final _targetWeightController = TextEditingController();
  final _sleepHoursController = TextEditingController();

  //------------------------------------------------------------
  // Dropdown / Selection State
  //------------------------------------------------------------
  String? _activityLevel;
  String? _stressLevel;
  String? _dietType;

  //------------------------------------------------------------
  // UI State
  //------------------------------------------------------------
  bool _hasChanges = false;
  bool _isSaving = false;

  //------------------------------------------------------------
  // Init
  //------------------------------------------------------------
  @override
  void initState() {
    super.initState();

    if (Get.isRegistered<HealthProfileController>()) {
      _controller = Get.find<HealthProfileController>();
    } else {
      _controller = Get.put(HealthProfileController());
    }

    _loadExistingData();
  }

  void _loadExistingData() {
    final profile = _controller.healthProfile.value;

    if (profile != null) {
      if (profile.heightCm != null) {
        _heightController.text = _formatNumber(profile.heightCm!);
      }
      if (profile.weightKg != null) {
        _weightController.text = _formatNumber(profile.weightKg!);
      }
      if (profile.targetWeightKg != null) {
        _targetWeightController.text = _formatNumber(profile.targetWeightKg!);
      }
      if (profile.sleepHoursTarget != null) {
        _sleepHoursController.text = _formatNumber(profile.sleepHoursTarget!);
      }

      _activityLevel = _displayActivityLevel(profile.activityLevel);
      _stressLevel = _displayStressLevel(profile.stressLevel);
      _dietType = _displayDietType(profile.dietType);
    }
  }

  //------------------------------------------------------------
  // Helpers
  //------------------------------------------------------------
  void _markChanged() {
    if (_hasChanges) return;
    setState(() {
      _hasChanges = true;
    });
  }

  String _formatNumber(double value) {
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }
    return value.toString();
  }

  // --- Activity Level Mapping ---
  String? _displayActivityLevel(String? value) {
    if (value == null) return null;
    switch (value.toLowerCase()) {
      case 'sedentary':
        return 'Sedentary';
      case 'lightly_active':
        return 'Lightly Active';
      case 'moderately_active':
        return 'Moderately Active';
      case 'very_active':
        return 'Very Active';
      case 'extra_active':
        return 'Extra Active';
      default:
        return 'Lightly Active';
    }
  }

  String _apiActivityLevel(String? value) {
    if (value == null) return 'lightly_active';
    return value.toLowerCase().replaceAll(' ', '_');
  }

  // --- Stress Level Mapping ---
  String? _displayStressLevel(String? value) {
    if (value == null) return null;
    switch (value.toLowerCase()) {
      case 'low':
        return 'Low';
      case 'medium':
        return 'Medium';
      case 'high':
        return 'High';
      default:
        return 'Medium';
    }
  }

  String _apiStressLevel(String? value) {
    if (value == null) return 'medium';
    return value.toLowerCase();
  }

  // --- Diet Type Mapping ---
  String? _displayDietType(String? value) {
    if (value == null) return null;
    switch (value.toLowerCase()) {
      case 'vegetarian':
        return 'Vegetarian';
      case 'vegan':
        return 'Vegan';
      case 'non_vegetarian':
      case 'non-vegetarian':
        return 'Non-Vegetarian';
      case 'pescatarian':
        return 'Pescatarian';
      case 'keto':
        return 'Keto';
      default:
        return 'Vegetarian';
    }
  }

  String _apiDietType(String? value) {
    if (value == null) return 'vegetarian';
    if (value == 'Non-Vegetarian') return 'non_vegetarian';
    return value.toLowerCase();
  }

  //------------------------------------------------------------
  // Save
  //------------------------------------------------------------
  void _showSuccessMessage() {
    Get.snackbar(
      "Success",
      "Health data updated successfully.",
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      backgroundColor: AppColors.surface,
      colorText: AppColors.textPrimary,
      borderColor: AppColors.primary,
      borderWidth: 1,
      icon: const Icon(Icons.check_circle, color: AppColors.primary),
      duration: const Duration(seconds: 2),
    );
  }

  void _showErrorMessage(String message) {
    Get.snackbar(
      "Error",
      message,
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      backgroundColor: AppColors.surface,
      colorText: AppColors.textPrimary,
      borderColor: Colors.redAccent,
      borderWidth: 1,
      duration: const Duration(seconds: 3),
    );
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();

    // 1. Parse Numbers
    final heightCm = double.tryParse(_heightController.text.trim()) ?? 0;
    final weightKg = double.tryParse(_weightController.text.trim()) ?? 0;
    final targetWeightKg =
        double.tryParse(_targetWeightController.text.trim()) ?? 0;
    final sleepHours = double.tryParse(_sleepHoursController.text.trim()) ?? 0;

    // 2. Validate
    if (heightCm < 50 || heightCm > 300) {
      _showErrorMessage("Please enter a realistic height (cm).");
      return;
    }
    if (weightKg < 20 || weightKg > 500) {
      _showErrorMessage("Please enter a realistic weight (kg).");
      return;
    }
    if (sleepHours < 2 || sleepHours > 16) {
      _showErrorMessage("Please enter realistic sleep hours (2-16).");
      return;
    }
    if (_activityLevel == null || _stressLevel == null || _dietType == null) {
      _showErrorMessage("Please select all dropdown options.");
      return;
    }

    setState(() {
      _isSaving = true;
    });

    // 3. Fetch existing profile to retain uneditable data (Personal Info)
    final profile = _controller.healthProfile.value;

    // 4. API Call
    final success = await _controller.updateHealthProfile(
      name: profile?.name ?? "User",
      age: profile?.age ?? 25,
      gender: profile?.gender ?? "other",
      heightCm: heightCm,
      weightKg: weightKg,
      targetWeightKg: targetWeightKg,
      activityLevel: _apiActivityLevel(_activityLevel),
      sleepHoursTarget: sleepHours,
      stressLevel: _apiStressLevel(_stressLevel),
      dietType: _apiDietType(_dietType),
      // Preserve existing arrays
      goals: profile?.goals ?? [],
      conditions: profile?.conditions ?? [],
      challenges: profile?.challenges ?? [],
      allergies: profile?.allergies ?? [],
      avoidedFoods: profile?.avoidedFoods ?? [],
      sleepQuality: profile?.sleepQuality ?? 'good',
    );

    if (!mounted) return;

    setState(() {
      _isSaving = false;
    });

    if (success) {
      setState(() {
        _hasChanges = false;
      });
      _showSuccessMessage();
    } else {
      final msg = _controller.errorMessage.value.trim().isEmpty
          ? "Failed to update health data."
          : _controller.errorMessage.value;
      _showErrorMessage(msg);
    }
  }

  //------------------------------------------------------------
  // Back Interceptor
  //------------------------------------------------------------
  Future<bool> _onBack() async {
    if (!_hasChanges) return true;

    final result = await showDialog<bool>(
      context: context,
      builder: (_) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          title: const Text(
            "Discard Changes?",
            style: TextStyle(color: AppColors.textPrimary),
          ),
          content: const Text(
            "You have unsaved changes to your health data.",
            style: TextStyle(color: AppColors.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text(
                "Cancel",
                style: TextStyle(color: AppColors.primary),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
              child: const Text("Discard"),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }

  //------------------------------------------------------------
  // Dispose
  //------------------------------------------------------------
  @override
  void dispose() {
    _heightController.dispose();
    _weightController.dispose();
    _targetWeightController.dispose();
    _sleepHoursController.dispose();
    super.dispose();
  }

  //------------------------------------------------------------
  // Build
  //------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_hasChanges,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final allow = await _onBack();
        if (allow && mounted) {
          Navigator.pop(context);
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          elevation: 0,
          centerTitle: true,
          backgroundColor: AppColors.background,
          leading: IconButton(
            onPressed: () async {
              final allow = await _onBack();
              if (allow && mounted) {
                Navigator.pop(context);
              }
            },
            icon: const Icon(
              Icons.arrow_back_ios_new,
              color: AppColors.primary,
            ),
          ),
          title: const Text(
            "Health Data",
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        body: LayoutBuilder(
          builder: (context, constraints) {
            final tablet = constraints.maxWidth >= 700;

            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.symmetric(
                horizontal: tablet ? 80 : 24,
                vertical: 24,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 650),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle("Body Metrics"),
                      const SizedBox(height: 16),

                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              label: "Height (cm)",
                              controller: _heightController,
                              icon: Icons.height,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildTextField(
                              label: "Weight (kg)",
                              controller: _weightController,
                              icon: Icons.monitor_weight_outlined,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      _buildTextField(
                        label: "Target Weight (kg)",
                        controller: _targetWeightController,
                        icon: Icons.track_changes,
                      ),

                      const SizedBox(height: 32),
                      _buildSectionTitle("Lifestyle & Diet"),
                      const SizedBox(height: 16),

                      _buildDropdown(
                        label: "Activity Level",
                        value: _activityLevel,
                        icon: Icons.directions_run,
                        items: [
                          "Sedentary",
                          "Lightly Active",
                          "Moderately Active",
                          "Very Active",
                          "Extra Active",
                        ],
                        onChanged: (val) {
                          setState(() => _activityLevel = val);
                          _markChanged();
                        },
                      ),
                      const SizedBox(height: 16),

                      _buildDropdown(
                        label: "Diet Type",
                        value: _dietType,
                        icon: Icons.restaurant,
                        items: [
                          "Vegetarian",
                          "Vegan",
                          "Non-Vegetarian",
                          "Pescatarian",
                          "Keto",
                        ],
                        onChanged: (val) {
                          setState(() => _dietType = val);
                          _markChanged();
                        },
                      ),

                      const SizedBox(height: 32),
                      _buildSectionTitle("Wellness & Sleep"),
                      const SizedBox(height: 16),

                      _buildTextField(
                        label: "Sleep Target (Hours)",
                        controller: _sleepHoursController,
                        icon: Icons.bedtime_outlined,
                      ),
                      const SizedBox(height: 16),

                      _buildDropdown(
                        label: "Stress Level",
                        value: _stressLevel,
                        icon: Icons.spa_outlined,
                        items: ["Low", "Medium", "High"],
                        onChanged: (val) {
                          setState(() => _stressLevel = val);
                          _markChanged();
                        },
                      ),

                      const SizedBox(height: 48),

                      ProfileSaveButton(
                        isLoading: _isSaving,
                        onPressed: _hasChanges ? _save : null,
                        text: "Save Health Data",
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  //------------------------------------------------------------
  // UI Reusable Widgets
  //------------------------------------------------------------
  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: AppColors.primary,
        fontSize: 16,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 48,
          child: TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (_) => _markChanged(),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: AppColors.textSecondary, size: 20),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              filled: true,
              fillColor: AppColors.surface,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(
                  color: AppColors.primary,
                  width: 1.5,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown({
    required String label,
    required String? value,
    required IconData icon,
    required List<String> items,
    required void Function(String?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 48,
          child: DropdownButtonFormField<String>(
            value: value,
            dropdownColor: AppColors.surface,
            icon: const Icon(
              Icons.keyboard_arrow_down,
              color: AppColors.textSecondary,
            ),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: AppColors.textSecondary, size: 20),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              filled: true,
              fillColor: AppColors.surface,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(
                  color: AppColors.primary,
                  width: 1.5,
                ),
              ),
            ),
            items: items.map((item) {
              return DropdownMenuItem(value: item, child: Text(item));
            }).toList(),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}
