import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../domain/models/basic_cycle_preset.dart';
import '../../domain/models/circuit.dart';
import '../../domain/models/educational_experiment.dart';
import '../solver/dynamic_solver.dart';
import 'simulation_state.dart';

/// Motor central de simulación física dinámica de FrigoLab.
/// Ejecuta la integración temporal numérica continua a 20 Hz (dt = 0.05 s)
/// desacoplado del bucle de pintado de la interfaz.
class SimulationEngine extends ChangeNotifier {
  late SimulationState _state;
  Timer? _ticker;
  EducationalExperiment? _activeExperiment;

  /// Paso de tiempo canónico de integración física (50 ms = 20 Hz)
  static const double physicsTimeStepSeconds = 0.05;

  SimulationEngine({Circuit? initialCircuit}) {
    final circuit = initialCircuit ?? BasicCyclePreset.create();
    _state = SimulationState.initial(circuit);
    // Realizamos un primer pase para asentar condiciones iniciales
    _state = DynamicSolver.integrateStep(
      currentState: _state,
      dt: 0.0,
    );
  }

  SimulationState get state => _state;
  bool get isRunning => _state.isRunning;
  EducationalExperiment? get activeExperiment => _activeExperiment;

  /// Arranca la simulación física continua
  void start() {
    if (_state.isRunning) return;

    _state = _state.copyWith(isRunning: true);
    _ticker?.cancel();
    _ticker = Timer.periodic(
      const Duration(milliseconds: 50),
      (_) => _onTick(),
    );
    notifyListeners();
  }

  /// Pausa la simulación física
  void pause() {
    if (!_state.isRunning) return;

    _ticker?.cancel();
    _ticker = null;
    _state = _state.copyWith(isRunning: false);
    // Un pase para actualizar estado de detención
    _state = DynamicSolver.integrateStep(
      currentState: _state,
      dt: 0.0,
    );
    notifyListeners();
  }

  /// Ejecuta un único paso temporal manual
  void step() {
    _onTick();
  }

  /// Restablece la simulación al circuito inicial
  void reset() {
    pause();
    final defaultCircuit = BasicCyclePreset.create();
    _state = SimulationState.initial(defaultCircuit);
    _state = DynamicSolver.integrateStep(currentState: _state, dt: 0.0);
    _activeExperiment = null;
    notifyListeners();
  }

  void _onTick() {
    _state = DynamicSolver.integrateStep(
      currentState: _state,
      dt: physicsTimeStepSeconds,
    );
    notifyListeners();
  }

  // --- Modificadores de parámetros físicos ---

  void setCompressorRpm(double rpm) {
    final comp = _state.circuit.compressor;
    if (comp == null) return;
    final updatedComp = comp.copyWith(rpm: rpm.clamp(500.0, 4500.0));
    _updateComponentInCircuit(updatedComp);
  }

  void setValveOpening(double percent) {
    final exp = _state.circuit.expansionDevice;
    if (exp == null) return;
    final updatedExp = exp.copyWith(openingPercent: percent.clamp(5.0, 100.0));
    _updateComponentInCircuit(updatedExp);
  }

  void setTxvAutomatic(bool automatic) {
    final exp = _state.circuit.expansionDevice;
    if (exp == null) return;
    final updatedExp = exp.copyWith(isAutomatic: automatic);
    _updateComponentInCircuit(updatedExp);
  }

  void setAmbientTemperature(double tempKelvin) {
    final cond = _state.circuit.condenser;
    if (cond == null) return;
    final updatedCond = cond.copyWith(ambientTemperatureKelvin: tempKelvin);
    _updateComponentInCircuit(updatedCond);
  }

  void setTxvOpening(double percent) => setValveOpening(percent);

  void setRoomTemperature(double tempKelvin) {
    final updatedColdRoom = _state.coldRoom.copyWith(temperatureKelvin: tempKelvin);
    _state = _state.copyWith(coldRoom: updatedColdRoom);
    notifyListeners();
  }

  void setColdRoomTemperature(double tempKelvin) => setRoomTemperature(tempKelvin);

