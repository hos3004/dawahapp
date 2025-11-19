// [ ملف معدل: lib/data/repositories/quran_repo.dart ]

import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import '../models/quran_models.dart';
import '../../utils/constants.dart';
import 'package:nb_utils/nb_utils.dart';

class QuranRepository {

  // 1. جلب قائمة المصاحف (من ملف JSON مستضاف ذاتياً)
  Future<List<Mushaf>> getMushafsList() async {
    // نفترض أن ملف mushafs_list.json موجود على سيرفرك
    final url = '${QURAN_BASE_URL}mushafs_list.json';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final List<dynamic> jsonList = jsonDecode(response.body);
        return jsonList.map((e) => Mushaf.fromJson(e)).toList();
      } else {
        // يمكن إضافة fallback لتحميل ملف محلي في حال فشل الاتصال
        throw Exception('Failed to load mushafs list: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error fetching mushafs: $e');
    }
  }

  // 2. جلب فهرس السور (لأي مصحف - نفترض أن الفهرس ثابت)
  Future<List<SurahIndex>> getSurahIndex() async {
    try {
      // 🆕 قراءة الملف من Assets
      final String response = await rootBundle.loadString('assets/quran/surahs_index.json');

      final Map<String, dynamic> jsonMap = jsonDecode(response);
      final List<dynamic> jsonList = jsonMap['chapters'] ?? [];

      return jsonList.map((e) => SurahIndex.fromJson(e)).toList();
    } catch (e) {
      throw Exception('Failed to load surah index from assets: $e');
    }
  }


  Future<List<Reciter>> getRecitersList() async {
    const String url = 'https://daawah.tv/app/quran/reciters_list.json';

    print('🔎 Fetching reciters from: $url');

    try {
      final response = await http.get(Uri.parse(url));
      print('🔎 reciters statusCode = ${response.statusCode}');

      if (response.statusCode == 200) {
        final body = response.body;
        print('🔎 reciters raw body (first 200 chars): '
            '${body.substring(0, body.length > 200 ? 200 : body.length)}');

        final decoded = jsonDecode(body);

        List<dynamic> jsonList;

        // يدعم: [ {...}, {...} ] أو { "reciters": [ ... ] }
        if (decoded is List) {
          jsonList = decoded;
        } else if (decoded is Map && decoded['reciters'] is List) {
          jsonList = decoded['reciters'];
        } else {
          print('❌ Unexpected reciters JSON format: $decoded');
          return [];
        }

        final list = jsonList.map((e) => Reciter.fromJson(e)).toList();
        print('✅ Loaded ${list.length} reciters from JSON');
        return list;
      } else {
        print('❌ Failed to load reciters list: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('❌ Network error fetching reciters: $e');
      return [];
    }
  }



  // 3. جلب فهرس الأجزاء (من Assets داخلياً)
  Future<List<JuzIndex>> getJuzIndex() async {
    try {
      // 🆕 قراءة الملف من Assets
      final String response = await rootBundle.loadString('assets/quran/juzs_index.json');
      final List<dynamic> jsonList = jsonDecode(response);

      return jsonList.map((e) => JuzIndex.fromJson(e)).toList();
    } catch (e) {
      throw Exception('Failed to load juz index from assets: $e');
    }
  }
}