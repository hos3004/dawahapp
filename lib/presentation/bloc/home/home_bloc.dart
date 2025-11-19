import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/repositories/program_repository.dart';
import 'home_event.dart';
import 'home_state.dart';
// import '../../../data/models/program_item.dart'; // <-- لم نعد بحاجة لهذا
// import '../../../data/models/program_slider.dart'; // <-- ولم نعد بحاجة لهذا

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final ProgramRepository _programRepository;
  HomeBloc({required ProgramRepository programRepository})
      : _programRepository = programRepository,
        super(HomeInitial()) {

    on<FetchHomeContent>(_onFetchHomeContent);
  }

  Future<void> _onFetchHomeContent(
      FetchHomeContent event,
      Emitter<HomeState> emit,
      ) async {
    emit(HomeLoading());
    try {
      // 1. جلب البيانات ككائن DashboardData
      final dashboardData = await _programRepository.getHomeContent();

      // 2. إزالة تحليل الـ Map القديم
      // final List<ProgramItem> staticItems = homeContent['static_items'] as List<ProgramItem>;
      // final List<ProgramSlider> dynamicSliders = homeContent['dynamic_sliders'] as List<ProgramSlider>;

      // 3. إرسال البيانات الجديدة إلى الحالة
      emit(HomeLoadSuccess(
        // staticItems: staticItems, // <-- تغيير هذا
        bannerItems: dashboardData.banner, // <-- إلى هذا
        dynamicSliders: dashboardData.sliders,
      ));
    } catch (e) {
      emit(HomeLoadFailure(error: e.toString()));
    }
  }
}