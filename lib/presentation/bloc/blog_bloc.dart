// [ ملف جديد: lib/presentation/bloc/blog/blog_bloc.dart ]

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:stream_transform/stream_transform.dart'; //
import 'blog_event.dart';
import 'blog_state.dart';
import '../../../data/repositories/program_repository.dart';

// تحديد عدد المقالات لكل صفحة
const _perPage = 15;

// لتجنب طلبات التحميل المتكررة
EventTransformer<Event> throttleDroppable<Event>() {
  return (events, mapper) {
    return events.throttle(const Duration(milliseconds: 300), trailing: false).switchMap(mapper);
  };
}

class BlogBloc extends Bloc<BlogEvent, BlogState> {
  final ProgramRepository _repository;
  int _currentPage = 1;

  BlogBloc(this._repository) : super(BlogInitial()) {
    on<FetchBlogs>(_onFetchBlogs);
    on<LoadMoreBlogs>(
      _onLoadMoreBlogs,
      transformer: throttleDroppable(), // منع التحميل المتكرر
    );
  }

  Future<void> _onFetchBlogs(FetchBlogs event, Emitter<BlogState> emit) async {
    emit(BlogLoading());
    try {
      _currentPage = 1; // إعادة تعيين الصفحة
      final posts = await _repository.getBlogList(page: _currentPage, perPage: _perPage);
      emit(BlogLoadSuccess(
        posts: posts,
        hasReachedMax: posts.length < _perPage,
      ));
    } catch (e) {
      emit(BlogLoadFailure(error: e.toString()));
    }
  }

  Future<void> _onLoadMoreBlogs(LoadMoreBlogs event, Emitter<BlogState> emit) async {
    if (state is BlogLoadSuccess && !(state as BlogLoadSuccess).hasReachedMax) {
      final currentState = state as BlogLoadSuccess;
      
      try {
        _currentPage++; // زيادة رقم الصفحة
        final posts = await _repository.getBlogList(page: _currentPage, perPage: _perPage);

        emit(posts.isEmpty
            ? currentState.copyWith(hasReachedMax: true)
            : BlogLoadSuccess(
                posts: List.of(currentState.posts)..addAll(posts),
                hasReachedMax: posts.length < _perPage,
              ));
      } catch (e) {
        // في حال حدوث خطأ، أعد الحالة كما كانت
        emit(currentState.copyWith(hasReachedMax: false));
        _currentPage--; // إرجاع رقم الصفحة
      }
    }
  }
}