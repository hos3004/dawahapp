// ... (imports و Bloc كما هو)
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
// ... (باقي imports)
import '../../../data/models/program_item.dart';
import '../../../data/repositories/program_repository.dart';
import '../../widgets/program_card.dart';
import '../program_detail/program_detail_screen.dart';
abstract class CategoryBrowseEvent {}
class FetchProgramsByGenre extends CategoryBrowseEvent { final String slug; FetchProgramsByGenre(this.slug); }
abstract class CategoryBrowseState {}
class CategoryBrowseInitial extends CategoryBrowseState {}
class CategoryBrowseLoading extends CategoryBrowseState {}
class CategoryBrowseLoadSuccess extends CategoryBrowseState { final List<ProgramItem> programs; CategoryBrowseLoadSuccess(this.programs); }
class CategoryBrowseLoadFailure extends CategoryBrowseState { final String error; CategoryBrowseLoadFailure(this.error); }
class CategoryBrowseBloc extends Bloc<CategoryBrowseEvent, CategoryBrowseState> { final ProgramRepository _repository; CategoryBrowseBloc(this._repository) : super(CategoryBrowseInitial()) { on<FetchProgramsByGenre>(_onFetchProgramsByGenre); } Future<void> _onFetchProgramsByGenre(FetchProgramsByGenre event, Emitter<CategoryBrowseState> emit) async { emit(CategoryBrowseLoading()); try { final programs = await _repository.getProgramsByGenre(slug: event.slug, page: 1); emit(CategoryBrowseLoadSuccess(programs)); } catch (e) { emit(CategoryBrowseLoadFailure(e.toString())); } } }


class CategoryBrowseScreen extends StatelessWidget {
  final String genreSlug;
  final String genreName;

  const CategoryBrowseScreen({
    super.key,
    required this.genreSlug,
    required this.genreName,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => CategoryBrowseBloc(RepositoryProvider.of<ProgramRepository>(context))
        ..add(FetchProgramsByGenre(genreSlug)),
      child: Scaffold(
        appBar: AppBar(
          title: Text(genreName),
        ),
        body: BlocBuilder<CategoryBrowseBloc, CategoryBrowseState>(
          builder: (context, state) {
            if (state is CategoryBrowseLoading || state is CategoryBrowseInitial) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is CategoryBrowseLoadFailure) {
              return Center(child: Text('خطأ: ${state.error}'));
            }
            if (state is CategoryBrowseLoadSuccess) {
              if (state.programs.isEmpty) {
                return const Center(child: Text('لا توجد برامج في هذا التصنيف حالياً.'));
              }

              return GridView.builder(
                padding: const EdgeInsets.all(12.0),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  // --- التعديلات هنا ---
                  childAspectRatio: 0.65, // <-- تقليل النسبة بشكل ملحوظ (كانت 2/3 ≈ 0.67)
                  crossAxisSpacing: 12.0,
                  mainAxisSpacing: 16.0, // <-- زيادة التباعد الرأسي
                  // --------------------
                ),
                itemCount: state.programs.length,
                itemBuilder: (context, index) {
                  final program = state.programs[index];
                  return ProgramCard(
                    program: program,
                    // تأكد من أن ProgramCard لا تحدد نسبة ارتفاع/عرض ثابتة للصورة
                    // بل تعتمد على المساحة المتاحة من GridView
                    aspectRatio: 3 / 4, // أو أزل هذه إذا كانت البطاقة مرنة
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ProgramDetailScreen(programId: program.id),
                        ),
                      );
                    },
                  );
                },
              );
            }
            return const Center(child: Text('حالة غير معروفة'));
          },
        ),
      ),
    );
  }
}