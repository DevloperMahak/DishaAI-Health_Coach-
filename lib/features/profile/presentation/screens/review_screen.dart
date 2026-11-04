import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/theme/app_colors.dart';
import '../controllers/review_controller.dart';

class ReviewScreen extends StatefulWidget {
  const ReviewScreen({super.key});

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen>
    with SingleTickerProviderStateMixin {
  // ==============================================================
  // CONTROLLERS & STATE
  // ==============================================================

  final TextEditingController _categoryController = TextEditingController();

  final TextEditingController _messageController = TextEditingController();

  late final ReviewController _reviewController;

  PlatformFile? _selectedFile;

  // ==============================================================
  // ANIMATION
  // ==============================================================

  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _reviewController = Get.isRegistered<ReviewController>()
        ? Get.find<ReviewController>()
        : Get.put(ReviewController());

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.035), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
        );

    _animationController.forward();
  }

  @override
  void dispose() {
    _categoryController.dispose();
    _messageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  // ==============================================================
  // FILE PICKER
  // ==============================================================

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'webp', 'pdf'],
        allowMultiple: false,
        withData: false,
      );

      if (!mounted) {
        return;
      }

      if (result == null || result.files.isEmpty) {
        return;
      }

      final file = result.files.first;

      // API contract: maximum attachment size = 5 MB.
      if (file.size > 5 * 1024 * 1024) {
        Get.snackbar(
          'File Too Large',
          'Please select a file smaller than 5 MB.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.surface,
          colorText: AppColors.textPrimary,
          margin: const EdgeInsets.all(16),
          borderRadius: 14,
        );
        return;
      }

      if (file.path == null || file.path!.trim().isEmpty) {
        Get.snackbar(
          'File Error',
          'Unable to access the selected file.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.surface,
          colorText: AppColors.textPrimary,
          margin: const EdgeInsets.all(16),
          borderRadius: 14,
        );
        return;
      }

      setState(() {
        _selectedFile = file;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      Get.snackbar(
        'Error',
        'Failed to pick file: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.surface,
        colorText: Colors.redAccent,
        margin: const EdgeInsets.all(16),
        borderRadius: 14,
      );
    }
  }

  // ==============================================================
  // SUBMIT REVIEW
  // ==============================================================

  Future<void> _submitReview() async {
    final category = _categoryController.text.trim();
    final message = _messageController.text.trim();

    if (category.isEmpty || message.isEmpty) {
      Get.snackbar(
        'Validation Error',
        'Please fill in both category and message fields.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.surface,
        colorText: AppColors.textPrimary,
        margin: const EdgeInsets.all(16),
        borderRadius: 14,
      );
      return;
    }

    if (category.length > 50) {
      Get.snackbar(
        'Category Too Long',
        'Category must not exceed 50 characters.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.surface,
        colorText: AppColors.textPrimary,
        margin: const EdgeInsets.all(16),
        borderRadius: 14,
      );
      return;
    }

    if (message.length < 5) {
      Get.snackbar(
        'Message Too Short',
        'Message must contain at least 5 characters.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.surface,
        colorText: AppColors.textPrimary,
        margin: const EdgeInsets.all(16),
        borderRadius: 14,
      );
      return;
    }

    if (message.length > 2000) {
      Get.snackbar(
        'Message Too Long',
        'Message must not exceed 2000 characters.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.surface,
        colorText: AppColors.textPrimary,
        margin: const EdgeInsets.all(16),
        borderRadius: 14,
      );
      return;
    }

    FocusScope.of(context).unfocus();

    File? attachment;

    if (_selectedFile?.path != null && _selectedFile!.path!.trim().isNotEmpty) {
      attachment = File(_selectedFile!.path!);
    }

    final success = await _reviewController.submitReview(
      category: category,
      message: message,
      attachment: attachment,
    );

    if (!mounted) {
      return;
    }

    if (!success) {
      final error = _reviewController.errorMessage.value;

      Get.snackbar(
        'Submission Failed',
        error.isNotEmpty
            ? error
            : 'Unable to submit your review. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.surface,
        colorText: Colors.redAccent,
        margin: const EdgeInsets.all(16),
        borderRadius: 14,
        duration: const Duration(seconds: 4),
      );

      return;
    }

    Get.back();

    Get.snackbar(
      'Review Submitted',
      'Thank you for your valuable feedback!',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: AppColors.surface,
      colorText: AppColors.textPrimary,
      margin: const EdgeInsets.all(16),
      borderRadius: 14,
      duration: const Duration(seconds: 3),
    );
  }

  // ==============================================================
  // RESPONSIVE HELPERS
  // ==============================================================

  double _getHorizontalPadding(double width) {
    if (width <= 340) return 16;
    if (width <= 375) return 18;
    if (width <= 430) return 22;
    if (width <= 600) return 28;
    return 40;
  }

  double _getScale(double width) {
    return (width / 390).clamp(0.88, 1.15);
  }

  // ==============================================================
  // BUILD
  // ==============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      resizeToAvoidBottomInset: true,
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
        title: const Text(
          'Submit Review',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final height = constraints.maxHeight;
            final isTablet = width >= 700;

            if (isTablet) {
              return _buildTabletLayout(width: width, height: height);
            }

            return _buildPhoneLayout(width: width, height: height);
          },
        ),
      ),
    );
  }

  // ==============================================================
  // PHONE LAYOUT
  // ==============================================================

  Widget _buildPhoneLayout({required double width, required double height}) {
    final horizontalPadding = _getHorizontalPadding(width);

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.symmetric(
            horizontal: horizontalPadding,
            vertical: 20,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: height - 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeaderSection(width),
                const SizedBox(height: 24),
                _buildFormFields(width),
                const SizedBox(height: 32),
                _buildSubmitButton(width),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==============================================================
  // TABLET LAYOUT
  // ==============================================================

  Widget _buildTabletLayout({required double width, required double height}) {
    final contentWidth = width >= 1100 ? 620.0 : 560.0;

    return Center(
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: SizedBox(
            width: contentWidth,
            height: height,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeaderSection(contentWidth),
                  const SizedBox(height: 28),
                  _buildFormFields(contentWidth),
                  const SizedBox(height: 36),
                  _buildSubmitButton(contentWidth),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ==============================================================
  // HEADER SECTION
  // ==============================================================

  Widget _buildHeaderSection(double width) {
    final scale = _getScale(width);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'We value your feedback',
          style: TextStyle(
            fontSize: (22 * scale).clamp(20.0, 26.0),
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Share your thoughts, suggestions, or report issues below.',
          style: TextStyle(
            fontSize: (13.5 * scale).clamp(12.0, 15.0),
            color: AppColors.textSecondary,
            height: 1.45,
          ),
        ),
      ],
    );
  }

  // ==============================================================
  // FORM FIELDS
  // ==============================================================

  Widget _buildFormFields(double width) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Category',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _categoryController,
          maxLength: 50,
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
          decoration: _inputDecoration(
            hintText: 'e.g., Bug, Feature Request, General',
          ).copyWith(counterText: ''),
        ),
        const SizedBox(height: 20),

        const Text(
          'Subject / Message',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _messageController,
          maxLines: 5,
          maxLength: 2000,
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
          decoration: _inputDecoration(
            hintText: 'Write your review or message here...',
          ).copyWith(counterText: ''),
        ),
        const SizedBox(height: 24),

        _buildRatingSection(),

        const SizedBox(height: 24),

        const Text(
          'Attachment (Optional)',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        _buildFilePickerBox(),
      ],
    );
  }

  // ==============================================================
  // RATING
  // ==============================================================

  Widget _buildRatingSection() {
    return Obx(() {
      final rating = _reviewController.selectedRating.value;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Rating (Optional)',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.primary.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Row(
                    children: List.generate(5, (index) {
                      final starNumber = index + 1;
                      final isSelected = starNumber <= rating;

                      return IconButton(
                        onPressed: () {
                          _reviewController.setRating(starNumber);
                        },
                        icon: Icon(
                          isSelected
                              ? Icons.star_rounded
                              : Icons.star_border_rounded,
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.textSecondary,
                          size: 28,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 38,
                          minHeight: 38,
                        ),
                      );
                    }),
                  ),
                ),
                if (rating > 0)
                  TextButton(
                    onPressed: _reviewController.clearRating,
                    child: const Text(
                      'Clear',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      );
    });
  }

  // ==============================================================
  // INPUT DECORATION
  // ==============================================================

  InputDecoration _inputDecoration({required String hintText}) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(color: AppColors.textSecondary.withOpacity(0.6)),
      filled: true,
      fillColor: AppColors.surface,
      contentPadding: const EdgeInsets.all(16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: AppColors.primary.withOpacity(0.2)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: AppColors.primary.withOpacity(0.2)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.2),
      ),
    );
  }

  // ==============================================================
  // FILE PICKER
  // ==============================================================

  Widget _buildFilePickerBox() {
    return InkWell(
      onTap: _reviewController.isSubmitting.value ? null : _pickFile,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.primary.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.attach_file_rounded,
              color: AppColors.primary,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _selectedFile != null
                    ? _selectedFile!.name
                    : 'Choose a file (Optional)',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: _selectedFile != null
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
            ),
            if (_selectedFile != null)
              IconButton(
                icon: const Icon(
                  Icons.close_rounded,
                  color: Colors.redAccent,
                  size: 18,
                ),
                onPressed: _reviewController.isSubmitting.value
                    ? null
                    : () {
                        setState(() {
                          _selectedFile = null;
                        });
                      },
                constraints: const BoxConstraints(),
                padding: EdgeInsets.zero,
              )
            else
              const Text(
                'Browse',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 12.5,
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ==============================================================
  // SUBMIT BUTTON
  // ==============================================================

  Widget _buildSubmitButton(double width) {
    final scale = _getScale(width);
    final buttonHeight = (52 * scale).clamp(48.0, 56.0);
    final fontSize = (14 * scale).clamp(13.0, 15.5);
    final radius = (12 * scale).clamp(10.0, 14.0);

    return Obx(() {
      final isSubmitting = _reviewController.isSubmitting.value;

      return SizedBox(
        width: double.infinity,
        height: buttonHeight,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            gradient: const LinearGradient(
              colors: [AppColors.primaryDark, AppColors.primary],
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.18),
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: isSubmitting ? null : _submitReview,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              foregroundColor: Colors.black,
              disabledBackgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(radius),
              ),
            ),
            child: isSubmitting
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.black,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.send_rounded,
                        size: 18,
                        color: Colors.black,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Submit Review',
                        style: TextStyle(
                          fontSize: fontSize,
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      );
    });
  }
}
