import 'package:flutter/material.dart';
import '../../data/models/genre_data.dart';

class GenreCard extends StatelessWidget {
  final GenreData genre;
  final VoidCallback onTap;
  final int? index;

  const GenreCard({
    super.key,
    required this.genre,
    required this.onTap,
    this.index,
  });

  static const List<Color> _palette = <Color>[
    Color(0xFF1E88E5), // أزرق داكن
    Color(0xFF43A047), // أخضر
    Color(0xFFFFB300), // ذهبي
    Color(0xFF8E24AA), // بنفسجي
    Color(0xFF039BE5), // أزرق سماوي
    Color(0xFFF4511E), // برتقالي محمر
    Color(0xFF3949AB), // أزرق بنفسجي
    Color(0xFF00897B), // تركوازي غامق
  ];

  @override
  Widget build(BuildContext context) {
    final int i = (index ?? 0);
    final Color base = _palette[i % _palette.length];

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: base,
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // الدائرة الخلفية الفاتحة لإضافة عمق بصري
            Positioned(
              top: -28,
              right: -28,
              child: _softCircle(110, Colors.white.withOpacity(0.12)),
            ),
            Positioned(
              bottom: -22,
              left: -22,
              child: _softCircle(84, Colors.white.withOpacity(0.07)),
            ),
            // المحتوى: أيقونة الهلال + اسم التصنيف
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // أيقونة الهلال بخط فلات (بدون صورة)
                    Icon(
                      Icons.nightlight_round, // شكل الهلال (Line Flat)
                      color: Colors.white,
                      size: 38,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      genre.name ?? '',
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 15.5,
                        height: 1.25,
                        shadows: [
                          Shadow(color: Colors.black54, blurRadius: 2),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _softCircle(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}
