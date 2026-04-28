import 'package:youtube_player_flutter/youtube_player_flutter.dart';

enum TvVideoSourceType { network, youtube }

class TvVideoSource {
  const TvVideoSource._(this.type, this.value);

  final TvVideoSourceType type;
  final String value;

  bool get isYouTube => type == TvVideoSourceType.youtube;
  bool get isNetwork => type == TvVideoSourceType.network;

  factory TvVideoSource.youtube(String videoId) =>
      TvVideoSource._(TvVideoSourceType.youtube, videoId);

  factory TvVideoSource.network(String url) =>
      TvVideoSource._(TvVideoSourceType.network, url);
}

class TvVideoSourceResolver {
  TvVideoSourceResolver._();

  static TvVideoSource? resolve({
    String? urlLink,
    String? embedContent,
    String? choice,
    List<dynamic>? sources,
  }) {
    final preferEmbed = switch (choice) {
      'movie_embed' || 'video_embed' || 'episode_embed' => true,
      _ => false,
    };

    final rawCandidates = <String?>[
      if (preferEmbed) embedContent,
      if (preferEmbed) urlLink,
      if (!preferEmbed) urlLink,
      if (!preferEmbed) embedContent,
      _extractSourceUrl(sources),
    ];

    for (final raw in rawCandidates) {
      final parsed = _parseCandidate(raw);
      if (parsed != null) return parsed;
    }

    return null;
  }

  static TvVideoSource? _parseCandidate(String? raw) {
    if (raw == null) return null;

    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;

    final normalized = _normalizeRawValue(trimmed);
    if (normalized == null || normalized.isEmpty) return null;

    final youtubeId = _extractYouTubeId(normalized);
    if (youtubeId != null) {
      return TvVideoSource.youtube(youtubeId);
    }

    if (normalized.startsWith('http://') || normalized.startsWith('https://')) {
      return TvVideoSource.network(normalized);
    }

    return null;
  }

  static String? _normalizeRawValue(String raw) {
    final iframeSrc = RegExp(
      r'''src=["']([^"']+)["']''',
      caseSensitive: false,
    ).firstMatch(raw)?.group(1);

    final directUrl = RegExp(
      r'''https?:\/\/[^\s"'<>]+''',
      caseSensitive: false,
    ).firstMatch(raw)?.group(0);

    final schemeLessUrl = RegExp(
      r'''\/\/[^\s"'<>]+''',
      caseSensitive: false,
    ).firstMatch(raw)?.group(0);

    final resolved = iframeSrc ?? directUrl ?? schemeLessUrl ?? raw;
    final cleaned = resolved.replaceAll('&amp;', '&').trim();

    if (cleaned.startsWith('//')) {
      return 'https:$cleaned';
    }

    return cleaned;
  }

  static String? _extractSourceUrl(List<dynamic>? sources) {
    if (sources == null || sources.isEmpty) return null;

    for (final source in sources) {
      if (source is! Map) continue;

      for (final key in const ['file', 'src', 'url', 'link']) {
        final candidate = source[key]?.toString();
        if (candidate != null && candidate.trim().isNotEmpty) {
          return candidate;
        }
      }
    }

    return null;
  }

  static String? _extractYouTubeId(String raw) {
    final converted = YoutubePlayer.convertUrlToId(raw);
    if (converted != null && converted.isNotEmpty) return converted;

    final patterns = <RegExp>[
      RegExp(r'youtube\.com/embed/([A-Za-z0-9_-]{11})', caseSensitive: false),
      RegExp(r'youtube\.com/shorts/([A-Za-z0-9_-]{11})', caseSensitive: false),
      RegExp(r'youtu\.be/([A-Za-z0-9_-]{11})', caseSensitive: false),
      RegExp(r'^[A-Za-z0-9_-]{11}$'),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(raw);
      if (match == null) continue;
      final candidate = match.groupCount > 0 ? match.group(1) : match.group(0);
      if (candidate != null && candidate.isNotEmpty) return candidate;
    }

    return null;
  }
}
