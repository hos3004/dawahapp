import 'package:share_plus/share_plus.dart';

/// خدمة مساعدة (Helper Service) للتعامل مع منطق المشاركة
class ShareService {

  /// دالة ثابتة (static) لمشاركة رابط الفيديو
  /// نقوم بتمرير العنوان والرابط
  static Future<void> shareVideo(String title, String youtubeUrl) async {
    try {
      // النص الذي سيتم مشاركته
      final String shareText = '$title\n\n$youtubeUrl';

      // استخدام مكتبة share_plus لفتح قائمة المشاركة
      await Share.share(
        shareText,
        subject: title, // 'الموضوع' (يُستخدم في الإيميل مثلاً)
      );
    } catch (e) {
      // في حال حدوث خطأ
      print('Error sharing video: $e');
      // يمكنك إظهار SnackBar للمستخدم هنا إذا أردت
    }
  }
}