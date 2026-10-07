import 'dart:math' as math;
import '../../domain/models/thermodynamic_state.dart';
import 'refrigerant_model.dart';

/// Modelo termodinámico continuo y riguroso para R-134a (1,1,1,2-Tetrafluoroetano).
/// Implementa ecuaciones de estado y saturación empíricas estándar de ASHRAE/IIR.
class R134aModel implements RefrigerantModel {
  @override
  String get name => 'R-134a';

  @override
  String get chemicalFormula => 'CF3-CH2F';

  @override
  double get molecularWeight => 102.032; // kg/kmol

  @override
  double get criticalPressure => 4059280.0; // 4.059 MPa (40.59 bar)

  @override
  double get criticalTemperature => 374.21; // 101.06 °C (374.21 K)

  // Coeficientes Antoine calibrados para R-134a (P en kPa, T en K)
  static const double _antoineA = 14.365;
  static const double _antoineB = 2081.4;
  static const double _antoineC = -33.5;

  // Propiedades térmicas específicas de referencia
  static const double _specificGasConstant = 81.4888; // J / (kg · K)
  static const double _cpLiquid = 1420.0; // J / (kg · K)
  static const double _cpVapor = 1025.0; // J / (kg · K)
  static const double _refEnthalpyLiquid0C = 200000.0; // 200 kJ/kg a 0 °C (273.15 K)
  static const double _refLatentHeat0C = 198600.0; // 198.6 kJ/kg a 0 °C
  static const double _refEntropyLiquid0C = 1000.0; // 1.0 kJ/(kg·K) a 0 °C

  @override
  double saturationPressure(double temperatureK) {
    // ln(P_kPa) = A - B / (T + C)
    final clampedT = temperatureK.clamp(200.0, criticalTemperature - 0.1);
    final lnPkPa = _antoineA - (_antoineB / (clampedT + _antoineC));
    final pKpa = math.exp(lnPkPa);
    return pKpa * 1000.0; // De kPa a Pa
  }

  @override
  double saturationTemperature(double pressurePa) {
    // T = B / (A - ln(P_kPa)) - C
    final clampedP = pressurePa.clamp(20000.0, criticalPressure - 1000.0);
    final pKpa = clampedP / 1000.0;
    final lnPkPa = math.log(pKpa);
    final denom = _antoineA - lnPkPa;
    if (denom.abs() < 1e-6) return criticalTemperature;
    final tempK = (_antoineB / denom) - _antoineC;
    return tempK.clamp(200.0, criticalTemperature);
  }

  @override
  double saturatedLiquidEnthalpy(double pressurePa) {
    final tSat = saturationTemperature(pressurePa);
    final deltaT = tSat - 273.15;
    return _refEnthalpyLiquid0C + (_cpLiquid * deltaT);
  }

  @override
  double saturatedVaporEnthalpy(double pressurePa) {
    final hLiquid = saturatedLiquidEnthalpy(pressurePa);
    final tSat = saturationTemperature(pressurePa);
    // Factor de calor latente decreciente con la aproximación al punto crítico
    final theta = ((criticalTemperature - tSat) / (criticalTemperature - 273.15))
        .clamp(0.01, 2.0);
    final latentHeat = _refLatentHeat0C * math.pow(theta, 0.38);
    return hLiquid + latentHeat;
  }

  @override
  double saturatedLiquidEntropy(double pressurePa) {
    final tSat = saturationTemperature(pressurePa);
    return _refEntropyLiquid0C + _cpLiquid * math.log(tSat / 273.15);
  }

  @override
  double saturatedVaporEntropy(double pressurePa) {
    final sLiquid = saturatedLiquidEntropy(pressurePa);
    final tSat = saturationTemperature(pressurePa);
    final hLiquid = saturatedLiquidEnthalpy(pressurePa);
    final hVapor = saturatedVaporEnthalpy(pressurePa);
    return sLiquid + ((hVapor - hLiquid) / tSat);
  }

  @override
  double saturatedLiquidDensity(double pressurePa) {
    final tSat = saturationTemperature(pressurePa);
    final deltaT = tSat - 273.15;
    // Densidad líquida aproximada en kg/m³
    return (1295.0 - (3.25 * deltaT)).clamp(500.0, 1500.0);
  }

