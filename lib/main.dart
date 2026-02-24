import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:google_fonts/google_fonts.dart';

import 'data/repositories/program_repository.dart';
import 'local/app_localizations.dart';
import 'presentation/screens/home/home_screen.dart';
import 'presentation/screens/Splash_Screen/Splash_Screen.dart';
import 'presentation/screens/settings/settings_screen.dart';
// ✅ استيراد ملفات المصحف الجديد والهيكلية الجديدة
import 'core/services/service_locator.dart';
import 'features/quran/presentation/pages/quran_view_page.dart';

// ✅ استيراد البلوكات الرئيسية لرفع حالتها
import 'presentation/bloc/home/home_bloc.dart';
import 'presentation/bloc/home/home_event.dart';
import 'presentation/screens/categories/categories_screen.dart'; // لاستيراد CategoriesBloc إذا كان في ملف منفصل، أو استيراده من مسار البلوك

// ملاحظة: تأكد من مسار CategoriesBloc الصحيح

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // ✅ 1. تهيئة الخدمات الجديدة (Service Locator)
  await ServiceLocator.init();
  await initialize(); // nb_utils initialization

  textPrimaryColorGlobal = Colors.black;
  textSecondaryColorGlobal = Colors.grey.shade700;
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(
    // ✅ نقوم بإنشاء RepositoryProvider في الجذر
    RepositoryProvider<ProgramRepository>(
      create: (_) => ProgramRepository(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final baseLight = ThemeData(
      brightness: Brightness.light,
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      scaffoldBackgroundColor: Colors.grey[100],
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
    );
    final baseDark = ThemeData(
      brightness: Brightness.dark,
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.blue,
        brightness: Brightness.dark,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
    );

    // ✅ هنا نقوم برفع البلوكات (HomeBloc و CategoriesBloc)
    return MultiBlocProvider(
      providers: [
        // بلوك الرئيسية: يتم إنشاؤه مرة واحدة ويجلب البيانات فوراً
        BlocProvider<HomeBloc>(
          create: (context) => HomeBloc(
            programRepository: RepositoryProvider.of<ProgramRepository>(context),
          )..add(FetchHomeContent()),
        ),
        // بلوك التصنيفات
        BlocProvider<CategoriesBloc>(
          create: (context) => CategoriesBloc(
            RepositoryProvider.of<ProgramRepository>(context),
          )..add(FetchCategories()),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Daawah App',
        theme: baseLight.copyWith(
          textTheme: GoogleFonts.tajawalTextTheme(baseLight.textTheme).apply(
            bodyColor: Colors.black87,
            displayColor: Colors.black87,
          ),
        ),
        darkTheme: baseDark.copyWith(
          textTheme: GoogleFonts.tajawalTextTheme(baseDark.textTheme).apply(
            bodyColor: Colors.white,
            displayColor: Colors.white,
          ),
        ),
        themeMode: ThemeMode.system,
        locale: const Locale('ar'),
        supportedLocales: const [Locale('ar')],
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        initialRoute: '/',
        routes: {
          '/': (context) => const SplashScreen(),
          '/home': (context) => const HomeScreen(),
          '/settings': (context) => const SettingsScreen(),
          '/quran': (context) => const QuranViewPage(),
        },
        onGenerateRoute: (settings) {
          Widget page;
          switch (settings.name) {
            case '/home':
              page = const HomeScreen();
              break;
            case '/settings':
              page = const SettingsScreen();
              break;
            case '/quran':
              page = const QuranViewPage();
              break;
            default:
              page = const HomeScreen();
          }
          return PageRouteBuilder(
            settings: settings,
            pageBuilder: (_, __, ___) => page,
            transitionsBuilder: (_, anim, __, child) =>
                FadeTransition(opacity: anim, child: child),
            transitionDuration: const Duration(milliseconds: 350),
          );
        },
        builder: (context, child) {
          return Directionality(
            textDirection: TextDirection.rtl,
            child: child ?? const SizedBox.shrink(),
          );
        },
      ),
    );
  }
}