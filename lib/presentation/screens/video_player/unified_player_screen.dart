/* ==== BEGIN FILE: C:\daawah_app\lib\presentation\screens\video_player\unified_player_screen.dart ==== */

import 'package:flutter/material.dart';
import 'package:better_player_plus/better_player_plus.dart';
// ❌ (تم حذف import 'package:video_player/video_player.dart'; لأنه غير مطلوب ويسبب تعارض)
import 'package:wakelock_plus/wakelock_plus.dart';
import '../../../data/models/episode_item.dart';
import '../../../data/repositories/program_repository.dart';
import '../../../data/playback_position_manager.dart';
import '../../widgets/episode_list_item.dart';

/// شاشة مشغل فيديو موحدة
/// تستخدم better_player_plus لتشغيل (MP4, HLS, YouTube)
class UnifiedPlayerScreen extends StatefulWidget {
  final List<EpisodeItem> episodes;
  final int startIndex;
  final ProgramRepository repository;

  const UnifiedPlayerScreen({
    super.key,
    required this.episodes,
    required this.startIndex,
    required this.repository,
  });

  @override
  State<UnifiedPlayerScreen> createState() => _UnifiedPlayerScreenState();
}

class _UnifiedPlayerScreenState extends State<UnifiedPlayerScreen> {
  BetterPlayerController? _betterPlayerController;
  final GlobalKey _betterPlayerKey = GlobalKey();

  late int _currentIndex;
  EpisodeItem? _currentEpisode;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    // تفعيل منع قفل الشاشة عند بدء التشغيل
    WakelockPlus.enable();

