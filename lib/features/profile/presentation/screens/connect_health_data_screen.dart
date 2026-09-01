import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/theme/app_colors.dart';

class ConnectHealthDataScreen extends StatefulWidget {
  const ConnectHealthDataScreen({super.key, this.onContinue, this.onSkip});

  /// Called when user taps "Connect Health Data"
  final VoidCallback? onContinue;

  /// Called when user taps "Maybe Later"
  final VoidCallback? onSkip;

  @override
  State<ConnectHealthDataScreen> createState() =>
      _ConnectHealthDataScreenState();
}

class _ConnectHealthDataScreenState extends State<ConnectHealthDataScreen> {
  // ------------------------------------------------------------
  // Health permissions
  // ------------------------------------------------------------

  bool stepsEnabled = true;
  bool sleepEnabled = true;
  bool heartRateEnabled = false;
  bool caloriesEnabled = true;
  bool weightEnabled = false;

  // ------------------------------------------------------------
  // Responsive helpers
  // ------------------------------------------------------------

  double _scale(double width) {
    return (width / 390).clamp(0.88, 1.15);
  }

  double _horizontalPadding(double width) {
    if (width < 340) return 18;
    if (width < 390) return 22;
    if (width < 600) return 24;
    if (width < 900) return 40;
    return 60;
  }

