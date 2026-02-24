import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/usecases/get_page_coordinates_usecase.dart';
import 'quran_overlay_event.dart';
import 'quran_overlay_state.dart';

class QuranOverlayBloc extends Bloc<QuranOverlayEvent, QuranOverlayState> {
  final GetPageCoordinatesUseCase _getPageCoordinatesUseCase;

  QuranOverlayBloc(this._getPageCoordinatesUseCase) : super(const QuranOverlayState()) {
    
    on<HighlightAyahEvent>((event, emit) async {
      // 1. جلب إحداثيات الصفحة كاملة
      final allCoordinates = await _getPageCoordinatesUseCase(
        pageNumber: event.pageNumber,
        mushafType: event.mushafType,
      );

      // 2. البحث عن الآية المطلوبة فقط
      // ملاحظة: الآية قد يكون لها أكثر من إحداثي (إذا كانت مقسومة على سطرين)
      final targetHighlights = allCoordinates
          .where((element) => element.ayahNumber == event.ayahNumber)
          .toList();

      // 3. إصدار حالة جديدة للرسم
      emit(QuranOverlayState(highlights: targetHighlights));
    });

    on<ClearHighlightEvent>((event, emit) {
      emit(const QuranOverlayState(highlights: []));
    });
  }
}