class AssetsManager {
  // دالة لجلب مسار ملف الإحداثيات بناءً على الرواية ورقم الصفحة
  static String getCoordsJsonPath({required String mushafType, required int pageNumber}) {
    // تنسيق الرقم ليصبح 3 خانات: 001, 010, 604
    String pageStr = pageNumber.toString().padLeft(3, '0');
    // مثال: assets/json/hafs/001.json
    return 'assets/json/$mushafType/$pageStr.json';
  }

  // دالة لجلب رابط الصورة (للاستخدام مع CachedNetworkImage)
  static String getPageImageUrl({required String baseUrl, required int pageNumber}) {
    String pageStr = pageNumber.toString().padLeft(3, '0');
    return '$baseUrl$pageStr.webp';
  }
}