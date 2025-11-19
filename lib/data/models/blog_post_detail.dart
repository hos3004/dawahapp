import 'package:equatable/equatable.dart';
import '../../utils/common.dart';

/// مودل لبيانات المقال التفصيلية (يحتوي على المحتوى الكامل)
class BlogPostDetail extends Equatable {
  final int id;
  final String title;
  final String content; // <-- المحتوى الكامل للمقال
  final String? imageUrl;
  final String date;

  const BlogPostDetail({
    required this.id,
    required this.title,
    required this.content,
    this.imageUrl,
    required this.date,
  });

  factory BlogPostDetail.fromJson(Map<String, dynamic> json) {
    String? finalImageUrl;

    // نفس منطق جلب الصورة من المودل السابق
    try {
      if (json.containsKey('_embedded') &&
          json['_embedded'] != null &&
          json['_embedded'].containsKey('wp:featuredmedia') &&
          json['_embedded']['wp:featuredmedia'] != null &&
          (json['_embedded']['wp:featuredmedia'] as List).isNotEmpty) {
        final mediaDetails =
            json['_embedded']['wp:featuredmedia'][0]['media_details'];
        if (mediaDetails != null && mediaDetails.containsKey('sizes')) {
          final sizes = mediaDetails['sizes'];
          if (sizes.containsKey('large')) {
            finalImageUrl = sizes['large']['source_url'];
          } else if (sizes.containsKey('medium_large')) {
            finalImageUrl = sizes['medium_large']['source_url'];
          } else if (sizes.containsKey('full')) {
            finalImageUrl = sizes['full']['source_url'];
          }
        }
        if (finalImageUrl == null) {
          finalImageUrl = json['_embedded']['wp:featuredmedia'][0]['source_url'];
        }
      }
    } catch (e) {
      print('Error parsing blog image: $e');
      finalImageUrl = null;
    }

    final String cleanTitle = json['title']?['rendered'] != null
        ? parseHtmlString(json['title']['rendered'])
        : '';
    
    // هنا نجلب المحتوى الكامل بدلاً من المختصر
    final String fullContent = json['content']?['rendered'] != null
        ? json['content']['rendered'] // نبقيه كـ HTML
        : '';
        
    final String formattedDate = json['date'] != null
        ? convertToAgo(json['date'])
        : '';

    return BlogPostDetail(
      id: json['id'] as int,
      title: cleanTitle,
      content: fullContent, // <-- استخدام المحتوى الكامل
      imageUrl: finalImageUrl,
      date: formattedDate,
    );
  }

  @override
  List<Object?> get props => [id, title, content, imageUrl, date];
}