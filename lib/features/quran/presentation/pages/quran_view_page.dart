import 'dart:async'; // ✅ 1. استيراد للتايمر
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/services/service_locator.dart';
import '../../../../../features/quran/domain/repositories/quran_repository.dart';
import '../../../../data/models/quran_models.dart'; // ✅ لاستيراد مودل SurahIndex
import '../bloc/navigation/quran_navigation_bloc.dart';
import '../bloc/navigation/quran_navigation_event.dart';
import '../bloc/navigation/quran_navigation_state.dart';
import '../bloc/audio/quran_audio_bloc.dart';
import '../bloc/audio/quran_audio_event.dart';
import '../bloc/audio/quran_audio_state.dart';
import '../widgets/quran_page_image.dart';
import '../widgets/memorization_sheet.dart';
import '../widgets/surah_index_sheet.dart';
import '../widgets/juz_index_sheet.dart';
import '../widgets/pages_index_sheet.dart';

class QuranViewPage extends StatelessWidget {
  const QuranViewPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => getIt<QuranNavigationBloc>()),
        BlocProvider(
            create: (context) =>
            getIt<QuranAudioBloc>()..add(LoadRecitersEvent())),
      ],
      child: const _QuranViewBody(),
    );
  }
}

class _QuranViewBody extends StatefulWidget {
  const _QuranViewBody();

  @override
  State<_QuranViewBody> createState() => _QuranViewBodyState();
}

class _QuranViewBodyState extends State<_QuranViewBody> {
  late PageController _pageController;

