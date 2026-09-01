import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';

class SaveButton extends StatelessWidget {
  const SaveButton({
    super.key,
    required this.onPressed,
    this.isLoading = false,
    this.text = "Save Changes",
    this.icon = Icons.check_circle_rounded,
  });

  final VoidCallback? onPressed;
  final bool isLoading;
  final String text;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        final buttonHeight = width > 700 ? 60.0 : 56.0;

        return SizedBox(
          width: double.infinity,
          height: buttonHeight,
          child: ElevatedButton(
            onPressed: isLoading ? null : onPressed,

            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.black,
              disabledBackgroundColor: AppColors.primary.withOpacity(.5),

              elevation: 0,

              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),

              padding: const EdgeInsets.symmetric(horizontal: 20),
            ),

            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),

              child: isLoading
                  ? const SizedBox(
                      key: ValueKey("loading"),
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                      ),
                    )
                  : Row(
                      key: const ValueKey("button"),
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(icon, size: 22),

                        const SizedBox(width: 10),

                        Text(
                          text,
                          style: TextStyle(
                            fontSize: width > 700 ? 18 : 16,
                            fontWeight: FontWeight.w700,
                            letterSpacing: .3,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        );
      },
    );
  }
}
