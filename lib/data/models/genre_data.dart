import 'package:equatable/equatable.dart';

class GenreData extends Equatable {
  final int id;
  final String name;
  final String slug;
  final String? genreImage; // رابط صورة التصنيف (قد يكون null)

  const GenreData({
    required this.id,
    required this.name,
    required this.slug,
    this.genreImage,
  });

  factory GenreData.fromJson(Map<String, dynamic> json) {
    // قراءة الصورة بأمان
    String? imageUrl;
    if (json['genre_image'] is String && json['genre_image'].isNotEmpty) {
      imageUrl = json['genre_image'];
    }

    return GenreData(
      // قراءة ID بأمان كـ num ثم تحويله
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name'] as String? ?? 'تصنيف غير مسمى',
      slug: json['slug'] as String? ?? '',
      genreImage: imageUrl,
    );
  }

  @override
  List<Object?> get props => [id, name, slug, genreImage];
}