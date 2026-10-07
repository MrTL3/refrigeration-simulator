import 'dart:math' as math;
import '../../domain/models/thermodynamic_state.dart';
import '../engine/simulation_state.dart';
import 'circuit_topology_validator.dart';

/// Solver analítico del ciclo frigorífico por compresión de vapor.
/// Realiza el cálculo del punto de operación en régimen cuasiestacionario
/// derivado de balances de materia, energía y ecuaciones de estado del fluido.
class CircuitSolver {
  static SimulationState solveStep({
    required SimulationState currentState,
    required double dt,
  }) {
    final circuit = currentState.circuit;
    final topResult = CircuitTopologyValidator.validate(circuit);

    // Si el circuito no es topológicamente válido o no está en marcha, resolvemos estado de parada
    if (!currentState.isRunning || !topResult.isValid) {
      return _solveStopped(currentState, topResult, dt);
    }

    final comp = circuit.compressor!;
    final cond = circuit.condenser!;
    final exp = circuit.expansionDevice!;
    final evap = circuit.evaporator!;
    final refrigerant = currentState.refrigerant;

    // 1. Temperaturas de saturación en función del ambiente y recinto
    // Lift del condensador proporcional a las RPM y factor de suciedad
    final rpmRatio = (comp.rpm / 2900.0).clamp(0.1, 2.0);
    final foulingMultiplier = 1.0 + (cond.foulingFactor * 0.8);
    final fanCondFactor = cond.fanOperational ? 1.0 : 2.5;
    final deltaTCond = 15.0 * math.sqrt(rpmRatio) * foulingMultiplier * fanCondFactor;
    final tCondK = cond.ambientTemperatureKelvin + deltaTCond;

    // Drop del evaporador proporcional al flujo y apertura de válvula
    final valveOpening = exp.openingPercent.clamp(5.0, 100.0);
    final valveFactor = math.pow(50.0 / valveOpening, 0.35).toDouble();
    final fanEvapFactor = evap.fanOperational ? 1.0 : 0.4;
    final deltaTEvap = (10.0 * math.sqrt(rpmRatio) * valveFactor) / fanEvapFactor;
    final tEvapK = evap.roomTemperatureKelvin - deltaTEvap;

    // 2. Presiones de saturación de alta y baja
    final pCondPa = refrigerant.saturationPressure(tCondK);
    final pEvapPa = refrigerant.saturationPressure(tEvapK);

    // 3. Recalentamiento (Superheat) y Subenfriamiento (Subcooling)
    // Una válvula más cerrada aumenta el superheat; más abierta lo disminuye
    final superheatK = (evap.targetSuperheatKelvin * (50.0 / valveOpening))
        .clamp(1.0, 35.0);
    final subcoolingK = cond.targetSubcoolingKelvin.clamp(0.5, 20.0);

    // 4. Estado 1: Aspiración del compresor (Vapor sobrecalentado a baja presión)
    final t1 = tEvapK + superheatK;
    final p1 = pEvapPa;
    final state1 = refrigerant.calculateStateFromPressureTemperature(
      p1,
      t1,
      isLiquid: false,
    );

    // 5. Caudal másico
    final massFlow = comp.calculateMassFlowKgPerSec(state1.density) *
        math.pow(valveOpening / 50.0, 0.25);

    // 6. Estado 2: Descarga del compresor (Vapor sobrecalentado a alta presión)
    // Compresión politrópica/isentrópica con k ~ 1.13 para R-134a
    const double adiabaticK = 1.13;
    final pressureRatio = comp.calculateCompressionRatio(pCondPa, p1);
    final isentropicWorkSpecific = (adiabaticK / (adiabaticK - 1.0)) *
        (p1 / state1.density) *
        (math.pow(pressureRatio, (adiabaticK - 1.0) / adiabaticK) - 1.0);
    final actualWorkSpecific = isentropicWorkSpecific / comp.isentropicEfficiency;

    final h2 = state1.enthalpy + actualWorkSpecific;
    final p2 = pCondPa;
    final state2 = refrigerant.calculateStateFromPressureEnthalpy(p2, h2);

    // 7. Estado 3: Salida del condensador / Línea de líquido (Líquido subenfriado a alta presión)
    final p3 = pCondPa;
    final t3 = tCondK - subcoolingK;
    final state3 = refrigerant.calculateStateFromPressureTemperature(
      p3,
      t3,
      isLiquid: true,
    );

    // 8. Estado 4: Salida del dispositivo de expansión / Entrada evaporador (Mezcla bifásica a baja presión)
    // Expansión isoentálpica (h4 = h3)
    final p4 = pEvapPa;
    final h4 = state3.enthalpy;
    final state4 = refrigerant.calculateStateFromPressureEnthalpy(p4, h4);

    // 9. Balances energéticos
    final coolingCapacityW = massFlow * (state1.enthalpy - state4.enthalpy);
    final heatingCapacityW = massFlow * (state2.enthalpy - state3.enthalpy);
    final indicatedCompPowerW = massFlow * (state2.enthalpy - state1.enthalpy);
    final electricalPowerW = indicatedCompPowerW / comp.motorEfficiency;
    final cop = indicatedCompPowerW > 0 ? (coolingCapacityW / indicatedCompPowerW) : 0.0;

    // 10. Actualizar componentes con sus variables operativas calculadas
    final updatedComp = comp.copyWith(
      electricalPowerWatts: electricalPowerW,
      indicatedPowerWatts: indicatedCompPowerW,
    );
    final updatedCond = cond.copyWith(
      heatRejectionWatts: heatingCapacityW,
    );
    final updatedEvap = evap.copyWith(
      coolingCapacityWatts: coolingCapacityW,
    );

    // 11. Actualizar nodos de las tuberías
    final updatedPipes = circuit.pipes.map((pipe) {
      ThermodynamicState pipeState;
      if (pipe.fromPortId == 'discharge') {
        pipeState = state2;
      } else if (pipe.fromPortId == 'outlet' && pipe.fromComponentId == cond.id) {
        pipeState = state3;
      } else if (pipe.fromPortId == 'outlet' && pipe.fromComponentId == exp.id) {
        pipeState = state4;
      } else {
        pipeState = state1;
      }

      final updatedNode = pipe.fluidNode.copyWith(
        state: pipeState,
        massFlowKgPerSec: massFlow,
      );
      return pipe.copyWith(fluidNode: updatedNode);
    }).toList();

    final updatedCircuit = circuit.copyWith(
      components: {
        updatedComp.id: updatedComp,
        updatedCond.id: updatedCond,
        exp.id: exp,
        updatedEvap.id: updatedEvap,
      },
      pipes: updatedPipes,
    );

    return currentState.copyWith(
      timeSeconds: currentState.timeSeconds + dt,
      circuit: updatedCircuit,
      topologyResult: topResult,
      state1Suction: state1,
      state2Discharge: state2,
      state3Liquid: state3,
      state4EvapInlet: state4,
      evaporatingPressurePa: pEvapPa,
      condensingPressurePa: pCondPa,
      evaporatingTemperatureK: tEvapK,
      condensingTemperatureK: tCondK,
      superheatKelvin: superheatK,
      subcoolingKelvin: subcoolingK,
      massFlowKgPerSec: massFlow,
      coolingCapacityWatts: coolingCapacityW,
      heatingCapacityWatts: heatingCapacityW,
      compressorPowerWatts: indicatedCompPowerW,
      electricalPowerWatts: electricalPowerW,
      cop: cop,
    );
  }

