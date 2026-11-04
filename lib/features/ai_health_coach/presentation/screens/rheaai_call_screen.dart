import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../../../app/theme/app_colors.dart';
import '../controllers/rhea_live_call_controller.dart';

class RheaCheckInCallScreen extends StatefulWidget {
  const RheaCheckInCallScreen({super.key});

  @override
  State<RheaCheckInCallScreen> createState() => _RheaCheckInCallScreenState();
}

class _RheaCheckInCallScreenState extends State<RheaCheckInCallScreen>
    with SingleTickerProviderStateMixin {
  late final RheaLiveCallController _liveController;
  late final AnimationController _pulseController;

  final List<Worker> _workers = [];

  bool _isEnding = false;
  bool _endRequested = false;
  bool _allowPop = false;
  bool _isInitializing = false;
  bool _isTogglingMute = false;
  bool _cleanupStarted = false;
  Future<void> _wakeLockOperation = Future<void>.value();

  RheaLiveCallStatus get _status => _liveController.status.value;

  bool get _isStarting =>
      _status == RheaLiveCallStatus.connecting ||
      _status == RheaLiveCallStatus.reconnecting;

  bool get _sessionStarted => _status == RheaLiveCallStatus.connected;

  bool get _microphoneMuted => _liveController.isMuted.value;

  bool get _isSpeaking => _liveController.isRheaSpeaking.value;

  bool get _isListening => _sessionStarted && !_microphoneMuted && !_isSpeaking;

  String get _statusText {
    if (_isEnding || _status == RheaLiveCallStatus.ending) {
      return 'Ending call...';
    }

    switch (_status) {
      case RheaLiveCallStatus.idle:
        return 'Preparing call...';
      case RheaLiveCallStatus.connecting:
        return 'Connecting to Rhea...';
      case RheaLiveCallStatus.connected:
        if (_microphoneMuted) return 'Microphone muted';
        if (_isSpeaking) return 'Rhea is speaking';
        return 'Listening';
      case RheaLiveCallStatus.reconnecting:
        return 'Reconnecting to Rhea...';
      case RheaLiveCallStatus.ending:
        return 'Ending call...';
      case RheaLiveCallStatus.ended:
        return 'Call ended';
      case RheaLiveCallStatus.failed:
        return 'Unable to connect';
    }
  }

  @override
  void initState() {
    super.initState();

    unawaited(_setScreenAwake(true));

    _liveController = Get.put(RheaLiveCallController(), tag: 'rhea_live_call');

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _workers.addAll([
      ever(_liveController.status, (_) => _refresh()),
      ever(_liveController.isMuted, (_) => _refresh()),
      ever(_liveController.isRheaSpeaking, (_) => _refresh()),
      ever(_liveController.elapsedSeconds, (_) => _refresh()),
      ever(_liveController.errorMessage, (message) {
        if (!mounted || _isEnding || message.trim().isEmpty) return;
        _showError(message);
      }),
    ]);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_isEnding) {
        unawaited(_initializeCall());
      }
    });
  }

  // Serialize wake-lock changes so a late enable cannot override disable.
  Future<void> _setScreenAwake(bool enabled) {
    _wakeLockOperation = _wakeLockOperation.then((_) async {
      try {
        if (enabled) {
          // If the route was disposed before this operation runs, skip it.
          if (!mounted || _isEnding) return;
          await WakelockPlus.enable();
        } else {
          await WakelockPlus.disable();
        }
      } catch (error) {
        debugPrint('RHEA LIVE: Screen wake lock error: $error');
      }
    });
    return _wakeLockOperation;
  }

  void _refresh() {
    if (mounted && !_isEnding) {
      setState(() {});
    }
  }

  Future<void> _initializeCall() async {
    if (!mounted || _isEnding || _isInitializing) return;

    _isInitializing = true;

    try {
      debugPrint('RHEA LIVE: Starting Gemini Live call.');

      final started = await _liveController.startCall();

      if (!mounted || _isEnding) return;

      if (!started) {
        final error = _liveController.errorMessage.value.trim();
        if (error.isNotEmpty) {
          _showError(error);
        } else {
          _showError('Unable to connect to Rhea. Please try again.');
        }
        return;
      }

      debugPrint('RHEA LIVE: Call connected.');
    } catch (error) {
      debugPrint('RHEA LIVE CALL INITIALIZATION ERROR: $error');

      if (mounted && !_isEnding) {
        _showError('Unable to start Rhea voice call. Please try again.');
      }
    } finally {
      _isInitializing = false;
    }
  }

  Future<void> _toggleMicrophone() async {
    if (_isEnding || !_sessionStarted || _isTogglingMute) return;

    _isTogglingMute = true;

    try {
      await _liveController.toggleMute();

      if (!mounted || _isEnding) return;

      debugPrint(
        'RHEA LIVE: Microphone muted = ${_liveController.isMuted.value}',
      );
    } catch (error) {
      debugPrint('RHEA LIVE MICROPHONE ERROR: $error');

      if (mounted && !_isEnding) {
        _showError('Unable to change microphone state.');
      }
    } finally {
      _isTogglingMute = false;
    }
  }

  Future<void> _endCall() async {
    if (_endRequested) return;

    _endRequested = true;
    _isEnding = true;
    _cleanupStarted = true;

    if (mounted) setState(() {});

    try {
      debugPrint('RHEA LIVE: Ending call.');
      await _liveController.endCall();
      debugPrint('RHEA LIVE: Call ended.');
    } catch (error) {
      debugPrint('RHEA LIVE END CALL ERROR: $error');
    }

    await _setScreenAwake(false);

    // Allow navigation only after endCall() has finished.
    if (!mounted) return;

    setState(() {
      _allowPop = true;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    });
  }

  void _showError(String message) {
    if (!mounted || message.trim().isEmpty || _isEnding) return;

    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(message, maxLines: 3, overflow: TextOverflow.ellipsis),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _formatDuration(int totalSeconds) {
    final duration = Duration(seconds: totalSeconds);
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    final hours = duration.inHours;

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:$minutes:$seconds';
    }

    return '$minutes:$seconds';
  }

  Color _statusColor() {
    if (_isStarting || _isEnding) return Colors.orange;
    if (_status == RheaLiveCallStatus.failed) return Colors.red;
    if (_microphoneMuted) return Colors.grey;
    if (_isListening) return Colors.green;
    return AppColors.primary;
  }

  IconData _statusIcon() {
    if (_isStarting) return Icons.sync_rounded;
    if (_isEnding) return Icons.call_end_rounded;
    if (_status == RheaLiveCallStatus.failed) {
      return Icons.error_outline_rounded;
    }
    if (_microphoneMuted) return Icons.mic_off_rounded;
    if (_isSpeaking) return Icons.volume_up_rounded;
    if (_isListening) return Icons.mic_rounded;
    return Icons.favorite_rounded;
  }

  Widget _buildAvatar(double size) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final pulse = (_isListening || _isSpeaking)
            ? _pulseController.value * 8
            : 0.0;

        return Container(
          width: size + pulse,
          height: size + pulse,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.surface,
            boxShadow: [
              BoxShadow(
                color: _statusColor().withValues(
                  alpha: _isListening || _isSpeaking ? .28 : .12,
                ),
                blurRadius: _isListening || _isSpeaking ? 30 : 16,
                spreadRadius: _isListening || _isSpeaking ? 5 : 1,
              ),
            ],
          ),
          child: ClipOval(
            child: SizedBox.expand(
              child: Image.asset(
                'assets/images/RheaAI_Call.png',
                fit: BoxFit.cover,
                alignment: Alignment.center,
                errorBuilder: (context, error, stackTrace) {
                  debugPrint('RHEA IMAGE LOAD ERROR: $error');

                  return Container(
                    color: AppColors.primary.withValues(alpha: .12),
                    child: const Center(
                      child: Icon(
                        Icons.person_rounded,
                        size: 70,
                        color: AppColors.primary,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: _statusColor().withValues(alpha: .10),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: _statusColor().withValues(alpha: .25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_statusIcon(), size: 16, color: _statusColor()),
          const SizedBox(width: 7),
          Flexible(
            child: Text(
              _statusText,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: _statusColor(),
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required Color backgroundColor,
    required Color foregroundColor,
    required VoidCallback? onTap,
    bool large = false,
  }) {
    final size = large ? 64.0 : 56.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: backgroundColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: backgroundColor.withValues(alpha: .20),
                  blurRadius: 12,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Icon(icon, color: foregroundColor, size: large ? 28 : 24),
          ),
        ),
        const SizedBox(height: 7),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildCallControls() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildControlButton(
            icon: _microphoneMuted ? Icons.mic_off_rounded : Icons.mic_rounded,
            label: _microphoneMuted ? 'Unmute' : 'Mute',
            backgroundColor: _microphoneMuted
                ? Colors.grey.shade700
                : AppColors.primary,
            foregroundColor: _microphoneMuted ? Colors.white : Colors.black,
            onTap: _isEnding || !_sessionStarted || _isTogglingMute
                ? null
                : () => unawaited(_toggleMicrophone()),
          ),
          const SizedBox(width: 24),
          _buildControlButton(
            icon: Icons.call_end_rounded,
            label: 'End',
            backgroundColor: Colors.red.shade500,
            foregroundColor: Colors.white,
            large: true,
            onTap: _isEnding ? null : () => unawaited(_endCall()),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmallHeight = size.height < 700;

    return PopScope(
      canPop: _allowPop,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && !_endRequested) {
          unawaited(_endCall());
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.surface,
          elevation: 0,
          centerTitle: false,
          automaticallyImplyLeading: false,
          leading: IconButton(
            onPressed: _isEnding ? null : () => unawaited(_endCall()),
            icon: const Icon(
              Icons.arrow_back_rounded,
              color: AppColors.textPrimary,
            ),
          ),
          title: const Text(
            'RheaAI Check-in',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
                child: Row(
                  children: [
                    Flexible(child: _buildStatusBadge()),
                    const Spacer(),
                    const SizedBox(width: 12),
                    Text(
                      _formatDuration(_liveController.elapsedSeconds.value),
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.only(
                    top: isSmallHeight ? 10 : 28,
                    bottom: 20,
                  ),
                  child: Column(
                    children: [
                      _buildAvatar(isSmallHeight ? 180 : 220),
                      const SizedBox(height: 20),
                      const Text(
                        'Rhea AI',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 7),
                      Text(
                        _isSpeaking
                            ? 'Rhea is talking with you'
                            : _isListening
                            ? 'Speak naturally'
                            : _statusText,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 22),
                      if (_isStarting)
                        const Padding(
                          padding: EdgeInsets.only(top: 18),
                          child: CircularProgressIndicator(
                            color: AppColors.primary,
                            strokeWidth: 2.5,
                          ),
                        ),
                      if (_status == RheaLiveCallStatus.reconnecting)
                        Padding(
                          padding: const EdgeInsets.only(top: 18),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 11,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              'Restoring your connection...',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      if (_status == RheaLiveCallStatus.failed)
                        Padding(
                          padding: const EdgeInsets.only(
                            top: 18,
                            left: 24,
                            right: 24,
                          ),
                          child: Text(
                            _liveController.errorMessage.value.isNotEmpty
                                ? _liveController.errorMessage.value
                                : 'Unable to connect to Rhea.',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.red,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              _buildCallControls(),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _isEnding = true;
    unawaited(_setScreenAwake(false));

    for (final worker in _workers) {
      worker.dispose();
    }
    _workers.clear();

    // When a route is removed externally, ensure its call is still ended.
    // Normal End/Back navigation already invokes endCall(), so do not
    // start a second cleanup operation.
    if (!_endRequested && !_cleanupStarted) {
      _cleanupStarted = true;
      unawaited(_liveController.endCall());
    }

    _pulseController.dispose();
    super.dispose();
  }
}
