import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/services/notification_router.dart';
import '../../../main.dart'; // For navigatorKey

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  late VideoPlayerController _controller;

  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();
    _initSplashFlow();
  }

  Future<void> _initSplashFlow() async {
    // 1. بدء تشغيل الفيديو (غير حاصر)
    _controller = VideoPlayerController.asset('assets/videos/Comp1.mp4')
      ..initialize().then((_) {
        _controller.play();
        if (mounted) setState(() {});
      });

    // 2. الانتظار المزدوج: إنهاء فحص الإشعارات + وقت أدنى للشاشة (1500 مللي ثانية)
    // هذا يحل الـ race condition بضمان أن الفحص يكتمل قبل الانتقال
    await Future.wait([
      _checkInitialMessage(),
      Future.delayed(const Duration(milliseconds: 1500)),
    ]);

    _navigateToHome();
  }

  Future<void> _checkInitialMessage() async {
    try {
      RemoteMessage? initialMessage =
          await FirebaseMessaging.instance.getInitialMessage();
      if (initialMessage != null) {
        String type = initialMessage.data['type'] ?? "general";
        String id = initialMessage.data['id'] ?? "0";

        if (initialMessage.data.containsKey('additionalData')) {
          dynamic additional = initialMessage.data['additionalData'];
          if (additional is String) {
            try {
              additional = json.decode(additional);
            } catch (_) {}
          }
          if (additional is Map) {
            type = additional['post_type'] ?? additional['type'] ?? "general";
            id = (additional['id'] ?? additional['post_id'] ?? "0").toString();
          }
        }
        NotificationService.pendingNotificationPayload = "$type|$id";
      }
    } catch (e) {
      debugPrint("Error checking initial message in Splash: $e");
    }
  }

  void _navigateToHome() {
    if (_hasNavigated || !mounted) return;
    _hasNavigated = true; // ✅ Guard يمنع التكرار

    if (NotificationService.pendingNotificationPayload != null) {
      // 1. الذهاب للرئيسية أولاً (لتكون في الخلفية)
      Navigator.pushReplacementNamed(context, '/home');

      // 2. ثم فتح صفحة الإشعار فوقها
      Future.delayed(const Duration(milliseconds: 100), () {
        if (navigatorKey.currentState != null) {
          NotificationRouter.navigate(
            navigatorKey.currentState!.context,
            NotificationService.pendingNotificationPayload!,
          );
          NotificationService.pendingNotificationPayload = null;
        }
      });
    } else {
      // السلوك الطبيعي: الذهاب للرئيسية فقط
      Navigator.pushReplacementNamed(context, '/home');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF9FA),
      body: Center(
        child: _controller.value.isInitialized
            ? AspectRatio(
                aspectRatio: _controller.value.aspectRatio,
                child: VideoPlayer(_controller),
              )
            : Image.asset('assets/images/logo.png',
                width: 140), // ✅ Fallback بصري أثناء التهيئة
      ),
    );
  }
}
