import 'package:disha_ai/features/profile/presentation/controllers/settings_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../../app/theme/app_colors.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // ==============================================================
  // CONTROLLER
  // ==============================================================
  SettingsController get _settingsController {
    if (Get.isRegistered<SettingsController>()) {
      return Get.find<SettingsController>();
    }
    return Get.put(SettingsController());
  }

  // ==============================================================
  // LOCAL UI STATE (Synced with Controller)
  // ==============================================================
  bool _pushNotifications = true;
  bool _microphoneAccess = false;
  String _selectedLanguage = 'en';
  String _selectedUnitSystem = 'metric';
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _settingsController.fetchSettings();
      _syncWithController();
    });
  }

  void _syncWithController() {
    final current = _settingsController.settings.value;
    if (current != null && mounted) {
      setState(() {
        _pushNotifications = current.pushNotifications;
        _microphoneAccess = current.microphoneAccess;
        _selectedLanguage = current.preferredLanguage;
        _selectedUnitSystem = current.unitSystem;
        _isInitialized = true;
      });
    }
  }

  // ==============================================================
  // UPDATE API CALL HELPER
  // ==============================================================
  Future<void> _updateSettings({
    String? language,
    bool? pushNotifications,
    bool? microphoneAccess,
    String? unitSystem,
  }) async {
    final lang = language ?? _selectedLanguage;
    final push = pushNotifications ?? _pushNotifications;
    final mic = microphoneAccess ?? _microphoneAccess;
    final unit = unitSystem ?? _selectedUnitSystem;

    final success = await _settingsController.updateSettings(
      preferredLanguage: lang,
      pushNotifications: push,
      microphoneAccess: mic,
      unitSystem: unit,
    );

    if (success && mounted) {
      _syncWithController(); // Ensure local state fully syncs with controller response model

      Get.snackbar(
        "Settings Updated".tr,
        "Your preferences have been saved successfully.".tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.surface,
        colorText: AppColors.textPrimary,
        margin: const EdgeInsets.all(16),
        borderRadius: 14,
      );
    } else {
      Get.snackbar(
        "Error".tr,
        _settingsController.errorMessage.value.isNotEmpty
            ? _settingsController.errorMessage.value
            : "Failed to update settings.".tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.surface,
        colorText: Colors.redAccent,
        margin: const EdgeInsets.all(16),
        borderRadius: 14,
      );
    }
  }

  // ==============================================================
  // BUILD
  // ==============================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        backgroundColor: AppColors.background,
        leading: IconButton(
          onPressed: () => Get.back(),
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.primary,
          ),
        ),
        title: Text(
          "Settings".tr,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Obx(() {
        if (!_isInitialized && _settingsController.settings.value != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _syncWithController();
          });
        }

        if (_settingsController.isLoading.value && !_isInitialized) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }

        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 700),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader("Preferences".tr),
                  const SizedBox(height: 12),

                  // Language Tile
                  _buildTileContainer(
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      leading: const Icon(
                        Icons.language_rounded,
                        color: AppColors.primary,
                      ),
                      title: Text(
                        "Preferred Language".tr,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        _selectedLanguage == 'hi'
                            ? 'Hindi (हिंदी)'
                            : _selectedLanguage == 'es'
                            ? 'Spanish (Español)'
                            : 'English (EN)',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      trailing: DropdownButton<String>(
                        value: _selectedLanguage,
                        dropdownColor: AppColors.surface,
                        underline: const SizedBox(),
                        icon: const Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: AppColors.primary,
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'en',
                            child: Text(
                              'English',
                              style: TextStyle(color: AppColors.textPrimary),
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'hi',
                            child: Text(
                              'Hindi',
                              style: TextStyle(color: AppColors.textPrimary),
                            ),
                          ),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            _updateSettings(language: val);
                          }
                        },
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Unit System Tile
                  _buildTileContainer(
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      leading: const Icon(
                        Icons.straighten_rounded,
                        color: AppColors.primary,
                      ),
                      title: Text(
                        "Unit System".tr,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        _selectedUnitSystem == 'metric'
                            ? 'Metric (kg, cm)'.tr
                            : 'Imperial (lbs, in)'.tr,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      trailing: DropdownButton<String>(
                        value: _selectedUnitSystem,
                        dropdownColor: AppColors.surface,
                        underline: const SizedBox(),
                        icon: const Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: AppColors.primary,
                        ),
                        items: [
                          DropdownMenuItem(
                            value: 'metric',
                            child: Text(
                              'Metric'.tr,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'imperial',
                            child: Text(
                              'Imperial'.tr,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            _updateSettings(unitSystem: val);
                          }
                        },
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  _buildSectionHeader("Permissions & Notifications".tr),
                  const SizedBox(height: 12),

                  // Push Notifications Switch
                  _buildTileContainer(
                    child: SwitchListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      secondary: const Icon(
                        Icons.notifications_active_rounded,
                        color: AppColors.primary,
                      ),
                      title: Text(
                        "Push Notifications".tr,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        "Receive alerts and reminders".tr,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      value: _pushNotifications,
                      activeColor: Colors.black,
                      activeTrackColor: AppColors.primary,
                      inactiveThumbColor: Colors.white,
                      inactiveTrackColor: Colors.white24,
                      onChanged: (val) {
                        _updateSettings(pushNotifications: val);
                      },
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Microphone Access Switch
                  _buildTileContainer(
                    child: SwitchListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      secondary: const Icon(
                        Icons.mic_rounded,
                        color: AppColors.primary,
                      ),
                      title: Text(
                        "Microphone Access".tr,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        "Allow voice conversations with AI coach".tr,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      value: _microphoneAccess,
                      activeColor: Colors.black,
                      activeTrackColor: AppColors.primary,
                      inactiveThumbColor: Colors.white,
                      inactiveTrackColor: Colors.white24,
                      onChanged: (val) async {
                        // 1. Optimistically update the UI immediately
                        setState(() => _microphoneAccess = val);

                        if (val == true) {
                          try {
                            final status = await Permission.microphone
                                .request();
                            final granted = status.isGranted;

                            if (granted) {
                              // 2. Permission granted, tell backend
                              await _updateSettings(microphoneAccess: true);
                            } else {
                              // 3. Permission denied, revert the UI toggle
                              if (mounted) {
                                setState(() => _microphoneAccess = false);
                              }
                              Get.snackbar(
                                "Permission Denied".tr,
                                "Please enable microphone access in your device settings."
                                    .tr,
                                snackPosition: SnackPosition.BOTTOM,
                                backgroundColor: AppColors.surface,
                                colorText: Colors.redAccent,
                              );
                            }
                          } catch (e) {
                            if (mounted) {
                              setState(() => _microphoneAccess = false);
                            }
                          }
                        } else {
                          // 4. User disabled it, tell backend
                          await _updateSettings(microphoneAccess: false);
                        }
                      },
                    ),
                  ),

                  if (_settingsController.isUpdating.value) ...[
                    const SizedBox(height: 30),
                    const Center(
                      child: SizedBox(
                        width: 28,
                        height: 28,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title.toUpperCase(),
      style: const TextStyle(
        color: AppColors.textSecondary,
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.1,
      ),
    );
  }

  Widget _buildTileContainer({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withOpacity(.12)),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: child,
      ),
    );
  }
}
