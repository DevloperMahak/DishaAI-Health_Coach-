import 'dart:math';

import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';

class AIAnalyzingLogo extends StatefulWidget {
  const AIAnalyzingLogo({super.key, required this.progress});

  final double progress;

  @override
  State<AIAnalyzingLogo> createState() => _AIAnalyzingLogoState();
}

class _AIAnalyzingLogoState extends State<AIAnalyzingLogo>
    with TickerProviderStateMixin {
  late final AnimationController _rotationController;
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();

    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
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

    final size = (180 * scale).clamp(150.0, 220.0);

    return AnimatedBuilder(
      animation: Listenable.merge([_rotationController, _pulseController]),
      builder: (_, __) {
        final pulse = 1 + (_pulseController.value * 0.05);

        return Transform.scale(
          scale: pulse,
          child: SizedBox(
            width: size,
            height: size,
            child: Stack(
              alignment: Alignment.center,
              children: [
                //================================================
                // GLOW
                //================================================
                Container(
                  width: size * .88,
                  height: size * .88,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(.22),
                        blurRadius: 40,
                        spreadRadius: 8,
                      ),
                    ],
                  ),
                ),

                //================================================
                // ROTATING RING
                //================================================
                Transform.rotate(
                  angle: _rotationController.value * pi * 2,
                  child: CustomPaint(
                    size: Size.square(size),
                    painter: _RingPainter(),
                  ),
                ),

                //================================================
                // LOGO
                //================================================
                Hero(
                  tag: "app_logo",
                  child: Container(
                    width: size * .70,
                    height: size * .70,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.surface,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(.30),
                          blurRadius: 18,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(18),
                    child: Image.asset(
                      "assets/images/RheaAI_Logo.png",
                      fit: BoxFit.contain,
                    ),
                  ),
                ),

                //================================================
                // FLOATING STARS
                //================================================
                Positioned(top: 18, right: 30, child: _sparkle(20)),

                Positioned(bottom: 26, left: 26, child: _sparkle(14)),

                Positioned(left: 10, top: 70, child: _sparkle(12)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _sparkle(double size) {
    return Opacity(
      opacity: .85 + (.15 * _pulseController.value),
      child: Icon(Icons.auto_awesome, color: AppColors.primary, size: size),
    );
  }
}

class _RingPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        colors: [
          Colors.transparent,
          AppColors.primary.withOpacity(.15),
          AppColors.primary,
          AppColors.primary.withOpacity(.15),
          Colors.transparent,
        ],
      ).createShader(rect);

    canvas.drawArc(
      Rect.fromLTWH(3, 3, size.width - 6, size.height - 6),
      0,
      pi * 1.65,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
