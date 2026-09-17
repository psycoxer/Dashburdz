import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'colors.dart';

/// Light and dark theme data for Dashburdz.
///
/// Uses Inter for numeric data (tabular figures) and
/// Space Grotesk for labels and UI text.
class AppTheme {
  AppTheme._();

  // ── Typography ──

  static TextStyle _inter({
    double size = 14,
    FontWeight weight = FontWeight.w400,
    Color color = AppColors.lightTextPrimary,
    double? letterSpacing,
  }) {
    return GoogleFonts.inter(
      fontSize: size,
      fontWeight: weight,
      color: color,
      letterSpacing: letterSpacing,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
  }

  static TextStyle _spaceGrotesk({
    double size = 14,
    FontWeight weight = FontWeight.w500,
    Color color = AppColors.lightTextSecondary,
    double? letterSpacing,
  }) {
    return GoogleFonts.spaceGrotesk(
      fontSize: size,
      fontWeight: weight,
      color: color,
      letterSpacing: letterSpacing,
    );
  }

  // ── Shared Constants ──

  static final _borderRadius = BorderRadius.circular(16);

  // ── Light Theme ──

  static ThemeData light() {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.lightBackground,
      canvasColor: AppColors.lightBackground,
      cardColor: AppColors.lightSurface,
      dividerColor: AppColors.lightDivider,
      colorScheme: const ColorScheme.light(
        primary: AppColors.lavender,
        secondary: AppColors.sage,
        tertiary: AppColors.coral,
        surface: AppColors.lightSurface,
        error: AppColors.error,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: AppColors.lightTextPrimary,
        onError: Colors.white,
      ),
      textTheme: TextTheme(
        // Large gauge readout (RPM, Speed hero numbers)
        displayLarge: _inter(
          size: 48,
          weight: FontWeight.w700,
          color: AppColors.lightTextPrimary,
        ),
        // Medium gauge readout
        displayMedium: _inter(
          size: 36,
          weight: FontWeight.w700,
          color: AppColors.lightTextPrimary,
        ),
        // Small gauge readout
        displaySmall: _inter(
          size: 24,
          weight: FontWeight.w600,
          color: AppColors.lightTextPrimary,
        ),
        // Tile labels
        titleMedium: _spaceGrotesk(
          size: 13,
          weight: FontWeight.w600,
          color: AppColors.lightTextSecondary,
          letterSpacing: 0.8,
        ),
        // Chip/compact text
        titleSmall: _spaceGrotesk(
          size: 11,
          weight: FontWeight.w500,
          color: AppColors.lightTextTertiary,
          letterSpacing: 0.5,
        ),
        // Unit labels (°C, km/h, %)
        labelMedium: _spaceGrotesk(
          size: 11,
          weight: FontWeight.w400,
          color: AppColors.lightTextTertiary,
        ),
        // Body text (debug panel)
        bodyMedium: _inter(
          size: 13,
          weight: FontWeight.w400,
          color: AppColors.lightTextPrimary,
        ),
        bodySmall: _inter(
          size: 11,
          weight: FontWeight.w400,
          color: AppColors.lightTextSecondary,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.lightSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: _borderRadius),
        margin: EdgeInsets.zero,
      ),
      iconTheme: const IconThemeData(
        color: AppColors.lightTextSecondary,
        size: 20,
      ),
      splashFactory: InkSparkle.splashFactory,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
        },
      ),
    );
  }

  // ── Dark Theme ──

  static ThemeData dark() {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.darkBackground,
      canvasColor: AppColors.darkBackground,
      cardColor: AppColors.darkSurface,
      dividerColor: AppColors.darkDivider,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.lavenderDark,
        secondary: AppColors.sageDark,
        tertiary: AppColors.coralDark,
        surface: AppColors.darkSurface,
        error: AppColors.error,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: AppColors.darkTextPrimary,
        onError: Colors.white,
      ),
      textTheme: TextTheme(
        displayLarge: _inter(
          size: 48,
          weight: FontWeight.w700,
          color: AppColors.darkTextPrimary,
        ),
        displayMedium: _inter(
          size: 36,
          weight: FontWeight.w700,
          color: AppColors.darkTextPrimary,
        ),
        displaySmall: _inter(
          size: 24,
          weight: FontWeight.w600,
          color: AppColors.darkTextPrimary,
        ),
        titleMedium: _spaceGrotesk(
          size: 13,
          weight: FontWeight.w600,
          color: AppColors.darkTextSecondary,
          letterSpacing: 0.8,
        ),
        titleSmall: _spaceGrotesk(
          size: 11,
          weight: FontWeight.w500,
          color: AppColors.darkTextTertiary,
          letterSpacing: 0.5,
        ),
        labelMedium: _spaceGrotesk(
          size: 11,
          weight: FontWeight.w400,
          color: AppColors.darkTextTertiary,
        ),
        bodyMedium: _inter(
          size: 13,
          weight: FontWeight.w400,
          color: AppColors.darkTextPrimary,
        ),
        bodySmall: _inter(
          size: 11,
          weight: FontWeight.w400,
          color: AppColors.darkTextSecondary,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.darkSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: _borderRadius),
        margin: EdgeInsets.zero,
      ),
      iconTheme: const IconThemeData(
        color: AppColors.darkTextSecondary,
        size: 20,
      ),
      splashFactory: InkSparkle.splashFactory,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
        },
      ),
    );
  }

  // ── Helper: resolve accent colors for current brightness ──

  static Color accentLavender(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? AppColors.lavenderDark
          : AppColors.lavender;

  static Color accentSage(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? AppColors.sageDark
          : AppColors.sage;

  static Color accentCoral(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? AppColors.coralDark
          : AppColors.coral;

  static Color accentSkyBlue(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? AppColors.skyBlueDark
          : AppColors.skyBlue;

  static Color surfaceColor(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? AppColors.darkSurface
          : AppColors.lightSurface;

  static Color backgroundVariant(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? AppColors.darkSurfaceVariant
          : AppColors.lightSurfaceVariant;
}
