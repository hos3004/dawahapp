import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../data/models/episode_item.dart';
import '../../data/playback_position_manager.dart';

/// بطاقة حلقة مع مؤشر استئناف التشغيل
class EpisodeListItem extends StatefulWidget {
  final EpisodeItem episode;
  final VoidCallback onTap;

  const EpisodeListItem({
    super.key,
    required this.episode,
    required this.onTap,
  });

  @override
  State<EpisodeListItem> createState() => _EpisodeListItemState();
}

class _EpisodeListItemState extends State<EpisodeListItem> {
  Duration _savedPosition = Duration.zero;

  @override
  void initState() {
    super.initState();
    _loadSavedPosition();
  }

  Future<void> _loadSavedPosition() async {
    final pos = await PlaybackPositionManager.getPosition(widget.episode.id);
    if (mounted && pos > Duration.zero) {
      setState(() => _savedPosition = pos);
    }
  }

  bool get _hasResume => _savedPosition > Duration.zero;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: widget.onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          children: [
            // صورة الحلقة مع شريط التقدم
            SizedBox(
              width: 120,
              child: AspectRatio(
                aspectRatio: 9 / 10,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CachedNetworkImage(
                        imageUrl: widget.episode.image ?? '',
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: Colors.black12,
                          child: const Center(
                              child: CircularProgressIndicator(strokeWidth: 2.0)),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: Colors.black12,
                          child: const Icon(Icons.image_not_supported,
                              color: Colors.black26),
                        ),
                      ),

                      // شريط تقدم الاستئناف (أسفل الصورة)
                      if (_hasResume)
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: _ResumeProgressBar(
                            position: _savedPosition,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(width: 12),

            // عنوان الحلقة ومعلوماتها
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.episode.title,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  if (widget.episode.runTime != null &&
                      widget.episode.runTime!.isNotEmpty)
                    Text(
                      widget.episode.runTime!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.black54,
                          ),
                    ),

                  // نص "متابعة من..."
                  if (_hasResume)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        'متابعة من ${_formatDuration(_savedPosition)}',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: Colors.blue[700],
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                ],
              ),
            ),

            // أيقونة التشغيل
            Icon(
              _hasResume ? Icons.play_circle : Icons.play_circle_outline,
              color: _hasResume ? Colors.blue[600] : Colors.black45,
              size: 28,
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    if (h > 0) {
      return '$hس ${m.toString().padLeft(2, '0')}د';
    }
    return '$m:${s.toString().padLeft(2, '0')}';
  }
}

/// شريط تقدم رفيع أسفل صورة الحلقة
class _ResumeProgressBar extends StatelessWidget {
  final Duration position;

  const _ResumeProgressBar({required this.position});

  @override
  Widget build(BuildContext context) {
    // نعرض الشريط بناءً على الوقت المحفوظ نسبةً لمدة الحلقة الاعتيادية (45 دقيقة كقيمة افتراضية)
    // هذا تقدير بصري، لأننا لا نملك مدة الحلقة الفعلية هنا
    const estimatedTotalSeconds = 45 * 60; // 45 دقيقة
    final progress = (position.inSeconds / estimatedTotalSeconds).clamp(0.0, 1.0);

    return Container(
      height: 4,
      color: Colors.black26,
      child: FractionallySizedBox(
        alignment: Alignment.centerRight,
        widthFactor: progress,
        child: Container(color: Colors.blue[600]),
      ),
    );
  }
}