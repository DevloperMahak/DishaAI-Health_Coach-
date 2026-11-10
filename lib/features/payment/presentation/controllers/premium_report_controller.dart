import 'package:disha_ai/features/authentication/presentation/controllers/auth_controller.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

import 'package:disha_ai/features/payment/data/models/payment_report_models.dart';
import 'package:disha_ai/features/payment/data/services/payment_report_service.dart';

import '../../../../app/routes/app_routes.dart';

class PremiumReportController extends GetxController {
  // ============================================================
  // SERVICES
  // ============================================================

  final PaymentReportService _service = PaymentReportService();

  late Razorpay _razorpay;

  // ============================================================
  // MEMBERSHIP STATE
  // ============================================================

  final RxBool isSubscribing = false.obs;
  final RxBool isReportLoading = false.obs;
  final RxBool isMembershipLoading = false.obs;

  final RxList<Map<String, dynamic>> membershipPlans =
      <Map<String, dynamic>>[].obs;

  final Rxn<Map<String, dynamic>> membershipStatus =
      Rxn<Map<String, dynamic>>();

  final Rxn<HealthReportModel> weeklyReport = Rxn<HealthReportModel>();

  final Rxn<HealthReportModel> monthlyReport = Rxn<HealthReportModel>();

  final RxString errorMessage = ''.obs;

  // ============================================================
  // PAYMENT STATE
  // ============================================================

  VoidCallback? _onSuccessCallback;

  bool _paymentProcessing = false;

  String? _currentOrderId;

  String? _currentPlanCode;

  // ============================================================
  // INITIALIZE
  // ============================================================

