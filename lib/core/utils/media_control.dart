import 'package:flutter/foundation.dart';

/// كلاس بسيط لإدارة إشارات التحكم في الميديا عبر التطبيق بالكامل
class MediaControl {
  /// نوتيفاير عام للإيقاف المؤقت
  /// يمكن لأي شاشة الاستماع إليه عبر:
  /// MediaControl.pauseNotifier.addListener(_onPauseSignal);
  static final ValueNotifier<bool> pauseNotifier = ValueNotifier<bool>(false);

  /// دالة لإرسال إشارة الإيقاف المؤقت
  static void sendPauseSignal() {
    // نغير القيمة لإنشاء Event، حتى لو كانت True مسبقاً
    pauseNotifier.value = !pauseNotifier.value;
  }
}
