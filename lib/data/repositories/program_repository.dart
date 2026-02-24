import '../datasources/api_service.dart';
import '../models/dashboard_data.dart';
import '../models/episode_details_data.dart';
import '../models/episode_item.dart';
import '../models/genre_data.dart';
import '../models/program_item.dart';
import '../models/program_slider.dart';
import '../models/tv_show_details.dart';
import '../models/blog_post.dart';
import '../models/blog_post_detail.dart';
import '../models/tiktok_video_item.dart';

class ProgramRepository {
  final ApiService _apiService = ApiService();

  // === 🟢 متغيرات التخزين المؤقت (Caching) ===

  // 1. تخزين بيانات الصفحة الرئيسية
  DashboardData? _cachedHomeData;
  DateTime? _lastHomeFetchTime;

  // 2. تخزين قائمة التصنيفات
  List<GenreData>? _cachedGenres;
  DateTime? _lastGenresFetchTime;

  // 3. مدة صلاحية الكاش (24 ساعة)
  static const Duration _cacheValidity = Duration(hours: 24);

  // === 🟢 دالة مساعدة للتحقق من الصلاحية ===
  bool _isCacheValid(DateTime? lastFetchTime) {
    if (lastFetchTime == null) return false;
    final difference = DateTime.now().difference(lastFetchTime);
    return difference < _cacheValidity;
  }

  // --- getHomeContent (معدلة للكاش) ---
  Future<DashboardData> getHomeContent({bool forceRefresh = false}) async {
    // 1. إذا كان هناك كاش صالح ولم يتم طلب تحديث إجباري، أعد البيانات المحفوظة
    if (_cachedHomeData != null && !forceRefresh && _isCacheValid(_lastHomeFetchTime)) {
      print('📦 Using Cached Home Data (Last fetch: $_lastHomeFetchTime)');
      return _cachedHomeData!;
    }

    try {
      print('🌐 Fetching Fresh Home Data from API...');
      final Map<String, dynamic> response = await _apiService.getHomeDashboard(type: 'home');

      if (response['data'] != null && response['data'] is Map<String, dynamic>) {
        // 2. حفظ البيانات الجديدة وتحديث الوقت
        _cachedHomeData = DashboardData.fromJson(response['data'] as Map<String, dynamic>);
        _lastHomeFetchTime = DateTime.now();
        return _cachedHomeData!;
      } else {
        throw Exception('Invalid data structure for dashboard');
      }
    } catch (e) {
      // في حال فشل الشبكة، إذا كان لدينا كاش قديم، نعيده بدلاً من الخطأ
      if (_cachedHomeData != null) {
        print('⚠️ Network Error ($e), returning cached data as fallback.');
        return _cachedHomeData!;
      }
      print('Error in getHomeContent: $e');
      throw Exception('Failed to load home content: $e');
    }
  }

  // --- getDashboardSlidersByType ---
  Future<List<ProgramSlider>> getDashboardSlidersByType(String type) async {
    try {
      final Map<String, dynamic> response =
      await _apiService.getHomeDashboard(type: type);
      List<ProgramSlider> dynamicSliders = [];
      if (response['data'] != null && response['data']['sliders'] is List) {
        dynamicSliders = (response['data']['sliders'] as List)
            .map((sliderJson) =>
            ProgramSlider.fromJson(sliderJson as Map<String, dynamic>))
            .toList();
      }
      return dynamicSliders;
    } catch (e) {
      print('Error in getDashboardSlidersByType for type $type: $e');
      throw Exception('Failed to load dashboard content for type $type: $e');
    }
  }

  // --- getProgramDetails ---
  Future<TvShowDetails> getProgramDetails(int programId) async {
    try {
      final Map<String, dynamic> response =
      await _apiService.getTvShowDetails(programId);
      if (response['data'] != null &&
          response['data']['details'] is Map<String, dynamic>) {
        return TvShowDetails.fromJson(
            response['data']['details'] as Map<String, dynamic>);
      } else if (response['data'] is Map<String, dynamic>) {
        return TvShowDetails.fromJson(response['data'] as Map<String, dynamic>);
      } else {
        throw Exception('Invalid data structure for program details');
      }
    } catch (e) {
      print('Error in getProgramDetails: $e');
      throw Exception('Failed to load program details: $e');
    }
  }

