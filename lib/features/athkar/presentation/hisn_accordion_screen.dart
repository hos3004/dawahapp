import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class HisnAccordionScreen extends StatefulWidget {
  const HisnAccordionScreen({super.key});

  @override
  State<HisnAccordionScreen> createState() => _HisnAccordionScreenState();
}

class _HisnAccordionScreenState extends State<HisnAccordionScreen> {
  // متغير لتخزين البيانات
  Map<String, dynamic>? _fullBookData;
  // متغير لتحديد أي بطاقة مفتوحة حالياً (null يعني الكل مغلق)
  int? _expandedIndex;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBookData();
  }

  Future<void> _loadBookData() async {
    try {
      // تحميل الملف
      final String response = await rootBundle.loadString('assets/hisn_full.json');
      setState(() {
        _fullBookData = json.decode(response);
        _isLoading = false;
      });
    } catch (e) {
      print("Error loading book: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5), // خلفية رمادية فاتحة جداً
      appBar: AppBar(
        title: Text(
          "حصن المسلم",
          style: GoogleFonts.tajawal(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xff0B4DA1),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              itemCount: _fullBookData!.keys.length,
              itemBuilder: (context, index) {
                String title = _fullBookData!.keys.elementAt(index);
                Map<String, dynamic> content = _fullBookData![title];
                bool isExpanded = _expandedIndex == index;

                return _buildAccordionCard(index, title, content, isExpanded);
              },
            ),
    );
  }

  Widget _buildAccordionCard(
      int index, String title, Map<String, dynamic> content, bool isExpanded) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: isExpanded 
            ? Border.all(color: const Color(0xff0B4DA1), width: 1.5) 
            : Border.all(color: Colors.transparent),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          // 1. رأس البطاقة (العنوان) - قابل للضغط
          InkWell(
            onTap: () {
              setState(() {
                // إذا ضغط على نفس الكارد المفتوح يغلقه، وإلا يفتح الجديد ويغلق القديم
                _expandedIndex = isExpanded ? null : index;
              });
            },
            borderRadius: BorderRadius.vertical(
              top: const Radius.circular(15),
              bottom: Radius.circular(isExpanded ? 0 : 15),
            ),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isExpanded ? const Color(0xff0B4DA1).withOpacity(0.05) : Colors.white,
                borderRadius: BorderRadius.vertical(
                  top: const Radius.circular(15),
                  bottom: Radius.circular(isExpanded ? 0 : 15),
                ),
              ),
              child: Row(
                children: [
                  // رقم الباب
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: isExpanded ? const Color(0xff0B4DA1) : Colors.grey[200],
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        "${index + 1}",
                        style: TextStyle(
                          color: isExpanded ? Colors.white : Colors.grey[600],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 15),
                  // العنوان
                  Expanded(
                    child: Text(
                      title,
                      style: GoogleFonts.tajawal(
                        fontSize: 16,
                        fontWeight: isExpanded ? FontWeight.bold : FontWeight.normal,
                        color: isExpanded ? const Color(0xff0B4DA1) : Colors.black87,
                      ),
                    ),
                  ),
                  // أيقونة السهم (تدور عند الفتح)
                  AnimatedRotation(
                    turns: isExpanded ? 0.25 : 0, // دوران 90 درجة
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: isExpanded ? const Color(0xff0B4DA1) : Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 2. المحتوى (يظهر فقط عند الفتح)
          AnimatedCrossFade(
            firstChild: Container(height: 0), // حالة الإغلاق
            secondChild: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(15)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // فاصل جمالي
                  Divider(color: Colors.grey.withOpacity(0.2), height: 1),
                  const SizedBox(height: 15),
                  
                  // عرض النصوص داخل الباب
                  ..._buildContentList(content['text']),
                  
                  // عرض الحاشية (Footnote) إن وجدت
                  if (content['footnote'] != null) ...[
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.amber.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.amber.withOpacity(0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: _buildFootnoteList(content['footnote']),
                      ),
                    ),
                  ]
                ],
              ),
            ),
            crossFadeState: isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 300),
          ),
        ],
      ),
    );
  }

  // دوال مساعدة لبناء النصوص
  List<Widget> _buildContentList(dynamic textData) {
    if (textData == null) return [];
    List<String> texts = List<String>.from(textData);
    
    return texts.map((text) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12.0),
        child: Text(
          text,
style: GoogleFonts.tajawal(            fontSize: 18,
            height: 1.8,
            color: Colors.black87,
          ),
          textAlign: TextAlign.justify,
        ),
      );
    }).toList();
  }

  List<Widget> _buildFootnoteList(dynamic footnoteData) {
    if (footnoteData == null) return [];
    List<String> notes = List<String>.from(footnoteData);
    
    return notes.map((note) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, size: 16, color: Colors.amber),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              note,
              style: GoogleFonts.tajawal(fontSize: 13, color: Colors.black54),
            ),
          ),
        ],
      );
    }).toList();
  }
}