import 'package:disha_ai/features/nutritionist/presentation/controllers/expert_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../app/theme/app_colors.dart';
import '../../data/models/expert_model.dart';

class NutritionistDetailScreen extends StatefulWidget {
  const NutritionistDetailScreen({super.key, required this.expert});

  final ExpertModel expert;

  @override
  State<NutritionistDetailScreen> createState() =>
      _NutritionistDetailScreenState();
}

class _NutritionistDetailScreenState extends State<NutritionistDetailScreen> {
  final ExpertController _expertController = Get.find<ExpertController>();

  void _showConsultDialog() {
    final TextEditingController messageController = TextEditingController(
      text: "I want a customized diet plan.",
    );

    Get.defaultDialog(
      title: "Consult ${widget.expert.name}",
      titleStyle: const TextStyle(color: AppColors.textPrimary),
      backgroundColor: AppColors.surface,
      content: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            TextField(
              controller: messageController,
              maxLines: 3,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(
                hintText: "Enter your message...",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Obx(
              () => ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                ),
                onPressed: _expertController.isConsulting.value
                    ? null
                    : () async {
                        final success = await _expertController.consultExpert(
                          expertId: widget.expert.id,
                          message: messageController.text,
                        );
                        Get.back();
                        if (success) {
                          Get.snackbar(
                            'Success',
                            'Enquiry sent successfully to ${widget.expert.name}!',
                            snackPosition: SnackPosition.BOTTOM,
                            backgroundColor: AppColors.surface,
                            colorText: AppColors.textPrimary,
                          );
                        } else {
                          Get.snackbar(
                            'Error',
                            _expertController.errorMessage.value,
                            snackPosition: SnackPosition.BOTTOM,
                            backgroundColor: Colors.redAccent,
                            colorText: Colors.white,
                          );
                        }
                      },
                child: _expertController.isConsulting.value
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.black,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        "Send Enquiry",
                        style: TextStyle(color: Colors.black),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        backgroundColor: AppColors.background,
        leading: IconButton(
          onPressed: () => Get.back(),
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.primary,
          ),
        ),
        title: Text(
          widget.expert.name,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final isTablet = width >= 700;
            final horizontalPadding = isTablet ? width * 0.15 : 20.0;

            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: 20,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 800),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Profile Header Card
                      _buildProfileHeader(),
                      const SizedBox(height: 24),

                      // Designation Section
                      _buildInfoSection(
                        title: "Designation",
                        content:
                            widget.expert.designation ??
                            'Professional Health Consultant',
                        icon: Icons.work_history_rounded,
                      ),
                      const SizedBox(height: 20),

                      // Expertise Section
                      _buildInfoSection(
                        title: "Expertise & Specialties",
                        content:
                            widget.expert.specialization ??
                            'Clinical Nutrition & Wellness',
                        icon: Icons.verified_rounded,
                      ),
                      const SizedBox(height: 20),

                      // About Section
                      _buildInfoSection(
                        title: "About",
                        content:
                            "Dedicated and certified nutrition specialist with a proven track record of helping clients achieve sustainable health, weight management, and metabolic well-being through personalized, evidence-based meal plans.",
                        icon: Icons.info_outline_rounded,
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: _buildBottomActionBar(),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withOpacity(.15)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.15),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 38,
            backgroundColor: AppColors.background,
            backgroundImage:
                widget.expert.imageUrl != null &&
                    widget.expert.imageUrl!.isNotEmpty
                ? NetworkImage(widget.expert.imageUrl!)
                : const AssetImage('assets/images/Profile.png')
                      as ImageProvider,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.expert.name,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  widget.expert.specialization ?? 'Specialist',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection({
    required String title,
    required String content,
    required IconData icon,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withOpacity(.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 20),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            content,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13.5,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActionBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(color: AppColors.primary.withOpacity(.12)),
        ),
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: _showConsultDialog,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.black,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text(
              "Consult Now",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
          ),
        ),
      ),
    );
  }
}
