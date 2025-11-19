import 'package:flutter_bloc/flutter_bloc.dart';
import 'blog_detail_event.dart';
import 'blog_detail_state.dart';
import '../../data/repositories/program_repository.dart';

class BlogDetailBloc extends Bloc<BlogDetailEvent, BlogDetailState> {
  final ProgramRepository _repository;

  BlogDetailBloc(this._repository) : super(BlogDetailInitial()) {
    on<FetchBlogDetail>(_onFetchBlogDetail);
  }

  Future<void> _onFetchBlogDetail(
    FetchBlogDetail event,
    Emitter<BlogDetailState> emit,
  ) async {
    emit(BlogDetailLoading());
    try {
      final post = await _repository.getBlogDetails(event.postId);
      emit(BlogDetailLoadSuccess(post));
    } catch (e) {
      emit(BlogDetailLoadFailure(error: e.toString()));
    }
  }
}