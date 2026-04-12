import 'package:flutter/material.dart';

/// Raw color primitives — never use these directly in widgets.
/// Widgets should read from Theme.of(context).colorScheme instead.
abstract final class AppColors {
  // ── Brand (theme-independent) ──────────────────────────────────────────────
  static const Color primary     = Color(0xFFFFC107); // BandiWala yellow
  static const Color primaryDark = Color(0xFFE6AC00); // darker yellow for dark bg
  static const Color onPrimary   = Color(0xFF1A1A1A); // text on yellow buttons

  // ── Semantic (same in both themes) ────────────────────────────────────────
  static const Color success = Color(0xFF43A047);
  static const Color error   = Color(0xFFE53935);
  static const Color warning = Color(0xFFFFA000);
  static const ColorScheme light = ColorScheme(
    brightness: Brightness.light,
    primary:          primary,
    onPrimary:        onPrimary,
    primaryContainer: Color(0xFFFFF3CD),
    onPrimaryContainer: Color(0xFF1A1A1A),
    secondary:        Color(0xFF757575),
    onSecondary:      Colors.white,
    secondaryContainer: Color(0xFFF5F5F5),
    onSecondaryContainer: Color(0xFF212121),
    surface:          Colors.white,
    onSurface:        Color(0xFF212121),
    surfaceContainerHighest: Color(0xFFEEEEEE),
    onSurfaceVariant: Color(0xFF757575),
    outline:          Color(0xFFBDBDBD),
    outlineVariant:   Color(0xFFEEEEEE),
    error:            Color(0xFFE53935),
    onError:          Colors.white,
    shadow:           Colors.black,
    scrim:            Colors.black,
    inverseSurface:   Color(0xFF1A1A1A),
    onInverseSurface: Colors.white,
    inversePrimary:   primaryDark,
  );

  // ── Dark palette ──────────────────────────────────────────────────────────
  static const ColorScheme dark = ColorScheme(
    brightness: Brightness.dark,
    primary:          primaryDark,
    onPrimary:        Color(0xFF1A1A1A),
    primaryContainer: Color(0xFF3D2E00),
    onPrimaryContainer: Color(0xFFFFE082),
    secondary:        Color(0xFFB0B0B0),
    onSecondary:      Color(0xFF1A1A1A),
    secondaryContainer: Color(0xFF2C2C2C),
    onSecondaryContainer: Color(0xFFE0E0E0),
    surface:          Color(0xFF121212),
    onSurface:        Color(0xFFE0E0E0),
    surfaceContainerHighest: Color(0xFF2C2C2C),
    onSurfaceVariant: Color(0xFFB0B0B0),
    outline:          Color(0xFF555555),
    outlineVariant:   Color(0xFF333333),
    error:            Color(0xFFEF5350),
    onError:          Colors.black,
    shadow:           Colors.black,
    scrim:            Colors.black,
    inverseSurface:   Color(0xFFE0E0E0),
    onInverseSurface: Color(0xFF1A1A1A),
    inversePrimary:   primary,
  );
}
