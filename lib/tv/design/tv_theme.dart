import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// ثيم خاص بإصدار التلفزيون - 10-foot UI
class TvTheme {
  TvTheme._();

  // ─── الألوان ────────────────────────────────────────────────
  static const Color background = Color(0xFF0D1117);
  static const Color surface = Color(0xFF161B22);
  static const Color surfaceVariant = Color(0xFF21262D);
  static const Color accent = Color(0xFF2576DF);
  static const Color accentLight = Color(0xFF4A9EFF);
  static const Color accentRed = Color(0xFFFF4D4D);
  static const Color onBackground = Colors.white;
  static const Color onSurface = Color(0xFFE6EDF3);
  static const Color onSurfaceMuted = Color(0xFF8B949E);
  static const Color focusBorder = Color(0xFFE6EDF3); // أبيض مائل للزرقة لزيادة التباين
  static const Color focused = Color(0xFF1F6FEB);
  static const Color focusGlow = Color(0x664A9EFF); // توهج ناعم أزرق (alpha 40%)

  // ─── أبعاد ──────────────────────────────────────────────────
  static const double cardWidth = 150.0;
  static const double cardHeight = 225.0;
  static const double cardBorderRadius = 12.0;
  static const double sidebarWidth = 220.0;
  static const double sidebarCollapsedWidth = 64.0;
  static const double focusBorderWidth = 3.0;

  // ─── مسافات ─────────────────────────────────────────────────
  static const double paddingS = 12.0;
  static const double paddingM = 24.0;
  static const double paddingL = 40.0;
  static const double paddingXL = 56.0;

  // ─── حجم الخطوط (10-foot UI) ────────────────────────────────
  static const double fontSizeTitle = 34.0;
  static const double fontSizeHeadline = 28.0;
  static const double fontSizeSubtitle = 22.0;
  static const double fontSizeBody = 20.0;
  static const double fontSizeCaption = 16.0;
  static const double fontSizeSmall = 14.0;

  // ─── مدة الانيميشن ──────────────────────────────────────────
  static const Duration animFast = Duration(milliseconds: 150);
  static const Duration animNormal = Duration(milliseconds: 250);
  static const Duration animSlow = Duration(milliseconds: 400);

  // ─── ThemeData ───────────────────────────────────────────────
  static ThemeData get themeData {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      colorScheme: const ColorScheme.dark(
        surface: surface,
        primary: accent,
        secondary: accentLight,
        onSurface: onSurface,
        onPrimary: Colors.white,
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(cardBorderRadius),
        ),
      ),
      iconTheme: const IconThemeData(color: onSurface, size: 28),
    );

    return base.copyWith(
      textTheme: GoogleFonts.tajawalTextTheme(base.textTheme).copyWith(
        displayLarge: GoogleFonts.tajawal(
          fontSize: fontSizeTitle,
          fontWeight: FontWeight.bold,
          color: onBackground,
        ),
        headlineMedium: GoogleFonts.tajawal(
          fontSize: fontSizeHeadline,
          fontWeight: FontWeight.bold,
          color: onBackground,
        ),
        titleLarge: GoogleFonts.tajawal(
          fontSize: fontSizeSubtitle,
          fontWeight: FontWeight.w600,
          color: onBackground,
        ),
        bodyLarge: GoogleFonts.tajawal(
          fontSize: fontSizeBody,
          color: onSurface,
        ),
        bodyMedium: GoogleFonts.tajawal(
          fontSize: fontSizeCaption,
          color: onSurfaceMuted,
        ),
        labelSmall: GoogleFonts.tajawal(
          fontSize: fontSizeSmall,
          color: onSurfaceMuted,
        ),
      ),
    );
  }
}
