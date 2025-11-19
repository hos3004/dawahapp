// [ ملف معدل وكامل: lib/presentation/screens/quran/quran_reader_screen.dart ]

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:just_audio/just_audio.dart';

import '../../bloc/quran/quran_reader_cubit.dart';
import '../../../data/models/quran_models.dart';
import '../../../services/download_manager.dart';
import '../../screens/quran/surah_index_modal.dart';
import '../../screens/quran/juz_index_modal.dart';
import '../../screens/quran/reciter_selection_modal.dart';
import '../../screens/quran/mushaf_selection_screen.dart';

class QuranReaderScreen extends StatefulWidget {
  const QuranReaderScreen({super.key});

  @override
  State<QuranReaderScreen> createState() => _QuranReaderScreenState();
}

class _QuranReaderScreenState extends State<QuranReaderScreen> {
  late PageController _pageController;
  final DownloadManager _downloadManager = DownloadManager();

  @override
  void initState() {
    super.initState();
    final cubit = context.read<QuranReaderCubit>();

    final totalPagesWithCover = cubit.state.selectedMushaf!.pagesCount + 1;
    final initialIndex = (totalPagesWithCover - 1 - cubit.state.currentPage).clamp(0, totalPagesWithCover - 1).toInt();

    _pageController = PageController(initialPage: initialIndex);
  }

  @override
  void dispose() {
    context.read<QuranReaderCubit>().stopAudio();
    _pageController.dispose();
    super.dispose();
  }

