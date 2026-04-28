import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:convex_bottom_bar/convex_bottom_bar.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../data/models/program_item.dart';

import '../../bloc/home/home_bloc.dart';
import '../../bloc/home/home_event.dart';
import '../../bloc/home/home_state.dart';

import '../../widgets/banner_slider.dart';
import '../../widgets/horizontal_program_row.dart';
import '../live_stream/live_stream_screen.dart';
import '../categories/categories_screen.dart';
import 'typed_content_tab.dart';
import '../blog/blog_list_screen.dart';
import '../../../core/utils/media_control.dart';

import '../tiktok_feed/daawah_tiktok_screen.dart';
import '../search/search_screen.dart';
import '../../../features/quran/presentation/pages/quran_view_page.dart';
import '../../../features/athkar/presentation/athkar_landing_screen.dart';
import '../../widgets/nested_navigator.dart';

/// ===== KeepAliveWrapper =====
class KeepAliveWrapper extends StatefulWidget {
  final Widget child;
  final bool keepAlive;
  const KeepAliveWrapper({
    super.key,
    required this.child,
    required this.keepAlive,
  });
  @override
  State<KeepAliveWrapper> createState() => _KeepAliveWrapperState();
}

class _KeepAliveWrapperState extends State<KeepAliveWrapper>
    with AutomaticKeepAliveClientMixin {
  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }

  @override
  bool get wantKeepAlive => widget.keepAlive;
}

