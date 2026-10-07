/// Constantes físicas universales para el cálculo termodinámico de FrigoLab.
abstract class PhysicalConstants {
  /// Presión atmosférica estándar a nivel del mar (Pascal)
  static const double standardAtmosphericPressure = 101325.0; // Pa

  /// Cero absoluto en grados Celsius
  static const double absoluteZeroCelsius = -273.15; // °C

  /// Aceleración de la gravedad estándar (m/s²)
  static const double standardGravity = 9.80665; // m/s²

  /// Constante universal de los gases ideales (J / (mol · K))
  static const double universalGasConstant = 8.314462618;

  /// Densidad aproximada del agua líquida a 4°C (kg/m³)
  static const double waterDensity = 1000.0;
}
