import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import 'package:disha_ai/features/ai_health_coach/presentation/controllers/ai_controller.dart';
import 'check_in_calls_screen.dart';
import '../../../../app/theme/app_colors.dart';

class AiHealthCoachScreen extends StatefulWidget {
  const AiHealthCoachScreen({super.key});

  @override
  State<AiHealthCoachScreen> createState() => _AiHealthCoachScreenState();
}

class _AiHealthCoachScreenState extends State<AiHealthCoachScreen> {
  //---------------------------------------------------------------
  // CONTROLLERS
  //---------------------------------------------------------------

  final TextEditingController messageController = TextEditingController();
  final ScrollController scrollController = ScrollController();
  final FocusNode inputFocusNode = FocusNode();

  // Inject AI Controller
  final AiController _aiController = Get.put(AiController());
  final ImagePicker _imagePicker = ImagePicker();

  //---------------------------------------------------------------
  // STATE
  //---------------------------------------------------------------

  bool _isTyping = false;

  final List<Map<String, dynamic>> messages = [];

  //---------------------------------------------------------------
  // INIT
  //---------------------------------------------------------------

  @override
  void initState() {
    super.initState();
    _restoreWelcomeMessage();
    _loadChatHistory();
  }

  void _restoreWelcomeMessage() {
    messages.clear();
    messages.add({
      "text":
          "Hi, I am Rhea AI 🤍\nYour personal health companion. How can I help you today?",
      "isUser": false,
      "isError": false,
    });
  }

  //---------------------------------------------------------------
  // FETCH CHAT HISTORY (API INTEGRATED)
  //---------------------------------------------------------------
  Future<void> _loadChatHistory() async {
    final success = await _aiController.getChatHistory();

    if (success && _aiController.chatHistory.value != null && mounted) {
      final rawData = _aiController.chatHistory.value!.data;

      // Handle the nested "history" object structure
      List<dynamic> chatList = [];
      if (rawData is List) {
        chatList = rawData;
      } else if (rawData is Map && rawData['history'] is List) {
        chatList = rawData['history'];
      }

      if (chatList.isNotEmpty) {
        setState(() {
          messages.clear(); // Clear the default welcome message

          for (var item in chatList) {
            if (item is Map) {
              // Extract text
              final text = item['message']?.toString() ?? '';

              // Determine if it was sent by the user (matching API 'sender' field)
              final isUser = item['sender'] == 'user' || item['role'] == 'user';

              if (text.isNotEmpty) {
                messages.add({
                  "text": text,
                  "isUser": isUser,
                  "isError": false,
                });
              }
            }
          }

          // If parsing found zero valid messages, restore the welcome message
          if (messages.isEmpty) {
            _restoreWelcomeMessage();
          }
        });

        scrollToBottom();
      }
    }
  }
  //---------------------------------------------------------------
  // CLEAR CHAT HISTORY (API INTEGRATED)
  //---------------------------------------------------------------

  void _confirmClearHistory() {
    Get.defaultDialog(
      backgroundColor: AppColors.surface,
      title: "Clear Chat",
      titleStyle: const TextStyle(
        color: AppColors.textPrimary,
        fontWeight: FontWeight.bold,
      ),
      middleText:
          "Are you sure you want to clear your entire conversation history?",
      middleTextStyle: const TextStyle(color: AppColors.textSecondary),
      textConfirm: "Clear",
      textCancel: "Cancel",
      confirmTextColor: Colors.white,
      buttonColor: Colors.redAccent,
      cancelTextColor: Colors.redAccent,
      onConfirm: () async {
        Get.back(); // Close dialog

        final success = await _aiController.clearChatHistory();

        if (success && mounted) {
          setState(() {
            _restoreWelcomeMessage();
          });
        } else if (!success) {
          Get.snackbar(
            "Error",
            "Failed to clear chat history.",
            backgroundColor: Colors.redAccent,
            colorText: Colors.white,
            snackPosition: SnackPosition.BOTTOM,
            margin: const EdgeInsets.all(16),
          );
        }
      },
    );
  }

