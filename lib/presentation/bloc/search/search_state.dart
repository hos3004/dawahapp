import 'package:equatable/equatable.dart';
import '../../../data/models/program_item.dart'; // Use ProgramItem for results

abstract class SearchState extends Equatable {
  const SearchState();

  @override
  List<Object> get props => [];
}

// Initial state before any search
class SearchInitial extends SearchState {}

// State while loading results
class SearchLoading extends SearchState {}

// State when results are loaded successfully
class SearchSuccess extends SearchState {
  final List<ProgramItem> programs;
  final bool hasReachedMax; // Flag for pagination

  const SearchSuccess({required this.programs, required this.hasReachedMax});

  SearchSuccess copyWith({
    List<ProgramItem>? programs,
    bool? hasReachedMax,
  }) {
    return SearchSuccess(
      programs: programs ?? this.programs,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
    );
  }

  @override
  List<Object> get props => [programs, hasReachedMax];
}

// State when an error occurs
class SearchFailure extends SearchState {
  final String error;
  const SearchFailure(this.error);

  @override
  List<Object> get props => [error];
}