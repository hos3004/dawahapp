import 'package:flutter/material.dart';
import '../design/tv_theme.dart';
import '../widgets/tv_sidebar_menu.dart';
import '../screens/tv_home_screen.dart';
import '../screens/tv_kids_screen.dart';
import '../screens/tv_search_screen.dart';
import '../screens/tv_live_screen.dart';

/// هيكل التنقل الرئيسي للتلفزيون: Sidebar + Content
class TvNavigation extends StatefulWidget {
  const TvNavigation({super.key});

  @override
  State<TvNavigation> createState() => _TvNavigationState();
}

class _TvNavigationState extends State<TvNavigation> {
  TvMenuItem _selectedItem = TvMenuItem.home;

  Future<void> _selectItem(TvMenuItem item) async {
    if (item == TvMenuItem.live) {
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const TvLiveScreen()),
      );
      return;
    }

    setState(() => _selectedItem = item);
  }

  Widget _buildContent() {
    switch (_selectedItem) {
      case TvMenuItem.home:
      case TvMenuItem.guide:
      case TvMenuItem.settings:
        return TvHomeScreen(onItemTap: _onProgramTap);
      case TvMenuItem.kids:
        return TvKidsScreen(onItemTap: _onProgramTap);
      case TvMenuItem.search:
        return TvSearchScreen(onItemTap: _onProgramTap);
      case TvMenuItem.live:
        return TvHomeScreen(onItemTap: _onProgramTap);
    }
  }

  void _onProgramTap(dynamic item) {
    // Navigation إلى التفاصيل يتم من داخل الشاشات
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TvTheme.background,
      body: FocusTraversalGroup(
        policy: ReadingOrderTraversalPolicy(),
        child: Row(
          textDirection: TextDirection.rtl,
          children: [
            // نبقي القائمة ظاهرة دائماً على التلفزيون حتى لا تبدو وكأنها اختفت.
            TvSidebarMenu(
              selectedItem: _selectedItem,
              onItemSelected: _selectItem,
              expanded: true,
            ),

            Expanded(
              child: AnimatedSwitcher(
                duration: TvTheme.animNormal,
                child: KeyedSubtree(
                  key: ValueKey(_selectedItem),
                  child: _buildContent(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
