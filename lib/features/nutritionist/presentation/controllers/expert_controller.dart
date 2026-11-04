import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../../data/models/expert_model.dart';
import '../../data/services/expert_service.dart';

class ExpertController extends GetxController {
  final ExpertService _service = ExpertService();

  // ============================================================
  // LOADING STATES
  // ============================================================

  final RxBool isExpertsLoading = false.obs;
  final RxBool isSendingMessage = false.obs;
  final RxBool isCheckingStatus = false.obs;
  final RxBool isPaymentProcessing = false.obs;

  // ============================================================
  // DATA
  // ============================================================

  final RxList<ExpertModel> expertsList = <ExpertModel>[].obs;

  final RxList<dynamic> chatMessages = <dynamic>[].obs;

  // ============================================================
  // CONSULTATION STATUS
  // ============================================================

  final RxBool isChatEligible = false.obs;
  final RxBool hasActiveConsultation = false.obs;

  final RxString passExpiryDate = ''.obs;

  // ============================================================
  // ERROR
  // ============================================================

  final RxString errorMessage = ''.obs;

  // ============================================================
  // SAFE DEBUG LOGGING
  // ============================================================

  void _log(String message) {
    if (kDebugMode) {
      debugPrint(message);
    }
  }

  // ============================================================
  // INIT
  // ============================================================

  @override
  void onInit() {
    super.onInit();

    _log('[EXPERT CONTROLLER] Initialized');

    fetchExperts();
  }

  // ============================================================
  // FETCH EXPERTS
  // ============================================================

  Future<void> fetchExperts() async {
    if (isExpertsLoading.value) {
      _log('[EXPERT CONTROLLER] Expert fetch already running');
      return;
    }

    try {
      isExpertsLoading.value = true;
      errorMessage.value = '';

      _log('[EXPERT CONTROLLER] Fetching experts');

      final result = await _service.getExperts();

      expertsList.assignAll(result);

      _log('[EXPERT CONTROLLER] Experts loaded successfully');
    } catch (_) {
      errorMessage.value = 'Unable to load experts. Please try again.';

      _log('[EXPERT CONTROLLER] Expert fetch failed');
    } finally {
      isExpertsLoading.value = false;
    }
  }

  // ============================================================
  // CHECK CONSULTATION STATUS
  // ============================================================

  Future<void> checkPassStatus(int expertId) async {
    if (expertId <= 0) {
      _resetConsultationStatus();
      errorMessage.value = 'Invalid expert ID.';
      return;
    }

    if (isCheckingStatus.value) {
      _log('[EXPERT CONTROLLER] Status check already running');
      return;
    }

    try {
      isCheckingStatus.value = true;

      _log('[EXPERT CONTROLLER] Checking consultation status');

      final statusData = await _service.checkConsultationStatus(expertId);

      if (statusData.isEmpty) {
        _resetConsultationStatus();
        return;
      }

      isChatEligible.value = statusData['chat_eligible'] == true;

      hasActiveConsultation.value =
          statusData['has_active_consultation'] == true;

      passExpiryDate.value = statusData['expires_at']?.toString() ?? '';

      _log('[EXPERT CONTROLLER] Consultation status updated');
    } catch (e) {
      errorMessage.value = _cleanError(e);

      _resetConsultationStatus();

      _log('[EXPERT CONTROLLER] Consultation status check failed');
    } finally {
      isCheckingStatus.value = false;
    }
  }

  // ============================================================
  // SEND EXPERT MESSAGE
  // ============================================================

  Future<bool> sendExpertMessage({
    required int expertId,
    required String message,
  }) async {
    final cleanMessage = message.trim();

    if (expertId <= 0) {
      errorMessage.value = 'Invalid expert ID.';
      return false;
    }

    if (cleanMessage.isEmpty) {
      errorMessage.value = 'Message cannot be empty.';
      return false;
    }

    if (isSendingMessage.value) {
      _log('[EXPERT CONTROLLER] Message request already running');
      return false;
    }

    try {
      isSendingMessage.value = true;
      errorMessage.value = '';

      _log('[EXPERT CONTROLLER] Sending expert message');

      await _service.sendMessage(expertId: expertId, message: cleanMessage);

      _log('[EXPERT CONTROLLER] Message sent successfully');

      await checkPassStatus(expertId);

      return true;
    } catch (e) {
      errorMessage.value = _cleanError(e);

      _log('[EXPERT CONTROLLER] Message send failed');

      return false;
    } finally {
      isSendingMessage.value = false;
    }
  }

  // ============================================================
  // FETCH CHAT HISTORY
  // ============================================================

