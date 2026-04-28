import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/episode_item.dart';
import '../../data/models/program_item.dart';
import '../../data/repositories/program_repository.dart';
import '../focus/tv_focus_manager.dart';
import 'tv_player_screen.dart';
import 'tv_youtube_player_screen.dart';
import '../utils/tv_video_source.dart';

/// شاشة تفاصيل البرنامج للتلفزيون بتصميم أفتح وهوية زرقاء أقرب للقنوات العالمية.
class TvDetailsScreen extends StatefulWidget {
  final ProgramItem item;

  const TvDetailsScreen({super.key, required this.item});

  @override
  State<TvDetailsScreen> createState() => _TvDetailsScreenState();
}

class _TvDetailsScreenState extends State<TvDetailsScreen> {
  static const Color _pageBg = Color(0xFFF4F8FF);
  static const Color _pageBgAlt = Color(0xFFE8F1FF);
  static const Color _brandBlue = Color(0xFF165CB5);
  static const Color _brandBlueDark = Color(0xFF0F3F82);
  static const Color _brandBlueSoft = Color(0xFFDCEBFF);
  static const Color _surface = Colors.white;
  static const Color _surfaceAlt = Color(0xFFF8FBFF);
  static const Color _textPrimary = Color(0xFF10233E);
  static const Color _textSecondary = Color(0xFF53657F);
  static const Color _divider = Color(0xFFD7E3F3);
  static const Color _danger = Color(0xFFD93C4C);

  bool _isLoadingDetails = true;
  String? _description;
  String? _coverImage;
  List<EpisodeItem> _episodes = [];
  String? _error;
  String? _playbackError;

  @override
  void initState() {
    super.initState();
    _loadDetails();
  }

  Future<void> _loadDetails() async {
    try {
      final repo = RepositoryProvider.of<ProgramRepository>(
        context,
        listen: false,
      );
      final details = await repo.getProgramDetails(widget.item.id);
      final firstSeason =
          (details.seasons?.isNotEmpty == true) ? details.seasons!.first : null;

      List<EpisodeItem> episodes = [];
      if (firstSeason != null) {
        episodes = await repo.getSeasonEpisodes(widget.item.id, firstSeason.id);
      }

      if (!mounted) return;
      setState(() {
        _description = details.description;
        _coverImage =
            details.image.isNotEmpty ? details.image : widget.item.image;
        _episodes = episodes.reversed.toList();
        _isLoadingDetails = false;
        _playbackError = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'تعذّر تحميل التفاصيل';
        _isLoadingDetails = false;
      });
    }
  }

