import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../design/tv_theme.dart';

class TvYouTubePlayerScreen extends StatefulWidget {
  const TvYouTubePlayerScreen({
    super.key,
    required this.videoId,
    required this.title,
  });

  final String videoId;
  final String title;

  @override
  State<TvYouTubePlayerScreen> createState() => _TvYouTubePlayerScreenState();
}

class _TvYouTubePlayerScreenState extends State<TvYouTubePlayerScreen> {
  late final YoutubePlayerController _controller;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    _controller = YoutubePlayerController(
      initialVideoId: widget.videoId,
      flags: const YoutubePlayerFlags(
        autoPlay: true,
        enableCaption: false,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return YoutubePlayerBuilder(
      player: YoutubePlayer(
        controller: _controller,
        showVideoProgressIndicator: true,
        progressIndicatorColor: TvTheme.accent,
        progressColors: const ProgressBarColors(
          playedColor: TvTheme.accent,
          handleColor: TvTheme.accentLight,
        ),
      ),
      builder: (context, player) {
        return Scaffold(
          backgroundColor: Colors.black,
          body: Stack(
            children: [
              Center(child: player),
              Positioned(
                top: 16,
                right: 16,
                child: SafeArea(
                  child: IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.arrow_back,
                      color: Colors.white,
                      size: 32,
                    ),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.black54,
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 16,
                left: 16,
                child: SafeArea(
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 520),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black45,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: Text(
                      widget.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: TvTheme.fontSizeCaption,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
