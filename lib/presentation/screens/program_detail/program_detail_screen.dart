/* ==== BEGIN FILE: C:\daawah_app\lib\presentation\screens\program_detail\program_detail_screen.dart ==== */

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart'; // ✅ 1. استيراد ضروري لـ convertUrlToId
import '../../../data/models/episode_item.dart';
import '../../../data/models/season.dart';
import '../../../data/models/tv_show_details.dart';
import '../../../data/repositories/program_repository.dart';
import '../../widgets/expandable_description.dart';
import '../../widgets/episode_list_item.dart';
// ✅ 2. استيراد كلا المشغلين
import '../../screens/video_player/unified_player_screen.dart';
import '../../screens/video_player/youtube_player_screen.dart';

class ProgramDetailScreen extends StatefulWidget {
  final int programId;
  final String? postType;

  const ProgramDetailScreen({
    super.key,
    required this.programId,
    this.postType = "tv_show",
  });

  @override
  State<ProgramDetailScreen> createState() => _ProgramDetailScreenState();
}

class _ProgramDetailScreenState extends State<ProgramDetailScreen> {
  final ProgramRepository _repository = ProgramRepository();
  TvShowDetails? _details;
  List<EpisodeItem> _episodes = [];
  Season? _selectedSeason;
  bool _isLoadingDetails = true;
  bool _isLoadingEpisodes = false;
  String? _error;
  bool _isStartingPlayback = false;

  @override
  void initState() {
    super.initState();
    _fetchProgramDetails();
  }

