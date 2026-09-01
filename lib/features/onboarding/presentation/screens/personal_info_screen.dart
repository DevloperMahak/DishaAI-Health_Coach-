import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../app/theme/app_colors.dart';
import '../../data/models/health_profile_model.dart';
import '../controllers/health_profile_controller.dart';
import '../widgets/onboarding_top_bar.dart';

class PersonalInfoScreen extends StatefulWidget {
  const PersonalInfoScreen({super.key});

  @override
  State<PersonalInfoScreen> createState() => _PersonalInfoScreenState();
}

class _PersonalInfoScreenState extends State<PersonalInfoScreen> {
  // ============================================================
  // ONBOARDING CONFIG
  // ============================================================

  static const int _currentStep = 2;
  static const int _totalSteps = 9;

  // ============================================================
  // CONTROLLER
  // ============================================================

  late final HealthProfileController _controller;

  // ============================================================
  // TEXT CONTROLLERS
  // ============================================================

  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();

  // ============================================================
  // STATE
  // ============================================================

  String? _selectedGender;
  bool _profileLoaded = false;

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    if (Get.isRegistered<HealthProfileController>()) {
      _controller = Get.find<HealthProfileController>();
    } else {
      _controller = Get.put(HealthProfileController());
    }

    _loadExistingProfile();
  }

  // ============================================================
  // LOAD EXISTING PROFILE
  // ============================================================

  Future<void> _loadExistingProfile() async {
    if (_profileLoaded) {
      return;
    }

    _profileLoaded = true;

    final existingProfile = _controller.healthProfile.value;

    if (existingProfile != null) {
      _populateFromProfile(existingProfile);
      return;
    }

    final success = await _controller.getHealthProfile();

    if (!mounted) {
      return;
    }

    if (!success) {
      return;
    }

    final profile = _controller.healthProfile.value;

    if (profile != null) {
      _populateFromProfile(profile);
    }
  }

  // ============================================================
  // POPULATE EXISTING PROFILE
  // ============================================================

  void _populateFromProfile(HealthProfileModel profile) {
    if (!mounted) {
      return;
    }

    setState(() {
      if (profile.name != null && profile.name!.trim().isNotEmpty) {
        _fullNameController.text = profile.name!;
      }

      if (profile.email != null && profile.email!.trim().isNotEmpty) {
        _emailController.text = profile.email!;
      }

      if (profile.gender != null) {
        _selectedGender = _displayGender(profile.gender!);
      }

      if (profile.heightCm != null) {
        _heightController.text = _formatNumber(profile.heightCm!);
      }

      if (profile.weightKg != null) {
        _weightController.text = _formatNumber(profile.weightKg!);
      }
    });
  }

  // ============================================================
  // DISPLAY GENDER
  // ============================================================

  String? _displayGender(String value) {
    final normalized = value.trim().toLowerCase();

    switch (normalized) {
      case 'male':
        return 'Male';
      case 'female':
        return 'Female';
      case 'other':
        return 'Other';
      case 'prefer not to say':
      case 'prefer_not_to_say':
      case 'prefer-not-to-say':
        return 'Prefer not to say';
      default:
        return null;
    }
  }

  // ============================================================
  // API GENDER VALUE
  // ============================================================

  String _apiGenderValue(String value) {
    switch (value) {
      case 'Male':
        return 'male';
      case 'Female':
        return 'female';
      case 'Other':
        return 'other';
      case 'Prefer not to say':
        return 'prefer_not_to_say';
      default:
        return value.toLowerCase();
    }
  }

  // ============================================================
  // FORMAT NUMBER
  // ============================================================

  String _formatNumber(double value) {
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }
    return value.toString();
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _dobController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  // ============================================================
  // RESPONSIVE SCALE
  // ============================================================

  double _scale(double width) {
    return (width / 390).clamp(0.88, 1.12);
  }

  // ============================================================
  // NEXT
  // ============================================================

  Future<void> _onNext() async {
    if (_controller.isSaving.value) {
      return;
    }

    FocusScope.of(context).unfocus();

    final name = _fullNameController.text.trim();
    final email = _emailController.text.trim();
    final dob = _dobController.text.trim();
    final heightText = _heightController.text.trim();
    final weightText = _weightController.text.trim();

    if (name.isEmpty) {
      _showError('Please enter your full name.'.tr);
      return;
    }

    if (email.isEmpty || !GetUtils.isEmail(email)) {
      _showError('Please enter a valid email address.'.tr);
      return;
    }

    if (dob.isEmpty) {
      _showError('Please select your date of birth.'.tr);
      return;
    }

    if (_selectedGender == null) {
      _showError('Please select your gender.'.tr);
      return;
    }

    if (heightText.isEmpty) {
      _showError('Please enter your height.'.tr);
      return;
    }

    final heightCm = double.tryParse(heightText);

    if (heightCm == null || heightCm <= 0 || heightCm < 50 || heightCm > 300) {
      _showError('Please enter a realistic height.'.tr);
      return;
    }

    if (weightText.isEmpty) {
      _showError('Please enter your weight.'.tr);
      return;
    }

    final weightKg = double.tryParse(weightText);

    if (weightKg == null || weightKg <= 0 || weightKg < 20 || weightKg > 500) {
      _showError('Please enter a realistic weight.'.tr);
      return;
    }

    final age = _calculateAgeFromDob(dob);

    if (age == null || age <= 0 || age > 120) {
      _showError('Please select a valid date of birth.'.tr);
      return;
    }

    final gender = _apiGenderValue(_selectedGender!);

    final success = await _controller.savePersonalInfo(
      name: name,
      email: email,
      age: age,
      gender: gender,
      heightCm: heightCm,
      weightKg: weightKg,
    );

    if (!mounted) {
      return;
    }

    if (!success) {
      final message = _controller.errorMessage.value.trim().isEmpty
          ? 'Unable to save your information.'.tr
          : _controller.errorMessage.value;

      _showError(message);
      return;
    }

    Get.toNamed(AppRoutes.healthCondition);
  }

  // ============================================================
  // CALCULATE AGE
  // ============================================================

  int? _calculateAgeFromDob(String dob) {
    try {
      final parts = dob.split('/');
      if (parts.length != 3) return null;

      final day = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      final year = int.parse(parts[2]);

      final birthDate = DateTime(year, month, day);

      if (birthDate.day != day ||
          birthDate.month != month ||
          birthDate.year != year) {
        return null;
      }

      final today = DateTime.now();

      if (birthDate.isAfter(today)) return null;

      int age = today.year - birthDate.year;
      final birthdayThisYear = DateTime(
        today.year,
        birthDate.month,
        birthDate.day,
      );

      if (today.isBefore(birthdayThisYear)) {
        age--;
      }

      return age;
    } catch (_) {
      return null;
    }
  }

  // ============================================================
  // ERROR
  // ============================================================

  void _showError(String message) {
    Get.snackbar(
      'Required'.tr,
      message,
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      backgroundColor: AppColors.surface,
      colorText: AppColors.textPrimary,
      borderColor: AppColors.primary,
      borderWidth: 1,
      duration: const Duration(seconds: 3),
    );
  }

  // ============================================================
  // DATE PICKER
  // ============================================================

  Future<void> _selectDateOfBirth() async {
    FocusScope.of(context).unfocus();

    final now = DateTime.now();
    DateTime initialDate = DateTime(now.year - 25, now.month, now.day);

    if (_dobController.text.isNotEmpty) {
      try {
        final parts = _dobController.text.split('/');
        if (parts.length == 3) {
          final day = int.parse(parts[0]);
          final month = int.parse(parts[1]);
          final year = int.parse(parts[2]);

          final parsedDate = DateTime(year, month, day);
          if (!parsedDate.isAfter(now)) {
            initialDate = parsedDate;
          }
        }
      } catch (_) {}
    }

    final firstDate = DateTime(now.year - 120, now.month, now.day);
    final lastDate = DateTime(now.year, now.month, now.day);

    final selectedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: AppColors.primary,
              surface: AppColors.surface,
            ),
          ),
          child: child!,
        );
      },
    );

    if (selectedDate == null || !mounted) return;

    final day = selectedDate.day.toString().padLeft(2, '0');
    final month = selectedDate.month.toString().padLeft(2, '0');
    final year = selectedDate.year.toString();

    setState(() {
      _dobController.text = '$day/$month/$year';
    });
  }

  // ============================================================
  // SKIP
  // ============================================================

  void _skipOnboarding() {
    FocusScope.of(context).unfocus();
    Get.toNamed(AppRoutes.healthCondition);
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final height = constraints.maxHeight;

            if (width >= 700 || width > height) {
              return _buildWideLayout(width: width, height: height);
            }

            return _buildPhoneLayout(width: width, height: height);
          },
        ),
      ),
    );
  }

  // ============================================================
  // PHONE
  // ============================================================

  Widget _buildPhoneLayout({required double width, required double height}) {
    final horizontalPadding = _getHorizontalPadding(width);

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: height),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              OnboardingTopBar(
                currentStep: _currentStep,
                totalSteps: _totalSteps,
                onBack: () => Get.back(),
                onSkip: _skipOnboarding,
              ),
              SizedBox(height: _spacing(width, 22)),
              _buildTitle(width: width),
              SizedBox(height: _spacing(width, 8)),
              _buildSubtitle(width: width),
              SizedBox(height: _spacing(width, 22)),
              _buildPersonalInfoForm(width: width),
              SizedBox(height: _spacing(width, 30)),
              _buildNextButton(width: width),
              SizedBox(height: _spacing(width, 22)),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // WIDE / TABLET
  // ============================================================

  Widget _buildWideLayout({required double width, required double height}) {
    final horizontalPadding = width >= 1200
        ? 100.0
        : width >= 900
        ? 70.0
        : 40.0;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 650),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: horizontalPadding,
            vertical: 30,
          ),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                OnboardingTopBar(
                  currentStep: _currentStep,
                  totalSteps: _totalSteps,
                  onBack: () => Get.back(),
                  onSkip: _skipOnboarding,
                ),
                const SizedBox(height: 30),
                _buildTitle(width: width),
                const SizedBox(height: 10),
                _buildSubtitle(width: width),
                const SizedBox(height: 30),
                _buildPersonalInfoForm(width: width),
                const SizedBox(height: 35),
                _buildNextButton(width: width),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // TITLE
  // ============================================================

  Widget _buildTitle({required double width}) {
    final scale = _scale(width);
    final fontSize = (21 * scale).clamp(19.0, 24.0);

    return Text(
      "Let's know more\nabout you".tr, // Translated
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: FontWeight.w700,
        color: AppColors.primary,
        height: 1.18,
      ),
    );
  }

  // ============================================================
  // SUBTITLE
  // ============================================================

  Widget _buildSubtitle({required double width}) {
    final scale = _scale(width);
    final fontSize = (12.5 * scale).clamp(11.5, 14.0);

    return Text(
      'This helps personalize your experience'.tr, // Translated
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: FontWeight.w400,
        color: AppColors.textSecondary,
        height: 1.4,
      ),
    );
  }

  // ============================================================
  // FORM
  // ============================================================

  Widget _buildPersonalInfoForm({required double width}) {
    final scale = _scale(width);
    final labelSize = (11 * scale).clamp(10.0, 13.0);
    final fieldSize = (12.5 * scale).clamp(11.5, 14.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel('Full Name'.tr, labelSize),
        const SizedBox(height: 6),
        _buildTextField(
          controller: _fullNameController,
          hintText: 'Enter your full name'.tr,
          fontSize: fieldSize,
          keyboardType: TextInputType.name,
          textCapitalization: TextCapitalization.words,
        ),
        SizedBox(height: _spacing(width, 18)),
        _buildFieldLabel('Email Address'.tr, labelSize),
        const SizedBox(height: 6),
        _buildTextField(
          controller: _emailController,
          hintText: 'Enter your email id'.tr,
          fontSize: fieldSize,
          keyboardType: TextInputType.emailAddress,
        ),
        SizedBox(height: _spacing(width, 18)),
        _buildFieldLabel('Date of Birth'.tr, labelSize),
        const SizedBox(height: 6),
        _buildTextField(
          controller: _dobController,
          hintText: 'DD/MM/YYYY',
          fontSize: fieldSize,
          readOnly: true,
          onTap: _selectDateOfBirth,
          suffixIcon: Icon(
            Icons.calendar_month_outlined,
            size: 17 * scale,
            color: AppColors.textSecondary,
          ),
        ),
        SizedBox(height: _spacing(width, 18)),
        _buildFieldLabel('Gender'.tr, labelSize),
        const SizedBox(height: 6),
        _buildGenderDropdown(fontSize: fieldSize),
        SizedBox(height: _spacing(width, 18)),
        _buildFieldLabel('Height'.tr, labelSize, suffix: 'cm'),
        const SizedBox(height: 6),
        _buildTextField(
          controller: _heightController,
          hintText: 'Enter your height'.tr,
          fontSize: fieldSize,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
        ),
        SizedBox(height: _spacing(width, 18)),
        _buildFieldLabel('Weight'.tr, labelSize, suffix: 'kg'),
        const SizedBox(height: 6),
        _buildTextField(
          controller: _weightController,
          hintText: 'Enter your weight'.tr,
          fontSize: fieldSize,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
        ),
      ],
    );
  }

  // ============================================================
  // LABEL
  // ============================================================

  Widget _buildFieldLabel(String label, double fontSize, {String? suffix}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w600,
            color: AppColors.primary,
          ),
        ),
        if (suffix != null)
          Text(
            suffix,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w400,
              color: AppColors.textSecondary,
            ),
          ),
      ],
    );
  }

  // ============================================================
  // TEXT FIELD
  // ============================================================

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required double fontSize,
    TextInputType? keyboardType,
    TextCapitalization textCapitalization = TextCapitalization.none,
    bool readOnly = false,
    VoidCallback? onTap,
    Widget? suffixIcon,
  }) {
    return SizedBox(
      height: 44,
      child: TextField(
        controller: controller,
        readOnly: readOnly,
        onTap: onTap,
        keyboardType: keyboardType,
        textCapitalization: textCapitalization,
        cursorColor: AppColors.primary,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w400,
          color: AppColors.textPrimary,
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(
            fontSize: fontSize,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w400,
          ),
          suffixIcon: suffixIcon,
          suffixIconConstraints: const BoxConstraints(
            minWidth: 42,
            minHeight: 42,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 13,
            vertical: 0,
          ),
          filled: true,
          fillColor: Colors.transparent,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(
              color: AppColors.primary.withOpacity(0.8),
              width: 1,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.2),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // GENDER
  // ============================================================

  Widget _buildGenderDropdown({required double fontSize}) {
    return SizedBox(
      height: 44,
      child: DropdownButtonFormField<String>(
        value: _selectedGender,
        dropdownColor: AppColors.surface,
        icon: const Icon(
          Icons.keyboard_arrow_down_rounded,
          color: AppColors.textSecondary,
        ),
        style: TextStyle(fontSize: fontSize, color: AppColors.textPrimary),
        decoration: InputDecoration(
          hintText: 'Select'.tr, // Translated
          hintStyle: TextStyle(
            fontSize: fontSize,
            color: AppColors.textSecondary,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 13,
            vertical: 0,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: AppColors.primary.withOpacity(0.8)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.2),
          ),
        ),
        items: [
          DropdownMenuItem(value: 'Male', child: Text('Male'.tr)),
          DropdownMenuItem(value: 'Female', child: Text('Female'.tr)),
          DropdownMenuItem(value: 'Other', child: Text('Other'.tr)),
          DropdownMenuItem(
            value: 'Prefer not to say',
            child: Text('Prefer not to say'.tr),
          ),
        ],
        onChanged: _controller.isSaving.value
            ? null
            : (value) {
                setState(() {
                  _selectedGender = value;
                });
              },
      ),
    );
  }

  // ============================================================
  // NEXT BUTTON
  // ============================================================

  Widget _buildNextButton({required double width}) {
    final scale = _scale(width);
    final buttonHeight = (48 * scale).clamp(46.0, 54.0);
    final fontSize = (13 * scale).clamp(12.0, 15.0);
    final radius = (8 * scale).clamp(7.0, 10.0);

    return Obx(() {
      final isSaving = _controller.isSaving.value;

      return SizedBox(
        width: double.infinity,
        height: buttonHeight,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            gradient: isSaving
                ? LinearGradient(
                    colors: [
                      AppColors.primary.withOpacity(0.45),
                      AppColors.primary.withOpacity(0.45),
                    ],
                  )
                : const LinearGradient(
                    colors: [AppColors.primaryDark, AppColors.primary],
                  ),
            boxShadow: isSaving
                ? null
                : [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.18),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: ElevatedButton(
            onPressed: isSaving ? null : _onNext,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              disabledBackgroundColor: Colors.transparent,
              foregroundColor: Colors.black,
              disabledForegroundColor: Colors.black,
              elevation: 0,
              shadowColor: Colors.transparent,
              padding: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(radius),
              ),
            ),
            child: isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.black,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Next'.tr, // Translated
                        style: TextStyle(
                          fontSize: fontSize,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                      SizedBox(width: 9 * scale),
                      Icon(
                        Icons.arrow_forward_rounded,
                        size: (17 * scale).clamp(15.0, 19.0),
                        color: Colors.black,
                      ),
                    ],
                  ),
          ),
        ),
      );
    });
  }

  // ============================================================
  // RESPONSIVE HELPERS
  // ============================================================

  double _getHorizontalPadding(double width) {
    if (width <= 340) return 16;
    if (width <= 380) return 20;
    if (width <= 430) return 22;
    return 28;
  }

  double _spacing(double width, double value) {
    return value * _scale(width);
  }
}
