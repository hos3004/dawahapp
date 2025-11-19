// [ ملف جديد: lib/presentation/screens/webview/webview_screen.dart ]

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// شاشة لعرض صفحة ويب داخل التطبيق
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

    // تهيئة المتحكم
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
            // يمكنك إظهار رسالة خطأ هنا
            print('Page load error: ${error.description}');
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url)); // تحميل الرابط
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