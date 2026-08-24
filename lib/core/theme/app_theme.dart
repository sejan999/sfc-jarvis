import 'package:flutter/material.dart';

/// Futuristic HUD / Jarvis color palette.
class JarvisColors {
  JarvisColors._();

  static const Color background = Color(0xFF050A14);
  static const Color surface = Color(0xFF0A1424);
  static const Color card = Color(0xFF0E1B30);
  static const Color neonCyan = Color(0xFF00E5FF);
  static const Color neonBlue = Color(0xFF2979FF);
  static const Color neonDeep = Color(0xFF00B8D4);
  static const Color danger = Color(0xFFFF5252);
  static const Color success = Color(0xFF00E676);
  static const Color textPrimary = Color(0xFFE3F2FD);
  static const Color textSecondary = Color(0xFF7FA8C9);

  static const LinearGradient orbGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [neonCyan, neonBlue, neonDeep],
  );
}

/// Application-wide dark futuristic theme.
class AppTheme {
  AppTheme._();

  static ThemeData get dark {
    final base = ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: JarvisColors.background,
      colorScheme: base.colorScheme.copyWith(
        primary: JarvisColors.neonCyan,
        secondary: JarvisColors.neonBlue,
        surface: JarvisColors.surface,
        error: JarvisColors.danger,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: JarvisColors.neonCyan,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          letterSpacing: 6,
        ),
      ),
      textTheme: base.textTheme.apply(
        bodyColor: JarvisColors.textPrimary,
        displayColor: JarvisColors.neonCyan,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.all(JarvisColors.neonCyan),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? JarvisColors.neonBlue.withOpacity(0.5)
              : JarvisColors.card,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: JarvisColors.card,
        contentTextStyle: const TextStyle(color: JarvisColors.textPrimary),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: JarvisColors.neonCyan),
        ),
      ),
    );
  }
}