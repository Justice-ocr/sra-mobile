import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static ThemeData get darkTheme => _build(Brightness.dark);
  static ThemeData get lightTheme => _build(Brightness.light);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final primary = const Color(0xFF00C8D7);
    final bg = isDark ? const Color(0xFF050816) : const Color(0xFFF0F4FF);
    final surface = isDark ? const Color(0xFF0A0E27) : Colors.white;
    final cardColor = isDark ? const Color(0xFF0D1B3E) : Colors.white;
    final scheme = isDark
        ? ColorScheme.dark(primary: primary, secondary: const Color(0xFFFF006E), surface: surface, error: const Color(0xFFFF3366))
        : ColorScheme.light(primary: primary, secondary: const Color(0xFFFF006E), surface: surface, error: const Color(0xFFFF3366));

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: bg,
      textTheme: GoogleFonts.robotoTextTheme(isDark ? ThemeData.dark().textTheme : ThemeData.light().textTheme),
      cardTheme: CardTheme(
        elevation: 4,
        color: cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.06)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.04),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: isDark ? Colors.white.withOpacity(0.15) : Colors.black.withOpacity(0.12)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: primary, width: 1.5),
        ),
      ),
    );
  }
}
