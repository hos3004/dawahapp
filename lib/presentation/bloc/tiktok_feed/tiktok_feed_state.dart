import 'package:equatable/equatable.dart';
import '../../../data/models/tiktok_video_item.dart';

// الكلاس الأساسي لجميع الحالات (States)
abstract class TikTokFeedState extends Equatable {
  final List<TikTokVideoItem> videos;
  final bool hasReachedMax;

  const TikTokFeedState({
    this.videos = const <TikTokVideoItem>[],
    this.hasReachedMax = false,
  });

  @override
  List<Object> get props => [videos, hasReachedMax];
}

/// الحالة الأولية (قبل بدء أي شيء)
class TikTokFeedInitial extends TikTokFeedState {
  const TikTokFeedInitial() : super(videos: const [], hasReachedMax: false);
}

/// حالة جاري التحميل
class TikTokFeedLoading extends TikTokFeedState {
  const TikTokFeedLoading({
    required List<TikTokVideoItem> previousVideos,
    required bool previousHasReachedMax,
  }) : super(
    videos: previousVideos,
    hasReachedMax: previousHasReachedMax,
  );
}

/// حالة النجاح (عندما يتم جلب البيانات بنجاح)
class TikTokFeedSuccess extends TikTokFeedState {
  const TikTokFeedSuccess({
    required super.videos,
    required super.hasReachedMax,
  });
}

/// حالة الفشل (عند حدوث خطأ أثناء جلب البيانات)
class TikTokFeedFailure extends TikTokFeedState {
  final String error;

  const TikTokFeedFailure({
    required this.error,
    required List<TikTokVideoItem> previousVideos,
    required bool previousHasReachedMax,
  }) : super(
    videos: previousVideos,
    hasReachedMax: previousHasReachedMax,
  );

  @override
  List<Object> get props => [videos, hasReachedMax, error];
}
