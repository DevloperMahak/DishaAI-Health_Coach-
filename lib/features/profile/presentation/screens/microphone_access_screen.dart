import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/theme/app_colors.dart';

class MicrophoneAccessScreen extends StatefulWidget {
  const MicrophoneAccessScreen({super.key, this.onAllow, this.onSkip});

  /// Called when user taps "Allow Microphone"
  final VoidCallback? onAllow;

  /// Called when user taps "Not Now"
  final VoidCallback? onSkip;

  @override
  State<MicrophoneAccessScreen> createState() => _MicrophoneAccessScreenState();
}

class _MicrophoneAccessScreenState extends State<MicrophoneAccessScreen> {
  // ============================================================
  // RESPONSIVE HELPERS
  // ============================================================

  double _scale(double width) {
    return (width / 390).clamp(0.88, 1.18);
  }

  double _horizontalPadding(double width) {
    if (width < 340) return 16;
    if (width < 390) return 20;
    if (width < 600) return 22;
    if (width < 900) return 40;
    return 60;
  }

  bool _isTablet(double width) {
    return width >= 600;
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final height = constraints.maxHeight;

            final scale = _scale(width);
            final horizontalPadding = _horizontalPadding(width);
            final tablet = _isTablet(width);

            /*
             * On very short screens we allow scrolling.
             * On normal screens the content fills the entire
             * available height so the microphone can truly
             * sit in the center.
             */
            final bool shortScreen = height < 620;

            if (shortScreen) {
              return _buildScrollableLayout(
                width: width,
                height: height,
                scale: scale,
                horizontalPadding: horizontalPadding,
                tablet: tablet,
              );
            }

            return _buildFullScreenLayout(
              width: width,
              height: height,
              scale: scale,
              horizontalPadding: horizontalPadding,
              tablet: tablet,
            );
          },
        ),
      ),
    );
  }

  // ============================================================
  // FULL SCREEN LAYOUT
  // ============================================================

  Widget _buildFullScreenLayout({
    required double width,
    required double height,
    required double scale,
    required double horizontalPadding,
    required bool tablet,
  }) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 700),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --------------------------------------------------
              // TOP HEADER
              // --------------------------------------------------
              SizedBox(height: tablet ? 42 : 34),

              _buildHeader(scale: scale, tablet: tablet),

              // --------------------------------------------------
              // CENTER AREA
              // --------------------------------------------------
              Expanded(
                child: Column(
                  children: [
                    // Flexible top spacing
                    const Spacer(flex: 2),

                    // ------------------------------------------------
                    // MICROPHONE
                    // ------------------------------------------------
                    _buildMicrophoneIllustration(scale: scale, tablet: tablet),

                    SizedBox(height: tablet ? 38 : 32),

                    // ------------------------------------------------
                    // PRIVACY MESSAGE
                    // ------------------------------------------------
                    _buildPrivacyMessage(scale: scale, tablet: tablet),

                    // Flexible spacing before buttons
                    const Spacer(flex: 2),

                    // ------------------------------------------------
                    // BUTTONS
                    // ------------------------------------------------
                    _buildAllowButton(scale: scale, tablet: tablet),

                    SizedBox(height: tablet ? 12 : 8),

                    _buildNotNowButton(scale: scale, tablet: tablet),

                    SizedBox(height: tablet ? 30 : 18),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // SCROLLABLE LAYOUT FOR SMALL HEIGHT
  // ============================================================

  Widget _buildScrollableLayout({
    required double width,
    required double height,
    required double scale,
    required double horizontalPadding,
    required bool tablet,
  }) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              horizontalPadding,
              28,
              horizontalPadding,
              24,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(scale: scale, tablet: tablet),

                SizedBox(height: 35 * scale),

                _buildMicrophoneIllustration(scale: scale, tablet: tablet),

                SizedBox(height: 28 * scale),

                _buildPrivacyMessage(scale: scale, tablet: tablet),

                SizedBox(height: 32 * scale),

                _buildAllowButton(scale: scale, tablet: tablet),

                SizedBox(height: 8 * scale),

                _buildNotNowButton(scale: scale, tablet: tablet),

                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader({required double scale, required bool tablet}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Let RheaAI hear you',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: AppColors.primary,
            fontSize: tablet ? 25 : (20 * scale).clamp(18.0, 23.0),
            fontWeight: FontWeight.w800,
            height: 1.15,
          ),
        ),

        SizedBox(height: tablet ? 14 : 11),

        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Text(
            'Your microphone is needed for voice check-in '
            'conversations with your AI health coach.',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: tablet ? 14 : (11.5 * scale).clamp(10.5, 13.0),
              height: 1.55,
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // MICROPHONE ILLUSTRATION
  // ============================================================

  Widget _buildMicrophoneIllustration({
    required double scale,
    required bool tablet,
  }) {
    final double circleSize = tablet ? 210 : (150 * scale).clamp(138.0, 175.0);

    return Center(
      child: Container(
        width: circleSize,
        height: circleSize,
        decoration: BoxDecoration(
          shape: BoxShape.circle,

          gradient: RadialGradient(
            center: Alignment.center,
            radius: 0.85,
            colors: [AppColors.surface, AppColors.surface.withOpacity(.82)],
          ),

          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(.40),
              blurRadius: 25,
              spreadRadius: 2,
              offset: const Offset(0, 8),
            ),

            BoxShadow(
              color: AppColors.primary.withOpacity(.04),
              blurRadius: 30,
              spreadRadius: 3,
            ),
          ],
        ),
        child: Center(child: _MicrophoneIcon(scale: tablet ? 1.25 : scale)),
      ),
    );
  }

  // ============================================================
  // PRIVACY MESSAGE
  // ============================================================

  Widget _buildPrivacyMessage({required double scale, required bool tablet}) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: tablet ? 20 : 10),
        child: Text(
          'Your conversations are private and\n'
          'secure with RheaAI',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: tablet ? 13 : (10 * scale).clamp(9.0, 12.0),
            height: 1.5,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // ALLOW BUTTON
  // ============================================================

  Widget _buildAllowButton({required double scale, required bool tablet}) {
    final double height = tablet ? 56 : (52 * scale).clamp(48.0, 58.0);

    return SizedBox(
      width: double.infinity,
      height: height,
      child: ElevatedButton(
        onPressed: _handleAllow,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.black,
          elevation: 0,
          padding: EdgeInsets.symmetric(horizontal: 20 * scale),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(tablet ? 10 : 8),
          ),
        ),
        child: Text(
          'Allow Microphone',
          style: TextStyle(
            color: Colors.black,
            fontSize: tablet ? 15 : (13 * scale).clamp(12.0, 15.0),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // NOT NOW
  // ============================================================

  Widget _buildNotNowButton({required double scale, required bool tablet}) {
    final double height = tablet ? 52 : (46 * scale).clamp(42.0, 52.0);

    return SizedBox(
      width: double.infinity,
      height: height,
      child: TextButton(
        onPressed: _handleSkip,
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10 * scale),
          ),
        ),
        child: Text(
          'Not Now',
          style: TextStyle(
            color: AppColors.primary,
            fontSize: tablet ? 15 : (13 * scale).clamp(12.0, 15.0),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // ALLOW HANDLER
  // ============================================================

  void _handleAllow() {
    if (widget.onAllow != null) {
      widget.onAllow!();
      return;
    }

    Get.snackbar(
      'Microphone',
      'Microphone permission will be requested here.',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: AppColors.surface,
      colorText: AppColors.textPrimary,
      margin: const EdgeInsets.all(16),
      borderRadius: 14,
      duration: const Duration(seconds: 2),
    );
  }

  // ============================================================
  // SKIP HANDLER
  // ============================================================

  void _handleSkip() {
    if (widget.onSkip != null) {
      widget.onSkip!();
      return;
    }

    Get.back();
  }
}

// ==================================================================
// CUSTOM MICROPHONE ICON
// ==================================================================

class _MicrophoneIcon extends StatelessWidget {
  const _MicrophoneIcon({required this.scale});

  final double scale;

  @override
  Widget build(BuildContext context) {
    final micWidth = (24 * scale).clamp(21.0, 31.0);

    final micHeight = (62 * scale).clamp(54.0, 76.0);

    final strokeWidth = (6 * scale).clamp(5.0, 7.5);

    return SizedBox(
      width: (75 * scale).clamp(66.0, 95.0),
      height: (100 * scale).clamp(88.0, 125.0),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // --------------------------------------------------------
          // MICROPHONE BODY
          // --------------------------------------------------------
          Positioned(
            top: 2 * scale,
            child: Container(
              width: micWidth,
              height: micHeight,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(micWidth / 2),
              ),
            ),
          ),

          // --------------------------------------------------------
          // MICROPHONE U-SHAPE
          // --------------------------------------------------------
          Positioned(
            top: 42 * scale,
            child: CustomPaint(
              size: Size(62 * scale, 43 * scale),
              painter: _MicArcPainter(
                color: AppColors.primary,
                strokeWidth: strokeWidth,
              ),
            ),
          ),

          // --------------------------------------------------------
          // CENTER STAND
          // --------------------------------------------------------
          Positioned(
            bottom: 10 * scale,
            child: Container(
              width: strokeWidth,
              height: 25 * scale,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),

          // --------------------------------------------------------
          // BASE
          // --------------------------------------------------------
          Positioned(
            bottom: 4 * scale,
            child: Container(
              width: 38 * scale,
              height: strokeWidth,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ==================================================================
// MICROPHONE ARC PAINTER
// ==================================================================

class _MicArcPainter extends CustomPainter {
  const _MicArcPainter({required this.color, required this.strokeWidth});

  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final rect = Rect.fromLTWH(
      strokeWidth,
      0,
      size.width - (strokeWidth * 2),
      size.height * 1.7,
    );

    canvas.drawArc(rect, 0, 3.14, false, paint);
  }

  @override
  bool shouldRepaint(covariant _MicArcPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.strokeWidth != strokeWidth;
  }
}
