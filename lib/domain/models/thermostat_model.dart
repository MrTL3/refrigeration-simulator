/// Controlador termostático digital para el control de marcha/paro del compresor.
class ThermostatModel {
  /// Consigna de temperatura de la cámara en grados Celsius
  final double setpointCelsius;

  /// Histéresis o diferencial de arranque en Kelvin
  final double hysteresisKelvin;

  /// Indica si el control automático por termostato está activo
  final bool isEnabled;

  /// Demanda de frío activa (relevador del compresor cerrado)
  final bool isCallForCooling;

  const ThermostatModel({
    this.setpointCelsius = 2.0, // 2.0 °C
    this.hysteresisKelvin = 2.0, // Arranca a 4.0 °C, para a 2.0 °C
    this.isEnabled = false,
    this.isCallForCooling = true,
  });

  /// Evalúa la lógica de histéresis ante la temperatura actual de la cámara (Kelvin)
  ThermostatModel update(double roomTempKelvin) {
    if (!isEnabled) {
      return copyWith(isCallForCooling: true);
    }

    final roomCelsius = roomTempKelvin - 273.15;
    final cutInTemp = setpointCelsius + hysteresisKelvin;
    final cutOutTemp = setpointCelsius;

    bool newCall = isCallForCooling;
    if (roomCelsius >= cutInTemp) {
      newCall = true;
    } else if (roomCelsius <= cutOutTemp) {
      newCall = false;
    }

    return copyWith(isCallForCooling: newCall);
  }

  ThermostatModel copyWith({
    double? setpointCelsius,
    double? hysteresisKelvin,
    bool? isEnabled,
    bool? isCallForCooling,
  }) {
    return ThermostatModel(
      setpointCelsius: setpointCelsius ?? this.setpointCelsius,
      hysteresisKelvin: hysteresisKelvin ?? this.hysteresisKelvin,
      isEnabled: isEnabled ?? this.isEnabled,
      isCallForCooling: isCallForCooling ?? this.isCallForCooling,
    );
  }
}
