class ApiConstants {
  ApiConstants._();

  static const String baseUrl = 'https://rhea-ai.acttconnect.com/api';

  // ============================================================
  // AUTHENTICATION
  // ============================================================

  static const String sendOtp = '/auth/send-otp';
  static const String verifyOtp = '/auth/verify-otp';
  static const String refreshToken = '/auth/refresh-token';
  static const String logout = '/auth/logout';
  static const String currentUser = '/auth/me';

  // ============================================================
  // ONBOARDING / HEALTH PROFILE
  // ============================================================

  static const String healthProfile = '/user/health-profile';

  // ============================================================
  // DASHBOARD
  // ============================================================

  static const String dashboard = '/dashboard';
  static const String todaySummary = '/today-summary';
  static const String tasks = '/tasks';

  // AI Endpoints
  static const String aiChat = '/ai/chat';
  static const String aiAnalyzeProfile = '/ai/analyze-profile';
  static const String scanFood = '/scan-food';
  static const String aiAnalyzeHealth = '/ai/analyze-health';
  static const String aiAnalyzeLabReport = '/ai/analyze-lab-report';

  // NEW AI Endpoints
  static const String aiRecommend = '/ai/recommend';
  static const String aiGeneratePlan = '/ai/generate-plan';
  static const String aiSymptomChecker = '/ai/symptom-checker';
  static const String aiExplainReport = '/ai/explain-report';
}