class _LogoHeader extends StatelessWidget {
  const _LogoHeader();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Container(
        height: 72,
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16.0),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // --- ⚠️ التعديل هنا: وضع اللوجو في اليمين ---
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(right: 50.0),
                child: Image.asset(
                  'assets/images/logo.png',
                  height: 44,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            // ------------------------------------------

            // الأيقونات تبقى في اليسار كما هي
            Align(
              alignment: Alignment.centerLeft,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.settings_outlined,
                      color: Colors.grey[700],
                      size: 28.0,
                    ),
                    onPressed: () {
                      MediaControl.sendPauseSignal(); // أرسل إشارة التوقف
                      Navigator.of(context, rootNavigator: true)
                          .pushNamed('/settings');
                    },
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.search,
                      color: Colors.grey[700],
                      size: 28.0,
                    ),
                    onPressed: () {
                      MediaControl.sendPauseSignal(); // أرسل إشارة التوقف
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SearchScreen(),
                        ),
                      );
                    },
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.category_outlined,
                      color: Colors.grey[700],
                      size: 28.0,
                    ),
                    onPressed: () {
                      MediaControl.sendPauseSignal(); // أرسل إشارة التوقف

                      // Navigate to Categories (Index 5)
                      // We need to access the parent HomeScreen state to switch tabs
                      final homeScreenState =
                          context.findAncestorStateOfType<_HomeScreenState>();
                      homeScreenState?._switchToCategories();
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// =====================
/// HomeSectionContainer
/// =====================
class HomeSectionContainer extends StatefulWidget {
  final Function(ProgramItem tappedItem) onStaticItemTap;
  final int bottomNavIndex;
  const HomeSectionContainer({
    super.key,
    required this.onStaticItemTap,
    required this.bottomNavIndex,
  });
  @override
  State<HomeSectionContainer> createState() => _HomeSectionContainerState();
}

class _HomeSectionContainerState extends State<HomeSectionContainer>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final List<bool> _visitedTabs =
      List.generate(5, (index) => index == 0); // التبويب الأول مزار افتراضياً

  final List<Tab> _tabs = const <Tab>[
    Tab(text: 'الرئيسية'),
    Tab(text: 'البرامج'),
    Tab(text: 'الأفلام'),
    Tab(text: 'الفيديو'),
    Tab(text: 'المقالات'),
  ];
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(() {
      if (!_visitedTabs[_tabController.index]) {
        setState(() {
          _visitedTabs[_tabController.index] = true;
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: _tabs.length,
      child: Column(
        children: [
          const _LogoHeader(),
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [Color(0xFF1C4E8E), Color(0xFF2576DF)],
              ),
            ),
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: TabBar(
              controller: _tabController,
              tabs: _tabs,
              isScrollable: true,
              indicatorColor: Colors.white,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              labelStyle: GoogleFonts.tajawal(
                fontWeight: FontWeight.bold,
                fontSize: 15, // يمكنك تعديل الحجم حسب الرغبة
              ),
              unselectedLabelStyle: GoogleFonts.tajawal(
                fontWeight: FontWeight.normal,
                fontSize: 15,
              ),
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: <Widget>[
                // ✅ 1. الرئيسية (تم إزالة BlocProvider المحلي واستخدام KeepAlive)
                KeepAliveWrapper(
                  keepAlive: true,
                  child: HomeContentWidget(
                    // تمرير دالة عند الضغط على شريط البث المباشر
                    onLiveTap: () {
                      MediaControl.sendPauseSignal(); // أرسل إشارة التوقف
                      // نستخدم آلية التنقل الموجودة في HomeScreen
                      // عن طريق إرسال عنصر وهمي نوعه live_stream
                      widget.onStaticItemTap(
                        const ProgramItem(
                          id: 0,
                          title: "Live",
                          postType: "live_stream",
                        ),
                      );
                    },
                  ),
                ),

                // 2. البرامج
                _visitedTabs[1]
                    ? const KeepAliveWrapper(
                        keepAlive: true,
                        child: TypedContentTab(contentType: 'tv_show'),
                      )
                    : const SizedBox.shrink(),
                // 3. الأفلام
                _visitedTabs[2]
                    ? const KeepAliveWrapper(
                        keepAlive: true,
                        child: TypedContentTab(contentType: 'movie'),
                      )
                    : const SizedBox.shrink(),
                // 4. الفيديو
                _visitedTabs[3]
                    ? const KeepAliveWrapper(
                        keepAlive: true,
                        child: TypedContentTab(contentType: 'video'),
                      )
                    : const SizedBox.shrink(),
                // 5. المقالات
                _visitedTabs[4]
                    ? const KeepAliveWrapper(
                        keepAlive: true,
                        child: BlogListScreen(),
                      )
                    : const SizedBox.shrink(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// =====================
/// HomeContentWidget
/// =====================
class HomeContentWidget extends StatelessWidget {
  final VoidCallback? onLiveTap; // استقبال دالة الضغط
  const HomeContentWidget({super.key, this.onLiveTap});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeBloc, HomeState>(
      builder: (context, state) {
        if (state is HomeLoading || state is HomeInitial) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state is HomeLoadFailure) {
          return Center(
            child: Text(
              'خطأ: ${state.error}',
              style: const TextStyle(color: Colors.white70),
            ),
          );
        }
        if (state is HomeLoadSuccess) {
          final hasBanners = state.bannerItems.isNotEmpty;
          // العنصر الأول هو الشريط + (البانر إن وجد) + السلايدرات الديناميكية
          final itemCount =
              1 + (hasBanners ? 1 : 0) + state.dynamicSliders.length;

          // ✅ إضافة ميزة السحب للتحديث (Pull-to-Refresh)
          return RefreshIndicator(
            onRefresh: () async {
              context.read<HomeBloc>().add(RefreshHomeContent());
              // انتظار بسيط ليعطي انطباعاً بالاستجابة
              await Future.delayed(const Duration(seconds: 1));
            },
            child: CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.only(top: 10), // هامش علوي بسيط
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      // 1. الشريط الجديد (دائماً في الاندكس 0)
                      if (index == 0) {
                        return _buildLiveStreamBar();
                      }

                      // تعديل الاندكس لباقي العناصر
                      int adjustedIndex = index - 1;

                      // 2. البانر (إذا وجد)
                      if (hasBanners) {
                        if (adjustedIndex == 0) {
                          return BannerSlider(items: state.bannerItems);
                        }
                        adjustedIndex--; // تحريك المؤشر للعناصر التالية
                      }

                      // 3. السلايدرات الديناميكية
                      if (adjustedIndex >= 0 &&
                          adjustedIndex < state.dynamicSliders.length) {
                        final slider = state.dynamicSliders[adjustedIndex];
                        return HorizontalProgramRow(
                          title: slider.title,
                          programs: slider.programs,
                          rowHeight: 280.0,
                          cardAspectRatio: 2 / 3,
                          cardWidth: 150.0,
                        );
                      }

                      return const SizedBox.shrink();
                    }, childCount: itemCount),
                  ),
                ),
              ],
            ),
          );
        }
        return const Center(
          child: Text(
            'حالة غير معروفة',
            style: TextStyle(color: Colors.white70),
          ),
        );
      },
    );
  }

  // ✅ بناء شريط البث المباشر
  Widget _buildLiveStreamBar() {
    return Padding(
      // جعل العرض متوافقاً مع الهوامش القياسية، مع ترك مسافة 8 بكسل من الأسفل
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: InkWell(
        onTap: onLiveTap,
        borderRadius: BorderRadius.circular(15), // ليتناسب مع تأثير الضغط
        child: Container(
          height: 40, // الارتفاع المطلوب
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.red[600] ?? Colors.red, // لون أحمر مميز للبث
            borderRadius: BorderRadius.circular(15), // حواف منحنية
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.live_tv, color: Colors.white, size: 24),
              SizedBox(width: 8),
              Text(
                "تابعوا البث الحي لقناة دعوة",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// =====================
/// HomeScreen
/// =====================
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  late List<Widget?> _tabCache;

  late HomeSectionContainer _homeSectionContainer;

  // Keys for Nested Navigators
  final _homeKey = GlobalKey<NavigatorState>();
  final _liveKey = GlobalKey<NavigatorState>();
  final _tiktokKey = GlobalKey<NavigatorState>();
  final _quranKey = GlobalKey<NavigatorState>();
  final _azkarKey = GlobalKey<NavigatorState>();
  final _categoriesKey = GlobalKey<NavigatorState>();

  // Notifier for active tab index
  final ValueNotifier<int> _tabNotifier = ValueNotifier<int>(0);

  @override
  void initState() {
    super.initState();
    _tabCache = List.filled(6, null);
    _homeSectionContainer = HomeSectionContainer(
      onStaticItemTap: _handleStaticItemTap,
      bottomNavIndex: _selectedIndex,
    );
    // بناء تبويب الرئيسية فقط في البداية
    _tabCache[0] = NestedNavigator(
      navigatorKey: _homeKey,
      home: _homeSectionContainer,
    );
  }

  @override
  void dispose() {
    _tabNotifier.dispose();
    super.dispose();
  }

  // ✅ استدعاء وبناء التبويبات عند الحاجة إليها فقط (Lazy Loading)
  Widget _getTab(int index) {
    if (_tabCache[index] != null) return _tabCache[index]!;

    Widget tabWidget;
    switch (index) {
      case 0:
        tabWidget = NestedNavigator(
          navigatorKey: _homeKey,
          home: _homeSectionContainer,
        );
        break;
      case 1:
        tabWidget = NestedNavigator(
          navigatorKey: _liveKey,
          home: LiveStreamScreen(
            tabIndex: 1,
            tabNotifier: _tabNotifier,
            isInTabView: false,
          ),
        );
        break;
      case 2:
        tabWidget = NestedNavigator(
          navigatorKey: _tiktokKey,
          home: DaawahTikTokScreen(tabNotifier: _tabNotifier),
        );
        break;
      case 3:
        tabWidget = NestedNavigator(
          navigatorKey: _quranKey,
          home: const QuranViewPage(),
        );
        break;
      case 4:
        tabWidget = NestedNavigator(
          navigatorKey: _azkarKey,
          home: const AthkarLandingScreen(),
        );
        break;
      case 5:
        tabWidget = NestedNavigator(
          navigatorKey: _categoriesKey,
          home: const CategoriesScreen(),
        );
        break;
      default:
        tabWidget = const SizedBox.shrink();
    }

    _tabCache[index] = tabWidget;
    return tabWidget;
  }

  void _handleStaticItemTap(ProgramItem tappedItem) {
    if (tappedItem.postType == "live_stream") {
      _onItemTapped(1);
    } else {
      debugPrint("Navigation handled by widget");
    }
  }

  void _onItemTapped(int index) {
    // أرسل إشارة التوقف عند التنقل لأي تبويب (حتى تبويب الرئيسية نفسه لضمان التوقف)
    MediaControl.sendPauseSignal();

    setState(() {
      if (_selectedIndex == index) {
        // إذا كان المستخدم يضغط على نفس التبويب الذي هو فيه بالفعل
        if (index == 0) {
          // تفريغ الـ Navigator الداخلي للعودة للصفحة الرئيسية (أول تبويب داخلي)
          _homeKey.currentState?.popUntil((route) => route.isFirst);

          // إعادة بناء HomeSectionContainer لضمان عودة الـ TabController للتبويب الأول (الرئيسية)
          _homeSectionContainer = HomeSectionContainer(
            // نستخدم key جديد لإجبار الـ Widget على إعادة البناء وتهيئة TabController من الصفر
            key: UniqueKey(),
            onStaticItemTap: _handleStaticItemTap,
            bottomNavIndex: _selectedIndex,
          );
          _tabCache[0] = NestedNavigator(
            navigatorKey: _homeKey,
            home: _homeSectionContainer,
          );
        }
      } else {
        // تغيير التبويب العادي
        _selectedIndex = index;
        _tabNotifier.value = index; // Update notifier
        if (index == 0) {
          _homeSectionContainer = HomeSectionContainer(
            onStaticItemTap: _handleStaticItemTap,
            bottomNavIndex: _selectedIndex,
          );
          _tabCache[0] = NestedNavigator(
            navigatorKey: _homeKey,
            home: _homeSectionContainer,
          );
        }
      }
    });
  }

  void _switchToCategories() {
    // ✅ جلب التصنيفات فقط عند النقر المباشر للتبويب لمنع التنزيل في شاشة البداية
    final bloc = context.read<CategoriesBloc>();
    if (bloc.state is CategoriesInitial) {
      bloc.add(FetchCategories());
    }

    setState(() {
      _selectedIndex = 5; // Categories Index
    });
  }

  Future<bool> _onWillPop() async {
    final NavigatorState? currentNavigator = _getCurrentNavigator();
    if (currentNavigator != null && currentNavigator.canPop()) {
      currentNavigator.pop();
      return false;
    }

    // If we are in Categories (5), go back to Home (0)
    if (_selectedIndex == 5) {
      _onItemTapped(0);
      return false;
    }

    // If we are not on Home (0), go to Home
    if (_selectedIndex != 0) {
      _onItemTapped(0);
      return false;
    }

    return true; // Exit app
  }

  NavigatorState? _getCurrentNavigator() {
    switch (_selectedIndex) {
      case 0:
        return _homeKey.currentState;
      case 1:
        return _liveKey.currentState;
      case 2:
        return _tiktokKey.currentState;
      case 3:
        return _quranKey.currentState;
      case 4:
        return _azkarKey.currentState;
      case 5:
        return _categoriesKey.currentState;
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color activeColor = Colors.red[600] ?? Colors.red;
    final Color inactiveColor = Colors.grey[400] ?? Colors.grey;

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        extendBodyBehindAppBar: false,
        body: Stack(
          children: [
            Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage("assets/images/bbg.jpg"),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            IndexedStack(
              index: _selectedIndex,
              children: List.generate(6, (index) {
                // نبني فقط التبويب المحدد حالياً أو التبويبات التي تم بناؤها مسبقاً
                if (index == _selectedIndex || _tabCache[index] != null) {
                  return _getTab(index);
                }
                return const SizedBox
                    .shrink(); // Placeholder للتبويبات غير المزارة
              }),
            ),
          ],
        ),
        bottomNavigationBar: ConvexAppBar(
          style: TabStyle.reactCircle,
          backgroundColor: Colors.white,
          color: inactiveColor,
          activeColor: activeColor,
          elevation: 5,
          height: 60,
          items: const [
            TabItem(
              icon: Icons.home_outlined,
              activeIcon: Icons.home,
              title: 'الرئيسية',
            ),
            TabItem(
              icon: Icons.live_tv_outlined,
              activeIcon: Icons.live_tv,
              title: 'بث مباشر',
            ),
            TabItem(
              icon: Icons.video_library_outlined,
              activeIcon: Icons.video_library,
              title: 'تيك توك',
            ),
            TabItem(
              icon: Icons.menu_book_outlined,
              activeIcon: Icons.menu_book,
              title: 'مصحف',
            ),
            TabItem(
              icon: Icons.auto_stories_outlined,
              activeIcon: Icons.auto_stories,
              title: 'أذكار',
            ),
          ],
          // If index is 5 (Categories), we can either show no selection or keep the last one.
          // ConvexAppBar might error if index is out of bounds.
          // Let's try to trick it or use a valid index.
          // A common trick is to set it to a valid index but maybe visually different?
          // Or we can just let it be 0 (Home) if it's 5.
          // But that would highlight Home.
          // Let's check if we can pass a controller.
          // For now, let's clamp it. If 5, show 0? Or maybe just don't update if 5?
          // Actually, if we are in Categories, maybe we shouldn't show the bottom bar?
          // User asked for bottom bar to be visible.
          // If I set initialActiveIndex to 5, it will crash.
          // Let's use `_selectedIndex > 4 ? 0 : _selectedIndex` for now and see.
          initialActiveIndex: _selectedIndex > 4 ? 0 : _selectedIndex,
          onTap: _onItemTapped,
        ),
      ),
    );
  }
}
