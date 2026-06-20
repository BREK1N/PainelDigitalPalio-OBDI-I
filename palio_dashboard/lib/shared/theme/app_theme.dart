import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  AppTheme._();

  static const Color background = Color(0xFF0A0A0A);
  static const Color surface = Color(0xFF161616);
  static const Color accent = Color(0xFFFF6A00);
  static const Color danger = Color(0xFFE53935);
  static const Color gaugeIdle = Color(0xFF555555);
  static const Color gaugeNormal = Color(0xFF2ECC71);
  static const Color gaugeWarning = Color(0xFFF1C40F);
  static const Color gaugeDanger = Color(0xFFE53935);

  static ThemeData get dark {
    final base = ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: background,
      colorScheme: base.colorScheme.copyWith(
        primary: accent,
        surface: surface,
        error: danger,
      ),
      textTheme: GoogleFonts.rajdhaniTextTheme(base.textTheme).apply(
        bodyColor: Colors.white,
        displayColor: Colors.white,
      ),
    );
  }

  static TextStyle digitalDisplay({double fontSize = 48, Color? color}) =>
      GoogleFonts.orbitron(
        fontSize: fontSize,
        fontWeight: FontWeight.bold,
        color: color ?? Colors.white,
      );
}
