import 'package:flutter_test/flutter_test.dart';
import 'package:frigolab/core/units/pressure_unit.dart';
import 'package:frigolab/core/units/temperature_unit.dart';
import 'package:frigolab/core/units/power_unit.dart';
import 'package:frigolab/core/units/mass_flow_unit.dart';

void main() {
  group('PressureUnit Tests', () {
    test('Conversión de bar a Pa y viceversa', () {
      const pBar = 2.5; // 2.5 bar
      final pPa = PressureUnit.bar.toPascals(pBar);
      expect(pPa, equals(250000.0));

      final backToBar = PressureUnit.bar.fromPascals(pPa);
      expect(backToBar, closeTo(2.5, 1e-6));
    });

    test('Conversión de PSI a Pa', () {
      const pPsi = 14.50377; // ~ 1 bar
      final pPa = PressureUnit.psi.toPascals(pPsi);
      expect(pPa, closeTo(100000.0, 10.0));
    });

    test('Presión manométrica (gauge) vs absoluta', () {
      // 0 bar manométricos = 101325 Pa absolutos
      final pAbs = PressureUnit.bar.toPascals(0.0, isGauge: true);
      expect(pAbs, equals(101325.0));

      final pGauge = PressureUnit.bar.fromPascals(101325.0, toGauge: true);
      expect(pGauge, closeTo(0.0, 1e-6));
    });
  });

  group('TemperatureUnit Tests', () {
    test('Conversión Celsius a Kelvin y viceversa', () {
      const tC = 0.0;
      final tK = TemperatureUnit.celsius.toKelvin(tC);
      expect(tK, equals(273.15));

      final backToC = TemperatureUnit.celsius.fromKelvin(tK);
      expect(backToC, closeTo(0.0, 1e-6));
    });

    test('Conversión Fahrenheit a Celsius', () {
      const tF = 32.0; // 32 °F = 0 °C
      final tK = TemperatureUnit.fahrenheit.toKelvin(tF);
      expect(tK, closeTo(273.15, 1e-4));

      final tC = TemperatureUnit.celsius.fromKelvin(tK);
      expect(tC, closeTo(0.0, 1e-4));
    });

    test('Diferenciales térmicos ΔT', () {
      const deltaK = 10.0;
      expect(TemperatureUnit.celsius.convertDelta(deltaK), equals(10.0));
      expect(TemperatureUnit.fahrenheit.convertDelta(deltaK), equals(18.0));
    });
  });

  group('PowerUnit & MassFlowUnit Tests', () {
    test('Conversión de kW a Watts', () {
      expect(PowerUnit.kilowatt.toWatts(3.5), equals(3500.0));
      expect(PowerUnit.kilowatt.fromWatts(3500.0), equals(3.5));
    });

    test('Conversión de Caudal Másico kg/h a kg/s', () {
      const flowKgPerHour = 360.0; // 360 kg/h = 0.1 kg/s
      final flowKgPerSec = MassFlowUnit.kilogramsPerHour.toKgPerSecond(flowKgPerHour);
      expect(flowKgPerSec, closeTo(0.1, 1e-6));
    });
  });
}