  @override
  void onInit() {
    super.onInit();

    debugPrint('Initializing PremiumReportController...');

    _razorpay = Razorpay();

    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);

    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);

    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);

    debugPrint('Razorpay initialized successfully');
  }

  // ============================================================
  // GET MEMBERSHIP PLANS
  // GET /membership/plans
  // ============================================================

  Future<void> fetchMembershipPlans() async {
    try {
      isMembershipLoading.value = true;
      errorMessage.value = '';

      final plans = await _service.getMembershipPlans();

      membershipPlans.assignAll(plans);

      debugPrint('========== MEMBERSHIP PLAN DEBUG ==========');
      debugPrint('TOTAL PLANS: ${membershipPlans.length}');

      for (final plan in membershipPlans) {
        debugPrint('PLAN CODE: ${plan['code']}');
        debugPrint('PLAN NAME: ${plan['name']}');
        debugPrint('PLAN PRICE: ${plan['price']}');
        debugPrint('PLAN ACTIVE: ${plan['is_active']}');
        debugPrint('-------------------------------------------');
      }

      debugPrint(
        'INITIAL ACCESS FOUND: ${getPlanByCode('initial_access') != null}',
      );

      debugPrint(
        'PREMIUM PLAN FOUND: ${getPlanByCode('premium_monthly') != null}',
      );

      debugPrint('===========================================');
    } catch (e, stackTrace) {
      errorMessage.value = _cleanError(e);

      debugPrint('FETCH MEMBERSHIP PLANS ERROR: $e');
      debugPrint('STACKTRACE: $stackTrace');
    } finally {
      isMembershipLoading.value = false;
    }
  }

  // ============================================================
  // GET PLAN BY CODE
  // ============================================================

  Map<String, dynamic>? getPlanByCode(String planCode) {
    try {
      return membershipPlans.firstWhere(
        (plan) => plan['code']?.toString() == planCode,
      );
    } catch (_) {
      return null;
    }
  }

  // ============================================================
  // GET PLAN PRICE
  // ============================================================

  String getPlanPrice(String planCode) {
    final plan = getPlanByCode(planCode);

    if (plan == null) return '';

    return plan['price']?.toString() ?? '';
  }

  // ============================================================
  // GET MEMBERSHIP STATUS
  // GET /membership/status
  // ============================================================

  Future<Map<String, dynamic>> refreshMembershipStatus() async {
    try {
      final status = await _service.getMembershipStatus();

      membershipStatus.value = status;

      debugPrint('========== MEMBERSHIP STATUS ==========');
      debugPrint('STATE: ${status['state']}');
      debugPrint('HAS ACCESS: ${status['has_access']}');
      debugPrint('SHOW UPGRADE: ${status['show_upgrade']}');

      return status;
    } catch (e, stackTrace) {
      debugPrint('MEMBERSHIP STATUS ERROR: $e');
      debugPrint('STACKTRACE: $stackTrace');

      rethrow;
    }
  }

  // ============================================================
  // MEMBERSHIP ACCESS HELPERS
  // ============================================================

  bool get hasMembershipAccess {
    return _parseBool(membershipStatus.value?['has_access']);
  }

  bool get shouldShowUpgrade {
    return _parseBool(membershipStatus.value?['show_upgrade']);
  }

  String get currentMembershipState {
    return membershipStatus.value?['state']?.toString() ?? '';
  }

  // ============================================================
  // START SUBSCRIPTION
  //
  // 1. POST /payment/create-order with plan_code
  // 2. Open Razorpay
  // 3. POST /payment/verify
  // 4. GET /membership/status
  // 5. GET /auth/me
  //
  // Backend is the source of truth for membership expiry.
  // ============================================================

  Future<void> startSubscription({
    String? planCode,

    // Temporary compatibility with existing screen calls.
    // This amount is NOT sent to the backend or used for billing.
    @Deprecated('Use planCode instead.') double? amount,

    // Temporary compatibility with existing screen calls.
    @Deprecated('Use planCode instead.')
    String paymentType = 'onboarding_trial',

    String description = 'App Premium Subscription',
    VoidCallback? onSuccess,
  }) async {
    if (isSubscribing.value || _paymentProcessing) {
      debugPrint('Payment is already processing');
      return;
    }

    // Map old screen arguments to the new backend plan codes.
    final selectedPlanCode =
        planCode ??
        (paymentType == 'onboarding_trial'
            ? 'initial_access'
            : paymentType == 'premium_monthly'
            ? 'rhea_premium_monthly'
            : '');

    if (selectedPlanCode.isEmpty) {
      Get.snackbar(
        'Payment Error',
        'Invalid membership plan.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    try {
      isSubscribing.value = true;
      errorMessage.value = '';

      _currentOrderId = null;
      _currentPlanCode = selectedPlanCode;
      _onSuccessCallback = onSuccess;

      debugPrint('========== START RHEAAI MEMBERSHIP ==========');
      debugPrint('PLAN CODE: $selectedPlanCode');

      // --------------------------------------------------------
      // STEP 1: CREATE ORDER
      // Backend decides the amount using plan_code.
      // --------------------------------------------------------

      final order = await _service.createMembershipOrder(
        planCode: selectedPlanCode,
      );

      if (order.orderId.trim().isEmpty) {
        throw Exception('Razorpay order ID was not received');
      }

      if (order.key.trim().isEmpty) {
        throw Exception('Razorpay API key was not received');
      }

      if (order.amount <= 0) {
        throw Exception('Invalid Razorpay order amount');
      }

      _currentOrderId = order.orderId;

      debugPrint('Razorpay order created successfully');
      //debugPrint('ORDER ID: ${order.orderId}');
      debugPrint('AMOUNT: ${order.amount} ${order.currency}');

      // --------------------------------------------------------
      // STEP 2: PREPARE RAZORPAY CHECKOUT
      // API amount is in rupees; Razorpay expects paise.
      // --------------------------------------------------------

      final amountInPaise = (order.amount * 100).round();

      final options = <String, dynamic>{
        'key': order.key,
        'amount': amountInPaise,
        'name': 'RheaAI',
        'description': description,
        'order_id': order.orderId,
        'currency': order.currency,
        'prefill': {'contact': '', 'email': ''},
        'theme': {'color': '#FFC400'},
      };

      // --------------------------------------------------------
      // STEP 3: OPEN RAZORPAY
      // --------------------------------------------------------

      _razorpay.open(options);
    } catch (e, stackTrace) {
      isSubscribing.value = false;

      _currentOrderId = null;
      _currentPlanCode = null;
      _onSuccessCallback = null;

      errorMessage.value = _cleanError(e);

      debugPrint('CREATE ORDER ERROR: $e');
      debugPrint('STACKTRACE: $stackTrace');

      Get.snackbar(
        'Payment Error',
        errorMessage.value,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  // ============================================================
  // PAYMENT SUCCESS CALLBACK
  // ============================================================

  Future<void> _handlePaymentSuccess(PaymentSuccessResponse response) async {
    if (_paymentProcessing) {
      debugPrint('Payment verification already running');
      return;
    }

    _paymentProcessing = true;

    try {
      debugPrint('========== RAZORPAY PAYMENT SUCCESS ==========');

      // --------------------------------------------------------
      // STEP 1: EXTRACT PAYMENT DETAILS
      // --------------------------------------------------------

      final orderId = response.orderId ?? _currentOrderId ?? '';
      final paymentId = response.paymentId ?? '';
      final signature = response.signature ?? '';

      final planCode = _currentPlanCode ?? '';

      debugPrint('ORDER ID: $orderId');
      debugPrint('PAYMENT ID: $paymentId');
      debugPrint('PLAN CODE: $planCode');

      if (orderId.trim().isEmpty ||
          paymentId.trim().isEmpty ||
          signature.trim().isEmpty) {
        throw Exception('Incomplete payment verification details');
      }

      // --------------------------------------------------------
      // STEP 2: VERIFY PAYMENT WITH BACKEND
      // POST /payment/verify
      // Only Razorpay's three required fields are sent.
      // --------------------------------------------------------

      debugPrint('Verifying Razorpay payment with backend...');

      await _service.verifyMembershipPayment(
        orderId: orderId,
        paymentId: paymentId,
        signature: signature,
      );

      debugPrint('Payment verified successfully by backend');

      // --------------------------------------------------------
      // STEP 3: REFRESH MEMBERSHIP STATUS
      // GET /membership/status
      // Backend decides whether access is active.
      // --------------------------------------------------------

      final status = await refreshMembershipStatus();

      if (!_parseBool(status['has_access'])) {
        throw Exception(
          'Payment was verified, but membership access is not active yet. Please refresh your membership status.',
        );
      }

      // --------------------------------------------------------
      // STEP 4: REFRESH AUTH USER
      // GET /auth/me
      // --------------------------------------------------------

      debugPrint('Refreshing user details...');

      final AuthController authController = Get.isRegistered<AuthController>()
          ? Get.find<AuthController>()
          : Get.put(AuthController());

      final result = await authController.getCurrentUser();

      if (result['success'] != true) {
        throw Exception(
          result['message']?.toString() ?? 'Unable to refresh user profile',
        );
      }

      debugPrint('User profile refreshed successfully');

      // --------------------------------------------------------
      // STEP 5: VALIDATE ONBOARDING STATUS
      // --------------------------------------------------------

      final user = result['user'];

      if (user is! Map) {
        throw Exception('User details missing after payment');
      }

      final onboardingValue = user['onboarding_completed'];

      final bool onboardingCompleted =
          onboardingValue == true ||
          onboardingValue == 1 ||
          onboardingValue?.toString().toLowerCase() == 'true';

      debugPrint('ONBOARDING COMPLETED: $onboardingCompleted');

      if (!onboardingCompleted) {
        throw Exception(
          'Payment verified, but onboarding is not yet completed.',
        );
      }

      // --------------------------------------------------------
      // STEP 6: PAYMENT COMPLETED
      // --------------------------------------------------------

      debugPrint('RheaAI membership payment completed');

      isSubscribing.value = false;
      errorMessage.value = '';

      _currentOrderId = null;
      _currentPlanCode = null;

      final successMessage = planCode == 'initial_access'
          ? 'Your RheaAI initial access has been activated!'
          : 'Your RheaAI Premium membership has been activated!';

      Get.snackbar(
        'Success',
        successMessage,
        snackPosition: SnackPosition.BOTTOM,
      );

      // --------------------------------------------------------
      // STEP 7: NAVIGATE TO DASHBOARD
      // --------------------------------------------------------

      if (_onSuccessCallback != null) {
        final callback = _onSuccessCallback!;

        _onSuccessCallback = null;

        callback();
      } else {
        Get.offAllNamed(AppRoutes.dashboard);
      }
    } catch (e, stackTrace) {
      errorMessage.value = _cleanError(e);

      debugPrint('PAYMENT / MEMBERSHIP ERROR: $e');
      debugPrint('STACKTRACE: $stackTrace');

      Get.snackbar(
        'Verification Failed',
        errorMessage.value,
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isSubscribing.value = false;
      _paymentProcessing = false;
    }
  }

  // ============================================================
  // PAYMENT FAILURE CALLBACK
  // ============================================================

  void _handlePaymentError(PaymentFailureResponse response) {
    debugPrint('========== RAZORPAY PAYMENT FAILED ==========');

    isSubscribing.value = false;
    _paymentProcessing = false;

    _currentOrderId = null;
    _currentPlanCode = null;
    _onSuccessCallback = null;

    errorMessage.value = response.message ?? 'Transaction cancelled or failed.';

    debugPrint('Razorpay payment failed: ${response.message}');

    Get.snackbar(
      'Payment Failed',
      errorMessage.value,
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  // ============================================================
  // EXTERNAL WALLET CALLBACK
  // ============================================================

  void _handleExternalWallet(ExternalWalletResponse response) {
    debugPrint('External wallet selected: ${response.walletName}');

    // Wait for actual payment success and backend verification.
  }

  // ============================================================
  // FETCH WEEKLY / MONTHLY REPORTS
  // EXISTING FUNCTIONALITY PRESERVED
  // ============================================================

  Future<void> fetchReports() async {
    try {
      isReportLoading.value = true;
      errorMessage.value = '';

      debugPrint('Fetching premium health reports...');

      weeklyReport.value = await _service.getWeeklyReport();

      monthlyReport.value = await _service.getMonthlyReport();

      debugPrint('Premium health reports fetched successfully');
    } catch (e, stackTrace) {
      errorMessage.value = _cleanError(e);

      debugPrint('FETCH REPORT ERROR: $e');
      debugPrint('STACKTRACE: $stackTrace');
    } finally {
      isReportLoading.value = false;
    }
  }

  // ============================================================
  // PARSE BOOLEAN
  // ============================================================

  bool _parseBool(dynamic value) {
    if (value is bool) return value;

    if (value is int) return value == 1;

    if (value is String) {
      return value.toLowerCase() == 'true' || value == '1';
    }

    return false;
  }

  // ============================================================
  // CLEAN ERROR MESSAGE
  // ============================================================

  String _cleanError(Object error) {
    final message = error.toString();

    if (message.startsWith('Exception: ')) {
      return message.substring('Exception: '.length);
    }

    return message;
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void onClose() {
    debugPrint('Disposing PremiumReportController...');

    _razorpay.clear();

    super.onClose();
  }
}
