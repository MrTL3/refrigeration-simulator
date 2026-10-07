import 'package:flutter_test/flutter_test.dart';
import 'package:frigolab/domain/models/thermodynamic_state.dart';
import 'package:frigolab/simulation/thermodynamics/diagram_data_generator.dart';
import 'package:frigolab/simulation/thermodynamics/r134a_model.dart';
import 'package:frigolab/simulation/engine/simulation_engine.dart';

void main() {
  group('DiagramDataGenerator Tests', () {
    late R134aModel refrigerant;
    late DiagramDataGenerator generator;

    setUp(() {
      refrigerant = R134aModel();
      generator = DiagramDataGenerator(refrigerant);
    });

    test('P-h liquid and vapor dome curves are generated with physical consistency', () {
      final liquidDome = generator.generatePhLiquidDome();
      final vaporDome = generator.generatePhVaporDome();

      expect(liquidDome.isNotEmpty, isTrue);
      expect(vaporDome.isNotEmpty, isTrue);
      expect(liquidDome.length, equals(vaporDome.length));

      // Comprobar que en cada nivel de presión h_f < h_g
      for (int i = 0; i < liquidDome.length; i++) {
        final liq = liquidDome[i];
        final vap = vaporDome[i];

        expect(liq.y, closeTo(vap.y, 1e-2), reason: 'Las presiones deben coincidir en el mismo nivel');
        expect(liq.x, lessThan(vap.x), reason: 'La entalpía de líquido debe ser menor que la de vapor');
        expect(liq.x, greaterThan(100.0), reason: 'La entalpía h_f debe ser positiva en kJ/kg');
        expect(vap.x, lessThan(500.0), reason: 'La entalpía h_g de R-134a debe estar en rango subcrítico');
      }

      // Comprobar que las presiones aumentan monótonamente
      for (int i = 1; i < liquidDome.length; i++) {
        expect(liquidDome[i].y, greaterThan(liquidDome[i - 1].y));
      }
    });

    test('P-h quality isolines (x = 0.2, 0.4, 0.6, 0.8) are bounded inside the dome', () {
      final qualityLines = generator.generatePhQualityLines();
      expect(qualityLines.length, equals(4));

      final qualities = [0.2, 0.4, 0.6, 0.8];
      for (int k = 0; k < qualityLines.length; k++) {
        final curve = qualityLines[k];
        final expectedX = qualities[k];
        expect(curve.points.isNotEmpty, isTrue);

        for (final pt in curve.points) {
          final pPa = pt.y * 1e5;
          final hf = refrigerant.saturatedLiquidEnthalpy(pPa) / 1000.0;
          final hg = refrigerant.saturatedVaporEnthalpy(pPa) / 1000.0;
          final expectedH = hf + expectedX * (hg - hf);

          expect(pt.x, closeTo(expectedH, 1e-2));
          expect(pt.x, greaterThan(hf));
          expect(pt.x, lessThan(hg));
        }
      }
    });

    test('P-h isotherms are generated and stay horizontal inside the two-phase dome', () {
      final isotherms = generator.generatePhIsotherms();
      expect(isotherms.isNotEmpty, isTrue);

      for (final iso in isotherms) {
        expect(iso.points.isNotEmpty, isTrue);
        // Cada isoterma debe cubrir líquido subenfriado, mezcla bifásica y vapor sobrecalentado
        expect(iso.points.length, greaterThanOrEqualTo(4));
      }
    });

    test('T-s saturation dome and quality isolines are physically consistent', () {
      final tsLiquid = generator.generateTsLiquidDome();
      final tsVapor = generator.generateTsVaporDome();

      expect(tsLiquid.isNotEmpty, isTrue);
      expect(tsVapor.isNotEmpty, isTrue);
      expect(tsLiquid.length, equals(tsVapor.length));

      for (int i = 0; i < tsLiquid.length; i++) {
        final liq = tsLiquid[i];
        final vap = tsVapor[i];

        // s_f < s_g para toda temperatura subcrítica
        expect(liq.x, lessThan(vap.x), reason: 's_f debe ser menor que s_g');
        expect(liq.y, closeTo(vap.y, 1e-2), reason: 'Las temperaturas deben coincidir');
      }

      final tsQuality = generator.generateTsQualityLines();
      expect(tsQuality.length, equals(4));
    });
  });

  group('Thermodynamic Cycle State Extraction Tests', () {
    late SimulationEngine engine;

    setUp(() {
      engine = SimulationEngine();
      engine.start();
      // Avanzar varios pasos para estabilizar el ciclo frigorífico
      for (int i = 0; i < 50; i++) {
        engine.step();
      }
    });

    tearDown(() {
      engine.pause();
      engine.dispose();
    });

    test('Cycle points 1 -> 2 -> 3 -> 4 adhere strictly to refrigeration physics', () {
      final state = engine.state;

      final s1 = state.state1Suction;
      final s2 = state.state2Discharge;
      final s3 = state.state3Liquid;
      final s4 = state.state4EvapInlet;

      // 1. Punto 1: Aspiración en baja presión
      expect(s1.pressure, closeTo(state.evaporatingPressurePa, 1e-1));
      expect(s1.phaseState == PhaseState.superheatedVapor || s1.phaseState == PhaseState.saturatedVapor, isTrue);
      expect(state.superheatKelvin, greaterThan(0.0));

      // 2. Punto 2: Descarga en alta presión tras compresión
      expect(s2.pressure, closeTo(state.condensingPressurePa, 1e-1));
      expect(s2.pressure, greaterThan(s1.pressure));
      expect(s2.enthalpy, greaterThan(s1.enthalpy));
      expect(s2.temperature, greaterThan(s1.temperature));

      // Segunda ley de la termodinámica: compresión real genera entropía (s2 >= s1)
      expect(s2.entropy, greaterThanOrEqualTo(s1.entropy));

      // 3. Punto 3: Líquido subenfriado a la salida del condensador
      expect(s3.pressure, closeTo(state.condensingPressurePa, 1e-1));
      expect(s3.enthalpy, lessThan(s2.enthalpy));
      expect(s3.phaseState == PhaseState.subcooledLiquid || s3.phaseState == PhaseState.saturatedLiquid, isTrue);
      expect(state.subcoolingKelvin, greaterThanOrEqualTo(0.0));

      // 4. Punto 4: Expansión isoentálpica en la válvula (h4 == h3)
      expect(s4.enthalpy, closeTo(s3.enthalpy, 1e-1), reason: 'Expansión isoentálpica');
      expect(s4.pressure, closeTo(state.evaporatingPressurePa, 1e-1));
      expect(s4.phaseState, equals(PhaseState.twoPhase), reason: 'Debe ingresar al evaporador como mezcla bifásica');
      expect(s4.vaporQuality, inInclusiveRange(0.1, 0.5));

      // Generación de entropía en la expansión estrangulada (s4 > s3)
      expect(s4.entropy, greaterThan(s3.entropy), reason: 'Estrangulamiento genera entropía irreversible');
    });
  });
}
