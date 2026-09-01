import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';

class ProfileSaveButton extends StatelessWidget {
  const ProfileSaveButton({
    super.key,
    required this.onPressed,
    this.isLoading = false,
    this.text = "Save Changes",
    this.icon = Icons.save_rounded,
  });

  final VoidCallback? onPressed;
  final bool isLoading;
  final String text;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    final bool tablet = width >= 700;

    return SizedBox(
      width: double.infinity,
      height: tablet ? 60 : 56,

      child: ElevatedButton.icon(
        onPressed: isLoading ? null : onPressed,

        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.black,

          disabledBackgroundColor: AppColors.primary.withOpacity(.6),

          elevation: 0,

          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),

        icon: isLoading
            ? SizedBox(
                width: tablet ? 24 : 20,
                height: tablet ? 24 : 20,
                child: const CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Icon(icon, size: tablet ? 24 : 22),

        label: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Text(
            isLoading ? "Saving..." : text,
            style: TextStyle(
              fontSize: tablet ? 17 : 15,
              fontWeight: FontWeight.w700,
              letterSpacing: .3,
            ),
          ),
        ),
      ),
    );
  }
}
