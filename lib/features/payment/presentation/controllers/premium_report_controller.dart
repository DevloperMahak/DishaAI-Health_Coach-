import 'package:disha_ai/features/payment/data/models/payment_report_models.dart';
import 'package:disha_ai/features/payment/data/services/payment_report_service.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../../../../app/routes/app_routes.dart';

class PremiumReportController extends GetxController {
  final PaymentReportService _service = PaymentReportService();
  late Razorpay _razorpay;

  final RxBool isSubscribing = false.obs;
  final RxBool isReportLoading = false.obs;
  final Rxn<HealthReportModel> weeklyReport = Rxn<HealthReportModel>();
  final Rxn<HealthReportModel> monthlyReport = Rxn<HealthReportModel>();
  final RxString errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
    fetchReports();
  }

  @override
  void onClose() {
    _razorpay.clear();
    super.onClose();
  }

  // Step 1 & 2: Trigger Order Creation & Open Razorpay SDK
  Future<void> startSubscription() async {
    try {
      isSubscribing.value = true;
      errorMessage.value = '';

      // Step 1: Create Order
      debugPrint('--- CREATING RAZORPAY ORDER ---');
      final order = await _service.createOrder(3);
      debugPrint('ORDER CREATED SUCCESSFULLY: ${order.orderId}');

      // Step 2: Open Razorpay Checkout SDK with dynamic key and paise conversion
      var options = {
        'key': order.key, // <-- Dynamic key from backend API response
        'amount': (order.amount * 100)
            .toInt(), // <-- Amount in paise (3 * 100 = 300)
        'name': 'Rhea AI Premium',
        'description': 'Monthly AI Health Coaching Subscription',
        'order_id': order.orderId,
        'prefill': {'contact': '', 'email': ''},
        'external': {
          'wallets': ['paytm'],
        },
      };

      _razorpay.open(options);
    } catch (e, stackTrace) {
      isSubscribing.value = false;
      errorMessage.value = _cleanError(e);
      debugPrint('CREATE ORDER ERROR: $e');
      debugPrint('STACKTRACE: $stackTrace');
      Get.snackbar('Subscription Error', errorMessage.value);
    }
  }

  // Step 3: Handle Payment Success & Verify Signature
  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    try {
      final success = await _service.verifyPayment(
        orderId: response.orderId ?? '',
        paymentId: response.paymentId ?? '',
        signature: response.signature ?? '',
      );

      isSubscribing.value = false;
      if (success) {
        Get.snackbar('Success', 'Premium subscription activated successfully!');
        // Automatically navigate to Dashboard after successful verification
        Get.offAllNamed(AppRoutes.dashboard);
      }
    } catch (e) {
      isSubscribing.value = false;
      Get.snackbar('Verification Failed', _cleanError(e));
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    isSubscribing.value = false;
    Get.snackbar(
      'Payment Failed',
      response.message ?? 'Transaction cancelled or failed.',
    );
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    isSubscribing.value = false;
    Get.snackbar('External Wallet', 'Wallet selected: ${response.walletName}');
  }

  // Fetch Reports Data
  Future<void> fetchReports() async {
    try {
      isReportLoading.value = true;
      errorMessage.value = '';
      weeklyReport.value = await _service.getWeeklyReport();
      monthlyReport.value = await _service.getMonthlyReport();
    } catch (e) {
      errorMessage.value = _cleanError(e);
    } finally {
      isReportLoading.value = false;
    }
  }

  String _cleanError(Object error) {
    final message = error.toString();
    if (message.startsWith('Exception: ')) {
      return message.substring('Exception: '.length);
    }
    return message;
  }
}