  Future<void> fetchChatMessages(int expertId) async {
    if (expertId <= 0) {
      errorMessage.value = 'Invalid expert ID.';
      return;
    }

    try {
      errorMessage.value = '';

      _log('[EXPERT CONTROLLER] Fetching chat history');

      final result = await _service.getChatMessages(expertId);

      chatMessages.assignAll(result);

      _log('[EXPERT CONTROLLER] Chat history loaded');
    } catch (e) {
      errorMessage.value = _cleanError(e);

      _log('[EXPERT CONTROLLER] Chat history fetch failed');
    }
  }

  // ============================================================
  // CONSULTATION ENQUIRY
  // ============================================================

  Future<bool> consultExpert({
    required int expertId,
    required String message,
  }) async {
    final cleanMessage = message.trim();

    if (expertId <= 0) {
      errorMessage.value = 'Invalid expert ID.';
      return false;
    }

    if (cleanMessage.isEmpty) {
      errorMessage.value = 'Consultation message cannot be empty.';
      return false;
    }

    if (isSendingMessage.value) {
      _log('[EXPERT CONTROLLER] Consultation request already running');
      return false;
    }

    try {
      isSendingMessage.value = true;
      errorMessage.value = '';

      await _service.consultExpert(expertId: expertId, message: cleanMessage);

      _log('[EXPERT CONTROLLER] Consultation enquiry submitted');

      await checkPassStatus(expertId);

      return true;
    } catch (e) {
      errorMessage.value = _cleanError(e);

      _log('[EXPERT CONTROLLER] Consultation enquiry failed');

      return false;
    } finally {
      isSendingMessage.value = false;
    }
  }

  // ============================================================
  // CONSULTATION ENQUIRY WITH RESPONSE
  // ============================================================

  Future<dynamic> consultExpertWithResponse({
    required int expertId,
    required String message,
  }) async {
    final cleanMessage = message.trim();

    if (expertId <= 0) {
      errorMessage.value = 'Invalid expert ID.';
      return null;
    }

    if (cleanMessage.isEmpty) {
      errorMessage.value = 'Consultation message cannot be empty.';
      return null;
    }

    if (isSendingMessage.value) {
      _log('[EXPERT CONTROLLER] Consultation request already running');
      return null;
    }

    try {
      isSendingMessage.value = true;
      errorMessage.value = '';

      final response = await _service.consultExpert(
        expertId: expertId,
        message: cleanMessage,
      );

      _log('[EXPERT CONTROLLER] Consultation enquiry submitted');

      await checkPassStatus(expertId);

      return response;
    } catch (e) {
      errorMessage.value = _cleanError(e);

      _log('[EXPERT CONTROLLER] Consultation enquiry failed');

      return null;
    } finally {
      isSendingMessage.value = false;
    }
  }

  // ============================================================
  // BOOK + PAY
  //
  // 1. Create enquiry
  // 2. Extract enquiry ID
  // 3. Create Razorpay order
  // 4. Request Razorpay Checkout
  // ============================================================

  Future<void> bookAndPayExpert({
    required int expertId,
    required double amount,
    required String message,
    required Function(int enquiryId, String orderId, String key) onOrderCreated,
  }) async {
    final cleanMessage = message.trim();

    if (expertId <= 0) {
      errorMessage.value = 'Invalid expert ID.';
      return;
    }

    if (!amount.isFinite || amount <= 0) {
      errorMessage.value = 'Invalid consultation amount.';
      return;
    }

    if (cleanMessage.isEmpty) {
      errorMessage.value = 'Please enter a consultation message.';
      return;
    }

    if (isPaymentProcessing.value) {
      _log('[EXPERT PAYMENT] Payment operation already running');
      return;
    }

    try {
      isPaymentProcessing.value = true;
      errorMessage.value = '';

      _log('[EXPERT PAYMENT] Starting consultation booking');

      // ========================================================
      // STEP 1: CREATE ENQUIRY
      // ========================================================

      final enquiryResponse = await _service.consultExpert(
        expertId: expertId,
        message: cleanMessage,
      );

      final enquiryId = _extractEnquiryId(enquiryResponse);

      if (enquiryId == null || enquiryId <= 0) {
        throw Exception(
          'Consultation enquiry was created, '
          'but the enquiry ID was not returned by the server.',
        );
      }

      _log('[EXPERT PAYMENT] Consultation enquiry created');

      // ========================================================
      // STEP 2: CREATE PAYMENT ORDER
      // ========================================================

      final orderResponse = await _service.createExpertOrder(
        expertId: expertId,
        amount: amount,
      );

      final String orderId = _extractString(orderResponse, const [
        'order_id',
        'id',
      ]);

      if (orderId.isEmpty) {
        throw Exception(
          'Payment order was created, '
          'but order ID was not returned.',
        );
      }

      final String razorpayKey = _extractString(orderResponse, const [
        'key',
        'razorpay_key',
      ]);

      if (razorpayKey.isEmpty) {
        throw Exception(
          'Payment order was created, '
          'but Razorpay key was not returned.',
        );
      }

      _log('[EXPERT PAYMENT] Razorpay order created');

      // ========================================================
      // STEP 3: REQUEST RAZORPAY CHECKOUT
      // ========================================================

      onOrderCreated(enquiryId, orderId, razorpayKey);

      _log('[EXPERT PAYMENT] Razorpay Checkout requested');
    } catch (e) {
      errorMessage.value = _cleanError(e);

      _log('[EXPERT PAYMENT] Consultation booking failed');
    } finally {
      // This flag tracks enquiry/order creation and callback invocation.
      // Razorpay Checkout completion is handled by the screen.
      isPaymentProcessing.value = false;
    }
  }

