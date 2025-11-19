import 'package:shared_preferences/shared_preferences.dart';

/// خدمة لإدارة "سجل المشاهدة" الخاص بفيديوهات تيك توك
class WatchHistoryService {
  static SharedPreferences? _prefs;
  static const String _historyKey = "tiktok_watch_history";

  // دالة لتهيئة الـ SharedPreferences
  static Future<void> _initPrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  /// دالة لإضافة ID فيديو إلى سجل المشاهدة
  static Future<void> addVideoToHistory(int videoId) async {
    await _initPrefs();
    
    // تحويل ID الرقمي إلى نصي (أسهل للتعامل في القوائم)
    final String videoIdStr = videoId.toString();

    // 1. جلب القائمة الحالية
    final List<String> history = _prefs?.getStringList(_historyKey) ?? [];

    // 2. التحقق من عدم وجوده قبل الإضافة (لمنع التكرار)
    if (!history.contains(videoIdStr)) {
      history.add(videoIdStr);
      
      // 3. حفظ القائمة المحدثة
      await _prefs?.setStringList(_historyKey, history);
    }
  }

  /// دالة لجلب كل IDs الفيديوهات التي تمت مشاهدتها
  static Future<List<String>> getWatchHistoryIds() async {
    await _initPrefs();
    
    // إرجاع القائمة المحفوظة (أو قائمة فارغة)
    return _prefs?.getStringList(_historyKey) ?? [];
  }

  /// (اختياري) دالة لمسح السجل بالكامل (للاختبار أو لإعدادات المستخدم)
  static Future<void> clearHistory() async {
    await _initPrefs();
    await _prefs?.remove(_historyKey);
  }
}