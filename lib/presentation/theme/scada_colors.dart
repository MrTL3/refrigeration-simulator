import 'package:flutter/material.dart';

/// Paleta de colores SCADA e industrial para refrigeración.
abstract class ScadaColors {
  // Fondos y paneles
  static const Color background = Color(0xFF0B0F19);
  static const Color surface = Color(0xFF131D2E);
  static const Color surfaceCard = Color(0xFF1B283E);
  static const Color surfaceCardHighlight = Color(0xFF22344F);
  static const Color border = Color(0xFF2B3F5E);
  static const Color borderLight = Color(0xFF3B537A);

  // Estados de presión y temperatura del ciclo frigorífico
  static const Color highPressureDischarge = Color(0xFFFF4D4F); // Vapor sobrecalentado descarga
  static const Color highPressureLiquid = Color(0xFFE02424);    // Líquido alta presión
  static const Color lowPressureTwoPhase = Color(0xFF00D2D3);   // Bifásico baja presión
  static const Color lowPressureSuction = Color(0xFF1E90FF);    // Vapor aspiración baja presión

  // Estados del sistema
  static const Color runningGreen = Color(0xFF10B981);
  static const Color warningAmber = Color(0xFFF59E0B);
  static const Color dangerRed = Color(0xFFEF4444);
  static const Color errorRed = dangerRed;
  static const Color infoBlue = Color(0xFF38BDF8);

  // Aliases de diseño y coherencia visual
  static const Color primary = infoBlue;
  static const Color cyanAccent = lowPressureTwoPhase;
  static const Color lowPressureGas = lowPressureSuction;

  // Textos y contrastes
  static const Color textPrimary = Color(0xFFF8FAFC);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textMuted = Color(0xFF64748B);
}

/// Tema de la aplicación FrigoLab.
abstract class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: ScadaColors.background,
      colorScheme: const ColorScheme.dark(
        primary: ScadaColors.infoBlue,
        secondary: ScadaColors.runningGreen,
        surface: ScadaColors.surface,
        error: ScadaColors.dangerRed,
      ),
      cardTheme: CardThemeData(
        color: ScadaColors.surfaceCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: ScadaColors.border, width: 1),
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: ScadaColors.surface,
        foregroundColor: ScadaColors.textPrimary,
        elevation: 0,
        centerTitle: false,
      ),
      dividerTheme: const DividerThemeData(
        color: ScadaColors.border,
        thickness: 1,
      ),
    );
  }
}
