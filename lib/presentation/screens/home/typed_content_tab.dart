import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/models/program_slider.dart'; // <-- استيراد Slider model
import '../../../data/repositories/program_repository.dart';
import '../../widgets/horizontal_program_row.dart';

// --- Bloc Events ---
abstract class TypedContentEvent {}
class FetchTypedContent extends TypedContentEvent {
  final String type; // movie, tv_show, video
  FetchTypedContent(this.type);
}

// --- Bloc States ---
abstract class TypedContentState {}
class TypedContentInitial extends TypedContentState {}
class TypedContentLoading extends TypedContentState {}
class TypedContentLoadSuccess extends TypedContentState {
  final List<ProgramSlider> sliders;
  TypedContentLoadSuccess(this.sliders);
}
class TypedContentLoadFailure extends TypedContentState {
  final String error;
  TypedContentLoadFailure(this.error);
}

// --- Bloc Logic ---
class TypedContentBloc extends Bloc<TypedContentEvent, TypedContentState> {
  final ProgramRepository _repository;

  TypedContentBloc(this._repository) : super(TypedContentInitial()) {
    on<FetchTypedContent>(_onFetchTypedContent);
  }

  Future<void> _onFetchTypedContent(FetchTypedContent event, Emitter<TypedContentState> emit) async {
    emit(TypedContentLoading());
    try {
      // استخدام الدالة الجديدة في الريبو
      final sliders = await _repository.getDashboardSlidersByType(event.type);
      emit(TypedContentLoadSuccess(sliders));
    } catch (e) {
      emit(TypedContentLoadFailure(e.toString()));
    }
  }
}


// --- الويدجت ---
class TypedContentTab extends StatelessWidget {
  final String contentType; // 'movie', 'tv_show', 'video'

  const TypedContentTab({super.key, required this.contentType});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => TypedContentBloc(RepositoryProvider.of<ProgramRepository>(context))
        ..add(FetchTypedContent(contentType)), // بدء جلب البيانات
      child: BlocBuilder<TypedContentBloc, TypedContentState>(
        builder: (context, state) {
          if (state is TypedContentLoading || state is TypedContentInitial) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is TypedContentLoadFailure) {
            return Center(child: Text('خطأ: ${state.error}', style: const TextStyle(color: Colors.white70)));
          }
          if (state is TypedContentLoadSuccess) {
            if (state.sliders.isEmpty) {
              return const Center(child: Text('لا يوجد محتوى متاح حالياً.', style: TextStyle(color: Colors.white70)));
            }

            // عرض السلايدرات في قائمة رأسية
            return CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: EdgeInsets.only(top: kToolbarHeight + MediaQuery.of(context).padding.top + 10), // ترك مسافة للـ AppBar والـ TabBar
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                          (context, index) {
                        final slider = state.sliders[index];
                        // كل السلايدرات هنا طولية (لا يوجد صف ثابت)
                        return HorizontalProgramRow(
                          title: slider.title,
                          programs: slider.programs,
                          rowHeight: 280.0,
                          cardAspectRatio: 2 / 3,
                          cardWidth: 150.0,
                          // لا نحتاج callback خاص هنا
                        );
                      },
                      childCount: state.sliders.length,
                    ),
                  ),
                ),
              ],
            );
          }
          return const Center(child: Text('حالة غير معروفة', style: TextStyle(color: Colors.white70)));
        },
      ),
    );
  }
}