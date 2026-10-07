/// Unidades de temperatura admitidas en el simulador.
/// La unidad base canónica interna del motor de física es el Kelvin (K).
enum TemperatureUnit {
  celsius('°C'),
  kelvin('K'),
  fahrenheit('°F');

  final String symbol;

  const TemperatureUnit(this.symbol);

  /// Convierte de esta unidad a Kelvin absolutos.
  double toKelvin(double value) {
    switch (this) {
      case TemperatureUnit.celsius:
        return value + 273.15;
      case TemperatureUnit.kelvin:
        return value;
      case TemperatureUnit.fahrenheit:
        return (value - 32.0) * (5.0 / 9.0) + 273.15;
    }
  }

  /// Convierte de Kelvin absolutos a esta unidad.
  double fromKelvin(double kelvin) {
    switch (this) {
      case TemperatureUnit.celsius:
        return kelvin - 273.15;
      case TemperatureUnit.kelvin:
        return kelvin;
      case TemperatureUnit.fahrenheit:
        return (kelvin - 273.15) * (9.0 / 5.0) + 32.0;
    }
  }

  /// Convierte un diferencial térmico (ΔT) de Kelvin a esta unidad.
  /// (En ΔT, 1 K = 1 °C = 1.8 °F).
  double convertDelta(double deltaKelvin) {
    switch (this) {
      case TemperatureUnit.celsius:
      case TemperatureUnit.kelvin:
        return deltaKelvin;
      case TemperatureUnit.fahrenheit:
        return deltaKelvin * 1.8;
    }
  }
}
