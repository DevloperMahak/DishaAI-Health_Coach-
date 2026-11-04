import 'dart:async';

import 'package:disha_ai/features/dashboard/presentation/controllers/banner_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

import '../../../meditation/data/models/category_hub_model.dart';
import '../../data/models/workout_session.dart';
import '../../../../app/theme/app_colors.dart';
import 'package:disha_ai/features/meditation/presentation/controllers/category_hub_controller.dart';
import 'workout_player_screen.dart';

class WorkoutHomeScreen extends StatefulWidget {
  const WorkoutHomeScreen({super.key});

  @override
  State<WorkoutHomeScreen> createState() => _WorkoutHomeScreenState();
}

class _WorkoutHomeScreenState extends State<WorkoutHomeScreen>
    with SingleTickerProviderStateMixin {
  // ============================================================
  // CONTROLLER
  // ============================================================

  final CategoryHubController _controller = Get.put(CategoryHubController());
  final BannerController _bannerController =
      Get.isRegistered<BannerController>()
      ? Get.find<BannerController>()
      : Get.put(BannerController());

  // ============================================================
  // ANIMATIONS
  // ============================================================

  AnimationController? _animationController;
  Animation<double>? _fadeAnimation;
  Animation<Offset>? _slideAnimation;

  // ============================================================
  // SLIDERS & TIMERS
  // ============================================================

  final PageController _todayPageController = PageController(
    viewportFraction: 0.90,
  );
  Timer? _todayAutoSlideTimer;
  int _todayCurrentPage = 0;

  final PageController _bannerPageController = PageController(
    viewportFraction: 0.92,
  );
  int _bannerPage = 0;
  Timer? _bannerAutoSlideTimer;

  // ============================================================
  // FILTER SCROLL & HIGHLIGHT
  // ============================================================

  final GlobalKey _sessionsAnchorKey = GlobalKey();
  bool _showFilterHighlight = false;
  Timer? _highlightTimer;

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController!,
      curve: Curves.easeOut,
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.04), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController!,
            curve: Curves.easeOutCubic,
          ),
        );

    _animationController!.forward();

    // ==========================================================
    // FETCH DYNAMIC WORKOUT DATA
    // ==========================================================
    _controller.fetchCategoryDetails('workout');
    _loadWorkoutBanners();

    // ==========================================================
    // START AUTO SLIDERS
    // ==========================================================
    _startTodayAutoSlide();
    _startBannerAutoSlide();
  }

  // ============================================================
  // AUTO SLIDE BEHAVIORS
  // ============================================================

  void _startTodayAutoSlide() {
    _todayAutoSlideTimer?.cancel();

    _todayAutoSlideTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted) return;
      if (!_todayPageController.hasClients) return;

      final items = _getTodaySliderItems();

      if (items.length <= 1) return;

      if (_todayCurrentPage >= items.length) {
        _todayCurrentPage = 0;
        _todayPageController.jumpToPage(0);
        return;
      }

      final nextPage = (_todayCurrentPage + 1) % items.length;

      _todayPageController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 650),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  Future<void> _loadWorkoutBanners() async {
    await _bannerController.fetchBanners(category: 'Workout');
    if (!mounted) return;
    if (_bannerPageController.hasClients) {
      _bannerPageController.jumpToPage(0);
    }
    setState(() => _bannerPage = 0);
  }

  void _startBannerAutoSlide() {
    _bannerAutoSlideTimer?.cancel();

    _bannerAutoSlideTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted) return;
      if (!_bannerPageController.hasClients) return;
      final count = _bannerController.banners.length;
      if (count <= 1) return;

      final nextPage = (_bannerPage + 1) % count;

      _bannerPageController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 650),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  // ============================================================
  // SCROLL TO FILTER
  // ============================================================

  Future<void> _selectCategoryAndScroll(int? categoryId) async {
    _controller.selectedSubcategoryId.value = categoryId;

    // Wait until the filtered list has rebuilt before scrolling.
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;

    final target = _sessionsAnchorKey.currentContext;
    if (target != null) {
      await Scrollable.ensureVisible(
        target,
        duration: const Duration(milliseconds: 650),
        curve: Curves.easeInOutCubic,
        alignment: 0.08,
      );
    }

    if (!mounted) return;
    setState(() => _showFilterHighlight = true);

    _highlightTimer?.cancel();
    _highlightTimer = Timer(const Duration(milliseconds: 1300), () {
      if (mounted) setState(() => _showFilterHighlight = false);
    });
  }

  // ============================================================
  // GET TODAY SLIDER ITEMS
  // ============================================================

  List<ContentItem> _getTodaySliderItems() {
    final List<ContentItem> items = [];
    final hero = _controller.heroFeatured;

    if (hero != null) {
      items.add(hero);
    }

    for (final item in _controller.filteredContents) {
      final alreadyAdded = items.any(
        (existing) =>
            existing.id == item.id ||
            existing.title.trim().toLowerCase() ==
                item.title.trim().toLowerCase(),
      );

      if (!alreadyAdded) {
        items.add(item);
      }

      if (items.length >= 5) {
        break;
      }
    }

    return items;
  }

  // ============================================================
  // RESET TODAY SLIDER
  // ============================================================

  void _resetTodaySlider() {
    if (!mounted) return;
    _todayCurrentPage = 0;
    if (_todayPageController.hasClients) {
      _todayPageController.jumpToPage(0);
    }
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _todayAutoSlideTimer?.cancel();
    _todayAutoSlideTimer = null;

    _bannerAutoSlideTimer?.cancel();
    _bannerAutoSlideTimer = null;

    _highlightTimer?.cancel();
    _highlightTimer = null;

    _todayPageController.dispose();
    _bannerPageController.dispose();

    _animationController?.dispose();

    super.dispose();
  }

  // ============================================================
  // NAVIGATION & ACTIONS
  // ============================================================

  Future<void> _openWorkout(ContentItem item) async {
    final url = item.playbackUrl;
    final isYouTube =
        item.sourceType == 'youtube' ||
        item.contentType == 'video' ||
        (url != null &&
            (url.toLowerCase().contains('youtube.com') ||
                url.toLowerCase().contains('youtu.be')));

    if (isYouTube && url != null) {
      await _showVideoOptions(url: url, title: item.title);
      return;
    }

    final session = WorkoutSession(
      id: item.id.toString(),
      title: item.title,
      description: item.description ?? 'A quick full-body workout session',
      duration: item.durationText,
      minutes: item.durationMinutes,
      level: item.level,
      category: item.subcategoryName,
      calories: item.durationMinutes * 7,
      icon: Icons.fitness_center_rounded,
    );

    Get.to(
      () => WorkoutPlayerScreen(session: session),
      transition: Transition.cupertino,
    );
  }

  // ============================================================
  // OPEN SUGGESTED VIDEO
  // ============================================================

  Future<void> _openSuggestedVideo(SuggestedVideoItem video) async {
    final url = video.playbackUrl;
    if (url == null || url.trim().isEmpty) return;

    final normalizedUrl = url.trim().toLowerCase();
    final isYouTube =
        normalizedUrl.contains('youtube.com') ||
        normalizedUrl.contains('youtu.be');

    if (isYouTube) {
      await _showVideoOptions(url: url, title: video.title);
      return;
    }

    await _launchExternalUrl(url);
  }

  // ============================================================
  // VIDEO OPEN OPTIONS
  // ============================================================

  Future<void> _showVideoOptions({
    required String url,
    required String title,
  }) async {
    Get.bottomSheet(
      SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.textSecondary.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Choose how you want to watch this workout.',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12.5,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Get.back();
                    _openInAppYouTube(url, title);
                  },
                  icon: const Icon(Icons.play_circle_fill_rounded, size: 22),
                  label: const Text(
                    'Play in App',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.black,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Get.back();
                    _launchExternalUrl(url);
                  },
                  icon: const Icon(Icons.open_in_new_rounded, size: 20),
                  label: const Text(
                    'Open on YouTube',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textPrimary,
                    side: BorderSide(
                      color: AppColors.primary.withOpacity(0.35),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      isDismissible: true,
      enableDrag: true,
    );
  }

  // ============================================================
  // OPEN YOUTUBE INSIDE APP
  // ============================================================

  Future<void> _openInAppYouTube(String urlString, String title) async {
    final videoId = YoutubePlayer.convertUrlToId(urlString);

    if (videoId == null || videoId.trim().isEmpty) {
      await _launchExternalUrl(urlString);
      return;
    }

    if (!mounted) return;

    Get.to(
      () => InAppYoutubePlayerScreen(videoId: videoId, title: title),
      transition: Transition.cupertino,
    );
  }

  // ============================================================
  // OPEN VIDEO EXTERNALLY
  // ============================================================

  Future<void> _launchExternalUrl(String urlString) async {
    final Uri? url = Uri.tryParse(urlString.trim());

    if (url == null || !url.hasScheme || url.host.trim().isEmpty) {
      Get.snackbar(
        'Error',
        'Invalid video URL',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
      );
      return;
    }

    try {
      final launched = await launchUrl(
        url,
        mode: LaunchMode.externalApplication,
      );

      if (!launched) {
        Get.snackbar(
          'Error',
          'Could not open video URL',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.redAccent,
          colorText: Colors.white,
          margin: const EdgeInsets.all(16),
        );
      }
    } catch (_) {
      Get.snackbar(
        'Error',
        'Could not open video URL',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
      );
    }
  }

  void _goBack() => Get.back();

  IconData _getSubcategoryIcon(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('strength')) return Icons.fitness_center_rounded;
    if (lower.contains('cardio')) return Icons.directions_run_rounded;
    if (lower.contains('stretch')) return Icons.self_improvement_rounded;
    if (lower.contains('morning')) return Icons.wb_sunny_outlined;
    return Icons.flash_on_rounded;
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final animationController = _animationController;
    final fadeAnimation = _fadeAnimation;
    final slideAnimation = _slideAnimation;

    if (animationController == null ||
        fadeAnimation == null ||
        slideAnimation == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Obx(() {
          if (_controller.isLoading.value &&
              _controller.hubData.value == null) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          if (_controller.errorMessage.value.isNotEmpty &&
              _controller.hubData.value == null) {
            return _buildErrorState(MediaQuery.of(context).size.width);
          }

          return LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;

              if (width >= 700) {
                return _buildWideLayout(
                  width: width,
                  height: constraints.maxHeight,
                  fadeAnimation: fadeAnimation,
                  slideAnimation: slideAnimation,
                );
              }

              return _buildPhoneLayout(
                width: width,
                height: constraints.maxHeight,
                fadeAnimation: fadeAnimation,
                slideAnimation: slideAnimation,
              );
            },
          );
        }),
      ),
    );
  }

  // ============================================================
  // ERROR STATE
  // ============================================================

  Widget _buildErrorState(double width) {
    final scale = _scale(width);

    return Center(
      child: Padding(
        padding: EdgeInsets.all(24 * scale),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 70 * scale,
              height: 70 * scale,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.10),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.cloud_off_rounded,
                size: 34 * scale,
                color: AppColors.primary,
              ),
            ),
            SizedBox(height: 18 * scale),
            Text(
              'Unable to load workouts',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18 * scale,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: 8 * scale),
            Text(
              _controller.errorMessage.value,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13 * scale,
                color: AppColors.textSecondary,
              ),
            ),
            SizedBox(height: 20 * scale),
            ElevatedButton(
              onPressed: () {
                _controller.fetchCategoryDetails('workout');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: EdgeInsets.symmetric(
                  horizontal: 22 * scale,
                  vertical: 12 * scale,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12 * scale),
                ),
              ),
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // PHONE LAYOUT
  // ============================================================

  Widget _buildPhoneLayout({
    required double width,
    required double height,
    required Animation<double> fadeAnimation,
    required Animation<Offset> slideAnimation,
  }) {
    final horizontalPadding = _horizontalPadding(width);

    return FadeTransition(
      opacity: fadeAnimation,
      child: SlideTransition(
        position: slideAnimation,
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () async {
            await Future.wait([
              _controller.fetchCategoryDetails('workout'),
              _loadWorkoutBanners(),
            ]);
            _resetTodaySlider();
          },
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            slivers: [
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  16,
                  horizontalPadding,
                  30,
                ),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _buildAppBar(width),
                    const SizedBox(height: 26),
                    _buildGreeting(width),
                    const SizedBox(height: 28),
                    _buildStaticBanners(width),
                    const SizedBox(height: 20),
                    _buildTodayCard(width),
                    const SizedBox(height: 28),
                    _buildYouTubeSlider(width),
                    const SizedBox(height: 28),
                    _buildSectionTitle(
                      title: 'Explore Workouts',
                      subtitle: 'Choose what your body needs today',
                      width: width,
                    ),
                    const SizedBox(height: 14),
                    _buildCategories(width),
                    const SizedBox(height: 28),
                    _buildSessionsAnchor(width: width, spacing: 14),
                    const SizedBox(height: 28),
                    _buildSectionTitle(
                      title: _controller.suggestedVideosTitle.isNotEmpty
                          ? _controller.suggestedVideosTitle
                          : 'Recommended For You',
                      subtitle: _controller.suggestedVideosSubtitle.isNotEmpty
                          ? _controller.suggestedVideosSubtitle
                          : 'Personalized by RheaAI',
                      width: width,
                    ),
                    const SizedBox(height: 14),
                    _buildSuggestedVideoList(width),
                    const SizedBox(height: 24),
                    _buildAIRecommendation(width),
                    const SizedBox(height: 20),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // TABLET / WIDE LAYOUT
  // ============================================================

  Widget _buildWideLayout({
    required double width,
    required double height,
    required Animation<double> fadeAnimation,
    required Animation<Offset> slideAnimation,
  }) {
    final horizontalPadding = width >= 1400
        ? 120.0
        : width >= 1100
        ? 80.0
        : 40.0;

    return FadeTransition(
      opacity: fadeAnimation,
      child: SlideTransition(
        position: slideAnimation,
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () async {
            await Future.wait([
              _controller.fetchCategoryDetails('workout'),
              _loadWorkoutBanners(),
            ]);
            _resetTodaySlider();
          },
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    30,
                    horizontalPadding,
                    50,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildAppBar(width),
                      const SizedBox(height: 32),
                      _buildGreeting(width),
                      const SizedBox(height: 24),
                      _buildTodayCard(width),
                      const SizedBox(height: 34),
                      _buildStaticBanners(width),
                      const SizedBox(height: 34),
                      _buildYouTubeSlider(width),
                      const SizedBox(height: 34),
                      _buildSectionTitle(
                        title: 'Explore Workouts',
                        subtitle: 'Choose what your body needs today',
                        width: width,
                      ),
                      const SizedBox(height: 16),
                      _buildCategories(width),
                      const SizedBox(height: 36),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 3,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildSessionsAnchor(width: width, spacing: 16),
                                const SizedBox(height: 28),
                                _buildSectionTitle(
                                  title:
                                      _controller
                                          .suggestedVideosTitle
                                          .isNotEmpty
                                      ? _controller.suggestedVideosTitle
                                      : 'Recommended For You',
                                  subtitle:
                                      _controller
                                          .suggestedVideosSubtitle
                                          .isNotEmpty
                                      ? _controller.suggestedVideosSubtitle
                                      : 'Personalized by RheaAI',
                                  width: width,
                                ),
                                const SizedBox(height: 16),
                                _buildSuggestedVideoList(width),
                              ],
                            ),
                          ),
                          const SizedBox(width: 24),
                          Expanded(
                            flex: 2,
                            child: Column(
                              children: [_buildAIRecommendation(width)],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // STATIC BANNERS
  // ============================================================

  Widget _buildStaticBanners(double width) {
    final scale = _scale(width);
    return Obx(() {
      final banners = _bannerController.banners;
      if (banners.isEmpty) {
        if (_bannerController.isLoading.value) {
          return SizedBox(
            height: 175 * scale,
            child: const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          );
        }
        // The API has no workout banners, so do not display static images.
        return const SizedBox.shrink();
      }

      final activePage = _bannerPage >= banners.length ? 0 : _bannerPage;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle(
            title: 'Fitness Motivation',
            subtitle: 'Fuel your workout journey',
            width: width,
          ),
          SizedBox(height: 14 * scale),
          SizedBox(
            height: 175 * scale,
            child: PageView.builder(
              controller: _bannerPageController,
              itemCount: banners.length,
              onPageChanged: (index) {
                if (mounted) setState(() => _bannerPage = index);
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
                        Image.network(
                          banner.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: AppColors.surface,
                            child: Icon(
                              Icons.fitness_center_rounded,
                              color: AppColors.primary,
                              size: 56 * scale,
                            ),
                          ),
                        ),
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
                        Positioned(
                          left: 18 * scale,
                          right: 18 * scale,
                          bottom: 18 * scale,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                banner.categoryName.isNotEmpty
                                    ? banner.categoryName
                                    : 'Workout',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 17 * scale,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              SizedBox(height: 5 * scale),
                              Text(
                                'Fuel your workout journey',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 11 * scale,
                                ),
                              ),
                            ],
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
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              banners.length,
              (index) => AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: EdgeInsets.symmetric(horizontal: 3 * scale),
                width: (activePage == index ? 20 : 7) * scale,
                height: 7 * scale,
                decoration: BoxDecoration(
                  color: activePage == index
                      ? AppColors.primary
                      : AppColors.primary.withOpacity(0.22),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      );
    });
  }

  // ============================================================
  // SESSIONS ANCHOR
  // ============================================================

  Widget _buildSessionsAnchor({
    required double width,
    required double spacing,
  }) {
    return Container(
      key: _sessionsAnchorKey,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: _showFilterHighlight
            ? AppColors.primary.withOpacity(0.10)
            : Colors.transparent,
        border: Border.all(
          color: _showFilterHighlight ? AppColors.primary : Colors.transparent,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle(
            title: 'Workout Sessions',
            subtitle: 'Train at your own pace',
            width: width,
          ),
          SizedBox(height: spacing),
          _buildSessionList(width),
        ],
      ),
    );
  }

  // ============================================================
  // TODAY FEATURED AUTO SLIDER
  // ============================================================

  Widget _buildTodayCard(double width) {
    final scale = _scale(width);
    final items = _getTodaySliderItems();

    if (items.isEmpty) {
      return _buildTodayFallbackCard(width);
    }

    if (_todayCurrentPage >= items.length) {
      _todayCurrentPage = 0;
    }

    if (items.length == 1) {
      return _buildTodaySingleCard(
        item: items.first,
        width: width,
        scale: scale,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(
          title: 'Today for You',
          subtitle: 'Recommended sessions curated by RheaAI',
          width: width,
        ),
        SizedBox(height: 14 * scale),
        SizedBox(
          height: 240 * scale,
          child: PageView.builder(
            controller: _todayPageController,
            itemCount: items.length,
            physics: const BouncingScrollPhysics(),
            onPageChanged: (index) {
              if (!mounted) return;
              setState(() {
                _todayCurrentPage = index;
              });
            },
            itemBuilder: (context, index) {
              final item = items[index];

              return Padding(
                padding: EdgeInsets.only(right: 12 * scale),
                child: _buildTodaySliderCard(
                  item: item,
                  width: width,
                  scale: scale,
                  isFeatured: index == 0,
                ),
              );
            },
          ),
        ),
        SizedBox(height: 11 * scale),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(items.length, (index) {
            final active = index == _todayCurrentPage;

            return AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOut,
              margin: EdgeInsets.symmetric(horizontal: 3 * scale),
              width: active ? 19 * scale : 6 * scale,
              height: 6 * scale,
              decoration: BoxDecoration(
                color: active
                    ? AppColors.primary
                    : AppColors.primary.withOpacity(0.18),
                borderRadius: BorderRadius.circular(10),
              ),
            );
          }),
        ),
      ],
    );
  }

  // ============================================================
  // TODAY SLIDER CARD
  // ============================================================

  Widget _buildTodaySliderCard({
    required ContentItem item,
    required double width,
    required double scale,
    required bool isFeatured,
  }) {
    final isVideo =
        item.contentType == 'video' ||
        item.sourceType == 'youtube' ||
        (item.playbackUrl?.contains('youtube.com') ?? false);

    final thumbnailUrl = item.thumbnailUrl;

    return GestureDetector(
      onTap: () => _openWorkout(item),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18 * scale),
          color: AppColors.surface,
          border: Border.all(color: AppColors.primary.withOpacity(0.28)),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.10),
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18 * scale),
          child: Stack(
            children: [
              if (thumbnailUrl != null && thumbnailUrl.trim().isNotEmpty)
                Positioned.fill(
                  child: Image.network(
                    thumbnailUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) {
                      return _buildTodayBackground();
                    },
                  ),
                )
              else
                Positioned.fill(child: _buildTodayBackground()),
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.05),
                        Colors.black.withOpacity(0.22),
                        Colors.black.withOpacity(0.84),
                      ],
                      stops: const [0.0, 0.42, 1.0],
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 13 * scale,
                left: 13 * scale,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 9 * scale,
                    vertical: 5 * scale,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isFeatured
                            ? Icons.auto_awesome_rounded
                            : isVideo
                            ? Icons.videocam_rounded
                            : Icons.fitness_center_rounded,
                        color: Colors.black,
                        size: 12 * scale,
                      ),
                      SizedBox(width: 4 * scale),
                      Text(
                        isFeatured ? 'TODAY FOR YOU' : 'RECOMMENDED',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 8.5 * scale,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.7,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (item.durationText.isNotEmpty)
                Positioned(
                  top: 13 * scale,
                  right: 13 * scale,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 9 * scale,
                      vertical: 5 * scale,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.55),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      item.durationText,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 9.5 * scale,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              Positioned(
                left: 15 * scale,
                right: 15 * scale,
                bottom: 13 * scale,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            item.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16 * scale,
                              fontWeight: FontWeight.w700,
                              height: 1.15,
                            ),
                          ),
                          SizedBox(height: 5 * scale),
                          Text(
                            item.description ??
                                'A quick full-body workout to get your body moving.',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.82),
                              fontSize: 10.5 * scale,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 10 * scale),
                    Container(
                      width: 43 * scale,
                      height: 43 * scale,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.play_arrow_rounded,
                        color: Colors.black,
                        size: 23 * scale,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // TODAY BACKGROUND
  // ============================================================

  Widget _buildTodayBackground() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary.withOpacity(0.18), AppColors.surface],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.fitness_center_rounded,
          color: AppColors.primary.withOpacity(0.25),
          size: 72,
        ),
      ),
    );
  }

  // ============================================================
  // TODAY SINGLE CARD
  // ============================================================

  Widget _buildTodaySingleCard({
    required ContentItem item,
    required double width,
    required double scale,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(
          title: 'Today for You',
          subtitle: 'Recommended session curated by RheaAI',
          width: width,
        ),
        SizedBox(height: 14 * scale),
        SizedBox(
          height: 240 * scale,
          child: _buildTodaySliderCard(
            item: item,
            width: width,
            scale: scale,
            isFeatured: true,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // TODAY FALLBACK CARD
  // ============================================================

  Widget _buildTodayFallbackCard(double width) {
    final scale = _scale(width);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20 * scale),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18 * scale),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.surface, AppColors.background],
        ),
        border: Border.all(color: AppColors.primary.withOpacity(0.30)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46 * scale,
                height: 46 * scale,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.fitness_center_rounded,
                  color: AppColors.primary,
                  size: 23 * scale,
                ),
              ),
              SizedBox(width: 13 * scale),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TODAY FOR YOU',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 10 * scale,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '10 min full body',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 17 * scale,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 9 * scale,
                  vertical: 5 * scale,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '10 min',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 10.5 * scale,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 17 * scale),
          Text(
            'A quick full-body workout to get your body moving and energized.',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12.5 * scale,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // YOUTUBE SLIDER
  // ============================================================

  Widget _buildYouTubeSlider(double width) {
    final scale = _scale(width);
    final videoSessions =
        _controller.hubData.value?.guidedVideoSessions?.items ?? [];

    if (videoSessions.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(
          title:
              _controller.hubData.value?.guidedVideoSessions?.title ??
              'Guided Video Sessions',
          subtitle:
              _controller.hubData.value?.guidedVideoSessions?.subtitle ??
              'Watch and train along',
          width: width,
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 150 * scale,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: videoSessions.length,
            separatorBuilder: (_, __) => SizedBox(width: 14 * scale),
            itemBuilder: (context, index) {
              final video = videoSessions[index];
              final thumbnailUrl =
                  video.thumbnailUrl ??
                  'https://images.unsplash.com/photo-1518241353330-0f7941c2d9b5?w=800&q=80';

              return GestureDetector(
                onTap: () {
                  if (video.playbackUrl != null) {
                    _openWorkout(video);
                  }
                },
                child: Container(
                  width: 240 * scale,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16 * scale),
                    color: AppColors.surface,
                    image: DecorationImage(
                      image: NetworkImage(thumbnailUrl),
                      fit: BoxFit.cover,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.15),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16 * scale),
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.black.withOpacity(0.85),
                          Colors.transparent,
                        ],
                        stops: const [0.0, 0.6],
                      ),
                    ),
                    padding: EdgeInsets.all(14 * scale),
                    child: Align(
                      alignment: Alignment.bottomLeft,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Icon(
                            Icons.play_circle_fill_rounded,
                            color: AppColors.primary,
                            size: 26 * scale,
                          ),
                          SizedBox(width: 10 * scale),
                          Expanded(
                            child: Text(
                              video.title,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 13.5 * scale,
                                fontWeight: FontWeight.w700,
                                height: 1.2,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ============================================================
  // APP BAR
  // ============================================================

  Widget _buildAppBar(double width) {
    final scale = _scale(width);
    final title = _controller.hubData.value?.category?.title ?? 'Workout';

    return Row(
      children: [
        _buildIconButton(
          icon: Icons.arrow_back_rounded,
          onTap: _goBack,
          size: 42 * scale,
        ),
        SizedBox(width: 14 * scale),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 21 * scale,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // GREETING
  // ============================================================

  Widget _buildGreeting(double width) {
    final scale = _scale(width);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Move with purpose',
          style: TextStyle(
            color: AppColors.primary,
            fontSize: 24 * scale,
            fontWeight: FontWeight.w700,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 7),
        Text(
          _controller.hubData.value?.category?.description ??
              'A little movement today can make a big difference.',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 13.5 * scale,
            height: 1.45,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // SECTION TITLE
  // ============================================================

  Widget _buildSectionTitle({
    required String title,
    required String subtitle,
    required double width,
  }) {
    final scale = _scale(width);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 17 * scale,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 11.5 * scale,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // CATEGORIES
  // ============================================================

  Widget _buildCategories(double width) {
    final scale = _scale(width);

    return Obx(() {
      final subcategories = _controller.hubData.value?.subcategories ?? [];
      final selectedId = _controller.selectedSubcategoryId.value;

      return SizedBox(
        height: 105 * scale,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          itemCount: subcategories.length + 1,
          separatorBuilder: (_, __) => SizedBox(width: 10 * scale),
          itemBuilder: (context, index) {
            final isAll = index == 0;
            final sub = isAll ? null : subcategories[index - 1];
            final selected = isAll ? selectedId == null : selectedId == sub?.id;
            final title = isAll ? 'All' : sub!.name;
            final icon = isAll
                ? Icons.apps_rounded
                : _getSubcategoryIcon(title);

            return Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(12 * scale),
                onTap: () => _selectCategoryAndScroll(isAll ? null : sub?.id),
                child: Ink(
                  width: 82 * scale,
                  padding: EdgeInsets.symmetric(
                    horizontal: 7 * scale,
                    vertical: 9 * scale,
                  ),
                  decoration: BoxDecoration(
                    color: selected
                        ? AppColors.primary.withOpacity(0.13)
                        : AppColors.surface,
                    borderRadius: BorderRadius.circular(12 * scale),
                    border: Border.all(
                      color: selected
                          ? AppColors.primary
                          : AppColors.primary.withOpacity(0.18),
                      width: selected ? 1.2 : 1,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(icon, color: AppColors.primary, size: 23 * scale),
                      SizedBox(height: 7 * scale),
                      Text(
                        title,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: selected
                              ? AppColors.primary
                              : AppColors.textSecondary,
                          fontSize: 9.5 * scale,
                          fontWeight: selected
                              ? FontWeight.w600
                              : FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      );
    });
  }

  // ============================================================
  // SUGGESTED VIDEOS
  // ============================================================

  Widget _buildSuggestedVideoList(double width) {
    final scale = _scale(width);
    final videos = _controller.suggestedVideoItems;

    if (videos.isEmpty) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: 20 * scale),
        child: Center(
          child: Column(
            children: [
              Container(
                width: 52 * scale,
                height: 52 * scale,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.recommend_rounded,
                  color: AppColors.primary,
                  size: 25 * scale,
                ),
              ),
              SizedBox(height: 10 * scale),
              Text(
                'No recommendations available right now.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13 * scale,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: List.generate(videos.length, (index) {
        final video = videos[index];

        return Padding(
          padding: EdgeInsets.only(
            bottom: index == videos.length - 1 ? 0 : 11 * scale,
          ),
          child: _buildSuggestedVideoCard(video: video, width: width),
        );
      }),
    );
  }

  // ============================================================
  // SUGGESTED VIDEO CARD
  // ============================================================

  Widget _buildSuggestedVideoCard({
    required SuggestedVideoItem video,
    required double width,
  }) {
    final scale = _scale(width);
    final hasPlaybackUrl =
        video.playbackUrl != null && video.playbackUrl!.trim().isNotEmpty;
    final hasThumbnail =
        video.thumbnailUrl != null && video.thumbnailUrl!.trim().isNotEmpty;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: hasPlaybackUrl ? () => _openSuggestedVideo(video) : null,
        borderRadius: BorderRadius.circular(13 * scale),
        child: Container(
          padding: EdgeInsets.all(12 * scale),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(13 * scale),
            border: Border.all(color: AppColors.primary.withOpacity(0.16)),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(11 * scale),
                child: SizedBox(
                  width: 54 * scale,
                  height: 54 * scale,
                  child: hasThumbnail
                      ? Image.network(
                          video.thumbnailUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) {
                            return _fallbackVideoIcon(scale);
                          },
                        )
                      : _fallbackVideoIcon(scale),
                ),
              ),
              SizedBox(width: 12 * scale),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      video.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 13.5 * scale,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 4 * scale),
                    Text(
                      video.categoryTitle.isNotEmpty
                          ? video.categoryTitle
                          : 'Recommended for you',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 10.5 * scale,
                        height: 1.25,
                      ),
                    ),
                    SizedBox(height: 6 * scale),
                    Row(
                      children: [
                        if (video.durationText.trim().isNotEmpty)
                          Text(
                            video.durationText,
                            style: TextStyle(
                              color: AppColors.primary,
                              fontSize: 10 * scale,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        if (video.durationText.trim().isNotEmpty &&
                            video.level.trim().isNotEmpty)
                          SizedBox(width: 8 * scale),
                        if (video.level.trim().isNotEmpty)
                          Text(
                            video.level,
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 10 * scale,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8 * scale),
              Container(
                width: 35 * scale,
                height: 35 * scale,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.play_arrow_rounded,
                  color: Colors.black,
                  size: 20 * scale,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _fallbackVideoIcon(double scale) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.10),
        borderRadius: BorderRadius.circular(11 * scale),
      ),
      child: Icon(
        Icons.fitness_center_rounded,
        color: AppColors.primary,
        size: 25 * scale,
      ),
    );
  }

  // ============================================================
  // SESSION LIST
  // ============================================================

  Widget _buildSessionList(double width) {
    final scale = _scale(width);

    return Obx(() {
      final sessions = _controller.filteredContents;

      if (sessions.isEmpty) {
        return Padding(
          padding: EdgeInsets.symmetric(vertical: 20 * scale),
          child: Center(
            child: Text(
              'No sessions found for this category.',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13 * scale,
              ),
            ),
          ),
        );
      }

      return Column(
        children: List.generate(sessions.length, (index) {
          final session = sessions[index];

          return Padding(
            padding: EdgeInsets.only(
              bottom: index == sessions.length - 1 ? 0 : 11 * scale,
            ),
            child: _buildSessionCard(item: session, width: width),
          );
        }),
      );
    });
  }

  // ============================================================
  // SESSION CARD
  // ============================================================

  Widget _buildSessionCard({required ContentItem item, required double width}) {
    final scale = _scale(width);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _openWorkout(item),
        borderRadius: BorderRadius.circular(13 * scale),
        child: Container(
          padding: EdgeInsets.all(12 * scale),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(13 * scale),
            border: Border.all(color: AppColors.primary.withOpacity(0.16)),
          ),
          child: Row(
            children: [
              Container(
                width: 54 * scale,
                height: 54 * scale,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(11 * scale),
                ),
                child: Icon(
                  item.contentType == 'video'
                      ? Icons.videocam_rounded
                      : Icons.fitness_center_rounded,
                  color: AppColors.primary,
                  size: 25 * scale,
                ),
              ),
              SizedBox(width: 12 * scale),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 13.5 * scale,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 4 * scale),
                    Text(
                      item.description ?? 'A quick full-body workout session',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 10.5 * scale,
                        height: 1.25,
                      ),
                    ),
                    SizedBox(height: 6 * scale),
                    Row(
                      children: [
                        Text(
                          item.durationText,
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 10 * scale,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (item.level.trim().isNotEmpty) ...[
                          SizedBox(width: 8 * scale),
                          Text(
                            item.level,
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 10 * scale,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8 * scale),
              Container(
                width: 35 * scale,
                height: 35 * scale,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.play_arrow_rounded,
                  color: Colors.black,
                  size: 20 * scale,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // AI RECOMMENDATION
  // ============================================================

  Widget _buildAIRecommendation(double width) {
    final scale = _scale(width);
    final rec = _controller.hubData.value?.rheaRecommendation;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(17 * scale),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.07),
        borderRadius: BorderRadius.circular(15 * scale),
        border: Border.all(color: AppColors.primary.withOpacity(0.22)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38 * scale,
            height: 38 * scale,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(10 * scale),
            ),
            child: Icon(
              Icons.auto_awesome_rounded,
              color: Colors.black,
              size: 19 * scale,
            ),
          ),
          SizedBox(width: 11 * scale),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  rec?.title ?? 'RheaAI Recommendation',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 11 * scale,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 6 * scale),
                Text(
                  rec?.message ??
                      'A short full-body workout can help you stay active and energized.',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11 * scale,
                    height: 1.4,
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
  // ICON BUTTON
  // ============================================================

  Widget _buildIconButton({
    required IconData icon,
    required VoidCallback onTap,
    required double size,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(size / 2),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: AppColors.surface,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.primary.withOpacity(0.16)),
          ),
          child: Icon(icon, color: AppColors.textPrimary, size: size * 0.46),
        ),
      ),
    );
  }

  // ============================================================
  // RESPONSIVE PADDING
  // ============================================================

  double _horizontalPadding(double width) {
    if (width <= 340) return 16;
    if (width <= 380) return 18;
    if (width <= 430) return 20;
    if (width <= 600) return 24;

    return 32;
  }

  // ============================================================
  // RESPONSIVE SCALE
  // ============================================================

  double _scale(double width) => (width / 390).clamp(0.88, 1.12);
}

// ================================================================
// IN-APP YOUTUBE PLAYER SCREEN
// ================================================================

class InAppYoutubePlayerScreen extends StatefulWidget {
  final String videoId;
  final String title;

  const InAppYoutubePlayerScreen({
    super.key,
    required this.videoId,
    required this.title,
  });

  @override
  State<InAppYoutubePlayerScreen> createState() =>
      _InAppYoutubePlayerScreenState();
}

class _InAppYoutubePlayerScreenState extends State<InAppYoutubePlayerScreen> {
  YoutubePlayerController? _controller;

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    _controller = YoutubePlayerController(
      initialVideoId: widget.videoId,
      flags: const YoutubePlayerFlags(autoPlay: true, mute: false),
    );
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _controller?.dispose();
    _controller = null;

    super.dispose();
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final controller = _controller;

    if (controller == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    return YoutubePlayerBuilder(
      player: YoutubePlayer(
        controller: controller,
        showVideoProgressIndicator: true,
        progressIndicatorColor: AppColors.primary,
      ),
      builder: (context, player) {
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: AppColors.surface,
            elevation: 0,
            title: Text(
              widget.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            iconTheme: const IconThemeData(color: AppColors.primary),
          ),
          body: Center(child: player),
        );
      },
    );
  }
}
