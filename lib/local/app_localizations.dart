import 'package:flutter/material.dart';
// (تأكد من حذف 'import ../main.dart';)
import 'base_language.dart';
import 'language_ar.dart';

class AppLocalizations extends LocalizationsDelegate<BaseLanguage> {
  const AppLocalizations();

  static const LocalizationsDelegate<BaseLanguage> delegate = AppLocalizations();

  @override
  bool isSupported(Locale locale) => ['ar'].contains(locale.languageCode);

  @override
  Future<BaseLanguage> load(Locale locale) async {
    // قم بتحميل اللغة العربية وإرجاعها مباشرة
    return LanguageAr();
  }

  @override
  bool shouldReload(LocalizationsDelegate<BaseLanguage> old) => false;
}