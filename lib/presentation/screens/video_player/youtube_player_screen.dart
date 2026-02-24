import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../../../data/models/episode_item.dart';
import '../../../data/repositories/program_repository.dart';
import '../../../data/playback_position_manager.dart';
import '../../widgets/episode_list_item.dart'; // <-- 1. استيراد ويدجت الحلقة
import '../../../core/utils/media_control.dart';
import 'package:flutter/services.dart';

class YouTubePlayerScreen extends StatefulWidget {
  final List<EpisodeItem> episodes;
  final int startIndex;
  final ProgramRepository repository;
  final String initialVideoId; // سنرسل ID الفيديو مباشرة

  const YouTubePlayerScreen({
    super.key,
    required this.episodes,
    required this.startIndex,
    required this.repository,
    required this.initialVideoId,
  });

  @override
  State<YouTubePlayerScreen> createState() => _YouTubePlayerScreenState();
}

class _YouTubePlayerScreenState extends State<YouTubePlayerScreen>
    with WidgetsBindingObserver {
  YoutubePlayerController? _controller;
  late int _currentIndex;
  EpisodeItem? _currentEpisode;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // الاستماع لحالة التطبيق
    WidgetsBinding.instance.addObserver(this);
    // الاستماع لإشارة الإيقاف العامة
    MediaControl.pauseNotifier.addListener(_pausePlayback);

    _currentIndex = widget.startIndex;
    _currentEpisode = widget.episodes[_currentIndex];
    _initializePlayer(widget.initialVideoId);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _pausePlayback();
    }
  }

  void _pausePlayback() {
    if (_controller != null && _controller!.value.isPlaying) {
      _controller!.pause();
    }
  }

  Future<void> _initializePlayer(String videoId,
      {bool isNewEpisode = false}) async {
    if (!mounted) return;

    // إظهار التحميل
    setState(() {
      _isLoading = true;
    });

    // إيقاف المتحكم القديم إذا كان موجوداً
    if (_controller != null && isNewEpisode) {
      _controller!.removeListener(_onPlayerStateChange);
      // لا نستخدم dispose() هنا، سنستخدم load() لتغيير الفيديو
    }

    // جلب الموضع المحفوظ
    final startAt =
        await PlaybackPositionManager.getPosition(_currentEpisode!.id);

    if (_controller == null) {
      // التهيئة لأول مرة
      _controller = YoutubePlayerController(
        initialVideoId: videoId,
        flags: YoutubePlayerFlags(
          autoPlay: true,
          startAt: startAt.inSeconds, // بدء التشغيل من الموضع المحفوظ
        ),
      );
      _controller!.addListener(_onPlayerStateChange);
    } else {
      // تحميل فيديو جديد على نفس المشغل
      _controller!.load(videoId, startAt: startAt.inSeconds);
    }

    setState(() {
      _isLoading = false;
      _currentEpisode = widget.episodes[_currentIndex];
    });
  }

  // مستمع انتهاء الفيديو
  void _onPlayerStateChange() {
    if (_controller != null &&
        _controller!.value.playerState == PlayerState.ended) {
      _controller!.removeListener(_onPlayerStateChange); // منع التكرار
      _playNextEpisode();
    }
  }

  // دالة لاختيار حلقة معينة (من القائمة)
  Future<void> _playEpisodeByIndex(int index) async {
    // 1. حفظ موضع الحلقة القديمة
    await _savePosition();

    // 2. تحديث الاندكس والحلقة
    _currentIndex = index;
    final nextEpisode = widget.episodes[_currentIndex];

    // 3. جلب الرابط والتأكد أنه يوتيوب
    final episodeDetails =
        await widget.repository.getEpisodeDetails(nextEpisode.id);
    final videoUrl = episodeDetails.urlLink;

    if (videoUrl != null &&
        (videoUrl.contains("youtube.com") || videoUrl.contains("youtu.be"))) {
      final nextVideoId = YoutubePlayer.convertUrlToId(videoUrl) ?? '';
      if (nextVideoId.isNotEmpty) {
        // 4. تهيئة المشغل بالفيديو الجديد
        _initializePlayer(nextVideoId, isNewEpisode: true);
      }
    } else {
      // 5. إذا الحلقة التالية ليست يوتيوب، ارجع لصفحة التفاصيل
      // (صفحة التفاصيل ستقوم بإعادة التوجيه للمشغل الصحيح)
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  // دالة تشغيل الحلقة التالية (تلقائياً)
  Future<void> _playNextEpisode() async {
    // مسح الموضع المحفوظ للحلقة التي انتهت
    await PlaybackPositionManager.savePosition(
        _currentEpisode!.id, Duration.zero);

    if (_currentIndex + 1 < widget.episodes.length) {
      // هناك حلقة تالية، قم بتشغيلها
      _playEpisodeByIndex(_currentIndex + 1);
    } else {
      // هذه هي الحلقة الأخيرة
      if (mounted) {
        Navigator.of(context).pop(); // العودة لصفحة التفاصيل
      }
    }
  }

  // حفظ الموضع
  Future<void> _savePosition() async {
    if (_controller != null &&
        _controller!.value.isReady &&
        _currentEpisode != null) {
      final position = _controller!.value.position; // نوع Duration
      if (position > Duration.zero) {
        await PlaybackPositionManager.savePosition(
            _currentEpisode!.id, position);
      }
    }
  }

  @override
  void dispose() {
    _savePosition();
    WidgetsBinding.instance.removeObserver(this);
    MediaControl.pauseNotifier.removeListener(_pausePlayback);

    // إجبار الجهاز على الوضع العمودي عند الخروج
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);

    _controller?.removeListener(_onPlayerStateChange);
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _controller == null) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    return PopScope(
      canPop: false, // Handle pop manually
      onPopInvokedWithResult: (bool didPop, Object? result) async {
        if (didPop) return;

        final navigator = Navigator.of(context);
        await _savePosition();
        // إجبار الجهاز على الوضع العمودي
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.portraitUp,
        ]);
        if (mounted) {
          navigator.pop(result);
        }
      },
      child: YoutubePlayerBuilder(
          player: YoutubePlayer(
            controller: _controller!,
            showVideoProgressIndicator: true,
            progressIndicatorColor: Colors.red,
            progressColors: const ProgressBarColors(
              playedColor: Colors.red,
              handleColor: Colors.redAccent,
            ),
            onReady: () {
              _controller!.addListener(_onPlayerStateChange);
            },
          ),
          builder: (context, player) {
            return Scaffold(
              backgroundColor: Colors.grey[100], // خلفية فاتحة
              body: SafeArea(
                top: true,
                bottom: false,
                child: Column(
                  children: [
                    // --- 1. المشغل بنسبة 16:9 القياسية المريحة للعين ---
                    AspectRatio(
                      aspectRatio: 16 / 9,
                      child: Stack(
                        children: [
                          Container(
                            color: Colors.black, // خلفية سوداء لليوتيوب
                            child: player,
                          ),
                          // زر الرجوع الشفاف
                          Positioned(
                            top: 8,
                            left: 8,
                            child: CircleAvatar(
                              backgroundColor:
                                  Colors.black.withValues(alpha: 0.5),
                              child: IconButton(
                                icon: const Icon(Icons.arrow_back,
                                    color: Colors.white),
                                onPressed: () => Navigator.of(context).pop(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // --- 2. باقى الشاشة (معلومات وقائمة حلقات) بالتمرير الطبيعي ---
                    Expanded(
                      child: Container(
                        color: Colors.white,
                        child: _buildInfoPanel(),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
    );
  }

  // --- ويدجتس بناء الواجهة ---

  // ويدجت بناء لوحة المعلومات (الحلقة الحالية + الحلقات التالية)
  Widget _buildInfoPanel() {
    // حساب عدد الحلقات المتبقية
    final int remainingEpisodesCount =
        widget.episodes.length - _currentIndex - 1;

    return ListView(
      padding: const EdgeInsets.all(20.0),
      children: [
        // 1. عنوان الحلقة الحالية
        Text(
          _currentEpisode?.title ?? "تحميل العنوان...",
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
        ),
        const SizedBox(height: 8),

        // 2. مدة الحلقة
        if (_currentEpisode?.runTime != null &&
            _currentEpisode!.runTime!.isNotEmpty)
          Row(
            children: [
              Icon(Icons.timer_outlined, color: Colors.grey[600], size: 18),
              const SizedBox(width: 8),
              Text(
                _currentEpisode!.runTime!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[800],
                    ),
              ),
            ],
          ),

        const Divider(height: 32),

        // 3. عنوان "الحلقات التالية"
        Text(
          "الحلقات التالية:",
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
        ),
        const SizedBox(height: 16),

        // 4. بناء قائمة الحلقات التالية
        if (remainingEpisodesCount <= 0)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20.0),
            child: Center(
                child: Text("أنت تشاهد الحلقة الأخيرة في الموسم.",
                    style: TextStyle(color: Colors.grey, fontSize: 16))),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics:
                const NeverScrollableScrollPhysics(), // التمرير سيكون للـ ListView الأساسي الأعلى
            itemCount: remainingEpisodesCount,
            itemBuilder: (context, index) {
              // حساب الاندكس الصحيح من القائمة الأصلية
              final int episodeIndex = _currentIndex + 1 + index;
              final episode = widget.episodes[episodeIndex];

              return EpisodeListItem(
                episode: episode,
                onTap: () {
                  // تشغيل الحلقة التي تم الضغط عليها
                  _playEpisodeByIndex(episodeIndex);
                },
              );
            },
          ),
      ],
    );
  }
}
