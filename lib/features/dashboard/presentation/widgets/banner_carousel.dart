import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/theme/app_colors.dart';
import '../controllers/banner_controller.dart';

class BannerCarousel extends StatefulWidget {
  const BannerCarousel({
    super.key,
    required this.category,
    this.title,
    this.subtitle,
    this.height = 175,
    this.autoSlideDuration = const Duration(seconds: 5),
    this.showSectionTitle = true,
    this.onVisibilityChanged,
  });

  final String category;
  final String? title;
  final String? subtitle;
  final double height;
  final Duration autoSlideDuration;
  final bool showSectionTitle;

  // NEW: Notify parent when banners become available/unavailable.
  final ValueChanged<bool>? onVisibilityChanged;

  @override
  State<BannerCarousel> createState() => BannerCarouselState();
}

class BannerCarouselState extends State<BannerCarousel> {
  // ============================================================
  // CONTROLLER
  //
  // Each carousel owns a separate controller so banner requests
  // from different Quick Action screens cannot overwrite each other.
  // ============================================================

  late final BannerController _bannerController;

  // ============================================================
  // PAGE CONTROLLER
  // ============================================================

  final PageController _pageController = PageController(viewportFraction: 0.92);

  // ============================================================
  // AUTO SLIDE
  // ============================================================

  Timer? _autoSlideTimer;

  int _currentPage = 0;

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    _bannerController = BannerController();

    refreshBanners();

