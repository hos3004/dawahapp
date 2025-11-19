import 'package:equatable/equatable.dart';
import '../../data/models/blog_post_detail.dart';

abstract class BlogDetailState extends Equatable {
  const BlogDetailState();

  @override
  List<Object> get props => [];
}

class BlogDetailInitial extends BlogDetailState {}

class BlogDetailLoading extends BlogDetailState {}

class BlogDetailLoadSuccess extends BlogDetailState {
  final BlogPostDetail post;
  const BlogDetailLoadSuccess(this.post);

  @override
  List<Object> get props => [post];
}

class BlogDetailLoadFailure extends BlogDetailState {
  final String error;

  // --- 🔥 هذا هو السطر الذي تم تصحيحه ---
  // لقد حولناه من (this.error) إلى ({required this.error})
  const BlogDetailLoadFailure({required this.error});
  // --- نهاية التصحيح ---

  @override
  List<Object> get props => [error];
}