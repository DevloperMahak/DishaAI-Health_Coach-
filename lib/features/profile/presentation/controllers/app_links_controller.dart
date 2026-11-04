import 'dart:async';

import 'package:get/get.dart';

import '../../data/models/app_links_model.dart';
import '../../data/services/app_links_service.dart';

class AppLinksController extends GetxController {
  // ============================================================
  // SERVICE
  // ============================================================

  final AppLinksService _service = AppLinksService();

  // ============================================================
  // OBSERVABLES
  // ============================================================

  final Rx<AppLinksModel> appLinks = const AppLinksModel.empty().obs;

  final RxBool isLoading = false.obs;

  final RxString errorMessage = ''.obs;

  // ============================================================
  // ACTIVE REQUEST
  //
  // Prevent duplicate API calls while allowing every caller
  // to wait until the current request finishes.
  // ============================================================

  Future<void>? _activeRequest;

  // ============================================================
  // INITIALIZATION
  // ============================================================

  @override
  void onInit() {
    super.onInit();

    // Load links automatically when controller initializes.
    fetchAppLinks();
  }

  // ============================================================
  // FETCH APP LINKS
  // ============================================================

  Future<void> fetchAppLinks() {
    // ----------------------------------------------------------
    // IF REQUEST IS ALREADY RUNNING
    //
    // Return the existing Future instead of returning
    // immediately. This fixes the first-tap issue.
    // ----------------------------------------------------------

    if (_activeRequest != null) {
      return _activeRequest!;
    }

    // ----------------------------------------------------------
    // START NEW REQUEST
    // ----------------------------------------------------------

    final completer = Completer<void>();

    _activeRequest = completer.future;

    _performFetch().then(
      (_) {
        completer.complete();
      },
      onError: (Object error, StackTrace stackTrace) {
        completer.completeError(error, stackTrace);
      },
    ).whenComplete(() {
      _activeRequest = null;
    });

    return completer.future;
  }

  // ============================================================
  // PERFORM API REQUEST
  // ============================================================

  Future<void> _performFetch() async {
    try {
      isLoading.value = true;

      errorMessage.value = '';

      // --------------------------------------------------------
      // CALL SERVICE
      // --------------------------------------------------------

      final result = await _service.getAppLinks();

      // --------------------------------------------------------
      // UPDATE MODEL
      // --------------------------------------------------------

      appLinks.value = result;

      // --------------------------------------------------------
      // DEBUG LOGS
      // --------------------------------------------------------

      print('========== APP LINKS API ==========');

      print('Terms URL: ${result.termsUrl}');

      print('Privacy URL: ${result.privacyPolicyUrl}');

      print('Help URL: ${result.helpSupportUrl}');

      print('Support Email: ${result.supportEmail}');

      print('===================================');

      // --------------------------------------------------------
      // VALIDATE RESPONSE
      // --------------------------------------------------------

      if (result.privacyPolicyUrl.isEmpty &&
          result.termsUrl.isEmpty &&
          result.helpSupportUrl.isEmpty &&
          result.supportEmail.isEmpty) {
        errorMessage.value = 'No app links are currently available.';
      }
    } catch (e) {
      errorMessage.value = _cleanError(e);

      print('APP LINKS ERROR: ${errorMessage.value}');
    } finally {
      isLoading.value = false;
    }
  }

  // ============================================================
  // ERROR CLEANUP
  // ============================================================

  String _cleanError(Object error) {
    final message = error.toString();

    if (message.startsWith('Exception: ')) {
      return message.substring('Exception: '.length);
    }

    return message;
  }
}