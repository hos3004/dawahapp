import 'package:equatable/equatable.dart';

/// مودل بسيط يمثل عنصر فيديو تيك توك من ملف JSON
/// (يفترض أن ملف JSON يحتوي على: id, title, youtube_url, tags)
class TikTokVideoItem extends Equatable {
  final int id;
  final String title;
  final String youtubeUrl; // اسم الحقل في JSON هو 'youtube_url'

  // --- ⚠️ [إضافة جديدة 1/2] ---
  final List<String> tags; // حقل الهاشتاجات
  // -------------------------

  const TikTokVideoItem({
    required this.id,
    required this.title,
    required this.youtubeUrl,
    required this.tags, // --- ⚠️ [إضافة جديدة] ---
  });

  /// دالة لإنشاء كائن من بيانات JSON
  factory TikTokVideoItem.fromJson(Map<String, dynamic> json) {
    // معالجة آمنة لـ ID (قد يأتي كرقم أو نص)
    final dynamic rawId = json['id'];
    int parsedId;
    if (rawId is int) {
      parsedId = rawId;
    } else if (rawId is String) {
      parsedId = int.tryParse(rawId) ?? 0;
    } else if (rawId is num) {
      parsedId = rawId.toInt();
    } else {
      parsedId = 0;
    }

    // --- ⚠️ [إضافة جديدة 2/2] ---
    // معالجة آمنة للهاشتاجات
    List<String> parsedTags = [];
    if (json['tags'] is List) {
      // تحويل القائمة (التي قد تكون List<dynamic>) إلى List<String>
      parsedTags = List<String>.from(
        (json['tags'] as List).map((tag) => tag.toString()),
      );
    }
    // -------------------------

    return TikTokVideoItem(
      id: parsedId,
      title: json['title'] as String? ?? '', // افتراض أن العنوان نصي
      youtubeUrl: json['youtube_url'] as String? ?? '', // جلب الرابط
      tags: parsedTags, // --- ⚠️ [إضافة جديدة] ---
    );
  }

  @override
  List<Object?> get props => [id, title, youtubeUrl, tags]; // --- ⚠️ [إضافة جديدة] ---
}