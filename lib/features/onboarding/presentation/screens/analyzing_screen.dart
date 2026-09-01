import 'dart:async';
import 'package:disha_ai/features/ai_health_coach/presentation/controllers/ai_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../app/theme/app_colors.dart';
import '../widgets/onboarding_top_bar.dart';
import '../widgets/ai_analyzing_logo.dart';

class AnalyzingScreen extends StatefulWidget {
  const AnalyzingScreen({super.key});

  @override
  State<AnalyzingScreen> createState() => _AnalyzingScreenState();
}

class _AnalyzingScreenState extends State<AnalyzingScreen> {
  //==============================================================
  // CONTROLLERS
  //==============================================================

  final AiController _aiController = Get.put(AiController());

  //==============================================================
  // ONBOARDING
  //==============================================================

  static const int _currentStep = 8;
  static const int _totalSteps = 9;

  //==============================================================
  // PROGRESS
  //==============================================================

  double _progress = 0;
  Timer? _timer;
  int _messageIndex = 0;

  bool _isApiDone = false;
  bool _isApiSuccess = false;

  final List<String> _messages = [
    "Analyzing your health profile...",
    "Processing your lifestyle...",
    "Building your nutrition plan...",
    "Preparing your workout plan...",
    "Finalizing your AI coach...",
  ];

  //==============================================================
  // INIT
  //==============================================================

  @override
  void initState() {
    super.initState();
    _startAnalysis();
  }

  //==============================================================
  // DISPOSE
  //==============================================================

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  //==============================================================
  // ANALYSIS (API INTEGRATED)
  //==============================================================

  void _startAnalysis() {
    // 1. Start the actual API call in the background
    _aiController.analyzeProfile().then((success) {
      if (mounted) {
        setState(() {
          _isApiDone = true;
          _isApiSuccess = success;
        });
      }
    });

    // 2. Start the visual progress animation
    _timer = Timer.periodic(const Duration(milliseconds: 80), (timer) {
      if (!mounted) return;

      setState(() {
        if (!_isApiDone && _progress < 0.85) {
          // Cap the fake progress at 85% while waiting for the API
          _progress += 0.01;
        } else if (_isApiDone && _isApiSuccess) {
          // API is done successfully, rush the progress to 100%
          _progress += 0.05;
        } else if (_isApiDone && !_isApiSuccess) {
          // API failed. Stop timer and show error.
          timer.cancel();
          Get.snackbar(
            "Analysis Failed",
            _aiController.errorMessage.value.isNotEmpty
                ? _aiController.errorMessage.value
                : "Unable to analyze profile at this time.",
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.redAccent.withOpacity(0.9),
            colorText: Colors.white,
            margin: const EdgeInsets.all(16),
          );
          // Let the user decide to press "Skip" or we could add a retry button.
        }

        // Clamp progress
        if (_progress >= 1) {
          _progress = 1;
        }

        final index = (_progress * _messages.length).floor();
        _messageIndex = index.clamp(0, _messages.length - 1);
      });

      // 3. Complete and Navigate
      if (_progress >= 1) {
        timer.cancel();

        Future.delayed(const Duration(milliseconds: 500), () {
          if (!mounted) return;
          Get.offNamed(AppRoutes.analysisComplete);
        });
      }
    });
  }

  //==============================================================
  // SKIP
  //==============================================================

  void _skip() {
    _timer?.cancel();
    Get.offNamed(AppRoutes.analysisComplete);
  }

  //==============================================================
  // RESPONSIVE
  //==============================================================

  double _scale(double width) {
    return (width / 390).clamp(.88, 1.12);
  }

  double _spacing(double width, double value) {
    return value * _scale(width);
  }

  double _horizontalPadding(double width) {
    if (width <= 340) return 16;
    if (width <= 380) return 20;
    if (width <= 430) return 22;
    return 28;
  }

  //==============================================================
  // BUILD
  //==============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final height = constraints.maxHeight;

            if (width >= 700 || width > height) {
              return _buildWideLayout(width: width, height: height);
            }

