import '../../domain/models/circuit.dart';
import '../../domain/models/thermodynamic_state.dart';
import '../solver/circuit_topology_validator.dart';
import '../thermodynamics/refrigerant_model.dart';
import '../thermodynamics/r134a_model.dart';

/// Estado global inmutable de la simulación frigorífica en un instante de tiempo t.
class SimulationState {
  final double timeSeconds;
  final bool isRunning;
  final Circuit circuit;
  final RefrigerantModel refrigerant;
  final TopologyValidationResult topologyResult;

  // Los 4 estados termodinámicos de referencia del ciclo básico
  final ThermodynamicState state1Suction;
  final ThermodynamicState state2Discharge;
  final ThermodynamicState state3Liquid;
  final ThermodynamicState state4EvapInlet;

  // Variables operativas consolidadas
  final double evaporatingPressurePa;
  final double condensingPressurePa;
  final double evaporatingTemperatureK;
  final double condensingTemperatureK;
  final double superheatKelvin;
  final double subcoolingKelvin;
  final double massFlowKgPerSec;
  final double coolingCapacityWatts;
  final double heatingCapacityWatts;
  final double compressorPowerWatts;
  final double electricalPowerWatts;
  final double cop;

  const SimulationState({
    required this.timeSeconds,
    required this.isRunning,
    required this.circuit,
    required this.refrigerant,
    required this.topologyResult,
    required this.state1Suction,
    required this.state2Discharge,
    required this.state3Liquid,
    required this.state4EvapInlet,
    required this.evaporatingPressurePa,
    required this.condensingPressurePa,
    required this.evaporatingTemperatureK,
    required this.condensingTemperatureK,
    required this.superheatKelvin,
    required this.subcoolingKelvin,
    required this.massFlowKgPerSec,
    required this.coolingCapacityWatts,
    required this.heatingCapacityWatts,
    required this.compressorPowerWatts,
    required this.electricalPowerWatts,
    required this.cop,
  });

  /// Estado inicial por defecto de referencia
  factory SimulationState.initial(Circuit defaultCircuit) {
    final ref = R134aModel();
    final topResult = CircuitTopologyValidator.validate(defaultCircuit);
    final zeroState = ThermodynamicState.zero();

    return SimulationState(
      timeSeconds: 0.0,
      isRunning: false,
      circuit: defaultCircuit,
      refrigerant: ref,
      topologyResult: topResult,
      state1Suction: zeroState,
      state2Discharge: zeroState,
      state3Liquid: zeroState,
      state4EvapInlet: zeroState,
      evaporatingPressurePa: 101325.0,
      condensingPressurePa: 101325.0,
      evaporatingTemperatureK: 273.15,
      condensingTemperatureK: 273.15,
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

  SimulationState copyWith({
    double? timeSeconds,
    bool? isRunning,
    Circuit? circuit,
    RefrigerantModel? refrigerant,
    TopologyValidationResult? topologyResult,
    ThermodynamicState? state1Suction,
    ThermodynamicState? state2Discharge,
    ThermodynamicState? state3Liquid,
    ThermodynamicState? state4EvapInlet,
    double? evaporatingPressurePa,
    double? condensingPressurePa,
    double? evaporatingTemperatureK,
    double? condensingTemperatureK,
    double? superheatKelvin,
    double? subcoolingKelvin,
    double? massFlowKgPerSec,
    double? coolingCapacityWatts,
    double? heatingCapacityWatts,
    double? compressorPowerWatts,
    double? electricalPowerWatts,
    double? cop,
  }) {
    return SimulationState(
      timeSeconds: timeSeconds ?? this.timeSeconds,
      isRunning: isRunning ?? this.isRunning,
      circuit: circuit ?? this.circuit,
      refrigerant: refrigerant ?? this.refrigerant,
      topologyResult: topologyResult ?? this.topologyResult,
      state1Suction: state1Suction ?? this.state1Suction,
      state2Discharge: state2Discharge ?? this.state2Discharge,
      state3Liquid: state3Liquid ?? this.state3Liquid,
      state4EvapInlet: state4EvapInlet ?? this.state4EvapInlet,
      evaporatingPressurePa: evaporatingPressurePa ?? this.evaporatingPressurePa,
      condensingPressurePa: condensingPressurePa ?? this.condensingPressurePa,
      evaporatingTemperatureK: evaporatingTemperatureK ?? this.evaporatingTemperatureK,
      condensingTemperatureK: condensingTemperatureK ?? this.condensingTemperatureK,
      superheatKelvin: superheatKelvin ?? this.superheatKelvin,
      subcoolingKelvin: subcoolingKelvin ?? this.subcoolingKelvin,
      massFlowKgPerSec: massFlowKgPerSec ?? this.massFlowKgPerSec,
      coolingCapacityWatts: coolingCapacityWatts ?? this.coolingCapacityWatts,
      heatingCapacityWatts: heatingCapacityWatts ?? this.heatingCapacityWatts,
      compressorPowerWatts: compressorPowerWatts ?? this.compressorPowerWatts,
      electricalPowerWatts: electricalPowerWatts ?? this.electricalPowerWatts,
      cop: cop ?? this.cop,
    );
  }
}
