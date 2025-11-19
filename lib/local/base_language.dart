import 'package:flutter/material.dart';

// الكلاس الأساسي لجميع اللغات (سيحتوي على النصوص المترجمة)
abstract class BaseLanguage {
  // مثال لنص (سيتم استخدامه لاحقاً في الواجهات)
  String get appName;
  String get loading;
  String get archive;
  // أضف النصوص الأخرى هنا

  // يمكن إضافة دالة لتحميل البيانات الخاصة باللغة
  static BaseLanguage of(BuildContext context) => Localizations.of<BaseLanguage>(context, BaseLanguage)!;
}