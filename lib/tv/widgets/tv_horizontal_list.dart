import 'package:flutter/material.dart';
import '../../data/models/program_item.dart';
import '../design/tv_theme.dart';
import 'tv_card.dart';

/// صف أفقي من بطاقات البرامج للتلفزيون
class TvHorizontalList extends StatefulWidget {
  final String title;
  final List<ProgramItem> items;
  final ValueChanged<ProgramItem>? onItemTap;
  final ValueChanged<ProgramItem>? onItemFocus;
  final bool autofocusFirst;

  const TvHorizontalList({
    super.key,
    required this.title,
    required this.items,
    this.onItemTap,
    this.onItemFocus,
    this.autofocusFirst = false,
  });

  @override
  State<TvHorizontalList> createState() => _TvHorizontalListState();
}

class _TvHorizontalListState extends State<TvHorizontalList> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // عنوان الصف
        Padding(
          padding: const EdgeInsets.only(
            right: TvTheme.paddingM,
            left: TvTheme.paddingM,
            bottom: 12,
          ),
          child: Text(
            widget.title,
            style: const TextStyle(
              color: TvTheme.onBackground,
              fontSize: TvTheme.fontSizeSubtitle,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        // القائمة الأفقية
        SizedBox(
          height: TvTheme.cardHeight + 16,
          child: ListView.separated(
            controller: _scrollController,
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(
              horizontal: TvTheme.paddingM,
            ),
            itemCount: widget.items.length,
            separatorBuilder: (_, __) =>
                const SizedBox(width: TvTheme.paddingS),
            itemBuilder: (context, index) {
              final item = widget.items[index];
              return TvCard(
                item: item,
                autofocus: widget.autofocusFirst && index == 0,
                onTap: () => widget.onItemTap?.call(item),
                onFocus: () => widget.onItemFocus?.call(item),
              );
            },
          ),
        ),
      ],
    );
  }
}
