import 'package:disha_ai/features/ai_health_coach/presentation/controllers/ai_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/theme/app_colors.dart';

class ExplainMedicalReportScreen extends StatefulWidget {
  const ExplainMedicalReportScreen({super.key});

  @override
  State<ExplainMedicalReportScreen> createState() =>
      _ExplainMedicalReportScreenState();
}

class _ExplainMedicalReportScreenState
    extends State<ExplainMedicalReportScreen> {
  //==============================================================
  // CONTROLLERS
  //==============================================================
  final AiController _aiController = Get.put(AiController());
  final TextEditingController _reportController = TextEditingController();

  // Track which view is currently active: 'report' or 'lab'
  String _activeTab = 'report';

  @override
  void dispose() {
    _reportController.dispose();
    super.dispose();
  }

  //==============================================================
  // API ACTIONS
  //==============================================================

  Future<void> _explainReport() async {
    final text = _reportController.text.trim();
    if (text.isEmpty) {
      Get.snackbar(
        "Input Required",
        "Please enter your medical summary or prescription notes.",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.surface,
        colorText: AppColors.textPrimary,
      );
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() {
      _activeTab = 'report';
    });

    final success = await _aiController.explainMedicalReport(text);

    if (!success) {
      Get.snackbar(
        "Error",
        _aiController.errorMessage.value.isNotEmpty
            ? _aiController.errorMessage.value
            : "Failed to analyze medical report.",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent.withOpacity(0.9),
        colorText: Colors.white,
      );
    }
  }

  Future<void> _runLabAnalysis() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _activeTab = 'lab';
    });

    final success = await _aiController.analyzeLabReport();

    if (!success) {
      Get.snackbar(
        "Analysis Failed",
        _aiController.errorMessage.value.isNotEmpty
            ? _aiController.errorMessage.value
            : "Could not process lab report analysis.",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent.withOpacity(0.9),
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
      );
    }
  }

  //==============================================================
  // BUILD
  //==============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "AI Medical & Lab Assistant",
          style: TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.w700,
            fontSize: 17,
          ),
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Card info
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.medical_information_rounded,
                      color: AppColors.primary,
                      size: 28,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        "Paste report notes below for a quick breakdown, or run an automated deep diagnostic check on your lab results.",
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 13.5,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              const Text(
                "Report Summary / Text",
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),

              // Text Field Input
              TextField(
                controller: _reportController,
                maxLines: 5,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                ),
                decoration: InputDecoration(
                  hintText:
                      "e.g., Complete Blood Count normal range, Hemoglobin 12.5 g/dL...",
                  hintStyle: TextStyle(
                    color: AppColors.textSecondary.withOpacity(0.6),
                  ),
                  filled: true,
                  fillColor: AppColors.surface,
                  contentPadding: const EdgeInsets.all(16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: AppColors.primary,
                      width: 1.5,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Action Buttons Row
              Row(
                children: [
                  // Explain Report Button
                  Expanded(
                    child: Obx(() {
                      final isLoading = _aiController.isExplainingReport.value;
                      return SizedBox(
                        height: 50,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            gradient: const LinearGradient(
                              colors: [
                                AppColors.primaryDark,
                                AppColors.primary,
                              ],
                            ),
                          ),
                          child: ElevatedButton(
                            onPressed: isLoading ? null : _explainReport,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: isLoading
                                ? const SizedBox(
                                    height: 22,
                                    width: 22,
                                    child: CircularProgressIndicator(
                                      color: Colors.black54,
                                      strokeWidth: 2.5,
                                    ),
                                  )
                                : const Text(
                                    "Explain Text",
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                    ),
                                  ),
                          ),
                        ),
                      );
                    }),
                  ),

                  const SizedBox(width: 12),

                  // Run Lab Analyzer Button
                  Expanded(
                    child: Obx(() {
                      final isLabLoading = _aiController.isLabAnalyzing.value;
                      return SizedBox(
                        height: 50,
                        child: OutlinedButton(
                          onPressed: isLabLoading ? null : _runLabAnalysis,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            side: const BorderSide(
                              color: AppColors.primary,
                              width: 1.5,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: isLabLoading
                              ? const SizedBox(
                                  height: 22,
                                  width: 22,
                                  child: CircularProgressIndicator(
                                    color: AppColors.primary,
                                    strokeWidth: 2.5,
                                  ),
                                )
                              : const Text(
                                  "Analyze Labs",
                                  style: TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                  ),
                                ),
                        ),
                      );
                    }),
                  ),
                ],
              ),

              const SizedBox(height: 28),

              // Results Container Section
              Obx(() {
                final reportResp = _aiController.reportExplanation.value;
                final labResp = _aiController.labAnalysis.value;

                // Dynamically select data based on which button was pressed last
                final dynamic activeData = (_activeTab == 'report')
                    ? reportResp?.data
                    : labResp?.data;

                if (activeData == null) {
                  return const SizedBox.shrink();
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _activeTab == 'report'
                          ? "AI Report Explanation"
                          : "AI Lab Diagnostic Insights",
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.primary.withOpacity(0.4),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.06),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: SelectableText(
                        _parseResponseData(activeData),
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                          height: 1.6,
                        ),
                      ),
                    ),
                  ],
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  String _parseResponseData(dynamic data) {
    if (data == null) return "No insights generated.";
    if (data is String) return data;
    if (data is Map<String, dynamic>) {
      return data['analysis']?.toString() ??
          data['explanation']?.toString() ??
          data['summary']?.toString() ??
          data['message']?.toString() ??
          data.toString();
    }
    return data.toString();
  }
}