  // --- getMovieDetails ---
  Future<TvShowDetails> getMovieDetails(int movieId) async {
    try {
      final Map<String, dynamic> response =
      await _apiService.getMovieDetails(movieId);
      if (response['data'] != null &&
          response['data']['details'] is Map<String, dynamic>) {
        return TvShowDetails.fromJson(
            response['data']['details'] as Map<String, dynamic>);
      } else if (response['data'] is Map<String, dynamic>) {
        return TvShowDetails.fromJson(response['data'] as Map<String, dynamic>);
      } else {
        throw Exception('Invalid data structure for movie details');
      }
    } catch (e) {
      print('Error in getMovieDetails: $e');
      throw Exception('Failed to load movie details: $e');
    }
  }

  // --- getVideoDetails ---
  Future<TvShowDetails> getVideoDetails(int videoId) async {
    try {
      final Map<String, dynamic> response =
      await _apiService.getVideoDetails(videoId);
      if (response['data'] != null &&
          response['data']['details'] is Map<String, dynamic>) {
        return TvShowDetails.fromJson(
            response['data']['details'] as Map<String, dynamic>);
      } else if (response['data'] is Map<String, dynamic>) {
        return TvShowDetails.fromJson(response['data'] as Map<String, dynamic>);
      } else {
        throw Exception('Invalid data structure for video details');
      }
    } catch (e) {
      print('Error in getVideoDetails: $e');
      throw Exception('Failed to load video details: $e');
    }
  }

  // --- getSeasonEpisodes ---
  Future<List<EpisodeItem>> getSeasonEpisodes(
      int programId, int seasonId) async {
    try {
      final Map<String, dynamic> response =
      await _apiService.getSeasonEpisodes(programId, seasonId);
      if (response['data'] != null && response['data']['episodes'] is List) {
        final List<dynamic> episodesJson = response['data']['episodes'] as List;
        return episodesJson
            .map((json) => EpisodeItem.fromJson(json as Map<String, dynamic>))
            .toList();
      } else {
        print('Unexpected structure for season episodes: $response');
        return [];
      }
    } catch (e) {
      print('Error in getSeasonEpisodes: $e');
      throw Exception('Failed to load season episodes: $e');
    }
  }

  // --- getEpisodeDetails ---
  Future<EpisodeDetailsData> getEpisodeDetails(int episodeId) async {
    try {
      final Map<String, dynamic> response =
      await _apiService.getEpisodeDetails(episodeId);
      if (response['data'] is Map<String, dynamic>) {
        return EpisodeDetailsData.fromJson(
            response['data'] as Map<String, dynamic>);
      } else {
        throw Exception('Invalid data structure for episode details');
      }
    } catch (e) {
      print('Error in getEpisodeDetails: $e');
      throw Exception('Failed to load episode details: $e');
    }
  }

