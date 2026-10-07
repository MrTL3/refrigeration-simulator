/// Estado físico del flujo de aire forzado a través de un intercambiador de calor (condensador o evaporador).
class HeatExchangerAirFlowState {
  /// Velocidad de giro del ventilador en RPM
  final double fanRpm;

  /// Porcentaje de velocidad relativa del ventilador (0.0 a 1.0)
  final double fanSpeedFraction;

  /// Caudal volumétrico de aire (m³/s)
  final double volumeFlowM3PerSec;

  /// Caudal másico de aire (kg/s)
  final double massFlowKgPerSec;

  /// Temperatura del aire de entrada al intercambiador (Kelvin, K)
  final double inletAirTemperatureK;

  /// Salto térmico experimentado por el aire (Kelvin, K): positivo si se calienta, negativo si se enfría
  final double deltaTAirKelvin;

  /// Temperatura del aire de salida/impulsión (Kelvin, K)
  final double outletAirTemperatureK;

  /// Calor total transferido entre el refrigerante y la corriente de aire (Watts, W)
  final double heatTransferWatts;

  const HeatExchangerAirFlowState({
    required this.fanRpm,
    required this.fanSpeedFraction,
    required this.volumeFlowM3PerSec,
    required this.massFlowKgPerSec,
    required this.inletAirTemperatureK,
    required this.deltaTAirKelvin,
    required this.outletAirTemperatureK,
    required this.heatTransferWatts,
  });

  /// Constante de calor específico del aire a presión atmosférica estándar (J / (kg · K))
  static const double cpAirJoulesPerKgK = 1005.0;

  /// Densidad media del aire seco a nivel del mar (kg/m³)
  static const double airDensityKgPerM3 = 1.204;

  /// Calcula el flujo de aire físico para el condensador (el aire absorbe calor y sale caliente)
  static HeatExchangerAirFlowState calculateCondenser({
    required double heatRejectionWatts,
    required double ambientTempK,
    required double fanSpeedFraction,
    double nominalFanRpm = 1350.0,
    double nominalAirVolumeM3PerSec = 0.35, // ~1260 m³/h
  }) {
    final speed = fanSpeedFraction.clamp(0.0, 1.2);
    final rpm = nominalFanRpm * speed;

    // Caudal de aire forzado dependiente de la velocidad del rodete
    // Si el ventilador está parado, queda una leve convección natural residual (~5% del caudal)
    final volFlow = (nominalAirVolumeM3PerSec * (speed > 0.05 ? speed : 0.05)).clamp(0.015, 0.6);
    final massFlow = volFlow * airDensityKgPerM3;

    // Salto térmico del aire: ΔT = Q_cond / (m_dot_air * Cp_air)
    final deltaT = massFlow > 0 ? (heatRejectionWatts / (massFlow * cpAirJoulesPerKgK)) : 0.0;
    final outletT = ambientTempK + deltaT;

    return HeatExchangerAirFlowState(
      fanRpm: rpm,
      fanSpeedFraction: speed,
      volumeFlowM3PerSec: volFlow,
      massFlowKgPerSec: massFlow,
      inletAirTemperatureK: ambientTempK,
      deltaTAirKelvin: deltaT,
      outletAirTemperatureK: outletT,
      heatTransferWatts: heatRejectionWatts,
    );
  }

  /// Calcula el flujo de aire físico para el evaporador (el aire cede calor y sale frío hacia la cámara)
  static HeatExchangerAirFlowState calculateEvaporator({
    required double coolingCapacityWatts,
    required double roomAirTempK,
    required double fanSpeedFraction,
    double nominalFanRpm = 1300.0,
    double nominalAirVolumeM3PerSec = 0.28, // ~1000 m³/h
  }) {
    final speed = fanSpeedFraction.clamp(0.0, 1.2);
    final rpm = nominalFanRpm * speed;

    final volFlow = (nominalAirVolumeM3PerSec * (speed > 0.05 ? speed : 0.04)).clamp(0.01, 0.5);
    final massFlow = volFlow * airDensityKgPerM3;

    // Salto térmico del aire: enfriamiento ΔT negativo
    final deltaT = massFlow > 0 ? -(coolingCapacityWatts / (massFlow * cpAirJoulesPerKgK)) : 0.0;
    final outletT = roomAirTempK + deltaT;

    return HeatExchangerAirFlowState(
      fanRpm: rpm,
      fanSpeedFraction: speed,
      volumeFlowM3PerSec: volFlow,
      massFlowKgPerSec: massFlow,
      inletAirTemperatureK: roomAirTempK,
      deltaTAirKelvin: deltaT,
      outletAirTemperatureK: outletT,
      heatTransferWatts: coolingCapacityWatts,
    );
  }
}
