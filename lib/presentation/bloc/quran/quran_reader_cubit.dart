// [ ملف معدل وكامل: lib/presentation/bloc/quran/quran_reader_cubit.dart ]

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:just_audio/just_audio.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../../../data/models/quran_models.dart';
import '../../../../data/repositories/quran_repo.dart';
import '../../../../services/download_manager.dart';
import '../../../../utils/constants.dart';
import 'dart:async';

// 🟢 المصحف الافتراضي (Final بدلاً من Const لحل مشكلة السطر 15)
final Mushaf defaultMushaf = Mushaf(
  id: 1,
  name: 'مصحف حفص',
  pagesCount: 604,
  slug: 'hafs_default',
  description: 'المصحف الافتراضي برواية حفص عن عاصم',
  image: 'assets/images/placeholder_cover.png',
);

// الرابط الأساسي لملفات صوت الصفحة في Everyayah
String _buildPageAudioUrl(int pageNumber, Reciter reciter) {
  final pageStr = pageNumber.toString().padLeft(3, '0');
  final base = reciter.sourceUrl.endsWith('/')
      ? reciter.sourceUrl
      : '${reciter.sourceUrl}/';
  final prefix = reciter.fileStructure;
  return '$base$prefix$pageStr.mp3';
}

/// حالة قارئ القرآن
class QuranReaderState {
  final Mushaf? selectedMushaf;
  final int currentPage;
  final bool isDownloaded;
  final int downloadProgress;
  final bool isDownloading;
  final bool showDownloadPrompt;

  final List<SurahIndex> surahIndex;
  final List<JuzIndex> juzIndex;

  // الصوت / القرّاء
  final List<Reciter> recitersList;
  final Reciter? selectedReciter;
  final bool isPlaying;
  final Duration position;
  final Duration duration;
  final ProcessingState processingState;

  // حالة التكرار
  final int repeatStartPage;
  final int repeatEndPage;
  final int repeatCount;
  final int currentRepeat;

  QuranReaderState({
    this.selectedMushaf,
    this.currentPage = 0,
    this.isDownloaded = false,
    this.downloadProgress = 0,
    this.isDownloading = false,
    this.showDownloadPrompt = false,
    this.surahIndex = const [],
    this.juzIndex = const [],
    this.recitersList = const [],
    this.selectedReciter,
    this.isPlaying = false,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.processingState = ProcessingState.idle,
    // القيم الافتراضية للتكرار
    this.repeatStartPage = 0,
    this.repeatEndPage = 0,
    this.repeatCount = 0,
    this.currentRepeat = 0,
  });

  QuranReaderState copyWith({
    Mushaf? selectedMushaf,
    int? currentPage,
    bool? isDownloaded,
    int? downloadProgress,
    bool? isDownloading,
    bool? showDownloadPrompt,
    List<SurahIndex>? surahIndex,
    List<JuzIndex>? juzIndex,
    List<Reciter>? recitersList,
    Reciter? selectedReciter,
    bool? isPlaying,
    Duration? position,
    Duration? duration,
    ProcessingState? processingState,
    // تحديث حالة التكرار
    int? repeatStartPage,
    int? repeatEndPage,
    int? repeatCount,
    int? currentRepeat,
  }) {
    return QuranReaderState(
      selectedMushaf: selectedMushaf ?? this.selectedMushaf,
      currentPage: currentPage ?? this.currentPage,
      isDownloaded: isDownloaded ?? this.isDownloaded,
      downloadProgress: downloadProgress ?? this.downloadProgress,
      isDownloading: isDownloading ?? this.isDownloading,
      showDownloadPrompt: showDownloadPrompt ?? this.showDownloadPrompt,
      surahIndex: surahIndex ?? this.surahIndex,
      juzIndex: juzIndex ?? this.juzIndex,
      recitersList: recitersList ?? this.recitersList,
      selectedReciter: selectedReciter ?? this.selectedReciter,
      isPlaying: isPlaying ?? this.isPlaying,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      processingState: processingState ?? this.processingState,
      // تحديث حالة التكرار
      repeatStartPage: repeatStartPage ?? this.repeatStartPage,
      repeatEndPage: repeatEndPage ?? this.repeatEndPage,
      repeatCount: repeatCount ?? this.repeatCount,
      currentRepeat: currentRepeat ?? this.currentRepeat,
    );
  }
}

