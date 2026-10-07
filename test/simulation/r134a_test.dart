import 'package:flutter_test/flutter_test.dart';
import 'package:frigolab/domain/models/thermodynamic_state.dart';
import 'package:frigolab/simulation/thermodynamics/r134a_model.dart';

void main() {
  final r134a = R134aModel();

  group('R134a Thermodynamic Model Tests', () {
    test('Presión de saturación a 0 °C es ~ 2.9 bar', () {
      final pSat0C = r134a.saturationPressure(273.15); // 0 °C
      final pBar = pSat0C / 100000.0;
      expect(pBar, inInclusiveRange(2.85, 3.05));
    });

    test('Presión de saturación a -10 °C es ~ 2.0 bar', () {
      final pSatMinus10 = r134a.saturationPressure(263.15);
      final pBar = pSatMinus10 / 100000.0;
      expect(pBar, inInclusiveRange(1.95, 2.15));
    });

    test('Presión de saturación a +45 °C es ~ 11.6 bar', () {
      final pSat45C = r134a.saturationPressure(318.15);
      final pBar = pSat45C / 100000.0;
      expect(pBar, inInclusiveRange(11.0, 12.5));
    });

    test('Inversión coherente Tsat(Psat(T)) == T', () {
      const originalT = 283.15; // 10 °C
      final pSat = r134a.saturationPressure(originalT);
      final computedT = r134a.saturationTemperature(pSat);
      expect(computedT, closeTo(originalT, 0.05));
    });

    test('Calor latente de vaporización positivo y coherente', () {
      final p = r134a.saturationPressure(273.15);
      final hf = r134a.saturatedLiquidEnthalpy(p);
      final hg = r134a.saturatedVaporEnthalpy(p);
      final hfg = hg - hf;

      expect(hfg, greaterThan(150000.0)); // > 150 kJ/kg
      expect(hfg, lessThan(250000.0));    // < 250 kJ/kg
    });

    test('Cálculo de estado bifásico con calidad de vapor', () {
      final p = 300000.0; // 3 bar
      final hf = r134a.saturatedLiquidEnthalpy(p);
      final hg = r134a.saturatedVaporEnthalpy(p);
      final hMid = hf + 0.35 * (hg - hf); // x = 0.35

      final state = r134a.calculateStateFromPressureEnthalpy(p, hMid);
      expect(state.phaseState, equals(PhaseState.twoPhase));
      expect(state.vaporQuality, closeTo(0.35, 0.01));
    });
  });
}
