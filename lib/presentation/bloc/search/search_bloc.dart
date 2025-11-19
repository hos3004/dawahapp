import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:stream_transform/stream_transform.dart';
import '../../../data/models/program_item.dart';
import '../../../data/repositories/program_repository.dart';
import 'search_event.dart';
import 'search_state.dart';

// Debounce duration
const _duration = Duration(milliseconds: 500);

// Debounce transformer
EventTransformer<Event> debounce<Event>(Duration duration) {
  return (events, mapper) => events.debounce(duration).switchMap(mapper);
}


class SearchBloc extends Bloc<SearchEvent, SearchState> {
  final ProgramRepository _repository;
  String _currentQuery = '';
  int _currentPage = 1;
  final int _perPage = 15; // Number of items per page

  SearchBloc(this._repository) : super(SearchInitial()) {
    on<SearchQueryChanged>(_onSearchQueryChanged, transformer: debounce(_duration));
    on<LoadMoreSearchResults>(_onLoadMoreSearchResults);
    on<ClearSearch>(_onClearSearch);
  }

  // Handle new search query
  Future<void> _onSearchQueryChanged(SearchQueryChanged event, Emitter<SearchState> emit) async {
    final query = event.query.trim();
    // إذا لم يتغير النص (مثل المسافات الزائدة)، لا تقم بالبحث مرة أخرى
    if (query == _currentQuery && state is! SearchInitial) return;

    _currentQuery = query;
    _currentPage = 1; // Reset page number for new query

    if (query.isEmpty) {
      emit(SearchInitial()); // Show initial state if query is empty
      return;
    }

    emit(SearchLoading());
    try {
      // --- التصحيح هنا: استخدام دالة البحث الصحيحة ---
      final programs = await _repository.searchPrograms(
        query: query,
        page: _currentPage,
        perPage: _perPage,
      );
      // ---------------------------------------------

      emit(SearchSuccess(
        programs: programs,
        hasReachedMax: programs.length < _perPage,
      ));
    } catch (e) {
      emit(SearchFailure(e.toString()));
    }
  }

  // Handle loading more results
  Future<void> _onLoadMoreSearchResults(LoadMoreSearchResults event, Emitter<SearchState> emit) async {
    // Ensure we are in a success state and haven't reached the end
    if (state is SearchSuccess && !(state as SearchSuccess).hasReachedMax) {
      final currentState = state as SearchSuccess;
      _currentPage++; // Increment page number

      try {
        // --- التصحيح هنا: استخدام دالة البحث الصحيحة ---
        final newPrograms = await _repository.searchPrograms(
          query: _currentQuery,
          page: _currentPage,
          perPage: _perPage,
        );
        // ---------------------------------------------

        emit(currentState.copyWith(
          programs: List.of(currentState.programs)..addAll(newPrograms),
          hasReachedMax: newPrograms.length < _perPage,
        ));
      } catch (e) {
        print("Error loading more search results: $e");
        // يمكن إبقاء الحالة الحالية أو إرسال خطأ جزئي، مع وضع علامة hasReachedMax
        // لتجنب محاولة التحميل مرة أخرى عند حدوث خطأ
        emit(currentState.copyWith(hasReachedMax: true));
      }
    }
  }

  // Handle clearing the search
  void _onClearSearch(ClearSearch event, Emitter<SearchState> emit) {
    _currentQuery = '';
    _currentPage = 1;
    emit(SearchInitial());
  }
}