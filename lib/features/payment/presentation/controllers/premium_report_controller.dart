import 'package:disha_ai/features/authentication/presentation/controllers/auth_controller.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

import 'package:disha_ai/features/payment/data/models/payment_report_models.dart';
import 'package:disha_ai/features/payment/data/services/payment_report_service.dart';

// Auth Controller
// Adjust this import if your AuthController is in a different folder.

import '../../../../app/routes/app_routes.dart';

class PremiumReportController extends GetxController {
  // ============================================================
  // SERVICES
  // ============================================================

  final PaymentReportService _service = PaymentReportService();

  late Razorpay _razorpay;

  // ============================================================
  // STATE
  // ============================================================

  final RxBool isSubscribing = false.obs;

  final RxBool isReportLoading = false.obs;

  final Rxn<HealthReportModel> weeklyReport = Rxn<HealthReportModel>();

  final Rxn<HealthReportModel> monthlyReport = Rxn<HealthReportModel>();

  final RxString errorMessage = ''.obs;

  // ============================================================
  // PAYMENT STATE
  // ============================================================

  VoidCallback? _onSuccessCallback;

  bool _paymentProcessing = false;

  String? _currentOrderId;

  // ============================================================
  // INITIALIZE
  // ============================================================

  @override
  void onInit() {
    super.onInit();

    debugPrint('💳 Initializing PremiumReportController...');

    _razorpay = Razorpay();

    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);

    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);

    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);

    debugPrint('✅ Razorpay initialized successfully');

    // Reports are fetched only when required.
    // No unnecessary API calls during onboarding.
  }

  // ============================================================
  // START SUBSCRIPTION
  // ============================================================

  Future<void> startSubscription({
    required double amount,
    String description = 'App Premium Subscription',
    VoidCallback? onSuccess,
  }) async {
    // Prevent duplicate payment attempts.
    if (isSubscribing.value || _paymentProcessing) {
      debugPrint('⚠️ Payment is already processing');
      return;
    }

    try {
      isSubscribing.value = true;

      errorMessage.value = '';

      _currentOrderId = null;

      _onSuccessCallback = onSuccess;

      debugPrint('========== START RHEAAI SUBSCRIPTION ==========');

      debugPrint('💰 Amount: ₹$amount');

      debugPrint('📦 Payment type: onboarding_trial');

      // --------------------------------------------------------
      // STEP 1: CREATE RAZORPAY ORDER
      // POST /payment/create-order
      // --------------------------------------------------------

      final order = await _service.createOrder(
        amount,
        paymentType: 'onboarding_trial',
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

      debugPrint('✅ Razorpay order created successfully');

      debugPrint('ORDER ID: ${order.orderId}');

      debugPrint('AMOUNT: ₹${order.amount}');

      // --------------------------------------------------------
      // STEP 2: PREPARE RAZORPAY CHECKOUT
      // --------------------------------------------------------

      // Backend returns amount in rupees.
      // Razorpay checkout requires amount in paise.
      //
      // ₹3 -> 300 paise

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

      debugPrint('🚀 Opening Razorpay checkout...');

      // --------------------------------------------------------
      // STEP 3: OPEN RAZORPAY
      // --------------------------------------------------------

      // IMPORTANT:
      // Razorpay uses callbacks.
      //
      // Do not navigate to Dashboard here.
      //
      // Payment success is handled by:
      // _handlePaymentSuccess()

      _razorpay.open(options);
    } catch (e, stackTrace) {
      isSubscribing.value = false;

      _currentOrderId = null;

      _onSuccessCallback = null;

      errorMessage.value = _cleanError(e);

      debugPrint('❌ CREATE ORDER ERROR: $e');

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
      debugPrint('⚠️ Payment verification already running');
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

      debugPrint('ORDER ID: $orderId');

      debugPrint('PAYMENT ID: $paymentId');

      if (orderId.trim().isEmpty ||
          paymentId.trim().isEmpty ||
          signature.trim().isEmpty) {
        throw Exception('Incomplete payment verification details');
      }

      // --------------------------------------------------------
      // STEP 2: VERIFY PAYMENT WITH BACKEND
      // POST /payment/verify
      // --------------------------------------------------------

      debugPrint('🔐 Verifying Razorpay payment with backend...');

      final verified = await _service.verifyPayment(
        orderId: orderId,
        paymentId: paymentId,
        signature: signature,
        paymentType: 'onboarding_trial',
      );

      if (!verified) {
        throw Exception('Payment verification failed');
      }

      debugPrint('✅ Payment verified successfully by backend');

      // --------------------------------------------------------
      // STEP 3: REFRESH AUTH USER
      // GET /auth/me
      // --------------------------------------------------------

      debugPrint('👤 Refreshing user details after payment...');

      final AuthController authController = Get.isRegistered<AuthController>()
          ? Get.find<AuthController>()
          : Get.put(AuthController());

      final result = await authController.getCurrentUser();

      // --------------------------------------------------------
      // STEP 4: VALIDATE AUTH RESPONSE
      // --------------------------------------------------------

      if (result['success'] != true) {
        throw Exception(
          result['message']?.toString() ?? 'Unable to refresh user profile',
        );
      }

      debugPrint('✅ User profile refreshed successfully');

      // --------------------------------------------------------
      // STEP 5: CHECK ONBOARDING STATUS
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

      debugPrint('========== ONBOARDING STATUS ==========');

      debugPrint('ONBOARDING COMPLETED: $onboardingCompleted');

      debugPrint('=======================================');

      if (!onboardingCompleted) {
        throw Exception(
          'Payment verified, but onboarding is not yet completed.',
        );
      }

      // --------------------------------------------------------
      // STEP 6: PAYMENT + ONBOARDING COMPLETED
      // --------------------------------------------------------

      debugPrint('🎉 RheaAI onboarding completed successfully!');

      isSubscribing.value = false;

      errorMessage.value = '';

      _currentOrderId = null;

      Get.snackbar(
        'Success',
        'Your RheaAI trial has been activated!',
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
        debugPrint('🏠 Navigating to RheaAI Dashboard...');

        Get.offAllNamed(AppRoutes.dashboard);
      }
    } catch (e, stackTrace) {
      errorMessage.value = _cleanError(e);

      debugPrint('❌ PAYMENT / ONBOARDING ERROR: $e');

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

    _onSuccessCallback = null;

    errorMessage.value = response.message ?? 'Transaction cancelled or failed.';

    debugPrint('❌ Razorpay payment failed: ${response.message}');

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
    debugPrint('💳 External wallet selected: ${response.walletName}');

    // Do not navigate or mark onboarding complete here.
    // Wait for actual payment success and backend verification.
  }

  // ============================================================
  // FETCH WEEKLY / MONTHLY REPORTS
  // ============================================================

  Future<void> fetchReports() async {
    try {
      isReportLoading.value = true;

      errorMessage.value = '';

      debugPrint('📊 Fetching premium health reports...');

      weeklyReport.value = await _service.getWeeklyReport();

      monthlyReport.value = await _service.getMonthlyReport();

      debugPrint('✅ Premium health reports fetched successfully');
    } catch (e, stackTrace) {
      errorMessage.value = _cleanError(e);

      debugPrint('❌ FETCH REPORT ERROR: $e');

      debugPrint('STACKTRACE: $stackTrace');
    } finally {
      isReportLoading.value = false;
    }
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
    debugPrint('🗑️ Disposing PremiumReportController...');

    _razorpay.clear();

    super.onClose();
  }
}
