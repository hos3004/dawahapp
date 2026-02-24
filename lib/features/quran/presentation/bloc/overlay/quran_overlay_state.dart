import 'package:equatable/equatable.dart';
import '../../../domain/entities/ayah_coordinates.dart';

class QuranOverlayState extends Equatable {
  final List<AyahCoordinates> highlights; // الإحداثيات التي سيتم رسمها

  const QuranOverlayState({this.highlights = const []});

  @override
  List<Object> get props => [highlights];
}