import 'package:disha_ai/features/ai_health_coach/presentation/screens/ai_health_coach_screen.dart';
import 'package:disha_ai/features/ai_health_coach/presentation/screens/rheaai_call_screen.dart';
import 'package:disha_ai/features/dashboard/presentation/screens/addiction_screen.dart';
import 'package:disha_ai/features/dashboard/presentation/screens/explain_medical_report_screen.dart';
import 'package:disha_ai/features/dashboard/presentation/screens/meals/meals_home_screen.dart';
import 'package:disha_ai/features/dashboard/presentation/screens/mood_checkin_screen.dart';
import 'package:disha_ai/features/dashboard/presentation/screens/sexual_wellness_screen.dart';
import 'package:disha_ai/features/dashboard/presentation/screens/sleep_checkin_screen.dart';
import 'package:disha_ai/features/dashboard/presentation/screens/steps_checkin_screen.dart';
import 'package:disha_ai/features/dashboard/presentation/screens/vitals_analysis_screen.dart';
import 'package:disha_ai/features/dashboard/presentation/screens/weight_checkin_screen.dart';
import 'package:disha_ai/features/meditation/presentation/screens/meditation_home_screen.dart';
import 'package:disha_ai/features/nutritionist/presentation/screens/nutritionist_screen.dart';
import 'package:disha_ai/features/onboarding/data/binding/health_profile_binding.dart';
import 'package:disha_ai/features/onboarding/presentation/screens/journey_ahead_screen.dart';
import 'package:disha_ai/features/profile/presentation/screens/connect_health_data_screen.dart';
import 'package:disha_ai/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:disha_ai/features/notifications/presentation/screens/notification_screen.dart';
import 'package:disha_ai/features/onboarding/presentation/screens/activity_screen.dart';
import 'package:disha_ai/features/onboarding/presentation/screens/analysis_complete_screen.dart';
import 'package:disha_ai/features/onboarding/presentation/screens/analyzing_screen.dart';
import 'package:disha_ai/features/onboarding/presentation/screens/challenge_Selection_screen.dart';
import 'package:disha_ai/features/onboarding/presentation/screens/food_Preferences_screen.dart';
import 'package:disha_ai/features/onboarding/presentation/screens/generated_plan_screen.dart';
import 'package:disha_ai/features/onboarding/presentation/screens/health_condition_screen.dart';
import 'package:disha_ai/features/onboarding/presentation/screens/health_goal_selection.dart';
import 'package:disha_ai/features/onboarding/presentation/screens/lifestyle_screen.dart';
import 'package:disha_ai/features/onboarding/presentation/screens/onBoarding_Screen.dart';
import 'package:disha_ai/features/onboarding/presentation/screens/personal_info_screen.dart';
import 'package:disha_ai/features/plan/presentation/screens/plan_screen.dart';
import 'package:disha_ai/features/profile/presentation/screens/edit_information_screen.dart';
import 'package:disha_ai/features/profile/presentation/screens/edit_personal_information_screen.dart';
import 'package:disha_ai/features/profile/presentation/screens/microphone_access_screen.dart';
import 'package:disha_ai/features/profile/presentation/screens/profile_screen.dart';
import 'package:disha_ai/features/profile/presentation/screens/settings_screen.dart';
import 'package:disha_ai/features/progress/presentation/screens/progress_screen.dart';
import 'package:disha_ai/features/water_tracker/presentation/screens/water_tracker_screen.dart';
import 'package:disha_ai/features/workout/presentation/screens/workout_home_screen.dart';
import 'package:get/get.dart';

import '../../features/authentication/presentation/screens/mobile_login_screen.dart';
import '../../features/authentication/presentation/screens/otp_verification_screen.dart';
import '../../features/splash/presentation/screens/splash_screen.dart';

import 'app_routes.dart';

class AppPages {
  AppPages._();

  // ============================================================
  // INITIAL ROUTE
  // ============================================================

  static const String initial = AppRoutes.splash;

  // ============================================================
  // APPLICATION PAGES
  // ============================================================

