import 'package:just_audio/just_audio.dart';
import 'package:audio_session/audio_session.dart';
import 'package:injectable/injectable.dart';

@lazySingleton
class AudioService {
  final AudioPlayer _player = AudioPlayer();

  Stream<int?> get currentIndexStream => _player.currentIndexStream;
  Stream<PlayerState> get playerStateStream => _player.playerStateStream;
  Stream<Duration> get positionStream => _player.positionStream;

  Future<void> init() async {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration(
      avAudioSessionCategory: AVAudioSessionCategory.playback,
      avAudioSessionCategoryOptions: AVAudioSessionCategoryOptions.duckOthers,
      avAudioSessionMode: AVAudioSessionMode.spokenAudio,
      androidAudioAttributes: AndroidAudioAttributes(
        contentType: AndroidAudioContentType.speech,
        usage: AndroidAudioUsage.media,
      ),
      androidAudioFocusGainType: AndroidAudioFocusGainType.gain,
    ));
  }

  Future<void> playPlaylist(List<String> urls, {int initialIndex = 0}) async {
    try {
      final playlist = ConcatenatingAudioSource(
        useLazyPreparation: true,
        children: urls.map((url) => AudioSource.uri(Uri.parse(url), tag: url)).toList(),
      );
      await _player.setAudioSource(playlist, initialIndex: initialIndex);
      await _player.play();
    } catch (e) {
      print("Audio Play Error: $e");
      throw Exception("Error playing audio");
    }
  }

// ... (باقي الكود في الأعلى كما هو)

  Future<void> playRange({
    required int surahNumber,
    required int startAyah,
    required int endAyah,
    required String baseUrl,
    int ayahRepeat = 1, // ✅ عدد مرات تكرار الآية الواحدة
    int rangeRepeat = 1, // ✅ عدد مرات تكرار الفقرة كاملة
  }) async {
    try {
      final List<AudioSource> playlist = [];

      // ✅ الحلقة الخارجية: تكرار الفقرة (النطاق) كاملة
      for (int rangeCycle = 0; rangeCycle < rangeRepeat; rangeCycle++) {

        // التحقق من البسملة (تضاف في بداية كل دورة للنطاق إذا كانت الفقرة تبدأ من الآية 1)
        if (startAyah == 1 && surahNumber != 1 && surahNumber != 9) {
          playlist.add(AudioSource.uri(Uri.parse("$baseUrl/001001.mp3")));
        }

        // الحلقة الوسطى: المرور على الآيات من البداية للنهاية
        for (int i = startAyah; i <= endAyah; i++) {
          final String fileName = _formatFileName(surahNumber, i);
          final Uri url = Uri.parse("$baseUrl/$fileName.mp3");

          // ✅ الحلقة الداخلية: تكرار الآية الحالية (ayahRepeat)
          for (int r = 0; r < ayahRepeat; r++) {
            // نمرر رقم الآية كـ tag
            playlist.add(AudioSource.uri(url, tag: i));
          }
        }
      }

      final source = ConcatenatingAudioSource(
        useLazyPreparation: true,
        children: playlist,
      );
      await _player.setAudioSource(source);
      await _player.play();

    } catch (e) {
      print("Quran Play Error: $e");
      throw Exception("فشل تشغيل التلاوة");
    }
  }

  // ... (باقي الكود في الأسفل كما هو)
  String _formatFileName(int surah, int ayah) {
    String s = surah.toString().padLeft(3, '0');
    String a = ayah.toString().padLeft(3, '0');
    return "$s$a";
  }

  Future<void> pause() async => await _player.pause();
  Future<void> resume() async => await _player.play();
  Future<void> stop() async => await _player.stop();
  Future<void> seekToNext() async => await _player.seekToNext();
  Future<void> seekToPrevious() async => await _player.seekToPrevious();

  void dispose() {
    _player.dispose();
  }
}