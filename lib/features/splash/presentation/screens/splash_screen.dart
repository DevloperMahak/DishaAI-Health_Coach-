import 'package:disha_ai/features/authentication/presentation/controllers/auth_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../core/storage/auth_storage.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _logoController;
  late final AnimationController _textController;
  late final AnimationController _exitController;

  late final Animation<double> _logoScale;
  late final Animation<double> _logoOpacity;
  late final Animation<double> _logoOffset;

  late final Animation<double> _brandOpacity;
  late final Animation<double> _brandOffset;

  late final Animation<double> _taglineOpacity;
  late final Animation<double> _taglineOffset;

  late final Animation<double> _footerOpacity;

  late final Animation<double> _exitOpacity;
  late final Animation<double> _exitScale;

  final AuthStorage _authStorage = AuthStorage.instance;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startAnimationSequence();
  }

  void _initializeAnimations() {
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _logoScale = Tween<double>(begin: 0.78, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeOutBack),
    );

    _logoOpacity = CurvedAnimation(
      parent: _logoController,
      curve: const Interval(0.0, 0.55, curve: Curves.easeOut),
    );

    _logoOffset = Tween<double>(begin: 18, end: 0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeOutCubic),
    );

    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _brandOpacity = CurvedAnimation(
      parent: _textController,
      curve: const Interval(0.0, 0.55, curve: Curves.easeOut),
    );

    _brandOffset = Tween<double>(begin: 14, end: 0).animate(
      CurvedAnimation(
        parent: _textController,
        curve: const Interval(0.0, 0.65, curve: Curves.easeOutCubic),
      ),
    );

    _taglineOpacity = CurvedAnimation(
      parent: _textController,
      curve: const Interval(0.30, 1.0, curve: Curves.easeOut),
    );

    _taglineOffset = Tween<double>(begin: 10, end: 0).animate(
      CurvedAnimation(
        parent: _textController,
        curve: const Interval(0.30, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    _footerOpacity = CurvedAnimation(
      parent: _textController,
      curve: const Interval(0.55, 1.0, curve: Curves.easeOut),
    );

    _exitController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );

    _exitOpacity = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _exitController, curve: Curves.easeInCubic),
    );

    _exitScale = Tween<double>(begin: 1.0, end: 1.025).animate(
      CurvedAnimation(parent: _exitController, curve: Curves.easeInCubic),
    );
  }

  Future<void> _startAnimationSequence() async {
    await _logoController.forward();
    if (!mounted) return;

    await _textController.forward();
    if (!mounted) return;

    await Future.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;

    final destination = await _determineInitialRoute();
    if (!mounted) return;

    await _exitController.forward();
    if (!mounted) return;

    Get.offNamed(destination);
  }

  Future<String> _determineInitialRoute() async {
    print('');
    print('==========================================');
    print('           SPLASH AUTH CHECK');
    print('==========================================');

    final token = _authStorage.accessToken;

    print('TOKEN EXISTS: ${token != null && token.isNotEmpty}');
    print('TOKEN LENGTH: ${token?.length ?? 0}');
    print('ACCESS TOKEN: $token'); // <--- Added full access token print

    if (token == null || token.isEmpty) {
      print('❌ NO ACCESS TOKEN');
      print('➡️ ROUTE: LOGIN');
      print('==========================================');
      return AppRoutes.login;
    }

    print('✅ ACCESS TOKEN FOUND');

    Map<String, dynamic>? user = _authStorage.currentUser;
    print('STORED USER EXISTS: ${user != null}');

    if (user == null) {
      print('⚠️ STORED USER NOT FOUND');
      print('🔄 FETCHING USER FROM SERVER...');

      try {
        final authController = Get.isRegistered<AuthController>()
            ? Get.find<AuthController>()
            : Get.put(AuthController());

        final result = await authController.getCurrentUser();

        if (result['success'] == true) {
          user = _authStorage.currentUser;
          print('✅ USER FETCHED SUCCESSFULLY');
        } else {
          print('❌ FAILED TO FETCH USER: ${result['message']}');
        }
      } catch (e) {
        print('❌ USER FETCH ERROR: $e');
      }
    }

    if (user == null) {
      print('⚠️ USER DATA NOT AVAILABLE');
      print('➡️ ROUTE: LOGIN');
      print('==========================================');
      return AppRoutes.login;
    }

    final onboardingCompleted = _parseBool(user['onboarding_completed']);
    print('ONBOARDING COMPLETED: $onboardingCompleted');

    print('🟢 ONBOARDING COMPLETED');
    print('➡️ ROUTE: DASHBOARD');
    print('==========================================');

    return AppRoutes.dashboard;
  }

  bool _parseBool(dynamic value) {
    if (value is bool) return value;
    if (value is String) return value.toLowerCase() == 'true';
    if (value is int) return value == 1;
    return false;
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    _exitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: AnimatedBuilder(
        animation: _exitController,
        builder: (context, child) {
          return Opacity(
            opacity: _exitOpacity.value,
            child: Transform.scale(scale: _exitScale.value, child: child),
          );
        },
        child: SafeArea(
          child: Stack(
            children: [
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedBuilder(
                      animation: _logoController,
                      builder: (context, child) {
                        return Opacity(
                          opacity: _logoOpacity.value,
                          child: Transform.translate(
                            offset: Offset(0, _logoOffset.value),
                            child: Transform.scale(
                              scale: _logoScale.value,
                              child: child,
                            ),
                          ),
                        );
                      },
                      child: Image.asset(
                        'assets/images/RheaAI_Logo.png',
                        width: 195,
                        height: 195,
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(height: 18),
                    AnimatedBuilder(
                      animation: _textController,
                      builder: (context, child) {
                        return Opacity(
                          opacity: _brandOpacity.value,
                          child: Transform.translate(
                            offset: Offset(0, _brandOffset.value),
                            child: child,
                          ),
                        );
                      },
                      child: const Text(
                        'RHEA AI',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                          color: Color(0xFFFFC400),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    AnimatedBuilder(
                      animation: _textController,
                      builder: (context, child) {
                        return Opacity(
                          opacity: _taglineOpacity.value,
                          child: Transform.translate(
                            offset: Offset(0, _taglineOffset.value),
                            child: child,
                          ),
                        );
                      },
                      child: const Text(
                        'Your AI Health Companion',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                          letterSpacing: 0.2,
                          color: Color(0xFFFFC400),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 8,
                child: FadeTransition(
                  opacity: _footerOpacity,
                  child: const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'All rights reserved',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 7,
                          fontWeight: FontWeight.w400,
                          color: Color(0xFFFFC400),
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        '© Powered by ACT T Connect Pvt. Ltd',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 7,
                          fontWeight: FontWeight.w400,
                          color: Color(0xFFFFC400),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
