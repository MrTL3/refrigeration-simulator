/// Modelo físico térmico de una cámara frigorífica industrial.
/// Calcula la transferencia de calor por cerramientos y cargas internas,
/// y gobierna la inercia térmica del recinto:
/// C_room · (dT_room / dt) = Q_load - Q_evap
class ColdRoomModel {
  /// Temperatura interior actual del aire de la cámara (Kelvin)
  final double temperatureKelvin;

  /// Volumen geométrico de la cámara en m³
  final double volumeM3;

  /// Superficie total de paredes, suelo y techo en m²
  final double surfaceAreaM2;

  /// Coeficiente global de transmisión térmica del aislamiento (W / (m² · K))
  /// Panel sándwich PUR/PIR típico de 100mm: U ~ 0.22 - 0.28 W/(m²·K)
  final double thermalTransmittanceU;

  /// Capacidad calorífica efectiva total del recinto (aire + estructura + género) en J/K
  final double thermalCapacitanceJoulesPerKelvin;

  /// Carga térmica interna constante (iluminación, motores, respiración de producto) en Watts
  final double internalHeatLoadWatts;

  /// Carga térmica por infiltraciones de aire o apertura de puertas en Watts
  final double infiltrationLoadWatts;

  const ColdRoomModel({
    this.temperatureKelvin = 277.15, // 4.0 °C inicial
    this.volumeM3 = 24.0,            // Cámara de ~3x3x2.6 m
    this.surfaceAreaM2 = 48.0,
    this.thermalTransmittanceU = 0.26,
    this.thermalCapacitanceJoulesPerKelvin = 85000.0, // 85 kJ/K de inercia
    this.internalHeatLoadWatts = 150.0,
    this.infiltrationLoadWatts = 100.0,
  });

  /// Transmisión térmica a través de los cerramientos hacia el exterior (Watts):
  /// Q_trans = U · A · (T_amb - T_room)
  double transmissionLoadWatts(double ambientTemperatureKelvin) {
    final deltaT = ambientTemperatureKelvin - temperatureKelvin;
    return thermalTransmittanceU * surfaceAreaM2 * deltaT;
  }

  /// Carga térmica total instantánea que entra al recinto (Watts)
  double totalHeatLoadWatts(double ambientTemperatureKelvin) {
    final qTrans = transmissionLoadWatts(ambientTemperatureKelvin);
    return qTrans + internalHeatLoadWatts + infiltrationLoadWatts;
  }

  ColdRoomModel copyWith({
    double? temperatureKelvin,
    double? volumeM3,
    double? surfaceAreaM2,
    double? thermalTransmittanceU,
    double? thermalCapacitanceJoulesPerKelvin,
    double? internalHeatLoadWatts,
    double? infiltrationLoadWatts,
  }) {
    return ColdRoomModel(
      temperatureKelvin: temperatureKelvin ?? this.temperatureKelvin,
      volumeM3: volumeM3 ?? this.volumeM3,
      surfaceAreaM2: surfaceAreaM2 ?? this.surfaceAreaM2,
      thermalTransmittanceU: thermalTransmittanceU ?? this.thermalTransmittanceU,
      thermalCapacitanceJoulesPerKelvin:
          thermalCapacitanceJoulesPerKelvin ?? this.thermalCapacitanceJoulesPerKelvin,
      internalHeatLoadWatts: internalHeatLoadWatts ?? this.internalHeatLoadWatts,
      infiltrationLoadWatts: infiltrationLoadWatts ?? this.infiltrationLoadWatts,
    );
  }
}
