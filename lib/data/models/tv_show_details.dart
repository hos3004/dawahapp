/* ==== BEGIN FILE: C:\daawah_app\lib\data\models\tv_show_details.dart ==== */

import 'package:equatable/equatable.dart';
import 'season.dart';

/// نموذج تفاصيل برنامج/مسلسل يعكس استجابة الـ API.
class TvShowDetails extends Equatable {
  /// المعرف (Kotlin Long -> Dart int)
  final int id;

  final String title;
  final String image;
  final String postType;
  final String description;

  /// الأنواع/التصنيفات
  final List<String> genre;

  /// المواسم قد لا تكون متوفرة لكل نوع محتوى
  final List<Season>? seasons;
  final int? seasonsCount;

  /// حقول قد تظهر في الأفلام/الفيديو
  final String? urlLink;
  final String? embedContent;
  /// قد يأتي من episode_choice أو movie_choice أو video_choice
  final String? episodeChoice;

  const TvShowDetails({
    required this.id,
    required this.title,
    required this.image,
    required this.postType,
    required this.description,
    required this.genre,
    this.seasons,
    this.seasonsCount,
    this.urlLink,
    this.embedContent,
    this.episodeChoice,
  });

  /// إنشاء الكائن من JSON مع تحمل اختلافات البنية
  factory TvShowDetails.fromJson(Map<String, dynamic> json) {
    // id قد يأتي كـ int أو double أو String
    final dynamic rawId = json['id'] ?? 0;
    final int parsedId = rawId is num
        ? rawId.toInt()
        : int.tryParse(rawId.toString()) ?? 0;

    // postType قد يظهر باسم مختلف
    final String postType =
    (json['post_type'] ?? json['postType'] ?? '').toString();

    // الوصف قد يكون HTML/نص؛ نتركه كما هو
    final String description = (json['description'] ?? '').toString();

    // العنوان والصورة
    final String title = (json['title'] ?? '').toString();
    final String image = (json['image'] ?? '').toString();

    // معالجة الأنواع: قائمة أو نص مفصول بفواصل
    List<String> genreList = <String>[];
    final dynamic rawGenre = json['genre'];
    if (rawGenre is List) {
      genreList = rawGenre.map((g) => g.toString()).toList();
    } else if (rawGenre is String && rawGenre.trim().isNotEmpty) {
      genreList = rawGenre
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }

    // معالجة المواسم: قد تأتي كـ
    // 1) كائن { data: [...], count: n }
    // 2) قائمة مباشرة [...]
    List<Season>? seasonsList;
    int? count;

    final dynamic rawSeasons = json['seasons'];
    if (rawSeasons is Map<String, dynamic>) {
      final dynamic data = rawSeasons['data'];
      if (data is List) {
        seasonsList =
            data.map((e) => Season.fromJson(e as Map<String, dynamic>)).toList();
      }
      final dynamic c = rawSeasons['count'];
      if (c is num) count = c.toInt();
    } else if (rawSeasons is List) {
      seasonsList =
          rawSeasons.map((e) => Season.fromJson(e as Map<String, dynamic>)).toList();
      count = seasonsList.length;
    }

    // حقول الفيديو/الفيلم
    final String? urlLink = json['url_link'] as String?;
    final String? embedContent = json['embed_content'] as String?;
    final String? episodeChoice = (json['episode_choice'] ??
        json['movie_choice'] ??
        json['video_choice'])
        ?.toString();

    return TvShowDetails(
      id: parsedId,
      title: title,
      image: image,
      postType: postType,
      description: description,
      genre: genreList,
      seasons: seasonsList,
      seasonsCount: count,
      urlLink: urlLink,
      embedContent: embedContent,
      episodeChoice: episodeChoice,
    );
  }

  /// اختياري: تحويل إلى JSON (مفيد للتخزين المؤقت/الاختبارات)
  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'image': image,
    'post_type': postType,
    'description': description,
    'genre': genre,
    if (seasons != null) 'seasons': {'data': seasons!.map((e) => e.toJson()).toList(), 'count': seasonsCount ?? seasons!.length},
    if (seasons == null && seasonsCount != null) 'seasons': {'data': [], 'count': seasonsCount},
    'url_link': urlLink,
    'embed_content': embedContent,
    'episode_choice': episodeChoice,
  };

  @override
  List<Object?> get props => [
    id,
    title,
    image,
    postType,
    description,
    genre,
    seasons,
    seasonsCount,
    urlLink,
    embedContent,
    episodeChoice,
  ];
}

/* ==== END FILE: C:\daawah_app\lib\data\models\tv_show_details.dart ==== */
