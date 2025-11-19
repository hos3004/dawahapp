import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../../../data/models/tiktok_video_item.dart';
import '../../../services/share_service.dart';
import '../../bloc/tiktok_feed/tiktok_feed_bloc.dart';
import '../../bloc/tiktok_feed/tiktok_feed_event.dart';
import 'dart:math';

// --- ⚠️ [إضافة 1/3]: استيراد خدمة سجل المشاهدة
import '../../../data/watch_history_service.dart';
// ------------------------------------

/// ويدجت يمثل صفحة فيديو واحدة في الفيد
class TikTokVideoPage extends StatefulWidget {
  final TikTokVideoItem videoItem;
  final bool isActive;
  final bool isScreenActive;
  final VoidCallback onVideoEnded;
  final VoidCallback onToggleAutoScroll;
  final bool isAutoScrollEnabled;

  const TikTokVideoPage({
    super.key,
    required this.videoItem,
    required this.isActive,
    required this.isScreenActive,
    required this.onVideoEnded,
    required this.onToggleAutoScroll,
    required this.isAutoScrollEnabled,
  });

  @override
  State<TikTokVideoPage> createState() => _TikTokVideoPageState();
}

class _TikTokVideoPageState extends State<TikTokVideoPage>
    with AutomaticKeepAliveClientMixin<TikTokVideoPage> {

  @override
  bool get wantKeepAlive => true; // تفعيل الحفاظ على الصفحة

  YoutubePlayerController? _controller;
  String? _videoId;
  bool _isPlayerReady = false;

  bool _isLiked = false;
  int _likeCount = 0;
  bool _isLikeAnimating = false;

  @override
  void initState() {
    super.initState();
    _videoId = YoutubePlayer.convertUrlToId(widget.videoItem.youtubeUrl);

    _likeCount = Random().nextInt(651) + 200;

    if (_videoId != null && _videoId!.isNotEmpty) {
      _controller = YoutubePlayerController(
        initialVideoId: _videoId!,
        flags: YoutubePlayerFlags(
          autoPlay: widget.isActive && widget.isScreenActive,
          controlsVisibleAtStart: false,
          hideControls: true,
          loop: false,
          isLive: false,
          forceHD: false,
          enableCaption: false,
          useHybridComposition: true,
        ),
      )..addListener(_playerListener);
    }
  }

  void _playerListener() {
    if (_isPlayerReady && mounted && !_controller!.value.isFullScreen) {
      if (mounted) {
        setState(() { /* ... */ });
      }
      if (_controller!.value.playerState == PlayerState.ended) {

        // --- ⚠️ [إضافة 2/3]: تسجيل المشاهدة عند انتهاء الفيديو
        WatchHistoryService.addVideoToHistory(widget.videoItem.id);
        // ------------------------------------

        widget.onVideoEnded();
      }
    }
  }

  @override
  void didUpdateWidget(covariant TikTokVideoPage oldWidget) {
    super.didUpdateWidget(oldWidget);

    final bool shouldBePlaying = widget.isActive && widget.isScreenActive;
    final bool wasPlaying = oldWidget.isActive && oldWidget.isScreenActive;

    if (shouldBePlaying != wasPlaying) {
      if (shouldBePlaying) {
        _controller?.play();
      } else {
        _controller?.pause();

        // --- ⚠️ [إضافة 3/3]: تسجيل المشاهدة عند الانتقال عن الفيديو
        // (كما طلبت)
        if (wasPlaying) {
          WatchHistoryService.addVideoToHistory(oldWidget.videoItem.id);
        }
        // ------------------------------------
      }
    }
  }

  @override
  void dispose() {
    _controller?.removeListener(_playerListener);
    _controller?.dispose();
    super.dispose();
  }

  /// تبديل الإيقاف المؤقت
  void _togglePlayPause() {
    if (_controller == null || !_isPlayerReady) return;

    if (_controller!.value.isPlaying) {
      _controller!.pause();
    } else {
      _controller!.play();
    }
  }

  /// استدعاء خدمة المشاركة
  void _onSharePressed() {
    ShareService.shareVideo(
      widget.videoItem.title,
      widget.videoItem.youtubeUrl,
    );
  }

  /// دالة "الإعجاب" الموحدة
  void _toggleLike() {
    // نفذ فقط إذا لم يكن قد تم الإعجاب به بالفعل
    if (_isLiked) return;

    setState(() {
      _isLiked = true;
      _likeCount++;
      _isLikeAnimating = true;
    });

    // إخفاء القلب الكبير بعد فترة
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        setState(() {
          _isLikeAnimating = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // ضروري لـ KeepAlive

    if (_controller == null) {
      return _buildErrorPage("رابط الفيديو غير صالح");
    }

    final progressColor = Theme.of(context).primaryColor;

    // (الكود المتبقي في build() ودوال الـ build المساعدة لم يتغير)
    // ...
    return Stack(
      fit: StackFit.expand,
      children: [
        // 1. مشغل الفيديو
        Container(
          color: Colors.black,
          child: YoutubePlayer(
            controller: _controller!,
            showVideoProgressIndicator: true,
            progressIndicatorColor: progressColor,
            progressColors: ProgressBarColors(
              playedColor: progressColor,
              handleColor: Colors.white, // (تم التعديل بناءً على الكود المرسل)
              bufferedColor: Colors.white24,
              backgroundColor: Colors.white12,
            ),
            onReady: () {
              setState(() {
                _isPlayerReady = true;
              });
              final shouldBePlaying =
                  widget.isActive && widget.isScreenActive;
              if (shouldBePlaying) {
                _controller!.play();
              } else {
                _controller!.pause();
              }
            },
            onEnded: (meta) {
              // --- ⚠️ [إضافة 2/3 مكرر]: تسجيل المشاهدة عند انتهاء الفيديو
              // (موجودة في الكود الذي أرسلته، سنبقي عليها)
              WatchHistoryService.addVideoToHistory(widget.videoItem.id);
              // ------------------------------------
              widget.onVideoEnded();
            },
          ),
        ),

        // --- 2. طبقة النقر (للإيقاف المؤقت والنقر المزدوج) ---
        GestureDetector(
          onTap: _togglePlayPause,
          onDoubleTap: _toggleLike,
          behavior: HitTestBehavior.opaque,
          child: Stack(
            children: [
              // أيقونة "التشغيل" (عند الإيقاف المؤقت)
              AnimatedOpacity(
                opacity: (_controller != null && _controller!.value.isReady && !_controller!.value.isPlaying)
                    ? 0.7
                    : 0.0,
                duration: const Duration(milliseconds: 300),
                child: const Center(
                  child: Icon(
                    Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 60.0,
                  ),
                ),
              ),

              // مؤثر "القلب" (عند النقر المزدوج)
              AnimatedOpacity(
                opacity: _isLikeAnimating ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 200),
                child: Center(
                  child: AnimatedScale(
                    scale: _isLikeAnimating ? 1.0 : 0.5,
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.elasticOut,
                    child: const Icon(
                      Icons.favorite,
                      color: Colors.white,
                      size: 80.0,
                      shadows: [
                        Shadow(blurRadius: 10.0, color: Colors.black45)
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // 3. طبقة المعلومات (العنوان والهاشتاجات)
        _buildVideoTitleAndTags(),

        // 4. الشريط الجانبي (المشاركة، عشوائي، لوجو...)
        _buildSocialSidebar(),
      ],
    );
  }

  /// ويدجت لعرض عنوان الفيديو والهاشتاجات في الأسفل
  Widget _buildVideoTitleAndTags() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.fromLTRB(60, 16, 16, 32),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [ Colors.transparent, Colors.black.withOpacity(0.6) ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(widget.videoItem.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 16.0, fontWeight: FontWeight.bold, shadows: [Shadow(blurRadius: 4.0, color: Colors.black54)])),
            if (widget.videoItem.tags.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Wrap(
                  spacing: 8.0,
                  runSpacing: 4.0,
                  children: widget.videoItem.tags.map((tag) {
                    return Text('#$tag', style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 13.0, fontWeight: FontWeight.w500));
                  }).toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// ويدجت لشريط التفاعل الجانبي
  Widget _buildSocialSidebar() {
    return Positioned(
      bottom: 90,
      right: 10,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // --- 1. اللوجو (كما في الصورة) ---
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2.0),
              image: const DecorationImage(
                image: AssetImage('assets/images/app_icon1.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),

          const SizedBox(height: 24),

          // --- 2. زر الإعجاب (القلب) ---
          _buildSidebarButton(
            icon: _isLiked ? Icons.favorite : Icons.favorite_border,
            color: _isLiked ? Colors.red : Colors.white,
            text: _likeCount.toString(),
            onPressed: _toggleLike,
          ),

          const SizedBox(height: 24),

          // --- 3. زر الترتيب العشوائي (Shuffle) ---
          _buildSidebarButton(
            icon: Icons.shuffle,
            onPressed: () {
              context.read<TikTokFeedBloc>().add(ShuffleTikTokFeed());
            },
          ),

          const SizedBox(height: 24),

          // --- 4. زر المشاركة ---
          _buildSidebarButton(
            icon: Icons.share,
            onPressed: _onSharePressed,
          ),

          const SizedBox(height: 24),

          // --- 5. زر التمرير التلقائي (Auto-Scroll) ---
          _buildSidebarButton(
            icon: widget.isAutoScrollEnabled
                ? Icons.playlist_play_rounded
                : Icons.skip_next_rounded,
            color: widget.isAutoScrollEnabled
                ? Theme.of(context).primaryColor
                : Colors.white,
            onPressed: widget.onToggleAutoScroll,
          ),
        ],
      ),
    );
  }

  /// ويدجت مساعد لبناء أيقونة الشريط الجانبي
  Widget _buildSidebarButton({
    required IconData icon,
    required VoidCallback onPressed,
    Color color = Colors.white,
    String? text,
  }) {
    return InkWell(
      onTap: onPressed,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: color,
            size: 32.0,
            shadows: const [
              Shadow(blurRadius: 4.0, color: Colors.black54),
            ],
          ),
          if (text != null)
            Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Text(
                text,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(blurRadius: 2.0, color: Colors.black54)
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }


  /// ويدجت لعرض صفحة الخطأ
  Widget _buildErrorPage(String message) {
    return Container(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 50),
            const SizedBox(height: 16),
            Text(message, style: const TextStyle(color: Colors.white70), textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(widget.videoItem.youtubeUrl, style: const TextStyle(color: Colors.white38, fontSize: 12), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}