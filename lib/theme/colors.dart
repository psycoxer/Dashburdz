import 'package:flutter/material.dart';

/// Soft pastel color palette — lavender, sage, coral, sky blue.
///
/// Each color has a light and dark variant. Dark variants are slightly
/// brighter/more saturated to maintain visibility on dark backgrounds.
class AppColors {
  AppColors._();

  // ── Light Mode ──
  static const Color lightBackground = Color(0xFFF8F6F4);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceVariant = Color(0xFFF0EDE8);
  static const Color lightTextPrimary = Color(0xFF2D2D3A);
  static const Color lightTextSecondary = Color(0xFF6B687A);
  static const Color lightTextTertiary = Color(0xFF9896A8);
  static const Color lightDivider = Color(0xFFE2DED8);

  // ── Dark Mode ──
  static const Color darkBackground = Color(0xFF1A1A2E);
  static const Color darkSurface = Color(0xFF232342);
  static const Color darkSurfaceVariant = Color(0xFF2C2C4A);
  static const Color darkTextPrimary = Color(0xFFE8E6F0);
  static const Color darkTextSecondary = Color(0xFF9896A8);
  static const Color darkTextTertiary = Color(0xFF6B687A);
  static const Color darkDivider = Color(0xFF3A3858);

  // ── Accent Colors (shared, slight dark-mode boost) ──

  /// Lavender — primary accent, used for RPM gauge.
  static const Color lavender = Color(0xFFB8A9C9);
  static const Color lavenderLight = Color(0xFFD4C8E2);
  static const Color lavenderDark = Color(0xFF9B8BB4);
  static const Color lavenderMuted = Color(0x33B8A9C9);

  /// Sage green — secondary accent, used for speed and throttle.
  static const Color sage = Color(0xFFA8C5A0);
  static const Color sageLight = Color(0xFFC5DEC0);
  static const Color sageDark = Color(0xFF8FB387);
  static const Color sageMuted = Color(0x33A8C5A0);

  /// Coral — warm accent, used for temperature warnings and RPM redline.
  static const Color coral = Color(0xFFE8A598);
  static const Color coralLight = Color(0xFFF2C5BC);
  static const Color coralDark = Color(0xFFD4917A);
  static const Color coralMuted = Color(0x33E8A598);

  /// Sky blue — cool accent, used for intake air temp and info.
  static const Color skyBlue = Color(0xFF9CC5D8);
  static const Color skyBlueLight = Color(0xFFBFDBE8);
  static const Color skyBlueDark = Color(0xFF7FB3C8);
  static const Color skyBlueMuted = Color(0x339CC5D8);

  // ── Semantic Colors ──
  static const Color success = sage;
  static const Color warning = Color(0xFFE8C598);
  static const Color error = coral;
  static const Color info = skyBlue;

  // ── Gauge Gradients ──

  /// RPM gauge gradient: lavender (low) → coral (high/redline).
  static const List<Color> rpmGradient = [lavender, coral];

  /// EngineOil temp gradient: sky blue (cold) → coral (hot).
  static const List<Color> tempGradient = [skyBlue, coral];

  /// Throttle gradient: sage (low) → sage (high), uniform green.
  static const List<Color> throttleGradient = [sageMuted, sage];

  /// Speed gradient: lavender tint.
  static const List<Color> speedGradient = [lavenderMuted, lavender];

  // ── Engine Viz ──
  static const Color engineBody = lavender;
  static const Color engineCylinder = Color(0xFFA89AB8);
  static const Color engineHead = skyBlue;
  static const Color enginePiston = sage;
  static const Color engineRod = coral;
  static const Color engineFin = lavenderLight;
}
