import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/program_item.dart';
import '../../presentation/bloc/home/home_bloc.dart';
import '../../presentation/bloc/home/home_state.dart';
import '../design/tv_theme.dart';
import '../widgets/tv_banner_slider.dart';
import '../widgets/tv_card.dart';
import '../widgets/tv_ambient_background.dart';
import 'tv_details_screen.dart';

/// شاشة الأطفال للتلفزيون - بانر + شبكة برامج
class TvKidsScreen extends StatefulWidget {
  final ValueChanged<ProgramItem>? onItemTap;

  const TvKidsScreen({super.key, this.onItemTap});

  @override
  State<TvKidsScreen> createState() => _TvKidsScreenState();
}

class _TvKidsScreenState extends State<TvKidsScreen> {
  List<ProgramItem> _bannerItems = [];
  List<ProgramItem> _programItems = [];
  String? _focusedImageUrl;

  @override
  void initState() {
    super.initState();
    _loadKidsData();
  }

  void _loadKidsData() {
    final state = context.read<HomeBloc>().state;
    if (state is HomeLoadSuccess) {
      final sliders = state.dynamicSliders;
      if (sliders.isEmpty) {
        setState(() {
          _bannerItems = [];
          _programItems = [];
        });
        return;
      }

      final kidsSlider = sliders.firstWhere(
        (s) => s.title.contains('أطفال') || s.title.contains('Kids'),
        orElse: () => sliders.first,
      );

      final banner = state.bannerItems
              .take(3)
              .map((b) => ProgramItem(
                    id: b.id,
                    title: b.title,
                    image: b.image,
                    postType: b.postType,
                  ))
              .toList();

      setState(() {
        _bannerItems = banner;
        _programItems = kidsSlider.programs
            .map((p) => ProgramItem(
                  id: p.id,
                  title: p.title,
                  image: p.image,
                  postType: p.postType,
                ))
            .toList();
      });
    }
  }

  void _openDetails(ProgramItem item) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => TvDetailsScreen(item: item)),
    );
  }

  void _onItemFocus(ProgramItem item) {
    if (item.image != _focusedImageUrl) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _focusedImageUrl = item.image);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return TvAmbientBackground(
      imageUrl: _focusedImageUrl,
      child: CustomScrollView(
        slivers: [
          // ─ عنوان القسم
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                TvTheme.paddingM,
                TvTheme.paddingL,
                TvTheme.paddingM,
                TvTheme.paddingM,
              ),
              child: Text(
                'قسم الأطفال 🌙',
                style: TextStyle(
                  color: TvTheme.onBackground,
                  fontSize: TvTheme.fontSizeTitle,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
  
          // ─ البانر
          if (_bannerItems.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: TvTheme.paddingM,
                ),
                child: TvBannerSlider(
                  items: _bannerItems,
                  onItemTap: _openDetails,
                  onItemFocus: _onItemFocus,
                ),
              ),
            ),
  
          const SliverToBoxAdapter(child: SizedBox(height: TvTheme.paddingL)),
  
          // ─ شبكة البرامج
          SliverPadding(
            padding: const EdgeInsets.symmetric(
              horizontal: TvTheme.paddingM,
            ),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                mainAxisSpacing: TvTheme.paddingS,
                crossAxisSpacing: TvTheme.paddingS,
                childAspectRatio: TvTheme.cardWidth / TvTheme.cardHeight,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final item = _programItems[index];
                  return TvCard(
                    item: item,
                    autofocus: index == 0,
                    onTap: () => _openDetails(item),
                    onFocus: () => _onItemFocus(item),
                  );
                },
                childCount: _programItems.length,
              ),
            ),
          ),
  
          const SliverToBoxAdapter(child: SizedBox(height: TvTheme.paddingXL)),
        ],
      ),
    );
  }
}