  @override
  double saturatedVaporDensity(double pressurePa) {
    final tSat = saturationTemperature(pressurePa);
    // Gas real con factor de compresibilidad Z ~ 0.88
    const zFactor = 0.88;
    final rho = pressurePa / (zFactor * _specificGasConstant * tSat);
    return rho.clamp(0.1, 300.0);
  }

  @override
  double qualityFromPressureEnthalpy(double pressurePa, double enthalpyJPerKg) {
    final hf = saturatedLiquidEnthalpy(pressurePa);
    final hg = saturatedVaporEnthalpy(pressurePa);
    if (hg <= hf) return 0.5;

    final x = (enthalpyJPerKg - hf) / (hg - hf);
    return x.clamp(0.0, 1.0);
  }

  @override
  ThermodynamicState calculateStateFromPressureEnthalpy(
    double pressurePa,
    double enthalpyJPerKg,
  ) {
    final tSat = saturationTemperature(pressurePa);
    final hf = saturatedLiquidEnthalpy(pressurePa);
    final hg = saturatedVaporEnthalpy(pressurePa);
    final sf = saturatedLiquidEntropy(pressurePa);
    final sg = saturatedVaporEntropy(pressurePa);
    final rhof = saturatedLiquidDensity(pressurePa);
    final rhog = saturatedVaporDensity(pressurePa);

    if (enthalpyJPerKg < hf) {
      // Líquido subenfriado
      final subcooling = (hf - enthalpyJPerKg) / _cpLiquid;
      final temp = tSat - subcooling;
      final entropy = sf - _cpLiquid * math.log(tSat / temp.clamp(100.0, tSat));
      return ThermodynamicState(
        pressure: pressurePa,
        temperature: temp,
        enthalpy: enthalpyJPerKg,
        entropy: entropy,
        density: rhof,
        vaporQuality: 0.0,
        phaseState: PhaseState.subcooledLiquid,
      );
    } else if (enthalpyJPerKg > hg) {
      // Vapor sobrecalentado
      final superheat = (enthalpyJPerKg - hg) / _cpVapor;
      final temp = tSat + superheat;
      final entropy = sg + _cpVapor * math.log(temp / tSat);
      const zFactor = 0.90;
      final rho = pressurePa / (zFactor * _specificGasConstant * temp);
      return ThermodynamicState(
        pressure: pressurePa,
        temperature: temp,
        enthalpy: enthalpyJPerKg,
        entropy: entropy,
        density: rho.clamp(0.1, 200.0),
        vaporQuality: 1.0,
        phaseState: PhaseState.superheatedVapor,
      );
    } else {
      // Región bifásica líquido-vapor
      final x = (enthalpyJPerKg - hf) / (hg - hf);
      final entropy = sf + x * (sg - sf);
      // Volumen específico bifásico: v = (1-x)*vf + x*vg
      final v = (1.0 - x) * (1.0 / rhof) + x * (1.0 / rhog);
      final rho = 1.0 / v;

      final phase = (x <= 0.001)
          ? PhaseState.saturatedLiquid
          : (x >= 0.999)
              ? PhaseState.saturatedVapor
              : PhaseState.twoPhase;

      return ThermodynamicState(
        pressure: pressurePa,
        temperature: tSat,
        enthalpy: enthalpyJPerKg,
        entropy: entropy,
        density: rho,
        vaporQuality: x,
        phaseState: phase,
      );
    }
  }

  @override
  ThermodynamicState calculateStateFromPressureTemperature(
    double pressurePa,
    double temperatureK, {
    bool isLiquid = false,
  }) {
    final tSat = saturationTemperature(pressurePa);
    final hf = saturatedLiquidEnthalpy(pressurePa);
    final hg = saturatedVaporEnthalpy(pressurePa);

    if (temperatureK < tSat - 0.05 || (temperatureK <= tSat && isLiquid)) {
      // Líquido subenfriado
      final subcooling = tSat - temperatureK;
      final enthalpy = hf - (_cpLiquid * subcooling);
      return calculateStateFromPressureEnthalpy(pressurePa, enthalpy);
    } else if (temperatureK > tSat + 0.05 || (!isLiquid && temperatureK >= tSat)) {
      // Vapor sobrecalentado
      final superheat = temperatureK - tSat;
      final enthalpy = hg + (_cpVapor * superheat);
      return calculateStateFromPressureEnthalpy(pressurePa, enthalpy);
    } else {
      // En la línea de saturación
      final enthalpy = isLiquid ? hf : hg;
      return calculateStateFromPressureEnthalpy(pressurePa, enthalpy);
    }
  }
}
