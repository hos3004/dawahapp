import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import '../data/repositories/program_repository.dart';
import '../local/app_localizations.dart';
import '../presentation/bloc/home/home_bloc.dart';
import '../presentation/bloc/home/home_event.dart';
import '../presentation/screens/categories/categories_screen.dart';
import 'design/tv_theme.dart';
import 'navigation/tv_navigation.dart';

/// نقطة دخول تطبيق التلفزيون
class TvApp extends StatefulWidget {
  const TvApp({super.key});

  @override
  State<TvApp> createState() => _TvAppState();
}

class _TvAppState extends State<TvApp> {
  @override
  void initState() {
    super.initState();
    // TV يعمل دائماً في Landscape
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    // إخفاء شريط الحالة للـ immersive experience
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.leanBack);
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<HomeBloc>(
          create: (context) => HomeBloc(
            programRepository: RepositoryProvider.of<ProgramRepository>(context),
          )..add(FetchHomeContent()),
        ),
        BlocProvider<CategoriesBloc>(
          create: (context) =>
              CategoriesBloc(RepositoryProvider.of<ProgramRepository>(context)),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'دعوة TV',
        theme: TvTheme.themeData,
        locale: const Locale('ar'),
        supportedLocales: const [Locale('ar')],
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        builder: (context, child) => Directionality(
          textDirection: TextDirection.rtl,
          child: child ?? const SizedBox.shrink(),
        ),
        home: const TvNavigation(),
      ),
    );
  }
}
