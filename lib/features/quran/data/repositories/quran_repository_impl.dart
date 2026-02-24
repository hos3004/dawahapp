import 'dart:convert';
import 'package:flutter/services.dart';
import '../../domain/entities/ayah_coordinates.dart';
import '../../domain/repositories/quran_repository.dart';
import '../datasources/quran_local_datasource.dart';
import '../models/reciter_model.dart';
// ✅ استيراد مودل SurahIndex
import '../../../../data/models/quran_models.dart';

class QuranRepositoryImpl implements QuranRepository {
  final QuranLocalDataSource localDataSource;

  QuranRepositoryImpl({required this.localDataSource});

  @override
  Future<List<AyahCoordinates>> getPageCoordinates({
    required int pageNumber,
    required String mushafType,
  }) async {
    return await localDataSource.getCoordinates(pageNumber, mushafType);
  }

  @override
  Future<List<ReciterModel>> getReciters() async {
    try {
      final String response = await rootBundle.loadString('assets/json/quran_data/reciters_list.json');
      final List<dynamic> data = json.decode(response);
      return data.map((e) => ReciterModel.fromJson(e)).toList();
    } catch (e) {
      print("Error loading reciters: $e");
      return [];
    }
  }

  // ✅ تنفيذ الدالة المفقودة هنا
  @override
  Future<List<SurahIndex>> getSurahIndex() async {
    try {
      // استخدام نفس المسار المستخدم في باقي التطبيق
      final String response = await rootBundle.loadString('assets/json/quran_data/surahs_index.json');
      final Map<String, dynamic> jsonMap = jsonDecode(response);
      final List<dynamic> jsonList = jsonMap['chapters'] ?? [];

      return jsonList.map((e) => SurahIndex.fromJson(e)).toList();
    } catch (e) {
      print("Error loading surah index: $e");
      return [];
    }
  }
}