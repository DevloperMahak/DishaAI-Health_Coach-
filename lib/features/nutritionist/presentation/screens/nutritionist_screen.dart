import 'package:disha_ai/features/nutritionist/widgets/nutritionist_card.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../app/theme/app_colors.dart';

class NutritionistListScreen extends StatefulWidget {
  const NutritionistListScreen({super.key});

  @override
  State<NutritionistListScreen> createState() => _NutritionistListScreenState();
}

class _NutritionistListScreenState extends State<NutritionistListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'All';

  final List<Map<String, dynamic>> _nutritionists = [
    {
      'id': '1',
      'name': 'Dr. Ananya Sharma',
      'specialty': 'Clinical Nutrition & Diabetes',
      'experience': '8+ Years Exp',
      'rating': 4.9,
      'reviews': 124,
      'fee': '₹800 / session',
      'image': 'assets/images/Profile.png',
      'category': 'Clinical',
      'isAvailable': true,
    },
    {
      'id': '2',
      'name': 'Rahul Verma',
      'specialty': 'Sports Dietetics & Muscle Building',
      'experience': '6+ Years Exp',
      'rating': 4.8,
      'reviews': 98,
      'fee': '₹650 / session',
      'image': 'assets/images/Profile.png',
      'category': 'Sports',
      'isAvailable': true,
    },
    {
      'id': '3',
      'name': 'Priya Nair',
      'specialty': 'Weight Management & PCOD',
      'experience': '7+ Years Exp',
      'rating': 4.9,
      'reviews': 156,
      'fee': '₹750 / session',
      'image': 'assets/images/Profile.png',
      'category': 'Weight Loss',
      'isAvailable': false,
    },
    {
      'id': '4',
      'name': 'Dr. Vikram Malhotra',
      'specialty': 'Holistic Wellness & Gut Health',
      'experience': '10+ Years Exp',
      'rating': 5.0,
      'reviews': 210,
      'fee': '₹1,000 / session',
      'image': 'assets/images/Profile.png',
      'category': 'Holistic',
      'isAvailable': true,
    },
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _getFilteredList() {
    final query = _searchController.text.trim().toLowerCase();
    return _nutritionists.where((item) {
      final name = item['name'].toString().toLowerCase();
      final specialty = item['specialty'].toString().toLowerCase();
      final cat = item['category'].toString();

      final matchesQuery = name.contains(query) || specialty.contains(query);
      final matchesCategory =
          _selectedCategory == 'All' || cat == _selectedCategory;

      return matchesQuery && matchesCategory;
    }).toList();
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
        title: const Text(
          "Expert Nutritionists",
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
            final isTablet = width >= 700;
            final horizontalPadding = isTablet ? width * 0.12 : 20.0;
            final filteredList = _getFilteredList();

            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
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
                      // Search Bar
                      _buildSearchBar(),
                      const SizedBox(height: 20),

                      // Category Filters
                      _buildCategoryChips(),
                      const SizedBox(height: 24),

                      // Section Heading
                      const Text(
                        "Available Specialists",
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Safe List / Grid Implementation
                      filteredList.isEmpty
                          ? _buildEmptyState()
                          : isTablet
                          ? _buildTabletGrid(filteredList)
                          : _buildMobileList(filteredList),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withOpacity(.2)),
      ),
      child: TextField(
        controller: _searchController,
        style: const TextStyle(color: AppColors.textPrimary),
        decoration: const InputDecoration(
          hintText: "Search by name or specialty...",
          hintStyle: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          prefixIcon: Icon(Icons.search_rounded, color: AppColors.primary),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        onChanged: (value) {
          setState(() {});
        },
      ),
    );
  }

  Widget _buildCategoryChips() {
    final categories = ['All', 'Clinical', 'Sports', 'Weight Loss', 'Holistic'];

    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final cat = categories[index];
          final isSelected = _selectedCategory == cat;

          return ChoiceChip(
            label: Text(cat),
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
              setState(() {
                _selectedCategory = cat;
              });
            },
          );
        },
      ),
    );
  }

  Widget _buildMobileList(List<Map<String, dynamic>> list) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: list.length,
      separatorBuilder: (_, __) => const SizedBox(height: 14),
      itemBuilder: (context, index) {
        return NutritionistCard(
          data: list[index],
        ); // 💡 Using separate card widget
      },
    );
  }

  Widget _buildTabletGrid(List<Map<String, dynamic>> list) {
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
        return NutritionistCard(
          data: list[index],
        ); // 💡 Using separate card widget
      },
    );
  }

  Widget _buildEmptyState() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 60),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 48,
              color: AppColors.textSecondary,
            ),
            SizedBox(height: 12),
            Text(
              "No nutritionists found",
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            SizedBox(height: 4),
            Text(
              "Try searching with a different keyword or category.",
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
