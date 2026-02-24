import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:just_audio/just_audio.dart';
import '../../../../../core/services/audio_service.dart';
import '../../../domain/repositories/quran_repository.dart';
import 'quran_audio_event.dart';
import 'quran_audio_state.dart';

class _UpdateCurrentAyahEvent extends QuranAudioEvent {
  final int ayahNumber;
  const _UpdateCurrentAyahEvent(this.ayahNumber);
  @override
  List<Object> get props => [ayahNumber];
}

class _UpdatePlayerStatusEvent extends QuranAudioEvent {
  final AudioStatus status;
  const _UpdatePlayerStatusEvent(this.status);
  @override
  List<Object> get props => [status];
}

class QuranAudioBloc extends Bloc<QuranAudioEvent, QuranAudioState> {
  final AudioService _audioService;
  final QuranRepository _quranRepository;

  StreamSubscription<PlayerState>? _playerStateSubscription;
  StreamSubscription<int?>? _currentIndexSubscription;

  int _startAyahOffset = 0;

  QuranAudioBloc(this._audioService, this._quranRepository)
      : super(const QuranAudioState()) {

    on<LoadRecitersEvent>(_onLoadReciters);
    on<ChangeReciterEvent>(_onChangeReciter);
    on<PlayAudioRangeEvent>(_onPlayAudioRange);
    on<PlayCurrentPageEvent>(_onPlayCurrentPage);

    on<PauseAudioEvent>((event, emit) async {
      await _audioService.pause();
    });
    on<ResumeAudioEvent>((event, emit) async {
      await _audioService.resume();
    });
    on<StopAudioEvent>((event, emit) async {
      await _audioService.stop();
      emit(state.copyWith(playingAyahNumber: null, status: AudioStatus.stopped));
    });

    on<_UpdateCurrentAyahEvent>((event, emit) {
      emit(state.copyWith(playingAyahNumber: event.ayahNumber));
    });
    on<_UpdatePlayerStatusEvent>((event, emit) {
      emit(state.copyWith(status: event.status));
    });

    _playerStateSubscription = _audioService.playerStateStream.listen((playerState) {
      final isPlaying = playerState.playing;
      final processingState = playerState.processingState;

      if (processingState == ProcessingState.loading ||
          processingState == ProcessingState.buffering) {
        add(const _UpdatePlayerStatusEvent(AudioStatus.loading));
      } else if (!isPlaying && processingState == ProcessingState.ready) {
        add(const _UpdatePlayerStatusEvent(AudioStatus.paused));
      } else if (isPlaying && processingState == ProcessingState.ready) {
        add(const _UpdatePlayerStatusEvent(AudioStatus.playing));
      } else if (processingState == ProcessingState.completed) {
        add(StopAudioEvent());
      }
    });

    _currentIndexSubscription = _audioService.currentIndexStream.listen((index) {
      if (index != null) {
        final currentAyah = _startAyahOffset + index;
        add(_UpdateCurrentAyahEvent(currentAyah));
      }
    });
  }

  Future<void> _onLoadReciters(
      LoadRecitersEvent event, Emitter<QuranAudioState> emit) async {
    try {
      final reciters = await _quranRepository.getReciters();
      emit(state.copyWith(reciters: reciters));
    } catch (e) {
      emit(state.copyWith(
          status: AudioStatus.error, errorMessage: "فشل تحميل قائمة القراء: $e"));
    }
  }

  Future<void> _onChangeReciter(
      ChangeReciterEvent event, Emitter<QuranAudioState> emit) async {
    emit(state.copyWith(selectedReciter: event.reciter));
  }

  Future<void> _onPlayAudioRange(
      PlayAudioRangeEvent event, Emitter<QuranAudioState> emit) async {
    if (state.selectedReciter == null) {
      emit(state.copyWith(errorMessage: "من فضلك اختر قارئًا أولاً."));
      return;
    }

    _startAyahOffset = event.startAyah;
    try {
      await _audioService.stop();
      await _audioService.playRange(
        surahNumber: event.surahNumber,
        startAyah: event.startAyah,
        endAyah: event.endAyah,
        baseUrl: state.selectedReciter!.sourceUrl,
        // ✅ هنا التصحيح: نمرر ayahRepeat و rangeRepeat بدلاً من المتغيرات القديمة
        ayahRepeat: event.ayahRepeat,
        rangeRepeat: event.rangeRepeat,
      );
    } catch (e) {
      emit(state.copyWith(status: AudioStatus.error, errorMessage: e.toString()));
    }
  }

  Future<void> _onPlayCurrentPage(
      PlayCurrentPageEvent event, Emitter<QuranAudioState> emit) async {
    if (state.selectedReciter == null) {
      emit(state.copyWith(errorMessage: "يرجى اختيار قارئ أولاً"));
      return;
    }

    try {
      final ayahCoordinates = await _quranRepository.getPageCoordinates(
        pageNumber: event.pageNumber,
        mushafType: event.mushafType,
      );
      if (ayahCoordinates.isEmpty) {
        emit(state.copyWith(errorMessage: "لا توجد بيانات لهذه الصفحة"));
        return;
      }

      final firstAyah = ayahCoordinates.first;
      final lastAyah = ayahCoordinates.last;
      _startAyahOffset = firstAyah.ayahNumber;

      await _audioService.stop();
      await _audioService.playRange(
        surahNumber: firstAyah.surahNumber,
        startAyah: firstAyah.ayahNumber,
        endAyah: lastAyah.ayahNumber,
        baseUrl: state.selectedReciter!.sourceUrl,
        // ✅ في التشغيل التلقائي للصفحة، التكرار يكون مرة واحدة
        ayahRepeat: 1,
        rangeRepeat: 1,
      );
    } catch (e) {
      emit(state.copyWith(status: AudioStatus.error, errorMessage: "خطأ: $e"));
    }
  }

  @override
  Future<void> close() {
    _playerStateSubscription?.cancel();
    _currentIndexSubscription?.cancel();
    return super.close();
  }
}