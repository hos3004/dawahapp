import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../design/tv_theme.dart';

/// تأثير الخلفية السينمائية (Ambient Background)
/// يظهر صورة كبيرة مموهة ومتدرجة خلف المحتوى الأساسي
class TvAmbientBackground extends StatelessWidget {
  final String? imageUrl;
  final Widget child;

  const TvAmbientBackground({
    super.key,
    required this.imageUrl,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // الخلفية المتغيرة بالصور
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 800),
          switchInCurve: Curves.easeInOut,
          switchOutCurve: Curves.easeInOut,
          child: imageUrl != null && imageUrl!.isNotEmpty
              ? Container(
                  key: ValueKey<String>(imageUrl!),
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: CachedNetworkImageProvider(imageUrl!),
                      fit: BoxFit.cover,
                    ),
                  ),
                )
              : Container(
                  key: const ValueKey('default_bg'),
                  color: TvTheme.background,
                ),
        ),

        // تأثير التمويه والتعتيم الكثيف ليظل النص والمحتوى مقروءاً
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    TvTheme.background.withValues(alpha: 0.5),
                    TvTheme.background.withValues(alpha: 0.95),
                  ],
                  stops: const [0.0, 0.7],
                ),
              ),
            ),
          ),
        ),

        // المحتوى الفعلي للشاشة (القوائم والبطاقات)
        Positioned.fill(child: child),
      ],
    );
  }
}
