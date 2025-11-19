import 'package:equatable/equatable.dart';
import '../../../data/models/program_item.dart';
import '../../../data/models/program_slider.dart';

abstract class HomeState extends Equatable {
  const HomeState();

  @override
  List<Object> get props => [];
}

class HomeInitial extends HomeState {}

class HomeLoading extends HomeState {}

class HomeLoadSuccess extends HomeState {
  // final List<ProgramItem> staticItems; // <-- تغيير هذا
  final List<ProgramItem> bannerItems; // <-- إلى هذا
  final List<ProgramSlider> dynamicSliders;

  const HomeLoadSuccess({
    // required this.staticItems, // <-- تغيير هذا
    required this.bannerItems, // <-- إلى هذا
    required this.dynamicSliders,
  });

  @override
  List<Object> get props => [bannerItems, dynamicSliders]; // <-- تحديث هذا
}

class HomeLoadFailure extends HomeState {
  final String error;
  const HomeLoadFailure({required this.error});

  @override
  List<Object> get props => [error];
}