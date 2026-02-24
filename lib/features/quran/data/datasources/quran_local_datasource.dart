import 'dart:convert';
import 'package:flutter/services.dart';
import '../../../../core/utils/assets_manager.dart';
import '../models/ayah_coordinates_model.dart';

abstract class QuranLocalDataSource {
  Future<List<AyahCoordinatesModel>> getCoordinates(int pageNumber, String mushafType);
}

class QuranLocalDataSourceImpl implements QuranLocalDataSource {
  @override
  Future<List<AyahCoordinatesModel>> getCoordinates(int pageNumber, String mushafType) async {
    try {
      // استخدام AssetsManager لجلب المسار الصحيح
      final path = AssetsManager.getCoordsJsonPath(
        mushafType: mushafType,
        pageNumber: pageNumber,
      );

      // قراءة الملف
      final String response = await rootBundle.loadString(path);
      final List<dynamic> data = json.decode(response);

      return data.map((e) => AyahCoordinatesModel.fromJson(e)).toList();
    } catch (e) {
      // في حال لم نجد الملف (مثل صفحات الفواصل أو خطأ في الاسم) نعيد قائمة فارغة
      print("QuranLocalDataSource Error: $e");
      return [];
    }
  }
}