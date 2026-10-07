import 'pressure_unit.dart';
import 'temperature_unit.dart';
import 'power_unit.dart';
import 'mass_flow_unit.dart';

/// Clase utilitaria para formatear valores termodinámicos con sus símbolos y precisión.
class UnitFormatter {
  static String formatPressure(
    double pascals,
    PressureUnit unit, {
    int decimals = 2,
    bool isGauge = false,
  }) {
    final value = unit.fromPascals(pascals, toGauge: isGauge);
    final gaugeSuffix = isGauge ? ' (g)' : '';
    return '${value.toStringAsFixed(decimals)} ${unit.symbol}$gaugeSuffix';
  }

  static String formatTemperature(
    double kelvin,
    TemperatureUnit unit, {
    int decimals = 1,
  }) {
    final value = unit.fromKelvin(kelvin);
    return '${value.toStringAsFixed(decimals)} ${unit.symbol}';
  }

  static String formatDeltaTemperature(
    double deltaKelvin,
    TemperatureUnit unit, {
    int decimals = 1,
  }) {
    final value = unit.convertDelta(deltaKelvin);
    return '${value.toStringAsFixed(decimals)} K';
  }

  static String formatPower(
    double watts,
    PowerUnit unit, {
    int decimals = 2,
  }) {
    final value = unit.fromWatts(watts);
    return '${value.toStringAsFixed(decimals)} ${unit.symbol}';
  }

  static String formatMassFlow(
    double kgPerSecond,
    MassFlowUnit unit, {
    int decimals = 3,
  }) {
    final value = unit.fromKgPerSecond(kgPerSecond);
    return '${value.toStringAsFixed(decimals)} ${unit.symbol}';
  }

  static String formatEnthalpy(
    double joulesPerKg,
    EnthalpyUnit unit, {
    int decimals = 1,
  }) {
    final value = unit.fromJoulesPerKg(joulesPerKg);
    return '${value.toStringAsFixed(decimals)} ${unit.symbol}';
  }
}
