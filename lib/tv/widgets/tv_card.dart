import 'package:flutter/material.dart';
import '../../data/models/program_item.dart';
import '../design/tv_theme.dart';
import '../focus/tv_focus_manager.dart';

/// بطاقة برنامج للتلفزيون (240x360)
class TvCard extends StatelessWidget {
  final ProgramItem item;
  final VoidCallback? onTap;
  final VoidCallback? onFocus;
  final bool autofocus;
  final FocusNode? focusNode;

  const TvCard({
    super.key,
    required this.item,
    this.onTap,
    this.onFocus,
    this.autofocus = false,
    this.focusNode,
  });

  @override
  Widget build(BuildContext context) {
    return TvFocusable(
      autofocus: autofocus,
      focusNode: focusNode,
      focusScale: 1.08,
      borderRadius: BorderRadius.circular(TvTheme.cardBorderRadius),
      onSelect: onTap,
      onFocusGained: onFocus,
      child: SizedBox(
        width: TvTheme.cardWidth,
        height: TvTheme.cardHeight,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(TvTheme.cardBorderRadius),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // صورة الغلاف
              item.image != null && item.image!.isNotEmpty
                  ? Image.network(
                      item.image!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _placeholderWidget(),
                      loadingBuilder: (_, child, progress) {
                        if (progress == null) return child;
                        return _shimmerWidget();
                      },
                    )
                  : _placeholderWidget(),

              // تدرج في الأسفل
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: 100,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.black87],
                    ),
                  ),
                ),
              ),

              // اسم البرنامج
              Positioned(
                bottom: 12,
                left: 8,
                right: 8,
                child: Text(
                  item.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: TvTheme.fontSizeCaption,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _placeholderWidget() {
    return Container(
      color: TvTheme.surfaceVariant,
      child: const Center(
        child: Icon(Icons.movie, color: TvTheme.onSurfaceMuted, size: 48),
      ),
    );
  }

  Widget _shimmerWidget() {
    return Container(
      color: TvTheme.surface,
      child: const Center(
        child: CircularProgressIndicator(
          color: TvTheme.accent,
          strokeWidth: 2,
        ),
      ),
    );
  }
}
