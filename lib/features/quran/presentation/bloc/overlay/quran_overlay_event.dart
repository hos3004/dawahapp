import 'package:equatable/equatable.dart';

abstract class QuranOverlayEvent extends Equatable {
  @override
  List<Object> get props => [];
}

class HighlightAyahEvent extends QuranOverlayEvent {
  final int ayahNumber;
  final int pageNumber;
  final String mushafType;

  HighlightAyahEvent({
    required this.ayahNumber,
    required this.pageNumber,
    required this.mushafType,
  });
  
  @override
  List<Object> get props => [ayahNumber, pageNumber, mushafType];
}

class ClearHighlightEvent extends QuranOverlayEvent {}