  void toggleCondenserFan(bool operational) {
    final cond = _state.circuit.condenser;
    if (cond == null) return;
    final updatedCond = cond.copyWith(fanOperational: operational);
    _updateComponentInCircuit(updatedCond);
  }

  void toggleEvaporatorFan(bool operational) {
    final evap = _state.circuit.evaporator;
    if (evap == null) return;
    final updatedEvap = evap.copyWith(fanOperational: operational);
    _updateComponentInCircuit(updatedEvap);
  }

  void setCondenserFouling(double fouling) {
    final cond = _state.circuit.condenser;
    if (cond == null) return;
    final updatedCond = cond.copyWith(foulingFactor: fouling.clamp(0.0, 1.0));
    _updateComponentInCircuit(updatedCond);
  }

  // --- Control Termostático y Carga Térmica ---

  void setThermostatEnabled(bool enabled) {
    final updated = _state.thermostat.copyWith(isEnabled: enabled);
    _state = _state.copyWith(thermostat: updated);
    notifyListeners();
  }

  void setThermostatSetpoint(double setpointCelsius) {
    final updated = _state.thermostat.copyWith(setpointCelsius: setpointCelsius);
    _state = _state.copyWith(thermostat: updated);
    notifyListeners();
  }

  void setThermostatHysteresis(double hysteresisK) {
    final updated = _state.thermostat.copyWith(hysteresisKelvin: hysteresisK);
    _state = _state.copyWith(thermostat: updated);
    notifyListeners();
  }

  void setInternalHeatLoad(double watts) {
    final updated = _state.coldRoom.copyWith(internalHeatLoadWatts: watts.clamp(0.0, 10000.0));
    _state = _state.copyWith(coldRoom: updated);
    notifyListeners();
  }

  void setInfiltrationLoad(double watts) {
    final updated = _state.coldRoom.copyWith(infiltrationLoadWatts: watts.clamp(0.0, 10000.0));
    _state = _state.copyWith(coldRoom: updated);
    notifyListeners();
  }

  // --- Sistema de Prácticas y Experimentos Educativos ---

  void startExperiment(EducationalExperiment experiment) {
    _activeExperiment = experiment.copyWith(phase: ExperimentPhase.stabilizingBaseline);
    // Aplicamos valor de referencia basal
    switch (experiment.type) {
      case ExperimentType.rpmVariation:
        setCompressorRpm(experiment.baselineValue);
      case ExperimentType.ambientTemperatureVariation:
        setAmbientTemperature(experiment.baselineValue + 273.15);
      case ExperimentType.expansionValveThrottling:
        setTxvAutomatic(false);
        setValveOpening(experiment.baselineValue);
    }
    start();
    notifyListeners();
  }

  void applyExperimentPerturbation() {
    if (_activeExperiment == null) return;

    final exp = _activeExperiment!;
    switch (exp.type) {
      case ExperimentType.rpmVariation:
        setCompressorRpm(exp.perturbedValue);
      case ExperimentType.ambientTemperatureVariation:
        setAmbientTemperature(exp.perturbedValue + 273.15);
      case ExperimentType.expansionValveThrottling:
        setValveOpening(exp.perturbedValue);
    }
    _activeExperiment = exp.copyWith(phase: ExperimentPhase.observingTransient);
    notifyListeners();
  }

  void evaluateExperimentResults() {
    if (_activeExperiment == null) return;
    _activeExperiment = _activeExperiment!.copyWith(phase: ExperimentPhase.evaluatingResults);
    notifyListeners();
  }

  void completeExperiment() {
    if (_activeExperiment == null) return;
    _activeExperiment = _activeExperiment!.copyWith(phase: ExperimentPhase.completed);
    notifyListeners();
  }

  void cancelExperiment() {
    _activeExperiment = null;
    notifyListeners();
  }

  void clearActiveExperiment() => cancelExperiment();

  void _updateComponentInCircuit(dynamic component) {
    final newComponents = Map.of(_state.circuit.components);
    newComponents[component.id] = component;
    final newCircuit = _state.circuit.copyWith(components: newComponents);
    _state = _state.copyWith(circuit: newCircuit);
    notifyListeners();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }
}