  // ============================================================
  // EXTRACT ENQUIRY ID
  // ============================================================

  int? _extractEnquiryId(dynamic response) {
    if (response is! Map) {
      return null;
    }

    final candidates = <dynamic>[response['id'], response['enquiry_id']];

    final dynamic data = response['data'];

    if (data is Map) {
      candidates.add(data['id']);
      candidates.add(data['enquiry_id']);

      final dynamic enquiry = data['enquiry'];

      if (enquiry is Map) {
        candidates.add(enquiry['id']);
        candidates.add(enquiry['enquiry_id']);
      }
    }

    if (data is List && data.isNotEmpty) {
      final dynamic first = data.first;

      if (first is Map) {
        candidates.add(first['id']);
        candidates.add(first['enquiry_id']);
      }
    }

    for (final candidate in candidates) {
      final id = int.tryParse(candidate?.toString() ?? '');

      if (id != null && id > 0) {
        return id;
      }
    }

    _log('[EXPERT PAYMENT] Enquiry ID missing from response');

    return null;
  }

  // ============================================================
  // EXTRACT STRING
  // ============================================================

  String _extractString(Map<String, dynamic> data, List<String> keys) {
    for (final key in keys) {
      final value = data[key];

      if (value != null) {
        final text = value.toString().trim();

        if (text.isNotEmpty) {
          return text;
        }
      }
    }

    return '';
  }

  // ============================================================
  // VERIFY PAYMENT
  // ============================================================

  Future<bool> verifyExpertCheckout({
    required String orderId,
    required String paymentId,
    required String signature,
    required int enquiryId,
    required int expertId,
  }) async {
    if (orderId.trim().isEmpty) {
      errorMessage.value = 'Payment order ID is missing.';
      return false;
    }

    if (paymentId.trim().isEmpty) {
      errorMessage.value = 'Payment ID is missing.';
      return false;
    }

    if (signature.trim().isEmpty) {
      errorMessage.value = 'Payment signature is missing.';
      return false;
    }

    if (enquiryId <= 0) {
      errorMessage.value = 'Invalid consultation enquiry ID.';
      return false;
    }

    if (expertId <= 0) {
      errorMessage.value = 'Invalid expert ID.';
      return false;
    }

    if (isPaymentProcessing.value) {
      _log('[EXPERT PAYMENT] Payment verification already running');
      return false;
    }

    try {
      isPaymentProcessing.value = true;
      errorMessage.value = '';

      _log('[EXPERT PAYMENT] Verifying consultation payment');

      final success = await _service.verifyExpertPayment(
        orderId: orderId,
        paymentId: paymentId,
        signature: signature,
        enquiryId: enquiryId,
      );

      if (!success) {
        errorMessage.value = 'Payment verification failed.';
        return false;
      }

      _log('[EXPERT PAYMENT] Payment verified by backend');

      // Payment verification is already successful at this point.
      // A status refresh problem must not reverse that result.
      await checkPassStatus(expertId);

      if (errorMessage.value.isNotEmpty) {
        _log(
          '[EXPERT PAYMENT] Payment verified; '
          'consultation status refresh may be delayed',
        );

        // Clear the status-refresh error so it is not mistaken
        // for a payment verification error.
        errorMessage.value = '';
      }

      return true;
    } catch (e) {
      errorMessage.value = _cleanError(e);

      _log('[EXPERT PAYMENT] Payment verification failed');

      return false;
    } finally {
      isPaymentProcessing.value = false;
    }
  }

  // ============================================================
  // RESET CONSULTATION STATUS
  // ============================================================

  void _resetConsultationStatus() {
    isChatEligible.value = false;
    hasActiveConsultation.value = false;
    passExpiryDate.value = '';
  }

  // ============================================================
  // CLEAN ERROR
  // ============================================================

  String _cleanError(Object error) {
    String message = error.toString().trim();

    if (message.startsWith('Exception: ')) {
      message = message.substring('Exception: '.length);
    }

    if (message.startsWith('DioException: ')) {
      message = message.substring('DioException: '.length);
    }

    if (message.isEmpty) {
      return 'Something went wrong. Please try again.';
    }

    return message;
  }
}
