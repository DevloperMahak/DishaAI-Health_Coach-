import 'package:disha_ai/features/authentication/presentation/controllers/auth_controller.dart';
import 'package:disha_ai/features/profile/presentation/controllers/profile_controller.dart';
import 'package:disha_ai/features/onboarding/presentation/controllers/health_profile_controller.dart';
import 'package:disha_ai/features/profile/presentation/screens/help_Support_screen.dart';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../app/theme/app_colors.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // ============================================================
  // STATE
  // ============================================================

  bool _isOpeningHelpSupport = false;
  bool _isOpeningLegal = false;

  // ============================================================
  // LEGAL URLS
  // ============================================================

  static final Uri _privacyPolicyUrl = Uri.parse(
    'https://rhea-ai.acttconnect.com/privacy',
  );

  static final Uri _termsConditionsUrl = Uri.parse(
    'https://rhea-ai.acttconnect.com/terms',
  );

  // ============================================================
  // CONTROLLERS
  // ============================================================

  ProfileController get _profileController =>
      Get.isRegistered<ProfileController>()
      ? Get.find<ProfileController>()
      : Get.put(ProfileController());

  HealthProfileController get _healthProfileController =>
      Get.isRegistered<HealthProfileController>()
      ? Get.find<HealthProfileController>()
      : Get.put(HealthProfileController());

  AuthController get _authController => Get.isRegistered<AuthController>()
      ? Get.find<AuthController>()
      : Get.put(AuthController());

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadProfileData();
      }
    });
  }

  // ============================================================
  // LOAD PROFILE DATA
  // ============================================================

  Future<void> _loadProfileData() async {
    try {
      await Future.wait([
        _profileController.fetchProfile(),
        _healthProfileController.getHealthProfile(),
      ]);
    } catch (e, stackTrace) {
      debugPrint('PROFILE LOAD ERROR: $e');
      debugPrint('$stackTrace');
    }
  }

  // ============================================================
  // OPEN LEGAL URL
  // ============================================================

  Future<void> _openLegalUrl(Uri url, String title) async {
    if (!mounted) return;

    try {
      final bool launched = await launchUrl(
        url,
        mode: LaunchMode.externalApplication,
      );

      if (!launched) {
        _showLegalError(title);
      }
    } catch (e, stackTrace) {
      debugPrint('LEGAL URL ERROR ($title): $e');
      debugPrint('$stackTrace');

      _showLegalError(title);
    }
  }

  // ============================================================
  // LEGAL URL ERROR
  // ============================================================

  void _showLegalError(String title) {
    if (!mounted) return;

    Get.snackbar(
      'Unable to open $title',
      'Please check your internet connection and try again.',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: AppColors.surface,
      colorText: AppColors.textPrimary,
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 3),
      icon: const Icon(Icons.error_outline_rounded, color: Colors.redAccent),
    );
  }

  // ============================================================
  // PRIVACY & SECURITY
  // ============================================================

  Future<void> _handlePrivacyPolicy() async {
    if (_isOpeningLegal) return;

    _isOpeningLegal = true;

    try {
      await Get.dialog<void>(
        AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),

          title: const Row(
            children: [
              Icon(Icons.gavel_rounded, color: AppColors.primary),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Legal & Policies',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 19,
                  ),
                ),
              ),
            ],
          ),

          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ==================================================
              // PRIVACY POLICY
              // ==================================================
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(
                  Icons.privacy_tip_outlined,
                  color: AppColors.primary,
                ),
                title: const Text(
                  'Privacy Policy',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: const Text(
                  'How we protect your data',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                trailing: const Icon(
                  Icons.open_in_new_rounded,
                  color: AppColors.textSecondary,
                  size: 20,
                ),
                onTap: () {
                  Get.back();

                  _openLegalUrl(_privacyPolicyUrl, 'Privacy Policy');
                },
              ),

              Divider(color: AppColors.primary.withOpacity(0.12)),

              // ==================================================
              // TERMS & CONDITIONS
              // ==================================================
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(
                  Icons.description_outlined,
                  color: AppColors.primary,
                ),
                title: const Text(
                  'Terms & Conditions',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: const Text(
                  'Read our terms of service',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                trailing: const Icon(
                  Icons.open_in_new_rounded,
                  color: AppColors.textSecondary,
                  size: 20,
                ),
                onTap: () {
                  Get.back();

                  _openLegalUrl(_termsConditionsUrl, 'Terms & Conditions');
                },
              ),
            ],
          ),

          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: const Text(
                'Close',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    } catch (e, stackTrace) {
      debugPrint('LEGAL DIALOG ERROR: $e');
      debugPrint('$stackTrace');

      if (mounted) {
        Get.snackbar(
          'Unable to open',
          'Could not open Legal & Policies. Please try again.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.surface,
          colorText: AppColors.textPrimary,
          margin: const EdgeInsets.all(16),
        );
      }
    } finally {
      _isOpeningLegal = false;
    }
  }

  // ============================================================
  // HELP & SUPPORT
  // ============================================================

  Future<void> _handleHelpSupport() async {
    if (_isOpeningHelpSupport) return;

    _isOpeningHelpSupport = true;

    try {
      await Get.to<void>(
        () => const HelpSupportScreen(),
        transition: Transition.rightToLeft,
        duration: const Duration(milliseconds: 300),
      );
    } catch (e, stackTrace) {
      debugPrint('HELP & SUPPORT NAVIGATION ERROR: $e');
      debugPrint('$stackTrace');

      if (mounted) {
        Get.snackbar(
          'Unable to open',
          'Could not open Help & Support. Please try again.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.surface,
          colorText: AppColors.textPrimary,
          margin: const EdgeInsets.all(16),
        );
      }
    } finally {
      _isOpeningHelpSupport = false;
    }
  }

  // ============================================================
  // LOGOUT
  // ============================================================

  Future<void> _logout(BuildContext context) async {
    final confirmed = await _showLogoutConfirmation(context);

    if (confirmed != true || !mounted) return;

    final authController = _authController;

    Get.dialog(
      const PopScope(
        canPop: false,
        child: Center(
          child: Material(
            color: Colors.transparent,
            child: SizedBox(
              width: 48,
              height: 48,
              child: CircularProgressIndicator(
                color: AppColors.primary,
                strokeWidth: 2.5,
              ),
            ),
          ),
        ),
      ),
      barrierDismissible: false,
      barrierColor: Colors.black54,
    );

    try {
      await authController.logout();
    } catch (e, stackTrace) {
      debugPrint('LOGOUT ERROR: $e');
      debugPrint('$stackTrace');
    } finally {
      if (Get.isDialogOpen == true) {
        Get.back();
      }

      Get.offAllNamed(AppRoutes.login);
    }
  }

  // ============================================================
  // LOGOUT CONFIRMATION
  // ============================================================

  Future<bool?> _showLogoutConfirmation(BuildContext context) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.logout_rounded, color: Colors.redAccent),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Sign Out',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        content: const Text(
          'Are you sure you want to sign out from Rhea AI?',
          style: TextStyle(color: AppColors.textSecondary, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop(false);
            },
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(dialogContext).pop(true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              'Sign Out',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final tablet = width > 600;

            return RefreshIndicator(
              color: AppColors.primary,
              backgroundColor: AppColors.surface,
              onRefresh: _loadProfileData,
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                padding: EdgeInsets.symmetric(
                  horizontal: tablet ? width * .18 : 16,
                  vertical: 18,
                ),
                child: Column(
                  children: [
                    _header(context, tablet),

                    const SizedBox(height: 20),

                    _profileCard(context, tablet),

                    const SizedBox(height: 16),

                    _menuCard(context, tablet),

                    const SizedBox(height: 16),

                    _motivationCard(tablet),

                    const SizedBox(height: 18),

                    _logoutButton(),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _header(BuildContext context, bool tablet) {
    return Row(
      children: [
        IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(
            Icons.arrow_back_ios_new,
            color: AppColors.primary,
            size: tablet ? 28 : 22,
          ),
        ),

        const Spacer(),

        Text(
          'Profile',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: tablet ? 24 : 20,
            fontWeight: FontWeight.bold,
          ),
        ),

        const Spacer(),
      ],
    );
  }

  // ============================================================
  // PROFILE CARD
  // ============================================================

  Widget _profileCard(BuildContext context, bool tablet) {
    return Container(
      padding: EdgeInsets.all(tablet ? 22 : 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primaryDark.withOpacity(.6)),
      ),
      child: Row(
        children: [
          // ==================================================
          // PROFILE IMAGE
          // ==================================================
          Obx(() {
            final apiProfile = _profileController.profile.value;

            String? photoPath = apiProfile?.profilePhoto;

            if (photoPath != null && photoPath.trim().isNotEmpty) {
              final trimmed = photoPath.trim();

              if (!trimmed.startsWith('http')) {
                photoPath =
                    'https://rhea-ai.acttconnect.com'
                    '${trimmed.startsWith('/') ? '' : '/'}'
                    '$trimmed';
              }
            } else {
              photoPath = null;
            }

            return Container(
              height: tablet ? 90 : 70,
              width: tablet ? 90 : 70,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.primary, width: 2),
              ),
              child: ClipOval(
                child: photoPath != null
                    ? Image.network(
                        photoPath,
                        fit: BoxFit.cover,
                        width: tablet ? 90 : 70,
                        height: tablet ? 90 : 70,
                        key: ValueKey(photoPath),
                        errorBuilder: (context, error, stackTrace) =>
                            Image.asset(
                              'assets/images/Profile.png',
                              fit: BoxFit.cover,
                            ),
                      )
                    : Image.asset(
                        'assets/images/Profile.png',
                        fit: BoxFit.cover,
                      ),
              ),
            );
          }),

          const SizedBox(width: 15),

          // ==================================================
          // PROFILE DETAILS
          // ==================================================
          Expanded(
            child: Obx(() {
              final apiProfile = _profileController.profile.value;

              final healthProfile =
                  _healthProfileController.healthProfile.value;

              final authUser = _authController.currentUser.value;

              String? clean(String? val) {
                if (val == null) return null;

                final trimmed = val.trim();

                if (trimmed.isEmpty || trimmed.toLowerCase() == 'user') {
                  return null;
                }

                return trimmed;
              }

              final name =
                  clean(apiProfile?.name) ??
                  clean(healthProfile?.name) ??
                  clean(authUser?['name']?.toString()) ??
                  clean(authUser?['full_name']?.toString()) ??
                  'Guest User';

              final email =
                  clean(apiProfile?.email) ??
                  clean(healthProfile?.email) ??
                  clean(authUser?['email']?.toString()) ??
                  'No email provided';

              final mobile =
                  clean(healthProfile?.mobile) ??
                  clean(authUser?['mobile']?.toString()) ??
                  clean(authUser?['phone']?.toString()) ??
                  '+91 Not Provided';

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: tablet ? 22 : 18,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    email,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    mobile,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              );
            }),
          ),

          // ==================================================
          // EDIT PROFILE
          // ==================================================
          InkWell(
            borderRadius: BorderRadius.circular(30),
            onTap: () async {
              await Get.toNamed(AppRoutes.editPersonalInfo);

              if (mounted) {
                await _loadProfileData();
              }
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(.12),
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.primary.withOpacity(.3)),
              ),
              child: const Icon(
                Icons.edit_rounded,
                color: AppColors.primary,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // MENU CARD
  // ============================================================

  Widget _menuCard(BuildContext context, bool tablet) {
    const items = <(IconData, String)>[
      (Icons.workspace_premium, 'Upgrade to Premium'),
      (Icons.person, 'Personal Information'),
      (Icons.health_and_safety, 'Connect Data'),
      (Icons.bar_chart, 'Health Data'),
      (Icons.notifications, 'Notifications'),
      (Icons.alarm, 'Reminders'),
      (Icons.security, 'Privacy & Security'),
      (Icons.help, 'Help & Support'),
      (Icons.smart_toy, 'About Rhea AI'),
    ];

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: items.length,
        separatorBuilder: (_, __) =>
            Divider(height: 1, color: AppColors.border.withOpacity(.5)),
        itemBuilder: (context, index) => Material(
          color: Colors.transparent,
          child: ListTile(
            dense: true,
            onTap: () async {
              switch (index) {
                case 0:
                  Get.toNamed(AppRoutes.upgradePremium);
                  break;

                case 1:
                  await Get.toNamed(AppRoutes.editPersonalInfo);

                  if (mounted) {
                    await _loadProfileData();
                  }
                  break;

                case 2:
                  Get.toNamed(AppRoutes.settings);
                  break;

                case 3:
                  Get.toNamed(AppRoutes.editHealthInfo);
                  break;

                case 4:
                  Get.toNamed(AppRoutes.notifications);
                  break;

                case 5:
                  Get.toNamed(AppRoutes.reminders);
                  break;

                case 6:
                  await _handlePrivacyPolicy();
                  break;

                case 7:
                  await _handleHelpSupport();
                  break;

                case 8:
                  Get.toNamed(AppRoutes.about);
                  break;
              }
            },

            leading: Icon(items[index].$1, color: AppColors.primary, size: 20),

            title: Text(
              items[index].$2,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),

            trailing: const Icon(
              Icons.arrow_forward_ios,
              color: AppColors.primary,
              size: 15,
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // MOTIVATION CARD
  // ============================================================

  Widget _motivationCard(bool tablet) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary),
      ),
      child: Row(
        children: [
          const Icon(Icons.auto_awesome, color: AppColors.primary, size: 40),

          const SizedBox(width: 15),

          Expanded(
            child: Obx(() {
              final apiProfile = _profileController.profile.value;

              final healthProfile =
                  _healthProfileController.healthProfile.value;

              final authUser = _authController.currentUser.value;

              String? clean(String? val) {
                if (val == null) return null;

                final trimmed = val.trim();

                if (trimmed.isEmpty || trimmed.toLowerCase() == 'user') {
                  return null;
                }

                return trimmed;
              }

              final displayName =
                  clean(apiProfile?.name) ??
                  clean(healthProfile?.name) ??
                  clean(authUser?['name']?.toString()) ??
                  clean(authUser?['full_name']?.toString()) ??
                  'there';

              final firstName = displayName.split(' ').first;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Keep going, $firstName!',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const Text(
                    'You are doing amazing.\nSmall steps matter.',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // LOGOUT BUTTON
  // ============================================================

  Widget _logoutButton() {
    return Container(
      width: double.infinity,
      height: 50,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: Colors.redAccent.withOpacity(0.08),
        border: Border.all(color: Colors.redAccent.withOpacity(0.5)),
      ),
      child: TextButton.icon(
        onPressed: () => _logout(context),
        icon: const Icon(Icons.logout, color: Colors.redAccent),
        label: const Text(
          'Sign Out',
          style: TextStyle(
            color: Colors.redAccent,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
