import 'dart:async';

import 'package:disha_ai/app/routes/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import '../../../../app/theme/app_colors.dart';

class OtpVerificationScreen extends StatefulWidget {
  const OtpVerificationScreen({super.key, required this.phoneNumber});

  final String phoneNumber;

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen>
    with SingleTickerProviderStateMixin {
  // ============================================================
  // CONSTANTS
  // ============================================================

  static const int _otpLength = 6;
  static const int _resendDuration = 30;

  late final AuthController _authController;

  // ============================================================
  // OTP CONTROLLERS
  // ============================================================

  final List<TextEditingController> _otpControllers = List.generate(
    _otpLength,
    (_) => TextEditingController(),
  );

  final List<FocusNode> _focusNodes = List.generate(
    _otpLength,
    (_) => FocusNode(),
  );

  // ============================================================
  // ANIMATION
  // ============================================================

  late final AnimationController _animationController;

  late final Animation<double> _fadeAnimation;

  late final Animation<Offset> _slideAnimation;

  late final Animation<double> _imageScaleAnimation;

  // ============================================================
  // TIMER & STATE
  // ============================================================

  Timer? _resendTimer;

  int _remainingSeconds = _resendDuration;

  bool _canResend = false;

  bool _isVerifying = false;

  String? _errorMessage;

  // ============================================================
  // LIFECYCLE
  // ============================================================

  @override
  void initState() {
    super.initState();

    _authController = Get.isRegistered<AuthController>()
        ? Get.find<AuthController>()
        : Get.put(AuthController());

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

    _startResendTimer();
  }

  @override
  void dispose() {
    for (final controller in _otpControllers) {
      controller.dispose();
    }

    for (final node in _focusNodes) {
      node.dispose();
    }

    _resendTimer?.cancel();

    _animationController.dispose();

    super.dispose();
  }

  // ============================================================
  // TIMER
  // ============================================================

  void _startResendTimer() {
    _resendTimer?.cancel();

    _remainingSeconds = _resendDuration;
    _canResend = false;

    if (mounted) {
      setState(() {});
    }

    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (_remainingSeconds <= 1) {
        timer.cancel();

        setState(() {
          _remainingSeconds = 0;
          _canResend = true;
        });
      } else {
        setState(() {
          _remainingSeconds--;
        });
      }
    });
  }

  // ============================================================
  // OTP INPUT
  // ============================================================

  void _onOtpChanged(String value, int index) {
    if (_errorMessage != null) {
      setState(() {
        _errorMessage = null;
      });
    }

    if (value.length > 1) {
      _handlePastedOtp(value);
      return;
    }

    if (value.isNotEmpty && index < _otpLength - 1) {
      _focusNodes[index + 1].requestFocus();
    }

    if (_isOtpComplete) {
      FocusScope.of(context).unfocus();
      _verifyOtp();
    }

    setState(() {});
  }

  // ============================================================
  // BACKSPACE
  // ============================================================

  void _onBackspace(int index) {
    if (_otpControllers[index].text.isEmpty && index > 0) {
      _otpControllers[index - 1].clear();
      _focusNodes[index - 1].requestFocus();
      setState(() {});
    }
  }

  // ============================================================
  // PASTE OTP
  // ============================================================

  void _handlePastedOtp(String value) {
    final digits = value.replaceAll(RegExp(r'[^0-9]'), '');

    if (digits.isEmpty) {
      return;
    }

    final otp = digits.substring(
      0,
      digits.length > _otpLength ? _otpLength : digits.length,
    );

    for (final controller in _otpControllers) {
      controller.clear();
    }

    for (int i = 0; i < otp.length; i++) {
      _otpControllers[i].text = otp[i];
    }

    if (otp.length == _otpLength) {
      FocusScope.of(context).unfocus();
      _verifyOtp();
    } else {
      _focusNodes[otp.length].requestFocus();
    }

    setState(() {});
  }

  // ============================================================
  // OTP GETTERS
  // ============================================================

  String get _enteredOtp {
    return _otpControllers.map((controller) => controller.text).join();
  }

  bool get _isOtpComplete {
    return _enteredOtp.length == _otpLength;
  }

  // ============================================================
  // VERIFY OTP
  // ============================================================
  Future<void> _verifyOtp() async {
    if (!_isOtpComplete || _isVerifying) {
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _isVerifying = true;
      _errorMessage = null;
    });

    final otp = _enteredOtp;

    try {
      final response = await _authController.verifyOtp(
        mobile: widget.phoneNumber,
        otp: otp,
      );

      if (!mounted) {
        return;
      }

      if (response['success'] == true) {
        setState(() {
          _isVerifying = false;
        });

        Get.offAllNamed(AppRoutes.onboarding);
        return;
      }

      setState(() {
        _isVerifying = false;
        _errorMessage =
            response['message'] ??
            'Invalid verification code. Please try again.'.tr; // Translated
      });

      for (final controller in _otpControllers) {
        controller.clear();
      }

      _focusNodes.first.requestFocus();
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isVerifying = false;
        _errorMessage =
            'Something went wrong. Please try again.'.tr; // Translated
      });
    }
  }

  // ============================================================
  // RESEND OTP
  // ============================================================

  Future<void> _resendOtp() async {
    if (!_canResend || _isVerifying) {
      return;
    }

    for (final controller in _otpControllers) {
      controller.clear();
    }

    setState(() {
      _errorMessage = null;
    });

    _startResendTimer();

    _focusNodes.first.requestFocus();

    try {
      final response = await _authController.sendOtp(
        mobile: widget.phoneNumber,
      );

      if (!mounted) {
        return;
      }

      if (response['success'] == true) {
        Get.snackbar(
          'OTP Sent'.tr, // Translated
          response['message'] ??
              'A new OTP has been sent to your mobile number.'.tr, // Translated
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.surface,
          colorText: AppColors.textPrimary,
          borderColor: AppColors.primary,
          borderWidth: 1,
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 2),
          icon: Icon(
            Icons.check_circle_outline_rounded,
            color: AppColors.primary,
          ),
        );

        return;
      }

      setState(() {
        _errorMessage =
            response['message'] ??
            'Unable to resend OTP. Please try again.'.tr; // Translated
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage =
            'Unable to resend OTP. Please try again.'.tr; // Translated
      });
    }
  }

  // ============================================================
  // MASK PHONE
  // ============================================================

  String get _maskedPhoneNumber {
    final phone = widget.phoneNumber;

    if (phone.length < 4) {
      return phone;
    }

    final lastFour = phone.substring(phone.length - 4);

    return '+91 •••••• $lastFour';
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
                // ==================================================
                // HERO
                // ==================================================
                SizedBox(
                  width: double.infinity,
                  height: heroHeight,
                  child: _buildHeroIllustration(
                    width: width,
                    height: heroHeight,
                  ),
                ),

                // ==================================================
                // SPACE BETWEEN IMAGE AND CARD
                // ==================================================
                SizedBox(height: keyboardOpen ? 8 : 18),

                // ==================================================
                // OTP CARD
                // ==================================================
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                  child: _buildOtpCard(
                    width: width - (horizontalPadding * 2),
                    screenHeight: height,
                    compact: keyboardOpen,
                  ),
                ),

                // ==================================================
                // FOOTER
                // ==================================================
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
              child: Row(
                children: [
                  // ==================================================
                  // HERO
                  // ==================================================
                  Expanded(
                    flex: 6,
                    child: SizedBox(
                      height: height * 0.88,
                      child: _buildHeroIllustration(
                        width: width * 0.55,
                        height: height * 0.88,
                      ),
                    ),
                  ),

                  SizedBox(width: spacing),

                  // ==================================================
                  // OTP CARD
                  // ==================================================
                  Expanded(
                    flex: 4,
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 500),
                        child: _buildOtpCard(
                          width: cardWidth,
                          screenHeight: height,
                          compact: false,
                        ),
                      ),
                    ),
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
  // HERO ILLUSTRATION
  // ============================================================

  Widget _buildHeroIllustration({
    required double width,
    required double height,
  }) {
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
  // OTP CARD
  // ============================================================

  Widget _buildOtpCard({
    required double width,
    required double screenHeight,
    required bool compact,
  }) {
    final scale = (width / 390).clamp(0.94, 1.08);

    // Typography
    final titleSize = 22 * scale;
    final subtitleSize = 14 * scale;
    final phoneSize = 14 * scale;
    final bodySize = 13 * scale;
    final buttonTextSize = 15 * scale;

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
            'Verify OTP'.tr, // Translated
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
            'Enter the 6-digit verification code sent to your mobile number'
                .tr, // Translated
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: subtitleSize,
              fontWeight: FontWeight.w400,
              color: AppColors.textPrimary,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            _maskedPhoneNumber,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: phoneSize,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
              letterSpacing: 0.4,
            ),
          ),
          SizedBox(height: compact ? 20 : 24),
          _buildOtpInput(scale: scale),
          if (_errorMessage != null) ...[
            const SizedBox(height: 10),
            _buildErrorMessage(scale: scale),
          ],
          SizedBox(height: compact ? 18 : 22),
          _buildVerifyButton(scale: scale, fontSize: buttonTextSize),
          SizedBox(height: compact ? 18 : 20),
          _buildResendSection(scale: scale, fontSize: bodySize),
          SizedBox(height: compact ? 18 : 22),
          _buildSecurityMessage(scale: scale, fontSize: bodySize),
        ],
      ),
    );
  }

  // ============================================================
  // OTP INPUT
  // ============================================================

  Widget _buildOtpInput({required double scale}) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final gap = 8.0 * scale;
        final availableWidth = constraints.maxWidth - (gap * 5);
        final boxWidth = availableWidth / 6;
        final boxHeight = boxWidth.clamp(48.0, 58.0);

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(_otpLength, (index) {
            return _buildOtpBox(
              index,
              width: boxWidth,
              height: boxHeight,
              scale: scale,
            );
          }),
        );
      },
    );
  }

  // ============================================================
  // OTP BOX
  // ============================================================

  Widget _buildOtpBox(
    int index, {
    required double width,
    required double height,
    required double scale,
  }) {
    final controller = _otpControllers[index];
    final focusNode = _focusNodes[index];
    final isFocused = focusNode.hasFocus;
    final hasValue = controller.text.isNotEmpty;

    return SizedBox(
      width: width,
      height: height,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: AppColors.black,
          borderRadius: BorderRadius.circular(7 * scale),
          border: Border.all(
            color: isFocused
                ? AppColors.primary
                : hasValue
                ? AppColors.primary.withOpacity(0.85)
                : AppColors.primary.withOpacity(0.60),
            width: isFocused ? 1.3 : 0.8,
          ),
          boxShadow: isFocused
              ? [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.12),
                    blurRadius: 8,
                  ),
                ]
              : null,
        ),
        child: TextField(
          controller: controller,
          focusNode: focusNode,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          maxLength: 1,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          onChanged: (value) {
            _onOtpChanged(value, index);
          },
          decoration: const InputDecoration(
            counterText: '',
            border: InputBorder.none,
            contentPadding: EdgeInsets.zero,
          ),
          style: TextStyle(
            fontSize: 15 * scale,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // ERROR
  // ============================================================

  Widget _buildErrorMessage({required double scale}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.error_outline_rounded,
          size: 16 * scale,
          color: AppColors.error,
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            _errorMessage!,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12 * scale,
              color: AppColors.error,
              fontWeight: FontWeight.w500,
              height: 1.3,
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // VERIFY BUTTON
  // ============================================================

  Widget _buildVerifyButton({required double scale, required double fontSize}) {
    final isEnabled = _isOtpComplete && !_isVerifying;
    final buttonHeight = 52 * scale;

    return SizedBox(
      width: double.infinity,
      height: buttonHeight,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
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
          onPressed: isEnabled ? _verifyOtp : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            disabledBackgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            padding: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: _isVerifying
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
                      'Verify OTP'.tr, // Translated
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
  // RESEND SECTION
  // ============================================================

  Widget _buildResendSection({
    required double scale,
    required double fontSize,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          "Didn't receive the code?".tr, // Translated
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14 * scale,
            fontWeight: FontWeight.w400,
            color: AppColors.textSecondary,
            height: 1.3,
          ),
        ),
        const SizedBox(height: 7),
        if (_canResend)
          GestureDetector(
            onTap: _resendOtp,
            child: Text(
              'Resend OTP'.tr, // Translated
              style: TextStyle(
                fontSize: 14 * scale,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
                decoration: TextDecoration.underline,
                decorationColor: AppColors.primary.withOpacity(0.7),
                height: 1.3,
              ),
            ),
          )
        else
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              children: [
                TextSpan(
                  text: 'Resend OTP in '.tr, // Translated
                  style: TextStyle(
                    fontSize: 14 * scale,
                    fontWeight: FontWeight.w400,
                    color: AppColors.textSecondary,
                  ),
                ),
                TextSpan(
                  text: '00:${_remainingSeconds.toString().padLeft(2, '0')}',
                  style: TextStyle(
                    fontSize: 14 * scale,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  // ============================================================
  // SECURITY MESSAGE
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
              fontSize: 12 * scale,
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
