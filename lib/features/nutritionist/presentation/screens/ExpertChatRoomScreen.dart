import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/theme/app_colors.dart';
import '../../data/models/expert_model.dart';
import '../controllers/expert_controller.dart';

class ExpertChatRoomScreen extends StatefulWidget {
  const ExpertChatRoomScreen({super.key, required this.expert});

  final ExpertModel expert;

  @override
  State<ExpertChatRoomScreen> createState() => _ExpertChatRoomScreenState();
}

class _ExpertChatRoomScreenState extends State<ExpertChatRoomScreen> {
  final ExpertController _controller = Get.put(ExpertController());
  final TextEditingController _messageController = TextEditingController();

  // Timer for periodic message polling
  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();

    // Fetch initial chat messages and check pass status on screen load
    _controller.fetchChatMessages(widget.expert.id);
    _controller.checkPassStatus(widget.expert.id);

    // Start background polling every 4 seconds to fetch expert replies live
    _pollingTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (mounted) {
        _controller.fetchChatMessages(widget.expert.id);
      } else {
        timer.cancel();
      }
    });
  }

  void _sendMessage() async {
    final text = _messageController.text.trim();

    if (text.isEmpty) return;

    _messageController.clear();

    final success = await _controller.sendExpertMessage(
      expertId: widget.expert.id,
      message: text,
    );

    if (success) {
      // Instantly fetch messages to show user's sent message right away
      _controller.fetchChatMessages(widget.expert.id);
    } else if (!_controller.isChatEligible.value) {
      Get.snackbar(
        'Pass Expired',
        _controller.errorMessage.value.isNotEmpty
            ? _controller.errorMessage.value
            : 'Please renew your consultation pass to continue.',
        backgroundColor: Colors.orangeAccent,
        colorText: Colors.black,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  // ============================================================
  // CALL EXPERT
  // ============================================================
  void _callExpert() {
    Get.snackbar(
      'Call Expert',
      'Calling ${widget.expert.name} will be available here.',
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(16),
      backgroundColor: AppColors.surface,
      colorText: AppColors.textPrimary,
      icon: const Icon(Icons.call_rounded, color: AppColors.primary),
    );
  }

  @override
  void dispose() {
    // Cancel the timer when leaving the chat room to prevent memory leaks
    _pollingTimer?.cancel();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,

        // ==========================================================
        // HEADER
        // ==========================================================
        leading: IconButton(
          onPressed: () => Get.back(),
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.primary,
          ),
        ),

        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.background,
              backgroundImage:
                  widget.expert.imageUrl != null &&
                      widget.expert.imageUrl!.isNotEmpty
                  ? NetworkImage(widget.expert.imageUrl!)
                  : const AssetImage('assets/images/Profile.png')
                        as ImageProvider,
            ),
            const SizedBox(width: 10),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.expert.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    widget.expert.isAvailable ? "Online" : "Offline",
                    style: TextStyle(
                      color: widget.expert.isAvailable
                          ? Colors.green
                          : Colors.grey,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        // ==========================================================
        // CALL ICON IN HEADER
        // ==========================================================
        actions: [
          IconButton(
            onPressed: _callExpert,
            tooltip: 'Call Expert',
            icon: const Icon(
              Icons.call_rounded,
              color: AppColors.primary,
              size: 22,
            ),
          ),
          const SizedBox(width: 6),
        ],
      ),

      body: SafeArea(
        child: Column(
          children: [
            // ==========================================
            // CHAT MESSAGES LIST (API DRIVEN)
            // ==========================================
            Expanded(
              child: Obx(() {
                final messages = _controller.chatMessages;

                if (messages.isEmpty) {
                  return const Center(
                    child: Text(
                      "No messages yet. Send a message to start consulting!",
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];

                    final String senderType = msg['sender_type'] ?? 'user';

                    final bool isUser = senderType == 'user';

                    final String text = msg['message'] ?? '';

                    final String time = msg['created_at'] ?? '';

                    return Align(
                      alignment: isUser
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        padding: const EdgeInsets.all(14),
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.75,
                        ),
                        decoration: BoxDecoration(
                          color: isUser ? AppColors.primary : AppColors.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: isUser
                              ? null
                              : Border.all(
                                  color: AppColors.primary.withOpacity(0.2),
                                ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              text,
                              style: TextStyle(
                                color: isUser
                                    ? Colors.black
                                    : AppColors.textPrimary,
                                fontSize: 14,
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              time.length > 16 ? time.substring(11, 16) : time,
                              style: TextStyle(
                                color: isUser
                                    ? Colors.black54
                                    : AppColors.textSecondary,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              }),
            ),

            // ==========================================
            // DYNAMIC INPUT BAR / PASS EXPIRY LOCK
            // ==========================================
            Obx(() {
              final bool eligible = _controller.isChatEligible.value;

              if (!eligible) {
                return Container(
                  padding: const EdgeInsets.all(16),
                  color: AppColors.surface,
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          "Consultation pass expired.",
                          style: TextStyle(
                            color: Colors.orangeAccent,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                        ),
                        onPressed: () {
                          Get.snackbar(
                            'Renew Pass',
                            'Please purchase a new consultation pass to continue messaging.',
                            snackPosition: SnackPosition.BOTTOM,
                          );
                        },
                        child: const Text(
                          "Renew Pass",
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }

              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  border: Border(
                    top: BorderSide(color: AppColors.primary.withOpacity(0.2)),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                        ),
                        decoration: InputDecoration(
                          hintText: "Type your query...",
                          hintStyle: TextStyle(
                            color: AppColors.textSecondary.withOpacity(0.6),
                          ),
                          border: InputBorder.none,
                        ),
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                    Obx(
                      () => _controller.isSendingMessage.value
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: AppColors.primary,
                                strokeWidth: 2,
                              ),
                            )
                          : IconButton(
                              onPressed: _sendMessage,
                              icon: const Icon(
                                Icons.send_rounded,
                                color: AppColors.primary,
                              ),
                            ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