  // ✅ 1. المتغيرات (تم دمجها هنا)
  // يبدأ ظاهراً (true)
  bool _isControlsVisible = true;
  Timer? _hideTimer;
  List<SurahIndex> _surahList = [];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);

    // تحميل البيانات
    _loadSurahData();

    // ✅ 2. بدء المؤقت فوراً عند الفتح ليختفي الشريط تلقائياً
    _startHideTimer();
  }

  // تحميل قائمة السور
  Future<void> _loadSurahData() async {
    try {
      final repo = getIt<QuranRepository>();
      final surahs = await repo.getSurahIndex();
      setState(() {
        _surahList = surahs;
      });
    } catch (e) {
      debugPrint("Error loading surah index: $e");
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _hideTimer?.cancel();
    super.dispose();
  }

  // دالة التبديل (Toggle)
  void _toggleControls() {
    setState(() {
      _isControlsVisible = !_isControlsVisible;
    });

    if (_isControlsVisible) {
      _startHideTimer();
    } else {
      _hideTimer?.cancel();
    }
  }

  // بدء عداد 5 ثواني للإخفاء
  void _startHideTimer() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 30), () {
      if (mounted) {
        setState(() {
          _isControlsVisible = true;
        });
      }
    });
  }

  // دالة لمعرفة اسم السورة
  String _getSurahNameByPage(int page) {
    if (_surahList.isEmpty) return "المصحف الشريف";
    try {
      final surah = _surahList.lastWhere((s) => s.pageNumber <= page);
      return "سورة ${surah.nameArabic}";
    } catch (e) {
      return "المصحف الشريف";
    }
  }

  @override
  Widget build(BuildContext context) {
    final navBloc = context.read<QuranNavigationBloc>();

    return BlocListener<QuranAudioBloc, QuranAudioState>(
      listenWhen: (prev, curr) =>
      curr.playingPageNumber != null &&
          curr.playingPageNumber != prev.playingPageNumber,
      listener: (context, audioState) {
        final currentNavPage = navBloc.state.currentPage;
        final audioPage = audioState.playingPageNumber!;

        if (audioPage != currentNavPage) {
          navBloc.add(ChangePageEvent(audioPage));
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFFFF8E1),
        body: SafeArea(
          child: Stack(
            children: [
              // 1. طبقة المصحف
              Positioned.fill(
                child: BlocListener<QuranNavigationBloc, QuranNavigationState>(
                  listener: (context, state) {
                    if (_pageController.hasClients &&
                        _pageController.page?.round() !=
                            state.currentPage - 1) {
                      _pageController.jumpToPage(state.currentPage - 1);
                    }
                  },
                  child: BlocBuilder<QuranNavigationBloc, QuranNavigationState>(
                    builder: (context, navState) {
                      return PageView.builder(
                        itemCount: 604,
                        reverse: false,
                        controller: _pageController,
                        onPageChanged: (index) {
                          final newPage = index + 1;
                          navBloc.add(ChangePageEvent(newPage));

                          final audioBloc = context.read<QuranAudioBloc>();
                          final isPlaying =
                              audioBloc.state.status == AudioStatus.playing;

                          if (isPlaying) {
                            audioBloc.add(PlayCurrentPageEvent(
                              pageNumber: newPage,
                              mushafType: navState.mushafType,
                            ));
                          }
                        },
                        itemBuilder: (context, index) {
                          final pageNum = index + 1;
                          return GestureDetector(
                            onTap: _toggleControls,
                            onDoubleTapDown: (details) {
                              _handleDoubleTap(
                                context,
                                details.localPosition,
                                (context.findRenderObject() as RenderBox).size,
                                pageNum,
                                navState.mushafType,
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16.0,
                                vertical: 8.0,
                              ),
                              child: QuranPageImage(
                                pageNumber: pageNum,
                                mushafType: navState.mushafType,
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ),

              // 2. الشريط العلوي
              AnimatedPositioned(
                duration: const Duration(milliseconds: 300),
                top: _isControlsVisible ? 0 : -50,
                left: 0,
                right: 0,
                child: BlocBuilder<QuranNavigationBloc, QuranNavigationState>(
                  builder: (context, state) {
                    return _buildTopInfoBar(state.currentPage);
                  },
                ),
              ),

              // 3. الشريط السفلي (المشغل)
              AnimatedPositioned(
                duration: const Duration(milliseconds: 300),
                bottom: _isControlsVisible ? 0 : -100,
                left: 0,
                right: 0,
                child: _buildUnifiedPlayerBar(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // دالة الشريط العلوي
  Widget _buildTopInfoBar(int pageNumber) {
    final int juz = ((pageNumber - 2) / 20).floor() + 1;
    final String surahName = _getSurahNameByPage(pageNumber);

    return Container(
      height: 30,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xff0B4DA1).withOpacity(0.7),
        border: const Border(
          bottom: BorderSide(color: Colors.white10, width: 0.5),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            "الجزء $juz",
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          Text(
            surahName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            "ص $pageNumber",
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  // دالة الشريط السفلي (المشغل)
  Widget _buildUnifiedPlayerBar(BuildContext context) {
    return BlocBuilder<QuranAudioBloc, QuranAudioState>(
      builder: (context, state) {
        final bool hasReciter = state.selectedReciter != null;
        final bool isPlaying = state.status == AudioStatus.playing;
        final bool isLoading = state.status == AudioStatus.loading;
        final bool showStopButton = state.status != AudioStatus.stopped &&
            state.status != AudioStatus.initial;

        return Container(
          height: 65,
          width: double.infinity,
          margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: const Color(0xff0B4DA1),
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 5,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            textDirection: TextDirection.rtl,
            children: [
              // زر التشغيل
              InkWell(
                onTap: hasReciter
                    ? () => _handlePlayPause(context, state)
                    : () => _openRecitersSheet(context, state),
                child: Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: isLoading
                      ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                      : Icon(
                    hasReciter
                        ? (isPlaying
                        ? Icons.pause_rounded
                        : Icons.play_arrow_rounded)
                        : Icons.person_search_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ),

              if (showStopButton) ...[
                const SizedBox(width: 4),
                InkWell(
                  onTap: () =>
                      context.read<QuranAudioBloc>().add(StopAudioEvent()),
                  child: const Icon(Icons.stop_rounded,
                      color: Colors.redAccent, size: 24),
                ),
              ],

              const SizedBox(width: 8),

              Expanded(
                child: InkWell(
                  onTap: () => _openRecitersSheet(context, state),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        hasReciter ? state.selectedReciter!.nameArabic : "قارئ",
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),

              Container(
                width: 1,
                height: 24,
                color: Colors.white30,
                margin: const EdgeInsets.symmetric(horizontal: 4),
              ),

              _buildCompactIconButton(
                icon: Icons.format_list_bulleted,
                label: "السور",
                onTap: () => _openSurahIndexSheet(context),
              ),
              _buildCompactIconButton(
                icon: Icons.pie_chart_outline,
                label: "الأجزاء",
                onTap: () => _openJuzIndexSheet(context),
              ),
              _buildCompactIconButton(
                icon: Icons.menu_book_rounded,
                label: "الصفحات",
                onTap: () => _openPagesIndexSheet(context),
              ),
              _buildCompactIconButton(
                icon: Icons.repeat_rounded,
                label: "الحفظ",
                onTap: () => _openMemorizationSheet(context),
              ),
            ],
          ),
        );
      },
    );
  }

  // --- باقي الدوال المساعدة ---
  Widget _buildCompactIconButton({
    required IconData icon,
    required VoidCallback onTap,
    required String label,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 9,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handlePlayPause(BuildContext context, QuranAudioState audioState) {
    final audioBloc = context.read<QuranAudioBloc>();
    final navBloc = context.read<QuranNavigationBloc>();

    if (audioState.status == AudioStatus.playing) {
      audioBloc.add(PauseAudioEvent());
    } else if (audioState.status == AudioStatus.paused) {
      audioBloc.add(ResumeAudioEvent());
    } else {
      audioBloc.add(PlayCurrentPageEvent(
        pageNumber: navBloc.state.currentPage,
        mushafType: navBloc.state.mushafType,
      ));
    }
  }

  Future<void> _handleDoubleTap(
      BuildContext context,
      Offset localPosition,
      Size widgetSize,
      int pageNumber,
      String mushafType,
      ) async {
    final audioBloc = context.read<QuranAudioBloc>();
    if (audioBloc.state.selectedReciter == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("يرجى اختيار قارئ أولاً للبدء")),
      );
      _openRecitersSheet(context, audioBloc.state);
      return;
    }

    const referenceSize = Size(230, 350);
    final scaleX = referenceSize.width / widgetSize.width;
    final scaleY = referenceSize.height / widgetSize.height;
    final targetPoint = Offset(localPosition.dx * scaleX, localPosition.dy * scaleY);

    try {
      final repo = getIt<QuranRepository>();
      final coordinates = await repo.getPageCoordinates(
        pageNumber: pageNumber,
        mushafType: mushafType,
      );
      for (var ayah in coordinates) {
        // دالة _isPointInsidePolygon يجب أن تكون موجودة في الكود (أو قمت بتعريفها سابقاً)
        if (_isPointInsidePolygon(targetPoint, ayah.polygonData)) {
          final lastAyahInPage = coordinates.last.ayahNumber;
          audioBloc.add(PlayAudioRangeEvent(
            surahNumber: ayah.surahNumber,
            startAyah: ayah.ayahNumber,
            endAyah: lastAyahInPage,
            rangeRepeat: 1,
            ayahRepeat: 1,
          ));
          return;
        }
      }
    } catch (e) {
      debugPrint("Error finding ayah on tap: $e");
    }
  }

  // دالة التحقق من الإحداثيات (ضرورية لعمل النقر المزدوج)
  bool _isPointInsidePolygon(Offset point, String polygonString) {
    final List<Offset> vertices = [];
    final points = polygonString.trim().split(' ');
    for (var p in points) {
      final xy = p.split(',');
      if (xy.length == 2) {
        try {
          vertices.add(Offset(double.parse(xy[0]), double.parse(xy[1])));
        } catch (e) {}
      }
    }
    int intersectCount = 0;
    for (int j = 0; j < vertices.length - 1; j++) {
      if (_rayCastIntersect(point, vertices[j], vertices[j + 1])) {
        intersectCount++;
      }
    }
    if (vertices.isNotEmpty &&
        _rayCastIntersect(point, vertices.last, vertices.first)) {
      intersectCount++;
    }
    return (intersectCount % 2) == 1;
  }

  bool _rayCastIntersect(Offset point, Offset vertA, Offset vertB) {
    final double aY = vertA.dy;
    final double bY = vertB.dy;
    final double aX = vertA.dx;
    final double bX = vertB.dx;
    final double pY = point.dy;
    final double pX = point.dx;
    if ((aY > pY && bY > pY) || (aY < pY && bY < pY) || (aX < pX && bX < pX)) {
      return false;
    }
    final double m = (aY - bY) / (aX - bX);
    final double bee = (-aX) * m + aY;
    final double x = (pY - bee) / m;
    return x > pX;
  }

  void _openRecitersSheet(BuildContext context, QuranAudioState state) {
    final audioBloc = context.read<QuranAudioBloc>();
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        if (state.reciters.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(20),
            child: Center(child: Text("لا يوجد قراء متاحين حالياً")),
          );
        }
        return BlocProvider.value(
          value: audioBloc,
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: SizedBox(
              height: 400,
              child: Column(
                children: [
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'اختر القارئ',
                      style:
                      TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  Expanded(
                    child: ListView.separated(
                      itemCount: state.reciters.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (ctx, index) {
                        final reciter = state.reciters[index];
                        final isSelected =
                            reciter.id == state.selectedReciter?.id;
                        return ListTile(
                          title: Text(reciter.nameArabic),
                          subtitle: Text(reciter.style,
                              style: const TextStyle(
                                  fontSize: 11, color: Colors.grey)),
                          trailing: isSelected
                              ? const Icon(Icons.check,
                              color: Color(0xff0B4DA1))
                              : null,
                          onTap: () {
                            audioBloc.add(ChangeReciterEvent(reciter));
                            Navigator.pop(ctx);
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _openMemorizationSheet(BuildContext context) {
    final audioBloc = context.read<QuranAudioBloc>();
    final navState = context.read<QuranNavigationBloc>().state;
    if (audioBloc.state.selectedReciter == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("يرجى اختيار قارئ أولاً")),
      );
      _openRecitersSheet(context, audioBloc.state);
      return;
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return BlocProvider.value(
          value: audioBloc,
          child: Padding(
            padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom),
            child: MemorizationSheet(
              currentSurah: 1,
              currentPage: navState.currentPage,
            ),
          ),
        );
      },
    );
  }

  void _openSurahIndexSheet(BuildContext context) {
    final navBloc = context.read<QuranNavigationBloc>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) =>
          BlocProvider.value(value: navBloc, child: const SurahIndexSheet()),
    );
  }

  void _openJuzIndexSheet(BuildContext context) {
    final navBloc = context.read<QuranNavigationBloc>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) =>
          BlocProvider.value(value: navBloc, child: const JuzIndexSheet()),
    );
  }

  void _openPagesIndexSheet(BuildContext context) {
    final navBloc = context.read<QuranNavigationBloc>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) =>
          BlocProvider.value(value: navBloc, child: const PagesIndexSheet()),
    );
  }
}