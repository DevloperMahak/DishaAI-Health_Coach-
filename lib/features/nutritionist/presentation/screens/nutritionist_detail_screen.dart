import 'package:disha_ai/features/nutritionist/presentation/controllers/expert_controller.dart';
import 'package:disha_ai/features/nutritionist/presentation/screens/ExpertConsultationDashboardScreen.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

import '../../../../app/theme/app_colors.dart';
import '../../data/models/expert_model.dart';

class NutritionistDetailScreen extends StatefulWidget {
  const NutritionistDetailScreen({super.key, required this.expert});

  final ExpertModel expert;

  @override
  State<NutritionistDetailScreen> createState() =>
      _NutritionistDetailScreenState();
}

class _NutritionistDetailScreenState extends State<NutritionistDetailScreen> {
  late final ExpertController _expertController;
  late final Razorpay _razorpay;

  int? _activeEnquiryId;
  bool _razorpayOpened = false;
  bool _verifyingPayment = false;
  bool _checkingCurrentExpert = true;
  bool _hasVerifiedPassForCurrentExpert = false;
  int _statusRequestVersion = 0;

  @override
  void initState() {
    super.initState();

    _expertController = Get.isRegistered<ExpertController>()
        ? Get.find<ExpertController>()
        : Get.put(ExpertController());

    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _refreshConsultationStatus();
    });
  }

  @override
  void didUpdateWidget(covariant NutritionistDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.expert.id != widget.expert.id) {
      _statusRequestVersion++;
      _hasVerifiedPassForCurrentExpert = false;
      _checkingCurrentExpert = true;
      _activeEnquiryId = null;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _refreshConsultationStatus();
      });
    }
  }

  @override
  void dispose() {
    _statusRequestVersion++;
    _razorpay.clear();
    super.dispose();
  }

  void _log(String message) {
    if (kDebugMode) debugPrint(message);
  }

  // Read this expert's entitlement directly, rather than trusting the
  // shared controller's last value (which may belong to another expert).
  Future<void> _refreshConsultationStatus() async {
    final requestVersion = ++_statusRequestVersion;
    final expertId = widget.expert.id;

    if (mounted) {
      setState(() {
        _checkingCurrentExpert = true;
        _hasVerifiedPassForCurrentExpert = false;
      });
    }

    try {
      // Use the existing authenticated service via the controller's public
      // method, then read its result. Avoid overlapping controller checks.
      // The controller's shared Rx status must only be consumed after this
      // screen's own request completes for its current expert.
      while (_expertController.isCheckingStatus.value) {
        await Future<void>.delayed(const Duration(milliseconds: 80));
        if (!mounted || requestVersion != _statusRequestVersion) return;
      }

      await _expertController.checkPassStatus(expertId);

      if (!mounted ||
          requestVersion != _statusRequestVersion ||
          expertId != widget.expert.id) {
        return;
      }

      // Controller resets entitlement on errors, so a failed refresh never
      // grants access based on a previous expert's cached value.
      setState(() {
        _hasVerifiedPassForCurrentExpert =
            _expertController.hasActiveConsultation.value;
      });
    } catch (_) {
      if (!mounted || requestVersion != _statusRequestVersion) return;
      setState(() => _hasVerifiedPassForCurrentExpert = false);
      _log('[EXPERT] Consultation status refresh failed');
    } finally {
      if (mounted && requestVersion == _statusRequestVersion) {
        setState(() => _checkingCurrentExpert = false);
      }
    }
  }

  String get _consultationDuration {
    final expert = widget.expert;
    if (expert.durationFormatted.trim().isNotEmpty) {
      return expert.durationFormatted.trim();
    }
    if (expert.durationValue > 0 && expert.durationUnit.trim().isNotEmpty) {
      return '${expert.durationValue} ${expert.durationUnit}';
    }
    return 'Not specified';
  }

  double? _parseFee(String? feeString) {
    if (feeString == null || feeString.trim().isEmpty) return null;
    final numericString = feeString.replaceAll(RegExp(r'[^0-9.]'), '');
    final amount = double.tryParse(numericString);
    if (amount == null || !amount.isFinite || amount <= 0) return null;
    return amount;
  }

  String get _feeLabel {
    final fee = _parseFee(widget.expert.fee);
    return fee == null ? 'Unavailable' : '₹${fee.toStringAsFixed(0)}';
  }

  Future<void> _handlePaymentSuccess(PaymentSuccessResponse response) async {
    if (_verifyingPayment) return;
    _verifyingPayment = true;
    _log('[RAZORPAY] Payment callback received; verifying with backend');

    final enquiryId = _activeEnquiryId;
    if (enquiryId == null || enquiryId <= 0) {
      _verifyingPayment = false;
      _razorpayOpened = false;
      _showSnackbar(
        title: 'Payment Pending Confirmation',
        message:
            'Unable to match this payment to a consultation. '
            'Please contact support before paying again.',
      );
      await _refreshConsultationStatus();
      return;
    }

    try {
      final verified = await _expertController.verifyExpertCheckout(
        orderId: response.orderId ?? '',
        paymentId: response.paymentId ?? '',
        signature: response.signature ?? '',
        enquiryId: enquiryId,
        expertId: widget.expert.id,
      );
      if (!mounted) return;

      if (!verified) {
        _showSnackbar(
          title: 'Verification Pending',
          message:
              'Your payment could not be confirmed yet. '
              'Please check your consultation status before paying again.',
        );
        await _refreshConsultationStatus();
        return;
      }

      await _refreshConsultationStatus();
      if (!mounted) return;

      if (!_hasVerifiedPassForCurrentExpert) {
        _showSnackbar(
          title: 'Payment Verified',
          message:
              'Payment was verified, but the consultation pass is not '
              'active yet. Please check again shortly or contact support.',
        );
        return;
      }

      _activeEnquiryId = null;
      _showSnackbar(
        title: 'Success',
        message: 'Consultation pass activated successfully!',
      );
      await Future<void>.delayed(const Duration(milliseconds: 300));
      if (!mounted) return;
      Get.off(() => ExpertConsultationDashboardScreen(expert: widget.expert));
    } catch (_) {
      _showSnackbar(
        title: 'Verification Pending',
        message:
            'Unable to confirm your payment right now. '
            'Please check your pass status before paying again.',
      );
      await _refreshConsultationStatus();
    } finally {
      _verifyingPayment = false;
      _razorpayOpened = false;
      if (mounted) setState(() {});
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    _log('[RAZORPAY] Payment failed or cancelled');
    _razorpayOpened = false;
    _activeEnquiryId = null;

    final message = response.message?.trim().isNotEmpty == true
        ? response.message!.trim()
        : 'Transaction cancelled or payment failed.';
    _showSnackbar(title: 'Payment Failed', message: message);
    _refreshConsultationStatus();
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    _showSnackbar(
      title: 'External Wallet',
      message: 'Wallet selected: ${response.walletName ?? 'Unknown wallet'}',
    );
  }

  void _showConsultDialog() {
    if (_razorpayOpened || _verifyingPayment || _checkingCurrentExpert) return;

    final feeAmount = _parseFee(widget.expert.fee);
    if (feeAmount == null) {
      _showSnackbar(
        title: 'Consultation Unavailable',
        message: 'Consultation fee is unavailable. Please try again later.',
      );
      return;
    }

    final messageController = TextEditingController(
      text: 'I want a customized diet plan.',
    );
    bool dialogClosed = false;

    // Dispose after the route has finished closing, including barrier/back.
    Get.defaultDialog(
      title: 'Consult ${widget.expert.name}',
      titleStyle: const TextStyle(
        color: AppColors.textPrimary,
        fontWeight: FontWeight.bold,
      ),
      backgroundColor: AppColors.surface,
      radius: 18,
      content: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            TextField(
              controller: messageController,
              maxLines: 3,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Enter your message...',
                hintStyle: const TextStyle(color: AppColors.textSecondary),
                filled: true,
                fillColor: AppColors.background,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: AppColors.primary.withOpacity(.15),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: AppColors.primary.withOpacity(.15),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(.07),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.payments_rounded,
                    color: AppColors.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Consultation Fee',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  Text(
                    _feeLabel,
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () {
                      if (dialogClosed) return;
                      dialogClosed = true;
                      Get.back();
                    },
                    child: const Text(
                      'Cancel',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Obx(() {
                    final isLoading =
                        _expertController.isPaymentProcessing.value;
                    return ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.black,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: isLoading
                          ? null
                          : () async {
                              if (dialogClosed) return;
                              final message = messageController.text.trim();
                              if (message.isEmpty) {
                                _showSnackbar(
                                  title: 'Message Required',
                                  message:
                                      'Please enter your consultation message.',
                                );
                                return;
                              }
                              dialogClosed = true;
                              Get.back();
                              await _expertController.bookAndPayExpert(
                                expertId: widget.expert.id,
                                amount: feeAmount,
                                message: message,
                                onOrderCreated: (enquiryId, orderId, key) {
                                  if (!mounted) return;
                                  _activeEnquiryId = enquiryId;
                                  _openRazorpay(
                                    enquiryId: enquiryId,
                                    orderId: orderId,
                                    key: key,
                                    amount: feeAmount,
                                  );
                                },
                              );
                              if (!mounted) return;
                              final error = _expertController.errorMessage.value
                                  .trim();
                              if (error.isNotEmpty) {
                                _showSnackbar(
                                  title: 'Booking Failed',
                                  message: error,
                                );
                              }
                            },
                      child: isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.black,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'Proceed to Pay',
                              style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    );
                  }),
                ),
              ],
            ),
          ],
        ),
      ),
    ).whenComplete(() {
      // Allow GetX dialog exit animation to finish before disposal.
      Future<void>.delayed(const Duration(milliseconds: 350), () {
        messageController.dispose();
      });
    });
  }

  void _openRazorpay({
    required int enquiryId,
    required String orderId,
    required String key,
    required double amount,
  }) {
    if (orderId.trim().isEmpty ||
        key.trim().isEmpty ||
        !amount.isFinite ||
        amount <= 0 ||
        enquiryId <= 0) {
      _activeEnquiryId = null;
      _showSnackbar(
        title: 'Payment Error',
        message: 'Invalid payment order details.',
      );
      return;
    }
    if (_razorpayOpened || _verifyingPayment) return;

    _razorpayOpened = true;
    final options = <String, dynamic>{
      'key': key,
      'amount': (amount * 100).round(),
      'name': 'Rhea AI',
      'description': 'Consultation with ${widget.expert.name}',
      'order_id': orderId,
      'prefill': {'contact': '', 'email': ''},
      'theme': {'color': '#FFC400'},
    };

    try {
      _log('[RAZORPAY] Opening consultation checkout');
      _razorpay.open(options);
    } catch (_) {
      _razorpayOpened = false;
      _activeEnquiryId = null;
      _showSnackbar(
        title: 'Payment Error',
        message: 'Unable to open payment gateway. Please try again.',
      );
    }
  }

  void _showSnackbar({required String title, required String message}) {
    if (!mounted) return;
    Get.snackbar(
      title,
      message.trim().isEmpty ? 'Something went wrong.' : message.trim(),
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: AppColors.surface,
      colorText: AppColors.textPrimary,
      margin: const EdgeInsets.all(16),
      borderRadius: 14,
      duration: const Duration(seconds: 4),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        backgroundColor: AppColors.background,
        leading: IconButton(
          onPressed: () => Get.back(),
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.primary,
          ),
        ),
        title: Text(
          widget.expert.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final isTablet = width >= 700;
            final horizontalPadding = isTablet
                ? (width * .15).clamp(40.0, 140.0)
                : 20.0;
            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: 20,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 800),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildProfileHeader(),
                      const SizedBox(height: 20),
                      _buildConsultationDetailsCard(),
                      const SizedBox(height: 20),
                      _buildScheduleCard(),
                      const SizedBox(height: 20),
                      _buildInfoSection(
                        title: 'Expertise & Specialties',
                        content:
                            widget.expert.specialization ??
                            'Clinical Nutrition & Wellness',
                        icon: Icons.verified_rounded,
                      ),
                      const SizedBox(height: 20),
                      _buildInfoSection(
                        title: 'Languages Spoken',
                        content: widget.expert.languages.isEmpty
                            ? 'English, Hindi'
                            : widget.expert.languages.join(', '),
                        icon: Icons.language_rounded,
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: _buildBottomActionBar(),
    );
  }

  Widget _buildConsultationDetailsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withOpacity(.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.workspace_premium_rounded,
                color: AppColors.primary,
                size: 20,
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Consultation Details',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(
                Icons.currency_rupee_rounded,
                color: AppColors.primary,
                size: 19,
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Consultation Fee',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ),
              Text(
                _feeLabel,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Divider(color: AppColors.primary.withOpacity(.10), height: 1),
          const SizedBox(height: 14),
          Row(
            children: [
              const Icon(
                Icons.timelapse_rounded,
                color: AppColors.primary,
                size: 19,
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Consultation Duration',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ),
              Flexible(
                child: Text(
                  _consultationDuration,
                  textAlign: TextAlign.end,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withOpacity(.15)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildExpertProfileImage(),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: widget.expert.isAvailable
                            ? Colors.green
                            : Colors.grey,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        widget.expert.availabilityStatus ?? 'Offline',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: widget.expert.isAvailable
                              ? Colors.green
                              : AppColors.textSecondary,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  widget.expert.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.expert.designation ?? 'Clinical Specialist',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpertProfileImage() {
    final imageUrl = widget.expert.imageUrl?.trim();
    return Container(
      width: 76,
      height: 76,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.primary.withOpacity(.08),
        border: Border.all(
          color: AppColors.primary.withOpacity(.15),
          width: 1.5,
        ),
      ),
      child: ClipOval(
        child: imageUrl != null && imageUrl.isNotEmpty
            ? Image.network(
                imageUrl,
                width: 76,
                height: 76,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    _buildProfileIcon(),
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    color: AppColors.primary.withOpacity(.06),
                    child: const Center(
                      child: SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  );
                },
              )
            : _buildProfileIcon(),
      ),
    );
  }

  Widget _buildProfileIcon() {
    return Container(
      width: 76,
      height: 76,
      color: AppColors.primary.withOpacity(.08),
      alignment: Alignment.center,
      child: const Icon(
        Icons.person_rounded,
        size: 42,
        color: AppColors.primary,
      ),
    );
  }

  Widget _buildScheduleCard() {
    final workingHours = widget.expert.workingHours?.trim().isNotEmpty == true
        ? widget.expert.workingHours!
        : '10:00 AM - 07:00 PM';
    final workingDays = widget.expert.workingDays.isNotEmpty
        ? widget.expert.workingDays.join(', ')
        : 'Monday - Friday';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withOpacity(.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Working Hours & Days',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.access_time_rounded,
                size: 17,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  workingHours,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.calendar_today_rounded,
                size: 16,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  workingDays,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection({
    required String title,
    required String content,
    required IconData icon,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withOpacity(.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            content,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13.5,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActionBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(color: AppColors.primary.withOpacity(.12)),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Consultation Fee',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _feeLabel,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 20),
            Expanded(
              child: SizedBox(
                height: 52,
                child: Obx(() {
                  // Observe the controller's payment operation, but only use
                  // this screen's current-expert entitlement for access.
                  final paymentProcessing =
                      _expertController.isPaymentProcessing.value;
                  final disabled =
                      _checkingCurrentExpert ||
                      paymentProcessing ||
                      _razorpayOpened ||
                      _verifyingPayment;
                  final hasPass = _hasVerifiedPassForCurrentExpert;
                  return ElevatedButton(
                    onPressed: disabled
                        ? null
                        : () async {
                            if (hasPass) {
                              // Reconfirm access immediately before navigation.
                              await _refreshConsultationStatus();
                              if (!mounted) return;
                              if (_hasVerifiedPassForCurrentExpert) {
                                Get.to(
                                  () => ExpertConsultationDashboardScreen(
                                    expert: widget.expert,
                                  ),
                                );
                              } else {
                                _showSnackbar(
                                  title: 'Consultation Status',
                                  message:
                                      'No active consultation pass was confirmed.',
                                );
                              }
                            } else {
                              _showConsultDialog();
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.black,
                      disabledBackgroundColor: AppColors.primary.withOpacity(
                        .5,
                      ),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: disabled
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.black,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            hasPass ? 'View Active Pass' : 'Consult Now',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
