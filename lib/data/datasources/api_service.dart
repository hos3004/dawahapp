/* ==== BEGIN FILE: lib/data/datasources/api_service.dart ==== */

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:nb_utils/nb_utils.dart';
import '../../utils/constants.dart';
import '../../data/models/quran_models.dart'; // Ensure this file exists


class ApiService {
  static const String _streamitBase = 'https://daawah.tv/wp-json/streamit/api/v1';
  static const String _wpBase = 'https://daawah.tv/wp-json/wp/v2';

  // TikTok JSON URL
  static const String _tiktokJsonUrl = 'https://daawah.tv/app/daawah_tiktok.json';

  // ======================= [ Helper: _getRequest ] =======================
  Future<dynamic> _getRequest(
      String endpoint, {
        bool requiresAuth = true,
        bool isStreamit = true,
      }) async {
    final String baseUrl = isStreamit ? _streamitBase : _wpBase;
    final String normalized = endpoint.startsWith('/') ? endpoint.substring(1) : endpoint;
    final Uri url = Uri.parse('$baseUrl/$normalized');

    print('📡 Calling API: $url');

    final Map<String, String> headers = {
      'Content-Type': 'application/json; charset=UTF-8',
      'Accept': 'application/json; charset=UTF-8',
    };

    if (requiresAuth) {
      final String token = await getStringAsync(TOKEN);
      if (token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    try {
      final response = await http.get(url, headers: headers).timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        return jsonDecode(utf8.decode(response.bodyBytes));
      } else {
        print('❌ API Error: ${response.statusCode} - ${response.body}');
        throw Exception('API error: ${response.statusCode}');
      }
    } catch (e) {
      print('⚠️ Network or parsing error: $e');
      rethrow;
    }
  }

  // ======================= [ Streamit API Calls ] =======================

  Future<Map<String, dynamic>> getHomeDashboard({String type = 'home'}) async {
    final res = await _getRequest('content/dashboard/$type', isStreamit: true, requiresAuth: false);
    if (res is Map<String, dynamic>) return res;
    throw Exception('Invalid home dashboard response');
  }

  Future<Map<String, dynamic>> getTvShowDetails(int id) async {
    final res = await _getRequest('tv-shows/$id', isStreamit: true, requiresAuth: false);
    return res as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getMovieDetails(int id) async {
    final res = await _getRequest('movies/$id', isStreamit: true, requiresAuth: false);
    return res as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getVideoDetails(int id) async {
    final res = await _getRequest('videos/$id', isStreamit: true, requiresAuth: false);
    return res as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getSeasonEpisodes(int programId, int seasonId) async {
    final res = await _getRequest(
      'tv-shows/$programId/seasons/$seasonId?limit=200&offset=0',
      isStreamit: true,
    );
    return res as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getEpisodeDetails(int episodeId) async {
    final res = await _getRequest('tv-show/season/episodes/$episodeId', isStreamit: true);
    return res as Map<String, dynamic>;
  }

  Future<dynamic> getProgramsByGenre(String slug, int page, int perPage) async {
    final res = await _getRequest(
      'content/tv_show/genre/$slug?paged=$page&posts_per_page=$perPage',
      isStreamit: true,
    );
    return res;
  }

  Future<dynamic> searchPrograms(String query, int page, int perPage) async {
    final res = await _getRequest(
      'content/search?search=$query&paged=$page&posts_per_page=$perPage',
      isStreamit: true,
      requiresAuth: false,
    );
    return res;
  }

  // ======================= [ WordPress API Calls ] =======================

  Future<dynamic> getGenreList(int page, int perPage) async {
    final res = await _getRequest(
      'tv_show_genre?page=$page&per_page=$perPage',
      isStreamit: false,
      requiresAuth: false,
    );
    return res;
  }

  Future<dynamic> getBlogList(int page, int perPage) async {
    final res = await _getRequest(
      'posts?_embed=1&page=$page&per_page=$perPage',
      isStreamit: false,
      requiresAuth: false,
    );
    return res;
  }

  Future<dynamic> getBlogDetails(int postId) async {
    final res = await _getRequest(
      'posts/$postId?_embed=1',
      isStreamit: false,
      requiresAuth: false,
    );
    return res;
  }

  Future<dynamic> getWpEpisodeDetails(int episodeId) async {
    final res = await _getRequest(
      'episode/$episodeId?_embed=1',
      isStreamit: false,
      requiresAuth: false,
    );
    return res;
  }

  // ======================= [ External JSON Calls (TikTok) ] =======================

  Future<List<dynamic>> getTikTokFeed() async {
    final Uri url = Uri.parse(_tiktokJsonUrl);
    print('📡 Calling External JSON: $url');

    try {
      final response = await http.get(url).timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        final decodedBody = utf8.decode(response.bodyBytes);
        final data = jsonDecode(decodedBody);

        if (data is List) {
          return data;
        } else {
          print('❌ JSON Error: Expected a List but got ${data.runtimeType}');
          throw Exception('Invalid data format: Expected List');
        }
      } else {
        print('❌ JSON API Error: ${response.statusCode} - ${response.body}');
        throw Exception('API error: ${response.statusCode}');
      }
    } catch (e) {
      print('⚠️ Network or parsing error: $e');
      rethrow;
    }
  }

  // ======================= [ Quran API Calls ] =======================

  // 1. Get Quran Chapters (Surahs)
  Future<List<Surah>> getQuranChapters() async {
    const String url = 'https://api.quran.com/api/v4/chapters?language=ar';
    print('📡 Calling Quran API: $url');

    try {
      // Using http directly since this is an external API not related to Streamit/WP
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final json = jsonDecode(utf8.decode(response.bodyBytes));
        final List<dynamic> chapters = json['chapters'];
        return chapters.map((e) => Surah.fromJson(e)).toList();
      } else {
        throw Exception('Failed to load chapters: ${response.statusCode}');
      }
    } catch (e) {
      print('⚠️ Quran API Error: $e');
      rethrow;
    }
  }
// 3. Get Mushafs List from Quranpedia
  Future<List<Mushaf>> getMushafs() async {
    const String url = 'https://api.quranpedia.net/v1/mushafs';
    print('📡 Calling Mushaf API: $url');

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        // الاستجابة تأتي كقائمة مباشرة []
        final List<dynamic> jsonList = jsonDecode(utf8.decode(response.bodyBytes));
        return jsonList.map((e) => Mushaf.fromJson(e)).toList();
      } else {
        throw Exception('Failed to load mushafs: ${response.statusCode}');
      }
    } catch (e) {
      print('⚠️ Mushaf API Error: $e');
      rethrow;
    }
  }
  // 2. Get Verses for a specific Surah
  Future<List<Ayah>> getSurahVerses(int surahId) async {
    // Using standard Uthmani script
    final String url = 'https://api.quran.com/api/v4/quran/verses/uthmani?chapter_number=$surahId';
    print('📡 Calling Quran API: $url');

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final json = jsonDecode(utf8.decode(response.bodyBytes));
        final List<dynamic> verses = json['verses'];
        return verses.map((e) => Ayah.fromJson(e)).toList();
      } else {
        throw Exception('Failed to load verses: ${response.statusCode}');
      }
    } catch (e) {
      print('⚠️ Quran API Error: $e');
      rethrow;
    }
  }
}

/* ==== END FILE: lib/data/datasources/api_service.dart ==== */