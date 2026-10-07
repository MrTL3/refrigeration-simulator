import 'dart:math' as math;
import '../../domain/components/compressor_component.dart';
import '../../domain/components/condenser_component.dart';
import '../../domain/components/expansion_device_component.dart';
import '../../domain/components/evaporator_component.dart';
import '../../domain/models/cold_room_model.dart';
import '../../domain/models/thermostat_model.dart';
import '../../domain/models/transient_metrics.dart';
import '../engine/simulation_state.dart';
import '../thermodynamics/refrigerant_model.dart';

/// Solver termodinámico dinámico de integración temporal (EDOs a dt = 0.05 s / 20 Hz).
/// Modela capacitancias térmicas, acumulación de masa, transitorios de arranque/parada,
/// bulbo de la TXV y cámara frigorífica con control termostático.
class DynamicSolver {
  // Constantes físicas y térmicas de diseño
  static const double _cEvap = 450.0;     // Capacitancia térmica efectiva evaporador (J/K) -> tau ~ 2.4 s
  static const double _cCond = 700.0;     // Capacitancia térmica efectiva condensador (J/K) -> tau ~ 3.0 s
  static const double _tauBulb = 3.5;     // Constante de tiempo del bulbo TXV (s)
  static const double _tauMotor = 0.8;    // Constante de aceleración del motor (s)
  static const double _cvTxv = 5.5e-7;    // Coeficiente de orificio de la TXV (m^2)