  static final List<GetPage<dynamic>> pages = [
    // ============================================================
    // SPLASH
    // ============================================================
    GetPage(name: AppRoutes.splash, page: () => const SplashScreen()),

    // ============================================================
    // MOBILE LOGIN
    // ============================================================
    GetPage(name: AppRoutes.login, page: () => const MobileLoginScreen()),

    // ============================================================
    // OTP VERIFICATION
    // ============================================================
    GetPage(
      name: AppRoutes.otpVerification,
      page: () {
        final arguments = Get.arguments;

        String phoneNumber = '';

        if (arguments is Map) {
          phoneNumber = arguments['phoneNumber']?.toString() ?? '';
        }

        return OtpVerificationScreen(phoneNumber: phoneNumber);
      },
    ),

    GetPage(name: AppRoutes.onboarding, page: () => const OnboardingScreen()),

    GetPage(
      name: AppRoutes.primaryHealthGoal,
      page: () => const PrimaryHealthGoalScreen(),
    ),

    GetPage(
      name: AppRoutes.personalInfo,
      page: () => const PersonalInfoScreen(),
      binding: HealthProfileBinding(),
    ),

    GetPage(
      name: AppRoutes.healthCondition,
      page: () => const HealthConditionScreen(),
    ),

    GetPage(
      name: AppRoutes.activityLevel,
      page: () => const ActivityLevelScreen(),
    ),

    GetPage(name: AppRoutes.lifestyle, page: () => const LifestyleScreen()),

    GetPage(
      name: AppRoutes.foodPreference,
      page: () => const FoodPreferencesScreen(),
    ),

    GetPage(
      name: AppRoutes.challengeSelection,
      page: () => const ChallengeSelectionScreen(),
    ),

    GetPage(name: AppRoutes.analyze, page: () => const AnalyzingScreen()),

    GetPage(
      name: AppRoutes.analysisComplete,
      page: () => const AnalysisCompleteScreen(),
    ),

    GetPage(
      name: AppRoutes.generatedPlan,
      page: () => const GeneratedPlanScreen(),
    ),

    // ============================================================
    // DASHBOARD
    // ============================================================
    GetPage(name: AppRoutes.dashboard, page: () => const DashboardScreen()),

    GetPage(name: AppRoutes.progress, page: () => const ProgressScreen()),

    GetPage(name: AppRoutes.aiCoach, page: () => const AiHealthCoachScreen()),

    GetPage(name: AppRoutes.profile, page: () => const ProfileScreen()),

    GetPage(
      name: AppRoutes.editHealthInfo,
      page: () => const EditHealthDataScreen(),
    ),

    GetPage(
      name: AppRoutes.editPersonalInfo,
      page: () => const EditPersonalInformationScreen(),
    ),

    GetPage(name: AppRoutes.myPlan, page: () => const PlanScreen()),

    GetPage(
      name: AppRoutes.notifications,
      page: () => const NotificationScreen(),
    ),

    GetPage(name: AppRoutes.waterTracker, page: () => WaterTrackerScreen()),

    GetPage(
      name: AppRoutes.connectHealthData,
      page: () => ConnectHealthDataScreen(),
    ),

    GetPage(
      name: AppRoutes.microphoneAccess,
      page: () => MicrophoneAccessScreen(),
    ),

    GetPage(name: AppRoutes.rheaAICall, page: () => RheaCheckInCallScreen()),

    GetPage(
      name: AppRoutes.meditation,
      page: () => const MeditationHomeScreen(),
      transition: Transition.cupertino,
    ),

    GetPage(
      name: AppRoutes.workout,
      page: () => const WorkoutHomeScreen(),
      transition: Transition.cupertino,
    ),

    GetPage(
      name: AppRoutes.meal,
      page: () => const MealsHomeScreen(),
      transition: Transition.cupertino,
    ),

    GetPage(
      name: AppRoutes.explainReport,
      page: () => const ExplainMedicalReportScreen(),
      transition: Transition.cupertino,
    ),
    GetPage(
      name: AppRoutes.vitalsAnalysis,
      page: () => const VitalsAnalysisScreen(),
      transition: Transition.cupertino,
    ),
    GetPage(
      name: AppRoutes.mood,
      page: () => const MoodCheckinScreen(),
      transition: Transition.cupertino,
    ),
    GetPage(
      name: AppRoutes.sleep,
      page: () => const SleepCheckinScreen(),
      transition: Transition.cupertino,
    ),
    GetPage(
      name: AppRoutes.steps,
      page: () => const StepsCheckinScreen(),
      transition: Transition.cupertino,
    ),
    GetPage(
      name: AppRoutes.weight,
      page: () => const WeightCheckinScreen(),
      transition: Transition.cupertino,
    ),
    GetPage(
      name: AppRoutes.sexualWellness,
      page: () => const SexualWellnessScreen(),
      transition: Transition.cupertino,
    ),
    GetPage(
      name: AppRoutes.addiction,
      page: () => const AddictionScreen(),
      transition: Transition.cupertino,
    ),
    GetPage(
      name: AppRoutes.journeyAhead,
      page: () => const JourneyAheadScreen(),
      transition: Transition.cupertino,
    ),
    GetPage(
      name: AppRoutes.settings,
      page: () => const SettingsScreen(),
      transition: Transition.cupertino,
    ),
    GetPage(
      name: AppRoutes.contactNutritionist,
      page: () => const NutritionistListScreen(),
      transition: Transition.cupertino,
    ),
  ];
}
