import 'package:html/parser.dart';
import 'package:intl/intl.dart';

//
// --- 🔥 ملف جديد: أضف هذا الملف إلى مشروعك ---
//
// هذا الملف يحتوي على الدوال المساعدة التي كان ملف `blog_post.dart` يحتاجها.
//

/// ينظف أكواد HTML من النصوص
String parseHtmlString(String? htmlString) {
  if (htmlString == null) return '';
  final document = parse(htmlString);
  final String? parsedString = document.documentElement?.text;
  return parsedString ?? '';
}

/// يحول تاريخ بصيغة ISO إلى "منذ كذا"
/// مثال: "منذ 5 أيام"
String convertToAgo(String dateTime) {
  if (dateTime.isEmpty) {
    return '';
  }

  DateTime input;
  try {
    // محاولة تحليل التاريخ بصيغة ISO 8601
    input = DateTime.parse(dateTime);
  } catch (e) {
    // في حال كان التنسيق مختلفاً
    try {
      // مثال: "2023-11-10 15:30:00" (بدون حرف T)
      input = DateFormat("yyyy-MM-dd HH:mm:ss").parse(dateTime);
    } catch (e2) {
      return '...'; // إرجاع قيمة فارغة إذا فشل التحليل
    }
  }

  final Duration difference = DateTime.now().difference(input);

  if (difference.inDays >= 365) {
    final years = (difference.inDays / 365).floor();
    return 'منذ $years ${years > 1 ? 'سنوات' : 'سنة'}';
  } else if (difference.inDays >= 30) {
    final months = (difference.inDays / 30).floor();
    return 'منذ $months ${months > 1 ? 'أشهر' : 'شهر'}';
  } else if (difference.inDays >= 7) {
    final weeks = (difference.inDays / 7).floor();
    return 'منذ $weeks ${weeks > 1 ? 'أسابيع' : 'أسبوع'}';
  } else if (difference.inDays >= 1) {
    return 'منذ ${difference.inDays} ${difference.inDays > 1 ? 'أيام' : 'يوم'}';
  } else if (difference.inHours >= 1) {
    return 'منذ ${difference.inHours} ${difference.inHours > 1 ? 'ساعات' : 'ساعة'}';
  } else if (difference.inMinutes >= 1) {
    return 'منذ ${difference.inMinutes} ${difference.inMinutes > 1 ? 'دقائق' : 'دقيقة'}';
  } else if (difference.inSeconds >= 3) {
    return 'منذ ${difference.inSeconds} ثواني';
  } else {
    return 'الآن';
  }
}