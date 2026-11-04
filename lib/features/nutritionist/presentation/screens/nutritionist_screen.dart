import 'package:disha_ai/features/nutritionist/presentation/controllers/expert_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:disha_ai/app/routes/app_routes.dart';
import 'package:disha_ai/features/dashboard/presentation/widgets/dashboard_bottom_nav_bar.dart';

import '../../../../app/theme/app_colors.dart';
import '../../widgets/nutritionist_card.dart';

class NutritionistListScreen extends StatefulWidget {
  const NutritionistListScreen({super.key});

  @override
  State<NutritionistListScreen> createState() => _NutritionistListScreenState();
}

class _NutritionistListScreenState extends State<NutritionistListScreen> {
  late final ExpertController _expertController;

  final TextEditingController _searchController = TextEditingController();

  String _selectedCategory = 'All';

  static const int _nutritionistIndex = 4;
  bool _isNavigating = false;

  Future<void> _navigateTo(String route) async {
    if (_isNavigating) return;
    _isNavigating = true;
    try {
      await Get.toNamed<dynamic>(route);
    } catch (e, stackTrace) {
      debugPrint('❌ [Nutritionist Navigation] Error opening $route: $e');
      debugPrint('$stackTrace');
    } finally {
      _isNavigating = false;
    }
  }

  void _onBottomNavigationTap(int index) {
    switch (index) {
      case 0:
        _navigateTo(AppRoutes.dashboard);
        break;
      case 1:
        _navigateTo(AppRoutes.myPlan);
        break;
      case 2:
        _navigateTo(AppRoutes.progress);
        break;
      case 3:
        _navigateTo(AppRoutes.aiCoach);
        break;
      case 4:
        // Already viewing the Nutritionist screen.
        break;
      default:
        debugPrint('⚠️ [Nutritionist Bottom Nav] Invalid index: $index');
    }
  }

  @override
  void initState() {
    super.initState();

    // Reuse the existing ExpertController if it is already registered.
    // Otherwise create it once.
    if (Get.isRegistered<ExpertController>()) {
      _expertController = Get.find<ExpertController>();
    } else {
      _expertController = Get.put(ExpertController());
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      bottomNavigationBar: DashboardBottomNavBar(
        currentIndex: _nutritionistIndex,
        onTap: _onBottomNavigationTap,
      ),
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
          'Expert Nutritionists',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final double width = constraints.maxWidth;
            final bool isTablet = width >= 700;
            final double horizontalPadding = isTablet ? width * 0.12 : 20.0;

            return RefreshIndicator(
              color: AppColors.primary,
              onRefresh: _handleRefresh,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                padding: EdgeInsets.symmetric(
                  horizontal: horizontalPadding,
                  vertical: 16,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 900),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // =====================================================
                        // SEARCH
                        // =====================================================
                        _buildSearchBar(),

                        const SizedBox(height: 20),

                        // =====================================================
                        // CATEGORY FILTERS
                        // =====================================================
                        _buildCategoryChips(),

                        const SizedBox(height: 24),

                        // =====================================================
                        // SECTION TITLE
                        // =====================================================
                        const Text(
                          'Available Specialists',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 14),

                        // =====================================================
                        // EXPERT API STATE
                        // =====================================================
                        Obx(() {
                          return _buildExpertContent(isTablet: isTablet);
                        }),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // ===========================================================================
  // REFRESH
  // ===========================================================================

  Future<void> _handleRefresh() async {
    await _expertController.fetchExperts();
  }

  // ===========================================================================
  // EXPERT CONTENT
  // ===========================================================================

  Widget _buildExpertContent({required bool isTablet}) {
    final bool isLoading = _expertController.isExpertsLoading.value;

    final experts = _expertController.expertsList;

    // Initial loading state.
    if (isLoading && experts.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 60),
        child: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    // Filter experts locally.
    final String query = _searchController.text.trim().toLowerCase();

    final List filteredList = experts.where((expert) {
      final String name = expert.name.toLowerCase();

      final String specialty = (expert.specialization ?? '').toLowerCase();

      final String designation = (expert.designation ?? '').toLowerCase();

      final bool matchesQuery =
          query.isEmpty ||
          name.contains(query) ||
          specialty.contains(query) ||
          designation.contains(query);

      final bool matchesCategory =
          _selectedCategory == 'All' ||
          specialty.contains(_selectedCategory.toLowerCase()) ||
          designation.contains(_selectedCategory.toLowerCase());

      return matchesQuery && matchesCategory;
    }).toList();

    // No matching experts.
    if (filteredList.isEmpty) {
      return _buildEmptyState(hasExperts: experts.isNotEmpty);
    }

    // Tablet layout.
    if (isTablet) {
      return _buildTabletGrid(filteredList);
    }

    // Mobile layout.
    return _buildMobileList(filteredList);
  }

  // ===========================================================================
  // SEARCH BAR
  // ===========================================================================

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withOpacity(.2)),
      ),
      child: TextField(
        controller: _searchController,
        textInputAction: TextInputAction.search,
        style: const TextStyle(color: AppColors.textPrimary),
        decoration: const InputDecoration(
          hintText: 'Search by name or specialty...',
          hintStyle: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          prefixIcon: Icon(Icons.search_rounded, color: AppColors.primary),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        onChanged: (_) {
          setState(() {});
        },
      ),
    );
  }

