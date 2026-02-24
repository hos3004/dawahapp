class ReciterModel {
  final int id;
  final String nameArabic;
  final String slug;
  final String sourceUrl;
  // 1️⃣ الحقول الجديدة المضافة لتعريف جودة وتكوين الملفات
  final String bitRate;
  final String fileStructure;

  ReciterModel({
    required this.id,
    required this.nameArabic,
    required this.slug,
    required this.sourceUrl,
    required this.bitRate,
    required this.fileStructure,
  });

  // 2️⃣ Getter لسهولة العرض في الـ UI (مثل: 64kbps • Ayah)
  String get style => '$bitRate • $fileStructure';

  // 3️⃣ تحديث fromJson للتعامل مع البيانات الجديدة ومعالجة الرابط
  factory ReciterModel.fromJson(Map<String, dynamic> json) {
    final rawSource = json['source_url'] as String? ?? '';
    
    // التأكد من إزالة / في نهاية الرابط لتوحيد المعالجة لاحقاً
    final normalizedSource = rawSource.endsWith('/')
        ? rawSource.substring(0, rawSource.length - 1)
        : rawSource;

    return ReciterModel(
      id: json['id'] as int,
      nameArabic: json['name_arabic'] as String,
      slug: json['slug'] as String,
      sourceUrl: normalizedSource,
      // التعامل الآمن مع الحقول الجديدة في حال كانت null
      bitRate: (json['bit_rate'] as String?) ?? '',
      fileStructure: (json['file_structure'] as String?) ?? '',
    );
  }
}