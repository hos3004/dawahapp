import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/repositories/program_repository.dart';
import '../../bloc/tiktok_feed/tiktok_feed_bloc.dart';
import '../../bloc/tiktok_feed/tiktok_feed_event.dart';
import '../../bloc/tiktok_feed/tiktok_feed_state.dart';
import 'tiktok_video_page.dart';

/// الشاشة الرئيسية التي تحتوي على PageView لصفحات التيك توك
class DaawahTikTokScreen extends StatelessWidget {
  final bool isScreenActive;

  const DaawahTikTokScreen({
    super.key,
    required this.isScreenActive
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => TikTokFeedBloc(
        RepositoryProvider.of<ProgramRepository>(context),
      )..add(FetchTikTokFeed()),
      child: TikTokFeedView(isScreenActive: isScreenActive),
    );
  }
}

/// الويدجت الفعلي الذي يعرض الواجهة بناءً على الحالات
class TikTokFeedView extends StatefulWidget {
  final bool isScreenActive;

  const TikTokFeedView({
    super.key,
    required this.isScreenActive
  });

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
      if (_currentPageIndex < (context.read<TikTokFeedBloc>().state.videos.length - 1)) {
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


  /// ويدجت لبناء أزرار التنقل (أعلى/أسفل)
  Widget _buildNavigationButtons(TikTokFeedState state) {
    return Positioned(
      bottom: 30,
      left: 16,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // --- زر السهم العلوي ---
          if (_currentPageIndex > 0)
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: CircleAvatar(
                backgroundColor: Colors.black.withOpacity(0.4),
                child: IconButton(
                  icon: const Icon(Icons.keyboard_arrow_up, color: Colors.white),
                  onPressed: () {
                    _pageController.previousPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  },
                ),
              ),
            ),

          // --- زر السهم السفلي ---
          if (_currentPageIndex < state.videos.length - 1)
            CircleAvatar(
              backgroundColor: Colors.black.withOpacity(0.4),
              child: IconButton(
                icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white),
                onPressed: () {
                  _pageController.nextPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: BlocBuilder<TikTokFeedBloc, TikTokFeedState>(
        builder: (context, state) {

          if (state is TikTokFeedInitial || (state is TikTokFeedLoading && state.videos.isEmpty)) {
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
                // 1. عارض الصفحات
                RefreshIndicator(
                  onRefresh: () async {
                    context.read<TikTokFeedBloc>().add(RefreshTikTokFeed());
                  },
                  child: PageView.builder(
                    physics: const PageScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                    controller: _pageController,
                    scrollDirection: Axis.vertical,
                    itemCount: state.hasReachedMax
                        ? state.videos.length
                        : state.videos.length + 1,

                    onPageChanged: (index) {
                      setState(() {
                        _currentPageIndex = index;
                      });
                      if (index >= state.videos.length - 2 && !state.hasReachedMax) {
                        context.read<TikTokFeedBloc>().add(LoadMoreTikTokFeed());
                      }
                    },
                    itemBuilder: (context, index) {
                      if (index >= state.videos.length) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final videoItem = state.videos[index];
                      final bool isActiveInPageView = (index == _currentPageIndex);

                      // --- ⚠️ [إضافة جديدة 3/4] ---
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
                      // --- ⚠️ [إضافة جديدة 4/4] ---
                      // (سيظهر خطأ هنا مؤقتاً حتى نعدل الملف التالي)
                    },
                  ),
                ),

                // 2. الأزرار (التي أضفناها)
                _buildNavigationButtons(state),
              ],
            );
          }

          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }
}