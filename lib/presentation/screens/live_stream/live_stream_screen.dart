import 'dart:convert';
import 'package:better_player_plus/better_player_plus.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:wakelock_plus/wakelock_plus.dart';
import '../../../data/models/program_guide_item.dart';
import '../../../data/models/episode_item.dart';

class LiveStreamScreen extends StatefulWidget {
  final int tabIndex;
  final int currentIndex;
  final bool isInTabView;

  const LiveStreamScreen({
    super.key,
    required this.tabIndex,
    required this.currentIndex,
    this.isInTabView = false,
  });

  @override
  State<LiveStreamScreen> createState() => LiveStreamScreenState();
}

class LiveStreamScreenState extends State<LiveStreamScreen>
    with AutomaticKeepAliveClientMixin {
  // GlobalKey for Picture-in-Picture (PIP)
  final GlobalKey _betterPlayerKey = GlobalKey();

  @override
  bool get wantKeepAlive => true;

  final String liveStreamUrl = "http://161.97.100.71/hls/stream.m3u8";

  BetterPlayerController? _betterPlayerController;

  bool _isLoading = true;
  String? _error;

  late Future<List<ProgramGuideItem>> _guideFuture;
  final String _guideUrl = "https://daawah.tv/app/prog.json";

  @override
  void initState() {
    super.initState();
    print("LiveStreamScreen: initState");
    _guideFuture = _fetchProgramGuide();
    _initializePlayer();

    // --- 🔴 2. قم بإضافة هذا السطر لتفعيل منع الإغلاق ---
    WakelockPlus.enable();
  }

  Future<void> _initializePlayer() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      BetterPlayerControlsConfiguration controlsConfiguration =
      const BetterPlayerControlsConfiguration(
        enablePip: true,
        pipMenuIcon: Icons.picture_in_picture_alt,
        enableFullscreen: true,
        enableMute: true,
        enablePlayPause: true,
        enableProgressText: true,
        liveTextColor: Colors.red,
        showControlsOnInitialize: true,
        enableSkips: false,
        enablePlaybackSpeed: false,
        enableSubtitles: false,
        enableQualities: true,

      );

      BetterPlayerConfiguration betterPlayerConfiguration =
      BetterPlayerConfiguration(
        aspectRatio: 16 / 9,
        fit: BoxFit.contain,
        autoPlay: true,
        looping: false,
        allowedScreenSleep: false, // نبقي هذا السطر أيضاً كاحتياط
        controlsConfiguration: controlsConfiguration,
      );

      _betterPlayerController =
          BetterPlayerController(betterPlayerConfiguration);

      BetterPlayerDataSource dataSource = BetterPlayerDataSource(
        BetterPlayerDataSourceType.network,
        liveStreamUrl,
        liveStream: true,
      );
      _betterPlayerController!.setBetterPlayerGlobalKey(_betterPlayerKey);

      await _betterPlayerController!.setupDataSource(dataSource);

      setState(() {
        _isLoading = false;
      });

      _checkPlaybackState();
    } catch (e) {
      print("Error initializing BetterPlayer: $e");
      setState(() {
        _isLoading = false;
        _error = "لا يمكن تحميل البث المباشر.";
      });
    }
  }

  Future<List<ProgramGuideItem>> _fetchProgramGuide() async {
    try {
      final response = await http.get(Uri.parse(_guideUrl));
      if (response.statusCode == 200) {
        final List<dynamic> jsonData =
        jsonDecode(utf8.decode(response.bodyBytes));
        return jsonData
            .map((item) => ProgramGuideItem.fromJson(item))
            .toList();
      } else {
        throw Exception(
            'Failed to load program guide (Status ${response.statusCode})');
      }
    } catch (e) {
      print("Error fetching program guide: $e");
      throw Exception('Failed to load program guide: $e');
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  @override
  void didUpdateWidget(covariant LiveStreamScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.isInTabView && widget.currentIndex != oldWidget.currentIndex) {
      _checkPlaybackState();
    }
  }

  void _checkPlaybackState() {
    if (!mounted || _betterPlayerController == null) return;

    bool shouldPlay = (widget.currentIndex == widget.tabIndex);
    print(
        "LiveStreamScreen (BottomNav): Check State - Current Index: ${widget.currentIndex}, TabIndex: ${widget.tabIndex}, ShouldPlay: $shouldPlay");

    if (shouldPlay) {
      if (_betterPlayerController!.isVideoInitialized() == true &&
          _betterPlayerController!.isPlaying() == false) {
        _betterPlayerController!.play();
      }
    } else {
      if (_betterPlayerController!.isVideoInitialized() == true &&
          _betterPlayerController!.isPlaying() == true) {
        _betterPlayerController!.pause();
      }
    }
  }

  void publicPause() {
    if (_betterPlayerController != null &&
        _betterPlayerController!.isVideoInitialized() == true &&
        _betterPlayerController!.isPlaying() == true) {
      _betterPlayerController?.pause();
    }
  }

  void publicCheckPlaybackState() {
    _checkPlaybackState();
  }

  void setStateIfMounted(VoidCallback fn) {
    if (mounted) {
      setState(fn);
    }
  }

  @override
  void dispose() {
    print("LiveStreamScreen: dispose");
    _betterPlayerController?.dispose();

    // --- 🔴 3. قم بإضافة هذا السطر لإلغاء تفعيل منع الإغلاق ---
    WakelockPlus.disable();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return _buildFullScreenLayout();
  }

  Widget _buildFullScreenLayout() {
    final scaffoldBackgroundColor = Colors.grey[100];
    return Scaffold(
      backgroundColor: scaffoldBackgroundColor,
      body: Stack(
        children: [
          _buildPlayerHeader(),
          DraggableScrollableSheet(
            initialChildSize: 0.35,
            minChildSize: 0.35,
            maxChildSize: 0.9,
            builder: (context, scrollController) {
              return Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                  BorderRadius.vertical(top: Radius.circular(24.0)),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black12,
                        blurRadius: 10,
                        offset: Offset(0, -5)),
                  ],
                ),
                child: ClipRRect(
                  borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(24.0)),
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.all(20.0),
                    children: [
                      _buildDragHandle(),
                      _buildInfoPanelContent(context),
                    ],
                  ),
                ),
              );
            },
          ),
          _buildBackButton(),
        ],
      ),
    );
  }

  Widget _buildPlayerHeader() {
    final screenHeight = MediaQuery.of(context).size.height;
    return Container(
      height: screenHeight * 0.65,
      width: double.infinity,
      color: Colors.black,
      child: _buildPlayerWidget(),
    );
  }

  Widget _buildPlayerWidget() {
    if (_isLoading) {
      print("Building Player Widget: Loading State");
      return const Center(child: CircularProgressIndicator(color: Colors.white));
    }
    if (_error != null) {
      print("Building Player Widget: Error State - $_error");
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Text(_error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70)),
        ),
      );
    }
    if (_betterPlayerController != null) {
      print(
          "Building Player Widget: Success State - BetterPlayer Controller Ready");
      return AspectRatio(
        aspectRatio: 16 / 9,
        child: BetterPlayer(
            key: _betterPlayerKey,controller: _betterPlayerController!),
      );
    }

    print("Building Player Widget: Fallback State - Player not available");
    return const Center(
        child: Text("Player not available.",
            style: TextStyle(color: Colors.white70)));
  }

  Widget _buildBackButton() {
    return Positioned(
      top: 40,
      left: 16,
      child: SafeArea(
        child: CircleAvatar(
          backgroundColor: Colors.black.withOpacity(0.5),
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pushReplacementNamed(context, '/home'),
          ),
        ),
      ),
    );
  }

  Widget _buildDragHandle() {
    return Center(
      child: Container(
        width: 40,
        height: 4,
        margin: const EdgeInsets.only(bottom: 16.0),
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Widget _buildInfoPanelContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "البث المباشر",
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            IconButton(
              icon: Icon(Icons.favorite_border,
                  color: Colors.red[400], size: 28),
              onPressed: () {},
            ),
          ],
        ),
        const SizedBox(height: 8),
        _buildInfoChip(context, Icons.tv_rounded, "قناة دعوة الفضائية"),
        _buildInfoChip(context, Icons.access_time_rounded, "مستمر 24/7"),
        const Divider(height: 32),
        Text(
          "خريطة البرامج:",
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        FutureBuilder<List<ProgramGuideItem>>(
          future: _guideFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(
                child: Text(
                  "خطأ في تحميل الجدول: ${snapshot.error}",
                  style: const TextStyle(color: Colors.red),
                ),
              );
            }
            if (snapshot.hasData && snapshot.data!.isNotEmpty) {
              return _buildProgramGuideTable(snapshot.data!);
            }
            return const Center(child: Text("لا توجد بيانات لعرضها."));
          },
        ),
      ],
    );
  }

  Widget _buildProgramGuideTable(List<ProgramGuideItem> items) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          _buildGuideRow(
            from: "من",
            to: "الى",
            program: "البرنامج",
            isHeader: true,
          ),
          ...items.map((item) {
            return _buildGuideRow(
              from: item.from,
              to: item.to,
              program: item.program,
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildGuideRow({
    required String from,
    required String to,
    required String program,
    bool isHeader = false,
  }) {
    final style = TextStyle(
      fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
      fontSize: 13,
      color: Colors.black87,
    );
    final padding = const EdgeInsets.symmetric(horizontal: 8.0, vertical: 10.0);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      decoration: BoxDecoration(
        color: isHeader ? Colors.grey.shade100 : Colors.transparent,
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.shade200,
            width: 1.0,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 5,
            child: Padding(
              padding: padding,
              child: Text(program, style: style, textAlign: TextAlign.right),
            ),
          ),
          Expanded(
            flex: 2,
            child: Padding(
              padding: padding,
              child: Text(to, style: style, textAlign: TextAlign.center),
            ),
          ),
          Expanded(
            flex: 2,
            child: Padding(
              padding: padding,
              child: Text(from, style: style, textAlign: TextAlign.center),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(BuildContext context, IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey[600], size: 18),
          const SizedBox(width: 8),
          Text(
            text,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[800],
            ),
          ),
        ],
      ),
    );
  }


  Future<void> _enablePip() async {
    if (_betterPlayerController != null) {
      try {
        await _betterPlayerController!.enablePictureInPicture(_betterPlayerKey);
      } catch (e) {
        debugPrint("PIP enable failed: $e");
      }
    }
  }
}