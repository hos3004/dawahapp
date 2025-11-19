import 'package:equatable/equatable.dart';

// الكلاس الأساسي لجميع Events الخاصة بـ TikTokFeedBloc
abstract class TikTokFeedEvent extends Equatable {
  const TikTokFeedEvent();

  @override
  List<Object> get props => [];
}

/// Event يُرسل لبدء جلب الدفعة الأولى من الفيديوهات
class FetchTikTokFeed extends TikTokFeedEvent {}

/// Event يُرسل لجلب المزيد من الفيديوهات (للتمرير اللانهائي)
class LoadMoreTikTokFeed extends TikTokFeedEvent {}

/// Event يُرسل عند قيام المستخدم "بالسحب للتحديث"
class RefreshTikTokFeed extends TikTokFeedEvent {}

// --- ⚠️ [إضافة جديدة] ---
/// Event يُرسل عند الضغط على زر "الترتيب العشوائي"
class ShuffleTikTokFeed extends TikTokFeedEvent {}
// -------------------------