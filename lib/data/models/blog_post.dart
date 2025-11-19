// [ ملف جديد: lib/data/models/blog_post.dart ]

import 'package:equatable/equatable.dart';
import '../../utils/common.dart'; //
import 'package:html/parser.dart'; //

/// مودل بسيط لبيانات المقال
class BlogPost extends Equatable {
  final int id;
  final String title;
  final String excerpt; // الوصف المختصر
  final String? imageUrl;
  final String date;

  const BlogPost({
    required this.id,
    required this.title,
    required this.excerpt,
    this.imageUrl,
    required this.date,
  });

  factory BlogPost.fromJson(Map<String, dynamic> json) {
    String? finalImageUrl;

    // محاولة جلب الصورة البارزة من بيانات _embedded
    try {
      if (json.containsKey('_embedded') &&
          json['_embedded'] != null &&
          json['_embedded'].containsKey('wp:featuredmedia') &&
          json['_embedded']['wp:featuredmedia'] != null &&
          (json['_embedded']['wp:featuredmedia'] as List).isNotEmpty) {
        // ابحث عن أفضل جودة للصورة
        final mediaDetails = json['_embedded']['wp:featuredmedia'][0]['media_details'];
        if (mediaDetails != null && mediaDetails.containsKey('sizes')) {
           final sizes = mediaDetails['sizes'];
           if (sizes.containsKey('medium_large')) {
             finalImageUrl = sizes['medium_large']['source_url'];
           } else if (sizes.containsKey('large')) {
             finalImageUrl = sizes['large']['source_url'];
           } else if (sizes.containsKey('full')) {
             finalImageUrl = sizes['full']['source_url'];
           }
        }
        // إذا لم يتم العثور على أحجام، استخدم source_url الافتراضي
        if (finalImageUrl == null) {
          finalImageUrl = json['_embedded']['wp:featuredmedia'][0]['source_url'];
        }
      }
    } catch (e) {
      print('Error parsing blog image: $e');
      finalImageUrl = null;
    }

    // تنظيف العنوان والوصف من أكواد HTML
    final String cleanTitle = json['title']?['rendered'] != null
        ? parseHtmlString(json['title']['rendered'])
        : '';
    final String cleanExcerpt = json['excerpt']?['rendered'] != null
        ? parseHtmlString(json['excerpt']['rendered'])
        : '';
        
    final String formattedDate = json['date'] != null
        ? convertToAgo(json['date']) // استخدام الدالة الموجودة لديك
        : '';

    return BlogPost(
      id: json['id'] as int,
      title: cleanTitle,
      excerpt: cleanExcerpt,
      imageUrl: finalImageUrl,
      date: formattedDate,
    );
  }

  @override
  List<Object?> get props => [id, title, excerpt, imageUrl, date];
}