import 'dart:io';
import 'package:disha_ai/features/profile/data/models/profile_model.dart';
import 'package:disha_ai/features/profile/data/services/profile_service.dart';
import 'package:get/get.dart';

class ProfileController extends GetxController {
  final ProfileService _service = ProfileService();

  final Rxn<ProfileModel> profile = Rxn<ProfileModel>();
  final RxBool isLoading = false.obs;
  final RxBool isUploadingPhoto = false.obs;
  final RxString errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    fetchProfile();
  }

  // Get Profile Data
  Future<void> fetchProfile() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      final result = await _service.getProfile();
      profile.value = result;
    } catch (e) {
      errorMessage.value = e.toString().replaceAll('Exception: ', '');
    } finally {
      isLoading.value = false;
    }
  }

  // Update Profile Details
  Future<bool> updateProfile({
    required String name,
    String? email,
    String? preferredLanguage,
  }) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      final updatedProfile = await _service.updateProfile(
        name: name,
        email: email,
        preferredLanguage: preferredLanguage,
      );
      profile.value = updatedProfile;
      return true;
    } catch (e) {
      errorMessage.value = e.toString().replaceAll('Exception: ', '');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // Upload Profile Image
  Future<bool> uploadPhoto(File imageFile) async {
    try {
      isUploadingPhoto.value = true;
      errorMessage.value = '';

      final updatedProfile = await _service.uploadProfilePhoto(imageFile);
      profile.value = updatedProfile;

      // Force sync with server data
      await fetchProfile();

      return true;
    } catch (e) {
      errorMessage.value = e.toString().replaceAll('Exception: ', '');
      return false;
    } finally {
      isUploadingPhoto.value = false;
    }
  }
}