  // ويدجت لعرض الصورة من المسار المحلي أو الغلاف (WebP/PNG)
  Widget _buildPageImage(String mushafSlug, int pageNumber) {
    if (pageNumber == 0) {
      return Image.asset(
        'assets/images/cover_frame.png',
        fit: BoxFit.fill,
        errorBuilder: (c, o, s) => const Center(child: Text("❌ غلاف المصحف مفقود.")),
      );
    }

    // 🟢 عزل FutureBuilder هنا جيد ولا يسبب وميض الصورة
    return FutureBuilder<String>(
      // **ملاحظة:** بما أن الـ Future يعتمد على pageNumber و mushafSlug،
      // فإن المشكلة هي في إعادة إنشاء هذا الويدجت بالكامل
      future: _downloadManager.getLocalFilePath(mushafSlug, pageNumber),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done && snapshot.hasData) {
          final filePath = snapshot.data!;
          if (File(filePath).existsSync()) {
            return Image.file(
              File(filePath),
              fit: BoxFit.fill,
            );
          }
        }
        return const Center(child: CircularProgressIndicator());
      },
    );
  }

  // ويدجت لتغليف الصفحة بالبرواز
  Widget _buildFramedPage(String mushafSlug, int pageNumber) {
    if (pageNumber == 0) {
      return _buildPageImage(mushafSlug, pageNumber);
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          'assets/images/frame.png',
          fit: BoxFit.fill,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 25),
          child: _buildPageImage(mushafSlug, pageNumber),
        ),
      ],
    );
  }


  @override
  Widget build(BuildContext context) {
    final cubit = context.read<QuranReaderCubit>();

    return BlocConsumer<QuranReaderCubit, QuranReaderState>(
      listener: (context, state) {
        final totalPagesWithCover = state.selectedMushaf?.pagesCount != null ? state.selectedMushaf!.pagesCount + 1 : 1;
        final targetIndex = (totalPagesWithCover - 1 - state.currentPage).clamp(0, totalPagesWithCover - 1).toInt();

        if (targetIndex >= 0 && targetIndex < totalPagesWithCover && targetIndex != _pageController.page?.toInt()) {
          _pageController.jumpToPage(targetIndex);
        }
      },
      builder: (context, state) {
        final mushaf = state.selectedMushaf;

        if (mushaf == null) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("جاري تحميل بيانات المصحف أو المصحف الافتراضي مفقود.", style: TextStyle(fontSize: 16)),
                  const SizedBox(height: 16),
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => _showMushafSelection(context),
                    icon: const Icon(Icons.book),
                    label: const Text("اختيار مصحف"),
                  ),
                ],
              ),
            ),
          );
        }

        final int totalPagesWithCover = mushaf.pagesCount + 1;

        return Scaffold(
          appBar: state.currentPage > 0 ? _buildCustomAppBar(context, cubit, state) : _buildSimpleAppBar(context),

          bottomNavigationBar: _buildAudioControlsBar(context, cubit, state),


          body: Stack(
            children: [
              // 🔴 الحل الجذري: عزل الـ PageView في BlocSelector
              BlocSelector<QuranReaderCubit, QuranReaderState, int>(
                selector: (s) => s.currentPage,
                builder: (context, currentPage) {
                  // يتم إعادة بناء هذا الويدجت فقط عندما يتغير رقم الصفحة (currentPage)
                  return PageView.builder(
                    controller: _pageController,
                    reverse: true,
                    itemCount: totalPagesWithCover,
                    onPageChanged: (index) {
                      final newPage = totalPagesWithCover - 1 - index;

                      cubit.pauseAudio();
                      cubit.changePage(newPage);
                    },
                    itemBuilder: (context, index) {
                      final pageNumber = totalPagesWithCover - 1 - index;
                      // يجب أن يكون mushaf غير null في هذه النقطة
                      final currentMushafSlug = cubit.state.selectedMushaf!.slug;
                      return _buildFramedPage(currentMushafSlug, pageNumber);
                    },
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // 🆕 شريط علوي بسيط لصفحة الغلاف
  PreferredSizeWidget _buildSimpleAppBar(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: false,
      title: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          // 🟢 زر العودة للرئيسية (استخدام pushAndRemoveUntil للعودة لـ Home Screen)
          IconButton(
              icon: const Icon(Icons.home, color: Colors.white),
              onPressed: () {
                // يفترض أن الشاشة الرئيسية هي '/' أو أول شاشة في التطبيق
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const MushafSelectionScreen()), // يمكن استبدالها بشاشتك الرئيسية الفعلية
                      (Route<dynamic> route) => false,
                );
              }
          ),
        ],
      ),
      backgroundColor: Theme.of(context).primaryColor,
    );
  }

  // بناء شريط علوي مخصص (AppBar) للصفحات
  PreferredSizeWidget _buildCustomAppBar(BuildContext context, QuranReaderCubit cubit, QuranReaderState state) {
    final String surahName = cubit.getPageTitle(state.currentPage);
    final String juzName = cubit.getJuzName(state.currentPage);

    return AppBar(
      automaticallyImplyLeading: false,
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 🟢 زر العودة للرئيسية (استخدام pushAndRemoveUntil للعودة لـ Home Screen)
          IconButton(
              icon: const Icon(Icons.home, color: Colors.white),
              onPressed: () {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const MushafSelectionScreen()), // يمكن استبدالها بشاشتك الرئيسية الفعلية
                      (Route<dynamic> route) => false,
                );
              }
          ),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildDropdownButton(
                    context,
                    surahName.split('سورة ').last,
                        () => _showSurahIndex(context),
                    Icons.list_alt,
                    prefix: 'سورة'
                ),
                const SizedBox(width: 8),
                _buildDropdownButton(
                    context,
                    juzName.split(' ').last,
                        () => _showJuzIndex(context),
                    Icons.layers,
                    prefix: 'الجزء'
                ),
              ],
            ),
          ),
          _buildDropdownButton(
            context,
            state.selectedMushaf!.name,
                () => _showMushafSelection(context),
            Icons.book,
          ),
        ],
      ),
      titleSpacing: 0,
      backgroundColor: Theme.of(context).primaryColor,
    );
  }


  // شريط التحكم بالصوت في الأسفل
  Widget _buildAudioControlsBar(BuildContext context, QuranReaderCubit cubit, QuranReaderState state) {
    final bool isReciterAvailable = state.selectedReciter != null;
    final bool isRepeating = state.repeatCount != 0;

    // 🟢 عرض شريط التحكم فقط إذا لم نكن في صفحة الغلاف
    if (state.currentPage == 0) {
      return const SizedBox.shrink();
    }

    // 🟢 عزل شريط التحكم في BlocSelector لتقليل إعادة البناء
    return BlocSelector<QuranReaderCubit, QuranReaderState, Map<String, dynamic>>(
      selector: (s) => {
        'isPlaying': s.isPlaying,
        'repeatCount': s.repeatCount,
        'currentRepeat': s.currentRepeat,
        'repeatStartPage': s.repeatStartPage,
        'repeatEndPage': s.repeatEndPage,
        'selectedReciter': s.selectedReciter,
        'currentPage': s.currentPage,
      },
      builder: (context, selectedState) {
        final currentIsPlaying = selectedState['isPlaying'] as bool;
        final currentRepeatCount = selectedState['repeatCount'] as int;
        final currentCurrentRepeat = selectedState['currentRepeat'] as int;
        final currentRepeatStartPage = selectedState['repeatStartPage'] as int;
        final currentRepeatEndPage = selectedState['repeatEndPage'] as int;
        final currentIsRepeating = currentRepeatCount != 0;

        return Container(
          color: Theme.of(context).primaryColor,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 2. مؤشر التكرار
                if (currentIsRepeating)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      currentRepeatCount == -1
                          ? "تكرار لا نهائي: $currentRepeatStartPage - $currentRepeatEndPage"
                          : "تكرار $currentCurrentRepeat من $currentRepeatCount: $currentRepeatStartPage - $currentRepeatEndPage",
                      style: const TextStyle(color: Colors.yellow, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),

                // 3. صف التحكم بالأزرار
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // رقم الصفحة + زر التكرار
                    Row(
                      children: [
                        Text(
                          "الصفحة: ${selectedState['currentPage']}",
                          style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 8),
                        // زر التكرار
                        IconButton(
                          icon: Icon(
                            currentIsRepeating ? Icons.repeat_on : Icons.repeat,
                            color: currentIsRepeating ? Colors.yellow : Colors.white,
                            size: 24,
                          ),
                          onPressed: () => _showRepeatSettingsModal(context, cubit.state),
                        ),
                      ],
                    ),

                    // أزرار التحكم الصوتي
                    if (isReciterAvailable)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // زر التوقف التام (Stop)
                          IconButton(
                            icon: const Icon(Icons.stop, color: Colors.redAccent, size: 30),
                            onPressed: () => cubit.stopAudio(),
                          ),

                          // زر التشغيل/الإيقاف المؤقت
                          IconButton(
                            icon: Icon(
                              currentIsPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                              color: Colors.white,
                              size: 30,
                            ),
                            onPressed: () {
                              if (currentIsPlaying) {
                                cubit.pauseAudio();
                              } else {
                                cubit.startAudio();
                              }
                            },
                          ),
                        ],
                      )
                    else
                      const SizedBox(width: 48),

                    // اختيار القارئ
                    _buildDropdownButton(
                      context,
                      state.selectedReciter?.nameArabic ?? "اختر قارئ",
                          () => _showReciterSelection(context),
                      Icons.person_pin,
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // 🟢 إعادة تعريف دالة _buildDropdownButton المفقودة
  Widget _buildDropdownButton(
      BuildContext context,
      String text,
      VoidCallback onTap,
      IconData icon,
      {String? prefix}
      ) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        child: Row(
          children: [
            if (prefix != null)
              Text(
                '$prefix ',
                style: const TextStyle(fontSize: 14, color: Colors.white70),
                maxLines: 1,
              ),
            Icon(icon, size: 18, color: Colors.white),
            const SizedBox(width: 4),
            Text(
              text,
              style: const TextStyle(fontSize: 14, color: Colors.white),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // فتح قائمة القراء كـ Modal
  void _showReciterSelection(BuildContext context) {
    final cubit = context.read<QuranReaderCubit>();
    showModalBottomSheet<Reciter>(
      context: context,
      isScrollControlled: true,
      builder: (modalContext) => ReciterSelectionModal(
        reciters: cubit.state.recitersList,
        onReciterSelected: (reciter) {
          cubit.selectReciter(reciter);
          Navigator.pop(modalContext);
        },
        selectedReciterId: cubit.state.selectedReciter?.id,
      ),
    );
  }

  // 🆕 فتح نافذة إعدادات التكرار
  void _showRepeatSettingsModal(BuildContext context, QuranReaderState state) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (modalContext) => RepeatSettingsModal(
        currentPage: state.currentPage,
        mushafPagesCount: state.selectedMushaf!.pagesCount,
        initialStartPage: state.repeatStartPage > 0 ? state.repeatStartPage : state.currentPage,
        initialEndPage: state.repeatEndPage > 0 ? state.repeatEndPage : state.currentPage,
        initialRepeatCount: state.repeatCount,
        onRepeatSet: (start, end, count) {
          context.read<QuranReaderCubit>().setRepeatRange(
            startPage: start,
            endPage: end,
            count: count,
          );
          Navigator.pop(modalContext);
        },
        onRepeatReset: () {
          context.read<QuranReaderCubit>().setRepeatRange(startPage: 0, endPage: 0, count: 0);
          Navigator.pop(modalContext);
        },
      ),
    );
  }

  // إصلاح مشكلة ProviderNotFoundException في _showSurahIndex
  void _showSurahIndex(BuildContext context) {
    final cubit = context.read<QuranReaderCubit>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (modalContext) => SurahIndexModal(
        onSurahSelected: (pageNumber) {
          cubit.changePage(pageNumber);
          Navigator.pop(modalContext);
        },
      ),
    );
  }

  // إصلاح مشكلة ProviderNotFoundException في _showJuzIndex
  void _showJuzIndex(BuildContext context) {
    final cubit = context.read<QuranReaderCubit>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (modalContext) => JuzIndexModal(
        onJuzSelected: (pageNumber) {
          cubit.changePage(pageNumber);
          Navigator.pop(modalContext);
        },
      ),
    );
  }


  void _showMushafSelection(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const MushafSelectionScreen()),
    );
  }
}

