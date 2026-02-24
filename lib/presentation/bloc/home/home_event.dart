import 'package:equatable/equatable.dart';

abstract class HomeEvent extends Equatable {
  const HomeEvent();

  @override
  List<Object> get props => [];
}

// جلب البيانات (يستخدم الكاش إن وجد وصالح)
class FetchHomeContent extends HomeEvent {}

// تحديث البيانات إجبارياً (يتجاوز الكاش) - للسحب من أعلى
class RefreshHomeContent extends HomeEvent {}