import 'package:equatable/equatable.dart';

abstract class HomeEvent extends Equatable {
  const HomeEvent();

  @override
  List<Object> get props => [];
}

// Event لإخبار الـ BLoC أن يبدأ جلب البيانات
class FetchHomeContent extends HomeEvent {}