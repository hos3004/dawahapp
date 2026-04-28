import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // لقراءة الملف
import 'package:google_fonts/google_fonts.dart';
import 'athkar_detail_screen.dart'; //
import '../data/athkar_model.dart'; //

class HisnIndexScreen extends StatefulWidget {
  const HisnIndexScreen({super.key});

  @override
  State<HisnIndexScreen> createState() => _HisnIndexScreenState();
}

class _HisnIndexScreenState extends State<HisnIndexScreen> {
  Map<String, dynamic>? _fullBookData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBookData();
  }

  // دالة لتحميل البيانات النصية الجديدة
  Future<void> _loadBookData() async {
    // افترضنا أن الملف اسمه hisn_full.json في الـ assets
    // يمكنك استبدال هذا برابط http إذا كانت البيانات على السيرفر
    final String response =
        await rootBundle.loadString('assets/hisn_full.json');
    setState(() {
      _fullBookData = json.decode(response);
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("فهرس حصن المسلم",
            style: GoogleFonts.tajawal(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xff0B4DA1), // نفس اللون المستخدم عندك
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _fullBookData!.keys.length,
              itemBuilder: (context, index) {
                // استخراج اسم الباب (المفتاح)
                String chapterTitle = _fullBookData!.keys.elementAt(index);

                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15)),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: const Color(0xff0B4DA1).withOpacity(0.1),
                      child: Text("${index + 1}",
                          style: const TextStyle(color: Color(0xff0B4DA1))),
                    ),
                    title: Text(
                      chapterTitle,
                      style: GoogleFonts.tajawal(
                          fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios,
                        size: 16, color: Colors.grey),
                    onTap: () {
                      _navigateToDetail(
                          context, chapterTitle, _fullBookData![chapterTitle]);
                    },
                  ),
                );
              },
            ),
    );
  }

  // دالة ذكية لتحويل البيانات وتوجيه المستخدم
  void _navigateToDetail(
      BuildContext context, String title, Map<String, dynamic> chapterData) {
    // 1. تحويل البيانات النصية إلى هيكل AthkarData الذي يقبله تطبيقك

    // تأكدنا من أن القائمة موجودة لتجنب الأخطاء
    List<String> texts = chapterData['text'] != null
        ? List<String>.from(chapterData['text'])
        : [];

    // تحويل كل نص إلى AthkarItem
    List<AthkarItem> items = texts.map((t) {
      return AthkarItem(
        text: t,
        count: 1, // افتراضي
        currentCount: 1, // للعداد
        reward: "", // لا يوجد فضل محدد
      );
    }).toList();

    // إنشاء كائن البيانات الكامل
    AthkarData formattedData = AthkarData(
      title: title,
      reciters: [], // لا يوجد قراء
      content: items,
    );

    // 2. الانتقال لشاشة التفاصيل (هنا كان الخطأ وتم تصحيحه)
    Navigator.push(
      context,
      MaterialPageRoute(
        // ✅ التصحيح: نستخدم AthkarDetailScreen ونمرر directData
        builder: (context) => AthkarDetailScreen(
          directData: formattedData,
        ),
      ),
    );
  }
}
