import 'package:disha_ai/features/authentication/presentation/controllers/auth_controller.dart';
import 'package:disha_ai/features/onboarding/presentation/controllers/health_profile_controller.dart';
import 'package:disha_ai/features/profile/presentation/controllers/profile_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../app/theme/app_colors.dart';

class DashboardDrawer extends StatelessWidget {
  DashboardDrawer({
    super.key,
    required this.userName,
    this.email,
    this.profileImage,
    required this.onItemTap,
  });

  final String userName;
  final String? email;
  final String? profileImage;
  final ValueChanged<int> onItemTap;

  // ============================================================
  // CONTROLLERS
  // ============================================================

  AuthController get _authController {
    if (Get.isRegistered<AuthController>()) {
      return Get.find<AuthController>();
    }
    return Get.put(AuthController());
  }

  HealthProfileController get _healthController {
    if (Get.isRegistered<HealthProfileController>()) {
      return Get.find<HealthProfileController>();
    }
    return Get.put(HealthProfileController());
  }

  ProfileController get _profileController {
    if (Get.isRegistered<ProfileController>()) {
      return Get.find<ProfileController>();
    }
    return Get.put(ProfileController());
  }

  // ============================================================
  // DRAWER ITEMS
  // ============================================================

  static const List<_DrawerItemData> _items = [
    _DrawerItemData(title: 'Home', icon: Icons.home_rounded),
    _DrawerItemData(title: 'Chat with Rhea', icon: Icons.psychology_rounded),
    _DrawerItemData(
      title: 'My Plan',
      subtitle: 'Diet + Workout',
      icon: Icons.assignment_rounded,
    ),
    _DrawerItemData(
      title: 'Progress',
      subtitle: 'Health Journey',
      icon: Icons.bar_chart_rounded,
    ),
    _DrawerItemData(
      title: 'Notifications',
      icon: Icons.notifications_none_rounded,
    ),
    _DrawerItemData(title: 'Settings', icon: Icons.settings_rounded),
    _DrawerItemData(title: 'Help & Support', icon: Icons.help_outline_rounded),
    _DrawerItemData(
      title: 'Privacy Policy',
      subtitle: 'Terms',
      icon: Icons.privacy_tip_outlined,
    ),
    _DrawerItemData(title: 'Rate App', icon: Icons.star_outline_rounded),
    _DrawerItemData(
      title: 'Logout',
      icon: Icons.logout_rounded,
      isLogout: true,
    ),
  ];

  // ============================================================
  // LOGOUT
  // ============================================================

  Future<void> _logout(BuildContext context) async {
    final confirmed = await _showLogoutConfirmation(context);

    if (confirmed != true) {
      return;
    }

    final authController = _authController;

    if (context.mounted) {
      Navigator.of(context).pop();
    }

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

      if (Get.isDialogOpen == true) {
        Get.back();
      }

      Get.offAllNamed(AppRoutes.login);
    } catch (e, stackTrace) {
      debugPrint('LOGOUT ERROR: $e');
      debugPrint('$stackTrace');

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
                  'Logout',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          content: const Text(
            'Are you sure you want to logout from Rhea AI?',
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
                'Logout',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppColors.background,
      child: SafeArea(
        child: Column(
          children: [
            // ==================================================
            // HEADER WITH LIVE PROFILE PHOTO REACTIVE BINDING
            // ==================================================
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  Hero(
                    tag: 'dashboard_profile',
                    child: Obx(() {
                      final apiProfile = _profileController.profile.value;
                      String? photoPath =
                          apiProfile?.profilePhoto ?? profileImage;

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
                        height: 68,
                        width: 68,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.primary,
                            width: 2,
                          ),
                        ),
                        child: ClipOval(
                          child: photoPath != null
                              ? Image.network(
                                  photoPath,
                                  fit: BoxFit.cover,
                                  key: ValueKey(photoPath),
                                  errorBuilder: (context, error, stackTrace) {
                                    return const Icon(
                                      Icons.person_rounded,
                                      size: 34,
                                      color: AppColors.primary,
                                    );
                                  },
                                )
                              : const Icon(
                                  Icons.person_rounded,
                                  size: 34,
                                  color: AppColors.primary,
                                ),
                        ),
                      );
                    }),
                  ),

                  const SizedBox(width: 16),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          userName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),

                        const SizedBox(height: 4),

                        // 💡 DYNAMIC EMAIL SECTION USING Obx
                        Obx(() {
                          final profileEmail =
                              _healthController.healthProfile.value?.email;
                          final authUser = _authController.currentUser.value;
                          final authEmail = authUser?['email'];

                          final displayEmail =
                              profileEmail ??
                              authEmail?.toString() ??
                              email ??
                              'Welcome to Rhea AI';

                          return Text(
                            displayEmail,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            Divider(color: AppColors.primary.withOpacity(.15), height: 1),

            // ==================================================
            // MENU
            // ==================================================
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                itemCount: _items.length,
                itemBuilder: (context, index) {
                  final item = _items[index];

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: ListTile(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      leading: Icon(
                        item.icon,
                        color: item.isLogout
                            ? Colors.redAccent
                            : AppColors.primary,
                      ),
                      title: Text(
                        item.title,
                        style: TextStyle(
                          color: item.isLogout
                              ? Colors.redAccent
                              : AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: item.subtitle == null
                          ? null
                          : Text(
                              item.subtitle!,
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                      trailing: const Icon(
                        Icons.chevron_right_rounded,
                        color: AppColors.textSecondary,
                      ),
                      onTap: () {
                        if (item.isLogout) {
                          _logout(context);
                          return;
                        }

                        Navigator.of(context).pop();
                        onItemTap(index);
                      },
                    ),
                  );
                },
              ),
            ),

            // ==================================================
            // FOOTER
            // ==================================================
            const Padding(
              padding: EdgeInsets.only(bottom: 20, top: 8),
              child: Column(
                children: [
                  Text(
                    'Rhea AI',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Version 1.0.0',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerItemData {
  final String title;
  final String? subtitle;
  final IconData icon;
  final bool isLogout;

  const _DrawerItemData({
    required this.title,
    required this.icon,
    this.subtitle,
    this.isLogout = false,
  });
}
