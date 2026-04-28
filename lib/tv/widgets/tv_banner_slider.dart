import 'dart:async';
import 'package:flutter/material.dart';
import '../../data/models/program_item.dart';
import '../design/tv_theme.dart';
import '../focus/tv_focus_manager.dart';

/// بانر تلقائي الانزلاق للتلفزيون
class TvBannerSlider extends StatefulWidget {
  final List<ProgramItem> items;
  final ValueChanged<ProgramItem>? onItemTap;
  final ValueChanged<ProgramItem>? onItemFocus;
  final Duration autoPlayDuration;

  const TvBannerSlider({
    super.key,
    required this.items,
    this.onItemTap,
    this.onItemFocus,
    this.autoPlayDuration = const Duration(seconds: 4),
  });

  @override
  State<TvBannerSlider> createState() => _TvBannerSliderState();
}

class _TvBannerSliderState extends State<TvBannerSlider> {
  final PageController _controller = PageController();
  Timer? _timer;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    if (widget.items.length > 1) {
      _startAutoPlay();
    }
  }

  void _startAutoPlay() {
    _timer = Timer.periodic(widget.autoPlayDuration, (_) {
      if (!mounted) return;
      final next = (_currentPage + 1) % widget.items.length;
      _controller.animateToPage(
        next,
        duration: TvTheme.animSlow,
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 340,
      child: Stack(
        children: [
          // الصور
          PageView.builder(
            controller: _controller,
            itemCount: widget.items.length,
            onPageChanged: (i) => setState(() => _currentPage = i),
            itemBuilder: (context, index) {
              final item = widget.items[index];
              return TvFocusable(
                onSelect: () => widget.onItemTap?.call(item),
                onFocusGained: () => widget.onItemFocus?.call(item),
                focusScale: 1.02,
                borderRadius: BorderRadius.circular(16),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (item.image != null && item.image!.isNotEmpty)
                        Image.network(
                          item.image!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: TvTheme.surface,
                          ),
                        )
                      else
                        Container(color: TvTheme.surface),

                      // تدرج
                      Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black87,
                            ],
                          ),
                        ),
                      ),

                      // النص
                      Positioned(
                        bottom: TvTheme.paddingM,
                        right: TvTheme.paddingM,
                        left: TvTheme.paddingM,
                        child: Text(
                          item.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: TvTheme.fontSizeHeadline,
                            fontWeight: FontWeight.bold,
                            shadows: [
                              Shadow(
                                color: Colors.black,
                                blurRadius: 8,
                              )
                            ],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          // مؤشرات
          if (widget.items.length > 1)
            Positioned(
              bottom: TvTheme.paddingS,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  widget.items.length,
                  (i) => AnimatedContainer(
                    duration: TvTheme.animFast,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: _currentPage == i ? 20 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _currentPage == i
                          ? TvTheme.accent
                          : TvTheme.onSurfaceMuted,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