  //---------------------------------------------------------------
  // SUGGESTIONS
  //---------------------------------------------------------------

  final List<String> suggestions = [
    "Analyze my sleep 😴",
    "Diet advice 🥗",
    "Workout plan 💪",
    "Health tips ✨",
  ];

  //---------------------------------------------------------------
  // SEND MESSAGE (API INTEGRATED)
  //---------------------------------------------------------------

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    final userMessage = text.trim();

    setState(() {
      messages.add({"text": userMessage, "isUser": true, "isError": false});
      messageController.clear();
      _isTyping = true;
    });

    scrollToBottom();

    final success = await _aiController.sendChatMessage(userMessage);

    if (!mounted) return;

    setState(() {
      _isTyping = false;

      if (success && _aiController.chatResponse.value != null) {
        final aiResponse =
            _aiController.chatResponse.value!.message ??
            _aiController.chatResponse.value!.data?.toString() ??
            "I've received your message, but I couldn't format the response.";

        messages.add({"text": aiResponse, "isUser": false, "isError": false});
      } else {
        messages.add({
          "text": _aiController.errorMessage.value.isNotEmpty
              ? _aiController.errorMessage.value
              : "Sorry, I'm having trouble connecting right now. Please try again.",
          "isUser": false,
          "isError": true,
        });
      }
    });