  Future<void> _fetchProgramDetails() async {
    if (!mounted) return;
    setState(() {
      _isLoadingDetails = true;
      _error = null;
    });
    try {
      TvShowDetails details;
      switch (widget.postType) {
        case "movie":
          details = await _repository.getMovieDetails(widget.programId);
          break;
        case "video":
          details = await _repository.getVideoDetails(widget.programId);
          break;
        case "tv_show":
        default:
          details = await _repository.getProgramDetails(widget.programId);
          break;
      }

      if (!mounted) return;
      setState(() {
        _details = details;
        _isLoadingDetails = false;
      });

      if (details.seasons != null && details.seasons!.isNotEmpty) {
        _selectSeason(details.seasons!.first);
      } else {
        setState(() {
          _isLoadingEpisodes = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = "فشل تحميل تفاصيل البرنامج: ${e.toString()}";
        _isLoadingDetails = false;
      });
    }
  }

  Future<void> _selectSeason(Season season) async {
    if (!mounted) return;
    setState(() {
      _selectedSeason = season;
      _isLoadingEpisodes = true;
      _episodes = [];
    });

    try {
      final episodes =
          await _repository.getSeasonEpisodes(widget.programId, season.id);
      if (!mounted) return;
      setState(() {
        _episodes = episodes.reversed.toList();
        _isLoadingEpisodes = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = "فشل تحميل الحلقات: ${e.toString()}";
        _isLoadingEpisodes = false;
      });
    }
  }

  // ✅ --- [التعديل 3] ---
  // تعديل دالة تشغيل الحلقات لتصبح "الموجّه"
  Future<void> _playEpisode(EpisodeItem episode, int index) async {
    if (_isLoadingDetails) return;

    setState(() {
      _isStartingPlayback = true;
    });

    try {
      // 1. جلب الرابط من الـ API
      final episodeDetails = await _repository.getEpisodeDetails(episode.id);

      // 2. تحديد الرابط الصحيح (URL أو Embed)
      String? videoUrl;
      final choice = episodeDetails.episodeChoice;
      if (choice == 'movie_embed' ||
          choice == 'video_embed' ||
          choice == 'episode_embed') {
        videoUrl = episodeDetails.embedContent;
      } else {
        videoUrl = episodeDetails.urlLink; // الافتراضي
      }

      if (videoUrl == null || videoUrl.isEmpty) {
        throw Exception("رابط الفيديو غير موجود.");
      }

      if (!mounted) return;

      // 3. الفحص الذكي (يوتيوب أم رابط مباشر)
      if (videoUrl.contains("youtube.com") || videoUrl.contains("youtu.be")) {
        // --- إنه رابط يوتيوب ---
        final videoId = YoutubePlayer.convertUrlToId(videoUrl);
        if (videoId == null || videoId.isEmpty) {
          throw Exception("رابط اليوتيوب غير صالح.");
        }

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => YouTubePlayerScreen(
              episodes: _episodes, // إرسال القائمة الكاملة
              startIndex: index,
              repository: _repository,
              initialVideoId: videoId,
            ),
          ),
        );
      } else {
        // --- إنه رابط مباشر (MP4/M3U8) ---
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => UnifiedPlayerScreen(
              episodes: _episodes, // إرسال القائمة الكاملة
              startIndex: index,
              repository: _repository,
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("خطأ في تشغيل الفيديو: ${e.toString()}")),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isStartingPlayback = false;
        });
      }
    }
  }
  // ✅ --- نهاية التعديل 3 ---

  // ✅ --- [التعديل 4] ---
  // تعديل دالة تشغيل الفيلم/الفيديو لتصبح "الموجّه"
  Future<void> _playDirectContent(TvShowDetails details) async {
    if (_isLoadingDetails) return;

    setState(() {
      _isStartingPlayback = true;
    });

    try {
      // 1. تحديد الرابط الصحيح (URL أو Embed)
      String? videoUrl;
      final choice = details.episodeChoice;

      if (choice == 'movie_embed' ||
          choice == 'video_embed' ||
          choice == 'episode_embed') {
        videoUrl = details.embedContent;
      } else {
        videoUrl = details.urlLink; // الافتراضي
      }

      if (videoUrl == null || videoUrl.isEmpty) {
        throw Exception("رابط الفيديو غير موجود.");
      }

      if (!mounted) return;

      // 2. الفحص الذكي (يوتيوب أم رابط مباشر)
      if (videoUrl.contains("youtube.com") || videoUrl.contains("youtu.be")) {
        // --- إنه رابط يوتيوب ---
        final videoId = YoutubePlayer.convertUrlToId(videoUrl);
        if (videoId == null || videoId.isEmpty) {
          throw Exception("رابط اليوتيوب غير صالح.");
        }

        // إنشاء "قائمة تشغيل مزيفة" تحتوي على الفيلم فقط
        final fakeEpisode = EpisodeItem(
            id: details.id, title: details.title, image: details.image);

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => YouTubePlayerScreen(
              episodes: [fakeEpisode], // قائمة من عنصر واحد
              startIndex: 0,
              repository: _repository,
              initialVideoId: videoId,
            ),
          ),
        );
      } else {
        // --- إنه رابط مباشر (MP4/M3U8) ---
        // إنشاء "قائمة تشغيل مزيفة"
        final fakeEpisode = EpisodeItem(
            id: details.id, title: details.title, image: details.image);

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => UnifiedPlayerScreen(
              episodes: [fakeEpisode], // قائمة من عنصر واحد
              startIndex: 0,
              repository: _repository,
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("خطأ في تشغيل الفيديو: ${e.toString()}")),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isStartingPlayback = false;
        });
      }
    }
  }
  // ✅ --- نهاية التعديل 4 ---

  // دالة زر التشغيل الكبير (تبقى كما هي - المنطق صحيح)
  Future<void> _onPlayTapped() async {
    if (widget.postType == "movie" || widget.postType == "video") {
      if (_details != null) {
        _playDirectContent(_details!);
      }
    } else {
      if (_isLoadingEpisodes || _episodes.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("لا توجد حلقات متاحة للتشغيل.")),
        );
        return;
      }
      _playEpisode(_episodes.first, 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: _buildBody(),
    );
  }

  // (باقي كود بناء الواجهة UI يبقى كما هو - لا حاجة لتغييره)
  // ... _buildBody()
  // ... _buildErrorWidget()
  // ... _buildHeaderImageWithPlayButton()
  // ... _buildInfoPanel()
  // ... _buildSeasonSelector()
  // ... _buildEpisodeList()

  // (لقد نسخت الكود المتبقي كما هو لضمان اكتمال الملف)

  Widget _buildBody() {
    if (_isLoadingDetails) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null && _details == null) {
      return _buildErrorWidget(_error!);
    }
    if (_details == null) {
      return const Center(child: Text("لم يتم العثور على البرنامج."));
    }

    return CustomScrollView(
      slivers: [
        // 1. صورة الغلاف العلوية كـ AppBar
        SliverAppBar(
          expandedHeight:
              MediaQuery.of(context).size.height * 0.70, // 70% من الشاشة
          pinned: true,
          stretch: true,
          backgroundColor: Colors.black,
          leading: Padding(
            padding: const EdgeInsets.all(8.0),
            child: CircleAvatar(
              backgroundColor: Colors.black.withValues(alpha: 0.5),
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ),
          flexibleSpace: FlexibleSpaceBar(
            stretchModes: const [StretchMode.zoomBackground],
            background: Stack(
              fit: StackFit.expand,
              children: [
                CachedNetworkImage(
                  imageUrl: _details!.image,
                  fit: BoxFit.cover,
                  placeholder: (context, url) =>
                      Container(color: Colors.black12),
                  errorWidget: (context, url, error) => Container(
                    color: Colors.black12,
                    child: const Icon(Icons.error, color: Colors.black26),
                  ),
                ),
                // تدرج لوني مكثف في الأسفل لضمان قراءة النصوص
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.black.withValues(alpha: 0.9),
                        Colors.black.withValues(alpha: 0.3),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.4, 1.0],
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                    ),
                  ),
                ),
                // زر التشغيل الكبير متمركز في النصف السفلي
                Positioned(
                  bottom: 30, // مرفوع قليلاً فوق الحواف
                  left: 0,
                  right: 0,
                  child: Center(
                    child: _isStartingPlayback
                        ? const SizedBox(
                            width: 60,
                            height: 60,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 3,
                            ),
                          )
                        : InkWell(
                            onTap: _onPlayTapped,
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.red[600], // لون لافت للانتباه
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.red.withValues(alpha: 0.5),
                                    blurRadius: 15,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.play_arrow_rounded,
                                color: Colors.white,
                                size: 45,
                              ),
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // 2. المحتوى والحلقات
        SliverToBoxAdapter(
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoSection(_details!),
                if (_details!.seasons != null &&
                    _details!.seasons!.isNotEmpty) ...[
                  const Divider(height: 1),
                  _buildSeasonChips(_details!.seasons!),
                  _buildEpisodeList(),
                ],
                // مسافة إضافية في الأسفل للراحة أثناء التمرير الممتد
                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorWidget(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(error,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.red[300])),
          ),
          ElevatedButton(
            onPressed: _fetchProgramDetails, // إعادة المحاولة
            child: const Text('إعادة المحاولة'),
          )
        ],
      ),
    );
  }

  Widget _buildInfoSection(TvShowDetails details) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  details.title,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                ),
              ),
              IconButton(
                icon: Icon(Icons.favorite_border,
                    color: Colors.red[400], size: 28),
                onPressed: () {},
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            "${details.genre.join(' • ')}  ${(details.seasonsCount ?? 0) > 0 ? '•  ${details.seasonsCount} مواسم' : ''}",
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[800],
                ),
          ),
          const SizedBox(height: 16),
          ExpandableDescription(text: details.description),
        ],
      ),
    );
  }

  Widget _buildSeasonChips(List<Season> seasons) {
    if (seasons.isEmpty) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Text(
              "المواسم",
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 40,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              scrollDirection: Axis.horizontal,
              itemCount: seasons.length,
              separatorBuilder: (context, index) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final season = seasons[index];
                final isSelected = _selectedSeason?.id == season.id;
                return ActionChip(
                  backgroundColor: isSelected
                      ? Theme.of(context).primaryColor
                      : Colors.grey[200],
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : Colors.black87,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  ),
                  label: Text(season.name),
                  onPressed: () {
                    if (!isSelected) {
                      _selectSeason(season);
                    }
                  },
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  side: BorderSide.none,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEpisodeList() {
    if (_isLoadingEpisodes) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40.0),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null && _episodes.isEmpty) {
      return Center(
          child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Text(_error!),
      ));
    }

    if (_episodes.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 40.0),
          child: Text("لا توجد حلقات في هذا الموسم."),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics:
          const NeverScrollableScrollPhysics(), // لأن الصفحة كلها قابلة للتمرير
      padding: const EdgeInsets.only(top: 8.0),
      itemCount: _episodes.length,
      itemBuilder: (context, index) {
        final episode = _episodes[index];
        return EpisodeListItem(
          episode: episode,
          onTap: () {
            _playEpisode(episode, index);
          },
        );
      },
    );
  }
}

/* ==== END FILE: C:\daawah_app\lib\presentation\screens\program_detail\program_detail_screen.dart ==== */