    _currentIndex = widget.startIndex;
    _initializeEpisode(_currentIndex);
  }

  /// دالة تهيئة الحلقة (الأهم)
  Future<void> _initializeEpisode(int index) async {
    if (!mounted) return;
    // منع النقر المتكرر أثناء التحميل
    if (_isLoading && _betterPlayerController != null) return;

    // إظهار التحميل
    setState(() {
      _isLoading = true;
      _error = null;
      _currentIndex = index;
      _currentEpisode = widget.episodes[index];
    });

    // إيقاف المشغل القديم وحفظ الموضع قبل التخلص منه
    if (_betterPlayerController != null) {
      await _savePosition();
      _betterPlayerController!.removeEventsListener(_onPlayerEvent);

      _betterPlayerController!.dispose();
      _betterPlayerController = null;
    }

    try {
      // أ. جلب رابط الفيديو من الـ API
      final episodeDetails = await widget.repository.getEpisodeDetails(_currentEpisode!.id);

      // تحديد الرابط الصحيح
      String? videoUrl;
      final choice = episodeDetails.episodeChoice;
      if (choice == 'movie_embed' || choice == 'video_embed' || choice == 'episode_embed') {
        videoUrl = episodeDetails.embedContent;
      } else {
        videoUrl = episodeDetails.urlLink; // الافتراضي
      }

      // تحقق من الرابط
      if (videoUrl == null || videoUrl.isEmpty) {
        throw Exception("رابط الفيديو غير موجود.");
      }

      // ب. جلب الموضع المحفوظ
      final startAt = await PlaybackPositionManager.getPosition(_currentEpisode!.id);

      // ج. تهيئة BetterPlayerDataSource
      BetterPlayerDataSource dataSource = BetterPlayerDataSource(
        BetterPlayerDataSourceType.network,
        videoUrl,
        liveStream: videoUrl.contains('.m3u8'), // تحديد إذا كان بثاً مباشراً
      );

      // د. تهيئة BetterPlayerController
      _betterPlayerController = BetterPlayerController(
        BetterPlayerConfiguration(
          autoPlay: true,
          startAt: startAt, // بدء التشغيل من الموضع المحفوظ
          aspectRatio: 16 / 9,
          fit: BoxFit.contain,
          allowedScreenSleep: false,
          controlsConfiguration: const BetterPlayerControlsConfiguration(
            enableQualities: true,
            enableSubtitles: false,
            enablePlaybackSpeed: true,
          ),
        ),
        betterPlayerDataSource: dataSource,
      );

      // إضافة مستمع لـ "التشغيل التلقائي"
      _betterPlayerController!.addEventsListener(_onPlayerEvent);

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = "لا يمكن تحميل الفيديو. يرجى المحاولة لاحقاً.";
      });
    }
  }

  /// مستمع انتهاء الفيديو
  void _onPlayerEvent(BetterPlayerEvent event) {
    if (event.betterPlayerEventType == BetterPlayerEventType.finished) {
      _betterPlayerController!.removeEventsListener(_onPlayerEvent);
      _playNextEpisode();
    }
  }

  /// دالة تشغيل الحلقة التالية
  Future<void> _playNextEpisode() async {
    // مسح الموضع المحفوظ للحلقة التي انتهت
    if (_currentEpisode != null) {
      await PlaybackPositionManager.savePosition(_currentEpisode!.id, Duration.zero);
    }

    if (_currentIndex + 1 < widget.episodes.length) {
      // هناك حلقة تالية، قم بتهيئتها
      _initializeEpisode(_currentIndex + 1);
    } else {
      // هذه هي الحلقة الأخيرة
      if (mounted) {
        Navigator.of(context).pop(); // العودة لصفحة التفاصيل
      }
    }
  }

  /// حفظ الموضع
  Future<void> _savePosition() async {

    // ✅ --- [التصحيح 1] ---
    // إضافة التحقق من أن duration ليست null قبل المقارنة
    final controller = _betterPlayerController?.videoPlayerController;
    if (_currentEpisode != null &&
        controller != null &&
        controller.value.duration != null && // <-- 1. التحقق من null
        controller.value.duration! > Duration.zero) { // <-- 2. استخدام !

      Duration position = controller.value.position;

      if (position > Duration.zero) {
        await PlaybackPositionManager.savePosition(
            _currentEpisode!.id, position);
      }
    }
    // ✅ --- نهاية التصحيح 1 ---
  }

  @override
  void dispose() {
    // إلغاء تفعيل منع قفل الشاشة عند الخروج
    WakelockPlus.disable();

    _betterPlayerController?.removeEventsListener(_onPlayerEvent);
    _betterPlayerController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // استخدام PopScope
    return PopScope(
      canPop: false, // نمنع الخروج التلقائي لنتمكن من حفظ الموضع
      onPopInvoked: (bool didPop) {
        if (didPop) {
          return; // إذا تم الخروج بالفعل
        }

        // إصلاح خطأ "BuildContext across async gaps"
        final navigator = Navigator.of(context);
        _savePosition().then((_) {
          if (mounted) {
            navigator.pop();
          }
        });
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
    if (_isLoading || _betterPlayerController == null) {
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
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: BetterPlayer(
        key: _betterPlayerKey,
        controller: _betterPlayerController!,
      ),
    );
  }

  // ويدجت بناء زر الرجوع
  Widget _buildBackButton() {
    return Positioned(
      top: 40,
      left: 16,
      child: SafeArea(
        child: CircleAvatar(
          // استخدام .withAlpha(128) بدلاً من .withOpacity(0.5)
          backgroundColor: Colors.black.withAlpha(128),
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () {
              // إصلاح خطأ "BuildContext across async gaps"
              final navigator = Navigator.of(context);
              _savePosition().then((_) {
                if (mounted) {
                  navigator.pop();
                }
              });
            },
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

          // 4. عنوان "الحلقات التالية" (فقط إذا كانت القائمة تحتوي على أكثر من عنصر)
          if (widget.episodes.length > 1)
            Text(
              "الحلقات التالية:",
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          if (widget.episodes.length > 1)
            const SizedBox(height: 8),

          // 5. بناء قائمة الحلقات التالية
          if (remainingEpisodesCount <= 0 && widget.episodes.length > 1)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20.0),
              child: Center(child: Text("أنت تشاهد الحلقة الأخيرة في الموسم.")),
            )
          else if (widget.episodes.length > 1)
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
            )
          else
          // (لا تعرض شيئاً إذا كان فيلماً واحداً)
            const SizedBox.shrink(),
        ],
      ),
    );
  }
}

/* ==== END FILE: C:\daawah_app\lib\presentation\screens\video_player\unified_player_screen.dart ==== */