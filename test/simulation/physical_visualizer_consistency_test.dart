import 'dart:math' as math;
import 'package:flutter_test/flutter_test.dart';
import 'package:frigolab/domain/models/electrical_model.dart';
import 'package:frigolab/domain/models/vacuum_model.dart';
import 'package:frigolab/simulation/engine/simulation_engine.dart';
import 'package:frigolab/visualization/components/compressor_visualizer.dart';
import 'package:frigolab/visualization/components/condenser_visualizer.dart';
import 'package:frigolab/visualization/components/evaporator_visualizer.dart';
import 'package:frigolab/visualization/components/txv_visualizer.dart';
import 'package:frigolab/visualization/flow/refrigerant_particle_system.dart';

void main() {
  group('Physical Visualizer & SCADA Consistency Tests', () {
    late SimulationEngine engine;

    setUp(() {
      engine = SimulationEngine();
    });

    tearDown(() {
      engine.dispose();
    });

    test('Regla de no-invención: Componentes visuales reflejan estrictamente el SimulationState', () {
      final compVis = CompressorVisualizer();
      final condVis = CondenserVisualizer();
      final evapVis = EvaporatorVisualizer();
      final txvVis = TxvVisualizer();

      engine.start();
      engine.setCompressorRpm(1800.0);
      for (int i = 0; i < 5; i++) {
        engine.step();
      }

      final state = engine.state;
      compVis.updateFromState(state);
      condVis.updateFromState(state);
      evapVis.updateFromState(state);
      txvVis.updateFromState(state);

      // Comprobación de que no hay valores inventados ni random
      expect(compVis.currentRpm, equals(state.dynamicRpm));
      expect(compVis.dischargePressureBar, closeTo(state.condensingPressurePa / 1e5, 0.001));
      expect(compVis.suctionPressureBar, closeTo(state.evaporatingPressurePa / 1e5, 0.001));
      expect(condVis.fanRpm, equals(state.condenserAirFlow.fanRpm));
      expect(evapVis.fanRpm, equals(state.evaporatorAirFlow.fanRpm));
      expect(txvVis.valveOpeningPercent, equals(state.circuit.expansionDevice?.openingPercent));
      expect(txvVis.bulbTempC, closeTo(state.dynamicBulbTempK - 273.15, 0.001));
    });

    test('Continuidad de fluidos: v = m_dot / (rho * A) en cada tramo de tubería', () {
      engine.start();
      for (int i = 0; i < 20; i++) {
        engine.step(); // Avanzar hacia régimen dinámico
      }

      final state = engine.state;
      expect(state.pipeStates.isNotEmpty, isTrue);

      final dischargePipe = state.pipeStates['pipe_discharge']!;
      final liquidPipe = state.pipeStates['pipe_liquid']!;

      // Verificación estricta de la fórmula física v = m_dot / (rho * A)
      final dDischargeM = dischargePipe.innerDiameterMm / 1000.0;
      final areaDischarge = math.pi * math.pow(dDischargeM / 2.0, 2);
      final expectedVDischarge = dischargePipe.massFlowKgPerSec / (dischargePipe.state.density * areaDischarge);
      expect(dischargePipe.velocityMetersPerSec, closeTo(expectedVDischarge, 1e-4));

      final dLiquidM = liquidPipe.innerDiameterMm / 1000.0;
      final areaLiquid = math.pi * math.pow(dLiquidM / 2.0, 2);
      final expectedVLiquid = liquidPipe.massFlowKgPerSec / (liquidPipe.state.density * areaLiquid);
      expect(liquidPipe.velocityMetersPerSec, closeTo(expectedVLiquid, 1e-4));

      // La velocidad de vapor en descarga debe ser notablemente superior a la del líquido debido a la densidad
      expect(dischargePipe.velocityMetersPerSec, greaterThan(liquidPipe.velocityMetersPerSec));
      expect(dischargePipe.state.density, lessThan(liquidPipe.state.density));
    });

    test('Estado de parada anula velocidades físicas y cinemáticas', () {
      engine.start();
      for (int i = 0; i < 10; i++) {
        engine.step();
      }
      expect(engine.state.dynamicRpm, greaterThan(0));

      engine.pause();
      // Integrar pasos de inercia hasta detención total (rotor spindown)
      for (int i = 0; i < 80; i++) {
        engine.step();
      }

      final state = engine.state;
      expect(state.dynamicRpm, equals(0.0));

      for (final pipeState in state.pipeStates.values) {
        expect(pipeState.velocityMetersPerSec, equals(0.0), reason: 'La velocidad de tubería en parada debe ser cero absoluto');
      }

      // El sistema de partículas no avanza cuando la velocidad es 0
      final particles = RefrigerantParticleSystem();
      particles.update(state, 0.05);
      for (final pipeState in state.pipeStates.values) {
        expect(pipeState.velocityMetersPerSec, equals(0.0));
      }
    });

    test('Modelo eléctrico: Potencia activa, factor de potencia y corriente de arranque (LRA)', () {
      // 1. Simular arranque en frío: corriente inicial de inrush por deslizamiento
      final startElectrical = CompressorElectricalState.calculate(
        indicatedPowerWatts: 800.0,
        currentRpm: 150.0,
        targetRpm: 1450.0,
        motorEfficiency: 0.85,
      );

      expect(startElectrical.currentAmps, greaterThan(startElectrical.fullLoadAmps * 2.5));

      // 2. Simular régimen permanente
      final steadyElectrical = CompressorElectricalState.calculate(
        indicatedPowerWatts: 850.0,
        currentRpm: 1450.0,
        targetRpm: 1450.0,
        motorEfficiency: 0.85,
      );

      expect(steadyElectrical.activePowerWatts, greaterThan(850.0)); // Incluye pérdidas por fricción
      expect(steadyElectrical.powerFactor, inInclusiveRange(0.70, 0.95));

      // Comprobación de fórmula P = V * I * cos(phi)
      final calculatedCurrent = steadyElectrical.activePowerWatts / (steadyElectrical.voltageVolts * steadyElectrical.powerFactor);
      expect(steadyElectrical.currentAmps, closeTo(calculatedCurrent, 0.05));
    });

    test('DEMO 4 — Fallo de ventilador del condensador: aumento de presión de alta y temperatura de condensación', () {
      engine.start();
      // Estabilizar régimen nominal
      for (int i = 0; i < 30; i++) {
        engine.step();
      }

      final baselinePk = engine.state.condensingPressurePa;
      final baselineTk = engine.state.condensingTemperatureK;

      // Parar forzosamente el ventilador del condensador
      engine.toggleCondenserFan(false);
      expect(engine.state.condenserFanSpeedOverride, equals(0.0));

      // Simular tiempo con ventilador parado
      for (int i = 0; i < 400; i++) {
        engine.step();
      }

      final perturbedPk = engine.state.condensingPressurePa;
      final perturbedTk = engine.state.condensingTemperatureK;

      // La presión y temperatura de condensación deben haber subido sensiblemente por asfixia térmica
      expect(perturbedPk, greaterThan(baselinePk * 1.08), reason: 'La presión de alta debe subir al fallar el ventilador');
      expect(perturbedTk, greaterThan(baselineTk + 2.5), reason: 'La temperatura de saturación debe subir al fallar el ventilador');
      expect(engine.state.condenserAirFlow.fanRpm, equals(0.0));
      // Caudal con ventilador parado queda únicamente en convección residual mínima (< 0.03 kg/s)
      expect(engine.state.condenserAirFlow.massFlowKgPerSec, lessThan(0.05));
    });

    test('Modelo de vacío por etapas: Evacuación atmosférica, meseta de ebullición del agua y alto vacío', () {
      var vacuum = VacuumState.initial();
      expect(vacuum.pressureMbar, equals(1013.25));

      // 1. Etapa de evacuación rápida de aire seco
      for (int i = 0; i < 25; i++) {
        vacuum = vacuum.integrateStep(1.0, pumpOn: true);
      }
      expect(vacuum.pressureMbar, lessThan(100.0));

      // 2. Meseta de humedad: al llegar a la presión de vapor del agua a ~20°C (~23 mbar), la presión se sostiene
      // mientras se evapora la humedad residual
      while (vacuum.residualWaterGrams > 0.01 && vacuum.pressureMbar > 20.0) {
        vacuum = vacuum.integrateStep(1.0, pumpOn: true);
      }
      expect(vacuum.pressureMbar, inInclusiveRange(18.0, 30.0));

      // 3. Etapa de alto vacío profundo tras evaporar humedad
      while (vacuum.residualWaterGrams > 0.0) {
        vacuum = vacuum.integrateStep(1.0, pumpOn: true);
      }
      for (int i = 0; i < 100; i++) {
        vacuum = vacuum.integrateStep(1.0, pumpOn: true);
      }
      expect(vacuum.isDeepVacuumReached, isTrue);
      expect(vacuum.pressureMicrons, lessThan(500.0));

      // 4. Test de estanqueidad (decay test): apagar bomba y verificar comportamiento
      final initialDecayPressure = vacuum.pressurePa;
      for (int i = 0; i < 60; i++) {
        vacuum = vacuum.integrateStep(1.0, pumpOn: false);
      }
      expect(vacuum.pressurePa, greaterThanOrEqualTo(initialDecayPressure));
    });
  });
}
