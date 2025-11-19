import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/models/genre_data.dart';
import '../../../data/repositories/program_repository.dart';
import '../../widgets/genre_card.dart'; // استيراد كارت التصنيف
import 'category_browse_screen.dart'; // استيراد شاشة تصفح التصنيف (سننشئها لاحقاً)

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

  Future<void> _onFetchCategories(FetchCategories event, Emitter<CategoriesState> emit) async {
    emit(CategoriesLoading());
    try {
      // جلب الصفحة الأولى فقط حالياً (يمكن إضافة pagination لاحقاً)
      final genres = await _repository.getGenreList(page: 1, perPage: 50); // جلب عدد كبير مبدئياً
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
    return BlocProvider(
      // استخدام RepositoryProvider للحصول على الريبو
      create: (context) => CategoriesBloc(RepositoryProvider.of<ProgramRepository>(context))
        ..add(FetchCategories()), // بدء جلب البيانات
      child: Scaffold(
        // لا نحتاج AppBar هنا لأنها ستكون جزءاً من HomeScreen
        backgroundColor: Colors.transparent, // لجعل خلفية HomeScreen تظهر
        body: BlocBuilder<CategoriesBloc, CategoriesState>(
          builder: (context, state) {
            if (state is CategoriesLoading || state is CategoriesInitial) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is CategoriesLoadFailure) {
              return Center(child: Text('خطأ: ${state.error}', style: const TextStyle(color: Colors.white70)));
            }
            if (state is CategoriesLoadSuccess) {
              if (state.genres.isEmpty) {
                return const Center(child: Text('لا توجد تصنيفات متاحة.', style: TextStyle(color: Colors.white70)));
              }

              // عرض التصنيفات في شبكة
              return GridView.builder(
                padding: EdgeInsets.only(
                  left: 16.0,
                  right: 16.0,
                  top: kToolbarHeight + MediaQuery.of(context).padding.top + 16.0, // لتجنب AppBar
                  bottom: 16.0,
                ),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2, // عدد الأعمدة
                  childAspectRatio: 1.1, // النسبة بين العرض والارتفاع
                  crossAxisSpacing: 12.0,
                  mainAxisSpacing: 12.0,
                ),
                itemCount: state.genres.length,
                itemBuilder: (context, index) {
                  final genre = state.genres[index];
                  return GenreCard(
                    genre: genre,
                    onTap: () {
                      // الانتقال لشاشة تصفح التصنيف
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
              return const Center(child: Text('حالة غير معروفة', style: TextStyle(color: Colors.black)));
          },
        ),
      ),
    );
  }
}