import 'package:equatable/equatable.dart';

class EpisodeDetailsData extends Equatable {
  final int id;
  final String title;
  final String? urlLink; // Video URL (nullable)
  final String? embedContent; // Embed code (nullable)
  final String? episodeChoice; // Type indicator (nullable)
  final List<dynamic>? sources; // Other sources (nullable list)

  const EpisodeDetailsData({
    required this.id,
    required this.title,
    this.urlLink,
    this.embedContent,
    this.episodeChoice,
    this.sources,
  });

  // Factory constructor to create an instance from JSON
  factory EpisodeDetailsData.fromJson(Map<String, dynamic> json) {
    // Read 'id' safely as num then convert to int
    num idNum = json['id'] ?? 0;

    return EpisodeDetailsData(
      id: idNum.toInt(),
      title: json['title'] as String? ?? '',
      urlLink: json['url_link'] as String?,
      embedContent: json['embed_content'] as String?,
      episodeChoice: json['episode_choice'] as String?,
      // Read sources as a List<dynamic> if it exists and is a list
      sources: json['sources'] is List ? List<dynamic>.from(json['sources']) : null,
    );
  }

  // Define props for Equatable comparison
  @override
  List<Object?> get props => [
    id,
    title,
    urlLink,
    embedContent,
    episodeChoice,
    sources,
  ];
}