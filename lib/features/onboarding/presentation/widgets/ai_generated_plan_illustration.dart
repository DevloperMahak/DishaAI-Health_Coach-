import 'dart:math';

import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';

class AIGeneratedPlanIllustration extends StatefulWidget {
  const AIGeneratedPlanIllustration({super.key});

  @override
  State<AIGeneratedPlanIllustration> createState() =>
      _AIGeneratedPlanIllustrationState();
}

class _AIGeneratedPlanIllustrationState
    extends State<AIGeneratedPlanIllustration>
    with TickerProviderStateMixin {
  late final AnimationController _rotationController;
  late final AnimationController _pulseController;
  late final AnimationController _floatingController;

  @override
  void initState() {
    super.initState();

    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14),
    )..repeat();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);

    _floatingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _pulseController.dispose();
    _floatingController.dispose();
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
      animation: Listenable.merge([
        _rotationController,
        _pulseController,
        _floatingController,
      ]),
      builder: (_, __) {
        final pulse = 1 + (_pulseController.value * .03);

        final floating = sin(_floatingController.value * pi * 2) * 6;

        return Transform.translate(
          offset: Offset(0, floating),
          child: Transform.scale(
            scale: pulse,
            child: SizedBox(
              width: size,
              height: size,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  //==================================================
                  // GLOW
                  //==================================================
                  Container(
                    width: size * .78,
                    height: size * .78,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(.18),
                          blurRadius: 60,
                          spreadRadius: 20,
                        ),
                      ],
                    ),
                  ),

                  //==================================================
                  // OUTER RING
                  //==================================================
                  Transform.rotate(
                    angle: _rotationController.value * pi * 2,
                    child: CustomPaint(
                      size: Size.square(size * .92),
                      painter: _PlanRingPainter(),
                    ),
                  ),

                  //==================================================
                  // IMAGE
                  //==================================================
                  Hero(
                    tag: "generated_plan",
                    child: Image.asset(
                      "assets/images/Rhea_Plan.png",
                      width: size,
                      fit: BoxFit.contain,
                    ),
                  ),

                  //==================================================
                  // FLOATING ICONS
                  //==================================================
                  _orbitIcon(
                    angle: 0,
                    radius: size * .42,
                    icon: Icons.favorite_rounded,
                  ),

                  _orbitIcon(
                    angle: 60,
                    radius: size * .43,
                    icon: Icons.restaurant_rounded,
                  ),

                  _orbitIcon(
                    angle: 120,
                    radius: size * .42,
                    icon: Icons.fitness_center_rounded,
                  ),

                  _orbitIcon(
                    angle: 180,
                    radius: size * .43,
                    icon: Icons.water_drop_rounded,
                  ),

                  _orbitIcon(
                    angle: 240,
                    radius: size * .42,
                    icon: Icons.bedtime_rounded,
                  ),

                  _orbitIcon(
                    angle: 300,
                    radius: size * .43,
                    icon: Icons.self_improvement_rounded,
                  ),

                  Positioned(top: 18, right: 32, child: _sparkle(22)),

                  Positioned(left: 26, bottom: 42, child: _sparkle(16)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _orbitIcon({
    required double angle,
    required double radius,
    required IconData icon,
  }) {
    final radians = (angle + (_rotationController.value * 360)) * pi / 180;

    final x = cos(radians) * radius;
    final y = sin(radians) * radius;

    return Transform.translate(
      offset: Offset(x, y),
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: AppColors.surface,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.primary.withOpacity(.35)),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(.15),
              blurRadius: 10,
            ),
          ],
        ),
        child: Icon(icon, size: 18, color: AppColors.primary),
      ),
    );
  }

  Widget _sparkle(double size) {
    return Opacity(
      opacity: .65 + (_pulseController.value * .35),
      child: Icon(Icons.auto_awesome, size: size, color: AppColors.primary),
    );
  }
}

class _PlanRingPainter extends CustomPainter {
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
      pi * 1.75,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
