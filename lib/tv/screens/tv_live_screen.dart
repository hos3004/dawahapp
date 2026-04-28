import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../design/tv_theme.dart';
import '../screens/tv_player_screen.dart';
import '../../data/models/program_guide_item.dart';

const String _liveStreamUrl = 'https://live.daawah.tv/hls/stream.m3u8';
const String _guideUrl = 'https://daawah.tv/app/prog.json';

/// شاشة البث المباشر للتلفزيون - تشغيل مباشر مع نافذة جدول اختيارية
class TvLiveScreen extends StatefulWidget {
  const TvLiveScreen({super.key});

  @override
  State<TvLiveScreen> createState() => _TvLiveScreenState();
}

class _TvLiveScreenState extends State<TvLiveScreen> {
  List<ProgramGuideItem> _guide = [];
  bool _isLoadingGuide = true;

  @override
  void initState() {
    super.initState();
    _fetchGuide();
  }

  Future<void> _fetchGuide() async {
    try {
      final response = await http.get(
        Uri.parse(_guideUrl),
        headers: {'Cache-Control': 'no-cache'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            _guide = data
                .map((e) =>
                    ProgramGuideItem.fromJson(e as Map<String, dynamic>))
                .toList();
            _isLoadingGuide = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoadingGuide = false);
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingGuide = false);
    }
  }

  Future<void> _showGuideDialog() async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: TvTheme.surface.withValues(alpha: 0.96),
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 96, vertical: 56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(
              color: TvTheme.focusBorder,
              width: 1.2,
            ),
          ),
          child: SizedBox(
            width: 620,
            child: Padding(
              padding: const EdgeInsets.all(TvTheme.paddingM),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_today_rounded,
                        color: TvTheme.accent,
                        size: 22,
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'جدول البرامج',
                          style: TextStyle(
                            color: TvTheme.onBackground,
                            fontSize: TvTheme.fontSizeSubtitle,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () => Navigator.of(dialogContext).pop(),
                        icon: const Icon(Icons.close),
                        label: const Text('إغلاق'),
                      ),
                    ],
                  ),
                  const SizedBox(height: TvTheme.paddingM),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 440),
                    child: _buildGuideDialogBody(),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildGuideDialogBody() {
    if (_isLoadingGuide) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: TvTheme.paddingXL),
          child: CircularProgressIndicator(color: TvTheme.accent),
        ),
      );
    }

    if (_guide.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: TvTheme.paddingXL),
        child: Center(
          child: Text(
            'الجدول غير متاح حالياً',
            style: TextStyle(
              color: TvTheme.onSurfaceMuted,
              fontSize: TvTheme.fontSizeBody,
            ),
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      itemCount: _guide.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final item = _guide[index];
        final isNow = _isCurrentlyAiring(item);
        return Container(
          padding: const EdgeInsets.symmetric(
            horizontal: TvTheme.paddingM,
            vertical: 16,
          ),
          decoration: BoxDecoration(
            color: isNow
                ? TvTheme.accent.withValues(alpha: 0.15)
                : TvTheme.background.withValues(alpha: 0.65),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isNow
                  ? TvTheme.accent
                  : TvTheme.surfaceVariant,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: TvTheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${item.from} - ${item.to}',
                  style: const TextStyle(
                    color: TvTheme.onBackground,
                    fontSize: TvTheme.fontSizeCaption,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              if (isNow) ...[
                Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: Text(
                  item.program,
                  style: TextStyle(
                    color: isNow
                        ? TvTheme.onBackground
                        : TvTheme.onSurface,
                    fontSize: TvTheme.fontSizeBody,
                    fontWeight:
                        isNow ? FontWeight.bold : FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTopOverlay(BuildContext context) {
    return Positioned(
      top: 16,
      left: 16,
      child: SafeArea(
        child: Row(
          children: [
            FilledButton.tonalIcon(
              onPressed: _showGuideDialog,
              style: FilledButton.styleFrom(
                backgroundColor: Colors.black54,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              icon: const Icon(Icons.calendar_today_rounded, size: 18),
              label: const Text(
                'جدول البرامج',
                style: TextStyle(
                  fontSize: TvTheme.fontSizeCaption,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                color: Colors.black45,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: Colors.white24,
                ),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.live_tv_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                  SizedBox(width: 10),
                  Text(
                    'قناة دعوة',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: TvTheme.fontSizeCaption,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(width: 10),
                  _LiveBadge(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return TvPlayerScreen(
      url: _liveStreamUrl,
      title: 'البث المباشر – قناة دعوة',
      isLive: true,
      overlayBuilder: _buildTopOverlay,
    );
  }

  bool _isCurrentlyAiring(ProgramGuideItem item) {
    try {
      final now = TimeOfDay.now();
      final start = _parseTime(item.from);
      final end = _parseTime(item.to);
      if (start == null || end == null) return false;
      final nowMins = now.hour * 60 + now.minute;
      final startMins = start.hour * 60 + start.minute;
      final endMins = end.hour * 60 + end.minute;
      return nowMins >= startMins && nowMins < endMins;
    } catch (_) {
      return false;
    }
  }

  TimeOfDay? _parseTime(String time) {
    final parts = time.split(':');
    if (parts.length < 2) return null;
    return TimeOfDay(
      hour: int.tryParse(parts[0]) ?? 0,
      minute: int.tryParse(parts[1]) ?? 0,
    );
  }
}

class _LiveBadge extends StatelessWidget {
  const _LiveBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.red,
        borderRadius: BorderRadius.circular(999),
      ),
      child: const Text(
        'LIVE',
        style: TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}
