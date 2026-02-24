import '../entities/ayah_coordinates.dart';
import '../../data/models/reciter_model.dart';
// ✅ استيراد مودل SurahIndex
import '../../../../data/models/quran_models.dart';

abstract class QuranRepository {
  /// جلب إحداثيات آيات صفحة معينة بناءً على نوع المصحف
  Future<List<AyahCoordinates>> getPageCoordinates({
    required int pageNumber,
    required String mushafType,
  });

  /// جلب قائمة القرّاء المتاحين للصوتيات
  Future<List<ReciterModel>> getReciters();

  // ✅ إضافة الدالة المفقودة هنا
  Future<List<SurahIndex>> getSurahIndex();
}