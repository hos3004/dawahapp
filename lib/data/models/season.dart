/* ==== BEGIN FILE: C:\daawah_app\lib\data\models\season.dart ==== */

import 'package:equatable/equatable.dart';
class Season extends Equatable {
  final int id;
  final String name;
  const Season({
    required this.id,
    required this.name,
  });
// Ø¯Ø§Ù„Ø© Ù„ØªØ­ÙˆÙŠÙ„ JSON Ø§Ù„Ù‚Ø§Ø¯Ù… Ù…Ù† API Ø¥Ù„Ù‰ ÙƒØ§Ø¦Ù† Season
  // (Ù…ÙˆØ¬ÙˆØ¯ Ø¯Ø§Ø®Ù„ Ù‚Ø§Ø¦Ù…Ø© data Ù ÙŠ TvShowDetailsResponse)
  factory Season.fromJson(Map<String, dynamic> json) {
    return Season(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
    );
  }

  // ✅ --- [التعديل 1] ---
  // إضافة دالة toJson لتحويل الكائن إلى Map
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['name'] = name;
    return data;
  }
  // ✅ --- نهاية التعديل 1 ---

  @override
  List<Object?> get props => [id, name];
}

/* ==== END FILE: C:\daawah_app\lib\data\models\season.dart ==== */