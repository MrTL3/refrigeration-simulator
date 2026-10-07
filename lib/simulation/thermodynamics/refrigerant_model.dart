import '../../domain/models/thermodynamic_state.dart';

/// Interfaz maestra para el modelo termodinámico de cualquier refrigerante.
/// Todas las propiedades se computan y devuelven en unidades SI estrictas:
/// - Presión en Pascal (Pa)
/// - Temperatura en Kelvin (K)
/// - Entalpía en J/kg
/// - Entropía en J / (kg · K)
/// - Densidad en kg/m³
abstract class RefrigerantModel {
  String get name;
  String get chemicalFormula;
  double get molecularWeight; // kg / kmol
  double get criticalPressure; // Pa
  double get criticalTemperature; // K

  /// Presión de saturación a partir de la temperatura absoluta (K).
  double saturationPressure(double temperatureK);

  /// Temperatura de saturación a partir de la presión absoluta (Pa).
  double saturationTemperature(double pressurePa);

  /// Entalpía específica de líquido saturado (x = 0) a una presión dada (J/kg).
  double saturatedLiquidEnthalpy(double pressurePa);

  /// Entalpía específica de vapor saturado seco (x = 1) a una presión dada (J/kg).
  double saturatedVaporEnthalpy(double pressurePa);

  /// Entropía específica de líquido saturado a una presión dada (J / (kg · K)).
  double saturatedLiquidEntropy(double pressurePa);

  /// Entropía específica de vapor saturado a una presión dada (J / (kg · K)).
  double saturatedVaporEntropy(double pressurePa);

  /// Densidad de líquido saturado (kg/m³).
  double saturatedLiquidDensity(double pressurePa);

  /// Densidad de vapor saturado seco (kg/m³).
  double saturatedVaporDensity(double pressurePa);

  /// Título o calidad de vapor dado un estado definido por presión (Pa) y entalpía (J/kg).
  double qualityFromPressureEnthalpy(double pressurePa, double enthalpyJPerKg);

  /// Calcula el estado termodinámico completo a partir de presión (Pa) y entalpía (J/kg).
  ThermodynamicState calculateStateFromPressureEnthalpy(
    double pressurePa,
    double enthalpyJPerKg,
  );

  /// Calcula el estado termodinámico a partir de presión (Pa) y temperatura (K),
  /// especificando si se encuentra en zona líquida o gaseosa en caso de ambigüedad.
  ThermodynamicState calculateStateFromPressureTemperature(
    double pressurePa,
    double temperatureK, {
    bool isLiquid = false,
  });
}