// ❌ تم حذف ويدجت _AudioSeekBar بالكامل


// ويدجت إعدادات التكرار (RepeatSettingsModal)
class RepeatSettingsModal extends StatefulWidget {
  final int currentPage;
  final int mushafPagesCount;
  final int initialStartPage;
  final int initialEndPage;
  final int initialRepeatCount;
  final Function(int start, int end, int count) onRepeatSet;
  final VoidCallback onRepeatReset;

  const RepeatSettingsModal({
    super.key,
    required this.currentPage,
    required this.mushafPagesCount,
    required this.initialStartPage,
    required this.initialEndPage,
    required this.initialRepeatCount,
    required this.onRepeatSet,
    required this.onRepeatReset,
  });

  @override
  State<RepeatSettingsModal> createState() => _RepeatSettingsModalState();
}

class _RepeatSettingsModalState extends State<RepeatSettingsModal> {
  late int _startPage;
  late int _endPage;
  late int _repeatCount;

  final List<int> repeatOptions = [1, 2, 3, 5, 10, -1]; // -1 للانهائي

  @override
  void initState() {
    super.initState();
    _startPage = widget.initialStartPage;
    _endPage = widget.initialEndPage;
    _repeatCount = widget.initialRepeatCount == 0 ? 1 : widget.initialRepeatCount;
  }

