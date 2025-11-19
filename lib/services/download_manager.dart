// [ ملف جديد: lib/services/download_manager.dart ]

import 'dart:async'; // 🆕 لتمكين استخدام Completer/Future.value
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:nb_utils/nb_utils.dart'; // للتوست والتحقق
import 'package:path_provider/path_provider.dart';
import '../data/models/quran_models.dart';
import '../utils/constants.dart';

class DownloadManager {

  // 🆕 Completer يستخدم لـ "إلغاء" عملية التحميل النشطة
  Completer<void>? _cancellationCompleter;

  // 1. جلب المسار المحلي لتخزين المصحف (Application Documents Directory)
  Future<String> _getLocalMushafPath(String mushafSlug) async {
    final directory = await getApplicationDocumentsDirectory();
    final path = '${directory.path}/quran_mushafs/$mushafSlug';
    await Directory(path).create(recursive: true);
    return path;
  }

  // 2. بناء رابط صفحة الصورة على السيرفر
  String _getServerPageUrl(String mushafSlug, int pageNumber) {
    // تنسيق رقم الصفحة بثلاثة أرقام (مثال: 001.webp)
    final fileName = pageNumber.toString().padLeft(3, '0');
    // 🚨 التعديل إلى .webp
    return '$QURAN_BASE_URL$mushafSlug/$fileName.webp';
  }

  // 3. بناء مسار الملف المحلي (File Path)
  Future<String> getLocalFilePath(String mushafSlug, int pageNumber) async {
    // 🆕 لا نحتاج مسار محلي لصفحة الغلاف (0)
    if (pageNumber == 0) return '';
    final localPath = await _getLocalMushafPath(mushafSlug);
    final fileName = pageNumber.toString().padLeft(3, '0');
    // 🚨 التعديل إلى .webp
    return '$localPath/$fileName.webp';
  }

  // 4. تحميل صفحة واحدة وحفظها
  Future<bool> _downloadPage(String mushafSlug, int pageNumber) async {
    // 🆕 لا نحمل صفحة الغلاف (0)
    if (pageNumber == 0) return true;

    final serverUrl = _getServerPageUrl(mushafSlug, pageNumber);
    final localFilePath = await getLocalFilePath(mushafSlug, pageNumber);

    try {
      final response = await http.get(Uri.parse(serverUrl));
      if (response.statusCode == 200) {
        final file = File(localFilePath);
        await file.writeAsBytes(response.bodyBytes);
        return true;
      } else {
        log('Failed to download page $pageNumber: ${response.statusCode}');
        // 🚨 الحل هنا: إرجاع False إذا لم تكن الحالة 200
        return false;
      }
    } catch (e) {
      log('Download Error: $e');
      // 🚨 الحل هنا: إرجاع False في حال وجود خطأ شبكة أو تحليل
      return false;
    }
  }

  // 5. التحقق من وجود الملف محلياً
  Future<bool> isPageDownloaded(String mushafSlug, int pageNumber) async {
    // 🆕 صفحة الغلاف (0) تعتبر محملة دائمًا (كونها جزء من الـ assets)
    if (pageNumber == 0) return true;

    final filePath = await getLocalFilePath(mushafSlug, pageNumber);
    return File(filePath).exists();
  }

  // 🆕 5.5. التحقق من اكتمال تحميل نطاق صفحات
  Future<bool> isRangeDownloaded(Mushaf mushaf, int startPage, int endPage) async {
    for (int page = startPage; page <= endPage; page++) {
      if (!await isPageDownloaded(mushaf.slug, page)) {
        return false;
      }
    }
    return true;
  }

  // 🆕 دالة لإلغاء عملية التحميل الجارية
  void cancelDownload() {
    if (_cancellationCompleter?.isCompleted == false) {
      // إكمال الـ Completer سيؤدي إلى إنهاء حلقة التحميل في downloadPagesRange
      _cancellationCompleter!.complete();
    }
    _cancellationCompleter = null;
  }

  // 6. تحميل مجموعة من الصفحات (تحسين منطق الإلغاء)
  Future<void> downloadPagesRange(
      Mushaf mushaf,
      int startPage,
      int endPage,
      Function(int progress) onProgress,
      {bool cancellable = false} // 🆕 هل يمكن إلغاء هذه الدورة؟
      ) async {
    int totalPages = mushaf.pagesCount; // 🆕 استخدام العدد الكلي لصفحات المصحف لحساب التقدم
    int fullyDownloadedCount = 0;

    // 🆕 إذا كانت العملية قابلة للإلغاء، ننشئ Completer جديد
    if (cancellable) {
      cancelDownload(); // إلغاء أي عملية سابقة أولاً
      _cancellationCompleter = Completer<void>();
    }

    // 1. حساب عدد الصفحات المحملة بالفعل
    for (int p = 1; p <= totalPages; p++) {
      if (await isPageDownloaded(mushaf.slug, p)) {
        fullyDownloadedCount++;
      }
    }

    // 2. بدء التحميل
    for (int page = startPage; page <= endPage; page++) {
      // 🆕 التحقق من الإلغاء في كل تكرار
      if (cancellable && _cancellationCompleter?.isCompleted == true) {
        log('Download cancelled by user.');
        break;
      }

      final isDownloaded = await isPageDownloaded(mushaf.slug, page);
      if (!isDownloaded) {
        await _downloadPage(mushaf.slug, page);
        fullyDownloadedCount++; // زيادة العدد بعد نجاح التحميل
      }

      // 3. تحديث التقدم بناءً على العدد الكلي
      final currentProgress = ((fullyDownloadedCount / totalPages) * 100).toInt();
      onProgress(currentProgress);
    }

    // 🆕 إغلاق الـ Completer في نهاية التحميل
    if (cancellable) _cancellationCompleter = null;
  }

  // 7. دالة لحساب التقدم الكلي للتحميل
  Future<double> getDownloadProgress(Mushaf mushaf) async {
    int downloadedCount = 0;
    for (int page = 1; page <= mushaf.pagesCount; page++) {
      if (await isPageDownloaded(mushaf.slug, page)) {
        downloadedCount++;
      }
    }
    return downloadedCount / mushaf.pagesCount;
  }
}