// --- Cubit ---
class QuranReaderCubit extends Cubit<QuranReaderState> {
  final DownloadManager _downloadManager = DownloadManager();
  final QuranRepository _quranRepository = QuranRepository();
  final AudioPlayer _audioPlayer = AudioPlayer();

  StreamSubscription? _audioPositionSubscription;
  StreamSubscription? _audioDurationSubscription;

  QuranReaderCubit() : super(QuranReaderState()) {
    _loadLastReadPage();
    _monitorAudioCompletion();
    _monitorAudioState();
  }

  // ---------------------- [ تخزين واسترجاع آخر صفحة ] ----------------------

  Future<void> _loadLastReadPage() async {
    final lastPage = getIntAsync(LAST_READ_PAGE_KEY, defaultValue: 0);

    // 🟢 تعيين المصحف الافتراضي إذا لم يتم تعيينه بعد
    if (state.selectedMushaf == null) {
      await initializeMushaf(defaultMushaf, skipPageLoad: true);
    }

    emit(state.copyWith(currentPage: lastPage));
  }

  Future<void> _saveCurrentPage(int pageNumber) async {
    if (pageNumber > 0) {
      await setValue(LAST_READ_PAGE_KEY, pageNumber);
      log('int - LAST_READ_PAGE_KEY - $pageNumber');
    }
  }

  // ---------------------- [ تهيئة المصحف والتحميل الأولي ] ----------------------

  Future<void> initializeMushaf(Mushaf mushaf, {bool skipPageLoad = false}) async {
    await stopAudio();

    try {
      final surahs = await _quranRepository.getSurahIndex();
      final juzs = await _quranRepository.getJuzIndex();
      final reciters = await _quranRepository.getRecitersList();

      emit(
        state.copyWith(
          selectedMushaf: mushaf,
          surahIndex: surahs,
          juzIndex: juzs,
          recitersList: reciters,
          selectedReciter: state.selectedReciter ?? reciters.firstOrNull,
          // إعادة تعيين حدود التكرار عند تغيير المصحف
          repeatStartPage: 0,
          repeatEndPage: 0,
          repeatCount: 0,
          currentRepeat: 0,
        ),
      );
    } catch (e) {
      log('Failed to load indices or reciters: $e');
      emit(state.copyWith(selectedMushaf: mushaf));
    }

    final initialProgress = await _downloadManager.getDownloadProgress(mushaf);
    final isFullyDownloaded = initialProgress >= 1.0;

    emit(
      state.copyWith(
        isDownloaded: isFullyDownloaded,
        downloadProgress: (initialProgress * 100).toInt(),
      ),
    );

    if (!isFullyDownloaded) {
      final isInitialDownloaded =
      await _downloadManager.isRangeDownloaded(mushaf, 1, 10);

      if (!isInitialDownloaded) {
        await _downloadManager.downloadPagesRange(
          mushaf,
          1,
          10,
              (p) {},
        );
        log('Initial 10 pages downloaded.');
      }
    }

    final finalProgress = await _downloadManager.getDownloadProgress(mushaf);
    emit(
      state.copyWith(
        downloadProgress: (finalProgress * 100).toInt(),
        isDownloaded: finalProgress >= 1.0,
      ),
    );
  }

  // ---------------------- [ منطق تغيير الصفحة + Preloading ] ----------------------

