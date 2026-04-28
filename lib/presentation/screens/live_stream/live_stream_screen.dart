import 'dart:convert';

import 'package:better_player_plus/better_player_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../../data/models/program_guide_item.dart';

class LiveStreamScreen extends StatefulWidget {
  final int tabIndex;
  final ValueNotifier<int> tabNotifier;
  final bool isInTabView;

  const LiveStreamScreen({
    super.key,
    required this.tabIndex,
    required this.tabNotifier,
    this.isInTabView = false,
  });

  @override
  State<LiveStreamScreen> createState() => LiveStreamScreenState();
}

class LiveStreamScreenState extends State<LiveStreamScreen>
    with AutomaticKeepAliveClientMixin {
  final GlobalKey _betterPlayerKey = GlobalKey();

  @override
  bool get wantKeepAlive => true;

  final String liveStreamUrl = 'https://live.daawah.tv/hls/stream.m3u8';
  final String _guideUrl = 'https://daawah.tv/app/prog.json';

  BetterPlayerController? _betterPlayerController;
  late Future<List<ProgramGuideItem>> _guideFuture;

  bool _isLoading = true;
  bool _isRefreshing = false;
  String? _error;
  bool _manualFullscreen = false;

  final Color _primaryBlue = const Color(0xFF155CB0);
  final Color _accentRed = const Color(0xFFFF4D4D);

  @override
  void initState() {
    super.initState();
    _guideFuture = _fetchProgramGuide();
    _initializePlayer();
    widget.tabNotifier.addListener(_checkPlaybackState);
  }

  Future<void> _initializePlayer({bool isRefresh = false}) async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _error = null;
      if (isRefresh) {
        _isRefreshing = true;
      }
    });

    try {
      final oldController = _betterPlayerController;
      _betterPlayerController = null;
      oldController?.dispose();

      const controlsConfiguration = BetterPlayerControlsConfiguration(
        enablePip: true,
        pipMenuIcon: Icons.picture_in_picture_alt,
        enableFullscreen: true,
        enableMute: true,
        enablePlayPause: true,
        enableProgressText: false,
        liveTextColor: Colors.red,
        showControlsOnInitialize: true,
        enableSkips: false,
        enablePlaybackSpeed: false,
        enableSubtitles: false,
        enableQualities: true,
        controlBarColor: Colors.black54,
        iconsColor: Colors.white,
      );

      final betterPlayerConfiguration = BetterPlayerConfiguration(
        aspectRatio: 16 / 9,
        fit: BoxFit.contain,
        autoPlay: true,
        looping: false,
        allowedScreenSleep: false,
        expandToFill: true,
        autoDetectFullscreenDeviceOrientation: true,
        autoDetectFullscreenAspectRatio: true,
        deviceOrientationsOnFullScreen: const [
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ],
        deviceOrientationsAfterFullScreen: const [
          DeviceOrientation.portraitUp,
        ],
        controlsConfiguration: controlsConfiguration,
      );

      final controller = BetterPlayerController(betterPlayerConfiguration);
      controller.setBetterPlayerGlobalKey(_betterPlayerKey);

      final dataSource = BetterPlayerDataSource(
        BetterPlayerDataSourceType.network,
        liveStreamUrl,
        liveStream: true,
        notificationConfiguration: const BetterPlayerNotificationConfiguration(
          showNotification: false,
          title: 'قناة دعوة الفضائية',
          author: 'بث مباشر',
        ),
      );

      await controller.setupDataSource(dataSource);

      if (!mounted) {
        controller.dispose();
        return;
      }

      _betterPlayerController = controller;

      setState(() {
        _isLoading = false;
        _isRefreshing = false;
      });

      _checkPlaybackState();
      WakelockPlus.enable();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _isRefreshing = false;
        if (kIsWeb) {
          _error =
              'لا يمكن تحميل البث المباشر. قد يكون السبب قيود المتصفح أو CORS.';
        } else {
          _error = 'لا يمكن تحميل البث المباشر الآن. جرّب التحديث اليدوي.';
        }
      });
    }
  }

  Future<List<ProgramGuideItem>> _fetchProgramGuide() async {
    try {
      final response = await http.get(Uri.parse(_guideUrl));
      if (response.statusCode == 200) {
        final List<dynamic> jsonData =
            jsonDecode(utf8.decode(response.bodyBytes)) as List<dynamic>;
        return jsonData.map((item) => ProgramGuideItem.fromJson(item)).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  void _checkPlaybackState() {
    if (!mounted || _betterPlayerController == null) return;

    final shouldPlay = widget.tabNotifier.value == widget.tabIndex;

    try {
      final isInitialized =
          _betterPlayerController!.isVideoInitialized() == true;
      final isPlaying = _betterPlayerController!.isPlaying() == true;

      if (shouldPlay) {
        if (isInitialized && !isPlaying) {
          _betterPlayerController!.play();
        }
      } else {
        if (isInitialized && isPlaying) {
          _betterPlayerController!.pause();
        }
      }
    } catch (_) {
      // نتجنب أي crash من استدعاءات حالة المشغل
    }
  }

  Future<void> _refreshStream() async {
    await _initializePlayer(isRefresh: true);
  }

  @override
  void dispose() {
    widget.tabNotifier.removeListener(_checkPlaybackState);
    _betterPlayerController?.dispose();
    WakelockPlus.disable();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    if (isLandscape || _manualFullscreen) {
      return _buildFullscreenPlayer();
    }

    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/bbg.jpg'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                _buildTopHeader(context),
                _buildBlueInfoBar(),
                Expanded(
                  child: Container(
                    color: Colors.white,
                    child: Column(
                      children: [
                        AspectRatio(
                          aspectRatio: 16 / 9,
                          child: Container(
                            color: Colors.black,
                            child: _buildPlayerWidget(),
                          ),
                        ),
                        Expanded(
                          child: SingleChildScrollView(
                            physics: const BouncingScrollPhysics(),
                            child: Column(
                              children: [
                                const SizedBox(height: 16),
                                _buildMainTitleSection(),
                                const SizedBox(height: 16),
                                _buildPillsSection(),
                                const SizedBox(height: 20),
                                _buildProgramGuideSection(),
                                const SizedBox(height: 30),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopHeader(BuildContext context) {
    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      child: Center(
        child: Image.asset(
          'assets/images/logo.png',
          height: 44,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.nightlight_round, size: 30, color: _primaryBlue),
              Text(
                'قناة دعوة',
                style: TextStyle(
                  color: _primaryBlue,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBlueInfoBar() {
    return Container(
      width: double.infinity,
      color: _primaryBlue,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'تابعوا البث الحي بث مباشر 7/24',
              style: TextStyle(color: Colors.white, fontSize: 13),
              textAlign: TextAlign.right,
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: _accentRed,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              children: [
                Icon(Icons.circle, color: Colors.white, size: 8),
                SizedBox(width: 6),
                Text(
                  'مباشر',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainTitleSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 4,
              children: [
                const Text(
                  'البث المباشر',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const Text(
                  'إذا توقف البث اضغط تحديث',
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                _isRefreshing
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : IconButton(
                        onPressed: _refreshStream,
                        icon: const Icon(Icons.refresh, color: Colors.blue),
                        tooltip: 'تحديث البث',
                      ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.favorite_border, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildPillsSection() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      reverse: false,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _buildPill(Icons.tv, 'قناة دعوة الفضائية'),
          const SizedBox(width: 8),
          _buildPill(Icons.access_time, 'مستمر 24/7'),
          const SizedBox(width: 8),
          _buildPill(Icons.hd, 'جودة تلقائية'),
        ],
      ),
    );
  }

  Widget _buildPill(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F0F0),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Text(
            text,
            style: const TextStyle(
              color: Colors.black54,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 6),
          Icon(icon, size: 16, color: Colors.black45),
        ],
      ),
    );
  }

  Widget _buildProgramGuideSection() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              const Text(
                'خريطة البرامج',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _accentRed,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        FutureBuilder<List<ProgramGuideItem>>(
          future: _guideFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError ||
                !snapshot.hasData ||
                snapshot.data!.isEmpty) {
              return Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Text('لا توجد بيانات متاحة حالياً'),
              );
            }

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                return _buildGuideItem(snapshot.data![index]);
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildGuideItem(ProgramGuideItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Text(
                  item.from,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  item.to,
                  style: const TextStyle(
                    fontWeight: FontWeight.normal,
                    fontSize: 11,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              item.program,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_left, color: Colors.grey),
        ],
      ),
    );
  }

  Widget _buildPlayerWidget() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: _refreshStream,
                icon: const Icon(Icons.refresh),
                label: const Text('إعادة المحاولة'),
              ),
            ],
          ),
        ),
      );
    }

    if (_betterPlayerController != null) {
      return BetterPlayer(
        key: _betterPlayerKey,
        controller: _betterPlayerController!,
      );
    }

    return const SizedBox();
  }

  Widget _buildFullscreenPlayer() {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(child: _buildPlayerWidget()),
    );
  }
}
