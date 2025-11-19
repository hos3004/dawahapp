import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import '../../../data/models/episode_item.dart'; // 1. استيراد مودل الحلقة
import '../../../data/repositories/program_repository.dart'; // 2. استيراد الريبو
import '../../../data/playback_position_manager.dart'; // 3. استيراد مدير الحفظ
import '../../widgets/episode_list_item.dart'; // 4. استيراد ويدجت عنصر الحلقة

class VideoPlayerScreen extends StatefulWidget {
  final List<EpisodeItem> episodes;
  final int startIndex;
  final ProgramRepository repository;

  const VideoPlayerScreen({
    super.key,
    required this.episodes,
    required this.startIndex,
    required this.repository,
  });

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  VideoPlayerController? _videoPlayerController;
  ChewieController? _chewieController;

  late int _currentIndex;
  EpisodeItem? _currentEpisode;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.startIndex;
    _initializeEpisode(_currentIndex);
  }

  // دالة تهيئة الحلقة (الأهم)
  Future<void> _initializeEpisode(int index) async {
    if (!mounted) return;

    // منع النقر المتكرر أثناء التحميل
    if (_isLoading) return;

    // إظهار التحميل
    setState(() {
      _isLoading = true;
      _error = null;
      _currentIndex = index; // تحديث الاندكس
      _currentEpisode = widget.episodes[index]; // تحديث الحلقة الحالية
    });

    // إيقاف المشغل القديم إذا كان موجوداً
    if (_chewieController != null) {
      _chewieController!.dispose(); // (بدون await)
      _chewieController = null;
    }
    if (_videoPlayerController != null) {
      _videoPlayerController!.removeListener(_onVideoEndListener);
      await _videoPlayerController!.dispose();
      _videoPlayerController = null;
    }

    try {
      // أ. جلب رابط الفيديو من الـ API
      final episodeDetails = await widget.repository.getEpisodeDetails(_currentEpisode!.id);
      final videoUrl = episodeDetails.urlLink;

      if (videoUrl == null || videoUrl.isEmpty) {
        throw Exception("رابط الفيديو غير موجود.");
      }

      // ب. جلب الموضع المحفوظ
      final startAt = await PlaybackPositionManager.getPosition(_currentEpisode!.id);

      _videoPlayerController = VideoPlayerController.networkUrl(Uri.parse(videoUrl));
      await _videoPlayerController!.initialize();
      if (!mounted) return;

      _chewieController = ChewieController(
        videoPlayerController: _videoPlayerController!,
        autoPlay: true,
        startAt: startAt, // بدء التشغيل من الموضع المحفوظ
        placeholder: Container(color: Colors.black),
      );

      // إضافة مستمع لـ "التشغيل التلقائي"
      _videoPlayerController!.addListener(_onVideoEndListener);

      setState(() {
        _isLoading = false;
      });

    } catch (e) {
      if (!mounted) return;
      print("Error initializing episode: $e");
      setState(() {
        _isLoading = false;
        _error = "لا يمكن تحميل الفيديو. يرجى المحاولة لاحقاً.";
      });
    }
  }

  // مستمع انتهاء الفيديو
  void _onVideoEndListener() {
    if (_videoPlayerController == null || !_videoPlayerController!.value.isInitialized) {
      return;
    }

    final position = _videoPlayerController!.value.position;
    final duration = _videoPlayerController!.value.duration;

    // التأكد أننا في نهاية الفيديو (مع هامش صغير)
    if (duration - position < const Duration(seconds: 1) &&
        !_videoPlayerController!.value.isPlaying) {
      _videoPlayerController!.removeListener(_onVideoEndListener);
      _playNextEpisode();
    }
  }

  // دالة تشغيل الحلقة التالية
  Future<void> _playNextEpisode() async {
    // مسح الموضع المحفوظ للحلقة التي انتهت
    await PlaybackPositionManager.savePosition(_currentEpisode!.id, Duration.zero);

    if (_currentIndex + 1 < widget.episodes.length) {
      // هناك حلقة تالية، قم بتهيئتها
      _initializeEpisode(_currentIndex + 1);
    } else {
      // هذه هي الحلقة الأخيرة
      print("End of season.");
      if (mounted) {
        Navigator.of(context).pop(); // العودة لصفحة التفاصيل
      }
    }
  }

  // حفظ الموضع عند الخروج
  Future<void> _savePosition() async {
    if (_videoPlayerController != null && _currentEpisode != null && _videoPlayerController!.value.isInitialized) {
      final position = _videoPlayerController!.value.position;
      if (position > Duration.zero) {
        await PlaybackPositionManager.savePosition(_currentEpisode!.id, position);
      }
    }
  }

  @override
  void dispose() {
    _savePosition(); // حفظ الموضع عند الإغلاق
    _videoPlayerController?.removeListener(_onVideoEndListener);
    _videoPlayerController?.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // استخدام WillPopScope لاعتراض زر الرجوع وحفظ الموضع
    return WillPopScope(
      onWillPop: () async {
        await _savePosition();
        return true; // السماح بالرجوع
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
              maxChildSize: 0.9, // اسمح بالسحب حتى 90%
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
    // جعل المشغل يأخذ 45% من ارتفاع الشاشة
    return Container(
      height: screenHeight * 0.45,
      width: double.infinity,
      color: Colors.black, // خلفية سوداء للمشغل
      child: _buildPlayerWidget(), // بناء المشغل الفعلي
    );
  }

  // ويدجت بناء المشغل (أو التحميل أو الخطأ)
  Widget _buildPlayerWidget() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Colors.white));
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70)),
        ),
      );
    }
    // إذا نجح، اعرض المشغل
    return Chewie(
      controller: _chewieController!,
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
                    _initializeEpisode(episodeIndex);
                  },
                );
              },
            ),
        ],
      ),
    );
  }
}