  Future<void> changePage(int newPage) async {
    if (state.selectedMushaf == null) return;
    final mushaf = state.selectedMushaf!;
    final int oldPage = state.currentPage;

    if (newPage == oldPage) return;

    if (state.isPlaying) {
      await stopAudio();
      // ❌ تم حذف Future.delayed(Duration.zero) والاعتماد على حالة ProcessingState
    }

    if (newPage < 0 || newPage > mushaf.pagesCount) return;

    if (newPage == 0) {
      emit(state.copyWith(currentPage: 0, showDownloadPrompt: false));
      return;
    }

    await _saveCurrentPage(newPage);

    // إعادة تعيين التكرار إذا تجاوزنا النطاق المحدد يدوياً
    if (state.repeatCount > 0 && newPage > state.repeatEndPage) {
      _resetRepeat();
    }


    if (newPage > 10 && !state.isDownloaded) {
      emit(
        state.copyWith(
          currentPage: newPage,
          showDownloadPrompt: true,
        ),
      );
    } else {
      emit(
        state.copyWith(
          currentPage: newPage,
          showDownloadPrompt: false,
        ),
      );

      if (newPage > oldPage &&
          newPage % 5 == 0 &&
          newPage < mushaf.pagesCount) {
        int startPreload = newPage + 1;
        int endPreload = newPage + 5;

        if (startPreload > mushaf.pagesCount) startPreload = mushaf.pagesCount;
        if (endPreload > mushaf.pagesCount) endPreload = mushaf.pagesCount;

        if (startPreload <= endPreload) {
          _preloadNextPages(startPreload, endPreload);
        }
      }
    }
  }

  Future<void> _preloadNextPages(int startPage, int endPage) async {
    final mushaf = state.selectedMushaf;
    if (mushaf == null) return;

    try {
      await _downloadManager.downloadPagesRange(
        mushaf,
        startPage,
        endPage,
            (p) {},
      );
    } catch (e) {
      log('Preload error ($startPage-$endPage): $e');
    }
  }


  Future<void> startFullDownload(Mushaf mushaf) async {
    emit(
      state.copyWith(
        isDownloading: true,
        showDownloadPrompt: false,
      ),
    );

    await _downloadManager.downloadPagesRange(
      mushaf,
      1,
      mushaf.pagesCount,
          (progress) {
        emit(state.copyWith(downloadProgress: progress));
      },
    );

    emit(
      state.copyWith(
        isDownloading: false,
        isDownloaded: true,
        downloadProgress: 100,
      ),
    );
  }

  // ---------------------- [ منطق الصوت + شريط التقدم ] ----------------------

  void _monitorAudioState() {
    _audioDurationSubscription = _audioPlayer.durationStream.listen((duration) {
      emit(state.copyWith(duration: duration ?? Duration.zero));
    });

    _audioPositionSubscription = _audioPlayer.positionStream.listen((position) {
      emit(state.copyWith(position: position));
    });

    _audioPlayer.playerStateStream.listen((playerState) {
      final isPlaying = playerState.playing;
      final processingState = playerState.processingState;

      emit(state.copyWith(
        isPlaying: isPlaying,
        processingState: processingState,
      ));
    });
  }


  void _monitorAudioCompletion() {
    _audioPlayer.playerStateStream.listen((playerState) async {
      if (playerState.processingState == ProcessingState.completed) {
        log('Page audio finished, checking repeat/next page logic.');

        // 🟢 نوقف الصوت وننتظر حتى يعود المشغل لحالة الخمول (idle) قبل البدء بصفحة جديدة
        await stopAudio();

        final mushaf = state.selectedMushaf;
        final current = state.currentPage;

        if (mushaf == null || current <= 0 || current > mushaf.pagesCount) return;


        // 1. منطق التكرار: هل نحن في صفحة النهاية؟
        if (state.repeatCount > 0 && current >= state.repeatEndPage) {

          if (state.currentRepeat < state.repeatCount || state.repeatCount == -1) {
            // التكرار مستمر: زيادة العداد والقفز لصفحة البداية
            final nextRepeat = state.repeatCount == -1 ? -1 : state.currentRepeat + 1;

            emit(state.copyWith(currentRepeat: nextRepeat));

            await changePage(state.repeatStartPage);
            await startAudio();
            return;
          } else {
            // انتهى التكرار
            _resetRepeat();
            return;
          }
        }

        // 2. منطق الانتقال للصفحة التالية (إذا لم يكن هناك تكرار أو تجاوزنا نطاق التكرار)
        if (current < mushaf.pagesCount) {
          await changePage(current + 1);
          await startAudio();
        }
      }
    });
  }

