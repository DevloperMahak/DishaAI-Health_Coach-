import 'package:disha_ai/features/onboarding/presentation/controllers/health_nutrition_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pedometer/pedometer.dart';
import 'package:disha_ai/app/theme/app_colors.dart';
import 'package:permission_handler/permission_handler.dart';

class StepsCheckinScreen extends StatefulWidget {
  const StepsCheckinScreen({super.key});

  @override
  State<StepsCheckinScreen> createState() => _StepsCheckinScreenState();
}

class _StepsCheckinScreenState extends State<StepsCheckinScreen> {
  final HealthNutritionController _healthController = Get.put(
    HealthNutritionController(),
  );

  late Stream<StepCount> _stepCountStream;
  late Stream<PedestrianStatus> _pedestrianStatusStream;

  String _steps = "0";
  String _status = "Initializing...";
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _initPlatformState();
  }

  Future<void> _initPlatformState() async {
    // 1. Request Activity Recognition Permission (Android 10+)
    var status = await Permission.activityRecognition.request();
    if (!status.isGranted) {
      setState(() {
        _status = "Permission Denied for Step Counter";
      });
      return;
    }

    // 2. Initialize Pedometer Streams
    _pedestrianStatusStream = Pedometer.pedestrianStatusStream;
    _pedestrianStatusStream
        .listen(onPedestrianStatusChanged)
        .onError(onPedestrianStatusError);

    _stepCountStream = Pedometer.stepCountStream;
    _stepCountStream.listen(onStepCount).onError(onStepCountError);
  }

  void onStepCount(StepCount event) {
    setState(() {
      _steps = event.steps.toString();
    });
  }

  void onPedestrianStatusChanged(PedestrianStatus event) {
    setState(() {
      _status = event.status; // e.g. "walking", "stopped"
    });
  }

  void onStepCountError(error) {
    setState(() {
      _status = "Step Count Not Available";
    });
  }

  void onPedestrianStatusError(error) {
    setState(() {
      _status = "Pedestrian Status Not Available";
    });
  }

  // Sync auto-captured steps with backend API
  Future<void> _syncStepsToApi() async {
    final parsedSteps = int.tryParse(_steps) ?? 0;
    setState(() => _isSubmitting = true);

    final currentLog = _healthController.healthLog.value;

    final success = await _healthController.postHealthMetrics(
      steps: parsedSteps,
      sleepHours: currentLog?.sleepHours ?? 7.5,
      caloriesConsumed: currentLog?.caloriesConsumed ?? 1800,
      caloriesBurned: currentLog?.caloriesBurned ?? 350,
      weightKg: currentLog?.weightKg ?? 58.0,
      mood: currentLog?.mood ?? "energetic",
      stressLevel: currentLog?.stressLevel ?? "low",
    );

    setState(() => _isSubmitting = false);

    if (success) {
      Get.back();
      Get.snackbar(
        "Steps Synced",
        "Successfully synced $parsedSteps live steps to your profile!",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.surface,
        colorText: AppColors.textPrimary,
        margin: const EdgeInsets.all(16),
        icon: const Icon(Icons.check_circle_rounded, color: AppColors.primary),
      );
    } else {
      Get.snackbar(
        "Sync Failed",
        "Could not sync steps with server. Try again.",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent.withOpacity(0.9),
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: const Text(
          "Auto Step Counter",
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 10),
              // LIVE PEDOMETER CIRCULAR DISPLAY
              Container(
                padding: const EdgeInsets.all(40),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.surface,
                  border: Border.all(
                    color: AppColors.primary.withOpacity(0.3),
                    width: 3,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.directions_walk_rounded,
                      color: AppColors.primary,
                      size: 48,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _steps,
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text(
                      "Steps Today",
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              // LIVE SENSOR STATUS
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _status == 'walking'
                        ? Icons.directions_run
                        : Icons.accessibility_new,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      "Motion Status: ${_status.capitalizeFirst}",
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              const Text(
                "Your phone's hardware sensor is automatically tracking your steps in real-time.",
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 50),

              // SYNC TO BACKEND BUTTON
              ElevatedButton(
                onPressed: _isSubmitting ? null : _syncStepsToApi,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.black,
                  minimumSize: const Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          color: Colors.black,
                          strokeWidth: 2.5,
                        ),
                      )
                    : const Text(
                        "Sync Live Steps to Server",
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
