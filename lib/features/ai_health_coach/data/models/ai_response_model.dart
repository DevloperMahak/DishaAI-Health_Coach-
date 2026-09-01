class AiResponseModel {
  final String? message;
  final dynamic data;
  final String? rawResponse;

  AiResponseModel({this.message, this.data, this.rawResponse});

  factory AiResponseModel.fromJson(Map<String, dynamic> json) {
    return AiResponseModel(
      message: json['message']?.toString() ?? json['reply']?.toString(),
      data: json['data'] ?? json['result'] ?? json,
      rawResponse: json.toString(),
    );
  }
}
