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
      final episodes = await _repository.getSeasonEpisodes(widget.programId, season.id);
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
      if (choice == 'movie_embed' || choice == 'video_embed' || choice == 'episode_embed') {
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

      if (choice == 'movie_embed' || choice == 'video_embed' || choice == 'episode_embed') {
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
        final fakeEpisode = EpisodeItem(id: details.id, title: details.title, image: details.image);

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
        final fakeEpisode = EpisodeItem(id: details.id, title: details.title, image: details.image);

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

    return Stack(
      children: [
        _buildHeaderImageWithPlayButton(_details!),
        DraggableScrollableSheet(
          initialChildSize: 0.45,
          minChildSize: 0.45,
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
              child: _buildInfoPanel(scrollController, _details!),
            );
          },
        ),
        Positioned(
          top: 40,
          left: 16,
          child: SafeArea(
            child: CircleAvatar(
              backgroundColor: Colors.black.withAlpha(128),
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
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
            child: Text(error, textAlign: TextAlign.center, style: TextStyle(color: Colors.red[300])),
          ),
          ElevatedButton(
            onPressed: _fetchProgramDetails, // إعادة المحاولة
            child: const Text('Retry'),
          )
        ],
      ),
    );
  }

  Widget _buildHeaderImageWithPlayButton(TvShowDetails details) {
    final screenHeight = MediaQuery.of(context).size.height;
    return SizedBox(
      height: screenHeight * 0.6, // 60% من الشاشة
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CachedNetworkImage(
            imageUrl: details.image,
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(color: Colors.black12),
            errorWidget: (context, url, error) => Container(
              color: Colors.black12,
              child: const Icon(Icons.error, color: Colors.black26),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.black.withOpacity(0.5), Colors.transparent],
                begin: Alignment.bottomCenter,
                end: Alignment.center,
              ),
            ),
          ),
          Center(
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
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Icon(
                  Icons.play_arrow,
                  color: Colors.red[600],
                  size: 45,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoPanel(ScrollController scrollController, TvShowDetails details) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24.0)),
      child: ListView(
        controller: scrollController,
        padding: const EdgeInsets.all(20.0),
        children: [
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
          const SizedBox(height: 6),
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
                icon: Icon(Icons.favorite_border, color: Colors.red[400], size: 28),
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
          const Divider(height: 5),
          const SizedBox(height: 5),
          ExpandableDescription(text: details.description),
          if (details.seasons != null && details.seasons!.isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Divider(height: 5),
                const SizedBox(height: 0),
                _buildEpisodeList(),
              ],
            )
        ],
      ),
    );
  }

  Widget _buildSeasonSelector(List<Season> seasons) {
    if (seasons.isEmpty) {
      return const Text("لا توجد مواسم متاحة.");
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "الموسم:",
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12.0),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<Season>(
              isExpanded: true,
              value: _selectedSeason,
              icon: const Icon(Icons.keyboard_arrow_down),
              items: seasons.map((season) {
                return DropdownMenuItem<Season>(
                  value: season,
                  child: Text(season.name),
                );
              }).toList(),
              onChanged: (Season? newSeason) {
                if (newSeason != null) {
                  _selectSeason(newSeason);
                }
              },
            ),
          ),
        ),
      ],
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
      return Center(child: Text(_error!));
    }

    if (_episodes.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 20.0),
          child: Text("لا توجد حلقات في هذا الموسم."),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
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