  Future<void> startAudio() async {
    final mushaf = state.selectedMushaf;
    final reciter = state.selectedReciter;

    if (mushaf == null || reciter == null) return;
    if (state.currentPage <= 0) return;

    final pageNumber = state.currentPage;
    final audioUrl = _buildPageAudioUrl(pageNumber, reciter);

    try {
      if (state.processingState == ProcessingState.ready && !state.isPlaying) {
        // إذا كان الصوت جاهزاً ومتوقفاً مؤقتاً، استأنف التشغيل
        await _audioPlayer.play();
        return;
      }

      // 🟢 ننتظر حتى يصبح المشغل خاملاً (idle) قبل محاولة التحميل الجديد
      // (هذا يضمن أن المشغل القديم قد توقف بالكامل)
      if (state.processingState != ProcessingState.idle) {
        await _audioPlayer.stop();
      }

      await _audioPlayer.setUrl(audioUrl);
      await _audioPlayer.play();
      WakelockPlus.enable();
      log('Playing: $audioUrl');
    } catch (e) {
      log('Audio Playback Error: $e');
    }
  }

  Future<void> pauseAudio() async {
    await _audioPlayer.pause();
  }

  Future<void> stopAudio() async {
    await _audioPlayer.stop();
    WakelockPlus.disable();
    // 🟢 تحديث الحالة إلى idle هنا هو المفتاح
    emit(state.copyWith(
      position: Duration.zero,
      processingState: ProcessingState.idle,
    ));
    _resetRepeat();
  }

  Future<void> seekAudio(Duration position) async {
    await _audioPlayer.seek(position);
  }


  void selectReciter(Reciter reciter) {
    stopAudio();
    emit(state.copyWith(selectedReciter: reciter));
  }

  // ---------------------- [ وظائف التكرار ] ----------------------

  void setRepeatRange({required int startPage, required int endPage, required int count}) {
    if (state.selectedMushaf == null || startPage <= 0 || endPage <= 0 || startPage > endPage || startPage > state.selectedMushaf!.pagesCount || endPage > state.selectedMushaf!.pagesCount) {
      _resetRepeat();
      return;
    }

    stopAudio();

    emit(state.copyWith(
      repeatStartPage: startPage,
      repeatEndPage: endPage,
      repeatCount: count,
      currentRepeat: 0,
    ));

    changePage(startPage);
  }

  void _resetRepeat() {
    emit(state.copyWith(
      repeatCount: 0,
      repeatStartPage: 0,
      repeatEndPage: 0,
      currentRepeat: 0,
    ));
  }


  // ... (باقي الدوال: getPageTitle, getJuzName) ...
  String getPageTitle(int pageNumber) {
    String surahName = 'سورة (غير معروفة)';

    try {
      final currentSurah = state.surahIndex
          .where((s) => s.pageNumber <= pageNumber)
          .lastWhere((_) => true, orElse: () => state.surahIndex.first);

      surahName = "سورة ${currentSurah.nameArabic}";
    } catch (e) {
      // تجاهل الخطأ والإبقاء على النص الافتراضي
    }

    return surahName;
  }

  String getJuzName(int pageNumber) {
    try {
      final currentJuz = state.juzIndex
          .where((j) => j.pageNumber <= pageNumber)
          .lastWhere((_) => true, orElse: () => state.juzIndex.first);
      return "الجزء ${currentJuz.id}";
    } catch (e) {
      return 'الجزء (غير معروف)';
    }
  }

  @override
  Future<void> close() {
    _audioPositionSubscription?.cancel();
    _audioDurationSubscription?.cancel();
    _audioPlayer.dispose();
    return super.close();
  }
}