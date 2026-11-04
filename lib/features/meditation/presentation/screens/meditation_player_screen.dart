import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:audioplayers/audioplayers.dart'; // 💡 Audio Player package
import '../../data/models/meditation_session.dart';
import '../../../../app/theme/app_colors.dart';

class MeditationPlayerScreen extends StatefulWidget {
  final MeditationSession session;
  final String? audioUrl; // 💡 Added playback URL parameter from API

  const MeditationPlayerScreen({
    super.key,
    required this.session,
    this.audioUrl,
  });

  @override
  State<MeditationPlayerScreen> createState() => _MeditationPlayerScreenState();
}

class _MeditationPlayerScreenState extends State<MeditationPlayerScreen>
    with SingleTickerProviderStateMixin {
  // ============================================================
  // AUDIO PLAYER & STATE
  // ============================================================
  late final AudioPlayer _audioPlayer;
  bool _isPlaying = false;
  bool _isLoadingAudio = true;
  bool _backgroundSound = true;

  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  double _volume = 0.75;

  late final AnimationController _breathingController;

  @override
  void initState() {
    super.initState();

    _audioPlayer = AudioPlayer();

    _breathingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );
    _breathingController.repeat(reverse: true);

    _initAudioPlayer();
  }

  Future<void> _initAudioPlayer() async {
    try {
      // Listen to player state changes
      _audioPlayer.onPlayerStateChanged.listen((state) {
        if (mounted) {
          setState(() {
            _isPlaying = state == PlayerState.playing;
          });
        }
      });

      // Listen to audio duration
      _audioPlayer.onDurationChanged.listen((newDuration) {
        if (mounted) {
          setState(() {
            _duration = newDuration;
          });
        }
      });

      // Listen to current playback position
      _audioPlayer.onPositionChanged.listen((newPosition) {
        if (mounted) {
          setState(() {
            _position = newPosition;
          });
        }
      });

      // Listen when audio completes
      _audioPlayer.onPlayerComplete.listen((_) {
        _completeSession();
      });

      // Default fallback sample URL if none provided by API
      final url =
          widget.audioUrl ??
          'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3';

      debugPrint("🎵 Playing Meditation Audio From: $url");

      await _audioPlayer.setSourceUrl(url);
      await _audioPlayer.setVolume(_volume);
      await _audioPlayer.resume(); // Start playing automatically

      setState(() {
        _isLoadingAudio = false;
      });
    } catch (e) {
      debugPrint("❌ Audio Player Error: $e");
      setState(() {
        _isLoadingAudio = false;
      });
      Get.snackbar(
        'Playback Error',
        'Could not stream meditation audio.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _breathingController.dispose();
    super.dispose();
  }

  // ============================================================
  // PLAYER ACTIONS
  // ============================================================

  Future<void> _togglePlay() async {
    if (_isPlaying) {
      await _audioPlayer.pause();
    } else {
      await _audioPlayer.resume();
    }
  }

  Future<void> _skipBack() async {
    final newPos = _position - const Duration(seconds: 10);
    await _audioPlayer.seek(newPos < Duration.zero ? Duration.zero : newPos);
  }

  Future<void> _skipForward() async {
    final newPos = _position + const Duration(seconds: 10);
    if (newPos < _duration) {
      await _audioPlayer.seek(newPos);
    } else {
      await _audioPlayer.seek(_duration);
    }
  }

  Future<void> _onSeekChanged(double value) async {
    final position = Duration(seconds: value.toInt());
    await _audioPlayer.seek(position);
  }

  Future<void> _onVolumeChanged(double value) async {
    setState(() {
      _volume = value;
    });
    await _audioPlayer.setVolume(_volume);
  }

  void _completeSession() {
    setState(() {
      _isPlaying = false;
    });
    _showCompletionSheet();
  }

  // ============================================================
  // COMPLETION SHEET
  // ============================================================

  void _showCompletionSheet() {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 30),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
          border: Border.all(color: AppColors.primary.withOpacity(0.18)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textSecondary.withOpacity(0.30),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_rounded,
                color: AppColors.primary,
                size: 34,
              ),
            ),
            const SizedBox(height: 17),
            const Text(
              'Meditation Complete',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 7),
            const Text(
              'Beautiful work. Take this calm feeling with you.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12.5,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 22),
            Row(
              children: [
                Expanded(
                  child: _completionStat(
                    value: widget.session.duration,
                    label: 'Meditated',
                  ),
                ),
                Expanded(
                  child: _completionStat(value: '1', label: 'Session'),
                ),
                Expanded(
                  child: _completionStat(value: '8', label: 'Day Streak'),
                ),
              ],
            ),
            const SizedBox(height: 25),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  Get.back();
                  Get.back();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.black,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(11),
                  ),
                ),
                child: const Text(
                  'Done',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  Widget _completionStat({required String value, required String label}) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: AppColors.primary,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 9.5),
        ),
      ],
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return _buildPlayer(
              width: constraints.maxWidth,
              height: constraints.maxHeight,
            );
          },
        ),
      ),
    );
  }

  Widget _buildPlayer({required double width, required double height}) {
    final scale = (width / 390).clamp(0.88, 1.15);
    final contentWidth = width >= 700 ? 560.0 : width - (40 * scale);

    return Center(
      child: SizedBox(
        width: contentWidth,
        height: double.infinity,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.fromLTRB(
            20 * scale,
            16 * scale,
            20 * scale,
            30 * scale,
          ),
          child: Column(
            children: [
              _buildTopBar(scale),
              SizedBox(height: 30 * scale),
              _buildMeditationArtwork(scale),
              SizedBox(height: 28 * scale),
              Text(
                widget.session.title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 23 * scale,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                ),
              ),
              SizedBox(height: 7 * scale),
              Text(
                widget.session.duration,
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 12 * scale,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 27 * scale),
              _buildProgressSlider(scale),
              SizedBox(height: 5 * scale),
              _buildTimeRow(scale),
              SizedBox(height: 23 * scale),
              _isLoadingAudio
                  ? const CircularProgressIndicator(color: AppColors.primary)
                  : _buildControls(scale),
              SizedBox(height: 28 * scale),
              _buildVolumeControl(scale),
              SizedBox(height: 15 * scale),
              _buildBackgroundSound(scale),
              SizedBox(height: 28 * scale),
              _buildBreathingMessage(scale),
              SizedBox(height: 25 * scale),
              _buildCompleteButton(scale),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(double scale) {
    return Row(
      children: [
        _circleButton(
          icon: Icons.arrow_back_rounded,
          onTap: () {
            _audioPlayer.stop();
            Get.back();
          },
          scale: scale,
        ),
        const Spacer(),
        Text(
          'MEDITATION',
          style: TextStyle(
            color: AppColors.primary,
            fontSize: 10 * scale,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
          ),
        ),
        const Spacer(),
      ],
    );
  }

  Widget _buildMeditationArtwork(double scale) {
    return AnimatedBuilder(
      animation: _breathingController,
      builder: (context, child) {
        final value = _breathingController.value;

        final outerSize = (235 + (value * 10)) * scale;
        final middleSize = (195 + (value * 8)) * scale;
        final innerSize = (165 + (value * 5)) * scale;

        // Bigger image
        final imageSize = 180 * scale;

        return SizedBox(
          width: outerSize,
          height: outerSize,
          child: Center(
            child: Container(
              width: outerSize,
              height: outerSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.primary.withOpacity(0.09),
                  width: 1,
                ),
              ),
              child: Center(
                child: Container(
                  width: middleSize,
                  height: middleSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.primary.withOpacity(0.12),
                      width: 1,
                    ),
                  ),
                  child: Center(
                    child: Container(
                      width: innerSize,
                      height: innerSize,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            AppColors.primary.withOpacity(0.18),
                            AppColors.primary.withOpacity(0.06),
                            Colors.transparent,
                          ],
                        ),
                      ),
                      child: Center(
                        child: Container(
                          width: imageSize,
                          height: imageSize,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.primary.withOpacity(0.35),
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withOpacity(0.18),
                                blurRadius: 20 * scale,
                                spreadRadius: 2 * scale,
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: Image.asset(
                              'assets/images/Meditation_Pose.jpeg',
                              width: imageSize,
                              height: imageSize,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: AppColors.primary.withOpacity(0.10),
                                  child: Icon(
                                    Icons.self_improvement_rounded,
                                    color: AppColors.primary,
                                    size: 45 * scale,
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildProgressSlider(double scale) {
    final maxSec = _duration.inSeconds.toDouble();
    final currentSec = _position.inSeconds.toDouble().clamp(
      0.0,
      maxSec > 0 ? maxSec : 1.0,
    );

    return SliderTheme(
      data: SliderTheme.of(context).copyWith(
        trackHeight: 4 * scale,
        thumbShape: RoundSliderThumbShape(enabledThumbRadius: 6 * scale),
        overlayShape: RoundSliderOverlayShape(overlayRadius: 14 * scale),
        activeTrackColor: AppColors.primary,
        inactiveTrackColor: AppColors.primary.withOpacity(0.12),
        thumbColor: AppColors.primary,
        overlayColor: AppColors.primary.withOpacity(0.10),
      ),
      child: Slider(
        value: currentSec,
        min: 0.0,
        max: maxSec > 0 ? maxSec : 1.0,
        onChanged: (value) {
          _onSeekChanged(value);
        },
      ),
    );
  }

  Widget _buildTimeRow(double scale) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          _formatDuration(_position),
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 10 * scale,
          ),
        ),
        Text(
          _formatDuration(_duration),
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 10 * scale,
          ),
        ),
      ],
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  Widget _buildControls(double scale) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _playerControl(
          icon: Icons.replay_10_rounded,
          onTap: _skipBack,
          scale: scale,
        ),
        SizedBox(width: 30 * scale),
        GestureDetector(
          onTap: _togglePlay,
          child: Container(
            width: 68 * scale,
            height: 68 * scale,
            decoration: BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: Icon(
              _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
              color: Colors.black,
              size: 31 * scale,
            ),
          ),
        ),
        SizedBox(width: 30 * scale),
        _playerControl(
          icon: Icons.forward_10_rounded,
          onTap: _skipForward,
          scale: scale,
        ),
      ],
    );
  }

  Widget _playerControl({
    required IconData icon,
    required VoidCallback onTap,
    required double scale,
  }) {
    return IconButton(
      onPressed: onTap,
      icon: Icon(icon, color: AppColors.textPrimary, size: 27 * scale),
    );
  }

  Widget _buildVolumeControl(double scale) {
    return Row(
      children: [
        Icon(
          Icons.volume_down_rounded,
          color: AppColors.textSecondary,
          size: 19 * scale,
        ),
        Expanded(
          child: Slider(
            value: _volume,
            onChanged: _onVolumeChanged,
            activeColor: AppColors.primary,
            inactiveColor: AppColors.primary.withOpacity(0.10),
          ),
        ),
        Icon(
          Icons.volume_up_rounded,
          color: AppColors.textSecondary,
          size: 19 * scale,
        ),
      ],
    );
  }

  Widget _buildBackgroundSound(double scale) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 14 * scale,
        vertical: 12 * scale,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12 * scale),
        border: Border.all(color: AppColors.primary.withOpacity(0.14)),
      ),
      child: Row(
        children: [
          Icon(Icons.waves_rounded, color: AppColors.primary, size: 19 * scale),
          SizedBox(width: 11 * scale),
          const Expanded(
            child: Text(
              'Background Ambient Sound',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Switch(
            value: _backgroundSound,
            onChanged: (val) => setState(() => _backgroundSound = val),
            activeColor: AppColors.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildBreathingMessage(double scale) {
    return Column(
      children: [
        Text(
          'Breathe in slowly...',
          style: TextStyle(
            color: AppColors.primary,
            fontSize: 12 * scale,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          'Let your thoughts come and go without judgment.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 10.5 * scale,
          ),
        ),
      ],
    );
  }

  Widget _buildCompleteButton(double scale) {
    return SizedBox(
      width: double.infinity,
      height: 48 * scale,
      child: OutlinedButton(
        onPressed: () {
          _audioPlayer.stop();
          _completeSession();
        },
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: BorderSide(color: AppColors.primary.withOpacity(0.35)),
        ),
        child: const Text(
          'Complete Session',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _circleButton({
    required IconData icon,
    required VoidCallback onTap,
    required double scale,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.primary.withOpacity(0.15)),
        ),
        child: Icon(icon, color: AppColors.textPrimary, size: 19 * scale),
      ),
    );
  }
}