    scrollToBottom();
  }

  //---------------------------------------------------------------
  // HANDLE CAMERA / FOOD SCAN IMAGE PICKING
  //---------------------------------------------------------------

  Future<void> _pickAndScanImage() async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );

      if (pickedFile == null) return;

      final File imageFile = File(pickedFile.path);

      setState(() {
        messages.add({
          "text": "📷 [Attached Food Image for Analysis]",
          "isUser": true,
          "isError": false,
        });
        _isTyping = true;
      });

      scrollToBottom();

      final success = await _aiController.scanFoodImage(imageFile);

      if (!mounted) return;

      setState(() {
        _isTyping = false;

        if (success && _aiController.foodAnalysis.value != null) {
          final resModel = _aiController.foodAnalysis.value!;
          final analysisResult =
              resModel.message ??
              resModel.data?.toString() ??
              "Food scanned successfully! Here are the nutritional insights.";

          messages.add({
            "text": "🥗 **Food Analysis Result:**\n$analysisResult",
            "isUser": false,
            "isError": false,
          });
        } else {
          messages.add({
            "text": _aiController.errorMessage.value.isNotEmpty
                ? _aiController.errorMessage.value
                : "Failed to analyze the image. Please try again.",
            "isUser": false,
            "isError": true,
          });
        }
      });

      scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isTyping = false;
        messages.add({
          "text": "Error capturing image: $e",
          "isUser": false,
          "isError": true,
        });
      });
      scrollToBottom();
    }
  }

  //---------------------------------------------------------------
  // HANDLE ATTACHMENT / LINK ICON
  //---------------------------------------------------------------

  void _handleAttachment() {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(
                Icons.camera_alt_rounded,
                color: AppColors.primary,
              ),
              title: const Text(
                "Scan Food Image",
                style: TextStyle(color: AppColors.textPrimary),
              ),
              onTap: () {
                Navigator.pop(context);
                _pickAndScanImage();
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.favorite_rounded,
                color: AppColors.primary,
              ),
              title: const Text(
                "Analyze My Profile",
                style: TextStyle(color: AppColors.textPrimary),
              ),
              onTap: () async {
                Navigator.pop(context);
                setState(() {
                  messages.add({
                    "text": "Analyzing my health profile...",
                    "isUser": true,
                    "isError": false,
                  });
                  _isTyping = true;
                });
                scrollToBottom();

                final success = await _aiController.analyzeProfile();
                if (!mounted) return;

                setState(() {
                  _isTyping = false;
                  if (success && _aiController.profileAnalysis.value != null) {
                    final resModel = _aiController.profileAnalysis.value!;
                    final profileText =
                        resModel.message ??
                        resModel.data?.toString() ??
                        "Profile analysis completed successfully.";

                    messages.add({
                      "text": "📊 **Profile Health Analysis:**\n$profileText",
                      "isUser": false,
                      "isError": false,
                    });
                  } else {
                    messages.add({
                      "text": _aiController.errorMessage.value.isNotEmpty
                          ? _aiController.errorMessage.value
                          : "Could not analyze profile right now.",
                      "isUser": false,
                      "isError": true,
                    });
                  }
                });
                scrollToBottom();
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.monitor_heart_rounded,
                color: AppColors.primary,
              ),
              title: const Text(
                "Check Vitals & Symptoms",
                style: TextStyle(color: AppColors.textPrimary),
              ),
              onTap: () async {
                Navigator.pop(context);
                setState(() {
                  messages.add({
                    "text": "Evaluating current vitals...",
                    "isUser": true,
                    "isError": false,
                  });
                  _isTyping = true;
                });
                scrollToBottom();

                final success = await _aiController.analyzeVitals();
                if (!mounted) return;

                setState(() {
                  _isTyping = false;
                  if (success && _aiController.vitalsAnalysis.value != null) {
                    final resModel = _aiController.vitalsAnalysis.value!;
                    String vitalsText = "";
                    final data = resModel.data;
                    if (data is Map<String, dynamic>) {
                      final assessment = data['health_assessment'] is Map
                          ? data['health_assessment'] as Map
                          : data;
                      final status = assessment['status'] ?? 'Balanced';
                      final score = assessment['vital_score'] ?? 'N/A';
                      final recommendation =
                          assessment['recommendation'] ??
                          resModel.message ??
                          'Keep maintaining your daily goals.';

                      vitalsText =
                          "Status: $status\nVital Score: $score / 100\n\nRecommendation: $recommendation";
                    } else {
                      vitalsText =
                          resModel.message ??
                          resModel.data?.toString() ??
                          "Vitals checked successfully.";
                    }

                    messages.add({
                      "text": "💓 **Vitals Health Assessment:**\n$vitalsText",
                      "isUser": false,
                      "isError": false,
                    });
                  } else {
                    messages.add({
                      "text": _aiController.errorMessage.value.isNotEmpty
                          ? _aiController.errorMessage.value
                          : "Could not retrieve vitals analysis.",
                      "isUser": false,
                      "isError": true,
                    });
                  }
                });
                scrollToBottom();
              },
            ),
          ],
        ),
      ),
    );
  }

  //---------------------------------------------------------------
  // SCROLL TO BOTTOM
  //---------------------------------------------------------------

  void scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (!mounted || !scrollController.hasClients) return;
      scrollController.animateTo(
        scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  //---------------------------------------------------------------
  // OPEN CHECK-IN CALL
  //---------------------------------------------------------------

  void _openCheckInCall() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CheckInCallsScreen()),
    );
  }

  //---------------------------------------------------------------
  // DISPOSE
  //---------------------------------------------------------------

  @override
  void dispose() {
    messageController.dispose();
    scrollController.dispose();
    inputFocusNode.dispose();
    super.dispose();
  }

  //---------------------------------------------------------------
  // BUILD
  //---------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final double width = constraints.maxWidth;
            final bool isTablet = width >= 600;

            return Column(
              children: [
                // HEADER
                _buildHeader(isTablet),

                // CHAT AREA
                Expanded(
                  child: GestureDetector(
                    onTap: () => FocusScope.of(context).unfocus(),
                    child: Obx(() {
                      if (_aiController.isHistoryLoading.value &&
                          messages.length <= 1) {
                        return const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.primary,
                          ),
                        );
                      }

                      return ListView.builder(
                        controller: scrollController,
                        physics: const BouncingScrollPhysics(),
                        padding: EdgeInsets.fromLTRB(
                          isTablet ? 40 : 16,
                          20,
                          isTablet ? 40 : 16,
                          12,
                        ),
                        itemCount: messages.length + (_isTyping ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == messages.length && _isTyping) {
                            return _typingIndicatorBubble(isTablet);
                          }

                          final message = messages[index];
                          final String text = message["text"] as String? ?? "";
                          final bool isUser =
                              message["isUser"] as bool? ?? false;
                          final bool isError =
                              message["isError"] as bool? ?? false;

                          return _chatBubble(text, isUser, isError, isTablet);
                        },
                      );
                    }),
                  ),
                ),

                // SUGGESTIONS
                if (messages.length < 3) _suggestionSection(isTablet),

                // MESSAGE INPUT
                _messageInput(isTablet),
              ],
            );
          },
        ),
      ),
    );
  }

  //================================================================
  // HEADER
  //================================================================

  Widget _buildHeader(bool tablet) {
    final double avatarSize = tablet ? 58 : 48;
    final double horizontalPadding = tablet ? 24 : 12;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: tablet ? 16 : 10,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border, width: 1)),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: AppColors.textPrimary,
              size: tablet ? 25 : 20,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            splashRadius: 20,
          ),
          SizedBox(width: tablet ? 16 : 8),
          Container(
            width: avatarSize,
            height: avatarSize,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.primaryDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Icon(
              Icons.auto_awesome_rounded,
              color: Colors.black,
              size: tablet ? 30 : 24,
            ),
          ),
          SizedBox(width: tablet ? 14 : 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Rhea AI",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: tablet ? 22 : 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  "Your Personal Health Coach",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: tablet ? 14 : 11.5,
                  ),
                ),
              ],
            ),
          ),

          // ==========================================
          // CLEAR CHAT ICON
          // ==========================================
          Material(
            color: Colors.transparent,
            shape: const CircleBorder(),
            child: InkWell(
              onTap: _confirmClearHistory,
              customBorder: const CircleBorder(),
              child: Container(
                width: tablet ? 48 : 40,
                height: tablet ? 48 : 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.redAccent.withOpacity(.12),
                  border: Border.all(color: Colors.redAccent.withOpacity(.30)),
                ),
                child: Icon(
                  Icons.delete_sweep_rounded,
                  color: Colors.redAccent,
                  size: tablet ? 24 : 20,
                ),
              ),
            ),
          ),
          SizedBox(width: tablet ? 12 : 7),

          // ==========================================
          // CHECK-IN CALL ICON
          // ==========================================
          Material(
            color: Colors.transparent,
            shape: const CircleBorder(),
            child: InkWell(
              onTap: _openCheckInCall,
              customBorder: const CircleBorder(),
              child: Container(
                width: tablet ? 48 : 40,
                height: tablet ? 48 : 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withOpacity(.12),
                  border: Border.all(color: AppColors.primary.withOpacity(.30)),
                ),
                child: Icon(
                  Icons.phone_rounded,
                  color: AppColors.primary,
                  size: tablet ? 24 : 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  //================================================================
  // CHAT BUBBLE
  //================================================================

  Widget _chatBubble(String text, bool isUser, bool isError, bool tablet) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: tablet ? 550 : MediaQuery.sizeOf(context).width * .82,
        ),
        margin: const EdgeInsets.only(bottom: 14),
        padding: EdgeInsets.symmetric(
          horizontal: tablet ? 18 : 15,
          vertical: tablet ? 16 : 14,
        ),
        decoration: BoxDecoration(
          color: isUser
              ? AppColors.primary
              : (isError
                    ? Colors.redAccent.withOpacity(0.1)
                    : AppColors.surfaceSoft),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isUser ? 18 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 18),
          ),
          border: isUser
              ? null
              : Border.all(
                  color: isError
                      ? Colors.redAccent.withOpacity(0.5)
                      : AppColors.border,
                ),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isUser
                ? Colors.black
                : (isError ? Colors.redAccent : AppColors.textPrimary),
            fontSize: tablet ? 17 : 15,
            height: 1.45,
            fontWeight: isUser ? FontWeight.w500 : FontWeight.w400,
          ),
        ),
      ),
    );
  }

  //================================================================
  // TYPING INDICATOR BUBBLE
  //================================================================

  Widget _typingIndicatorBubble(bool tablet) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: EdgeInsets.symmetric(
          horizontal: tablet ? 18 : 15,
          vertical: tablet ? 16 : 14,
        ),
        decoration: BoxDecoration(
          color: AppColors.surfaceSoft,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(18),
            topRight: Radius.circular(18),
            bottomLeft: Radius.circular(4),
            bottomRight: Radius.circular(18),
          ),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              "Rhea is analyzing...",
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: tablet ? 15 : 13,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  //================================================================
  // SUGGESTIONS
  //================================================================

  Widget _suggestionSection(bool tablet) {
    return SizedBox(
      height: tablet ? 58 : 52,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: tablet ? 40 : 16),
        itemCount: suggestions.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          return Center(
            child: ActionChip(
              backgroundColor: AppColors.surfaceSoft,
              side: const BorderSide(color: AppColors.border),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22),
              ),
              padding: EdgeInsets.symmetric(
                horizontal: tablet ? 12 : 9,
                vertical: tablet ? 8 : 6,
              ),
              label: Text(
                suggestions[index],
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: tablet ? 14 : 12.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
              onPressed: () {
                messageController.text = suggestions[index];
                sendMessage(suggestions[index]);
              },
            ),
          );
        },
      ),
    );
  }

  //================================================================
  // MESSAGE INPUT
  //================================================================

  Widget _messageInput(bool tablet) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        tablet ? 30 : 14,
        8,
        tablet ? 30 : 14,
        tablet ? 24 : 14,
      ),
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border(
          top: BorderSide(color: AppColors.border.withOpacity(.35)),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              controller: messageController,
              focusNode: inputFocusNode,
              minLines: 1,
              maxLines: tablet ? 4 : 3,
              textInputAction: TextInputAction.send,
              onSubmitted: (val) => _isTyping ? null : sendMessage(val),
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: tablet ? 16 : 14,
              ),
              decoration: InputDecoration(
                hintText: "Ask Rhea anything...",
                hintStyle: TextStyle(
                  color: AppColors.textDisabled,
                  fontSize: tablet ? 15 : 13,
                ),
                filled: true,
                fillColor: AppColors.surface,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: tablet ? 18 : 14,
                  vertical: tablet ? 15 : 12,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(28),
                  borderSide: const BorderSide(
                    color: AppColors.border,
                    width: 1,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(28),
                  borderSide: const BorderSide(
                    color: AppColors.primary,
                    width: 1.5,
                  ),
                ),
                prefixIcon: IconButton(
                  tooltip: "Attach / Options",
                  icon: Icon(
                    Icons.link_rounded,
                    color: AppColors.textSecondary,
                    size: tablet ? 23 : 20,
                  ),
                  onPressed: _handleAttachment,
                ),
                suffixIcon: IconButton(
                  tooltip: "Scan Food Camera",
                  icon: Icon(
                    Icons.camera_alt_outlined,
                    color: AppColors.primary,
                    size: tablet ? 23 : 20,
                  ),
                  onPressed: _pickAndScanImage,
                ),
              ),
            ),
          ),
          const SizedBox(width: 9),
          Material(
            color: Colors.transparent,
            shape: const CircleBorder(),
            child: InkWell(
              onTap: _isTyping
                  ? null
                  : () => sendMessage(messageController.text),
              customBorder: const CircleBorder(),
              child: Opacity(
                opacity: _isTyping ? 0.5 : 1.0,
                child: Container(
                  width: tablet ? 54 : 48,
                  height: tablet ? 54 : 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, AppColors.primaryDark],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(.30),
                        blurRadius: 12,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.send_rounded,
                    color: Colors.black,
                    size: tablet ? 25 : 22,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
