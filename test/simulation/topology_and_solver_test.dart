import 'package:flutter_test/flutter_test.dart';
import 'package:frigolab/domain/models/basic_cycle_preset.dart';
import 'package:frigolab/simulation/engine/simulation_engine.dart';
import 'package:frigolab/simulation/solver/circuit_topology_validator.dart';

void main() {
  group('Circuit Topology & Solver Tests', () {
    test('Preset del ciclo básico tiene lazo cerrado válido', () {
      final circuit = BasicCyclePreset.create();
      final result = CircuitTopologyValidator.validate(circuit);

      expect(result.isValid, isTrue);
      expect(result.isClosedLoop, isTrue);
      expect(result.errors, isEmpty);
    });

    test('Detección de circuito incompleto si falta el condensador', () {
      final circuit = BasicCyclePreset.create();
      final componentsWithoutCond = Map.of(circuit.components)..remove('cond_1');
      final brokenCircuit = circuit.copyWith(components: componentsWithoutCond);

      final result = CircuitTopologyValidator.validate(brokenCircuit);
      expect(result.isValid, isFalse);
      expect(result.errors.any((e) => e.contains('condensador')), isTrue);
    });

    test('Simulación en marcha verifica el Primer Principio de la Termodinámica (Qc ≈ Qe + Wcomp)', () {
      final engine = SimulationEngine();
      engine.start();

      // Ejecutamos varios pasos
      for (int i = 0; i < 5; i++) {
        engine.step();
      }

      final state = engine.state;
      expect(state.isRunning, isTrue);
      expect(state.massFlowKgPerSec, greaterThan(0.0));
      expect(state.coolingCapacityWatts, greaterThan(0.0));
      expect(state.heatingCapacityWatts, greaterThan(0.0));
      expect(state.compressorPowerWatts, greaterThan(0.0));

      // Verificación de balance de energía: Qc = Qe + Wcomp
      final sumEnergy = state.coolingCapacityWatts + state.compressorPowerWatts;
      expect(state.heatingCapacityWatts, closeTo(sumEnergy, 1.0)); // < 1 Watt de discrepancia numérica!

      // Verificación de COP realista para refrigeración positiva
      expect(state.cop, inInclusiveRange(1.5, 6.0));
    });

    test('Simulación detenida iguala presiones y anula caudal', () {
      final engine = SimulationEngine();
      engine.pause();

      final state = engine.state;
      expect(state.isRunning, isFalse);
      expect(state.massFlowKgPerSec, equals(0.0));
      expect(state.coolingCapacityWatts, equals(0.0));
      expect(state.compressorPowerWatts, equals(0.0));
      expect(state.evaporatingPressurePa, equals(state.condensingPressurePa));
    });
  });
}
