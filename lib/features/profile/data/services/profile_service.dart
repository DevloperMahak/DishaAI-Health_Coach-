import 'dart:io';
import 'package:dio/dio.dart';
import 'package:disha_ai/core/network/api_client.dart';
import 'package:disha_ai/core/network/api_constants.dart';
import 'package:disha_ai/features/profile/data/models/profile_model.dart';

class ProfileService {
  final Dio _dio = ApiClient.instance.dio;

  // GET /api/profile
  Future<ProfileModel> getProfile() async {
    try {
      final response = await _dio.get('/profile');
      return ProfileModel.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to load profile');
    }
  }

  // PUT /api/profile
  Future<ProfileModel> updateProfile({
    required String name,
    String? email,
    String? preferredLanguage,
  }) async {
    try {
      final response = await _dio.put(
        '/profile',
        data: {
          'name': name.trim(),
          if (email != null) 'email': email.trim(),
          if (preferredLanguage != null)
            'preferred_language': preferredLanguage.trim(),
        },
      );
      return ProfileModel.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ?? 'Failed to update profile',
      );
    }
  }

  // POST /api/profile/photo (Multipart Upload)
  // POST /api/profile/photo (Multipart Upload)
  Future<ProfileModel> uploadProfilePhoto(File imageFile) async {
    try {
      String fileName = imageFile.path.split('/').last;
      FormData formData = FormData.fromMap({
        'photo': await MultipartFile.fromFile(
          imageFile.path,
          filename: fileName,
        ),
      });

      final response = await _dio.post(
        '/profile/photo',
        data: formData,
        options: Options(headers: {'Content-Type': 'multipart/form-data'}),
      );

      // Pass raw response data to ProfileModel
      return ProfileModel.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ?? 'Failed to upload profile photo',
      );
    }
  }
}
