import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;

import 'data/repositories/program_repository.dart';
import 'local/app_localizations.dart';
import 'presentation/screens/home/home_screen.dart';
import 'presentation/screens/Splash_Screen/Splash_Screen.dart';
import 'presentation/screens/settings/settings_screen.dart';
import 'core/services/service_locator.dart';
import 'features/quran/presentation/pages/quran_view_page.dart';
import 'presentation/bloc/home/home_bloc.dart';
import 'presentation/bloc/home/home_event.dart';
import 'presentation/screens/categories/categories_screen.dart';
import 'core/services/notification_service.dart';
import 'core/services/notification_router.dart';
import 'presentation/screens/live_stream/live_stream_screen.dart';
import 'tv/tv_app.dart';
import 'tv/services/tv_platform.dart';

// Global Navigator Key
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!kIsWeb) {
    await Firebase.initializeApp();
  }

  await ServiceLocator.init();
  await initialize();

  textPrimaryColorGlobal = Colors.black;
  textSecondaryColorGlobal = Colors.grey.shade700;

  final isAndroidTv = await TvPlatform.isAndroidTv();

  // ✅ للموبايل فقط: إجبار Portrait. التلفزيون يتعامل مع التوجه بنفسه.
  if (!isAndroidTv) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  runApp(
    RepositoryProvider<ProgramRepository>(
      create: (_) => ProgramRepository(),
      child: isAndroidTv ? const TvApp() : const MyApp(),
    ),
  );

  // تأجيل تهيئة الإشعارات - للموبايل فقط
  if (!kIsWeb && !isAndroidTv) {
    Future.microtask(() async {
      try {
        await NotificationService().init();
        NotificationService.notificationStream.listen((payload) {
          final context = navigatorKey.currentContext;
          if (payload != null && context != null && context.mounted) {
            NotificationRouter.navigate(context, payload);
          }
        });
      } catch (e) {
        debugPrint('Deferred init error: $e');
      }
    });
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
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

    return MultiBlocProvider(
      providers: [
        BlocProvider<HomeBloc>(
          create: (context) => HomeBloc(
            programRepository: RepositoryProvider.of<ProgramRepository>(
              context,
            ),
          )..add(FetchHomeContent()),
        ),
        BlocProvider<CategoriesBloc>(
          create: (context) =>
              CategoriesBloc(RepositoryProvider.of<ProgramRepository>(context)),
        ),
      ],
      child: MaterialApp(
        navigatorKey: navigatorKey,
        debugShowCheckedModeBanner: false,
        title: 'Daawah App',
        theme: baseLight.copyWith(
          textTheme: GoogleFonts.tajawalTextTheme(
            baseLight.textTheme,
          ).apply(bodyColor: Colors.black87, displayColor: Colors.black87),
        ),
        darkTheme: baseDark.copyWith(
          textTheme: GoogleFonts.tajawalTextTheme(
            baseDark.textTheme,
          ).apply(bodyColor: Colors.white, displayColor: Colors.white),
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
          // ✅ 3. إضافة المسارات الناقصة لضمان عدم حدوث خطأ
          '/live_stream': (context) =>
              LiveStreamScreen(tabIndex: 0, tabNotifier: ValueNotifier(0)),
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
            // ✅ معالجة حالة البث المباشر
            case '/live_stream':
              page =
                  LiveStreamScreen(tabIndex: 0, tabNotifier: ValueNotifier(0));
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
