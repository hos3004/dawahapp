import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/models/genre_data.dart';
import '../../../data/repositories/program_repository.dart';
import '../../widgets/genre_card.dart';
import 'category_browse_screen.dart';

// --- Bloc Events ---
abstract class CategoriesEvent {}

class FetchCategories extends CategoriesEvent {}

// --- Bloc States ---
abstract class CategoriesState {}

class CategoriesInitial extends CategoriesState {}

class CategoriesLoading extends CategoriesState {}

class CategoriesLoadSuccess extends CategoriesState {
  final List<GenreData> genres;
  CategoriesLoadSuccess(this.genres);
}

class CategoriesLoadFailure extends CategoriesState {
  final String error;
  CategoriesLoadFailure(this.error);
}

// --- Bloc Logic ---
class CategoriesBloc extends Bloc<CategoriesEvent, CategoriesState> {
  final ProgramRepository _repository;
  CategoriesBloc(this._repository) : super(CategoriesInitial()) {
    on<FetchCategories>(_onFetchCategories);
  }

  Future<void> _onFetchCategories(
      FetchCategories event, Emitter<CategoriesState> emit) async {
    if (state is! CategoriesLoadSuccess) {
      emit(CategoriesLoading());
    }
    try {
      // تم تحديث getGenreList في الريبو لدعم الكاش
      final genres = await _repository.getGenreList(page: 1, perPage: 50);
      emit(CategoriesLoadSuccess(genres));
    } catch (e) {
      emit(CategoriesLoadFailure(e.toString()));
    }
  }
}

// --- الشاشة (Widget) ---
class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // ❌ تم حذف BlocProvider من هنا لأنه موجود الآن في main.dart

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: BlocBuilder<CategoriesBloc, CategoriesState>(
        builder: (context, state) {
          if (state is CategoriesLoading || state is CategoriesInitial) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is CategoriesLoadFailure) {
            return Center(
                child: Text('خطأ: ${state.error}',
                    style: const TextStyle(color: Colors.white70)));
          }
          if (state is CategoriesLoadSuccess) {
            if (state.genres.isEmpty) {
              return const Center(
                  child: Text('لا توجد تصنيفات متاحة.',
                      style: TextStyle(color: Colors.white70)));
            }

            return GridView.builder(
              padding: EdgeInsets.only(
                left: 16.0,
                right: 16.0,
                top: kToolbarHeight + MediaQuery.of(context).padding.top + 16.0,
                bottom: 16.0,
              ),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1.1,
                crossAxisSpacing: 12.0,
                mainAxisSpacing: 12.0,
              ),
              itemCount: state.genres.length,
              itemBuilder: (context, index) {
                final genre = state.genres[index];
                return GenreCard(
                  genre: genre,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CategoryBrowseScreen(
                          genreSlug: genre.slug,
                          genreName: genre.name,
                        ),
                      ),
                    );
                  },
                );
              },
            );
          }
          return const Center(
              child: Text('حالة غير معروفة',
                  style: TextStyle(color: Colors.black)));
        },
      ),
    );
  }
}
