// [ ملف معدل: lib/services/url_launcher_service.dart ]

// ✅ تصحيح 1/2: استيراد الحزمة مع بادئة (prefix) "launcher"
import 'package:url_launcher/url_launcher.dart' as launcher;

class UrlLauncherService {

  // (أبقينا على اسم الدالة كما هو)
  static Future<void> launchUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);

    // ✅ تصحيح 2/2: استدعاء الدالة باستخدام البادئة "launcher"
    // هذا يضمن أننا نستدعي الدالة الصحيحة من الحزمة
    if (!await launcher.launchUrl(
      url, // (الدالة الصحيحة تقبل Uri)

      // (يجب استخدام البادئة هنا أيضاً للـ enum)
      mode: launcher.LaunchMode.externalApplication,
    )) {
      // (الدالة الصحيحة ترجع bool)

      // يمكنك إظهار رسالة خطأ للمستخدم هنا
      print('Could not launch $urlString');
    }
  }
}