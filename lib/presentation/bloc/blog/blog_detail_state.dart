import 'package:equatable/equatable.dart';
import '../../../data/models/tiktok_video_item.dart';

// الكلاس الأساسي لجميع الحالات (States)
abstract class TikTokFeedState extends Equatable {
  // --- ⚠️ [تعديل 1/3] ---
  // نقل الخصائص المشتركة إلى الكلاس الأساسي
  final List<TikTokVideoItem> videos;
  final bool hasReachedMax;

  const TikTokFeedState({
    this.videos = const <TikTokVideoItem>[],
    this.hasReachedMax = false,
  });
  // -------------------------

  @override
  List<Object> get props => [videos, hasReachedMax];
}

/// الحالة الأولية (قبل بدء أي شيء)
class TikTokFeedInitial extends TikTokFeedState {
  // الحالة الأولية دائماً فارغة
  const TikTokFeedInitial() : super(videos: const [], hasReachedMax: false);
}

/// حالة جاري التحميل (عندما يتم طلب البيانات)
class TikTokFeedLoading extends TikTokFeedState {
  // --- ⚠️ [تعديل 2/3] ---
  // نجعلها ترث الخصائص من الحالة السابقة
  // هذا يسمح لنا بعرض "مؤشر تحميل" فوق البيانات القديمة
  const TikTokFeedLoading({
    required List<TikTokVideoItem> previousVideos,
    required bool previousHasReachedMax,
  }) : super(videos: previousVideos, hasReachedMax: previousHasReachedMax);
// -------------------------
}

/// حالة النجاح (عندما يتم جلب البيانات بنجاح)
class TikTokFeedSuccess extends TikTokFeedState {
  // الخصائص موجودة أصلاً في الكلاس الأساسي
  const TikTokFeedSuccess({
    required super.videos,
    required super.hasReachedMax,
  });
}

/// حالة الفشل (عند حدوث خطأ أثناء جلب البيانات)
class TikTokFeedFailure extends TikTokFeedState {
  final String error;

  // --- ⚠️ [تعديل 3/3] ---
  // نجعلها ترث الخصائص + تضيف الخطأ
  // هذا يسمح لنا بعرض "رسالة خطأ" فوق البيانات القديمة
  const TikTokFeedFailure({
    required this.error,
    required List<TikTokVideoItem> previousVideos,
    required bool previousHasReachedMax,
  }) : super(videos: previousVideos, hasReachedMax: previousHasReachedMax);
  // -------------------------

  @override
  List<Object> get props => [videos, hasReachedMax, error];
}