  @override
  Widget build(BuildContext context) {
    final maxPage = widget.mushafPagesCount;
    _startPage = _startPage.clamp(1, maxPage);
    _endPage = _endPage.clamp(_startPage, maxPage);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Center(
            child: Text(
              'تحديد نطاق التكرار',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
            ),
          ),
          const Divider(color: Colors.grey),

          // 1. تحديد صفحة البداية
          _buildPageSelector(
            title: 'صفحة البداية (من)',
            currentValue: _startPage,
            onChanged: (value) {
              setState(() {
                _startPage = value;
                if (_endPage < _startPage) {
                  _endPage = _startPage;
                }
              });
            },
            max: maxPage,
          ),

          // 2. تحديد صفحة النهاية
          _buildPageSelector(
            title: 'صفحة النهاية (إلى)',
            currentValue: _endPage,
            onChanged: (value) {
              setState(() {
                _endPage = value;
                if (_startPage > _endPage) {
                  _startPage = _endPage;
                }
              });
            },
            min: _startPage,
            max: maxPage,
          ),

          const SizedBox(height: 16),

          // 3. تحديد عدد مرات التكرار
          Text('عدد مرات التكرار:', style: TextStyle(fontSize: 16, color: Colors.grey[700])),
          Wrap(
            spacing: 8.0,
            children: repeatOptions.map((count) {
              final isSelected = _repeatCount == count;
              return ChoiceChip(
                label: Text(count == -1 ? 'لا نهائي' : count.toString()),
                selected: isSelected,
                selectedColor: Theme.of(context).primaryColor,
                onSelected: (selected) {
                  if (selected) {
                    setState(() {
                      _repeatCount = count;
                    });
                  }
                },
              );
            }).toList(),
          ),

          const SizedBox(height: 24),

          // 4. أزرار التحكم
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: widget.onRepeatReset,
                child: const Text('إلغاء التكرار', style: TextStyle(color: Colors.red)),
              ),
              const SizedBox(width: 16),
              ElevatedButton(
                onPressed: () {
                  widget.onRepeatSet(_startPage, _endPage, _repeatCount);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                ),
                child: const Text('تطبيق التكرار'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ويدجت مساعد لاختيار الصفحات باستخدام Dropdown
  Widget _buildPageSelector({
    required String title,
    required int currentValue,
    required Function(int) onChanged,
    int min = 1,
    required int max,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: TextStyle(fontSize: 16, color: Colors.grey[700])),
          DropdownButton<int>(
            value: currentValue,
            items: List.generate(max - min + 1, (index) => min + index)
                .map((page) => DropdownMenuItem(
              value: page,
              child: Text('صفحة $page'),
            ))
                .toList(),
            onChanged: (value) {
              if (value != null) {
                onChanged(value);
              }
            },
          ),
        ],
      ),
    );
  }
}