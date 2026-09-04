import 'package:disha_ai/features/authentication/presentation/controllers/auth_controller.dart';
import 'package:disha_ai/features/profile/presentation/controllers/profile_controller.dart';
import 'package:disha_ai/features/onboarding/presentation/controllers/health_profile_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../app/theme/app_colors.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProfileData();
    });
  }

  Future<void> _loadProfileData() async {
    await Future.wait([
      _profileController.fetchProfile(),
      _healthProfileController.getHealthProfile(),
    ]);
  }

  Future<void> _logout(BuildContext context) async {
    final confirmed = await _showLogoutConfirmation(context);
    if (confirmed != true) return;

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
      if (Get.isDialogOpen == true) Get.back();
      Get.offAllNamed(AppRoutes.login);
    } catch (e) {
      debugPrint('LOGOUT ERROR: $e');
      if (Get.isDialogOpen == true) Get.back();
      Get.offAllNamed(AppRoutes.login);
    }
  }

  Future<bool?> _showLogoutConfirmation(BuildContext context) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
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
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text(
                'Cancel',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
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
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final bool tablet = width > 600;

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
                    _statsSection(tablet),
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
          "Profile",
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
          Obx(() {
            final apiProfile = _profileController.profile.value;
            String? photoPath = apiProfile?.profilePhoto;

            if (photoPath != null && photoPath.trim().isNotEmpty) {
              final trimmed = photoPath.trim();
              if (!trimmed.startsWith('http')) {
                photoPath =
                    'https://rhea-ai.acttconnect.com${trimmed.startsWith('/') ? '' : '/'}$trimmed';
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
                        errorBuilder: (context, error, stackTrace) {
                          return Image.asset(
                            "assets/images/Profile.png",
                            fit: BoxFit.cover,
                          );
                        },
                      )
                    : Image.asset(
                        "assets/images/Profile.png",
                        fit: BoxFit.cover,
                      ),
              ),
            );
          }),
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

              final name =
                  clean(apiProfile?.name) ??
                  clean(healthProfile?.name) ??
                  clean(authUser?['name']?.toString()) ??
                  clean(authUser?['full_name']?.toString()) ??
                  "Guest User";

              final email =
                  clean(apiProfile?.email) ??
                  clean(healthProfile?.email) ??
                  clean(authUser?['email']?.toString()) ??
                  "No email provided";

              final mobile =
                  clean(healthProfile?.mobile) ??
                  clean(authUser?['mobile']?.toString()) ??
                  clean(authUser?['phone']?.toString()) ??
                  "+91 Not Provided";

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: tablet ? 22 : 18,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    email,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    mobile,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              );
            }),
          ),
          InkWell(
            borderRadius: BorderRadius.circular(30),
            onTap: () async {
              await Get.toNamed(AppRoutes.editPersonalInfo);
              _loadProfileData();
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

  Widget _statsSection(bool tablet) {
    final stats = [
      ["🔥", "12", "Day Streak"],
      ["🏆", "Great", "Your Progress"],
      ["⭐", "1,250", "Points Earned"],
      ["⚙️", "7", "Badges"],
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: tablet ? 4 : 4,
        childAspectRatio: tablet ? 1.4 : 0.9,
        crossAxisSpacing: 8,
      ),
      itemCount: stats.length,
      itemBuilder: (context, index) {
        return Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(stats[index][0], style: const TextStyle(fontSize: 20)),
              const SizedBox(height: 5),
              Text(
                stats[index][1],
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                stats[index][2],
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _menuCard(BuildContext context, bool tablet) {
    final items = [
      [
        Icons.workspace_premium,
        "Upgrade to Premium",
      ], // <-- ADDED HERE IN PROFILE
      [Icons.person, "Personal Information"],
      [Icons.health_and_safety, "Connect Data"],
      [Icons.bar_chart, "Health Data"],
      [Icons.notifications, "Notifications"],
      [Icons.alarm, "Reminders"],
      [Icons.security, "Privacy & Security"],
      [Icons.help, "Help & Support"],
      [Icons.smart_toy, "About Rhea AI"],
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
        itemBuilder: (context, index) {
          return Material(
            color: Colors.transparent,
            child: ListTile(
              dense: true,
              onTap: () async {
                switch (index) {
                  case 0:
                    Get.toNamed(AppRoutes.upgradePremium); // <-- ROUTE NAVIGATE
                    break;
                  case 1:
                    await Get.toNamed(AppRoutes.editPersonalInfo);
                    _loadProfileData();
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
                }
              },
              leading: Icon(
                items[index][0] as IconData,
                color: AppColors.primary,
                size: 20,
              ),
              title: Text(
                items[index][1].toString(),
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
          );
        },
      ),
    );
  }

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
                  "there";

              final firstName = displayName.split(' ').first;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Keep going, $firstName!",
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                    "You are doing amazing.\nSmall steps matter.",
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
          "Sign Out",
          style: TextStyle(
            color: Colors.redAccent,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
