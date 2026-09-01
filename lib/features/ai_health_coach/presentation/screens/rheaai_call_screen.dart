import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/theme/app_colors.dart';

class RheaCheckInCallScreen extends StatefulWidget {
  const RheaCheckInCallScreen({super.key, this.onEndCall});

  final VoidCallback? onEndCall;

  @override
  State<RheaCheckInCallScreen> createState() => _RheaCheckInCallScreenState();
}

class _RheaCheckInCallScreenState extends State<RheaCheckInCallScreen>
    with SingleTickerProviderStateMixin {
  // ==============================================================
  // STATE
  // ==============================================================

  bool isMuted = false;
  bool isSpeakerOn = true;

  bool isRheaSpeaking = true;

  Duration callDuration = Duration.zero;

  late AnimationController _pulseController;

  // ==============================================================
  // INIT
  // ==============================================================

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _startTimer();
  }

  // ==============================================================
  // DISPOSE
  // ==============================================================

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  // ==============================================================
  // TIMER
  // ==============================================================

  void _startTimer() {
    Stream.periodic(const Duration(seconds: 1)).listen((_) {
      if (!mounted) return;

      setState(() {
        callDuration += const Duration(seconds: 1);
      });
    });
  }

  // ==============================================================
  // BUILD
  // ==============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final isDesktop = width >= 700;

            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 850),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isDesktop ? 60 : 22,
                    vertical: 20,
                  ),
                  child: Column(
                    children: [
                      _buildHeader(isDesktop),

                      const Spacer(),

                      _buildRheaAvatar(isDesktop),

                      const SizedBox(height: 28),

                      _buildStatus(),

                      const SizedBox(height: 12),

                      _buildDuration(),

                      const SizedBox(height: 35),

                      _buildTranscript(),

                      const Spacer(),

                      _buildCallControls(isDesktop),

                      const SizedBox(height: 18),

                      _buildPrivacyNote(),
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

  // ==============================================================
  // HEADER
  // ==============================================================

  Widget _buildHeader(bool isDesktop) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(13),
          ),
          child: IconButton(
            onPressed: _confirmEndCall,
            icon: const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: AppColors.textPrimary,
            ),
          ),
        ),

        const SizedBox(width: 13),

        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Rhea AI',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Daily Check-in',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
              ),
            ],
          ),
        ),

        Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(.09),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              const Text(
                'LIVE',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  letterSpacing: .8,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ==============================================================
  // RHEA AVATAR
  // ==============================================================

  Widget _buildRheaAvatar(bool isDesktop) {
    final size = isDesktop ? 245.0 : 205.0;

    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final pulse = _pulseController.value;

        return Stack(
          alignment: Alignment.center,
          children: [
            // Outer glow
            Container(
              width: size + (25 * pulse),
              height: size + (25 * pulse),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(.08 + (.06 * pulse)),
                    blurRadius: 45 + (15 * pulse),
                    spreadRadius: 5,
                  ),
                ],
              ),
            ),

            // Outer ring
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.primary.withOpacity(.22),
                  width: 1.5,
                ),
              ),
            ),

            // Inner ring
            Container(
              width: size * .86,
              height: size * .86,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withOpacity(.06),
                border: Border.all(color: AppColors.primary.withOpacity(.12)),
              ),
            ),

            // Illustration
            ClipOval(
              child: Image.asset(
                'assets/images/rhea_ai_avatar.png',
                width: size * .72,
                height: size * .72,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: size * .72,
                    height: size * .72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.surface,
                    ),
                    child: Icon(
                      Icons.auto_awesome_rounded,
                      color: AppColors.primary,
                      size: size * .25,
                    ),
                  );
                },
              ),
            ),

            // Speaking indicator
            if (isRheaSpeaking)
              Positioned(
                bottom: size * .03,
                child: _SpeakingIndicator(pulse: pulse),
              ),
          ],
        );
      },
    );
  }

  // ==============================================================
  // STATUS
  // ==============================================================

  Widget _buildStatus() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      child: Text(
        isRheaSpeaking ? 'Rhea is speaking...' : 'Rhea is listening...',
        key: ValueKey(isRheaSpeaking),
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 19,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  // ==============================================================
  // DURATION
  // ==============================================================

  Widget _buildDuration() {
    final minutes = callDuration.inMinutes.toString().padLeft(2, '0');

    final seconds = (callDuration.inSeconds % 60).toString().padLeft(2, '0');

    return Text(
      '$minutes:$seconds',
      style: TextStyle(
        color: AppColors.textSecondary,
        fontSize: 13,
        letterSpacing: 1.2,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  // ==============================================================
  // TRANSCRIPT
  // ==============================================================

  Widget _buildTranscript() {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 620),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
      decoration: BoxDecoration(
        color: AppColors.surface.withOpacity(.72),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.primary.withOpacity(.08)),
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: Row(
          key: ValueKey(isRheaSpeaking),
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(.10),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isRheaSpeaking ? Icons.auto_awesome_rounded : Icons.mic_rounded,
                color: AppColors.primary,
                size: 14,
              ),
            ),

            const SizedBox(width: 11),

            Expanded(
              child: Text(
                isRheaSpeaking
                    ? '"How has your day been so far? '
                          'Take your time — I\'m here to listen."'
                    : 'Listening to you...',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  height: 1.45,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==============================================================
  // CALL CONTROLS
  // ==============================================================

  Widget _buildCallControls(bool isDesktop) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _CallControlButton(
          icon: isMuted ? Icons.mic_off_rounded : Icons.mic_rounded,
          label: isMuted ? 'Unmute' : 'Mute',
          active: isMuted,
          onTap: () {
            setState(() {
              isMuted = !isMuted;
            });
          },
        ),

        SizedBox(width: isDesktop ? 35 : 22),

        // END CALL
        GestureDetector(
          onTap: _confirmEndCall,
          child: Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              color: Colors.redAccent.withOpacity(.92),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.redAccent.withOpacity(.20),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Icon(
              Icons.call_end_rounded,
              color: Colors.white,
              size: 29,
            ),
          ),
        ),

        SizedBox(width: isDesktop ? 35 : 22),

        _CallControlButton(
          icon: isSpeakerOn
              ? Icons.volume_up_rounded
              : Icons.volume_off_rounded,
          label: isSpeakerOn ? 'Speaker' : 'Muted',
          active: isSpeakerOn,
          onTap: () {
            setState(() {
              isSpeakerOn = !isSpeakerOn;
            });
          },
        ),
      ],
    );
  }

  // ==============================================================
  // PRIVACY
  // ==============================================================

  Widget _buildPrivacyNote() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.lock_outline_rounded,
          size: 13,
          color: AppColors.textSecondary.withOpacity(.65),
        ),
        const SizedBox(width: 6),
        Text(
          'Private & secure conversation',
          style: TextStyle(
            color: AppColors.textSecondary.withOpacity(.65),
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  // ==============================================================
  // END CALL
  // ==============================================================

  void _confirmEndCall() {
    Get.dialog(
      Dialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: Colors.redAccent.withOpacity(.10),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.call_end_rounded,
                  color: Colors.redAccent,
                  size: 25,
                ),
              ),

              const SizedBox(height: 16),

              const Text(
                'End check-in?',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                'Are you sure you want to end your '
                'conversation with Rhea AI?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  height: 1.45,
                ),
              ),

              const SizedBox(height: 22),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: Get.back,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textPrimary,
                        side: BorderSide(
                          color: AppColors.textSecondary.withOpacity(.20),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Continue'),
                    ),
                  ),

                  const SizedBox(width: 10),

                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Get.back();

                        if (widget.onEndCall != null) {
                          widget.onEndCall!();
                        } else {
                          Get.back();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'End Call',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==================================================================
// SPEAKING INDICATOR
// ==================================================================

class _SpeakingIndicator extends StatelessWidget {
  const _SpeakingIndicator({required this.pulse});

  final double pulse;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(.25),
            blurRadius: 12 + (pulse * 8),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _bar(4 + (pulse * 5)),
          const SizedBox(width: 3),
          _bar(8 + (pulse * 7)),
          const SizedBox(width: 3),
          _bar(5 + (pulse * 6)),
          const SizedBox(width: 7),
          const Text(
            'Speaking',
            style: TextStyle(
              color: Colors.black,
              fontSize: 9,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _bar(double height) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: 3,
      height: height,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(.75),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

// ==================================================================
// CALL CONTROL
// ==================================================================

class _CallControlButton extends StatelessWidget {
  const _CallControlButton({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: active
                  ? AppColors.primary.withOpacity(.13)
                  : AppColors.surface,
              shape: BoxShape.circle,
              border: Border.all(
                color: active
                    ? AppColors.primary.withOpacity(.25)
                    : Colors.white.withOpacity(.06),
              ),
            ),
            child: Icon(
              icon,
              color: active ? AppColors.primary : AppColors.textPrimary,
              size: 22,
            ),
          ),
        ),

        const SizedBox(height: 7),

        Text(
          label,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 9),
        ),
      ],
    );
  }
}
