import '../entities/ayah_coordinates.dart';
import '../repositories/quran_repository.dart';

class GetPageCoordinatesUseCase {
  final QuranRepository repository;

  GetPageCoordinatesUseCase(this.repository);

  Future<List<AyahCoordinates>> call({
    required int pageNumber,
    required String mushafType,
  }) async {
    return await repository.getPageCoordinates(
      pageNumber: pageNumber,
      mushafType: mushafType,
    );
  }
}