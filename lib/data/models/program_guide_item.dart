import 'package:equatable/equatable.dart';

// نموذج لتمثيل كل سطر في جدول البرامج
class ProgramGuideItem extends Equatable {
  final String from;
  final String to;
  final String program;

  const ProgramGuideItem({
    required this.from,
    required this.to,
    required this.program,
  });

  // دالة لإنشاء كائن من بيانات JSON
  factory ProgramGuideItem.fromJson(Map<String, dynamic> json) {
    return ProgramGuideItem(
      from: json['from'] as String? ?? '',
      to: json['to'] as String? ?? '',
      program: json['program'] as String? ?? '',
    );
  }

  @override
  List<Object?> get props => [from, to, program];
}