import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/program_item.dart';
import '../../presentation/bloc/home/home_bloc.dart';
import '../../presentation/bloc/home/home_state.dart';
import '../design/tv_theme.dart';
import '../widgets/tv_card.dart';
import 'tv_details_screen.dart';

/// شاشة البحث في التلفزيون
class TvSearchScreen extends StatefulWidget {
  final ValueChanged<ProgramItem>? onItemTap;

  const TvSearchScreen({super.key, this.onItemTap});

  @override
  State<TvSearchScreen> createState() => _TvSearchScreenState();
}

class _TvSearchScreenState extends State<TvSearchScreen> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  Timer? _debounce;
  List<ProgramItem> _allItems = [];
  List<ProgramItem> _results = [];

  @override
  void initState() {
    super.initState();
    _searchFocus.requestFocus();
    _loadAllPrograms();
    _controller.addListener(_onQueryChanged);
  }

  void _loadAllPrograms() {
    final state = context.read<HomeBloc>().state;
    if (state is HomeLoadSuccess) {
      final sliders = state.dynamicSliders;
      final all = sliders
          .expand((s) => s.programs)
          .map((p) => ProgramItem(
                id: p.id,
                title: p.title,
                image: p.image,
                postType: p.postType,
              ))
          .toList();
      final unique = {for (final p in all) p.id: p}.values.toList();
      setState(() => _allItems = unique);
    }
  }

  void _onQueryChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      final q = _controller.text.trim().toLowerCase();
      setState(() {
        _results = q.isEmpty
            ? []
            : _allItems
                .where((p) => p.title.toLowerCase().contains(q))
                .toList();
      });
    });
  }

  void _openDetails(ProgramItem item) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => TvDetailsScreen(item: item)),
    );
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(TvTheme.paddingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─ حقل البحث
          Container(
            decoration: BoxDecoration(
              color: TvTheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _searchFocus.hasFocus
                    ? TvTheme.focusBorder
                    : Colors.transparent,
                width: 2,
              ),
            ),
            child: TextField(
              controller: _controller,
              focusNode: _searchFocus,
              style: const TextStyle(
                color: TvTheme.onBackground,
                fontSize: TvTheme.fontSizeSubtitle,
              ),
              decoration: const InputDecoration(
                hintText: 'ابحث عن برنامج...',
                hintStyle: TextStyle(color: TvTheme.onSurfaceMuted),
                prefixIcon: Icon(Icons.search, color: TvTheme.onSurfaceMuted),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: TvTheme.paddingM,
                  vertical: 18,
                ),
              ),
              textDirection: TextDirection.rtl,
            ),
          ),

          const SizedBox(height: TvTheme.paddingL),

          // ─ النتائج
          if (_results.isEmpty && _controller.text.isNotEmpty)
            Expanded(
              child: Center(
                child: Text(
                  'لا توجد نتائج لـ "${_controller.text}"',
                  style: const TextStyle(
                    color: TvTheme.onSurfaceMuted,
                    fontSize: TvTheme.fontSizeBody,
                  ),
                ),
              ),
            )
          else if (_results.isNotEmpty)
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 5,
                  mainAxisSpacing: TvTheme.paddingS,
                  crossAxisSpacing: TvTheme.paddingS,
                  childAspectRatio: TvTheme.cardWidth / TvTheme.cardHeight,
                ),
                itemCount: _results.length,
                itemBuilder: (context, index) {
                  final item = _results[index];
                  return TvCard(
                    item: item,
                    onTap: () => _openDetails(item),
                  );
                },
              ),
            )
          else
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.search,
                      color: TvTheme.onSurfaceMuted,
                      size: 80,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'ابدأ الكتابة للبحث',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: TvTheme.onSurfaceMuted,
                          ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
