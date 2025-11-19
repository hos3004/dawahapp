import 'package:equatable/equatable.dart';
import 'program_item.dart'; // استيراد مودل البرنامج

class ProgramSlider extends Equatable {
  final String title;
  final List<ProgramItem> programs;

  const ProgramSlider({
    required this.title,
    required this.programs,
  });

  // دالة لتحويل JSON القادم من API (داخل قائمة 'sliders')
  factory ProgramSlider.fromJson(Map<String, dynamic> json) {
    List<ProgramItem> programsList = [];
    if (json['data'] is List) {
      programsList = (json['data'] as List)
          .map((itemJson) => ProgramItem.fromJson(itemJson as Map<String, dynamic>))
          .toList();
    }

    // في ملف MainFragment.kt، كان اسم الحقل 'title'
    return ProgramSlider(
      title: json['title'] as String? ?? 'قسم غير مسمى',
      programs: programsList,
    );
  }

  @override
  List<Object?> get props => [title, programs];
}