import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../../../../app/theme/app_colors.dart';

class InAppYoutubePlayerScreen extends StatefulWidget {
  final String youtubeUrl;
  final String title;

  const InAppYoutubePlayerScreen({
    super.key,
    required this.youtubeUrl,
    required this.title,
  });

  @override
  State<InAppYoutubePlayerScreen> createState() =>
      _InAppYoutubePlayerScreenState();
}

class _InAppYoutubePlayerScreenState extends State<InAppYoutubePlayerScreen> {
  late YoutubePlayerController _controller;

  @override
  void initState() {
    super.initState();
    // 💡 URL se unique Video ID extract karna
    final videoId = YoutubePlayer.convertUrlToId(widget.youtubeUrl) ?? '';

    _controller = YoutubePlayerController(
      initialVideoId: videoId,
      flags: const YoutubePlayerFlags(
        autoPlay: true,
        mute: false,
        isLive: false,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return YoutubePlayerBuilder(
      player: YoutubePlayer(
        controller: _controller,
        showVideoProgressIndicator: true,
        progressIndicatorColor: AppColors.primary,
        progressColors: const ProgressBarColors(
          playedColor: AppColors.primary,
          handleColor: AppColors.primary,
        ),
      ),
      builder: (context, player) {
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: AppColors.surface,
            title: Text(
              widget.title,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
              ),
            ),
            iconTheme: const IconThemeData(color: AppColors.primary),
          ),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Embedded YouTube Video Player Widget
                player,
              ],
            ),
          ),
        );
      },
    );
  }
}
