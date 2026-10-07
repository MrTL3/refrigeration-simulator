/// Estado de fase de un fluido refrigerante.
enum PhaseState {
  subcooledLiquid('Líquido subenfriado'),
  saturatedLiquid('Líquido saturado (x=0)'),
  twoPhase('Mezcla bifásica líquido-vapor'),
  saturatedVapor('Vapor saturado seco (x=1)'),
  superheatedVapor('Vapor sobrecalentado');

  final String displayName;
  const PhaseState(this.displayName);
}

/// Representa el estado termodinámico completo e instantáneo de un punto del fluido.
class ThermodynamicState {
  /// Presión absoluta (Pascal, Pa)
  final double pressure;

  /// Temperatura absoluta (Kelvin, K)
  final double temperature;

  /// Entalpía específica (J/kg)
  final double enthalpy;

  /// Entropía específica (J / (kg · K))
  final double entropy;

  /// Densidad (kg/m³)
  final double density;

  /// Título o calidad de vapor (0.0 = líquido saturado, 1.0 = vapor saturado seco)
  /// Se fija en 0.0 para líquido subenfriado y 1.0 para vapor sobrecalentado.
  final double vaporQuality;

  /// Estado de fase
  final PhaseState phaseState;

  const ThermodynamicState({
    required this.pressure,
    required this.temperature,
    required this.enthalpy,
    required this.entropy,
    required this.density,
    required this.vaporQuality,
    required this.phaseState,
  });

  /// Crea una copia con campos modificados
  ThermodynamicState copyWith({
    double? pressure,
    double? temperature,
    double? enthalpy,
    double? entropy,
    double? density,
    double? vaporQuality,
    PhaseState? phaseState,
  }) {
    return ThermodynamicState(
      pressure: pressure ?? this.pressure,
      temperature: temperature ?? this.temperature,
      enthalpy: enthalpy ?? this.enthalpy,
      entropy: entropy ?? this.entropy,
      density: density ?? this.density,
      vaporQuality: vaporQuality ?? this.vaporQuality,
      phaseState: phaseState ?? this.phaseState,
    );
  }

  /// Estado de referencia nulo o no inicializado (vacío)
  factory ThermodynamicState.zero() {
    return const ThermodynamicState(
      pressure: 101325.0,
      temperature: 293.15, // 20 °C
      enthalpy: 200000.0,
      entropy: 1000.0,
      density: 1.2,
      vaporQuality: 1.0,
      phaseState: PhaseState.superheatedVapor,
    );
  }
}
