import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Stitch Exact Cyberpunk & Tactical Automotive Palette
  static const Color background = Color(0xFF07080B);
  static const Color surfaceLowest = Color(0xFF0D0E11);
  static const Color surfaceLow = Color(0xFF1A1B1F);
  static const Color surface = Color(0xFF121317);
  static const Color surfaceContainer = Color(0xFF1E1F23);
  static const Color surfaceHigh = Color(0xFF292A2D);
  static const Color surfaceHighest = Color(0xFF343538);
  static const Color border = Color(0xFF282C3C);
  static const Color borderLight = Color(0x1FFFFFFF);

  // High-Voltage Tactical Accents
  static const Color primaryMint = Color(0xFF00F59B);
  static const Color hudAmber = Color(0xFFFF9F0A);
  static const Color hudCrimson = Color(0xFFFF2D55);
  static const Color hudCyan = Color(0xFF00E5FF);

  // Backward compatibility aliases
  static const Color safeGreen = primaryMint;
  static const Color warningAmber = hudAmber;
  static const Color dangerRed = hudCrimson;
  static const Color accentCyan = hudCyan;
  static const Color surfaceElevated = surfaceHigh;
  static const Color surfaceMid = surfaceContainer;
  static const Color cyan = hudCyan;
  static const Color accentAmber = hudAmber;
  static const Color dangerCrimson = hudCrimson;

  // Text
  static const Color textPrimary = Color(0xFFE3E2E6);
  static const Color textSecondary = Color(0xFFB9CBBD);
  static const Color textMuted = Color(0xFF849588);

  static TextStyle get telemetryDigits => GoogleFonts.jetBrainsMono(
        fontWeight: FontWeight.w800,
        color: textPrimary,
      );

  static TextStyle get telemetryNumber => telemetryDigits;

  static TextStyle get telemetryUnit => GoogleFonts.jetBrainsMono(
        fontWeight: FontWeight.w700,
        color: textSecondary,
      );

  static TextStyle get headlineMedium => GoogleFonts.inter(
        fontWeight: FontWeight.w800,
        color: textPrimary,
      );

  static TextStyle get bodyMedium => GoogleFonts.inter(
        fontWeight: FontWeight.w500,
        color: textPrimary,
      );

  static TextStyle get bodySmall => GoogleFonts.inter(
        fontWeight: FontWeight.w400,
        color: textSecondary,
      );

  static TextStyle get labelCaps => GoogleFonts.jetBrainsMono(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
        color: textSecondary,
      );

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      primaryColor: primaryMint,
      colorScheme: const ColorScheme.dark(
        primary: primaryMint,
        secondary: hudAmber,
        error: hudCrimson,
        surface: surface,
      ),
      textTheme: GoogleFonts.interTextTheme(
        ThemeData.dark().textTheme,
      ).apply(
        bodyColor: textPrimary,
        displayColor: textPrimary,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: surfaceLowest,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
        ),
      ),
      cardTheme: CardThemeData(
        color: surfaceLowest,
        elevation: 0,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: borderLight, width: 1),
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
}
