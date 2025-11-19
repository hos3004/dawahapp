// [ ملف معدل: lib/presentation/bloc/quran/quran_bloc.dart ]

import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/datasources/api_service.dart'; // Correct import
import '../../../data/models/quran_models.dart';

// --- Events ---
abstract class QuranEvent {}
class FetchSurahs extends QuranEvent {}
class FetchSurahVerses extends QuranEvent {
  final int surahId;
  FetchSurahVerses(this.surahId);
}

// --- States ---
abstract class QuranState {}
class QuranInitial extends QuranState {}
class QuranLoading extends QuranState {}
class SurahsLoaded extends QuranState {
  final List<Surah> surahs;
  SurahsLoaded(this.surahs);
}
class VersesLoaded extends QuranState {
  final List<Ayah> verses;
  final int surahId;
  VersesLoaded(this.verses, this.surahId);
}
class QuranError extends QuranState {
  final String message;
  QuranError(this.message);
}

// --- Bloc ---
class QuranBloc extends Bloc<QuranEvent, QuranState> {
  // Create an instance of ApiService
  final ApiService _apiService = ApiService();

  QuranBloc() : super(QuranInitial()) {

    on<FetchSurahs>((event, emit) async {
      emit(QuranLoading());
      try {
        // Call the method on the instance
        final surahs = await _apiService.getQuranChapters();
        emit(SurahsLoaded(surahs));
      } catch (e) {
        emit(QuranError("فشل تحميل السور: $e"));
      }
    });

    on<FetchSurahVerses>((event, emit) async {
      emit(QuranLoading());
      try {
        // Call the method on the instance
        final verses = await _apiService.getSurahVerses(event.surahId);
        emit(VersesLoaded(verses, event.surahId));
      } catch (e) {
        emit(QuranError("فشل تحميل الآيات: $e"));
      }
    });
  }
}