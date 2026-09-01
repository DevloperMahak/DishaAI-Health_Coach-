import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import 'package:disha_ai/features/profile/presentation/controllers/profile_controller.dart';
import 'package:disha_ai/features/onboarding/presentation/controllers/health_profile_controller.dart';
import 'package:disha_ai/features/authentication/presentation/controllers/auth_controller.dart';
import '../../../../app/theme/app_colors.dart';
import '../widgets/editable_text_tile.dart';
import '../widgets/phone_number_tile.dart';
import '../widgets/profile_save_button.dart';

class EditPersonalInformationScreen extends StatefulWidget {
  const EditPersonalInformationScreen({super.key});

  @override
  State<EditPersonalInformationScreen> createState() =>
      _EditPersonalInformationScreenState();
}

class _EditPersonalInformationScreenState
    extends State<EditPersonalInformationScreen> {
  //------------------------------------------------------------
  // Controllers
  //------------------------------------------------------------
  ProfileController get _profileController {
    if (Get.isRegistered<ProfileController>()) {
      return Get.find<ProfileController>();
    }
    return Get.put(ProfileController());
  }

  HealthProfileController get _healthProfileController {
    if (Get.isRegistered<HealthProfileController>()) {
      return Get.find<HealthProfileController>();
    }
    return Get.put(HealthProfileController());
  }

  AuthController get _authController {
    if (Get.isRegistered<AuthController>()) {
      return Get.find<AuthController>();
    }
    return Get.put(AuthController());
  }

  final ImagePicker _imagePicker = ImagePicker();

  //------------------------------------------------------------
  // Text Controllers
  //------------------------------------------------------------
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _mobileController = TextEditingController();

  //------------------------------------------------------------
  // Data
  //------------------------------------------------------------
  String _gender = "Female";
  bool _hasChanges = false;
  bool _isSaving = false;
  bool _isUploadingPhoto = false;
  File? _selectedImageFile;

  //------------------------------------------------------------
  // Init
  //------------------------------------------------------------
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _profileController.fetchProfile();
      if (_healthProfileController.healthProfile.value == null) {
        await _healthProfileController.getHealthProfile();
      }
      _populateInitialFields();
    });
  }

  void _populateInitialFields() {
    final apiProfile = _profileController.profile.value;
    final healthProfile = _healthProfileController.healthProfile.value;
    final authUser = _authController.currentUser.value;

    String? clean(String? val) {
      if (val == null) return null;
      final trimmed = val.trim();
      if (trimmed.isEmpty || trimmed.toLowerCase() == 'user') return null;
      return trimmed;
    }

    final resolvedName =
        clean(apiProfile?.name) ??
        clean(healthProfile?.name) ??
        clean(authUser?['name']?.toString()) ??
        clean(authUser?['full_name']?.toString()) ??
        '';

    final resolvedEmail =
        clean(apiProfile?.email) ??
        clean(healthProfile?.email) ??
        clean(authUser?['email']?.toString()) ??
        '';

    final resolvedMobile =
        clean(healthProfile?.mobile) ??
        clean(authUser?['mobile']?.toString()) ??
        clean(authUser?['phone']?.toString()) ??
        '';

    if (_nameController.text.isEmpty) _nameController.text = resolvedName;
    if (_emailController.text.isEmpty) _emailController.text = resolvedEmail;
    if (_mobileController.text.isEmpty) _mobileController.text = resolvedMobile;

    final genderStr = healthProfile?.gender;
    if (genderStr != null) {
      final displayGen = _displayGender(genderStr);
      if (displayGen != null &&
          ["Male", "Female", "Other"].contains(displayGen)) {
        setState(() {
          _gender = displayGen;
        });
      }
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

  String? _displayGender(String value) {
    final normalized = value.trim().toLowerCase();
    switch (normalized) {
      case 'male':
        return 'Male';
      case 'female':
        return 'Female';
      case 'other':
        return 'Other';
      default:
        return null;
    }
  }

  String _apiGenderValue(String value) {
    return value.toLowerCase();
  }

  //------------------------------------------------------------
  // Profile Photo Picker & Uploader
  //------------------------------------------------------------
  Future<void> _pickAndUploadPhoto() async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (pickedFile == null) return;

      setState(() {
        _selectedImageFile = File(pickedFile.path);
        _isUploadingPhoto = true;
      });

      final success = await _profileController.uploadPhoto(_selectedImageFile!);
      await _profileController.fetchProfile();

      if (!mounted) return;

      setState(() {
        _isUploadingPhoto = false;
        _hasChanges = true;
      });

      if (success) {
        Get.snackbar(
          "Success",
          "Profile photo updated successfully.",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.surface,
          colorText: AppColors.textPrimary,
          borderColor: AppColors.primary,
          borderWidth: 1,
        );
      } else {
        _showErrorMessage(
          _profileController.errorMessage.value.isNotEmpty
              ? _profileController.errorMessage.value
              : "Failed to upload photo.",
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isUploadingPhoto = false;
      });
      _showErrorMessage("Error selecting image: $e");
    }
  }

  //------------------------------------------------------------
  // Save Profile Details
  //------------------------------------------------------------
  void _showSuccessMessage() {
    Get.snackbar(
      "Success",
      "Personal information updated successfully.",
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

    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final mobile = _mobileController.text.trim();

    if (name.isEmpty) {
      _showErrorMessage("Full name cannot be empty.");
      return;
    }

    if (email.isEmpty || !GetUtils.isEmail(email)) {
      _showErrorMessage("Please enter a valid email address.");
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final profileSuccess = await _profileController.updateProfile(
      name: name,
      email: email,
    );

    final healthProfile = _healthProfileController.healthProfile.value;
    final healthSuccess = await _healthProfileController.savePersonalInfo(
      name: name,
      email: email,
      mobile: mobile,
      age: healthProfile?.age ?? 25,
      gender: _apiGenderValue(_gender),
      heightCm: healthProfile?.heightCm ?? 160.0,
      weightKg: healthProfile?.weightKg ?? 60.0,
    );

    // 💡 FORCE SYNC: Refresh both controllers instantly so UI updates everywhere
    await Future.wait([
      _profileController.fetchProfile(),
      _healthProfileController.getHealthProfile(),
    ]);

    if (!mounted) return;

    setState(() {
      _isSaving = false;
    });

    if (profileSuccess || healthSuccess) {
      setState(() {
        _hasChanges = false;
        _selectedImageFile = null;
      });
      _showSuccessMessage();

      // Optional: Automatically pop back after successful save
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) Navigator.pop(context, true);
    } else {
      final msg = _profileController.errorMessage.value.trim().isNotEmpty
          ? _profileController.errorMessage.value
          : "Failed to update profile.";
      _showErrorMessage(msg);
    }
  }

  //------------------------------------------------------------
  // Back Confirmation
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
            "You have unsaved changes.",
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
    _nameController.dispose();
    _emailController.dispose();
    _mobileController.dispose();
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
            "Personal Information",
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        body: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final tablet = width >= 700;

            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.symmetric(
                horizontal: tablet ? 60 : 20,
                vertical: 24,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 700),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Profile Image with Upload Trigger & Network Image Fallback
                      Center(
                        child: GestureDetector(
                          onTap: _pickAndUploadPhoto,
                          child: Stack(
                            children: [
                              Obx(() {
                                final apiProfile =
                                    _profileController.profile.value;
                                String? netPhoto = apiProfile?.profilePhoto;

                                if (netPhoto != null &&
                                    netPhoto.trim().isNotEmpty) {
                                  final trimmed = netPhoto.trim();
                                  if (!trimmed.startsWith('http')) {
                                    netPhoto =
                                        'https://rhea-ai.acttconnect.com${trimmed.startsWith('/') ? '' : '/'}$trimmed';
                                  }
                                }

                                ImageProvider? imageProvider;
                                if (_selectedImageFile != null) {
                                  imageProvider = FileImage(
                                    _selectedImageFile!,
                                  );
                                } else if (netPhoto != null) {
                                  imageProvider = NetworkImage(netPhoto);
                                } else {
                                  imageProvider = const AssetImage(
                                    "assets/images/Profile.png",
                                  );
                                }

                                return CircleAvatar(
                                  radius: tablet ? 58 : 48,
                                  backgroundColor: AppColors.surface,
                                  backgroundImage: imageProvider,
                                );
                              }),
                              if (_isUploadingPhoto)
                                Positioned.fill(
                                  child: Container(
                                    decoration: const BoxDecoration(
                                      color: Colors.black54,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Center(
                                      child: SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                          color: AppColors.primary,
                                          strokeWidth: 2,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: const BoxDecoration(
                                    color: AppColors.primary,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.camera_alt,
                                    color: Colors.black,
                                    size: 18,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),

                      // Form Fields
                      EditableTextTile(
                        title: "Full Name",
                        controller: _nameController,
                        icon: Icons.person,
                        hintText: "Enter name",
                        onChanged: (_) => _markChanged(),
                      ),
                      PhoneNumberTile(
                        controller: _mobileController,
                        onChanged: (_) => _markChanged(),
                      ),
                      EditableTextTile(
                        title: "Email Address",
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        icon: Icons.email_outlined,
                        hintText: "Enter email address",
                        onChanged: (_) => _markChanged(),
                      ),

                      const SizedBox(height: 8),

                      // Gender
                      const Text(
                        "Gender",
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: ["Male", "Female", "Other"].map((gender) {
                          final selected = gender == _gender;
                          return ChoiceChip(
                            label: Text(gender),
                            selected: selected,
                            onSelected: (_) {
                              setState(() {
                                _gender = gender;
                              });
                              _markChanged();
                            },
                            selectedColor: AppColors.primary,
                            backgroundColor: AppColors.surface,
                            labelStyle: TextStyle(
                              color: selected
                                  ? Colors.black
                                  : AppColors.textPrimary,
                            ),
                            side: const BorderSide(color: AppColors.border),
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: 40),

                      // Save Button
                      ProfileSaveButton(
                        isLoading: _isSaving,
                        onPressed: (_hasChanges || _selectedImageFile != null)
                            ? _save
                            : null,
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
}
