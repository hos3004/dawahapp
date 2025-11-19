import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../../../data/models/episode_item.dart';
import '../../../data/repositories/program_repository.dart';
import '../../../data/playback_position_manager.dart';
import '../../widgets/episode_list_item.dart'; // <-- 1. استيراد ويدجت الحلقة

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

class _YouTubePlayerScreenState extends State<YouTubePlayerScreen> {
  YoutubePlayerController? _controller;
  late int _currentIndex;
  EpisodeItem? _currentEpisode;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.startIndex;
    _currentEpisode = widget.episodes[_currentIndex];
    _initializePlayer(widget.initialVideoId);
  }

  Future<void> _initializePlayer(String videoId, {bool isNewEpisode = false}) async {
    if (!mounted) return;

    // إظهار التحميل
    setState(() { _isLoading = true; });

    // إيقاف المتحكم القديم إذا كان موجوداً
    if (_controller != null && isNewEpisode) {
      _controller!.removeListener(_onPlayerStateChange);
      // لا نستخدم dispose() هنا، سنستخدم load() لتغيير الفيديو
    }

    // جلب الموضع المحفوظ
    final startAt = await PlaybackPositionManager.getPosition(_currentEpisode!.id);

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
    if (_controller != null && _controller!.value.playerState == PlayerState.ended) {
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
    final episodeDetails = await widget.repository.getEpisodeDetails(nextEpisode.id);
    final videoUrl = episodeDetails.urlLink;

    if (videoUrl != null && (videoUrl.contains("youtube.com") || videoUrl.contains("youtu.be"))) {
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
    await PlaybackPositionManager.savePosition(_currentEpisode!.id, Duration.zero);

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
    if (_controller != null && _controller!.value.isReady && _currentEpisode != null) {
      final position = _controller!.value.position; // نوع Duration
      if (position > Duration.zero) {
        await PlaybackPositionManager.savePosition(_currentEpisode!.id, position);
      }
    }
  }

  @override
  void dispose() {
    _savePosition();
    _controller?.removeListener(_onPlayerStateChange);
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        await _savePosition();
        return true;
      },
      child: Scaffold(
        backgroundColor: Colors.grey[100], // خلفية فاتحة
        body: Stack(
          children: [
            // --- 1. المشغل (في الأعلى) ---
            _buildPlayerHeader(),

            // --- 2. لوحة المعلومات القابلة للسحب ---
            DraggableScrollableSheet(
              initialChildSize: 0.55, // ابدأ من 55% من الشاشة
              minChildSize: 0.55,
              maxChildSize: 0.9,
              builder: (context, scrollController) {
                return Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(24.0)),
                    boxShadow: [
                      BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -5)),
                    ],
                  ),
                  child: _buildInfoPanel(scrollController),
                );
              },
            ),

            // --- 3. زر الرجوع ---
            _buildBackButton(),
          ],
        ),
      ),
    );
  }

  // --- ويدجتس بناء الواجهة ---

  // ويدجت لبناء الجزء العلوي (المشغل)
  Widget _buildPlayerHeader() {
    final screenHeight = MediaQuery.of(context).size.height;
    return Container(
      height: screenHeight * 0.45, // 45% من الشاشة
      width: double.infinity,
      color: Colors.black, // خلفية سوداء للمشغل
      child: _buildPlayerWidget(), // بناء المشغل الفعلي
    );
  }

  // ويدجت بناء المشغل (أو التحميل)
  Widget _buildPlayerWidget() {
    if (_isLoading || _controller == null) {
      return const Center(child: CircularProgressIndicator(color: Colors.white));
    }
    // إذا نجح، اعرض المشغل
    return YoutubePlayer(
      controller: _controller!,
      showVideoProgressIndicator: true,
      progressIndicatorColor: Colors.red,
      progressColors: const ProgressBarColors(
        playedColor: Colors.red,
        handleColor: Colors.redAccent,
      ),
      onReady: () {
        // إضافة المستمع بعد أن يصبح المشغل جاهزاً
        _controller!.addListener(_onPlayerStateChange);
      },
    );
  }

  // ويدجت بناء زر الرجوع
  Widget _buildBackButton() {
    return Positioned(
      top: 40,
      left: 16,
      child: SafeArea(
        child: CircleAvatar(
          backgroundColor: Colors.black.withOpacity(0.5),
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
      ),
    );
  }

  // ويدجت بناء لوحة المعلومات (الحلقة الحالية + الحلقات التالية)
  Widget _buildInfoPanel(ScrollController scrollController) {
    // حساب عدد الحلقات المتبقية
    final int remainingEpisodesCount = widget.episodes.length - _currentIndex - 1;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24.0)),
      child: ListView(
        controller: scrollController,
        padding: const EdgeInsets.all(20.0),
        children: [
          // 1. مقبض السحب
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 2. عنوان الحلقة الحالية
          Text(
            _currentEpisode?.title ?? "تحميل العنوان...",
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),

          // 3. مدة الحلقة
          if (_currentEpisode?.runTime != null && _currentEpisode!.runTime!.isNotEmpty)
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

          // 4. عنوان "الحلقات التالية"
          Text(
            "الحلقات التالية:",
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),

          // 5. بناء قائمة الحلقات التالية
          if (remainingEpisodesCount <= 0)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20.0),
              child: Center(child: Text("أنت تشاهد الحلقة الأخيرة في الموسم.")),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
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
      ),
    );
  }
}