  // --- getGenreList (معدلة للكاش) ---
  Future<List<GenreData>> getGenreList({int page = 1, int perPage = 50}) async {
    // كاش فقط للصفحة الأولى لتسريع فتح شاشة التصنيفات
    if (page == 1 && _cachedGenres != null && _isCacheValid(_lastGenresFetchTime)) {
      print('📦 Using Cached Genres');
      return _cachedGenres!;
    }

    try {
      final response = await _apiService.getGenreList(page, perPage);
      List<GenreData> genres = [];

      if (response is List) {
        genres = response
            .map((json) => GenreData.fromJson(json as Map<String, dynamic>))
            .toList();
      } else if (response is Map<String, dynamic> &&
          response.containsKey('data') &&
          response['data'] is List) {
        final List<dynamic> genresJson = response['data'] as List<dynamic>;
        genres = genresJson
            .map((json) => GenreData.fromJson(json as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception('Invalid data structure for genre list');
      }

      // حفظ الكاش للصفحة الأولى
      if (page == 1) {
        _cachedGenres = genres;
        _lastGenresFetchTime = DateTime.now();
      }
      return genres;

    } catch (e) {
      if (page == 1 && _cachedGenres != null) return _cachedGenres!;
      print('Error in getGenreList: $e');
      throw Exception('Failed to load genres: $e');
    }
  }

  // --- getProgramsByGenre ---
  Future<List<ProgramItem>> getProgramsByGenre({
    required String slug,
    int page = 1,
    int perPage = 15,
  }) async {
    try {
      final response =
      await _apiService.getProgramsByGenre(slug, page, perPage);
      if (response is Map<String, dynamic> &&
          response.containsKey('data') &&
          response['data'] is List) {
        final List<dynamic> programsJson = response['data'] as List<dynamic>;
        return programsJson
            .map((json) => ProgramItem.fromJson(json as Map<String, dynamic>))
            .toList();
      } else {
        print('Unexpected structure for programs by genre: $response');
        throw Exception('Invalid data structure for programs by genre');
      }
    } catch (e) {
      print('Error in getProgramsByGenre for slug $slug: $e');
      rethrow;
    }
  }

  // --- getEpisodeLandscapeImageUrl ---
  Future<String?> getEpisodeLandscapeImageUrl(int episodeId) async {
    try {
      final response = await _apiService.getWpEpisodeDetails(episodeId);
      if (response != null &&
          response is Map<String, dynamic> &&
          response.containsKey('_embedded')) {
        final embedded = response['_embedded'] as Map<String, dynamic>?;
        if (embedded != null && embedded.containsKey('wp:featuredmedia')) {
          final featuredMediaList =
          embedded['wp:featuredmedia'] as List<dynamic>?;
          if (featuredMediaList != null && featuredMediaList.isNotEmpty) {
            final mediaDetails = featuredMediaList[0]['media_details']
            as Map<String, dynamic>?;
            if (mediaDetails != null && mediaDetails.containsKey('sizes')) {
              final sizes = mediaDetails['sizes'] as Map<String, dynamic>?;
              if (sizes != null) {
                final dynamic landscapeSize =
                    sizes['medium_large'] ?? sizes['large'] ?? sizes['full'];
                if (landscapeSize is Map<String, dynamic> &&
                    landscapeSize.containsKey('source_url')) {
                  return landscapeSize['source_url'] as String?;
                }
              }
            }
          }
        }
      }
      print('Landscape image URL not found in WP API response for episode $episodeId');
      return null;
    } catch (e) {
      print('Error in getEpisodeLandscapeImageUrl for episode $episodeId: $e');
      return null;
    }
  }

  // --- searchPrograms ---
  Future<List<ProgramItem>> searchPrograms({
    required String query,
    int page = 1,
    int perPage = 15,
  }) async {
    try {
      final response =
      await _apiService.searchPrograms(query, page, perPage);
      if (response is Map<String, dynamic> &&
          response.containsKey('data') &&
          response['data'] is List) {
        final List<dynamic> programsJson = response['data'] as List<dynamic>;
        return programsJson
            .map((json) => ProgramItem.fromJson(json as Map<String, dynamic>))
            .toList();
      } else if (response is List) {
        return response
            .map((json) => ProgramItem.fromJson(json as Map<String, dynamic>))
            .toList();
      } else {
        print('Unexpected structure for search results: $response');
        throw Exception('Invalid data structure for search results');
      }
    } catch (e) {
      print('Error in searchPrograms for query "$query": $e');
      rethrow;
    }
  }

  // --- getBlogList ---
  Future<List<BlogPost>> getBlogList({int page = 1, int perPage = 15}) async {
    try {
      final response = await _apiService.getBlogList(page, perPage);
      if (response is List) {
        return response
            .map((json) => BlogPost.fromJson(json as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception('Invalid data structure for blog list');
      }
    } catch (e) {
      print('Error in getBlogList: $e');
      throw Exception('Failed to load blogs: $e');
    }
  }

  // --- getBlogDetails ---
  Future<BlogPostDetail> getBlogDetails(int postId) async {
    try {
      final response = await _apiService.getBlogDetails(postId);
      if (response is Map<String, dynamic>) {
        return BlogPostDetail.fromJson(response);
      } else {
        throw Exception('Invalid data structure for blog details');
      }
    } catch (e) {
      print('Error in getBlogDetails: $e');
      throw Exception('Failed to load blog details: $e');
    }
  }

  // --- getTikTokFeed ---
  Future<List<TikTokVideoItem>> getTikTokFeed() async {
    try {
      final List<dynamic> response = await _apiService.getTikTokFeed();
      return response
          .map((json) =>
          TikTokVideoItem.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error in getTikTokFeed Repository: $e');
      throw Exception('Failed to load TikTok feed: $e');
    }
  }
}