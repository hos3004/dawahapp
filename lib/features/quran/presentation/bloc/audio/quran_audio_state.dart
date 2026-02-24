import 'package:equatable/equatable.dart';
import '../../../data/models/reciter_model.dart';

enum AudioStatus { initial, loading, playing, paused, stopped, error }

class QuranAudioState extends Equatable {
  final AudioStatus status;
  final String? errorMessage;
  final int? playingAyahNumber;
  final int? playingPageNumber;
  final int currentAyahPlaying;
  
  // ✅ إضافة القراء
  final List<ReciterModel> reciters;
  final ReciterModel? selectedReciter;

  const QuranAudioState({
    this.status = AudioStatus.initial,
    this.errorMessage,
    this.playingPageNumber, // ✅
    this.playingAyahNumber, // ✅
    this.currentAyahPlaying = 0,
    this.reciters = const [],
    this.selectedReciter,
  });

  QuranAudioState copyWith({
    AudioStatus? status,
    String? errorMessage,
    int? playingPageNumber, // ✅
    int? playingAyahNumber, // ✅
    int? currentAyahPlaying,
    List<ReciterModel>? reciters,
    ReciterModel? selectedReciter,
  }) {
    return QuranAudioState(
      status: status ?? this.status,
      errorMessage: errorMessage,
      playingAyahNumber: playingAyahNumber ?? this.playingAyahNumber, // ✅
      playingPageNumber: playingPageNumber ?? this.playingPageNumber, // ✅
      currentAyahPlaying: currentAyahPlaying ?? this.currentAyahPlaying,
      reciters: reciters ?? this.reciters,
      selectedReciter: selectedReciter ?? this.selectedReciter,
    );
  }

  @override
  List<Object?> get props => [
        status,
        errorMessage,
        playingPageNumber,
        playingAyahNumber,
        currentAyahPlaying,
        reciters,
        selectedReciter
      ];
}
