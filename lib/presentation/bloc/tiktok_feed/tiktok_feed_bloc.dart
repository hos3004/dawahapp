import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:stream_transform/stream_transform.dart';
import 'dart:math';

import '../../../data/models/tiktok_video_item.dart';
import '../../../data/repositories/program_repository.dart';
import 'tiktok_feed_event.dart';
import 'tiktok_feed_state.dart';

// --- ⚠️ [إضافة 1/4]: استيراد خدمة سجل المشاهدة
import '../../../data/watch_history_service.dart';
// ------------------------------------

EventTransformer<Event> throttleDroppable<Event>() {
  return (events, mapper) {
    return events
        .throttle(const Duration(milliseconds: 100), trailing: false)
        .switchMap(mapper);
  };
}

class TikTokFeedBloc extends Bloc<TikTokFeedEvent, TikTokFeedState> {
  final ProgramRepository _repository;

  List<TikTokVideoItem> _fullVideoList = [];
  final int _videosPerPage = 5;

  TikTokFeedBloc(this._repository) : super(const TikTokFeedInitial()) {
    on<FetchTikTokFeed>(
      _onFetchTikTokFeed,
      transformer: (events, mapper) => events.distinct().switchMap(mapper),
    );

    on<LoadMoreTikTokFeed>(
      _onLoadMoreTikTokFeed,
      transformer: throttleDroppable(),
    );

    on<RefreshTikTokFeed>(_onRefreshTikTokFeed);
    on<ShuffleTikTokFeed>(_onShuffleTikTokFeed);
  }

  // --- ⚠️ [تعديل 2/4]: تعديل دالة الجلب والترشيح
  /// هذه الدالة تجلب البيانات، ترشحها، وتعكسها، ثم تحدث الحالة
  Future<void> _fetchAndEmitFeed(Emitter<TikTokFeedState> emit, {bool shuffle = false}) async {
    try {
      // 1. جلب البيانات من المصدر (JSON)
      final fetchedList = await _repository.getTikTokFeed();

      // 2. جلب IDs الفيديوهات المشاهدة من الذاكرة
      final watchedIds = await WatchHistoryService.getWatchHistoryIds();

      // 3. ترشيح القائمة: فصل "المشاهد" عن "غير المشاهد"
      final List<TikTokVideoItem> unwatchedVideos = [];
      final List<TikTokVideoItem> watchedVideos = [];

      for (var video in fetchedList) {
        if (watchedIds.contains(video.id.toString())) {
          watchedVideos.add(video);
        } else {
          unwatchedVideos.add(video);
        }
      }

      // 4. دمج القائمتين: "غير المشاهد" أولاً، ثم "المشاهد"
      // مع عكس الترتيب لكل قائمة (لضمان "الأحدث أولاً" في كلا القسمين)
      _fullVideoList =
          unwatchedVideos.reversed.toList() +
              watchedVideos.reversed.toList();

      // 5. إذا كان الطلب "عشوائي"، قم بخربطة القائمة النهائية
      if (shuffle) {
        _fullVideoList.shuffle(Random());
      }

      // 6. إرسال الصفحة الأولى
      final videosToShow = _fullVideoList.take(_videosPerPage).toList();

      emit(
        TikTokFeedSuccess(
          videos: videosToShow,
          hasReachedMax: _fullVideoList.length <= _videosPerPage,
        ),
      );
    } catch (e) {
      emit(
        TikTokFeedFailure(
          error: e.toString(),
          previousVideos: state.videos,
          previousHasReachedMax: state.hasReachedMax,
        ),
      );
    }
  }
  // ------------------------------------

  /// جلب الفيديوهات لأول مرة
  Future<void> _onFetchTikTokFeed(
      FetchTikTokFeed event,
      Emitter<TikTokFeedState> emit,
      ) async {
    if (_fullVideoList.isNotEmpty) return;

    emit(
      TikTokFeedLoading(
        previousVideos: state.videos,
        previousHasReachedMax: state.hasReachedMax,
      ),
    );

    // --- ⚠️ [تعديل 3/4]: استدعاء الدالة الجديدة
    await _fetchAndEmitFeed(emit);
  }

  /// تحميل المزيد (Pagination وهمي)
  Future<void> _onLoadMoreTikTokFeed(
      LoadMoreTikTokFeed event,
      Emitter<TikTokFeedState> emit,
      ) async {
    // (الكود هنا لم يتغير، سيعمل مع القائمة المرشحة)
    if (!state.hasReachedMax) {
      final currentCount = state.videos.length;
      if (currentCount < _fullVideoList.length) {
        final int remaining = _fullVideoList.length - currentCount;
        final int nextCount =
        (remaining < _videosPerPage) ? remaining : _videosPerPage;
        final newVideos =
        _fullVideoList.skip(currentCount).take(nextCount).toList();
        emit(
          TikTokFeedSuccess(
            videos: List.of(state.videos)..addAll(newVideos),
            hasReachedMax:
            (currentCount + newVideos.length) >= _fullVideoList.length,
          ),
        );
      } else {
        emit(
          TikTokFeedSuccess(
            videos: state.videos,
            hasReachedMax: true,
          ),
        );
      }
    }
  }

  /// السحب للتحديث (Refresh)
  Future<void> _onRefreshTikTokFeed(
      RefreshTikTokFeed event,
      Emitter<TikTokFeedState> emit,
      ) async {
    // --- ⚠️ [تعديل 4/4]: استدعاء الدالة الجديدة
    await _fetchAndEmitFeed(emit);
  }

  /// ترتيب القائمة عشوائياً (Shuffle)
  Future<void> _onShuffleTikTokFeed(
      ShuffleTikTokFeed event,
      Emitter<TikTokFeedState> emit,
      ) async {
    // التأكد أن لدينا فيديوهات
    if (_fullVideoList.isEmpty) {
      // إذا كانت القائمة فارغة، قم بالجلب أولاً (مع الترتيب العشوائي)
      emit(
        TikTokFeedLoading(
          previousVideos: state.videos,
          previousHasReachedMax: state.hasReachedMax,
        ),
      );
      await _fetchAndEmitFeed(emit, shuffle: true);
    } else {
      // إذا كانت القائمة موجودة، فقط قم بخربطتها وإرسالها
      _fullVideoList.shuffle(Random());
      final videosToShow = _fullVideoList.take(_videosPerPage).toList();
      emit(
        TikTokFeedSuccess(
          videos: videosToShow,
          hasReachedMax: _fullVideoList.length <= _videosPerPage,
        ),
      );
    }
  }
}