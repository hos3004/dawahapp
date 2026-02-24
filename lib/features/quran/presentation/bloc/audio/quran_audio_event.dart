import 'package:equatable/equatable.dart';
import '../../../data/models/reciter_model.dart';
import 'quran_audio_state.dart';

abstract class QuranAudioEvent extends Equatable {
  const QuranAudioEvent();
  @override
  List<Object> get props => [];
}

// ✅ الحدث المفقود: تحميل قائمة القراء
class LoadRecitersEvent extends QuranAudioEvent {}

// ✅ الحدث المفقود: تغيير القارئ
class ChangeReciterEvent extends QuranAudioEvent {
  final ReciterModel reciter;
  const ChangeReciterEvent(this.reciter);
  @override
  List<Object> get props => [reciter];
}

// حدث لتشغيل الصفحة الحالية تلقائياً
class PlayCurrentPageEvent extends QuranAudioEvent {
  final int pageNumber;
  final String mushafType;

  const PlayCurrentPageEvent({
    required this.pageNumber,
    this.mushafType = 'hafs', // القيمة الافتراضية
  });

  @override
  List<Object> get props => [pageNumber, mushafType];
}

// تعديل حدث التشغيل: حذفنا reciterBaseUrl لأنه سيأتي من الـ State
class PlayAudioRangeEvent extends QuranAudioEvent {
  final int surahNumber;
  final int startAyah;
  final int endAyah;
  final int ayahRepeat;  // ✅ تكرار الآية
  final int rangeRepeat; // ✅ تكرار الفقرة

  const PlayAudioRangeEvent({
    required this.surahNumber,
    required this.startAyah,
    required this.endAyah,
    this.ayahRepeat = 1,  // الافتراضي 1
    this.rangeRepeat = 1, // الافتراضي 1
  });

  @override
  List<Object> get props => [surahNumber, startAyah, endAyah, ayahRepeat, rangeRepeat];
}
class PauseAudioEvent extends QuranAudioEvent {}

class ResumeAudioEvent extends QuranAudioEvent {}

class StopAudioEvent extends QuranAudioEvent {}

// حدث داخلي لتحديث الآية التي يتم تشغيلها حالياً
class _UpdateCurrentAyahEvent extends QuranAudioEvent {
  final int ayahNumber;
  const _UpdateCurrentAyahEvent(this.ayahNumber);
  @override
  List<Object> get props => [ayahNumber];
}

// حدث داخلي لتحديث حالة المشغل العامة (يعالج الحالات الوسيطة)
class _UpdatePlayerStatusEvent extends QuranAudioEvent {
  final AudioStatus status;
  const _UpdatePlayerStatusEvent(this.status);
  @override
  List<Object> get props => [status];
}
