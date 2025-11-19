import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart'; // <-- 1. استيراد الحزمة

class ExpandableDescription extends StatefulWidget {
  final String text;

  const ExpandableDescription({super.key, required this.text});

  @override
  State<ExpandableDescription> createState() => _ExpandableDescriptionState();
}

class _ExpandableDescriptionState extends State<ExpandableDescription> {
  bool _isExpanded = false;

  // ارتفاع تقريبي لـ 3 أسطر (يمكنك تعديله)
  static const double _collapsedHeight = 65.0;

  @override
  Widget build(BuildContext context) {

    // تعريف الأنماط المشتركة (مستفادة من الكود القديم)
    final Map<String, Style> htmlStyles = {
      "body": Style(
        // استخدام حجم الخط الافتراضي من الثيم
        fontSize: FontSize(Theme.of(context).textTheme.bodyMedium!.fontSize!),
        color: Colors.black54, // لون النص الأساسي
        margin: Margins.zero, // لإزالة الهوامش الافتراضية
        padding: HtmlPaddings.zero, // لإزالة الحشو الافتراضي
        lineHeight: LineHeight.number(1.5), // لتباعد الأسطر
      ),
      "strong": Style(
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
      // يمكنك إضافة أنماط أخرى هنا (مثل p, a, etc.)
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 2. استخدام حاوية متغيرة الارتفاع لعرض الـ HTML
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          // إذا كان مطوياً، حدد الارتفاع. إذا كان مفتوحاً، دعه يتمدد (null)
          height: _isExpanded ? null : _collapsedHeight,
          // قص المحتوى الزائد في حالة الطي
          clipBehavior: Clip.hardEdge,
          decoration: const BoxDecoration(), // ضروري لـ clipBehavior
          child: Html(
            data: widget.text.isEmpty ? "لا يوجد وصف." : widget.text, // <-- استخدام Html هنا
            style: htmlStyles, // <-- تطبيق الأنماط
          ),
        ),

        // 3. زر "اقرأ المزيد" / "عرض أقل"
        // (لا تظهر الزر إذا كان النص قصيراً)
        if (widget.text.length > 100) // تقدير تقريبي لطول النص
          InkWell(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            child: Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Text(
                _isExpanded ? "عرض أقل" : "اقرأ المزيد...",
                style: TextStyle(
                  color: Theme.of(context).primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }
}