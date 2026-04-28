import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ✅ استيراد الـ APIs والمودلز
import '../../presentation/screens/program_detail/program_detail_screen.dart';
import '../../presentation/screens/blog/blog_detail_screen.dart';
import '../../features/quran/presentation/pages/quran_view_page.dart';
import '../../presentation/screens/notifications/generic_notification_screen.dart';

class NotificationRouter {
  
  static void navigate(BuildContext context, String payload) async {
    // Payload format: "type|id"
    final parts = payload.split('|');
    if (parts.length < 2) return;
    
    final type = parts[0];
    final idString = parts[1];
    final int id = int.tryParse(idString) ?? 0;

    // إذا لم يكن هناك ID ونوع الإشعار ليس "بث مباشر" أو "أذكار/عام"، نتجاهل الإشعار
    if (id == 0 && !['live', 'live_stream', 'azkar', 'event', 'general'].contains(type)) return;

    try {
      // final repo = ProgramRepository(); // (غير مستخدم هنا مباشرة، الشاشات تقوم بالجلب)

      switch (type) {
        // --- 1. محتوى الفيديو (أفلام، برامج، حلقات) ---
        case 'movie':
        case 'tv_show':
        case 'video':
        case 'episode':
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProgramDetailScreen(
                programId: id,
                postType: type == 'episode' ? 'tv_show' : type, // توحيد المسميات
              ),
            ),
          );
          break;

        // --- 2. المقالات والأخبار ---
        case 'post': 
        case 'article':
        case 'news':
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => BlogDetailScreen(postId: id),
            ),
          );
          break;

        // --- 3. القرآن الكريم ---
        case 'quran':
          Navigator.push(
             context,
             MaterialPageRoute(builder: (context) => const QuranViewPage()),
          ).then((_) {
             // يمكن إضافة منطق لتغيير الصفحة هنا لاحقاً إذا لزم الأمر
          });
          break;
          
        // --- 4. البث المباشر ---
        case 'live':
        case 'live_stream':
           Navigator.pushNamed(context, '/live_stream');
           break;

        // --- 5. الأذكار والمناسبات العامة (إشعارات محلية) ---
        case 'azkar':
        case 'event':
        case 'general':
           // البحث عن تفاصيل الإشعار في الملف المحلي (العنوان والنص)
           final details = await _getNotificationDetails(idString); // idString هنا هو target_id مثل morning
           
           if (details != null) {
             Navigator.push(
               context,
               MaterialPageRoute(
                 builder: (context) => GenericNotificationScreen(
                   title: details['title'],
                   body: details['body'],
                   imageUrl: details['image'], 
                 ),
               ),
             );
           } else {
             // fallback: فتح الرئيسية إذا لم نجد التفاصيل
             Navigator.pushNamed(context, '/home');
           }
           break;

        default:
          print("Unknown notification type: $type");
          // يمكن فتح الرئيسية كإجراء افتراضي
          Navigator.pushNamed(context, '/home');
      }
    } catch (e) {
      print("Error in notification routing: $e");
    }
  }

  // --- دالة مساعدة للبحث في ملف الجدول عن تفاصيل الإشعار المحلي ---
  static Future<Map<String, dynamic>?> _getNotificationDetails(String targetId) async {
    try {
      // قراءة الملف المحلي
      final String jsonString = await rootBundle.loadString('assets/json/fixed_schedule.json');
      final Map<String, dynamic> data = json.decode(jsonString);
      
      if (data['routine'] != null) {
        final List<dynamic> list = data['routine'];
        // البحث عن العنصر الذي يطابق target_id
        final item = list.firstWhere(
          (element) => element['target_id'].toString() == targetId, 
          orElse: () => null
        );
        
        if (item != null) {
          return {
            'title': item['title'],
            'body': item['body'],
            'image': item['image']
          };
        }
      }
    } catch (e) {
      print("Error fetching local notification details: $e");
    }
    return null;
  }
}