    _startAutoSlide();
  }

  // ============================================================
  // UPDATE CATEGORY
  // ============================================================

  @override
  void didUpdateWidget(covariant BannerCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.category != widget.category) {
      _currentPage = 0;

      if (_pageController.hasClients) {
        _pageController.jumpToPage(0);
      }

      refreshBanners();
    }

    if (oldWidget.autoSlideDuration != widget.autoSlideDuration) {
      _startAutoSlide();
    }
  }

  // ============================================================
  // FETCH BANNERS
  // ============================================================

  Future<void> refreshBanners() async {
    await _bannerController.fetchBanners(category: widget.category);

    if (!mounted) return;

    final count = _bannerController.banners.length;

    if (count == 0 || _currentPage >= count) {
      _currentPage = 0;

      if (_pageController.hasClients) {
        _pageController.jumpToPage(0);
      }

      setState(() {});
    }

    // Notify parent after fetching banners.
    widget.onVisibilityChanged?.call(count > 0);
  }

  // ============================================================
  // AUTO SLIDE
  // ============================================================

  void _startAutoSlide() {
    _autoSlideTimer?.cancel();

    if (widget.autoSlideDuration <= Duration.zero) {
      return;
    }

    _autoSlideTimer = Timer.periodic(widget.autoSlideDuration, (_) {
      if (!mounted || !_pageController.hasClients) {
        return;
      }

      final banners = _bannerController.banners;

      if (banners.length <= 1) {
        return;
      }

      final nextPage = (_currentPage + 1) % banners.length;

      _pageController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 650),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _autoSlideTimer?.cancel();

    _pageController.dispose();

    _bannerController.onClose();

    super.dispose();
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final banners = _bannerController.banners;

      // Same behavior as Meditation:
      // Hide the banner section when no banners are available.
      if (banners.isEmpty) {
        return const SizedBox.shrink();
      }

      final width = MediaQuery.sizeOf(context).width;

      final scale = (width / 390).clamp(0.88, 1.12);

      final bannerHeight = widget.height * scale;

      final currentPage = _currentPage.clamp(0, banners.length - 1);

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ======================================================
          // SECTION TITLE
          // ======================================================
          if (widget.showSectionTitle) ...[
            _buildSectionHeader(scale),

            SizedBox(height: 14 * scale),
          ],

          // ======================================================
          // BANNER SLIDER
          // ======================================================
          SizedBox(
            height: bannerHeight,
            child: PageView.builder(
              controller: _pageController,
              physics: const BouncingScrollPhysics(),
              itemCount: banners.length,
              onPageChanged: (index) {
                if (!mounted) return;

                setState(() {
                  _currentPage = index;
                });
              },
              itemBuilder: (context, index) {
                final banner = banners[index];

                return Padding(
                  padding: EdgeInsets.only(right: 12 * scale),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18 * scale),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        // ==========================================
                        // API BANNER IMAGE
                        // ==========================================
                        Image.network(
                          banner.imageUrl,
                          fit: BoxFit.cover,

                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) {
                              return child;
                            }

                            return _buildImagePlaceholder(scale);
                          },

                          errorBuilder: (context, error, stackTrace) {
                            return _buildImagePlaceholder(scale);
                          },
                        ),

                        // ==========================================
                        // GRADIENT OVERLAY
                        // ==========================================
                        DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withOpacity(0.15),
                                Colors.black.withOpacity(0.82),
                              ],
                              stops: const [0.0, 0.55, 1.0],
                            ),
                          ),
                        ),

                        // ==========================================
                        // API CATEGORY NAME
                        // ==========================================
                        if (banner.categoryName.trim().isNotEmpty)
                          Positioned(
                            left: 18 * scale,
                            right: 18 * scale,
                            bottom: 18 * scale,
                            child: Text(
                              banner.categoryName,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 17 * scale,
                                fontWeight: FontWeight.w700,
                                height: 1.2,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // ======================================================
          // PAGINATION INDICATORS
          // ======================================================
          if (banners.length > 1) ...[
            SizedBox(height: 12 * scale),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(banners.length, (index) {
                final isActive = currentPage == index;

                return AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOut,
                  margin: EdgeInsets.symmetric(horizontal: 3 * scale),
                  width: (isActive ? 20 : 7) * scale,
                  height: 7 * scale,
                  decoration: BoxDecoration(
                    color: isActive
                        ? AppColors.primary
                        : AppColors.primary.withOpacity(0.22),
                    borderRadius: BorderRadius.circular(8),
                  ),
                );
              }),
            ),
          ],
        ],
      );
    });
  }

  // ============================================================
  // SECTION HEADER
  // ============================================================

  Widget _buildSectionHeader(double scale) {
    final sectionTitle = widget.title ?? '${widget.category} Highlights';

    final sectionSubtitle =
        widget.subtitle ??
        'Discover something helpful for your wellness journey';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          sectionTitle,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 17 * scale,
            fontWeight: FontWeight.w700,
          ),
        ),

        SizedBox(height: 4 * scale),

        Text(
          sectionSubtitle,
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 11.5 * scale,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // IMAGE PLACEHOLDER
  // ============================================================

  Widget _buildImagePlaceholder(double scale) {
    return Container(
      color: AppColors.surface,
      child: Center(
        child: Icon(
          _getCategoryIcon(),
          color: AppColors.primary,
          size: 56 * scale,
        ),
      ),
    );
  }

  // ============================================================
  // CATEGORY ICON
  // ============================================================

  IconData _getCategoryIcon() {
    switch (widget.category.toLowerCase()) {
      case 'meditation':
        return Icons.self_improvement_rounded;

      case 'workout':
        return Icons.fitness_center_rounded;

      case 'water':
        return Icons.water_drop_rounded;

      case 'meals':
      case 'nutrition':
        return Icons.restaurant_rounded;

      case 'sleep':
        return Icons.nightlight_round;

      case 'progress':
        return Icons.insights_rounded;

      case 'weight':
        return Icons.monitor_weight_rounded;

      case 'vitals':
        return Icons.favorite_rounded;

      case 'mood':
        return Icons.mood_rounded;

      case 'steps':
        return Icons.directions_walk_rounded;

      case 'sexual-wellness':
        return Icons.health_and_safety_rounded;

      case 'addictions':
        return Icons.psychology_rounded;

      case 'medical-record':
        return Icons.medical_services_rounded;

      case 'ai-coach':
        return Icons.auto_awesome_rounded;

      default:
        return Icons.spa_rounded;
    }
  }
}
