import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';

/// Builds a [ThemeData] from a [ColorScheme].
/// Add AppTheme.dark to MaterialApp.darkTheme and you're done.
abstract final class AppTheme {
  static SystemUiOverlayStyle systemUiStyle(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    return SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      systemNavigationBarColor: isDark
          ? AppColors.dark.surface
          : AppColors.light.surface,
      systemNavigationBarIconBrightness:
          isDark ? Brightness.light : Brightness.dark,
    );
  }

  static ThemeData get light => _build(AppColors.light);
  static ThemeData get dark  => _build(AppColors.dark);

  static ThemeData _build(ColorScheme scheme) {
    final isDark = scheme.brightness == Brightness.dark;
    return ThemeData(
      colorScheme: scheme,
      brightness: scheme.brightness,
      scaffoldBackgroundColor: scheme.surface,
      primaryColor: scheme.primary,
      textTheme: const TextTheme(
        displayLarge: AppTextStyles.displayLarge,
        titleLarge:   AppTextStyles.titleLarge,
        titleMedium:  AppTextStyles.titleMedium,
        bodyLarge:    AppTextStyles.bodyLarge,
        bodySmall:    AppTextStyles.bodySmall,
        labelSmall:   AppTextStyles.labelSmall,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        systemOverlayStyle: systemUiStyle(scheme.brightness),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: scheme.surface,
        selectedItemColor: scheme.primary,
        unselectedItemColor: scheme.onSurfaceVariant,
        type: BottomNavigationBarType.fixed,
      ),
      cardTheme: CardThemeData(
        color: isDark ? scheme.surfaceContainerHighest : scheme.surface,
        elevation: isDark ? 0 : 1.5,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: isDark
              ? BorderSide(color: scheme.outlineVariant)
              : BorderSide.none,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark
            ? scheme.surfaceContainerHighest
            : scheme.secondaryContainer,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: scheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
        hintStyle: TextStyle(color: scheme.onSurfaceVariant),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: isDark ? scheme.surfaceContainerHighest : scheme.inverseSurface,
        contentTextStyle: TextStyle(color: isDark ? scheme.onSurface : scheme.onInverseSurface),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant,
        thickness: 1,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: scheme.primaryContainer,
        labelStyle: TextStyle(
          color: scheme.onPrimaryContainer,
          fontWeight: FontWeight.w700,
        ),
        deleteIconColor: scheme.onPrimaryContainer,
      ),
    );
  }
}
