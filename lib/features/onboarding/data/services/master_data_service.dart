import 'package:dio/dio.dart';
import 'package:disha_ai/core/network/api_client.dart';
import '../models/master_data_model.dart';

class MasterDataService {
  final Dio _dio = ApiClient.instance.dio;

  Future<MasterDataModel?> fetchMasterData() async {
    try {
      final response = await _dio.get('/user/master-data');
      if (response.statusCode == 200 && response.data != null) {
        final res = MasterDataResponse.fromJson(response.data);
        return res.data;
      }
    } catch (e) {
      print("Error fetching master data: $e");
    }
    return null;
  }
}
