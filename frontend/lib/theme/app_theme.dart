import 'package:flutter/material.dart';

class AppTheme {
  static const Color _teal = Color(0xFF0B8A7D);
  static const Color _mint = Color(0xFFB8E3DE);
  static const Color _coral = Color(0xFFF28B57);
  static const Color _ink = Color(0xFF15353A);

  static ThemeData light() {
    final scheme =
        ColorScheme.fromSeed(
          seedColor: _teal,
          brightness: Brightness.light,
        ).copyWith(
          primary: _teal,
          secondary: _coral,
          surface: const Color(0xFFFFFEFB),
          onSurface: _ink,
          surfaceContainerHighest: const Color(0xFFEAF3F1),
        );

    final textTheme = Typography.blackCupertino.apply(
      bodyColor: _ink,
      displayColor: _ink,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      fontFamily: 'SF Pro Text',
      fontFamilyFallback: const [
        'SF Pro Display',
        'PingFang SC',
        'Helvetica Neue',
        'Arial',
        'sans-serif',
      ],
      scaffoldBackgroundColor: const Color(0xFFF4F8F7),
      textTheme: textTheme,
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Color(0xFFF1F8F5),
        surfaceTintColor: Colors.transparent,
        foregroundColor: _ink,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: Colors.white.withValues(alpha: 0.92),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.9),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: _mint.withValues(alpha: 0.75)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: _mint.withValues(alpha: 0.75)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: _teal, width: 1.4),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          backgroundColor: _teal,
          foregroundColor: Colors.white,
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        indicatorColor: _mint.withValues(alpha: 0.9),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: _teal);
          }
          return const IconThemeData(color: Color(0xFF4E6A68));
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          return TextStyle(
            color: states.contains(WidgetState.selected)
                ? _teal
                : const Color(0xFF4E6A68),
            fontSize: 12,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w500,
          );
        }),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}
