// lib/presentation/screens/webview/webview_screen.dart

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// شاشة لعرض صفحة ويب داخل التطبيق (تدعم الروابط الخارجية والملفات المحلية)
class WebViewScreen extends StatefulWidget {
  final String title;
  final String url;

  const WebViewScreen({
    super.key,
    required this.title,
    required this.url,
  });

  @override
  State<WebViewScreen> createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> {
  // للتحكم في حالة التحميل (Loading)
  int _loadingPercentage = 0;
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();

    // 1. إعداد المتحكم الأساسي
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            setState(() {
              _loadingPercentage = progress;
            });
          },
          onPageStarted: (String url) {
            setState(() {
              _loadingPercentage = 0;
            });
          },
          onPageFinished: (String url) {
            setState(() {
              _loadingPercentage = 100;
            });
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint('Page load error: ${error.description}');
          },
        ),
      );

    // 2. منطق تحميل المحتوى (التعديل الجديد)
    _loadContent();
  }

  /// دالة لتحديد نوع التحميل (إنترنت أو ملف محلي)
  void _loadContent() {
    if (widget.url.startsWith('http') || widget.url.startsWith('https')) {
      // تحميل من الإنترنت
      _controller.loadRequest(Uri.parse(widget.url));
    } else {
      // تحميل من ملفات التطبيق (Assets)
      // مثال: assets/web/privacy.html
      _controller.loadFlutterAsset(widget.url);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 1,
      ),
      body: Stack(
        children: [
          // 1. عرض الويب
          WebViewWidget(
            controller: _controller,
          ),

          // 2. شريط التحميل (يختفي عند 100%)
          if (_loadingPercentage < 100)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: LinearProgressIndicator(
                value: _loadingPercentage / 100.0,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).primaryColor,
                ),
              ),
            ),
        ],
      ),
    );
  }
}