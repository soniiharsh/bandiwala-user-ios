import 'package:flutter/material.dart';

/// Central color palette for Bandiwala.
/// Change values here to retheme the entire app.
abstract final class AppColors {
  // ── Brand ──────────────────────────────────────────────────────────────────
  static const Color primary = Color(0xFFFFC107);       // Bandiwala yellow
  static const Color primaryLight = Color(0xFFFFF3CD);  // pale yellow tint
  static const Color primaryBorder = Color(0x4DFFC107); // 30% yellow

  // ── Semantic ───────────────────────────────────────────────────────────────
  static const Color success = Color(0xFF43A047);   // green (veg / rating)
  static const Color error   = Color(0xFFE53935);   // red (non-veg / offline)
  static const Color warning = Color(0xFFFFA000);   // amber

  // ── Neutrals ───────────────────────────────────────────────────────────────
  static const Color white      = Colors.white;
  static const Color black      = Colors.black;
  static const Color textPrimary   = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textHint      = Color(0xFFBDBDBD);
  static const Color divider       = Color(0xFFEEEEEE);
  static const Color surfaceGrey   = Color(0xFFF5F5F5);
  static const Color cardGrey      = Color(0xFFEEEEEE);
}
