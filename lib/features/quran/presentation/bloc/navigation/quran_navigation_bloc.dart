import 'package:flutter_bloc/flutter_bloc.dart';
import 'quran_navigation_event.dart';
import 'quran_navigation_state.dart';

class QuranNavigationBloc extends Bloc<QuranNavigationEvent, QuranNavigationState> {
  // ثوابت حدود الصفحات (مصحف المدينة)
  static const int _minPage = 1;
  static const int _maxMadinaPages = 604; 

  QuranNavigationBloc() : super(const QuranNavigationState()) {
    
    on<ChangePageEvent>((event, emit) {
      // ✅ ضمان أن رقم الصفحة دائماً بين 1 و 604
      final int safePage = event.pageNumber.clamp(_minPage, _maxMadinaPages);
      emit(state.copyWith(currentPage: safePage));
    });

    on<ChangeMushafTypeEvent>((event, emit) {
      emit(state.copyWith(mushafType: event.mushafType));
    });
  }
}