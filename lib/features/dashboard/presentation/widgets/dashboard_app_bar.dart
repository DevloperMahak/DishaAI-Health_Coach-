import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';

class DashboardAppBar extends StatelessWidget {
  const DashboardAppBar({
    super.key,
    required this.userName,
    this.profileImage,
    this.notificationCount = 0,
    required this.onMenuTap,
    required this.onNotificationTap,
    required this.onProfileTap,
  });

  final VoidCallback onMenuTap;

  final String userName;
  final String? profileImage;
  final int notificationCount;

  final VoidCallback onNotificationTap;
  final VoidCallback onProfileTap;

  double _scale(double width) {
    return (width / 390).clamp(.88, 1.12);
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final scale = _scale(width);

    return Padding(
      padding: EdgeInsets.only(top: 8 * scale, bottom: 10 * scale),
      child: Column(
        children: [
          //------------------------------------------------------
          // TOP ACTION ROW
          //------------------------------------------------------
          Row(
            children: [
              _ActionButton(
                icon: Icons.menu_rounded,
                badge: 0,
                onTap: onMenuTap,
              ),

              const Spacer(),

              // Notifications Action Button
              _ActionButton(
                icon: Icons.notifications_outlined,
                badge: notificationCount,
                onTap: onNotificationTap,
              ),

              SizedBox(width: 8 * scale),

              // 💡 Profile Button added to Header
              InkWell(
                borderRadius: BorderRadius.circular(30),
                onTap: onProfileTap,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.primary.withOpacity(0.4),
                      width: 1.5,
                    ),
                  ),
                  child: ClipOval(
                    child: profileImage != null && profileImage!.isNotEmpty
                        ? Image.network(
                            profileImage!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                const _ProfilePlaceholder(),
                          )
                        : const _ProfilePlaceholder(),
                  ),
                ),
              ),

              SizedBox(width: 4 * scale),
            ],
          ),

          SizedBox(height: 18 * scale),

          //------------------------------------------------------
          // GREETING
          //------------------------------------------------------
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              "Good Morning,",
              style: TextStyle(
                fontSize: (13 * scale).clamp(12.0, 15.0),
                color: AppColors.textSecondary,
              ),
            ),
          ),

          SizedBox(height: 4 * scale),

          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              "$userName 👋",
              style: TextStyle(
                fontSize: (28 * scale).clamp(24.0, 32.0),
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
          ),

          SizedBox(height: 6 * scale),

          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              "Let's make today healthier.",
              style: TextStyle(
                fontSize: (13 * scale).clamp(12.0, 15.0),
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.badge,
    required this.onTap,
  });

  final IconData icon;
  final int badge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 40,
      height: 40,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Center(
            child: InkWell(
              borderRadius: BorderRadius.circular(30),
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: Icon(icon, size: 28, color: AppColors.primary),
              ),
            ),
          ),

          if (badge > 0)
            Positioned(
              right: 2,
              top: 2,
              child: Container(
                width: 18,
                height: 18,
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  badge > 9 ? "9+" : "$badge",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ProfilePlaceholder extends StatelessWidget {
  const _ProfilePlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      child: const Icon(
        Icons.person_rounded,
        color: AppColors.primary,
        size: 24,
      ),
    );
  }
}
