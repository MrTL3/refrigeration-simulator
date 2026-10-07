import '../constants/physical_constants.dart';

/// Unidades de presión admitidas en el simulador.
/// La unidad base canónica interna del motor de física es el Pascal (Pa).
enum PressureUnit {
  pascal('Pa', 1.0),
  kilopascal('kPa', 1000.0),
  bar('bar', 100000.0),
  megapascal('MPa', 1000000.0),
  psi('PSI', 6894.757293168);

  final String symbol;
  final double pascalsPerUnit;

  const PressureUnit(this.symbol, this.pascalsPerUnit);

  /// Convierte un valor de esta unidad a Pascales absolutos.
  double toPascals(double value, {bool isGauge = false}) {
    final absPascals = value * pascalsPerUnit;
    return isGauge ? absPascals + PhysicalConstants.standardAtmosphericPressure : absPascals;
  }

  /// Convierte un valor de Pascales absolutos a esta unidad.
  double fromPascals(double pascals, {bool toGauge = false}) {
    final effectivePascals = toGauge
        ? (pascals - PhysicalConstants.standardAtmosphericPressure)
        : pascals;
    return effectivePascals / pascalsPerUnit;
  }
}
