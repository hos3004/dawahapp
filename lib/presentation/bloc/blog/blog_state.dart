// [ ملف جديد: lib/presentation/bloc/blog/blog_state.dart ]

import 'package:equatable/equatable.dart';
import '../../../data/models/blog_post.dart';

abstract class BlogState extends Equatable {
  const BlogState();

  @override
  List<Object> get props => [];
}

class BlogInitial extends BlogState {}

class BlogLoading extends BlogState {}

class BlogLoadSuccess extends BlogState {
  final List<BlogPost> posts;
  final bool hasReachedMax;

  const BlogLoadSuccess({
    this.posts = const <BlogPost>[],
    this.hasReachedMax = false,
  });

  BlogLoadSuccess copyWith({
    List<BlogPost>? posts,
    bool? hasReachedMax,
  }) {
    return BlogLoadSuccess(
      posts: posts ?? this.posts,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
    );
  }

  @override
  List<Object> get props => [posts, hasReachedMax];
}

class BlogLoadFailure extends BlogState {
  final String error;

  const BlogLoadFailure({required this.error});

  @override
  List<Object> get props => [error];
}