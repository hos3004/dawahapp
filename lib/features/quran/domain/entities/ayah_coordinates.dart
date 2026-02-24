import 'package:equatable/equatable.dart';

class AyahCoordinates extends Equatable {
  final int ayahNumber;
  final int pageNumber;
  final int surahNumber; // ✅ إضافة رقم السورة
  final String polygonData; // سلسلة نصية تحتوي النقاط: "x,y x,y ..."

  const AyahCoordinates({
    required this.ayahNumber,
    required this.pageNumber,
    required this.surahNumber, // ✅
    required this.polygonData,
  });

  @override
  List<Object?> get props => [ayahNumber, pageNumber, polygonData];
}