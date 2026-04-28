import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/repositories/program_repository.dart';
import '../../bloc/tiktok_feed/tiktok_feed_bloc.dart';
import '../../bloc/tiktok_feed/tiktok_feed_event.dart';
import '../../bloc/tiktok_feed/tiktok_feed_state.dart';
import 'tiktok_video_page.dart';

/// الشاشة الرئيسية التي تحتوي على PageView لصفحات التيك توك
class DaawahTikTokScreen extends StatelessWidget {
  final ValueNotifier<int> tabNotifier;

  const DaawahTikTokScreen({
    super.key,
    required this.tabNotifier,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => TikTokFeedBloc(
        RepositoryProvider.of<ProgramRepository>(context),
      )..add(FetchTikTokFeed()),
      child: ValueListenableBuilder<int>(
        valueListenable: tabNotifier,
        builder: (context, tabIndex, child) {
          // TikTok is active if tabIndex is 2
          return TikTokFeedView(isScreenActive: tabIndex == 2);
        },
      ),
    );
  }
}

/// الويدجت الفعلي الذي يعرض الواجهة بناءً على الحالات
class TikTokFeedView extends StatefulWidget {
  final bool isScreenActive;

  const TikTokFeedView({super.key, required this.isScreenActive});

  @override
  State<TikTokFeedView> createState() => _TikTokFeedViewState();
}

class _TikTokFeedViewState extends State<TikTokFeedView> {
  final PageController _pageController = PageController();
  int _currentPageIndex = 0; // لتتبع الصفحة النشطة

  // --- ⚠️ [إضافة جديدة 1/4] ---
  // متغير الحالة لزر التمرير التلقائي
  bool _isAutoScrollEnabled = false;
  // -------------------------

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // --- ⚠️ [إضافة جديدة 2/4] ---
  /// دالة يتم استدعاؤها عند انتهاء الفيديو (من الابن)
  void _handleVideoEnd() {
    // إذا كان التمرير التلقائي مُفعّل، انتقل للتالي
    if (_isAutoScrollEnabled && widget.isScreenActive) {
      // التأكد أننا لسنا في الصفحة الأخيرة قبل الانتقال
      if (_currentPageIndex <
          (context.read<TikTokFeedBloc>().state.videos.length - 1)) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    }
  }

  /// دالة لتبديل حالة التمرير التلقائي (من الابن)
  void _handleToggleAutoScroll() {
    setState(() {
      _isAutoScrollEnabled = !_isAutoScrollEnabled;
    });
  }
  // -------------------------

  // --- ملاحظة: تمت إزالة أزرار التنقل اليدوية (الأسهم) للاعتماد الكلي على السحب (Swiping) ---

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: BlocBuilder<TikTokFeedBloc, TikTokFeedState>(
        builder: (context, state) {
          if (state is TikTokFeedInitial ||
              (state is TikTokFeedLoading && state.videos.isEmpty)) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is TikTokFeedFailure && state.videos.isEmpty) {
            return Center(/* ... كود الخطأ ... */);
          }

          if (state is TikTokFeedSuccess && state.videos.isEmpty) {
            return const Center(/* ... كود القائمة الفارغة ... */);
          }

          if (state.videos.isNotEmpty) {
            return Stack(
              children: [
                // 1. عارض الصفحات المستمر (بدون RefreshIndicator لتجنب تضارب السحب)
                PageView.builder(
                  physics: const PageScrollPhysics(
                      parent: AlwaysScrollableScrollPhysics()),
                  controller: _pageController,
                  scrollDirection: Axis.vertical,
                  itemCount: state.hasReachedMax
                      ? state.videos.length
                      : state.videos.length + 1,
                  onPageChanged: (index) {
                    setState(() {
                      _currentPageIndex = index;
                    });
                    if (index >= state.videos.length - 2 &&
                        !state.hasReachedMax) {
                      context.read<TikTokFeedBloc>().add(LoadMoreTikTokFeed());
                    }
                  },
                  itemBuilder: (context, index) {
                    if (index >= state.videos.length) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final videoItem = state.videos[index];
                    final bool isActiveInPageView =
                        (index == _currentPageIndex);

                    // تمرير المتغيرات والدوال الجديدة إلى الابن
                    return TikTokVideoPage(
                      key: PageStorageKey<int>(videoItem.id),
                      videoItem: videoItem,
                      isActive: isActiveInPageView,
                      isScreenActive: widget.isScreenActive,

                      // --- المتغيرات الجديدة ---
                      onVideoEnded: _handleVideoEnd,
                      onToggleAutoScroll: _handleToggleAutoScroll,
                      isAutoScrollEnabled: _isAutoScrollEnabled,
                      // -------------------------
                    );
                  },
                ),
              ],
            );
          }

          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }
}
