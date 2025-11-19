import 'package:equatable/equatable.dart';

abstract class SearchEvent extends Equatable {
  const SearchEvent();

  @override
  List<Object> get props => [];
}

// Event triggered when the search query changes
class SearchQueryChanged extends SearchEvent {
  final String query;
  const SearchQueryChanged(this.query);

  @override
  List<Object> get props => [query];
}

// Event to load the next page of results (for pagination)
class LoadMoreSearchResults extends SearchEvent {}

// Event to clear the search results
class ClearSearch extends SearchEvent {}