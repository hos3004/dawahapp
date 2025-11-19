// [ ملف معدل: lib/data/models/quran_models.dart ]

class Mushaf {
  final int id;
  final String name;
  final String description;
  final String image;
  final String slug; // مفتاح المجلد (مثلاً: hafs)
  final int pagesCount;

  Mushaf({
    required this.id,
    required this.name,
    required this.description,
    required this.image,
    required this.slug,
    required this.pagesCount,
  });

  factory Mushaf.fromJson(Map<String, dynamic> json) {
    // استخدمنا slug: 'hafs' أو أي slug افتراضي إذا لم يكن موجوداً
    // هذا مهم جداً لمطابقة اسم المجلد في DownloadManager
    final String slug = (json['rawi']?['name'] ?? '').toLowerCase() == 'حفص' ? 'hafs' : (json['rawi']?['name'] ?? '').toLowerCase() == 'ورش' ? 'warsh' : json['slug'] ?? 'hafs';

    return Mushaf(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      image: json['image'] ?? '',
      slug: slug,
      // غالباً المصاحف المرفوعة لها 604 صفحات ما لم يذكر غير ذلك
      pagesCount: json['pages_count'] ?? 604,
    );
  }
}

class SurahIndex {
  final int id;
  final String nameArabic;
  final int pageNumber; // رقم الصفحة الذي تبدأ منه السورة
  final int versesCount;

  SurahIndex({
    required this.id,
    required this.nameArabic,
    required this.pageNumber,
    required this.versesCount,
  });

  factory SurahIndex.fromJson(Map<String, dynamic> json) {
    // 🆕 التعديل لاستخراج رقم الصفحة الأولى من مصفوفة 'pages'
    int startPage = 1;
    if (json['pages'] is List && json['pages'].isNotEmpty) {
      startPage = json['pages'][0] ?? 1;
    }

    return SurahIndex(
      id: json['id'] ?? 0,
      // استخدمنا 'name_arabic' من ملف surahs_index.json
      nameArabic: json['name_arabic'] ?? json['name_simple'] ?? '',
      pageNumber: startPage,
      versesCount: json['verses_count'] ?? 0,
    );
  }
}

class JuzIndex {
  final int id;
  final int pageNumber; // رقم الصفحة الذي يبدأ منه الجزء

  JuzIndex({
    required this.id,
    required this.pageNumber,
  });

  factory JuzIndex.fromJson(Map<String, dynamic> json) {
    return JuzIndex(
      id: json['id'] ?? 0,
      pageNumber: json['page_number'] ?? 1,
    );
  }
}

// 🆕 نموذج جديد لبيانات السورة في QuranListScreen
class Surah {
  final int id;
  final String nameArabic;
  final String nameSimple;
  final int versesCount;
  final String revelationPlace;

  Surah({
    required this.id,
    required this.nameArabic,
    required this.nameSimple,
    required this.versesCount,
    required this.revelationPlace,
  });

  factory Surah.fromJson(Map<String, dynamic> json) {
    return Surah(
      id: json['id'] ?? 0,
      nameArabic: json['name_arabic'] ?? '',
      nameSimple: json['name_simple'] ?? '',
      versesCount: json['verses_count'] ?? 0,
      revelationPlace: json['revelation_place'] ?? '',
    );
  }
}
// 🆕 نموذج جديد لبيانات القارئ
class Reciter {
  final int id;
  final String nameArabic;
  final String slug;
  final String bitRate;

  // رابط الفولدر النهائي اللي فيه ملفات mp3
  final String sourceUrl;

  // بادئة اسم الملف، زي "Page" أو "page"
  final String fileStructure;

  Reciter({
    required this.id,
    required this.nameArabic,
    required this.slug,
    required this.bitRate,
    required this.sourceUrl,
    required this.fileStructure,
  });

  factory Reciter.fromJson(Map<String, dynamic> json) {
    return Reciter(
      id: json['id'] ?? 0,
      nameArabic: json['name_arabic'] ?? '',
      slug: json['slug'] ?? '',
      bitRate: json['bit_rate'] ?? '',
      sourceUrl: json['source_url'] ?? '',
      fileStructure: json['file_structure'] ?? '',
    );
  }
}
// 🆕 نموذج جديد لبيانات الآية في SurahDetailScreen
class Ayah {
  final String textUthmani;
  final String verseKey; // مثل 1:1, 2:10

  Ayah({
    required this.textUthmani,
    required this.verseKey,
  });

  factory Ayah.fromJson(Map<String, dynamic> json) {
    return Ayah(
      textUthmani: json['text_uthmani'] ?? '',
      verseKey: json['verse_key'] ?? '',
    );
  }
}