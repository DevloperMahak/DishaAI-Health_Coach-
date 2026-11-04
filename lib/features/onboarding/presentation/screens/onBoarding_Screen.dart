import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../app/theme/app_colors.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  // ============================================================
  // CONSTANTS
  // ============================================================

  static const int _pageCount = 3;

  static const Duration _conditionDuration =
      Duration(milliseconds: 2600);

  // ============================================================
  // LEGAL URLS
  // ============================================================

  static final Uri _privacyPolicyUrl = Uri.parse(
    'https://rhea-ai.acttconnect.com/privacy',
  );

  static final Uri _termsConditionsUrl = Uri.parse(
    'https://rhea-ai.acttconnect.com/terms',
  );

  // ============================================================
  // PAGE
  // ============================================================

  late final PageController _pageController;

  int _currentPage = 0;

  // ============================================================
  // CONDITIONS
  // ============================================================

  final List<String> _conditions = [
    'Diabetes',
    'Thyroid',
    'Heart Disease',
    'PCOS',
    'Obesity',
  ];

  int _conditionIndex = 0;

  Timer? _conditionTimer;

  late final AnimationController _conditionAnimationController;

  late final Animation<double> _conditionFadeAnimation;

  late final Animation<Offset> _conditionSlideAnimation;

  // ============================================================
  // MAIN ANIMATION
  // ============================================================

  late final AnimationController _animationController;

  late final Animation<double> _fadeAnimation;

  late final Animation<Offset> _slideAnimation;

  late final Animation<double> _imageScaleAnimation;

  // ============================================================
  // STATE
  // ============================================================

  bool _termsAccepted = false;

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    _pageController = PageController();

    // ----------------------------------------------------------
    // MAIN ANIMATION
    // ----------------------------------------------------------

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.025),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
      ),
    );

    _imageScaleAnimation = Tween<double>(
      begin: 0.96,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutBack,
      ),
    );

    // ----------------------------------------------------------
    // CONDITION ANIMATION
    // ----------------------------------------------------------

    _conditionAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );

    _conditionFadeAnimation = CurvedAnimation(
      parent: _conditionAnimationController,
      curve: Curves.easeInOut,
    );

    _conditionSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.25),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _conditionAnimationController,
        curve: Curves.easeOutCubic,
      ),
    );

    // ----------------------------------------------------------
    // START
    // ----------------------------------------------------------

    _animationController.forward();

    _conditionAnimationController.forward();

    _startConditionAnimation();
  }

  // ============================================================
  // CONDITION TIMER
  // ============================================================

  void _startConditionAnimation() {
    _conditionTimer?.cancel();

    _conditionTimer = Timer.periodic(
      _conditionDuration,
      (_) {
        if (!mounted) return;

        _changeCondition();
      },
    );
  }

  // ============================================================
  // CHANGE CONDITION
  // ============================================================

  Future<void> _changeCondition() async {
    if (!mounted) return;

    await _conditionAnimationController.reverse();

    if (!mounted) return;

    setState(() {
      _conditionIndex =
          (_conditionIndex + 1) % _conditions.length;
    });

    _conditionAnimationController.forward();
  }

  // ============================================================
  // OPEN LEGAL URL
  // ============================================================

  Future<void> _openLegalUrl(
    Uri url,
    String title,
  ) async {
    if (!mounted) return;

    try {
      final bool launched = await launchUrl(
        url,
        mode: LaunchMode.externalApplication,
      );

      if (!launched) {
        _showLegalError(title);
      }
    } catch (e, stackTrace) {
      debugPrint('LEGAL URL ERROR ($title): $e');
      debugPrint('$stackTrace');

      _showLegalError(title);
    }
  }

  // ============================================================
  // LEGAL ERROR HANDLING
  // ============================================================

  void _showLegalError(String title) {
    if (!mounted) return;

    Get.snackbar(
      'Unable to open $title',
      'Please check your internet connection and try again.',
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(16),
      backgroundColor: AppColors.surface,
      colorText: AppColors.textPrimary,
      borderColor: AppColors.primary,
      borderWidth: 1,
      duration: const Duration(seconds: 3),
      icon: const Icon(
        Icons.error_outline_rounded,
        color: Colors.redAccent,
      ),
    );
  }

  // ============================================================
  // TERMS OF SERVICE - LIVE URL
  // ============================================================

  Future<void> _handleTermsOfService() async {
    await _openLegalUrl(
      _termsConditionsUrl,
      'Terms & Conditions',
    );
  }

  // ============================================================
  // PRIVACY POLICY - LIVE URL
  // ============================================================

  Future<void> _handlePrivacyPolicy() async {
    await _openLegalUrl(
      _privacyPolicyUrl,
      'Privacy Policy',
    );
  }

  // ============================================================
  // GET STARTED
  // ============================================================

  void _getStarted() {
    if (!_termsAccepted) {
      Get.snackbar(
        'Terms & Privacy'.tr,
        'Please accept the Terms of Service and Privacy Policy to continue.'.tr,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
        backgroundColor: AppColors.surface,
        colorText: AppColors.textPrimary,
        borderColor: AppColors.primary,
        borderWidth: 1,
      );

      return;
    }

    Get.toNamed(AppRoutes.primaryHealthGoal);
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _pageController.dispose();

    _conditionTimer?.cancel();

    _animationController.dispose();

    _conditionAnimationController.dispose();

    super.dispose();
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

            if (width >= 700 || width > height) {
              return _buildWideLayout(
                width: width,
                height: height,
              );
            }

            return _buildPhoneLayout(
              width: width,
              height: height,
            );
          },
        ),
      ),
    );
  }

  // ============================================================
  // PHONE LAYOUT
  // ============================================================

  Widget _buildPhoneLayout({
    required double width,
    required double height,
  }) {
    final horizontalPadding = _getHorizontalPadding(width);

    final heroHeight = _calculateHeroHeight(height);

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Column(
          children: [
            // ==================================================
            // MAIN CONTENT
            // ==================================================

            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: height - 45,
                  ),
                  child: Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        height: heroHeight,
                        child: _buildHero(
                          width: width,
                          height: heroHeight,
                        ),
                      ),

                      SizedBox(
                        height: _getHeroContentGap(height),
                      ),

                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: horizontalPadding,
                        ),
                        child: _buildOnboardingContent(
                          width: width -
                              (horizontalPadding * 2),
                          height: height,
                        ),
                      ),

                      const SizedBox(height: 35),
                    ],
                  ),
                ),
              ),
            ),

            // ==================================================
            // FIXED BOTTOM FOOTER
            // ==================================================

            Padding(
              padding: const EdgeInsets.only(
                top: 8,
                bottom: 12,
              ),
              child: _buildFooter(width: width),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // HORIZONTAL PADDING
  // ============================================================

  double _getHorizontalPadding(double width) {
    if (width <= 340) return 18;

    if (width <= 380) return 20;

    if (width <= 430) return 22;

    return 28;
  }

  // ============================================================
  // HERO HEIGHT
  // ============================================================

  double _calculateHeroHeight(double height) {
    if (height <= 580) return height * 0.40;

    if (height <= 650) return height * 0.42;

    if (height <= 720) return height * 0.44;

    if (height <= 800) return height * 0.46;

    return height * 0.48;
  }

  double _getHeroContentGap(double height) {
    if (height <= 600) return 10;

    if (height <= 700) return 14;

    return 18;
  }

  // ============================================================
  // WIDE / TABLET
  // ============================================================

  Widget _buildWideLayout({
    required double width,
    required double height,
  }) {
    final horizontalPadding = width >= 1200
        ? 70.0
        : width >= 900
            ? 45.0
            : 30.0;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: horizontalPadding,
            vertical: 16,
          ),
          child: Column(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      flex: 6,
                      child: SizedBox(
                        height: height * 0.88,
                        child: _buildHero(
                          width: width * 0.55,
                          height: height * 0.88,
                        ),
                      ),
                    ),

                    SizedBox(
                      width: width >= 1100 ? 80 : 45,
                    ),

                    Expanded(
                      flex: 4,
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                            maxWidth: 500,
                          ),
                          child: SingleChildScrollView(
                            physics:
                                const BouncingScrollPhysics(),
                            child: _buildOnboardingContent(
                              width: width * 0.40,
                              height: height,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.only(
                  bottom: 8,
                ),
                child: _buildFooter(width: width),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // HERO
  // ============================================================

  Widget _buildHero({
    required double width,
    required double height,
  }) {
    return AnimatedBuilder(
      animation: _imageScaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _imageScaleAnimation.value,
          child: child,
        );
      },
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: width < 380 ? 2 : 6,
          vertical: 2,
        ),
        child: Image.asset(
          'assets/images/Onboarding.jpeg',
          width: width,
          height: height,
          fit: BoxFit.contain,
          alignment: Alignment.center,
        ),
      ),
    );
  }

  // ============================================================
  // ONBOARDING CONTENT
  // ============================================================

  Widget _buildOnboardingContent({
    required double width,
    required double height,
  }) {
    final scale = (width / 390).clamp(0.90, 1.12);

    final titleSize =
        (22.0 * scale).clamp(20.0, 24.0);

    final buttonTextSize =
        (14.0 * scale).clamp(13.0, 15.5);

    final termsSize =
        (10.5 * scale).clamp(9.0, 11.5);

    final titleGap =
        (5.0 * scale).clamp(4.0, 6.0);

    final descriptionGap =
        (14.0 * scale).clamp(12.0, 17.0);

    final indicatorGap =
        (28.0 * scale).clamp(24.0, 32.0);

    final buttonGap =
        (22.0 * scale).clamp(18.0, 25.0);

    final termsGap =
        (14.0 * scale).clamp(12.0, 17.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ======================================================
        // TITLE
        // ======================================================

        Text(
          'Your Personal Coach For'.tr,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: titleSize,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
            height: 1.18,
          ),
        ),

        SizedBox(height: titleGap),

        // ======================================================
        // ANIMATED CONDITION
        // ======================================================

        SizedBox(
          height: titleSize * 1.30,
          width: double.infinity,
          child: ClipRect(
            child: FadeTransition(
              opacity: _conditionFadeAnimation,
              child: SlideTransition(
                position: _conditionSlideAnimation,
                child: Text(
                  _conditions[_conditionIndex].tr,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: titleSize,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                    height: 1.18,
                  ),
                ),
              ),
            ),
          ),
        ),

        SizedBox(height: descriptionGap),

        // ======================================================
        // DESCRIPTION
        // ======================================================

        Text(
          'Diet, exercise & mental health.\nHelp when you need it.'.tr,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: AppColors.primary,
            height: 1.55,
          ),
        ),

        SizedBox(height: indicatorGap),

        // ======================================================
        // PAGE INDICATORS
        // ======================================================

        _buildPageIndicators(scale: scale),

        SizedBox(height: buttonGap),

        // ======================================================
        // GET STARTED
        // ======================================================

        _buildGetStartedButton(
          scale: scale,
          fontSize: buttonTextSize,
        ),

        SizedBox(height: termsGap),

        // ======================================================
        // TERMS & PRIVACY
        // ======================================================

        _buildTermsSection(
          scale: scale,
          fontSize: termsSize,
        ),
      ],
    );
  }

  // ============================================================
  // PAGE INDICATORS
  // ============================================================

  Widget _buildPageIndicators({
    required double scale,
  }) {
    final inactiveSize =
        (7.5 * scale).clamp(6.5, 8.5);

    final activeSize =
        (9.5 * scale).clamp(8.0, 10.5);

    return SizedBox(
      width: double.infinity,
      height: activeSize,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(
          _pageCount,
          (index) {
            final active = index == _currentPage;

            return AnimatedContainer(
              duration:
                  const Duration(milliseconds: 220),
              margin: EdgeInsets.symmetric(
                horizontal: 5 * scale,
              ),
              width:
                  active ? activeSize : inactiveSize,
              height:
                  active ? activeSize : inactiveSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: active
                    ? AppColors.primary
                    : AppColors.textSecondary
                        .withOpacity(0.75),
              ),
            );
          },
        ),
      ),
    );
  }

  // ============================================================
  // GET STARTED BUTTON
  // ============================================================

  Widget _buildGetStartedButton({
    required double scale,
    required double fontSize,
  }) {
    final buttonHeight =
        (50.0 * scale).clamp(47.0, 54.0);

    final radius =
        (9.0 * scale).clamp(8.0, 11.0);

    return SizedBox(
      width: double.infinity,
      height: buttonHeight,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius:
              BorderRadius.circular(radius),
          gradient: const LinearGradient(
            colors: [
              AppColors.primaryDark,
              AppColors.primary,
            ],
          ),
          boxShadow: [
            BoxShadow(
              color:
                  AppColors.primary.withOpacity(0.18),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: _getStarted,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.black,
            shadowColor: Colors.transparent,
            elevation: 0,
            padding: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.circular(radius),
            ),
          ),
          child: Row(
            mainAxisAlignment:
                MainAxisAlignment.center,
            children: [
              Text(
                "Let's Get Started".tr,
                style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                  height: 1.0,
                ),
              ),

              SizedBox(width: 9 * scale),

              Icon(
                Icons.arrow_forward_rounded,
                size:
                    (17 * scale).clamp(16.0, 19.0),
                color: Colors.black,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // TERMS & PRIVACY POLICY
  //
  // Both links are individually clickable.
  // Clicking a link does NOT change checkbox state.
  // ============================================================

  Widget _buildTermsSection({
    required double scale,
    required double fontSize,
  }) {
    final checkboxSize =
        (17 * scale).clamp(16.0, 19.0);

    final textStyle = TextStyle(
      fontSize: fontSize,
      fontWeight: FontWeight.w400,
      color: AppColors.primary,
      height: 1.45,
    );

    final linkStyle = textStyle.copyWith(
      fontWeight: FontWeight.w600,
      decoration: TextDecoration.underline,
      decorationColor: AppColors.primary,
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ======================================================
        // CHECKBOX
        // ======================================================

        SizedBox(
          width: checkboxSize,
          height: checkboxSize,
          child: Checkbox(
            value: _termsAccepted,
            onChanged: (value) {
              setState(() {
                _termsAccepted = value ?? false;
              });
            },
            activeColor: AppColors.primary,
            checkColor: Colors.black,
            side: const BorderSide(
              color: AppColors.primary,
              width: 1,
            ),
            materialTapTargetSize:
                MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
          ),
        ),

        SizedBox(width: 7 * scale),

        // ======================================================
        // AGREEMENT TEXT WITH CLICKABLE LINKS
        // ======================================================

        Expanded(
          child: Text.rich(
            TextSpan(
              style: textStyle,
              children: [
                // AGREEMENT TEXT
                TextSpan(
                  text:
                      'By clicking, you agree to our '.tr,
                ),

                // TERMS OF SERVICE - LIVE URL
                WidgetSpan(
                  alignment:
                      PlaceholderAlignment.baseline,
                  baseline:
                      TextBaseline.alphabetic,
                  child: InkWell(
                    onTap: _handleTermsOfService,
                    borderRadius:
                        BorderRadius.circular(3),
                    child: Text(
                      'Terms of Service'.tr,
                      style: linkStyle,
                    ),
                  ),
                ),

                // CONNECTING TEXT
                TextSpan(
                  text: ' and '.tr,
                ),

                // PRIVACY POLICY - LIVE URL
                WidgetSpan(
                  alignment:
                      PlaceholderAlignment.baseline,
                  baseline:
                      TextBaseline.alphabetic,
                  child: InkWell(
                    onTap: _handlePrivacyPolicy,
                    borderRadius:
                        BorderRadius.circular(3),
                    child: Text(
                      'Privacy Policy'.tr,
                      style: linkStyle,
                    ),
                  ),
                ),
              ],
            ),
            textAlign: TextAlign.center,
            softWrap: true,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // FOOTER
  // ============================================================

  Widget _buildFooter({
    required double width,
  }) {
    final scale =
        (width / 390).clamp(0.92, 1.10);

    final fontSize =
        (10.5 * scale).clamp(9.5, 12.0);

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: 20 * scale,
      ),
      child: Text(
        '© Powered by ACT T Connect Pvt. Ltd',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w400,
          color: AppColors.primary,
          height: 1.3,
        ),
      ),
    );
  }
}