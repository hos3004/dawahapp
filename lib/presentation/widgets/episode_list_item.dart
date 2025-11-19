import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../data/models/episode_item.dart';

class EpisodeListItem extends StatelessWidget {
  final EpisodeItem episode;
  final VoidCallback onTap;

  const EpisodeListItem({
    super.key,
    required this.episode,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          children: [
            // صورة الحلقة
            SizedBox(
              width: 120,
              child: AspectRatio(
                aspectRatio: 9 / 10,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedNetworkImage(
                    // تأكد من أن episode.image ليس null أو فارغاً
                    imageUrl: episode.image ?? '',
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: Colors.black12,
                      child: const Center(child: CircularProgressIndicator(strokeWidth: 2.0)),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: Colors.black12,
                      child: const Icon(Icons.image_not_supported, color: Colors.black26),
                    ),
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
                    episode.title,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  // إظهار مدة الحلقة فقط إذا كانت موجودة
                  if (episode.runTime != null && episode.runTime!.isNotEmpty)
                    Text(
                      episode.runTime!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.black54,
                      ),
                    ),
                ],
              ),
            ),

            // أيقونة التشغيل
            const Icon(Icons.play_circle_outline, color: Colors.black45, size: 28),
          ],
        ),
      ),
    );
  }
}