  static SimulationState integrateStep({
    required SimulationState currentState,
    required double dt,
  }) {
    final circuit = currentState.circuit;
    final ref = currentState.refrigerant;
    final topResult = currentState.topologyResult;

    if (!topResult.isValid) {
      return currentState.copyWith(
        timeSeconds: currentState.timeSeconds + dt,
        operationalMode: SystemOperationalMode.off,
      );
    }

    final comp = circuit.compressor!;
    final cond = circuit.condenser!;
    final exp = circuit.expansionDevice!;
    final evap = circuit.evaporator!;
    final coldRoom = currentState.coldRoom;
    final thermostat = currentState.thermostat;

    // 1. Evaluación de control de termostato
    final updatedThermostat = thermostat.update(coldRoom.temperatureKelvin);
    final isDemandingRun = currentState.isRunning && updatedThermostat.isCallForCooling;

    // 2. Dinámica de velocidad de giro del compresor (RPM)
    final targetRpm = isDemandingRun ? comp.rpm : 0.0;
    double currentRpm = currentState.dynamicRpm;
    if ((currentRpm - targetRpm).abs() > 1.0) {
      final dRpm = (targetRpm - currentRpm) / (isDemandingRun ? _tauMotor : 0.5);
      currentRpm = (currentRpm + dRpm * dt).clamp(0.0, 4500.0);
    } else {
      currentRpm = targetRpm;
    }

    // 3. Temperaturas de evaporador y condensador actuales (variables de estado)
    double tEvap = currentState.evaporatingTemperatureK;
    double tCond = currentState.condensingTemperatureK;
    double tRoom = coldRoom.temperatureKelvin;
    double txvOpening = exp.openingPercent;

    final tAmb = cond.ambientTemperatureKelvin;

    // Si el compresor está completamente parado, las temperaturas y presiones tienden a ecualizar con el ambiente
    if (currentRpm < 10.0 && !isDemandingRun) {
      return _integrateStoppedStep(
        currentState: currentState,
        comp: comp,
        cond: cond,
        exp: exp,
        evap: evap,
        coldRoom: coldRoom,
        thermostat: updatedThermostat,
        ref: ref,
        dt: dt,
        tAmb: tAmb,
      );
    }

    // 4. Presiones de saturación derivadas de las temperaturas de las baterías
    final pEvap = ref.saturationPressure(tEvap);
    final pCond = ref.saturationPressure(tCond);

    // 5. Estado 1: Aspiración del compresor
    final superheat = currentState.superheatKelvin.clamp(1.0, 35.0);
    final t1 = tEvap + superheat;
    final p1 = pEvap;
    final state1 = ref.calculateStateFromPressureTemperature(p1, t1, isLiquid: false);

    // 6. Eficiencia volumétrica física (re-expansión de volumen nocivo)
    const double clearanceRatio = 0.045; // 4.5% espacio nocivo
    const double adiabaticK = 1.13;
    final pressureRatio = comp.calculateCompressionRatio(pCond, p1);
    final reexpansion = clearanceRatio * (math.pow(pressureRatio, 1.0 / adiabaticK) - 1.0);
    final etaVol = ((1.0 - reexpansion) * 0.82).clamp(0.15, 0.88);

    // Caudal másico bombeado por el compresor (kg/s)
    final displacementM3 = comp.displacementCm3 * 1e-6;
    final massFlowComp = displacementM3 * (currentRpm / 60.0) * state1.density * etaVol;

    // 7. Estado 2: Descarga del compresor
    final isentropicWork = (adiabaticK / (adiabaticK - 1.0)) *
        (p1 / state1.density) *
        (math.pow(pressureRatio, (adiabaticK - 1.0) / adiabaticK) - 1.0);
    final actualWork = isentropicWork / comp.isentropicEfficiency;
    final h2 = state1.enthalpy + actualWork;
    final p2 = pCond;
    final state2 = ref.calculateStateFromPressureEnthalpy(p2, h2);

    // 8. Estado 3: Salida del condensador / Líquido subenfriado
    final subcooling = cond.targetSubcoolingKelvin.clamp(0.5, 15.0);
    final t3 = tCond - subcooling;
    final p3 = pCond;
    final state3 = ref.calculateStateFromPressureTemperature(p3, t3, isLiquid: true);

    // 9. Caudal másico a través de la válvula TXV
    final deltaPValve = math.max(1000.0, pCond - pEvap);
    final massFlowTxv = _cvTxv * (txvOpening / 100.0) * math.sqrt(2.0 * state3.density * deltaPValve);

    // 10. Dinámica del bulbo termostático y modulación automática de la TXV
    double bulbTemp = currentState.dynamicBulbTempK;
    bulbTemp += ((t1 - bulbTemp) / _tauBulb) * dt;

    if (exp.isAutomatic) {
      // El bulbo empuja a abrir, el resorte ajusta el recalentamiento objetivo
      final targetBulbTemp = tEvap + exp.targetSuperheatKelvin;
      final errorTemp = bulbTemp - targetBulbTemp;
      // Modulación proporcional suave
      txvOpening = (txvOpening + (errorTemp * 0.8 * dt)).clamp(10.0, 95.0);
    }

    // 11. Estado 4: Expansión isentálpica (h4 = h3)
    final p4 = pEvap;
    final h4 = state3.enthalpy;
    final state4 = ref.calculateStateFromPressureEnthalpy(p4, h4);

    // 12. Balances energéticos en tiempo real
    // En régimen dinámico acoplado, el caudal másico en evaporación está condicionado
    // por la apertura del orificio de la TXV y la aspiración del compresor:
    final effectiveMassFlow = math.max(0.0, math.min(massFlowComp, massFlowTxv * 1.5));
    final qCoolingRefW = effectiveMassFlow * (state1.enthalpy - state4.enthalpy);
    final qHeatingRefW = effectiveMassFlow * (state2.enthalpy - state3.enthalpy);
    final wIndicatedW = effectiveMassFlow * (state2.enthalpy - state1.enthalpy);
    final wElectricW = wIndicatedW / comp.motorEfficiency;
    final cop = wIndicatedW > 0 ? (qCoolingRefW / wIndicatedW) : 0.0;

    // 13. Transferencia de calor en los intercambiadores (W)
    final qEvapAirW = evap.effectiveUA * (tRoom - tEvap);
    final qCondAirW = cond.effectiveUA * (tCond - tAmb);

    // 14. Ecuaciones Diferenciales Ordinarias (EDOs) de temperatura de baterías
    // dT_evap/dt = (Q_evap_air - Q_ref_evap) / C_evap
    final dtEvapRate = (qEvapAirW - qCoolingRefW) / _cEvap;
    tEvap = (tEvap + dtEvapRate * dt).clamp(230.0, 310.0);

    // dT_cond/dt = (Q_ref_cond - Q_cond_air) / C_cond
    final dtCondRate = (qHeatingRefW - qCondAirW) / _cCond;
    tCond = (tCond + dtCondRate * dt).clamp(270.0, 355.0);

    // 15. EDO de la Cámara Frigorífica
    // dT_room/dt = (Q_load - Q_evap_air) / C_room
    final qRoomLoadW = coldRoom.totalHeatLoadWatts(tAmb);
    final dtRoomRate = (qRoomLoadW - qEvapAirW) / coldRoom.thermalCapacitanceJoulesPerKelvin;
    tRoom = (tRoom + dtRoomRate * dt).clamp(240.0, 320.0);

    // 16. Dinámica del Superheat real en función del acoplamiento TXV / Compresor:
    // Si la TXV se estrangula frente a la aspiración, la batería se desalimenta y el recalentamiento sube
    final targetSuperheat = (exp.targetSuperheatKelvin * (massFlowComp / math.max(0.0001, massFlowTxv))).clamp(2.0, 32.0);
    final dynamicSuperheat = (superheat + ((targetSuperheat - superheat) / 5.0) * dt).clamp(1.0, 35.0);

    // 17. Determinación del Modo Operacional (Steady State Detector)
    final isPSteady = (pCond - currentState.condensingPressurePa).abs() / dt < 800.0;
    final isTSteady = dtEvapRate.abs() < 0.02 && dtCondRate.abs() < 0.02;
    final isRpmRamped = (currentRpm - targetRpm).abs() < 10.0;

    SystemOperationalMode opMode;
    if (currentRpm < 500.0) {
      opMode = SystemOperationalMode.starting;
    } else if (isPSteady && isTSteady && isRpmRamped) {
      opMode = SystemOperationalMode.steadyState;
    } else {
      opMode = SystemOperationalMode.transient;
    }

    // 18. Actualización de tendencias temporales
    final trendPEvap = MetricTrend.calculate(
      current: pEvap,
      previous: currentState.evaporatingPressurePa,
      dt: dt,
      steadyTolerance: 150.0,
    );
    final trendPCond = MetricTrend.calculate(
      current: pCond,
      previous: currentState.condensingPressurePa,
      dt: dt,
      steadyTolerance: 200.0,
    );
    final trendTRoom = MetricTrend.calculate(
      current: tRoom,
      previous: coldRoom.temperatureKelvin,
      dt: dt,
      steadyTolerance: 0.005,
    );

    // 19. Muestreo temporal para gráficas (máximo 120 puntos de histórico)
    final updatedHistory = List<TimeSeriesSample>.from(currentState.timeSeriesHistory);
    // Agregamos una muestra cada 0.5 s para eficiencia de memoria
    if (currentState.timeSeconds - (currentState.lastSampleTime ?? -1.0) >= 0.5) {
      updatedHistory.add(
        TimeSeriesSample(
          timeSeconds: currentState.timeSeconds + dt,
          evaporatingPressureBar: pEvap / 100000.0,
          condensingPressureBar: pCond / 100000.0,
          suctionTemperatureCelsius: t1 - 273.15,
          dischargeTemperatureCelsius: state2.temperature - 273.15,
          roomTemperatureCelsius: tRoom - 273.15,
          massFlowGramsPerSec: effectiveMassFlow * 1000.0,
          coolingCapacityKw: qCoolingRefW / 1000.0,
          cop: cop,
        ),
      );
      if (updatedHistory.length > 150) {
        updatedHistory.removeAt(0);
      }
    }

    // 20. Actualización de componentes del circuito
    final updatedComp = comp.copyWith(
      electricalPowerWatts: wElectricW,
      indicatedPowerWatts: wIndicatedW,
    );
    final updatedCond = cond.copyWith(
      heatRejectionWatts: qHeatingRefW,
    );
    final updatedExp = exp.copyWith(
      openingPercent: txvOpening,
    );
    final updatedEvap = evap.copyWith(
      coolingCapacityWatts: qCoolingRefW,
      roomTemperatureKelvin: tRoom,
    );

    final updatedCircuit = circuit.copyWith(
      components: {
        updatedComp.id: updatedComp,
        updatedCond.id: updatedCond,
        updatedExp.id: updatedExp,
        updatedEvap.id: updatedEvap,
      },
    );

    final updatedColdRoom = coldRoom.copyWith(
      temperatureKelvin: tRoom,
    );

    return currentState.copyWith(
      timeSeconds: currentState.timeSeconds + dt,
      circuit: updatedCircuit,
      coldRoom: updatedColdRoom,
      thermostat: updatedThermostat,
      operationalMode: opMode,
      dynamicRpm: currentRpm,
      dynamicBulbTempK: bulbTemp,
      state1Suction: state1,
      state2Discharge: state2,
      state3Liquid: state3,
      state4EvapInlet: state4,
      evaporatingPressurePa: pEvap,
      condensingPressurePa: pCond,
      evaporatingTemperatureK: tEvap,
      condensingTemperatureK: tCond,
      superheatKelvin: dynamicSuperheat,
      subcoolingKelvin: subcooling,
      massFlowKgPerSec: effectiveMassFlow,
      coolingCapacityWatts: qCoolingRefW,
      heatingCapacityWatts: qHeatingRefW,
      compressorPowerWatts: wIndicatedW,
      electricalPowerWatts: wElectricW,
      cop: cop,
      trendPEvap: trendPEvap,
      trendPCond: trendPCond,
      trendTRoom: trendTRoom,
      timeSeriesHistory: updatedHistory,
      lastSampleTime: (currentState.timeSeconds - (currentState.lastSampleTime ?? -1.0) >= 0.5)
          ? (currentState.timeSeconds + dt)
          : currentState.lastSampleTime,
    );
  }

