import 'package:disha_ai/features/ai_health_coach/presentation/controllers/ai_controller.dart';
import 'package:disha_ai/features/dashboard/presentation/widgets/banner_carousel.dart';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/theme/app_colors.dart';

class VitalsAnalysisScreen extends StatefulWidget {
  const VitalsAnalysisScreen({super.key});

  @override
  State<VitalsAnalysisScreen> createState() => _VitalsAnalysisScreenState();
}

class _VitalsAnalysisScreenState extends State<VitalsAnalysisScreen> {
  // ============================================================
  // CONTROLLERS
  // ============================================================

  final AiController _aiController = Get.isRegistered<AiController>()
      ? Get.find<AiController>()
      : Get.put(AiController());

  // ============================================================
  // OPTIONAL VITALS BANNER
  // ============================================================

  final GlobalKey<BannerCarouselState> _vitalsBannerKey =
      GlobalKey<BannerCarouselState>();

  bool _hasVitalsBanners = false;

  void _onVitalsBannerVisibilityChanged(bool visible) {
    if (!mounted || _hasVitalsBanners == visible) return;

    setState(() {
      _hasVitalsBanners = visible;
    });
  }

  // ============================================================
  // LIFECYCLE
  // ============================================================

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      _fetchVitalsAnalysis();
    });
  }

  // ============================================================
  // FETCH VITALS ANALYSIS
  // ============================================================

  Future<void> _fetchVitalsAnalysis() async {
    try {
      final success = await _aiController.analyzeVitals();

      if (!mounted) return;

      if (!success) {
        Get.snackbar(
          'Analysis Failed',
          _aiController.errorMessage.value.isNotEmpty
              ? _aiController.errorMessage.value
              : 'Could not fetch health vitals analysis.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.redAccent.withOpacity(0.9),
          colorText: Colors.white,
          margin: const EdgeInsets.all(16),
        );
      }
    } catch (e) {
      debugPrint('❌ [Vitals] Analysis error: $e');

      if (!mounted) return;

      Get.snackbar(
        'Analysis Failed',
        'Unable to fetch your vitals analysis. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent.withOpacity(0.9),
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
      );
    }
  }

  // ============================================================
  // REFRESH VITALS + BANNERS
  // ============================================================

  Future<void> _refreshVitalsScreen() async {
    await Future.wait<void>([
      _fetchVitalsAnalysis(),
      _vitalsBannerKey.currentState?.refreshBanners() ?? Future<void>.value(),
    ]);
  }

  // ============================================================
  // EXTRACTORS FOR VISUALIZATION
  // ============================================================

  Map<String, dynamic>? get _assessmentMap {
    final data = _aiController.vitalsAnalysis.value?.data;

    if (data is Map<String, dynamic>) {
      if (data['health_assessment'] is Map<String, dynamic>) {
        return data['health_assessment'] as Map<String, dynamic>;
      }

      return data;
    }

    return null;
  }

  int get _vitalScore {
    final score = _assessmentMap?['vital_score'];

    if (score != null) {
      return (int.tryParse(score.toString()) ?? 85).clamp(0, 100);
    }

    return 85;
  }

  String get _healthStatus {
    return _assessmentMap?['status']?.toString() ?? 'Balanced';
  }

  String get _recommendationText {
    return _assessmentMap?['recommendation']?.toString() ??
        'Maintain consistent water intake and daily activity levels.';
  }

  // ============================================================
  // OPTIONAL VITALS BANNER
  //
  // Backend category: Vitals
  //
  // Banner available:
  //   Display Meditation-style banner.
  //
  // No banner:
  //   Display nothing, including no additional spacing.
  // ============================================================

  Widget _buildOptionalVitalsBanner() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        BannerCarousel(
          key: _vitalsBannerKey,
          category: 'Vitals',
          title: 'Know Your Health',
          subtitle: 'Understand your body with AI-powered insights',
          height: 175,
          autoSlideDuration: const Duration(seconds: 5),
          showSectionTitle: true,
          onVisibilityChanged: _onVitalsBannerVisibilityChanged,
        ),

        if (_hasVitalsBanners) const SizedBox(height: 24),
      ],
    );
  }

  // ============================================================
  // HEADER DESCRIPTION CARD
  // ============================================================

  Widget _buildHeaderDescriptionCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withOpacity(0.25)),
      ),
      child: const Row(
        children: [
          Icon(Icons.monitor_heart_rounded, color: AppColors.primary, size: 28),

          SizedBox(width: 14),

          Expanded(
            child: Text(
              'Real-time evaluation of your key health indicators generated by Rhea AI.',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // VITAL SCORE CARD
  // ============================================================

  Widget _buildVitalScoreCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.primary.withOpacity(0.4)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.08),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Vital Score',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _healthStatus,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // ======================================================
          // CIRCULAR VITAL SCORE INDICATOR
          // ======================================================
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 110,
                height: 110,
                child: CircularProgressIndicator(
                  value: _vitalScore / 100,
                  strokeWidth: 10,
                  backgroundColor: AppColors.primary.withOpacity(0.15),
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    AppColors.primary,
                  ),
                  strokeCap: StrokeCap.round,
                ),
              ),

              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$_vitalScore',
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                    ),
                  ),

                  const Text(
                    '/ 100',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // AI RECOMMENDATION CARD
  // ============================================================

  Widget _buildAiRecommendationCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.primary.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.auto_awesome_rounded,
                color: AppColors.primary,
                size: 18,
              ),

              SizedBox(width: 8),

              Text(
                'AI Recommendation',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          Text(
            _recommendationText,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 13.5,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // VITALS ANALYSIS CONTENT
  // ============================================================

  Widget _buildVitalsAnalysisContent() {
    return Obx(() {
      if (_aiController.isVitalsAnalyzing.value) {
        return const Center(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 50),
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
        );
      }

      return Column(
        children: [
          _buildVitalScoreCard(),

          const SizedBox(height: 20),

          _buildAiRecommendationCard(),
        ],
      );
    });
  }

  // ============================================================
  // REFRESH BUTTON
  // ============================================================

  Widget _buildRefreshButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: const LinearGradient(
            colors: [AppColors.primaryDark, AppColors.primary],
          ),
        ),
        child: ElevatedButton(
          onPressed: _fetchVitalsAnalysis,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.refresh_rounded, color: Colors.black, size: 20),

              SizedBox(width: 8),

              Text(
                'Refresh Vitals',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,

      // ==========================================================
      // APP BAR — ORIGINAL UI PRESERVED
      // ==========================================================
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'AI Vitals Health Analysis',
          style: TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.w700,
            fontSize: 17,
          ),
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),

      // ==========================================================
      // BODY
      // ==========================================================
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          backgroundColor: AppColors.surface,
          onRefresh: _refreshVitalsScreen,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 700;

              return SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1100),
                    child: Padding(
                      padding: EdgeInsets.all(isWide ? 30 : 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ======================================
                          // OPTIONAL VITALS BANNER
                          // ======================================
                          _buildOptionalVitalsBanner(),

                          // ======================================
                          // ORIGINAL DESCRIPTION CARD
                          // ======================================
                          _buildHeaderDescriptionCard(),

                          const SizedBox(height: 24),

                          // ======================================
                          // VITALS ANALYSIS
                          // ======================================
                          _buildVitalsAnalysisContent(),

                          const SizedBox(height: 28),

                          // ======================================
                          // REFRESH VITALS BUTTON
                          // ======================================
                          _buildRefreshButton(),

                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
