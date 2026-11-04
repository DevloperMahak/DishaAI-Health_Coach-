import 'dart:io';

import 'package:disha_ai/features/ai_health_coach/presentation/controllers/ai_controller.dart';
import 'package:disha_ai/features/dashboard/presentation/widgets/banner_carousel.dart';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../app/theme/app_colors.dart';

class ExplainMedicalReportScreen extends StatefulWidget {
  const ExplainMedicalReportScreen({super.key});

  @override
  State<ExplainMedicalReportScreen> createState() =>
      _ExplainMedicalReportScreenState();
}

class _ExplainMedicalReportScreenState
    extends State<ExplainMedicalReportScreen> {
  // ============================================================
  // CONTROLLERS
  // ============================================================

  final AiController _aiController = Get.isRegistered<AiController>()
      ? Get.find<AiController>()
      : Get.put(AiController());

  final TextEditingController _reportController = TextEditingController();

  final ImagePicker _imagePicker = ImagePicker();

  // ============================================================
  // OPTIONAL MEDICAL BANNER
  // ============================================================

  final GlobalKey<BannerCarouselState> _medicalBannerKey =
      GlobalKey<BannerCarouselState>();

  bool _hasMedicalBanners = false;

  void _onMedicalBannerVisibilityChanged(bool visible) {
    if (!mounted || _hasMedicalBanners == visible) return;

    setState(() {
      _hasMedicalBanners = visible;
    });
  }
  // ============================================================
  // OPTIONAL MEDICAL RECORD BANNER
  // ============================================================

  Widget _buildOptionalMedicalBanner() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        BannerCarousel(
          key: _medicalBannerKey,

          // Must match backend category exactly.
          category: 'Medical Record',

          title: 'Understand Your Health',
          subtitle: 'Get clearer insights into your medical information',

          height: 175,
          autoSlideDuration: const Duration(seconds: 5),

          showSectionTitle: true,

          onVisibilityChanged: _onMedicalBannerVisibilityChanged,
        ),

        // Spacing appears only when banners exist.
        if (_hasMedicalBanners) const SizedBox(height: 24),
      ],
    );
  }

  Future<void> _refreshMedicalScreen() async {
    await _medicalBannerKey.currentState?.refreshBanners();
  }

  // ============================================================
  // CURRENT FEATURE
  // ============================================================

  // report   = Explain Medical Report
  // medicine = Medicine / Prescription
  // lab      = Lab Report

  String _activeFeature = 'report';

  // ============================================================
  // ATTACHMENT STATE
  // ============================================================

  PlatformFile? _selectedFile;
  XFile? _selectedImage;

  // ============================================================
  // CONSTANTS
  // ============================================================

  static const int _maxFileSizeBytes = 10 * 1024 * 1024;

  static const List<String> _allowedExtensions = ['jpg', 'png', 'webp', 'pdf'];

  static const int _imageQuality = 95;

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _reportController.dispose();
    super.dispose();
  }

  // ============================================================
  // FEATURE SELECTION
  // ============================================================

  void _selectFeature(String feature) {
    FocusScope.of(context).unfocus();

    setState(() {
      _activeFeature = feature;

      // Clear attachment when switching feature.
      _selectedFile = null;
      _selectedImage = null;

      // Clear text when switching to file-based features.
      if (feature != 'report') {
        _reportController.clear();
      }
    });
  }

  // ============================================================
  // FILE PICKER
  // ============================================================

  Future<void> _pickFile() async {
    try {
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: _allowedExtensions,
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) {
        return;
      }

      final PlatformFile file = result.files.first;

      if (file.size > _maxFileSizeBytes) {
        _showError(
          'File Too Large',
          'Please select a file smaller than 10 MB.',
        );
        return;
      }

      if (file.path == null || file.path!.isEmpty) {
        _showError('File Error', 'The selected file could not be accessed.');
        return;
      }

      if (!mounted) return;

      setState(() {
        _selectedFile = file;
        _selectedImage = null;
      });
    } catch (e) {
      if (!mounted) return;
      _showError('Error', 'Failed to pick file: $e');
    }
  }

  // ============================================================
  // GALLERY
  // ============================================================

  Future<void> _pickImageFromGallery() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: _imageQuality,
      );

      if (image == null) return;

      if (!await _validateImageSize(image)) return;

      if (!mounted) return;

      setState(() {
        _selectedImage = image;
        _selectedFile = null;
      });
    } catch (e) {
      if (!mounted) return;
      _showError('Error', 'Failed to select image: $e');
    }
  }

  // ============================================================
  // CAMERA
  // ============================================================

  Future<void> _takePhoto() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: _imageQuality,
      );

      if (image == null) return;

      if (!await _validateImageSize(image)) return;

      if (!mounted) return;

      setState(() {
        _selectedImage = image;
        _selectedFile = null;
      });
    } catch (e) {
      if (!mounted) return;
      _showError('Error', 'Failed to take photo: $e');
    }
  }

  // ============================================================
  // IMAGE SIZE VALIDATION
  // ============================================================

  Future<bool> _validateImageSize(XFile image) async {
    try {
      final File imageFile = File(image.path);
      final int fileSize = await imageFile.length();

      if (fileSize > _maxFileSizeBytes) {
        if (mounted) {
          _showError(
            'Image Too Large',
            'Please select an image smaller than 10 MB.',
          );
        }
        return false;
      }
    } catch (_) {
      // Let API handle file read errors.
    }

    return true;
  }

  // ============================================================
  // REMOVE ATTACHMENT
  // ============================================================

  void _removeAttachment() {
    setState(() {
      _selectedImage = null;
      _selectedFile = null;
    });
  }

  // ============================================================
  // GET SELECTED FILE
  // ============================================================

  File? _getSelectedFile() {
    if (_selectedImage != null) {
      return File(_selectedImage!.path);
    }

    if (_selectedFile != null &&
        _selectedFile!.path != null &&
        _selectedFile!.path!.isNotEmpty) {
      return File(_selectedFile!.path!);
    }

    return null;
  }

  // ============================================================
  // 1. EXPLAIN MEDICAL REPORT
  //
  // POST /api/ai/explain-report
  //
  // TEXT ONLY
  // ============================================================

  Future<void> _explainMedicalReport() async {
    final String reportText = _reportController.text.trim();

    if (reportText.isEmpty) {
      _showError(
        'Text Required',
        'Please enter the medical report text or summary first.',
      );
      return;
    }

    FocusScope.of(context).unfocus();

    _aiController.medicineResponse.value = null;
    _aiController.labAnalysis.value = null;

    final bool success = await _aiController.explainMedicalReport(reportText);

    if (!mounted) return;

    if (!success) {
      _showError(
        'Explanation Failed',
        _aiController.errorMessage.value.isNotEmpty
            ? _aiController.errorMessage.value
            : 'Could not explain the medical report.',
      );
    }
  }

  // ============================================================
  // 2. ANALYZE MEDICINE / PRESCRIPTION
  //
  // POST /api/medicines
  //
  // FILE OR IMAGE
  // ============================================================

  Future<void> _analyzeMedicine() async {
    final File? fileToUpload = _getSelectedFile();

    if (fileToUpload == null) {
      _showError(
        'Attachment Required',
        'Please upload or capture a medicine bottle, syrup, tonic, or prescription.',
      );
      return;
    }

    if (!await _validateFileSize(fileToUpload)) return;

    if (!mounted) return;

    FocusScope.of(context).unfocus();

    _aiController.reportExplanation.value = null;
    _aiController.labAnalysis.value = null;

    final bool success = await _aiController.addMedicine(
      attachment: fileToUpload,
    );

    if (!mounted) return;

    if (!success) {
      _showError(
        'Medicine Analysis Failed',
        _aiController.errorMessage.value.isNotEmpty
            ? _aiController.errorMessage.value
            : 'Could not analyze the medicine or prescription.',
      );
    }
  }

  // ============================================================
  // 3. ANALYZE LAB REPORT
  //
  // POST /api/ai/analyze-labs
  //
  // REQUIRED FILE
  // ============================================================

  Future<void> _runLabAnalysis() async {
    final File? fileToUpload = _getSelectedFile();

    if (fileToUpload == null) {
      _showError(
        'Lab Report Required',
        'Please upload or capture a diagnostic lab report.',
      );
      return;
    }

    if (!await _validateFileSize(fileToUpload)) return;

    if (!mounted) return;

    FocusScope.of(context).unfocus();

    _aiController.reportExplanation.value = null;
    _aiController.medicineResponse.value = null;

    final String notes = _reportController.text.trim();

    final bool success = await _aiController.analyzeLabReport(
      reportFile: fileToUpload,
      notes: notes.isNotEmpty ? notes : null,
    );

    if (!mounted) return;

    if (!success) {
      _showError(
        'Lab Analysis Failed',
        _aiController.errorMessage.value.isNotEmpty
            ? _aiController.errorMessage.value
            : 'Could not analyze the lab report.',
      );
    }
  }

  // ============================================================
  // FILE SIZE VALIDATION
  // ============================================================

  Future<bool> _validateFileSize(File file) async {
    try {
      final int fileSize = await file.length();

      if (fileSize > _maxFileSizeBytes) {
        if (mounted) {
          _showError(
            'File Too Large',
            'Please select a file smaller than 10 MB.',
          );
        }
        return false;
      }
    } catch (_) {
      // Let API handle file read errors.
    }

    return true;
  }

  // ============================================================
  // ERROR SNACKBAR
  // ============================================================

  void _showError(String title, String message) {
    if (!mounted) return;

    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: AppColors.surface,
      colorText: AppColors.textPrimary,
      margin: const EdgeInsets.all(16),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'AI Medical Assistant',
          style: TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.w700,
            fontSize: 17,
          ),
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          backgroundColor: AppColors.surface,
          onRefresh: _refreshMedicalScreen,
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 30),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 900),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ======================================
                        // OPTIONAL MEDICAL BANNER
                        // ======================================
                        _buildOptionalMedicalBanner(),

                        // ======================================
                        // HEADER
                        // ======================================
                        _buildHeader(),

                        const SizedBox(height: 20),

                        // ======================================
                        // FEATURE SELECTOR
                        // ======================================
                        _buildFeatureSelector(),

                        const SizedBox(height: 24),

                        // ======================================
                        // ACTIVE FEATURE CONTENT
                        // ======================================
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 250),
                          child: _buildActiveFeature(),
                        ),

                        const SizedBox(height: 24),

                        // ======================================
                        // RESULTS
                        // ======================================
                        _buildResults(),
                      ],
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

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.primary.withOpacity(0.20)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.05),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.10),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.medical_services_rounded,
              color: AppColors.primary,
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Medical AI Tools',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'Choose the tool that matches your medical information. Each tool uses its dedicated AI analysis service.',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12.5,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // FEATURE SELECTOR
  // ============================================================

  Widget _buildFeatureSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Choose an AI Tool',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 10),
        _buildFeatureCard(
          feature: 'report',
          icon: Icons.description_rounded,
          title: 'Explain Medical Report',
          subtitle: 'Paste medical report text or summary',
        ),
        const SizedBox(height: 10),
        _buildFeatureCard(
          feature: 'medicine',
          icon: Icons.medication_rounded,
          title: 'Analyze Medicine / Prescription',
          subtitle: 'Bottle, syrup, tonic, or prescription',
        ),
        const SizedBox(height: 10),
        _buildFeatureCard(
          feature: 'lab',
          icon: Icons.science_rounded,
          title: 'Analyze Lab Report',
          subtitle: 'Diagnostic blood or laboratory report',
        ),
      ],
    );
  }

  // ============================================================
  // FEATURE CARD
  // ============================================================

  Widget _buildFeatureCard({
    required String feature,
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final bool selected = _activeFeature == feature;

    return InkWell(
      onTap: () => _selectFeature(feature),
      borderRadius: BorderRadius.circular(15),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withOpacity(0.10)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(selected ? 0.15 : 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppColors.primary, size: 23),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11.5,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              selected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_off_rounded,
              color: selected ? AppColors.primary : AppColors.textSecondary,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // ACTIVE FEATURE
  // ============================================================

  Widget _buildActiveFeature() {
    switch (_activeFeature) {
      case 'medicine':
        return _buildMedicineFeature();

      case 'lab':
        return _buildLabFeature();

      case 'report':
      default:
        return _buildReportFeature();
    }
  }

  // ============================================================
  // REPORT FEATURE
  // ============================================================

  Widget _buildReportFeature() {
    return Container(
      key: const ValueKey('report'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle(
            icon: Icons.description_rounded,
            title: 'Medical Report Text',
            subtitle:
                'Enter or paste the medical report summary you want Rhea to explain.',
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _reportController,
            maxLines: 7,
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
            decoration: InputDecoration(
              hintText:
                  'Example: Hemoglobin 12.5 g/dL, Vitamin D 55.9 ng/mL...',
              hintStyle: TextStyle(
                color: AppColors.textSecondary.withOpacity(0.65),
              ),
              filled: true,
              fillColor: AppColors.surface,
              contentPadding: const EdgeInsets.all(16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(
                  color: AppColors.primary,
                  width: 1.5,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Obx(() {
            final bool loading = _aiController.isExplainingReport.value;

            return _buildPrimaryButton(
              icon: Icons.auto_awesome_rounded,
              label: 'Explain Medical Report',
              loading: loading,
              onPressed: loading ? null : _explainMedicalReport,
            );
          }),
        ],
      ),
    );
  }

  // ============================================================
  // MEDICINE FEATURE
  // ============================================================

  Widget _buildMedicineFeature() {
    return Container(
      key: const ValueKey('medicine'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle(
            icon: Icons.medication_rounded,
            title: 'Medicine / Prescription',
            subtitle:
                'Upload a medicine bottle, syrup, Ayurvedic tonic, or prescription for analysis.',
          ),
          const SizedBox(height: 16),
          _buildAttachmentSection(showPdf: true),
          const SizedBox(height: 16),
          Obx(() {
            final bool loading = _aiController.isMedicineUploading.value;

            return _buildPrimaryButton(
              icon: Icons.medication_rounded,
              label: 'Analyze Medicine / Prescription',
              loading: loading,
              onPressed: loading ? null : _analyzeMedicine,
            );
          }),
        ],
      ),
    );
  }

  // ============================================================
  // LAB FEATURE
  // ============================================================

  Widget _buildLabFeature() {
    return Container(
      key: const ValueKey('lab'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle(
            icon: Icons.science_rounded,
            title: 'Diagnostic Lab Report',
            subtitle:
                'Upload a clear diagnostic laboratory report for parameter analysis.',
          ),
          const SizedBox(height: 16),
          _buildAttachmentSection(showPdf: true),
          const SizedBox(height: 16),
          const Text(
            'Optional Notes',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _reportController,
            maxLines: 3,
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
            decoration: InputDecoration(
              hintText: 'Add any context or notes about this lab report...',
              hintStyle: TextStyle(
                color: AppColors.textSecondary.withOpacity(0.65),
              ),
              filled: true,
              fillColor: AppColors.surface,
              contentPadding: const EdgeInsets.all(14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.border),
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
          const SizedBox(height: 16),
          Obx(() {
            final bool loading = _aiController.isLabAnalyzing.value;

            return _buildPrimaryButton(
              icon: Icons.science_rounded,
              label: 'Analyze Lab Report',
              loading: loading,
              onPressed: loading ? null : _runLabAnalysis,
            );
          }),
        ],
      ),
    );
  }

  // ============================================================
  // SECTION TITLE
  // ============================================================

  Widget _buildSectionTitle({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.10),
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(icon, color: AppColors.primary, size: 21),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11.5,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ============================================================
  // API INFO
  // ============================================================

  Widget _buildApiInfo(String endpoint, String description) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.primary.withOpacity(0.12)),
      ),
      child: Row(
        children: [
          const Icon(Icons.api_rounded, color: AppColors.primary, size: 18),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  endpoint,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 10.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // PRIMARY BUTTON
  // ============================================================

  Widget _buildPrimaryButton({
    required IconData icon,
    required String label,
    required bool loading,
    required VoidCallback? onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: const LinearGradient(
            colors: [AppColors.primaryDark, AppColors.primary],
          ),
        ),
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            disabledBackgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: loading
              ? const SizedBox(
                  height: 22,
                  width: 22,
                  child: CircularProgressIndicator(
                    color: Colors.black,
                    strokeWidth: 2.5,
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, color: Colors.black, size: 20),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        label,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.w800,
                          fontSize: 13.5,
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  // ============================================================
  // ATTACHMENT SECTION
  // ============================================================

  Widget _buildAttachmentSection({required bool showPdf}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Upload Source',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildAttachmentOption(
                icon: Icons.photo_library_rounded,
                title: 'Gallery',
                subtitle: 'Choose photo',
                onTap: _pickImageFromGallery,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildAttachmentOption(
                icon: Icons.camera_alt_rounded,
                title: 'Camera',
                subtitle: 'Take photo',
                onTap: _takePhoto,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildAttachmentOption(
                icon: Icons.attach_file_rounded,
                title: 'File',
                subtitle: showPdf ? 'PDF / JPG / PNG' : 'JPG / PNG',
                onTap: _pickFile,
              ),
            ),
          ],
        ),
        if (_selectedImage != null || _selectedFile != null) ...[
          const SizedBox(height: 12),
          _buildSelectedAttachment(),
        ],
      ],
    );
  }

  // ============================================================
  // ATTACHMENT OPTION
  // ============================================================

  Widget _buildAttachmentOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.primary, size: 24),
            const SizedBox(height: 7),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 9.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // SELECTED ATTACHMENT
  // ============================================================

  Widget _buildSelectedAttachment() {
    final bool hasImage = _selectedImage != null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: AppColors.primary.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          if (hasImage)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.file(
                File(_selectedImage!.path),
                width: 58,
                height: 58,
                fit: BoxFit.cover,
              ),
            )
          else
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.10),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.insert_drive_file_rounded,
                color: AppColors.primary,
                size: 30,
              ),
            ),
          const SizedBox(width: 12),
          Expanded(
            child: hasImage
                ? const Text(
                    'Image ready for analysis',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _selectedFile!.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'File ready for analysis',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
          ),
          IconButton(
            onPressed: _removeAttachment,
            tooltip: 'Remove attachment',
            icon: const Icon(
              Icons.close_rounded,
              color: Colors.redAccent,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // RESULTS
  // ============================================================

  Widget _buildResults() {
    return Obx(() {
      dynamic activeData;
      String title = '';

      if (_activeFeature == 'report') {
        activeData = _aiController.reportExplanation.value?.data;

        if (activeData != null) {
          title = 'AI Medical Report Explanation';
        }
      } else if (_activeFeature == 'medicine') {
        activeData = _aiController.medicineResponse.value?.data;

        if (activeData != null) {
          title = 'AI Medicine / Prescription Analysis';
        }
      } else if (_activeFeature == 'lab') {
        activeData = _aiController.labAnalysis.value?.data;

        if (activeData != null) {
          title = 'AI Lab Diagnostic Insights';
        }
      }

      if (activeData == null) {
        return const SizedBox.shrink();
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(height: 30, color: AppColors.border),
          Row(
            children: [
              const Icon(
                Icons.auto_awesome_rounded,
                color: AppColors.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.primary.withOpacity(0.30)),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.05),
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
    });
  }

  // ============================================================
  // RESPONSE PARSER
  // ============================================================

  String _parseResponseData(dynamic data) {
    if (data == null) {
      return 'No insights generated.';
    }

    if (data is String) {
      return data;
    }

    if (data is Map<String, dynamic>) {
      // ========================================================
      // LAB REPORT
      // ========================================================

      if (data.containsKey('overall_summary')) {
        final StringBuffer buffer = StringBuffer();

        final dynamic overallSummary = data['overall_summary'];

        if (overallSummary != null &&
            overallSummary.toString().trim().isNotEmpty) {
          buffer.writeln('Summary');
          buffer.writeln(overallSummary);
          buffer.writeln();
        }

        final dynamic counts = data['counts'];

        if (counts is Map) {
          final dynamic total = counts['total'] ?? 0;
          final dynamic normal = counts['normal'] ?? 0;
          final dynamic abnormal = counts['abnormal'] ?? 0;

          buffer.writeln('Report Overview');
          buffer.writeln('• Total Parameters: $total');
          buffer.writeln('• Normal: $normal');
          buffer.writeln('• Abnormal: $abnormal');
          buffer.writeln();
        }

        if (data['urgent_attention'] == true) {
          buffer.writeln('⚠️ URGENT ATTENTION REQUIRED');
          buffer.writeln();
        }

        final dynamic parameters = data['parameters'];

        if (parameters is List && parameters.isNotEmpty) {
          buffer.writeln('Lab Parameters');

          for (final dynamic parameter in parameters) {
            if (parameter is! Map) continue;

            final String name = parameter['name']?.toString() ?? 'Unknown';

            final String value = parameter['value']?.toString() ?? '-';

            final String unit = parameter['unit']?.toString() ?? '';

            final String referenceRange =
                parameter['reference_range']?.toString() ?? '-';

            final String status = parameter['status']?.toString() ?? 'unknown';

            final String explanation =
                parameter['explanation']?.toString() ?? '';

            buffer.writeln();
            buffer.writeln('• $name');

            buffer.writeln(
              '  Value: $value'
              '${unit.isNotEmpty ? ' $unit' : ''}',
            );

            buffer.writeln('  Reference: $referenceRange');
            buffer.writeln('  Status: ${_formatLabStatus(status)}');

            if (explanation.isNotEmpty) {
              buffer.writeln('  Explanation: $explanation');
            }
          }

          buffer.writeln();
        }

        final dynamic keyFindings = data['key_findings'];

        if (keyFindings is List && keyFindings.isNotEmpty) {
          buffer.writeln('Key Findings');

          for (final dynamic finding in keyFindings) {
            buffer.writeln('• $finding');
          }

          buffer.writeln();
        }

        final dynamic dietSuggestions = data['diet_suggestions'];

        if (dietSuggestions is List && dietSuggestions.isNotEmpty) {
          buffer.writeln('Diet Suggestions');

          for (final dynamic suggestion in dietSuggestions) {
            buffer.writeln('• $suggestion');
          }

          buffer.writeln();
        }

        final dynamic lifestyleSuggestions = data['lifestyle_suggestions'];

        if (lifestyleSuggestions is List && lifestyleSuggestions.isNotEmpty) {
          buffer.writeln('Lifestyle Suggestions');

          for (final dynamic suggestion in lifestyleSuggestions) {
            buffer.writeln('• $suggestion');
          }

          buffer.writeln();
        }

        final dynamic questions = data['questions_for_doctor'];

        if (questions is List && questions.isNotEmpty) {
          buffer.writeln('Questions to Ask Your Doctor');

          for (final dynamic question in questions) {
            buffer.writeln('• $question');
          }

          buffer.writeln();
        }

        final String? disclaimer = data['disclaimer']?.toString();

        if (disclaimer != null && disclaimer.trim().isNotEmpty) {
          buffer.writeln('Disclaimer');
          buffer.writeln(disclaimer);
        }

        final String result = buffer.toString().trim();

        return result.isNotEmpty ? result : 'No lab insights generated.';
      }

      // ========================================================
      // MEDICINE / PRESCRIPTION
      // ========================================================

      if (data.containsKey('medicine') && data.containsKey('report')) {
        final StringBuffer buffer = StringBuffer();

        final dynamic report = data['report'];

        if (report is Map) {
          if (report['summary'] != null) {
            buffer.writeln('${report['summary']}\n');
          }

          final dynamic reportWarnings = report['warnings'];

          if (reportWarnings is List && reportWarnings.isNotEmpty) {
            buffer.writeln('⚠️ Warnings');

            for (final dynamic warning in reportWarnings) {
              buffer.writeln('• $warning');
            }

            buffer.writeln();
          }

          final dynamic medicines = report['detected_medicines'];

          if (medicines is List) {
            for (final dynamic medicine in medicines) {
              if (medicine is! Map) continue;

              final String name = medicine['name']?.toString() ?? 'Medicine';

              final String? dosage = medicine['dosage']?.toString();

              final String? frequency = medicine['frequency']?.toString();

              final String? purpose = medicine['purpose']?.toString();

              final String? instructions = medicine['instructions']?.toString();

              buffer.writeln(
                '💊 $name'
                '${dosage != null && dosage.isNotEmpty ? ' ($dosage)' : ''}',
              );

              if (frequency != null && frequency.isNotEmpty) {
                buffer.writeln('   Frequency: $frequency');
              }

              if (purpose != null && purpose.isNotEmpty) {
                buffer.writeln('   Purpose: $purpose');
              }

              if (instructions != null && instructions.isNotEmpty) {
                buffer.writeln('   Instructions: $instructions');
              }

              final dynamic medicineWarnings = medicine['warnings'];

              if (medicineWarnings is List && medicineWarnings.isNotEmpty) {
                buffer.writeln('   ⚠️ Warnings:');

                for (final dynamic warning in medicineWarnings) {
                  buffer.writeln('      • $warning');
                }
              }

              buffer.writeln();
            }
          }
        }

        final String result = buffer.toString().trim();

        return result.isNotEmpty
            ? result
            : 'No prescription insights generated.';
      }

      // ========================================================
      // GENERIC RESPONSE
      // ========================================================

      return data['analysis']?.toString() ??
          data['explanation']?.toString() ??
          data['summary']?.toString() ??
          data['message']?.toString() ??
          data.toString();
    }

    return data.toString();
  }

  // ============================================================
  // LAB STATUS
  // ============================================================

  String _formatLabStatus(String status) {
    switch (status.toLowerCase()) {
      case 'normal':
        return 'Normal';

      case 'low':
        return 'Low';

      case 'high':
        return 'High';

      case 'abnormal':
        return 'Abnormal';

      case 'critical':
        return 'Critical';

      default:
        return status;
    }
  }
}
