import 'package:disha_ai/features/workout/data/models/workout_session.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/theme/app_colors.dart';
import 'workout_player_screen.dart';

class WorkoutHomeScreen extends StatefulWidget {
  const WorkoutHomeScreen({super.key});

  @override
  State<WorkoutHomeScreen> createState() => _WorkoutHomeScreenState();
}

class _WorkoutHomeScreenState extends State<WorkoutHomeScreen>
    with SingleTickerProviderStateMixin {
  static const String _userName = 'Mahak';

  int _selectedCategory = 0;

  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  final List<_WorkoutCategory> _categories = const [
    _WorkoutCategory(title: 'Quick', icon: Icons.flash_on_rounded),
    _WorkoutCategory(title: 'Full Body', icon: Icons.accessibility_new_rounded),
    _WorkoutCategory(title: 'Strength', icon: Icons.fitness_center_rounded),
    _WorkoutCategory(title: 'Cardio', icon: Icons.directions_run_rounded),
    _WorkoutCategory(title: 'Stretch', icon: Icons.self_improvement_rounded),
    _WorkoutCategory(title: 'Morning', icon: Icons.wb_sunny_outlined),
  ];

  final List<WorkoutSession> _sessions = const [
    WorkoutSession(
      id: 'quick_10',
      title: '10-Minute Full Body',
      description:
          'A quick full-body workout to get your body moving and energized.',
      duration: '10 min',
      minutes: 10,
      level: 'Beginner',
      category: 'Quick',
      calories: 70,
      icon: Icons.accessibility_new_rounded,
    ),
    WorkoutSession(
      id: 'cardio_15',
      title: 'Quick Cardio Boost',
      description: 'Increase your heart rate with simple cardio movements.',
      duration: '15 min',
      minutes: 15,
      level: 'Beginner',
      category: 'Cardio',
      calories: 110,
      icon: Icons.directions_run_rounded,
    ),
    WorkoutSession(
      id: 'strength_20',
      title: 'Strength Basics',
      description: 'Build strength with simple bodyweight exercises.',
      duration: '20 min',
      minutes: 20,
      level: 'Intermediate',
      category: 'Strength',
      calories: 140,
      icon: Icons.fitness_center_rounded,
    ),
    WorkoutSession(
      id: 'stretch_10',
      title: 'Gentle Stretch',
      description:
          'Release tension and improve flexibility with gentle movements.',
      duration: '10 min',
      minutes: 10,
      level: 'Beginner',
      category: 'Stretch',
      calories: 45,
      icon: Icons.self_improvement_rounded,
    ),
  ];

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.04), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
        );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _openWorkout(WorkoutSession session) {
    Get.to(
      () => WorkoutPlayerScreen(session: session),
      transition: Transition.cupertino,
    );
  }

  void _goBack() {
    Get.back();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;

            if (width >= 700) {
              return _buildWideLayout(width);
            }

            return _buildPhoneLayout(width);
          },
        ),
      ),
    );
  }

  // ============================================================
  // PHONE
  // ============================================================

  Widget _buildPhoneLayout(double width) {
    final horizontalPadding = _horizontalPadding(width);

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
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

                  const SizedBox(height: 20),

                  _buildTodayWorkout(width),

                  const SizedBox(height: 28),

                  _buildSectionTitle(
                    title: 'Explore Workouts',
                    subtitle: 'Choose what your body needs today',
                    width: width,
                  ),

                  const SizedBox(height: 14),

                  _buildCategories(width),

                  const SizedBox(height: 28),

                  _buildSectionTitle(
                    title: 'Recommended For You',
                    subtitle: 'Personalized by RheaAI',
                    width: width,
                  ),

                  const SizedBox(height: 14),

                  _buildSessionList(width),

                  const SizedBox(height: 28),

                  _buildWorkoutProgress(width),

                  const SizedBox(height: 20),

                  _buildAIRecommendation(width),

                  const SizedBox(height: 20),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // TABLET / DESKTOP
  // ============================================================

  Widget _buildWideLayout(double width) {
    final horizontalPadding = width >= 1400
        ? 120.0
        : width >= 1100
        ? 80.0
        : 40.0;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
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

                    _buildTodayWorkout(width),

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
                              _buildSectionTitle(
                                title: 'Recommended For You',
                                subtitle: 'Personalized by RheaAI',
                                width: width,
                              ),
                              const SizedBox(height: 16),
                              _buildSessionList(width),
                            ],
                          ),
                        ),

                        const SizedBox(width: 24),

                        Expanded(
                          flex: 2,
                          child: Column(
                            children: [
                              _buildWorkoutProgress(width),
                              const SizedBox(height: 20),
                              _buildAIRecommendation(width),
                            ],
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
    );
  }

  // ============================================================
  // APP BAR
  // ============================================================

  Widget _buildAppBar(double width) {
    final scale = _scale(width);

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
            'Workout',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 21 * scale,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
            ),
          ),
        ),

        _buildIconButton(
          icon: Icons.history_rounded,
          onTap: () {
            Get.snackbar(
              'Workout History',
              'Your workout history will appear here.',
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: AppColors.surface,
              colorText: AppColors.textPrimary,
            );
          },
          size: 42 * scale,
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
          'Move with purpose, $_userName',
          style: TextStyle(
            color: AppColors.primary,
            fontSize: 24 * scale,
            fontWeight: FontWeight.w700,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 7),
        Text(
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
  // TODAY WORKOUT
  // ============================================================

  Widget _buildTodayWorkout(double width) {
    final scale = _scale(width);

    final session = _sessions.first;

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
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.07),
            blurRadius: 22,
            offset: const Offset(0, 8),
          ),
        ],
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
                      'TODAY\'S WORKOUT',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 10 * scale,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      session.title,
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
                  session.duration,
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
            session.description,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12.5 * scale,
              height: 1.45,
            ),
          ),

          SizedBox(height: 14 * scale),

          Row(
            children: [
              _buildMiniInfo(
                Icons.local_fire_department_outlined,
                '${session.calories} kcal',
                scale,
              ),

              SizedBox(width: 16 * scale),

              _buildMiniInfo(
                Icons.signal_cellular_alt_rounded,
                session.level,
                scale,
              ),
            ],
          ),

          SizedBox(height: 18 * scale),

          SizedBox(
            width: double.infinity,
            height: 46 * scale,
            child: ElevatedButton.icon(
              onPressed: () => _openWorkout(session),
              icon: Icon(Icons.play_arrow_rounded, size: 19 * scale),
              label: Text(
                'Start Workout',
                style: TextStyle(
                  fontSize: 13 * scale,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.black,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10 * scale),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniInfo(IconData icon, String text, double scale) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 15 * scale),
        SizedBox(width: 5 * scale),
        Text(
          text,
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 10.5 * scale,
            fontWeight: FontWeight.w500,
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

    return SizedBox(
      height: 92 * scale,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: _categories.length,
        separatorBuilder: (_, __) => SizedBox(width: 10 * scale),
        itemBuilder: (context, index) {
          final category = _categories[index];
          final selected = _selectedCategory == index;

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedCategory = index;
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
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
                  Icon(
                    category.icon,
                    color: AppColors.primary,
                    size: 23 * scale,
                  ),
                  SizedBox(height: 7 * scale),
                  Text(
                    category.title,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: selected
                          ? AppColors.primary
                          : AppColors.textSecondary,
                      fontSize: 9.5 * scale,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ============================================================
  // SESSION LIST
  // ============================================================

  Widget _buildSessionList(double width) {
    final scale = _scale(width);

    return Column(
      children: List.generate(_sessions.length, (index) {
        final session = _sessions[index];

        return Padding(
          padding: EdgeInsets.only(
            bottom: index == _sessions.length - 1 ? 0 : 11 * scale,
          ),
          child: _buildSessionCard(session: session, width: width),
        );
      }),
    );
  }

  Widget _buildSessionCard({
    required WorkoutSession session,
    required double width,
  }) {
    final scale = _scale(width);

    return GestureDetector(
      onTap: () => _openWorkout(session),
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
                session.icon,
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
                    session.title,
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
                    session.description,
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
                        session.duration,
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 10 * scale,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(width: 8 * scale),
                      Text(
                        '•',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 10 * scale,
                        ),
                      ),
                      SizedBox(width: 8 * scale),
                      Text(
                        session.level,
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
              decoration: BoxDecoration(
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
    );
  }

  // ============================================================
  // PROGRESS
  // ============================================================

  Widget _buildWorkoutProgress(double width) {
    final scale = _scale(width);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(17 * scale),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(15 * scale),
        border: Border.all(color: AppColors.primary.withOpacity(0.16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.insights_outlined,
                color: AppColors.primary,
                size: 19 * scale,
              ),
              SizedBox(width: 8 * scale),
              Text(
                'Your Progress',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14 * scale,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),

          SizedBox(height: 17 * scale),

          Row(
            children: [
              Expanded(child: _progressStat('12', 'Workouts', scale)),
              Expanded(child: _progressStat('96', 'Minutes', scale)),
              Expanded(child: _progressStat('5', 'Day Streak', scale)),
            ],
          ),

          SizedBox(height: 18 * scale),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Weekly goal',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 10.5 * scale,
                ),
              ),
              Text(
                '4 / 5 workouts',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 10.5 * scale,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),

          SizedBox(height: 8 * scale),

          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              value: 0.8,
              minHeight: 6 * scale,
              backgroundColor: AppColors.primary.withOpacity(0.10),
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _progressStat(String value, String label, double scale) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: TextStyle(
            color: AppColors.primary,
            fontSize: 18 * scale,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 9.5 * scale,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // AI RECOMMENDATION
  // ============================================================

  Widget _buildAIRecommendation(double width) {
    final scale = _scale(width);

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
                  'RheaAI Recommendation',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 11 * scale,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                SizedBox(height: 6 * scale),

                Text(
                  'You have some time today. A short full-body workout can help you stay active and energized.',
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
  // RESPONSIVE
  // ============================================================

  double _horizontalPadding(double width) {
    if (width <= 340) return 16;
    if (width <= 380) return 18;
    if (width <= 430) return 20;
    if (width <= 600) return 24;

    return 32;
  }

  double _scale(double width) {
    return (width / 390).clamp(0.88, 1.12);
  }
}

// ================================================================
// CATEGORY MODEL
// ================================================================

class _WorkoutCategory {
  final String title;
  final IconData icon;

  const _WorkoutCategory({required this.title, required this.icon});
}
