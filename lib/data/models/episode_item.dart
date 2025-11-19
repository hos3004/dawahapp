import 'package:equatable/equatable.dart';

class EpisodeItem extends Equatable {
  final int id; // Kotlin Long maps to Dart int
  final String title;
  final String? image; // Nullable String
  final String? postType; // Nullable String
  final String? runTime; // Nullable String
  final String? releaseDate; // Nullable String

  const EpisodeItem({
    required this.id,
    required this.title,
    this.image,
    this.postType,
    this.runTime,
    this.releaseDate,
  });

  // دالة لتحويل JSON القادم من API إلى كائن EpisodeItem
  factory EpisodeItem.fromJson(Map<String, dynamic> json) {
    // حاول قراءة id كـ int أو double ثم تحويله
    num idNum = json['id'] ?? 0;

    return EpisodeItem(
      id: idNum.toInt(), // تحويل num إلى int
      title: json['title'] as String? ?? '',
      image: json['image'] as String?, // قد تكون null
      postType: json['post_type'] as String?,
      runTime: json['run_time'] as String?,
      releaseDate: json['release_date'] as String?,
    );
  }

  @override
  List<Object?> get props => [
    id,
    title,
    image,
    postType,
    runTime,
    releaseDate,
  ];
}