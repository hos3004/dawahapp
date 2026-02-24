import 'package:equatable/equatable.dart';

abstract class QuranNavigationEvent extends Equatable {
  const QuranNavigationEvent();
  @override
  List<Object> get props => [];
}

class ChangePageEvent extends QuranNavigationEvent {
  final int pageNumber;
  const ChangePageEvent(this.pageNumber);
  @override
  List<Object> get props => [pageNumber];
}

class ChangeMushafTypeEvent extends QuranNavigationEvent {
  final String mushafType; // 'hafs', 'warsh', etc.
  const ChangeMushafTypeEvent(this.mushafType);
  @override
  List<Object> get props => [mushafType];
}