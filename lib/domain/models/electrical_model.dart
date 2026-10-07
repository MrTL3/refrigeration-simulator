import 'dart:math' as math;

/// Modelo físico eléctrico del motor del compresor frigorífico.
/// Calcula la potencia eléctrica consumida, factor de potencia y corriente
/// a partir del trabajo indicado entregado al refrigerante y la fricción mecánica.
class CompressorElectricalState {
  /// Tensión nominal de alimentación eficaz (Voltios, V)
  final double voltageVolts;

  /// Potencia mecánica indicada entregada al refrigerante (Watts, W)
  final double indicatedPowerWatts;

  /// Pérdidas mecánicas por fricción en cojinetes y rozamiento del pistón (Watts, W)
  final double frictionPowerWatts;

  /// Potencia eléctrica activa absorbida de la red (Watts, W)
  final double activePowerWatts;

  /// Factor de potencia (cos φ) dependiente del régimen de carga del motor
  final double powerFactor;

  /// Corriente eficaz total absorbida (Amperios, A)
  final double currentAmps;

  /// Corriente nominal a plena carga (FLA - Full Load Amps)
  final double fullLoadAmps;

  /// Corriente de rotor bloqueado en el instante de arranque (LRA - Locked Rotor Amps)
  final double lockedRotorAmps;

  const CompressorElectricalState({
    required this.voltageVolts,
    required this.indicatedPowerWatts,
    required this.frictionPowerWatts,
    required this.activePowerWatts,
    required this.powerFactor,
    required this.currentAmps,
    required this.fullLoadAmps,
    required this.lockedRotorAmps,
  });

  /// Estado con compresor desconectado (consumo nulo)
  factory CompressorElectricalState.off() {
    return const CompressorElectricalState(
      voltageVolts: 230.0,
      indicatedPowerWatts: 0.0,
      frictionPowerWatts: 0.0,
      activePowerWatts: 0.0,
      powerFactor: 0.0,
      currentAmps: 0.0,
      fullLoadAmps: 4.8,
      lockedRotorAmps: 24.0,
    );
  }

  /// Calcula el estado eléctrico riguroso a partir de la potencia de compresión y las RPM
  static CompressorElectricalState calculate({
    required double indicatedPowerWatts,
    required double currentRpm,
    required double targetRpm,
    required double motorEfficiency,
    double nominalVoltage = 230.0,
  }) {
    if (currentRpm <= 5.0 && indicatedPowerWatts <= 1.0) {
      return CompressorElectricalState.off();
    }

    // Pérdidas por fricción mecánica proporcionales a las RPM
    final rpmRatio = (currentRpm / math.max(100.0, targetRpm)).clamp(0.0, 1.5);
    final frictionWatts = 55.0 * math.pow(rpmRatio, 1.4);

    // Potencia en el eje del motor
    final shaftPowerWatts = indicatedPowerWatts + frictionWatts;

    // Rendimiento eléctrico del motor
    final eff = motorEfficiency.clamp(0.65, 0.92);
    final activePowerWatts = shaftPowerWatts / eff;

    // Relación de carga del motor sobre su punto de diseño (~900 W nominales)
    const nominalMotorPower = 950.0;
    final loadFraction = (activePowerWatts / nominalMotorPower).clamp(0.1, 1.6);

    // El factor de potencia aumenta con la carga inductiva del motor
    final powerFactor = (0.55 + 0.35 * math.sqrt(loadFraction.clamp(0.0, 1.0))).clamp(0.50, 0.92);

    // Corriente de régimen continuo
    final nominalFla = nominalMotorPower / (nominalVoltage * 0.82);
    final nominalLra = nominalFla * 5.2;

    double runningAmps = activePowerWatts / (nominalVoltage * powerFactor);

    // Transitorio de arranque: corriente de inserción elevada (Inrush / LRA) mientras acelera el rotor
    if (targetRpm > 0 && currentRpm < targetRpm * 0.85) {
      final slip = (1.0 - (currentRpm / targetRpm)).clamp(0.0, 1.0);
      runningAmps += nominalLra * slip * 0.75;
    }

    return CompressorElectricalState(
      voltageVolts: nominalVoltage,
      indicatedPowerWatts: indicatedPowerWatts,
      frictionPowerWatts: frictionWatts,
      activePowerWatts: activePowerWatts,
      powerFactor: powerFactor,
      currentAmps: runningAmps.clamp(0.0, nominalLra * 1.2),
      fullLoadAmps: nominalFla,
      lockedRotorAmps: nominalLra,
    );
  }
}
