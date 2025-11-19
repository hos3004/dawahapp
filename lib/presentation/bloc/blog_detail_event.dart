import 'package:equatable/equatable.dart';

abstract class BlogDetailEvent extends Equatable {
  const BlogDetailEvent();

  @override
  List<Object> get props => [];
}

// Event لجلب تفاصيل مقال معين
class FetchBlogDetail extends BlogDetailEvent {
  final int postId;
  const FetchBlogDetail(this.postId);

  @override
  List<Object> get props => [postId];
}