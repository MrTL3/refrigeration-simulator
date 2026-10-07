import 'package:flutter_test/flutter_test.dart';
import 'package:frigolab/domain/models/transient_metrics.dart';
import 'package:frigolab/simulation/engine/simulation_engine.dart';

void main() {
  group('DynamicSolver & Transients Tests (Phase 2)', () {
    test('Transitorio de arranque: aceleración inercial y bifurcación de presiones', () {
      final engine = SimulationEngine();
      expect(engine.state.dynamicRpm, equals(0.0));
      expect(engine.state.operationalMode, equals(SystemOperationalMode.off));

      engine.start();

      // Primeros pasos: el motor acelera pero aún está por debajo del régimen
      for (int i = 0; i < 5; i++) {
        engine.step();
      }

      final earlyState = engine.state;
      expect(earlyState.dynamicRpm, greaterThan(0.0));
      expect(earlyState.dynamicRpm, lessThan(2900.0));
      expect(earlyState.operationalMode, isNot(equals(SystemOperationalMode.off)));

      // Tras 80 pasos (~4 segundos), el motor ha alcanzado velocidad nominal y presiones divergen
      for (int i = 0; i < 75; i++) {
        engine.step();
      }

      final runningState = engine.state;
      expect(runningState.dynamicRpm, closeTo(2900.0, 50.0));
      expect(runningState.condensingPressurePa, greaterThan(runningState.evaporatingPressurePa));
      expect(runningState.trendPCond.direction, isNot(equals(TrendDirection.falling)));
      expect(runningState.massFlowKgPerSec, greaterThan(0.0));
      expect(runningState.coolingCapacityWatts, greaterThan(0.0));
    });

    test('Pull-down térmico de la cámara frigorífica con balances de energía', () {
      final engine = SimulationEngine();
      engine.start();

      // Permitimos que la batería evaporadora enfríe y alcance régimen de absorción (80 pasos ~ 4s)
      for (int i = 0; i < 80; i++) {
        engine.step();
      }
      final establishedRoomT = engine.state.coldRoom.temperatureKelvin;

      // Continuamos la refrigeración durante 120 pasos adicionales (~6s de absorción activa)
      for (int i = 0; i < 120; i++) {
        engine.step();
      }

      final cooledRoomT = engine.state.coldRoom.temperatureKelvin;
      // La temperatura de la cámara desciende sostenidamente bajo la extracción de calor
      expect(cooledRoomT, lessThan(establishedRoomT));
      expect(engine.state.trendTRoom.direction, equals(TrendDirection.falling));
    });

    test('Ciclo de control termostático: corte por baja temperatura y rearranque por histéresis', () {
      final engine = SimulationEngine();
      // Configuramos termostato a 10.0 °C con 2.0 K de histéresis (corte a 10.0 °C, arranque a 12.0 °C)
      engine.setThermostatEnabled(true);
      engine.setThermostatSetpoint(10.0);
      engine.setThermostatHysteresis(2.0);

      // Ponemos la temperatura inicial de la cámara a 10.5 °C (dentro de la banda de enfriamiento)
      engine.setColdRoomTemperature(283.65); // 10.5 °C

      engine.start();
      expect(engine.state.thermostat.isCallForCooling, isTrue);

      // Forzamos la cámara a descender por debajo de consigna (9.5 °C < 10.0 °C)
      engine.setColdRoomTemperature(282.65); // 9.5 °C
      engine.step();

      // El termostato debe cortar la demanda de frío
      expect(engine.state.thermostat.isCallForCooling, isFalse);

      // Damos varios pasos y verificamos que el compresor frena
      for (int i = 0; i < 40; i++) {
        engine.step();
      }
      expect(engine.state.dynamicRpm, lessThan(200.0));

      // Ahora simulamos calentamiento por carga térmica por encima de cut-in (12.5 °C > 12.0 °C)
      engine.setColdRoomTemperature(285.65); // 12.5 °C
      engine.step();

      // El termostato debe reactivar la demanda de frío
      expect(engine.state.thermostat.isCallForCooling, isTrue);

      // Damos pasos y comprobamos aceleración
      for (int i = 0; i < 30; i++) {
        engine.step();
      }
      expect(engine.state.dynamicRpm, greaterThan(1000.0));
    });

    test('Robustez numérica ante perturbaciones extremas: sin NaNs ni Infs', () {
      final engine = SimulationEngine();
      engine.start();

      // Perturbaciones secuenciales agresivas
      engine.setCompressorRpm(4500.0);
      for (int i = 0; i < 30; i++) {
        engine.step();
      }

      engine.setAmbientTemperature(323.15); // 50 °C ola de calor extrema
      for (int i = 0; i < 30; i++) {
        engine.step();
      }

      engine.setTxvOpening(12.0); // Estrangulamiento severo
      for (int i = 0; i < 30; i++) {
        engine.step();
      }

      final s = engine.state;
      expect(s.condensingPressurePa.isFinite, isTrue);
      expect(s.evaporatingPressurePa.isFinite, isTrue);
      expect(s.massFlowKgPerSec.isFinite, isTrue);
      expect(s.coolingCapacityWatts.isFinite, isTrue);
      expect(s.compressorPowerWatts.isFinite, isTrue);
      expect(s.cop.isFinite, isTrue);
      expect(s.superheatKelvin.isFinite, isTrue);
      expect(s.subcoolingKelvin.isFinite, isTrue);

      expect(s.condensingPressurePa, greaterThan(0.0));
      expect(s.evaporatingPressurePa, greaterThan(0.0));
    });
  });
}
