import 'package:flutter/material.dart';

class AppTheme {
  static const green = Color(0xFF238B45);
  static const deepGreen = Color(0xFF14573A);
  static const lightAccent = Color(0xFF4ADE80);

  // ---- Theme-aware helpers (use these instead of hard-coded colors) ----
  static bool isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  /// Main accent color that is readable in both modes.
  static Color brand(BuildContext context) =>
      isDark(context) ? lightAccent : green;

  /// Soft green background for icon circles / empty states.
  static Color softGreen(BuildContext context) => isDark(context)
      ? lightAccent.withValues(alpha: 0.14)
      : const Color(0xFFE3F3E8);

  /// Secondary text color that is readable in both modes.
  static Color muted(BuildContext context) =>
      Theme.of(context).colorScheme.onSurfaceVariant;

  static ThemeData get light => _build(Brightness.light);
  static ThemeData get dark => _build(Brightness.dark);

  static ThemeData _build(Brightness b) {
    final dark = b == Brightness.dark;

    final scheme =
        ColorScheme.fromSeed(
          seedColor: dark ? lightAccent : green,
          brightness: b,
        ).copyWith(
          surface: dark ? const Color(0xFF101A14) : const Color(0xFFF5F8F4),
          onSurface: dark ? const Color(0xFFEAF2EC) : const Color(0xFF14231A),
          onSurfaceVariant: dark
              ? const Color(0xFFB9C9BE)
              : const Color(0xFF4B5C51),
        );

    final cardColor = dark ? const Color(0xFF182A1F) : Colors.white;
    final border = dark
        ? Colors.white.withValues(alpha: 0.12)
        : const Color(0xFFCFE0D3);
    final focus = dark ? lightAccent : green;
    final dialogColor = dark
        ? const Color(0xFF1A2B21)
        : const Color(0xFFF7FBF7);

    OutlineInputBorder outline(Color c, [double w = 1]) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: c, width: w),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: b,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        color: cardColor,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: border),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: dialogColor,
        surfaceTintColor: dark
            ? lightAccent.withValues(alpha: 0.04)
            : green.withValues(alpha: 0.035),
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: border),
        ),
        alignment: Alignment.center,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        titleTextStyle: TextStyle(
          color: scheme.onSurface,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          height: 1.25,
        ),
        contentTextStyle: TextStyle(
          color: scheme.onSurfaceVariant,
          fontSize: 15,
          height: 1.45,
        ),
        actionsPadding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: cardColor,
        selectedColor: dark
            ? lightAccent.withValues(alpha: 0.22)
            : const Color(0xFFD6EEDD),
        side: BorderSide(color: border),
        labelStyle: TextStyle(color: scheme.onSurface),
      ),
      dividerTheme: DividerThemeData(color: border),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: dark
            ? Colors.white.withValues(alpha: 0.07)
            : Colors.white.withValues(alpha: 0.95),
        border: outline(border),
        enabledBorder: outline(border),
        focusedBorder: outline(focus, 1.5),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        labelStyle: TextStyle(color: scheme.onSurfaceVariant),
        floatingLabelStyle: TextStyle(
          color: focus,
          fontWeight: FontWeight.w600,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        insetPadding: const EdgeInsets.all(16),
      ),
    );
  }
}