            return _buildPhoneLayout(width: width, height: height);
          },
        ),
      ),
    );
  }

  Widget _buildPhoneLayout({required double width, required double height}) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: height),
        child: IntrinsicHeight(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: _horizontalPadding(width),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                OnboardingTopBar(
                  currentStep: _currentStep,
                  totalSteps: _totalSteps,
                  onBack: () => Get.back(),
                  onSkip: _skip,
                ),
                const Spacer(),
                Center(child: AIAnalyzingLogo(progress: _progress)),
                SizedBox(height: _spacing(width, 32)),
                _buildTitle(width),
                SizedBox(height: _spacing(width, 10)),
                _buildSubtitle(width),
                SizedBox(height: _spacing(width, 34)),
                _buildProgress(width),
                SizedBox(height: _spacing(width, 30)),
                _buildTipCard(width),
                const Spacer(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWideLayout({required double width, required double height}) {
    final horizontalPadding = width >= 1200
        ? 100.0
        : width >= 900
        ? 70.0
        : 40.0;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: height),
        child: IntrinsicHeight(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 650),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: horizontalPadding,
                  vertical: 28,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    OnboardingTopBar(
                      currentStep: _currentStep,
                      totalSteps: _totalSteps,
                      onBack: () => Get.back(),
                      onSkip: _skip,
                    ),
                    const Spacer(),
                    Center(child: AIAnalyzingLogo(progress: _progress)),
                    const SizedBox(height: 36),
                    _buildTitle(width),
                    const SizedBox(height: 12),
                    _buildSubtitle(width),
                    const SizedBox(height: 36),
                    _buildProgress(width),
                    const SizedBox(height: 32),
                    _buildTipCard(width),
                    const Spacer(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTitle(double width) {
    final scale = _scale(width);
    final fontSize = (22 * scale).clamp(20.0, 26.0);

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 350),
      child: Text(
        _messages[_messageIndex],
        key: ValueKey(_messages[_messageIndex]),
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w700,
          color: AppColors.primary,
          height: 1.2,
        ),
      ),
    );
  }

  Widget _buildSubtitle(double width) {
    final scale = _scale(width);
    final fontSize = (13 * scale).clamp(12.0, 15.0);

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: Text(
        key: ValueKey(_messageIndex),
        "Our AI is securely processing your information to create a personalized nutrition, workout and wellness plan just for you.",
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: fontSize,
          color: AppColors.textSecondary,
          height: 1.6,
        ),
      ),
    );
  }

  Widget _buildProgress(double width) {
    final scale = _scale(width);
    final percent = (_progress * 100).round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(100),
          child: LinearProgressIndicator(
            value: _progress,
            minHeight: (8 * scale).clamp(6.0, 10.0),
            backgroundColor: AppColors.textSecondary.withOpacity(.18),
            valueColor: const AlwaysStoppedAnimation(AppColors.primary),
          ),
        ),
        SizedBox(height: 12 * scale),
        Row(
          children: [
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Text(
                  _messages[_messageIndex],
                  key: ValueKey(_messageIndex),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: (12 * scale).clamp(11.0, 14.0),
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              transitionBuilder: (child, animation) {
                return ScaleTransition(
                  scale: animation,
                  child: FadeTransition(opacity: animation, child: child),
                );
              },
              child: Text(
                "$percent%",
                key: ValueKey(percent),
                style: TextStyle(
                  fontSize: (14 * scale).clamp(13.0, 16.0),
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTipCard(double width) {
    final scale = _scale(width);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16 * scale),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withOpacity(.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42 * scale,
            height: 42 * scale,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary.withOpacity(.12),
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: AppColors.primary,
            ),
          ),
          SizedBox(width: 14 * scale),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "AI Tip",
                  style: TextStyle(
                    fontSize: (13 * scale).clamp(12.0, 15.0),
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
                SizedBox(height: 4 * scale),
                Text(
                  "This usually takes only a few seconds while we prepare recommendations tailored specifically for you.",
                  style: TextStyle(
                    fontSize: (12 * scale).clamp(11.0, 14.0),
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