  /// Resuelve el estado estático de la instalación cuando el compresor está detenido
  static SimulationState _solveStopped(
    SimulationState currentState,
    TopologyValidationResult topResult,
    double dt,
  ) {
    final refrigerant = currentState.refrigerant;
    final cond = currentState.circuit.condenser;
    final tAmb = cond?.ambientTemperatureKelvin ?? 298.15;
    // Presión de ecualización en reposo ~ presión de saturación a temperatura ambiente
    final pEqualized = refrigerant.saturationPressure(tAmb);
    final restingState = refrigerant.calculateStateFromPressureTemperature(
      pEqualized,
      tAmb,
      isLiquid: false,
    );

    return currentState.copyWith(
      timeSeconds: currentState.timeSeconds + dt,
      topologyResult: topResult,
      state1Suction: restingState,
      state2Discharge: restingState,
      state3Liquid: restingState,
      state4EvapInlet: restingState,
      evaporatingPressurePa: pEqualized,
      condensingPressurePa: pEqualized,
      evaporatingTemperatureK: tAmb,
      condensingTemperatureK: tAmb,
      superheatKelvin: 0.0,
      subcoolingKelvin: 0.0,
      massFlowKgPerSec: 0.0,
      coolingCapacityWatts: 0.0,
      heatingCapacityWatts: 0.0,
      compressorPowerWatts: 0.0,
      electricalPowerWatts: 0.0,
      cop: 0.0,
    );
  }
}
