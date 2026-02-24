import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/repositories/program_repository.dart';
import 'home_event.dart';
import 'home_state.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final ProgramRepository _programRepository;

  HomeBloc({required ProgramRepository programRepository})
      : _programRepository = programRepository,
        super(HomeInitial()) {

    on<FetchHomeContent>(_onFetchHomeContent);
    on<RefreshHomeContent>(_onRefreshHomeContent); // ✅ إضافة الحدث الجديد
  }

  Future<void> _onFetchHomeContent(
      FetchHomeContent event,
      Emitter<HomeState> emit,
      ) async {
    // إذا كانت البيانات محملة بالفعل، لا نعيد إرسال Loading
    if (state is! HomeLoadSuccess) {
      emit(HomeLoading());
    }

    try {
      // هنا الريبو سيقرر: هل يستخدم الكاش أم يجلب من النت
      final dashboardData = await _programRepository.getHomeContent();

      emit(HomeLoadSuccess(
        bannerItems: dashboardData.banner,
        dynamicSliders: dashboardData.sliders,
      ));
    } catch (e) {
      emit(HomeLoadFailure(error: e.toString()));
    }
  }

  Future<void> _onRefreshHomeContent(
      RefreshHomeContent event,
      Emitter<HomeState> emit,
      ) async {
    try {
      // ⚠️ نرسل forceRefresh: true لإجبار التحديث
      final dashboardData = await _programRepository.getHomeContent(forceRefresh: true);

      emit(HomeLoadSuccess(
        bannerItems: dashboardData.banner,
        dynamicSliders: dashboardData.sliders,
      ));
    } catch (e) {
      // في حالة التحديث اليدوي، لا نغير الحالة للفشل إذا كان هناك بيانات معروضة بالفعل
      // يمكن فقط طباعة الخطأ أو إظهار رسالة عبر Listener في الواجهة
      print("Refresh failed: $e");
    }
  }
}