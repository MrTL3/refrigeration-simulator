import 'package:flutter_test/flutter_test.dart';
import 'package:frigolab/domain/models/educational_experiment.dart';
import 'package:frigolab/simulation/engine/simulation_engine.dart';

void main() {
  group('Educational Experiments Tests (Phase 2)', () {
    test('Experimento 1: Aumento de velocidad de compresión (RPM) incrementa caudal y potencia', () {
      final engine = SimulationEngine();
      engine.start();

      // Permitimos que alcance régimen nominal a 2900 RPM
      for (int i = 0; i < 80; i++) {
        engine.step();
      }
      final nominalFlow = engine.state.massFlowKgPerSec;
      final nominalPower = engine.state.compressorPowerWatts;

      // Cargamos el experimento 1 y aplicamos 3800 RPM
      final exp = EducationalExperiment.builtInExperiments[0];
      engine.startExperiment(exp);
      engine.setCompressorRpm(3800.0);

      // Simulamos la aceleración
      for (int i = 0; i < 60; i++) {
        engine.step();
      }

      final boostedFlow = engine.state.massFlowKgPerSec;
      final boostedPower = engine.state.compressorPowerWatts;

      expect(boostedFlow, greaterThan(nominalFlow));
      expect(boostedPower, greaterThan(nominalPower));
      expect(engine.state.dynamicRpm, closeTo(3800.0, 50.0));
    });

    test('Experimento 2: Incremento de temperatura ambiente eleva P_k y reduce COP', () {
      final engine = SimulationEngine();
      engine.start();

      // Régimen a 25 °C ambiente
      for (int i = 0; i < 80; i++) {
        engine.step();
      }
      final initialPk = engine.state.condensingPressurePa;
      final initialCop = engine.state.cop;

      // Cargamos el experimento 2 y elevamos ambiente a 42 °C (315.15 K)
      final exp = EducationalExperiment.builtInExperiments[1];
      engine.startExperiment(exp);
      engine.setAmbientTemperature(315.15);

      for (int i = 0; i < 80; i++) {
        engine.step();
      }

      final elevatedPk = engine.state.condensingPressurePa;
      final reducedCop = engine.state.cop;

      expect(elevatedPk, greaterThan(initialPk));
      expect(reducedCop, lessThan(initialCop));
    });

    test('Experimento 3: Estrangulamiento de la TXV provoca subida de Superheat y caída de caudal', () {
      final engine = SimulationEngine();
      engine.start();

      // Régimen a apertura nominal (45%)
      for (int i = 0; i < 80; i++) {
        engine.step();
      }
      final nominalFlow = engine.state.massFlowKgPerSec;
      final nominalSuperheat = engine.state.superheatKelvin;

      // Cargamos el experimento 3 y cerramos la válvula al 18%
      final exp = EducationalExperiment.builtInExperiments[2];
      engine.startExperiment(exp);
      engine.setTxvOpening(18.0);

      for (int i = 0; i < 80; i++) {
        engine.step();
      }

      final throttledFlow = engine.state.massFlowKgPerSec;
      final throttledSuperheat = engine.state.superheatKelvin;

      // Comprobamos la física del estrangulamiento: menor caudal y batería desalimentada (mayor recalentamiento)
      expect(throttledFlow, lessThan(nominalFlow));
      expect(throttledSuperheat, greaterThan(nominalSuperheat));
    });

    test('Workflow del experimento: inicio y finalización de ensayo guiado', () {
      final engine = SimulationEngine();
      expect(engine.activeExperiment, isNull);

      final exp = EducationalExperiment.builtInExperiments[0];
      engine.startExperiment(exp);
      expect(engine.activeExperiment?.id, equals(exp.id));

      engine.clearActiveExperiment();
      expect(engine.activeExperiment, isNull);
    });
  });
}
