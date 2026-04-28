import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/program_item.dart';
import '../../presentation/bloc/home/home_bloc.dart';
import '../../presentation/bloc/home/home_state.dart';
import '../design/tv_theme.dart';
import '../focus/tv_focus_manager.dart';
import '../widgets/tv_horizontal_list.dart';
import '../widgets/tv_banner_slider.dart';
import '../widgets/tv_ambient_background.dart';
import 'tv_details_screen.dart';
import 'tv_live_screen.dart';


/// الشاشة الرئيسية للتلفزيون - صفوف برامج أسلوب Netflix
class TvHomeScreen extends StatefulWidget {
  final ValueChanged<ProgramItem>? onItemTap;

  const TvHomeScreen({super.key, this.onItemTap});

  @override
  State<TvHomeScreen> createState() => _TvHomeScreenState();
}

class _TvHomeScreenState extends State<TvHomeScreen> {
  String? _focusedImageUrl;
  late final FocusNode _liveCardFocusNode;

  @override
  void initState() {
    super.initState();
    _liveCardFocusNode = FocusNode(debugLabel: 'tv_home_live');
  }

  void _openDetails(BuildContext context, ProgramItem item) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TvDetailsScreen(item: item),
      ),
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
  void dispose() {
    _liveCardFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeBloc, HomeState>(
      builder: (context, state) {
        if (state is HomeLoading) {
          return const Center(
            child: CircularProgressIndicator(color: TvTheme.accent),
          );
        }

        if (state is HomeLoadFailure) {
          return Center(
            child: Column(
               mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.wifi_off, color: TvTheme.onSurfaceMuted, size: 64),
                const SizedBox(height: 16),
                Text(
                  'تعذّر تحميل المحتوى',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
          );
        }

        if (state is HomeLoadSuccess) {
           final sliders = state.dynamicSliders;
          final bannerItems = state.bannerItems
                  .take(5)
                  .map((b) => ProgramItem(
                        id: b.id,
                        title: b.title,
                        image: b.image,
                        postType: b.postType,
                      ))
                  .toList();

           return TvAmbientBackground(
            imageUrl: _focusedImageUrl,
             child: CustomScrollView(
              slivers: [
                // ─ البانر
                if (bannerItems.isNotEmpty)
                  SliverToBoxAdapter(
                     child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        TvTheme.paddingM,
                        TvTheme.paddingM,
                        TvTheme.paddingM,
                        TvTheme.paddingL,
                      ),
                       child: TvBannerSlider(
                        items: bannerItems,
                        onItemTap: (item) => _openDetails(context, item),
                        onItemFocus: _onItemFocus,
                      ),
                    ),
                  ),

                // ─ بطاقة البث المباشر (رابط البث كما في الكوتلن)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: TvTheme.paddingM, vertical: TvTheme.paddingS),
                    child: TvFocusable(
                      focusScale: 1.02,
                      focusNode: _liveCardFocusNode,
                      borderRadius: BorderRadius.circular(TvTheme.cardBorderRadius),
                      onSelect: () {
                        // الانتقال لشاشة البث المباشر الخاصة بالتلفزيون
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const TvLiveScreen()),
                        );
                      },
                      child: Container(
                        height: 80,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(TvTheme.cardBorderRadius),
                          gradient: const LinearGradient(
                            colors: [TvTheme.accent, Color(0xFF153B6E)],
                          ),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.live_tv, color: Colors.white, size: 36),
                            SizedBox(width: 16),
                            Text(
                              'البث المباشر لقناة دعوة',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // ─ الصفوف
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final slider = sliders[index];
                      return Padding(
                         padding: const EdgeInsets.only(
                            bottom: TvTheme.paddingL),
                        child: TvHorizontalList(
                           title: slider.title,
                          items: slider.programs
                               .map((p) => ProgramItem(
                                     id: p.id,
                                    title: p.title,
                                    image: p.image,
                                    postType: p.postType,
                                  ))
                               .toList(),
                           autofocusFirst: index == 0,
                          onItemTap: (item) => _openDetails(context, item),
                          onItemFocus: _onItemFocus,
                         ),
                      );
                    },
                    childCount: sliders.length,
                   ),
                ),

                const SliverToBoxAdapter(
                   child: SizedBox(height: TvTheme.paddingXL),
                ),
              ],
            ),
          );
        }

         return const SizedBox.shrink();
      },
    );
  }
}
