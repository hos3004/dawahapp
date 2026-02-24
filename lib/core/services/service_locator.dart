import 'package:get_it/get_it.dart';
import 'audio_service.dart';
// سنضيف الـ Repositories والـ Blocs هنا لاحقاً عند إنشائهم
import '../../features/quran/data/datasources/quran_local_datasource.dart';
import '../../features/quran/data/repositories/quran_repository_impl.dart';
import '../../features/quran/domain/repositories/quran_repository.dart';
import '../../features/quran/domain/usecases/get_page_coordinates_usecase.dart';
import '../../features/quran/presentation/bloc/navigation/quran_navigation_bloc.dart';
import '../../features/quran/presentation/bloc/audio/quran_audio_bloc.dart';
import '../../features/quran/presentation/bloc/overlay/quran_overlay_bloc.dart';


final getIt = GetIt.instance;

class ServiceLocator {
  static Future<void> init() async {
    // 1. Core Services (خدمات عامة لكل التطبيق)
    // تسجيل خدمة الصوت كـ Singleton (نسخة واحدة طوال عمر التطبيق)
    getIt.registerLazySingleton<AudioService>(() => AudioService());


// 1. Data Sources
    getIt.registerLazySingleton<QuranLocalDataSource>(
      () => QuranLocalDataSourceImpl(),
    );

    // 2. Repository
    getIt.registerLazySingleton<QuranRepository>(
      () => QuranRepositoryImpl(localDataSource: getIt()),
    );

    // 3. Use Cases
    getIt.registerLazySingleton<GetPageCoordinatesUseCase>(
      () => GetPageCoordinatesUseCase(getIt()),
    );


// --- Blocs Registration ---
    getIt.registerFactory(() => QuranNavigationBloc());

    // AudioBloc يحتاج AudioService
    getIt.registerFactory(() => QuranAudioBloc(
      getIt<AudioService>(),
      getIt<QuranRepository>(),
    ));

    getIt.registerFactory(() => QuranOverlayBloc(getIt()));
  }
}