  Future<void> _playEpisode(EpisodeItem episode, int index) async {
    final repo = RepositoryProvider.of<ProgramRepository>(
      context,
      listen: false,
    );

    try {
      final details = await repo.getEpisodeDetails(episode.id);
      if (!mounted) return;

      final source = TvVideoSourceResolver.resolve(
        urlLink: details.urlLink,
        embedContent: details.embedContent,
        choice: details.episodeChoice,
        sources: details.sources,
      );

      if (source == null) {
        setState(() => _playbackError = 'رابط الحلقة غير متاح حالياً');
        return;
      }

      setState(() => _playbackError = null);

      if (source.isYouTube) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => TvYouTubePlayerScreen(
              videoId: source.value,
              title: episode.title,
            ),
          ),
        );
        return;
      }

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => TvPlayerScreen(
            url: source.value,
            title: episode.title,
            episodeId: episode.id,
            episodeIds: _episodes.map((e) => e.id).toList(),
            currentPosition: index,
            getNextEpisodeUrl: (nextId) async {
              final d = await repo.getEpisodeDetails(nextId);
              final nextSource = TvVideoSourceResolver.resolve(
                urlLink: d.urlLink,
                embedContent: d.embedContent,
                choice: d.episodeChoice,
                sources: d.sources,
              );
              return nextSource?.isNetwork == true ? nextSource!.value : null;
            },
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _playbackError = 'تعذّر تحميل الحلقة');
    }
  }

  @override
  Widget build(BuildContext context) {
    final description = _cleanDescription(_description);

    return Scaffold(
      backgroundColor: _pageBg,
      body: Stack(
        fit: StackFit.expand,
        children: [
          _DecorativeBackground(imageUrl: _coverImage),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(36, 28, 36, 28),
              child: _isLoadingDetails
                  ? const Center(
                      child: CircularProgressIndicator(color: _brandBlue),
                    )
                  : _error != null
                      ? Center(
                          child: Text(
                            _error!,
                            style: const TextStyle(
                              color: _textPrimary,
                              fontSize: 24,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        )
                      : Column(
                          children: [
                            _buildTopBar(),
                            const SizedBox(height: 26),
                            Expanded(
                              child: Row(
                                textDirection: TextDirection.rtl,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(
                                    width: 420,
                                    child: _buildPosterPanel(),
                                  ),
                                  const SizedBox(width: 30),
                                  Expanded(
                                    child: Column(
                                      children: [
                                        _buildOverviewPanel(description),
                                        const SizedBox(height: 24),
                                        Expanded(
                                          child: _buildEpisodesPanel(),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Row(
      children: [
        TvFocusable(
          onSelect: () => Navigator.of(context).pop(),
          focusScale: 1.04,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              color: _surface.withValues(alpha: 0.94),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _divider),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x140F3F82),
                  blurRadius: 18,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.arrow_back_rounded, color: _brandBlueDark, size: 28),
                SizedBox(width: 10),
                Text(
                  'العودة',
                  style: TextStyle(
                    color: _brandBlueDark,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [_brandBlue, _brandBlueDark],
            ),
            borderRadius: BorderRadius.circular(999),
            boxShadow: const [
              BoxShadow(
                color: Color(0x33165CB5),
                blurRadius: 20,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'assets/images/alogo.png',
                height: 38,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.live_tv_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),
              const Text(
                'دعوة للتلفزيون',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPosterPanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.white, _surfaceAlt],
              ),
              borderRadius: BorderRadius.circular(34),
              border: Border.all(color: Colors.white),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x20165CB5),
                  blurRadius: 32,
                  offset: Offset(0, 18),
                ),
              ],
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: _coverImage != null && _coverImage!.isNotEmpty
                      ? Image.network(
                          _coverImage!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _posterPlaceholder(),
                        )
                      : _posterPlaceholder(),
                ),
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      gradient: const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Color(0x190F3F82),
                          Color(0x6610233E),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 18,
                  left: 18,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.auto_awesome_rounded,
                            size: 16, color: _brandBlueDark),
                        SizedBox(width: 8),
                        Text(
                          'محتوى دعوي',
                          style: TextStyle(
                            color: _brandBlueDark,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: _surface.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: _divider),
            boxShadow: const [
              BoxShadow(
                color: Color(0x14165CB5),
                blurRadius: 18,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            children: [
              _InfoStat(
                label: 'الحلقات',
                value: _episodes.length.toString(),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: _InfoStat(
                  label: 'الهوية',
                  value: 'دعوة TV',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOverviewPanel(String description) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(30, 28, 30, 28),
      decoration: BoxDecoration(
        color: _surface.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(34),
        border: Border.all(color: Colors.white),
        boxShadow: const [
          BoxShadow(
            color: Color(0x18165CB5),
            blurRadius: 26,
            offset: Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: _brandBlueSoft,
              borderRadius: BorderRadius.circular(999),
            ),
            child: const Text(
              'برنامج دعوي',
              style: TextStyle(
                color: _brandBlueDark,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            widget.item.title,
            style: const TextStyle(
              color: _textPrimary,
              fontSize: 30,
              fontWeight: FontWeight.w800,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            description,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _textSecondary,
              fontSize: 18,
              height: 1.7,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (_playbackError != null) ...[
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFEEF1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFFFD2D8)),
              ),
              child: Text(
                _playbackError!,
                style: const TextStyle(
                  color: _danger,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEpisodesPanel() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(28, 24, 28, 22),
      decoration: BoxDecoration(
        color: _surface.withValues(alpha: 0.97),
        borderRadius: BorderRadius.circular(34),
        border: Border.all(color: Colors.white),
        boxShadow: const [
          BoxShadow(
            color: Color(0x18165CB5),
            blurRadius: 26,
            offset: Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [_brandBlue, _brandBlueDark],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.playlist_play_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Text(
                  'الحلقات',
                  style: TextStyle(
                    color: _textPrimary,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                '${_episodes.length} حلقة',
                style: const TextStyle(
                  color: _brandBlueDark,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Divider(color: _divider, height: 1),
          const SizedBox(height: 14),
          Expanded(
            child: _episodes.isEmpty
                ? const Center(
                    child: Text(
                      'لا توجد حلقات متاحة',
                      style: TextStyle(
                        color: _textSecondary,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )
                : ListView.separated(
                    itemCount: _episodes.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 14),
                    itemBuilder: (context, index) {
                      final episode = _episodes[index];
                      return _EpisodeTile(
                        episode: episode,
                        index: index,
                        autofocus: index == 0,
                        onTap: () => _playEpisode(episode, index),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _posterPlaceholder() {
    return Container(
      decoration: BoxDecoration(
        color: _brandBlueSoft,
        borderRadius: BorderRadius.circular(24),
      ),
      child: const Center(
        child: Icon(
          Icons.ondemand_video_rounded,
          size: 82,
          color: _brandBlue,
        ),
      ),
    );
  }

  String _cleanDescription(String? raw) {
    if (raw == null || raw.trim().isEmpty) {
      return 'برنامج دعوي يقدّم محتوى نافعًا بروح هادئة وهوية بصرية واضحة للمشاهدة على التلفزيون.';
    }

    return raw
        .replaceAll(RegExp(r'<[^>]*>'), ' ')
        .replaceAll('&nbsp;', ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}

class _DecorativeBackground extends StatelessWidget {
  const _DecorativeBackground({required this.imageUrl});

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                _TvDetailsScreenState._pageBg,
                _TvDetailsScreenState._pageBgAlt,
                Color(0xFFFDFEFF),
              ],
            ),
          ),
        ),
        Positioned(
          top: -120,
          left: -80,
          child: _blurBlob(
            size: 340,
            color: const Color(0x40165CB5),
          ),
        ),
        Positioned(
          bottom: -130,
          right: -40,
          child: _blurBlob(
            size: 320,
            color: const Color(0x301F8CFF),
          ),
        ),
        Positioned(
          top: 90,
          right: 420,
          child: _blurBlob(
            size: 220,
            color: const Color(0x22165CB5),
          ),
        ),
        if (imageUrl != null && imageUrl!.isNotEmpty)
          Positioned(
            top: 0,
            bottom: 0,
            left: 0,
            right: 0,
            child: Opacity(
              opacity: 0.11,
              child: Image.network(
                imageUrl!,
                fit: BoxFit.cover,
                alignment: Alignment.centerRight,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
          ),
      ],
    );
  }

  static Widget _blurBlob({required double size, required Color color}) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: color,
              blurRadius: 120,
              spreadRadius: 40,
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoStat extends StatelessWidget {
  const _InfoStat({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: _TvDetailsScreenState._textSecondary,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: _TvDetailsScreenState._textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _EpisodeTile extends StatelessWidget {
  const _EpisodeTile({
    required this.episode,
    required this.index,
    required this.onTap,
    this.autofocus = false,
  });

  final EpisodeItem episode;
  final int index;
  final VoidCallback onTap;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    return TvFocusable(
      autofocus: autofocus,
      onSelect: onTap,
      focusScale: 1.01,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.centerRight,
            end: Alignment.centerLeft,
            colors: [Colors.white, _TvDetailsScreenState._surfaceAlt],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: _TvDetailsScreenState._divider),
        ),
        child: Row(
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    _TvDetailsScreenState._brandBlue,
                    _TvDetailsScreenState._brandBlueDark,
                  ],
                ),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(
                Icons.play_arrow_rounded,
                color: Colors.white,
                size: 32,
              ),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'الحلقة ${index + 1}',
                    style: const TextStyle(
                      color: _TvDetailsScreenState._brandBlueDark,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    episode.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _TvDetailsScreenState._textPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Container(
              width: 64,
              height: 64,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFFEAF3FF),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Text(
                '${index + 1}',
                style: const TextStyle(
                  color: _TvDetailsScreenState._brandBlueDark,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
