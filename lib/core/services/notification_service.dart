/* ==== BEGIN FILE: lib/core/services/notification_service.dart ==== */
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http; // لتحميل الصور عند العرض الفوري
import 'package:path_provider/path_provider.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _localPlugin = FlutterLocalNotificationsPlugin();
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  // Stream controller for notification clicks
  static final StreamController<String?> _notificationStreamController = StreamController<String?>.broadcast();
  static Stream<String?> get notificationStream => _notificationStreamController.stream;

  // متغير لحفظ الإشعار المبدئي (عند فتح التطبيق من الخلفية)
  static String? pendingNotificationPayload;

  // Initialize the service
  Future<void> init() async {
    // 1. إعدادات الإشعارات المحلية (للعرض الفوري فقط)
    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    final DarwinInitializationSettings initializationSettingsDarwin =
    DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    final InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );

    await _localPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        _notificationStreamController.add(response.payload);
      },
    );

    // 2. إعدادات Firebase
    await _fcm.requestPermission(alert: true, badge: true, sound: true);

    // 3. الاشتراك في القناة العامة
    await _fcm.subscribeToTopic('all_users');

    // 4. الاستماع للرسائل أثناء عمل التطبيق (Foreground)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _handleRemoteMessage(message);
    });
  }

  // معالجة الرسائل الواردة من Firebase
  void _handleRemoteMessage(RemoteMessage message) {
    String type = "general";
    String id = "0";
    String? image = message.data['image'];

    // 1. محاولة قراءة الهيكل القديم (OneSignal Logic Support)
    if (message.data.containsKey('additionalData')) {
      dynamic additional = message.data['additionalData'];
      if (additional is String) {
        try {
          additional = json.decode(additional);
        } catch (e) {
          print("Error decoding additionalData: $e");
        }
      }

      if (additional is Map) {
        type = additional['post_type'] ?? additional['type'] ?? "general";
        id = (additional['id'] ?? additional['post_id'] ?? "0").toString();
      }

      if (image == null && message.data.containsKey('bigPicture')) {
        image = message.data['bigPicture'];
      }
    }
    // 2. الهيكل الجديد البسيط
    else {
      type = message.data['type'] ?? "general";
      id = message.data['id'] ?? "0";
    }

    if (message.notification != null) {
      // ✅ تم إيقاف الحفظ في السجل المحلي (NotificationStorage) لتقليل التعقيد و Data Safety

      // ✅ عرض الإشعار فوراً (بدون جدولة)
      showNotification(
        title: message.notification?.title,
        body: message.notification?.body,
        image: image,
        payload: "$type|$id",
      );
    }
  }

  // دالة عرض الإشعار (Immediate Display)
  Future<void> showNotification({
    String? title,
    String? body,
    String? image,
    String? payload,
    int id = 0,
  }) async {
    String? bigPicturePath;

    // تحميل الصورة إذا وجدت لعرضها في الإشعار
    if (image != null && image.isNotEmpty && image.startsWith('http')) {
      bigPicturePath = await _downloadAndSaveFile(image, 'notification_img_$id');
    }

    await _localPlugin.show(
      id,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'main_channel', // Channel ID
          'قناة دعوة',    // Channel Name
          channelDescription: 'تنبيهات البرامج والمحتوى',
          importance: Importance.max,
          priority: Priority.high,
          styleInformation: bigPicturePath != null
              ? BigPictureStyleInformation(
            FilePathAndroidBitmap(bigPicturePath),
            hideExpandedLargeIcon: true,
          )
              : null,
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      payload: payload,
    );
  }

  // دالة مساعدة لتحميل الصور
  Future<String?> _downloadAndSaveFile(String url, String fileName) async {
    try {
      final Directory directory = await getApplicationDocumentsDirectory();
      final String filePath = '${directory.path}/$fileName';
      final http.Response response = await http.get(Uri.parse(url));
      final File file = File(filePath);
      await file.writeAsBytes(response.bodyBytes);
      return filePath;
    } catch (e) {
      print('Error downloading image: $e');
      return null;
    }
  }
}
/* ==== END FILE: lib/core/services/notification_service.dart ==== */