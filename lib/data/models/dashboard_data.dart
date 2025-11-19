import 'program_item.dart';
import 'program_slider.dart';

// هذا النموذج يمثل الكائن 'data' الذي يأتي من API
// ويحتوي على قائمة البانر وقائمة السلايدرات
class DashboardData {
  final List<ProgramItem> banner;
  final List<ProgramSlider> sliders;

  const DashboardData({
    required this.banner,
    required this.sliders,
  });

  factory DashboardData.fromJson(Map<String, dynamic> json) {
    // 1. تحليل قائمة البانر (banner)
    // نفترض أن 'banner' هي قائمة من نفس نوع 'ProgramItem'
    List<ProgramItem> bannerList = [];
    if (json['banner'] is List) {
      bannerList = (json['banner'] as List)
          .map((itemJson) => ProgramItem.fromJson(itemJson as Map<String, dynamic>))
          .toList();
    }

    // 2. تحليل قائمة السلايدرات (sliders)
    List<ProgramSlider> slidersList = [];
    if (json['sliders'] is List) {
      slidersList = (json['sliders'] as List)
          .map((sliderJson) => ProgramSlider.fromJson(sliderJson as Map<String, dynamic>))
          .toList();
    }

    return DashboardData(
      banner: bannerList,
      sliders: slidersList,
    );
  }
}