import 'package:equatable/equatable.dart';

class QuranNavigationState extends Equatable {
  final int currentPage;
  final String mushafType;

  const QuranNavigationState({
    this.currentPage = 1,
    this.mushafType = 'hafs', // القيمة الافتراضية
  });

  QuranNavigationState copyWith({
    int? currentPage,
    String? mushafType,
  }) {
    return QuranNavigationState(
      currentPage: currentPage ?? this.currentPage,
      mushafType: mushafType ?? this.mushafType,
    );
  }

  @override
  List<Object> get props => [currentPage, mushafType];
}