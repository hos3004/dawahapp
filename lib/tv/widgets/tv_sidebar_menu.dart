import 'package:flutter/material.dart';
import '../design/tv_theme.dart';
import '../focus/tv_focus_manager.dart';

/// عناصر القائمة الجانبية
enum TvMenuItem {
  live,
  home,
  kids,
  search,
  guide,
  settings,
}

extension TvMenuItemExt on TvMenuItem {
  String get label {
    switch (this) {
      case TvMenuItem.live:
        return 'البث المباشر';
      case TvMenuItem.home:
        return 'البرامج';
      case TvMenuItem.kids:
        return 'للأطفال';
      case TvMenuItem.search:
        return 'البحث';
      case TvMenuItem.guide:
        return 'خريطة البرامج';
      case TvMenuItem.settings:
        return 'الإعدادات';
    }
  }

  IconData get icon {
    switch (this) {
      case TvMenuItem.live:
        return Icons.live_tv;
      case TvMenuItem.home:
        return Icons.home_rounded;
      case TvMenuItem.kids:
        return Icons.child_care;
      case TvMenuItem.search:
        return Icons.search;
      case TvMenuItem.guide:
        return Icons.calendar_today;
      case TvMenuItem.settings:
        return Icons.settings;
    }
  }
}

/// القائمة الجانبية للتلفزيون
class TvSidebarMenu extends StatelessWidget {
  final TvMenuItem selectedItem;
  final ValueChanged<TvMenuItem> onItemSelected;
  final bool expanded;

  const TvSidebarMenu({
    super.key,
    required this.selectedItem,
    required this.onItemSelected,
    this.expanded = true,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: TvTheme.animNormal,
      width: expanded
          ? TvTheme.sidebarWidth
          : TvTheme.sidebarCollapsedWidth,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF153B6E), // Daawah brand dark blue
            Color(0xFF0A192F), // Deep navy
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black54,
            blurRadius: 15,
            offset: Offset(-5, 0),
          )
        ],
      ),
      child: Column(
        children: [
          const SizedBox(height: TvTheme.paddingL),

          // لوجو
          if (expanded) ...[
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: TvTheme.paddingM,
              ),
              child: Image.asset(
                'assets/images/logo.png',
                height: 44,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Text(
                  'دعوة',
                  style: TextStyle(
                    color: TvTheme.accent,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: TvTheme.paddingL),
          ] else
            const SizedBox(height: TvTheme.paddingM),

          // عناصر القائمة
          ...TvMenuItem.values.map((item) => _SidebarItem(
                item: item,
                isSelected: item == selectedItem,
                expanded: expanded,
                onTap: () => onItemSelected(item),
              )),

          const Spacer(),
          const SizedBox(height: TvTheme.paddingM),
        ],
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final TvMenuItem item;
  final bool isSelected;
  final bool expanded;
  final VoidCallback onTap;

  const _SidebarItem({
    required this.item,
    required this.isSelected,
    required this.expanded,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return TvFocusable(
      onSelect: onTap,
      focusScale: 1.0,
      borderRadius: BorderRadius.zero,
      child: AnimatedContainer(
        duration: TvTheme.animFast,
        width: double.infinity,
        padding: EdgeInsets.symmetric(
          horizontal: expanded ? TvTheme.paddingM : TvTheme.paddingS,
          vertical: 14,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? TvTheme.accent.withAlpha(30)
              : Colors.transparent,
          border: Border(
            right: BorderSide(
              color: isSelected ? TvTheme.accent : Colors.transparent,
              width: 4,
            ),
          ),
        ),
        child: Row(
          children: [
            Icon(
              item.icon,
              color: isSelected ? TvTheme.accent : TvTheme.onSurfaceMuted,
              size: 26,
            ),
            if (expanded) ...[
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  item.label,
                  style: TextStyle(
                    color: isSelected
                        ? TvTheme.onBackground
                        : TvTheme.onSurfaceMuted,
                    fontSize: TvTheme.fontSizeBody,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