  /// Integra el comportamiento dinámico durante la parada (ecualización gradual y calentamiento del recinto)
  static SimulationState _integrateStoppedStep({
    required SimulationState currentState,
    required CompressorComponent comp,
    required CondenserComponent cond,
    required ExpansionDeviceComponent exp,
    required EvaporatorComponent evap,
    required ColdRoomModel coldRoom,
    required ThermostatModel thermostat,
    required RefrigerantModel ref,
    required double dt,
    required double tAmb,
  }) {
    // 1. Ecualización lenta de presiones entre alta y baja a través del orificio de la TXV
    double pEvap = currentState.evaporatingPressurePa;
    double pCond = currentState.condensingPressurePa;
    final deltaP = pCond - pEvap;

    if (deltaP.abs() > 2000.0) {
      // Caudal de ecualización en reposo
      final equalizationFlow = deltaP * 0.08 * dt;
      pCond -= equalizationFlow;
      pEvap += equalizationFlow;
    } else {
      pCond = pEvap;
    }

    // 2. Temperaturas de saturación siguen las presiones en reposo
    final tEvap = ref.saturationTemperature(pEvap);
    final tCond = ref.saturationTemperature(pCond);

    // 3. La cámara frigorífica se calienta lentamente por transmisión ambiental
    final qLoad = coldRoom.totalHeatLoadWatts(tAmb);
    final dtRoom = (qLoad / coldRoom.thermalCapacitanceJoulesPerKelvin) * dt;
    final tRoom = coldRoom.temperatureKelvin + dtRoom;

    final updatedColdRoom = coldRoom.copyWith(temperatureKelvin: tRoom);
    final restingState = ref.calculateStateFromPressureTemperature(pEvap, tAmb, isLiquid: false);

    final updatedComp = comp.copyWith(
      electricalPowerWatts: 0.0,
      indicatedPowerWatts: 0.0,
    );
    final updatedCond = cond.copyWith(heatRejectionWatts: 0.0);
    final updatedEvap = evap.copyWith(coolingCapacityWatts: 0.0, roomTemperatureKelvin: tRoom);

    final updatedCircuit = currentState.circuit.copyWith(
      components: {
        updatedComp.id: updatedComp,
        updatedCond.id: updatedCond,
        exp.id: exp,
        updatedEvap.id: updatedEvap,
      },
    );

    return currentState.copyWith(
      timeSeconds: currentState.timeSeconds + dt,
      circuit: updatedCircuit,
      coldRoom: updatedColdRoom,
      thermostat: thermostat,
      operationalMode: (deltaP.abs() > 5000.0)
          ? SystemOperationalMode.stopping
          : SystemOperationalMode.off,
      dynamicRpm: 0.0,
      state1Suction: restingState,
      state2Discharge: restingState,
      state3Liquid: restingState,
      state4EvapInlet: restingState,
      evaporatingPressurePa: pEvap,
      condensingPressurePa: pCond,
      evaporatingTemperatureK: tEvap,
      condensingTemperatureK: tCond,
      superheatKelvin: 0.0,
      subcoolingKelvin: 0.0,
      massFlowKgPerSec: 0.0,
      coolingCapacityWatts: 0.0,
      heatingCapacityWatts: 0.0,
      compressorPowerWatts: 0.0,
      electricalPowerWatts: 0.0,
      cop: 0.0,
      trendPEvap: MetricTrend.initial(pEvap),
      trendPCond: MetricTrend.initial(pCond),
      trendTRoom: MetricTrend.calculate(
        current: tRoom,
        previous: coldRoom.temperatureKelvin,
        dt: dt,
        steadyTolerance: 0.005,
      ),
    );
  }
}
