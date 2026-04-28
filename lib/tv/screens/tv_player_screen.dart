import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:better_player_plus/better_player_plus.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../../data/playback_position_manager.dart';
import '../design/tv_theme.dart';

/// مشغل الفيديو للتلفزيون - HLS، MP4، وبث مباشر
class TvPlayerScreen extends StatefulWidget {
  final String url;
  final String title;
  final bool isLive;
  final int? episodeId;
  final List<int>? episodeIds;
  final int? currentPosition;
  final Future<String?> Function(int episodeId)? getNextEpisodeUrl;
  final Widget Function(BuildContext context)? overlayBuilder;

  const TvPlayerScreen({
    super.key,
    required this.url,
    required this.title,
    this.isLive = false,
    this.episodeId,
    this.episodeIds,
    this.currentPosition,
    this.getNextEpisodeUrl,
    this.overlayBuilder,
  });

  @override
  State<TvPlayerScreen> createState() => _TvPlayerScreenState();
}

class _TvPlayerScreenState extends State<TvPlayerScreen> {
  BetterPlayerController? _playerController;
  bool _isLoading = true;
  String? _error;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.currentPosition ?? 0;
    // إجبار Landscape للتلفزيون
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    _initPlayer();
    WakelockPlus.enable();
  }

  Future<void> _initPlayer({String? overrideUrl}) async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      _playerController?.dispose();

      final url = overrideUrl ?? widget.url;

      // استئناف التشغيل من آخر نقطة
      Duration? startAt;
      if (!widget.isLive && widget.episodeId != null) {
        final saved = await PlaybackPositionManager.getPosition(
          widget.episodeId!,
        );
        if (saved.inMilliseconds > 0) {
          startAt = saved;
        }
      }

      final dataSource = BetterPlayerDataSource(
        BetterPlayerDataSourceType.network,
        url,
        liveStream: widget.isLive,
        headers: widget.isLive
            ? const {'Cache-Control': 'no-cache', 'Pragma': 'no-cache'}
            : null,
        notificationConfiguration: const BetterPlayerNotificationConfiguration(
          showNotification: false,
        ),
      );

      final controlsConfiguration = BetterPlayerControlsConfiguration(
        enablePip: false,
        enableFullscreen: false,
        enableMute: true,
        enablePlayPause: true,
        enableProgressText: !widget.isLive,
        showControlsOnInitialize: true,
        enableSkips: !widget.isLive,
        enablePlaybackSpeed: !widget.isLive,
        enableSubtitles: false,
        controlBarColor: Colors.black54,
        iconsColor: Colors.white,
        liveTextColor: Colors.red,
      );

      final controller = BetterPlayerController(
        BetterPlayerConfiguration(
          aspectRatio: 16 / 9,
          fit: BoxFit.contain,
          autoPlay: true,
          looping: false,
          allowedScreenSleep: false,
          expandToFill: true,
          startAt: startAt,
          deviceOrientationsOnFullScreen: const [
            DeviceOrientation.landscapeLeft,
            DeviceOrientation.landscapeRight,
          ],
          deviceOrientationsAfterFullScreen: const [
            DeviceOrientation.landscapeLeft,
            DeviceOrientation.landscapeRight,
          ],
          controlsConfiguration: controlsConfiguration,
          eventListener: _onPlayerEvent,
        ),
      );

      await controller.setupDataSource(dataSource);

      if (!mounted) {
        controller.dispose();
        return;
      }

      setState(() {
        _playerController = controller;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = 'تعذّر تحميل الفيديو. تحقق من الاتصال.';
      });
    }
  }

  void _onPlayerEvent(BetterPlayerEvent event) {
    if (event.betterPlayerEventType == BetterPlayerEventType.finished) {
      _playNext();
    } else if (event.betterPlayerEventType == BetterPlayerEventType.pause ||
        event.betterPlayerEventType == BetterPlayerEventType.exception) {
      _savePosition();
    }
  }

  Future<void> _savePosition() async {
    if (widget.episodeId != null && _playerController != null) {
      final pos = await _playerController!.videoPlayerController?.position;
      if (pos != null) {
        await PlaybackPositionManager.savePosition(
          widget.episodeId!,
          pos,
        );
      }
    }
  }

  void _playNext() async {
    final ids = widget.episodeIds;
    if (ids == null || _currentIndex + 1 >= ids.length) {
      if (mounted) Navigator.of(context).pop();
      return;
    }

    _currentIndex++;
    final nextId = ids[_currentIndex];
    final nextUrl = await widget.getNextEpisodeUrl?.call(nextId);
    if (nextUrl != null && mounted) {
      await _savePosition();
      _initPlayer(overrideUrl: nextUrl);
    }
  }

  @override
  void dispose() {
    _savePosition();
    _playerController?.dispose();
    WakelockPlus.disable();
    // إعادة الشاشة لـ Landscape بعد الخروج
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // المشغل
          if (_playerController != null && !_isLoading && _error == null)
            BetterPlayer(controller: _playerController!),

          // مؤشر تحميل
          if (_isLoading)
            const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: TvTheme.accent),
                  SizedBox(height: 16),
                  Text(
                    'جاري التحميل...',
                    style: TextStyle(color: Colors.white, fontSize: 20),
                  ),
                ],
              ),
            ),

          // رسالة خطأ
          if (_error != null)
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, color: Colors.white, size: 64),
                  const SizedBox(height: 16),
                  Text(
                    _error!,
                    style: const TextStyle(color: Colors.white, fontSize: 20),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: TvTheme.accent,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                    ),
                    onPressed: () => _initPlayer(),
                    icon: const Icon(Icons.refresh),
                    label: const Text('إعادة المحاولة', style: TextStyle(fontSize: 20)),
                  ),
                ],
              ),
            ),

          // زر الرجوع
          Positioned(
            top: 16,
            right: 16,
            child: SafeArea(
              child: IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back, color: Colors.white, size: 32),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.black54,
                ),
              ),
            ),
          ),

          if (widget.overlayBuilder != null) widget.overlayBuilder!(context),
        ],
      ),
    );
  }
}
