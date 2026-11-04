import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../data/models/review_model.dart';
import '../../data/services/review_service.dart';

class ReviewController extends GetxController {
  final ReviewService _service = ReviewService();

  final RxBool isSubmitting = false.obs;
  final RxInt selectedRating = 0.obs;
  final Rx<ReviewModel?> submittedReview = Rx<ReviewModel?>(null);
  final RxString errorMessage = ''.obs;

  Future<bool> submitReview({
    required String category,
    required String message,
    File? attachment,
  }) async {
    if (isSubmitting.value) {
      return false;
    }

    try {
      isSubmitting.value = true;
      errorMessage.value = '';

      final review = await _service.submitReview(
        category: category,
        message: message,
        attachment: attachment,
        rating: selectedRating.value > 0 ? selectedRating.value : null,
        platform: _platform,
      );

      submittedReview.value = review;

      return true;
    } catch (e) {
      errorMessage.value = _cleanError(e);
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }

  void setRating(int rating) {
    if (rating < 1 || rating > 5) {
      return;
    }

    selectedRating.value = rating;
  }

  void clearRating() {
    selectedRating.value = 0;
  }

  String get _platform {
    if (Platform.isAndroid) {
      return 'android';
    }

    if (Platform.isIOS) {
      return 'ios';
    }

    if (Platform.isWindows) {
      return 'windows';
    }

    if (Platform.isMacOS) {
      return 'macos';
    }

    if (Platform.isLinux) {
      return 'linux';
    }

    return 'unknown';
  }

  String _cleanError(Object error) {
    final message = error.toString();

    if (message.startsWith('Exception: ')) {
      return message.substring('Exception: '.length);
    }

    return message;
  }

  void reset() {
    selectedRating.value = 0;
    submittedReview.value = null;
    errorMessage.value = '';
  }
}