  // ------------------------------------------------------------
  // Build
  // ------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,

      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final scale = _scale(width);
            final horizontalPadding = _horizontalPadding(width);

            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 620),
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      horizontalPadding,
                      28 * scale,
                      horizontalPadding,
                      24 * scale,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ------------------------------------------------
                        // HEADER
                        // ------------------------------------------------
                        _buildHeader(scale: scale),

                        SizedBox(height: 28 * scale),

                        // ------------------------------------------------
                        // HEALTH DATA LIST
                        // ------------------------------------------------
                        _buildHealthDataList(scale: scale, width: width),

                        SizedBox(height: 32 * scale),

                        // ------------------------------------------------
                        // CONNECT BUTTON
                        // ------------------------------------------------
                        _buildConnectButton(scale: scale, width: width),

                        SizedBox(height: 16 * scale),

                        // ------------------------------------------------
                        // MAYBE LATER
                        // ------------------------------------------------
                        _buildMaybeLaterButton(scale: scale),

                        SizedBox(height: 12 * scale),
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

  // ==============================================================
  // HEADER
  // ==============================================================

  Widget _buildHeader({required double scale}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Connect your\nhealth data',
          style: TextStyle(
            color: AppColors.primary,
            fontSize: (30 * scale).clamp(25.0, 34.0),
            height: 1.08,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),

        SizedBox(height: 14 * scale),

        Text(
          'Allow JiyaAI to access your health\ndata for better insights.',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: (13 * scale).clamp(12.0, 15.0),
            height: 1.5,
          ),
        ),
      ],
    );
  }

  // ==============================================================
  // HEALTH DATA LIST
  // ==============================================================

  Widget _buildHealthDataList({required double scale, required double width}) {
    return Column(
      children: [
        _HealthDataItem(
          icon: Icons.directions_run_rounded,
          title: 'Steps & Activity',
          subtitle: 'Track your daily movement',
          enabled: stepsEnabled,
          scale: scale,
          onChanged: (value) {
            setState(() {
              stepsEnabled = value;
            });
          },
        ),

        SizedBox(height: 8 * scale),

        _HealthDataItem(
          icon: Icons.nightlight_round,
          title: 'Sleep',
          subtitle: 'Track your sleep quality',
          enabled: sleepEnabled,
          scale: scale,
          onChanged: (value) {
            setState(() {
              sleepEnabled = value;
            });
          },
        ),

        SizedBox(height: 8 * scale),

        _HealthDataItem(
          icon: Icons.favorite_rounded,
          title: 'Heart Rate',
          subtitle: 'Track your heart rate',
          enabled: heartRateEnabled,
          scale: scale,
          onChanged: (value) {
            setState(() {
              heartRateEnabled = value;
            });
          },
        ),

        SizedBox(height: 8 * scale),

        _HealthDataItem(
          icon: Icons.local_fire_department_rounded,
          title: 'Calories',
          subtitle: 'Track calories burned',
          enabled: caloriesEnabled,
          scale: scale,
          onChanged: (value) {
            setState(() {
              caloriesEnabled = value;
            });
          },
        ),

        SizedBox(height: 8 * scale),

        _HealthDataItem(
          icon: Icons.monitor_weight_rounded,
          title: 'Weight',
          subtitle: 'Track your weight',
          enabled: weightEnabled,
          scale: scale,
          onChanged: (value) {
            setState(() {
              weightEnabled = value;
            });
          },
        ),
      ],
    );
  }

  // ==============================================================
  // CONNECT BUTTON
  // ==============================================================

  Widget _buildConnectButton({required double scale, required double width}) {
    return SizedBox(
      width: double.infinity,
      height: (54 * scale).clamp(50.0, 60.0),
      child: ElevatedButton(
        onPressed:
            widget.onContinue ??
            () {
              _handleConnect();
            },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.black,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12 * scale),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Connect Health Data',
              style: TextStyle(
                fontSize: (14 * scale).clamp(13.0, 16.0),
                fontWeight: FontWeight.w700,
              ),
            ),

            SizedBox(width: 10 * scale),

            Icon(Icons.arrow_forward_rounded, size: 18 * scale),
          ],
        ),
      ),
    );
  }

  // ==============================================================
  // MAYBE LATER
  // ==============================================================

  Widget _buildMaybeLaterButton({required double scale}) {
    return SizedBox(
      width: double.infinity,
      height: (48 * scale).clamp(44.0, 54.0),
      child: TextButton(
        onPressed:
            widget.onSkip ??
            () {
              _handleSkip();
            },
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12 * scale),
          ),
        ),
        child: Text(
          'Maybe Later',
          style: TextStyle(
            color: AppColors.primary,
            fontSize: (14 * scale).clamp(13.0, 16.0),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  // ==============================================================
  // CONNECT HANDLER
  // ==============================================================

  void _handleConnect() {
    // ------------------------------------------------------------
    // Later integrate Health Connect / Apple Health here.
    // ------------------------------------------------------------

    final selected = <String>[
      if (stepsEnabled) 'Steps & Activity',
      if (sleepEnabled) 'Sleep',
      if (heartRateEnabled) 'Heart Rate',
      if (caloriesEnabled) 'Calories',
      if (weightEnabled) 'Weight',
    ];

    debugPrint('Selected health permissions: $selected');

    if (widget.onContinue != null) {
      widget.onContinue!();
      return;
    }

    Get.snackbar(
      'Health Data',
      selected.isEmpty
          ? 'Please select at least one health data type.'
          : 'Health data connection will be started.',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: AppColors.surface,
      colorText: AppColors.textPrimary,
      margin: const EdgeInsets.all(16),
      borderRadius: 14,
      duration: const Duration(seconds: 2),
    );
  }

  // ==============================================================
  // SKIP HANDLER
  // ==============================================================

  void _handleSkip() {
    if (widget.onSkip != null) {
      widget.onSkip!();
      return;
    }

    Get.back();
  }
}

// ==================================================================
// HEALTH DATA ITEM
// ==================================================================

class _HealthDataItem extends StatelessWidget {
  const _HealthDataItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.enabled,
    required this.onChanged,
    required this.scale,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool enabled;
  final ValueChanged<bool> onChanged;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final horizontalPadding = (12 * scale).clamp(10.0, 15.0);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: (9 * scale).clamp(8.0, 12.0),
      ),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(9 * scale),
        border: Border.all(color: AppColors.primary.withOpacity(.75), width: 1),
      ),
      child: Row(
        children: [
          // --------------------------------------------------------
          // ICON
          // --------------------------------------------------------
          Container(
            width: (40 * scale).clamp(36.0, 46.0),
            height: (40 * scale).clamp(36.0, 46.0),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(6 * scale),
            ),
            child: Icon(
              icon,
              color: AppColors.primary,
              size: (21 * scale).clamp(19.0, 24.0),
            ),
          ),

          SizedBox(width: 12 * scale),

          // --------------------------------------------------------
          // TEXT
          // --------------------------------------------------------
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: (11.5 * scale).clamp(10.5, 13.0),
                    fontWeight: FontWeight.w700,
                  ),
                ),

                SizedBox(height: 2 * scale),

                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: (10.5 * scale).clamp(9.5, 12.0),
                    height: 1.15,
                  ),
                ),
              ],
            ),
          ),

          SizedBox(width: 8 * scale),

          // --------------------------------------------------------
          // SWITCH
          // --------------------------------------------------------
          Transform.scale(
            scale: (0.82 * scale).clamp(.76, .94),
            alignment: Alignment.centerRight,
            child: Switch.adaptive(
              value: enabled,
              onChanged: onChanged,
              activeColor: Colors.white,
              activeTrackColor: AppColors.primary,
              inactiveThumbColor: Colors.white,
              inactiveTrackColor: Colors.white.withOpacity(.75),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ],
      ),
    );
  }
}
