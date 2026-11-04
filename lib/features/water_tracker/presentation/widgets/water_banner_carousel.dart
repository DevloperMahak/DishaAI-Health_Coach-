import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/theme/app_colors.dart';

import 'package:disha_ai/features/dashboard/presentation/controllers/banner_controller.dart';

class WaterBannerCarousel extends StatefulWidget {
  const WaterBannerCarousel({super.key});

  @override
  State<WaterBannerCarousel> createState() => WaterBannerCarouselState();
}

class WaterBannerCarouselState extends State<WaterBannerCarousel> {
  // ============================================================
  // BANNER CONTROLLER
  //
  // Independent controller prevents banners from other
  // categories from replacing Water banners.
  // ============================================================

  final BannerController _bannerController = BannerController();

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

    refreshBanners();

    _startAutoSlide();
  }

  // ============================================================
  // FETCH WATER BANNERS
  //
  // GET /api/banners?category=Water
  // ============================================================

  Future<void> refreshBanners() async {
    await _bannerController.fetchBanners(category: 'Water');

    if (!mounted) return;

    final count = _bannerController.banners.length;

    if (count == 0 || _currentPage >= count) {
      setState(() {
        _currentPage = 0;
      });

      if (_pageController.hasClients) {
        _pageController.jumpToPage(0);
      }
    }
  }

  // ============================================================
  // AUTO SLIDE
  // ============================================================

  void _startAutoSlide() {
    _autoSlideTimer?.cancel();

    _autoSlideTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted || !_pageController.hasClients) {
        return;
      }

      final count = _bannerController.banners.length;

      if (count <= 1) return;

      final nextPage = (_currentPage + 1) % count;

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
    return LayoutBuilder(
      builder: (context, constraints) {
        final scale = (constraints.maxWidth / 390).clamp(0.88, 1.12);

        return Obx(() {
          final banners = _bannerController.banners;

          // Hide section if API has no banners.
          if (banners.isEmpty) {
            return const SizedBox.shrink();
          }

          final currentPage = _currentPage.clamp(0, banners.length - 1);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ========================================
              // SECTION TITLE
              // ========================================
              Text(
                'Stay Hydrated',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 17 * scale,
                  fontWeight: FontWeight.w700,
                ),
              ),

              SizedBox(height: 4 * scale),

              Text(
                'A little inspiration for your hydration journey',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11.5 * scale,
                ),
              ),

              SizedBox(height: 14 * scale),

              // ========================================
              // BANNER SLIDER
              // ========================================
              SizedBox(
                height: 175 * scale,
                child: PageView.builder(
                  controller: _pageController,
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
                            // ============================
                            // API IMAGE
                            // ============================
                            Image.network(
                              banner.imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: AppColors.surface,
                                  child: Icon(
                                    Icons.water_drop_rounded,
                                    color: AppColors.primary,
                                    size: 56 * scale,
                                  ),
                                );
                              },
                            ),

                            // ============================
                            // GRADIENT
                            // ============================
                            DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.transparent,
                                    Colors.black.withOpacity(0.82),
                                  ],
                                ),
                              ),
                            ),

                            // ============================
                            // API CATEGORY NAME
                            // ============================
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

              SizedBox(height: 10 * scale),

              // ========================================
              // PAGINATION
              // ========================================
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(banners.length, (index) {
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: EdgeInsets.symmetric(horizontal: 3 * scale),
                    width: (currentPage == index ? 20 : 7) * scale,
                    height: 7 * scale,
                    decoration: BoxDecoration(
                      color: currentPage == index
                          ? AppColors.primary
                          : AppColors.primary.withOpacity(0.22),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  );
                }),
              ),
            ],
          );
        });
      },
    );
  }
}
