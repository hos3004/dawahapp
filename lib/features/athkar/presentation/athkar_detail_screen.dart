import 'dart:async'; // للتايمر
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/athkar_model.dart';

class AthkarDetailScreen extends StatefulWidget {
  final String? jsonPath;
  final AthkarData? directData;
  const AthkarDetailScreen({super.key, this.jsonPath, this.directData});

  @override
  State<AthkarDetailScreen> createState() => _AthkarDetailScreenState();
}

class _AthkarDetailScreenState extends State<AthkarDetailScreen> {
  final AudioPlayer _player = AudioPlayer();
  AthkarData? _data;
  AthkarReciter? _selectedReciter;
  bool _isLoading = true;
  bool _isPlaying = false;

  // اللون الرئيسي
  final Color _primaryColor = const Color(0xff0B4DA1);
  final Color _accentColor = const Color(0xFFD4AF37);

  @override
  void initState() {
    super.initState();
    if (widget.directData != null) {
      _data = widget.directData;
      if (_data!.reciters.isNotEmpty) _selectedReciter = _data!.reciters.first;
      _isLoading = false;
    } else {
      _loadData();
    }

    // مراقبة حالة الصوت لتحديث الواجهة تلقائياً عند الانتهاء
    _player.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        setState(() {
          _isPlaying = false;
          _player.stop();
          _player.seek(Duration.zero);
        });
      }
    });
  }

  Future<void> _loadData() async {
    if (widget.jsonPath == null) return;
    try {
      String response;
      if (widget.jsonPath!.startsWith('http')) {
        final res = await http.get(Uri.parse(widget.jsonPath!));
        if (res.statusCode == 200) {
          // Decode explicitly as UTF-8 to handle Arabic characters correctly
          response = utf8.decode(res.bodyBytes);
        } else {
          throw Exception('Failed to load athkar');
        }
      } else {
        response = await rootBundle.loadString(widget.jsonPath!);
      }

      final data = json.decode(response);
      setState(() {
        _data = AthkarData.fromJson(data);
        if (_data!.reciters.isNotEmpty) {
          _selectedReciter = _data!.reciters.first;
        }
        _isLoading = false;
      });
    } catch (e) {
      print("Error loading JSON: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleAudio() async {
    if (_selectedReciter == null) return;
    try {
      if (_isPlaying) {
        await _player.pause();
      } else {
        if (_player.processingState == ProcessingState.idle ||
            _player.processingState == ProcessingState.completed) {
          await _player.setUrl(_selectedReciter!.audioUrl);
        }
        _player.play();
      }
      setState(() => _isPlaying = !_isPlaying);
    } catch (e) {
      print("Audio Error: $e");
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: Stack(
          children: [
            // 1. الخلفية
            Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage("assets/images/bbg.jpg"),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            // 2. طبقة تغطية
            Container(color: Colors.white.withOpacity(0.85)),

            // 3. المحتوى
            Column(
              children: [
                // AppBar
                AppBar(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  iconTheme: IconThemeData(color: _primaryColor),
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back_ios),
                    onPressed: () => Navigator.pop(context),
                  ),
                  title: Text(
                    _data!.title,
                    style: GoogleFonts.tajawal(
                        fontWeight: FontWeight.bold, color: _primaryColor),
                  ),
                  centerTitle: true,
                ),

                // قسم المشغل المطور (مع السلايد شو)
                _buildProAudioPlayer(),

                // القائمة
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                    itemCount: _data!.content.length,
                    itemBuilder: (context, index) {
                      return _buildCreativeAthkarCard(_data!.content[index]);
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // --- ويدجت المشغل المطور (يحتوي على السلايد شو) ---
  Widget _buildProAudioPlayer() {
    return Container(
      height: 440, // ارتفاع ثابت للمشغل ليتسع للصور
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
              color: _primaryColor.withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 5)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(25),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 1. طبقة الصور المتحركة (خلفية المشغل)
            NatureSlideshow(isPlaying: _isPlaying),

            // 2. طبقة تدرج لوني لضمان قراءة النصوص فوق الصور
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    _primaryColor.withOpacity(0.1), // غامق من الأسفل
                    _primaryColor.withOpacity(0.3),
                    _primaryColor.withOpacity(0.6), // شفاف من الأعلى
                  ],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
              ),
            ),

            // 3. محتوى المشغل (أزرار ونصوص)
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // الصف العلوي: القارئ
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const CircleAvatar(
                          radius: 22,
                          backgroundColor: Colors.transparent,
                          child:
                              Icon(Icons.person, color: Colors.white, size: 28),
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text("القارئ المختار:",
                                style: GoogleFonts.tajawal(
                                    color: Colors.white70, fontSize: 11)),
                            DropdownButtonHideUnderline(
                              child: DropdownButton<AthkarReciter>(
                                value: _selectedReciter,
                                dropdownColor: _primaryColor.withOpacity(0.9),
                                icon: const Icon(Icons.keyboard_arrow_down,
                                    color: Colors.white),
                                style: GoogleFonts.tajawal(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16),
                                onChanged: (val) {
                                  setState(() {
                                    _selectedReciter = val;
                                    _isPlaying = false;
                                  });
                                  _player.stop();
                                },
                                items: _data!.reciters
                                    .map((r) => DropdownMenuItem(
                                          value: r,
                                          child: Text(r.name),
                                        ))
                                    .toList(),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  // الصف السفلي: التحكم والتشغيل
                  Row(
                    children: [
                      // زر التشغيل الكبير
                      GestureDetector(
                        onTap: _toggleAudio,
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _accentColor,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: [
                              BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 10,
                                  spreadRadius: 1)
                            ],
                          ),
                          child: Icon(
                              _isPlaying ? Icons.pause : Icons.play_arrow,
                              color: Colors.white,
                              size: 35),
                        ),
                      ),
                      const SizedBox(width: 15),
                      // شريط تقدم (وهمي للتصميم)
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                  activeTrackColor: Colors.white,
                                  inactiveTrackColor: Colors.white30,
                                  thumbColor: Colors.white,
                                  thumbShape: const RoundSliderThumbShape(
                                      enabledThumbRadius: 6),
                                  overlayShape: SliderComponentShape.noOverlay,
                                  trackHeight: 3),
                              child: Slider(
                                value: _isPlaying ? 0.3 : 0.0,
                                onChanged: (v) {},
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ... (نفس دالة _buildCreativeAthkarCard السابقة) ...
  Widget _buildCreativeAthkarCard(AthkarItem item) {
    bool isCompleted = item.currentCount == 0;
    double progress =
        item.count > 0 ? 1 - (item.currentCount / item.count) : 1.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 5)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.text,
                    style: GoogleFonts.tajawal(
                      fontSize: 17,
                      height: 1.6,
                      fontWeight: FontWeight.w500,
                      color:
                          isCompleted ? Colors.grey.shade400 : Colors.black87,
                    ),
                  ),
                  if (item.reward != null && item.reward!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      item.reward!,
                      style: GoogleFonts.tajawal(
                          fontSize: 13, color: _accentColor),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 16),
            GestureDetector(
              onTap: () {
                if (item.currentCount > 0) {
                  setState(() {
                    item.currentCount--;
                    HapticFeedback.mediumImpact();
                  });
                }
              },
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 60,
                    height: 60,
                    child: CircularProgressIndicator(
                      value: isCompleted ? 1.0 : progress,
                      backgroundColor: Colors.grey.shade100,
                      color: isCompleted ? Colors.green : _primaryColor,
                      strokeWidth: 5,
                    ),
                  ),
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: isCompleted ? Colors.green : Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: isCompleted
                          ? []
                          : [
                              BoxShadow(
                                  color: Colors.grey.withOpacity(0.1),
                                  blurRadius: 5)
                            ],
                    ),
                    child: Center(
                      child: isCompleted
                          ? const Icon(Icons.check,
                              color: Colors.white, size: 24)
                          : Text(
                              "${item.currentCount}",
                              style: GoogleFonts.tajawal(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: _primaryColor),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------
// 🌿 ويدجت السلايد شو للمناظر الطبيعية (الجديد)
// -----------------------------------------------------------
class NatureSlideshow extends StatefulWidget {
  final bool isPlaying;
  const NatureSlideshow({super.key, required this.isPlaying});

  @override
  State<NatureSlideshow> createState() => _NatureSlideshowState();
}

class _NatureSlideshowState extends State<NatureSlideshow>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;
  Timer? _timer;
  int _currentIndex = 0;

  // قائمة الصور (تأكد من وجود هذه الملفات في assets/images/athkar/)
// التعديل: تغيير العدد إلى 15 والصيغة إلى .jpeg
  final List<String> _images =
      List.generate(15, (index) => 'assets/images/athkar/${index + 1}.jpeg');
  @override
  void initState() {
    super.initState();
    // إعداد الأنيميشن للزووم (من 1.0 إلى 1.15)
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(
          seconds: 16), // مدة الحركة أطول قليلاً من مدة الصورة لتكون ناعمة
    );
    _scaleAnimation =
        Tween<double>(begin: 1.0, end: 1.5).animate(_animController);
  }

  @override
  void didUpdateWidget(covariant NatureSlideshow oldWidget) {
    super.didUpdateWidget(oldWidget);
    // التحكم في البدء والتوقف بناءً على حالة الصوت
    if (widget.isPlaying && !oldWidget.isPlaying) {
      _startSlideshow();
    } else if (!widget.isPlaying && oldWidget.isPlaying) {
      _stopSlideshow();
    }
  }

  void _startSlideshow() {
    _animController.forward(from: 0.0); // بدء الزووم
    _timer = Timer.periodic(const Duration(seconds: 15), (timer) {
      if (mounted) {
        setState(() {
          _currentIndex = (_currentIndex + 1) % _images.length;
        });
        _animController.forward(from: 0.0); // إعادة تشغيل الزووم للصورة الجديدة
      }
    });
  }

  void _stopSlideshow() {
    _timer?.cancel();
    _animController.stop(); // إيقاف الزووم في مكانه
  }

  @override
  void dispose() {
    _timer?.cancel();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // عرض صورة ثابتة أولى إذا لم يبدأ التشغيل
    if (!widget.isPlaying && _timer == null) {
      return Image.asset(
        _images[0],
        fit: BoxFit.cover,
      );
    }

    return AnimatedSwitcher(
      duration:
          const Duration(milliseconds: 1800), // مدة الانتقال الناعم (Crossfade)
      child: SizedBox(
        key: ValueKey<int>(_currentIndex), // مفتاح لتغيير الصورة
        height: double.infinity,
        width: double.infinity,
        child: AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: child,
            );
          },
          child: Image.asset(
            _images[_currentIndex],
            fit: BoxFit.cover,
            errorBuilder: (c, o, s) =>
                Container(color: Colors.grey), // لون احتياطي
          ),
        ),
      ),
    );
  }
}
