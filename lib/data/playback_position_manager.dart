import 'package:shared_preferences/shared_preferences.dart';

class PlaybackPositionManager {
  static SharedPreferences? _prefs;

  // دالة لتهيئة الـ SharedPreferences
  static Future<void> _initPrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  // مفتاح فريد لكل حلقة
  static String _episodeKey(int episodeId) => "episode_$episodeId";

  // حفظ الموضع (بالثواني)
  static Future<void> savePosition(int episodeId, Duration position) async {
    await _initPrefs();
    _prefs?.setInt(_episodeKey(episodeId), position.inSeconds);
  }

  // جلب الموضع (بالثواني)
  static Future<Duration> getPosition(int episodeId) async {
    await _initPrefs();
    final seconds = _prefs?.getInt(_episodeKey(episodeId)) ?? 0;
    return Duration(seconds: seconds);
  }
}