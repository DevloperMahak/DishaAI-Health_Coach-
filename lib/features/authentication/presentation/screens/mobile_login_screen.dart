import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart'; // Added GetStorage

import '../../../../app/routes/app_routes.dart';
import '../../../../app/theme/app_colors.dart';
import '../controllers/auth_controller.dart';

class MobileLoginScreen extends StatefulWidget {
  const MobileLoginScreen({super.key});

  @override
  State<MobileLoginScreen> createState() => _MobileLoginScreenState();
}

class _MobileLoginScreenState extends State<MobileLoginScreen>
    with SingleTickerProviderStateMixin {
  // ============================================================
  // CONTROLLERS
  // ============================================================

  final TextEditingController _phoneController = TextEditingController();
  final FocusNode _phoneFocusNode = FocusNode();

  // ============================================================
  // AUTH CONTROLLER
  // ============================================================

  late final AuthController _authController;

  // ============================================================
  // ANIMATION
  // ============================================================

  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;
  late final Animation<double> _imageScaleAnimation;

  // ============================================================
  // STATE
  // ============================================================

  bool _isPhoneValid = false;
  bool _isSendingOtp = false;
  String _selectedLanguage = 'en'; // Added local language state

  // ============================================================
  // LIFECYCLE
  // ============================================================

  @override
  void initState() {
    super.initState();

    // Fetch the previously saved language from storage
    _selectedLanguage = GetStorage().read('preferred_language') ?? 'en';

    // ----------------------------------------------------------
    // AUTH CONTROLLER
    // ----------------------------------------------------------
    _authController = Get.put(AuthController(), tag: 'mobile_login_auth');

    // ==========================================================
    // ANIMATION
    // ==========================================================

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.025), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
        );

    _imageScaleAnimation = Tween<double>(begin: 0.96, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );

    _animationController.forward();

    // ==========================================================
    // PHONE VALIDATION
    // ==========================================================

    _phoneController.addListener(_validatePhoneNumber);
    _phoneFocusNode.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });
  }

  // ============================================================
  // CHANGE LANGUAGE (LOCAL)
  // ============================================================

  void _changeLanguage(String langCode) {
    // 1. Save locally
    GetStorage().write('preferred_language', langCode);

    // 2. Set Locale
    Locale newLocale = langCode == 'hi'
        ? const Locale('hi', 'IN')
        : const Locale('en', 'US');

    // 3. Apply instantly to UI
    Get.updateLocale(newLocale);

    setState(() {
      _selectedLanguage = langCode;
    });
  }

  // ============================================================
  // PHONE VALIDATION
  // ============================================================

  void _validatePhoneNumber() {
    final phone = _phoneController.text.trim();
    final valid =
        phone.length == 10 && RegExp(r'^[6-9][0-9]{9}$').hasMatch(phone);

    if (valid != _isPhoneValid) {
      setState(() {
        _isPhoneValid = valid;
      });
    }
  }

  // ============================================================
  // SEND OTP
  // ============================================================

  Future<void> _continue() async {
    if (!_isPhoneValid || _isSendingOtp) {
      return;
    }

    FocusScope.of(context).unfocus();

    final phone = _phoneController.text.trim();

    setState(() {
      _isSendingOtp = true;
    });

    try {
      final response = await _authController.sendOtp(mobile: phone);

      if (!mounted) {
        return;
      }

      setState(() {
        _isSendingOtp = false;
      });

      if (response['success'] == true) {
        Get.toNamed(
          AppRoutes.otpVerification,
          arguments: {'phoneNumber': phone},
        );
        return;
      }

      _showError(
        response['message'] ?? 'Unable to send OTP. Please try again.'.tr,
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isSendingOtp = false;
      });

      _showError('Something went wrong. Please try again.'.tr);
    }
  }

  void _showError(String message) {
    Get.snackbar(
      'Unable to send OTP'.tr,
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: AppColors.surface,
      colorText: AppColors.textPrimary,
      borderColor: AppColors.primary,
      borderWidth: 1,
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 3),
      icon: Icon(Icons.error_outline_rounded, color: AppColors.error),
    );
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _phoneController.dispose();
    _phoneFocusNode.dispose();
    _animationController.dispose();

    if (Get.isRegistered<AuthController>(tag: 'mobile_login_auth')) {
      Get.delete<AuthController>(tag: 'mobile_login_auth');
    }

    super.dispose();
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final height = constraints.maxHeight;
            final keyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

            if (width >= 700 || width > height) {
              return _buildWideLayout(width: width, height: height);
            }

            return _buildPhoneLayout(
              width: width,
              height: height,
              keyboardOpen: keyboardOpen,
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
    required bool keyboardOpen,
  }) {
    final horizontalPadding = _getHorizontalPadding(width);
    final heroHeight = _calculateHeroHeight(
      height: height,
      keyboardOpen: keyboardOpen,
    );

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: height),
            child: Column(
              children: [
                if (!keyboardOpen)
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      horizontalPadding,
                      8,
                      horizontalPadding,
                      0,
                    ),
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: _buildLanguageSelector(width: width),
                    ),
                  ),
                SizedBox(
                  width: double.infinity,
                  height: heroHeight,
                  child: _buildHero(width: width, height: heroHeight),
                ),
                SizedBox(height: keyboardOpen ? 8 : 18),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                  child: _buildLoginCard(
                    width: width - (horizontalPadding * 2),
                    compact: keyboardOpen,
                  ),
                ),
                if (!keyboardOpen) ...[
                  const SizedBox(height: 18),
                  _buildFooter(width: width),
                  const SizedBox(height: 10),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // RESPONSIVE PADDING
  // ============================================================

  double _getHorizontalPadding(double width) {
    if (width <= 340) return 16;
    if (width <= 380) return 18;
    if (width <= 430) return 20;
    return 24;
  }

  // ============================================================
  // HERO HEIGHT
  // ============================================================

  double _calculateHeroHeight({
    required double height,
    required bool keyboardOpen,
  }) {
    if (keyboardOpen) {
      return (height * 0.28).clamp(145.0, 200.0);
    }
    if (height <= 650) return height * 0.34;
    if (height <= 750) return height * 0.36;
    if (height <= 850) return height * 0.38;
    if (height <= 950) return height * 0.39;
    return 370;
  }

  // ============================================================
  // WIDE / TABLET
  // ============================================================

  Widget _buildWideLayout({required double width, required double height}) {
    final horizontalPadding = width >= 1200
        ? 70.0
        : width >= 900
        ? 45.0
        : 25.0;

    final spacing = width >= 1100 ? 70.0 : 40.0;
    final rightAreaWidth = (width - (horizontalPadding * 2) - spacing) * 0.4;
    final cardWidth = rightAreaWidth > 500.0 ? 500.0 : rightAreaWidth;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: height),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: 20,
              ),
              child: Stack(
                children: [
                  Row(
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
                      SizedBox(width: spacing),
                      Expanded(
                        flex: 4,
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 500),
                            child: _buildLoginCard(
                              width: cardWidth,
                              compact: false,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Positioned(
                    top: 0,
                    right: 0,
                    child: _buildLanguageSelector(width: width),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // LANGUAGE SELECTOR (Updated to functional PopupMenuButton)
  // ============================================================

  Widget _buildLanguageSelector({required double width}) {
    final scale = (width / 390).clamp(0.90, 1.20);
    final height = 38.0 * scale;

    return PopupMenuButton<String>(
      onSelected: _changeLanguage,
      color: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      offset: Offset(
        0,
        height + 5,
      ), // Dropdown appears slightly below the button
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'en',
          child: Text(
            'English',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const PopupMenuItem(
          value: 'hi',
          child: Text(
            'Hindi (हिंदी)',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
      child: Container(
        height: height,
        padding: EdgeInsets.symmetric(horizontal: 12 * scale),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(height / 2),
          border: Border.all(
            color: AppColors.primary.withOpacity(0.85),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.language_rounded,
              size: 17 * scale,
              color: AppColors.primary,
            ),
            SizedBox(width: 7 * scale),
            Text(
              _selectedLanguage == 'hi' ? 'Hindi' : 'English',
              style: TextStyle(
                fontSize: 12.5 * scale,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(width: 5 * scale),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 17 * scale,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // HERO
  // ============================================================

  Widget _buildHero({required double width, required double height}) {
    return AnimatedBuilder(
      animation: _imageScaleAnimation,
      builder: (context, child) {
        return Transform.scale(scale: _imageScaleAnimation.value, child: child);
      },
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: width < 380 ? 3 : 8,
          vertical: 2,
        ),
        child: Image.asset(
          'assets/images/RheaAI_illustration.png',
          width: width,
          height: height,
          fit: BoxFit.contain,
          alignment: Alignment.center,
        ),
      ),
    );
  }

  // ============================================================
  // LOGIN CARD
  // ============================================================

  Widget _buildLoginCard({required double width, required bool compact}) {
    final scale = (width / 390).clamp(0.94, 1.08);

    // Typography
    final titleSize = 22 * scale;
    final subtitleSize = 14 * scale;
    final inputSize = 14 * scale;
    final helperSize = 13 * scale;
    final buttonTextSize = 15 * scale;
    final securitySize = 12 * scale;

    // Spacing
    final horizontalPadding = width <= 350 ? 18.0 : 20.0;
    final verticalPadding = compact ? 20.0 : 24.0;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        horizontalPadding,
        verticalPadding,
        horizontalPadding,
        verticalPadding,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.primary, width: 1.1),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.12),
            blurRadius: 24,
            spreadRadius: 0,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Welcome to RheaAI'.tr, // Translated
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: titleSize,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
              height: 1.2,
              letterSpacing: 0.1,
            ),
          ),
          SizedBox(height: compact ? 8 : 10),
          Text(
            'Login to continue your health journey'.tr, // Translated
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: subtitleSize,
              fontWeight: FontWeight.w400,
              color: AppColors.textPrimary,
              height: 1.45,
            ),
          ),
          SizedBox(height: compact ? 20 : 24),
          _buildPhoneInput(scale: scale, textSize: inputSize),
          SizedBox(height: compact ? 10 : 11),
          _buildHelperText(scale: scale, fontSize: helperSize),
          SizedBox(height: compact ? 18 : 22),
          _buildContinueButton(
            scale: scale,
            fontSize: buttonTextSize,
            compact: compact,
          ),
          SizedBox(height: compact ? 18 : 22),
          _buildSecurityMessage(scale: scale, fontSize: securitySize),
        ],
      ),
    );
  }

  // ============================================================
  // PHONE INPUT
  // ============================================================

  Widget _buildPhoneInput({required double scale, required double textSize}) {
    final focused = _phoneFocusNode.hasFocus;
    final inputHeight = (54 * scale).clamp(50.0, 58.0);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: double.infinity,
      height: inputHeight,
      decoration: BoxDecoration(
        color: AppColors.black,
        borderRadius: BorderRadius.circular(9 * scale),
        border: Border.all(
          color: focused
              ? AppColors.primary
              : AppColors.primary.withOpacity(0.60),
          width: focused ? 1.3 : 0.8,
        ),
        boxShadow: focused
            ? [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.12),
                  blurRadius: 8,
                ),
              ]
            : null,
      ),
      child: Row(
        children: [
          SizedBox(width: 12 * scale),
          Icon(Icons.phone_rounded, size: 19 * scale, color: AppColors.primary),
          SizedBox(width: 9 * scale),
          Text(
            '+91',
            style: TextStyle(
              fontSize: textSize,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          Container(
            height: inputHeight * 0.52,
            width: 1,
            margin: EdgeInsets.symmetric(horizontal: 11 * scale),
            color: AppColors.primary.withOpacity(0.45),
          ),
          Expanded(
            child: TextField(
              controller: _phoneController,
              focusNode: _phoneFocusNode,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.done,
              maxLength: 10,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onSubmitted: (_) {
                if (_isPhoneValid && !_isSendingOtp) {
                  _continue();
                }
              },
              decoration: InputDecoration(
                hintText: 'Enter your mobile number'.tr, // Translated
                hintStyle: TextStyle(
                  fontSize: textSize,
                  color: AppColors.textSecondary.withOpacity(0.55),
                ),
                border: InputBorder.none,
                counterText: '',
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
              style: TextStyle(
                fontSize: textSize,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
                letterSpacing: 0.4,
              ),
            ),
          ),
          if (_isPhoneValid)
            Padding(
              padding: EdgeInsets.only(right: 11 * scale),
              child: Icon(
                Icons.check_circle_rounded,
                color: AppColors.primary,
                size: 19 * scale,
              ),
            ),
        ],
      ),
    );
  }

  // ============================================================
  // HELPER TEXT
  // ============================================================

  Widget _buildHelperText({required double scale, required double fontSize}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(
          Icons.verified_user_outlined,
          size: 16 * scale,
          color: AppColors.primary,
        ),
        SizedBox(width: 7 * scale),
        Expanded(
          child: Text(
            'We’ll send you a secure one-time verification code'
                .tr, // Translated
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: fontSize,
              color: AppColors.textSecondary,
              height: 1.3,
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // SEND OTP BUTTON
  // ============================================================

  Widget _buildContinueButton({
    required double scale,
    required double fontSize,
    required bool compact,
  }) {
    final buttonHeight = (52 * scale).clamp(48.0, 56.0);
    final radius = 12 * scale;
    final isEnabled = _isPhoneValid && !_isSendingOtp;

    return SizedBox(
      width: double.infinity,
      height: buttonHeight,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          gradient: isEnabled
              ? const LinearGradient(
                  colors: [AppColors.primaryDark, AppColors.primary],
                )
              : const LinearGradient(
                  colors: [Color(0xFF3D3100), Color(0xFF574500)],
                ),
          boxShadow: isEnabled
              ? [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.20),
                    blurRadius: 14,
                    offset: const Offset(0, 5),
                  ),
                ]
              : null,
        ),
        child: ElevatedButton(
          onPressed: isEnabled ? _continue : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            disabledBackgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            padding: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(radius),
            ),
          ),
          child: _isSendingOtp
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Send OTP'.tr, // Translated
                      style: TextStyle(
                        fontSize: fontSize,
                        fontWeight: FontWeight.w700,
                        color: isEnabled
                            ? Colors.black
                            : AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 9),
                    Icon(
                      Icons.arrow_forward_rounded,
                      size: 20,
                      color: isEnabled ? Colors.black : AppColors.textSecondary,
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  // ============================================================
  // SECURITY
  // ============================================================

  Widget _buildSecurityMessage({
    required double scale,
    required double fontSize,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.lock_outline_rounded,
          size: 16 * scale,
          color: AppColors.primary,
        ),
        const SizedBox(width: 7),
        Flexible(
          child: Text(
            'Your health data stays private and secure'.tr, // Translated
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w400,
              color: AppColors.textSecondary,
              height: 1.3,
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // FOOTER
  // ============================================================

  Widget _buildFooter({required double width}) {
    final scale = (width / 390).clamp(0.95, 1.08);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Text(
        '© Powered by ACT T Connect Pvt. Ltd',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 11 * scale,
          fontWeight: FontWeight.w400,
          color: AppColors.primary,
          height: 1.3,
        ),
      ),
    );
  }
}
