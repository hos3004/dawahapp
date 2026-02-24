// [ تم التعديل ليتوافق مع الـ Lifted State و Caching ]

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

import '../tiktok_feed/daawah_tiktok_screen.dart';
import '../search/search_screen.dart';
import '../../../features/quran/presentation/pages/quran_view_page.dart';

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

/// ===== Logo Header =====
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
            Center(
              child: Image.asset(
                'assets/images/logo.png',
                height: 44,
                fit: BoxFit.contain,
              ),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(Icons.settings_outlined, color: Colors.grey[700], size: 28.0),
                    onPressed: () => Navigator.pushNamed(context, '/settings'),
                  ),
                  IconButton(
                    icon: Icon(Icons.search, color: Colors.grey[700], size: 28.0),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const SearchScreen()),
                      );
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
                colors: [
                  Color(0xFF1C4E8E),
                  Color(0xFF2576DF),
                ],
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
                const KeepAliveWrapper(
                  keepAlive: true,
                  child: HomeContentWidget(),
                ),

                // 2. البرامج
                const KeepAliveWrapper(
                  keepAlive: true,
                  child: TypedContentTab(contentType: 'tv_show'),
                ),
                // 3. الأفلام
                const KeepAliveWrapper(
                  keepAlive: true,
                  child: TypedContentTab(contentType: 'movie'),
                ),
                // 4. الفيديو
                const KeepAliveWrapper(
                  keepAlive: true,
                  child: TypedContentTab(contentType: 'video'),
                ),
                // 5. المقالات
                const KeepAliveWrapper(
                  keepAlive: true,
                  child: BlogListScreen(),
                ),
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
  const HomeContentWidget({super.key});
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
          final itemCount = state.dynamicSliders.length + (state.bannerItems.isNotEmpty ? 1 : 0);

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
                  padding: const EdgeInsets.only(top: 0),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                          (context, index) {
                        if (index == 0 && state.bannerItems.isNotEmpty) {
                          return BannerSlider(items: state.bannerItems);
                        }
                        final sliderIndex = state.bannerItems.isNotEmpty ? index - 1 : index;
                        if (sliderIndex < 0 || sliderIndex >= state.dynamicSliders.length) {
                          return const SizedBox.shrink();
                        }
                        final slider = state.dynamicSliders[sliderIndex];
                        return HorizontalProgramRow(
                          title: slider.title,
                          programs: slider.programs,
                          rowHeight: 280.0,
                          cardAspectRatio: 2 / 3,
                          cardWidth: 150.0,
                        );
                      },
                      childCount: itemCount,
                    ),
                  ),
                ),
              ],
            ),
          );
        }
        return const Center(
          child: Text('حالة غير معروفة', style: TextStyle(color: Colors.white70)),
        );
      },
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
  int _selectedIndex = 1;
  late List<Widget> _widgetOptions;

  final CategoriesScreen _categoriesScreen = const CategoriesScreen();
  late HomeSectionContainer _homeSectionContainer;

  @override
  void initState() {
    super.initState();
    _homeSectionContainer = HomeSectionContainer(
      onStaticItemTap: _handleStaticItemTap,
      bottomNavIndex: _selectedIndex,
    );
    _buildWidgetOptions();
  }

  void _buildWidgetOptions() {
    _widgetOptions = <Widget>[
      _categoriesScreen, // 0
      _homeSectionContainer, // 1
      LiveStreamScreen(
        tabIndex: 2,
        currentIndex: _selectedIndex,
        isInTabView: false,
      ), // 2
      DaawahTikTokScreen(
        isScreenActive: _selectedIndex == 3,
      ), // 3
      const QuranViewPage(), // 4
    ];
  }

  void _handleStaticItemTap(ProgramItem tappedItem) {
    if (tappedItem.postType == "live_stream") {
      _onItemTapped(2);
    } else {
      debugPrint("Navigation handled by widget");
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      if (index == 1) {
        _homeSectionContainer = HomeSectionContainer(
          onStaticItemTap: _handleStaticItemTap,
          bottomNavIndex: _selectedIndex,
        );
      }
      _buildWidgetOptions();
    });
  }

  @override
  Widget build(BuildContext context) {
    final Color activeColor = Colors.red[600] ?? Colors.red;
    final Color inactiveColor = Colors.grey[400] ?? Colors.grey;

    return Scaffold(
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
            children: _widgetOptions,
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
            icon: Icons.category_outlined,
            activeIcon: Icons.category,
            title: 'تصنيفات',
          ),
          TabItem(
            icon: Icons.home_outlined,
            activeIcon: Icons.home,
            title: 'الرئيسية',
          ),
          TabItem(
            icon: Icons.live_tv_outlined,
            activeIcon: Icons.live_tv,
            title: 'البث المباشر',
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
        ],
        initialActiveIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}