  // ===========================================================================
  // CATEGORY CHIPS
  // ===========================================================================

  Widget _buildCategoryChips() {
    const List<String> categories = [
      'All',
      'Clinical Care',
      'Sports',
      'Weight',
      'Holistic',
    ];

    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final String category = categories[index];

          final bool isSelected = _selectedCategory == category;

          return ChoiceChip(
            label: Text(category),
            selected: isSelected,
            selectedColor: AppColors.primary,
            backgroundColor: AppColors.surface,
            labelStyle: TextStyle(
              color: isSelected ? Colors.black : AppColors.textPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
            side: BorderSide(
              color: isSelected
                  ? AppColors.primary
                  : AppColors.primary.withOpacity(.2),
            ),
            onSelected: (_) {
              if (_selectedCategory == category) {
                return;
              }

              setState(() {
                _selectedCategory = category;
              });
            },
          );
        },
      ),
    );
  }

  // ===========================================================================
  // MOBILE LIST
  // ===========================================================================

  Widget _buildMobileList(List list) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: list.length,
      separatorBuilder: (_, __) => const SizedBox(height: 14),
      itemBuilder: (context, index) {
        final expert = list[index];

        return NutritionistCard(expert: expert);
      },
    );
  }

  // ===========================================================================
  // TABLET GRID
  // ===========================================================================

  Widget _buildTabletGrid(List list) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.45,
      ),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final expert = list[index];

        return NutritionistCard(expert: expert);
      },
    );
  }

  // ===========================================================================
  // EMPTY STATE
  // ===========================================================================

  Widget _buildEmptyState({required bool hasExperts}) {
    final bool hasSearchOrFilter =
        _searchController.text.trim().isNotEmpty || _selectedCategory != 'All';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Center(
        child: Column(
          children: [
            Icon(
              hasSearchOrFilter
                  ? Icons.search_off_rounded
                  : Icons.people_outline_rounded,
              size: 48,
              color: AppColors.textSecondary,
            ),

            const SizedBox(height: 12),

            Text(
              hasSearchOrFilter
                  ? 'No nutritionists found'
                  : 'No specialists available',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),

            const SizedBox(height: 4),

            Text(
              hasSearchOrFilter
                  ? 'Try searching with a different keyword or category.'
                  : hasExperts
                  ? 'No specialists match the selected filters.'
                  : 'No nutritionists are currently available.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),

            // Show clear filters only when a filter/search is active.
            if (hasSearchOrFilter) ...[
              const SizedBox(height: 18),

              OutlinedButton.icon(
                onPressed: _clearFilters,
                icon: const Icon(Icons.clear_all_rounded, size: 18),
                label: const Text('Clear Filters'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: BorderSide(color: AppColors.primary.withOpacity(.35)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // CLEAR SEARCH + FILTER
  // ===========================================================================

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _selectedCategory = 'All';
    });
  }
}
