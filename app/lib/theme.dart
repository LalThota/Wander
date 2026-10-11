import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Design tokens. Change kPrimary to re-colour the whole app.
const kPrimary = Color(0xFF14AAF5);
const kPrimarySoft = Color(0xFFE6F6FE);
const kInk = Color(0xFF1B1F2A);
const kMuted = Color(0xFF8A90A0);
const kLine = Color(0xFFEDEFF3);
const kPanel = Color(0xFFF5F6F9);
const kStar = Color(0xFFFFB400);
const kGood = Color(0xFF2FBF71);
const kWarn = Color(0xFFF5A524);
const kBad = Color(0xFFF04F5F);

List<BoxShadow> softShadow([double opacity = 0.07]) => [
      BoxShadow(
        color: Colors.black.withAlpha((opacity * 255).round()),
        blurRadius: 24,
        offset: const Offset(0, 8),
      ),
    ];

/// White rounded card with a soft shadow, used across the app.
BoxDecoration cardDecoration({double radius = 24}) => BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: kLine),
      boxShadow: softShadow(),
    );

ThemeData buildTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: kPrimary,
    brightness: Brightness.light,
  ).copyWith(primary: kPrimary, onPrimary: Colors.white, surface: Colors.white);

  final text = GoogleFonts.plusJakartaSansTextTheme(ThemeData.light().textTheme)
      .apply(bodyColor: kInk, displayColor: kInk);

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: Colors.white,
    textTheme: text,
    dividerColor: kLine,
    snackBarTheme: const SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: kInk,
      contentTextStyle: TextStyle(color: Colors.white),
    ),
    sliderTheme: const SliderThemeData(
      activeTrackColor: kPrimary,
      thumbColor: kPrimary,
      inactiveTrackColor: kLine,
    ),
  );
}
