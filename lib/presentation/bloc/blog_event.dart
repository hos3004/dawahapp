// [ ملف جديد: lib/presentation/bloc/blog/blog_event.dart ]

import 'package:equatable/equatable.dart';

abstract class BlogEvent extends Equatable {
  const BlogEvent();

  @override
  List<Object> get props => [];
}

// Event لبدء جلب المقالات (الصفحة الأولى)
class FetchBlogs extends BlogEvent {}

// Event لجلب المزيد من المقالات (للتمرير)
class LoadMoreBlogs extends BlogEvent {}