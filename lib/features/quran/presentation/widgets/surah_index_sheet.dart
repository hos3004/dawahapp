import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/navigation/quran_navigation_bloc.dart';
import '../bloc/navigation/quran_navigation_event.dart';

/// شيت فهرس السور
/// يعرض قائمة بالسور (الاسم، رقم السورة، مكية/مدنية، عدد الآيات، أول صفحة)
/// وعند الضغط على أي سورة ينتقل مباشرة إلى أول صفحة في هذه السورة.
class SurahIndexSheet extends StatefulWidget {
  const SurahIndexSheet({super.key});

  @override
  State<SurahIndexSheet> createState() => _SurahIndexSheetState();
}

class _SurahIndexSheetState extends State<SurahIndexSheet> {
  late Future<List<_SurahInfo>> _futureSurahs;

  // مسار ملف السور داخل الأصول – عدِّله لو مختلف عندك
  static const String _surahsAssetPath =
      'assets/json/quran_data/surahs_index.json';

  @override
  void initState() {
    super.initState();
    _futureSurahs = _loadSurahs();
  }

  Future<List<_SurahInfo>> _loadSurahs() async {
    final jsonStr = await rootBundle.loadString(_surahsAssetPath);
    final Map<String, dynamic> data =
        json.decode(jsonStr) as Map<String, dynamic>;

    final List<dynamic> chapters = data['chapters'] as List<dynamic>;

    final List<_SurahInfo> list = chapters.map((dynamic e) {
      final ch = e as Map<String, dynamic>;

      final int id = ch['id'] as int;
      final String nameArabic = ch['name_arabic'] as String;
      final String revelationPlace = ch['revelation_place'] as String;
      final int versesCount = ch['verses_count'] as int;
      final List pages = ch['pages'] as List;
      final int firstPage = pages.first as int;

      return _SurahInfo(
        id: id,
        nameArabic: nameArabic,
        revelationPlace: revelationPlace,
        versesCount: versesCount,
        firstPage: firstPage,
      );
    }).toList();

    // نضمن الترتيب التصاعدي للسور
    list.sort((a, b) => a.id.compareTo(b.id));
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final navBloc = context.read<QuranNavigationBloc>();

    return Directionality(
      textDirection: TextDirection.rtl,
        child: SizedBox(
          height: 500,

          child: Container(
          padding: const EdgeInsets.only(top: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // عنوان الشيت
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  'فهرس السور',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const Divider(height: 1),

              // قائمة السور
              Expanded(
                child: FutureBuilder<List<_SurahInfo>>(
                  future: _futureSurahs,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          'حدث خطأ في تحميل فهرس السور',
                          style: TextStyle(color: Colors.red.shade700),
                        ),
                      );
                    }

                    final surahs = snapshot.data ?? [];

                    return Stack(
                      children: [
                        // خط طولي على اليسار كشكل جمالي (يشبه الصورة)
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            width: 1.5,
                            margin: const EdgeInsets.only(top: 0),
                            color: const Color(0xff00BCD4), // لون سماوي خفيف
                          ),
                        ),
                        ListView.separated(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          itemCount: surahs.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final s = surahs[index];
                            final String placeArabic =
                                s.revelationPlace == 'madinah'
                                    ? 'مدنية'
                                    : 'مكية';

                            return InkWell(
                              onTap: () {
                                navBloc.add(ChangePageEvent(s.firstPage));
                                Navigator.pop(context);
                              },
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 6.0),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // يسار: نص "صفحة X"
                                    SizedBox(
                                      width: 80,
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'صفحة ${s.firstPage}',
                                            style: const TextStyle(
                                              fontSize: 13,
                                              color: Colors.grey,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    // فاصل بسيط (المسافة عن الخط العمودي)
                                    const SizedBox(width: 4),

                                    // يمين: رقم السورة + اسمها + تفاصيلها
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '${s.id} - سورة ${s.nameArabic}',
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '$placeArabic • آياتها ${s.versesCount}',
                                            style: const TextStyle(
                                              fontSize: 13,
                                              color: Colors.black54,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    const Icon(
                                      Icons.chevron_left,
                                      color: Colors.grey,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// نموذج داخلي لتمثيل بيانات السورة داخل الشيت
class _SurahInfo {
  final int id;
  final String nameArabic;
  final String revelationPlace; // "makkah" أو "madinah"
  final int versesCount;
  final int firstPage;

  _SurahInfo({
    required this.id,
    required this.nameArabic,
    required this.revelationPlace,
    required this.versesCount,
    required this.firstPage,
  });
}
