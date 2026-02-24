import '../../domain/entities/ayah_coordinates.dart';

class AyahCoordinatesModel extends AyahCoordinates {
  const AyahCoordinatesModel({
    required super.ayahNumber,
    required super.pageNumber,
    required super.surahNumber, // ✅
    required super.polygonData,
  });

  factory AyahCoordinatesModel.fromJson(Map<String, dynamic> json) {
    return AyahCoordinatesModel(
      ayahNumber: json['ayahNumber'] ?? 0,
      pageNumber: json['page_number'] ?? 0,
      surahNumber: json['surahNumber'] ?? 1, // ✅ قراءة رقم السورة من JSON
      // تأكدنا من اسم الحقل في ملف 001.json المرفق وهو "polygon"
      polygonData: json['polygon'] ?? "",
    );
  }
}