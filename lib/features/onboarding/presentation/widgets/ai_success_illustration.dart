import 'dart:math';

import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';

class AICompletionIllustration extends StatefulWidget {
  const AICompletionIllustration({super.key});

  @override
  State<AICompletionIllustration> createState() =>
      _AICompletionIllustrationState();
}

class _AICompletionIllustrationState extends State<AICompletionIllustration>
    with TickerProviderStateMixin {
  late final AnimationController _rotationController;

  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();

    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  double _scale(double width) {
    return (width / 390).clamp(.88, 1.12);
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;

    final scale = _scale(width);

    final size = (250 * scale).clamp(210.0, 320.0);

    return AnimatedBuilder(
      animation: Listenable.merge([_rotationController, _pulseController]),
      builder: (_, __) {
        final pulse = 1 + (_pulseController.value * .03);

        return Transform.scale(
          scale: pulse,
          child: SizedBox(
            width: size,
            height: size,
            child: Stack(
              alignment: Alignment.center,
              children: [
                //==================================================
                // BACKGROUND GLOW
                //==================================================
                Container(
                  width: size * .72,
                  height: size * .72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(.20),
                        blurRadius: 55,
                        spreadRadius: 18,
                      ),
                    ],
                  ),
                ),

                //==================================================
                // ROTATING RING
                //==================================================
                Transform.rotate(
                  angle: _rotationController.value * pi * 2,
                  child: CustomPaint(
                    size: Size.square(size * .92),
                    painter: _SuccessRingPainter(),
                  ),
                ),

                //==================================================
                // IMAGE
                //==================================================
                Hero(
                  tag: "completion_image",
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(26),
                    child: Image.asset(
                      "assets/images/Rhea_Plan.png",
                      width: size,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),

                //==================================================
                // FLOATING STARS
                //==================================================
                Positioned(top: 18, right: 42, child: _sparkle(22)),

                Positioned(left: 18, bottom: 55, child: _sparkle(18)),

                Positioned(right: 12, bottom: 38, child: _sparkle(15)),

                Positioned(left: 42, top: 40, child: _sparkle(13)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _sparkle(double size) {
    return Transform.rotate(
      angle: _rotationController.value * pi * 2,
      child: Opacity(
        opacity: .6 + (.4 * _pulseController.value),
        child: Icon(Icons.auto_awesome, color: AppColors.primary, size: size),
      ),
    );
  }
}

class _SuccessRingPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 5
      ..shader = SweepGradient(
        colors: [
          Colors.transparent,
          AppColors.primary.withOpacity(.25),
          AppColors.primary,
          AppColors.primary.withOpacity(.25),
          Colors.transparent,
        ],
      ).createShader(rect);

    canvas.drawArc(
      Rect.fromLTWH(3, 3, size.width - 6, size.height - 6),
      0,
      pi * 1.7,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
