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

  /// Notificador previo a la mutación causada por una acción de usuario
  void Function(String description)? onUserAction;

  void notifyUserAction(String description) {
    onUserAction?.call(description);
  }

  /// Restaura un estado previo exacto procedente de un Snapshot de Undo/Redo.
  /// NO altera ecuaciones ni parámetros físicos. Reanuda o pausa el bucle temporal según corresponda.
  void restoreState(SimulationState restoredState, {EducationalExperiment? activeExperiment}) {
    _ticker?.cancel();
    _ticker = null;
    _state = restoredState;
    _activeExperiment = activeExperiment;

    // Asentamiento instantáneo de estados a dt = 0.0 sin avanzar tiempo
    _state = DynamicSolver.integrateStep(
      currentState: _state,
      dt: 0.0,
    );

    if (restoredState.isRunning) {
      _ticker = Timer.periodic(
        const Duration(milliseconds: 50),
        (_) => _onTick(),
      );
    }
    notifyListeners();
  }

  /// Arranca la simulación física continua
  void start() {
    if (_state.isRunning) return;

    notifyUserAction('Arrancar instalación frigorífica');
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

    notifyUserAction('Parar instalación frigorífica');
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
    notifyUserAction('Ajustar RPM compresor a ${rpm.toInt()} RPM');
    final updatedComp = comp.copyWith(rpm: rpm.clamp(500.0, 4500.0));
    _updateComponentInCircuit(updatedComp);
  }

  void setValveOpening(double percent) {
    final exp = _state.circuit.expansionDevice;
    if (exp == null) return;
    notifyUserAction('Ajustar apertura TXV a ${percent.toStringAsFixed(0)}%');
    final updatedExp = exp.copyWith(openingPercent: percent.clamp(5.0, 100.0));
    _updateComponentInCircuit(updatedExp);
  }

  void setTxvAutomatic(bool automatic) {
    final exp = _state.circuit.expansionDevice;
    if (exp == null) return;
    notifyUserAction(automatic ? 'Activar modo automático TXV' : 'Activar modo manual TXV');
    final updatedExp = exp.copyWith(isAutomatic: automatic);
    _updateComponentInCircuit(updatedExp);
  }

  void setAmbientTemperature(double tempKelvin) {
    final cond = _state.circuit.condenser;
    if (cond == null) return;
    notifyUserAction('Ajustar temp. ambiente a ${(tempKelvin - 273.15).toStringAsFixed(0)} °C');
    final updatedCond = cond.copyWith(ambientTemperatureKelvin: tempKelvin);
    _updateComponentInCircuit(updatedCond);
  }

  void setTxvOpening(double percent) => setValveOpening(percent);

  void setRoomTemperature(double tempKelvin) {
    notifyUserAction('Ajustar temp. cámara a ${(tempKelvin - 273.15).toStringAsFixed(0)} °C');
    final updatedColdRoom = _state.coldRoom.copyWith(temperatureKelvin: tempKelvin);
    _state = _state.copyWith(coldRoom: updatedColdRoom);
    notifyListeners();
  }

  void setColdRoomTemperature(double tempKelvin) => setRoomTemperature(tempKelvin);

  void toggleCondenserFan(bool operational) {
    final cond = _state.circuit.condenser;
    if (cond == null) return;
    notifyUserAction(operational ? 'Encender ventilador condensador' : 'Apagar ventilador condensador');
    final updatedCond = cond.copyWith(fanOperational: operational);
    _updateComponentInCircuit(updatedCond);
    _state = _state.copyWith(condenserFanSpeedOverride: operational ? 1.0 : 0.0);
    notifyListeners();
  }

  void toggleEvaporatorFan(bool operational) {
    final evap = _state.circuit.evaporator;
    if (evap == null) return;
    notifyUserAction(operational ? 'Encender ventilador evaporador' : 'Apagar ventilador evaporador');
    final updatedEvap = evap.copyWith(fanOperational: operational);
    _updateComponentInCircuit(updatedEvap);
    _state = _state.copyWith(evaporatorFanSpeedOverride: operational ? 1.0 : 0.0);
    notifyListeners();
  }

  void setCondenserFanSpeedOverride(double fraction) {
    _state = _state.copyWith(condenserFanSpeedOverride: fraction.clamp(0.0, 1.2));
    notifyListeners();
  }

  void setEvaporatorFanSpeedOverride(double fraction) {
    _state = _state.copyWith(evaporatorFanSpeedOverride: fraction.clamp(0.0, 1.2));
    notifyListeners();
  }

  void stepVacuum(double dt, {bool pumpOn = true}) {
    final updatedVac = _state.vacuumState.integrateStep(dt, pumpOn: pumpOn);
    _state = _state.copyWith(vacuumState: updatedVac);
    notifyListeners();
  }

  void setCondenserFouling(double fouling) {
    final cond = _state.circuit.condenser;
    if (cond == null) return;
    notifyUserAction('Ajustar suciedad condensador a ${(fouling * 100).toInt()}%');
    final updatedCond = cond.copyWith(foulingFactor: fouling.clamp(0.0, 1.0));
    _updateComponentInCircuit(updatedCond);
  }

  // --- Control Termostático y Carga Térmica ---

  void setThermostatEnabled(bool enabled) {
    notifyUserAction(enabled ? 'Habilitar control termostático' : 'Deshabilitar control termostático');
    final updated = _state.thermostat.copyWith(isEnabled: enabled);
    _state = _state.copyWith(thermostat: updated);
    notifyListeners();
  }

  void setThermostatSetpoint(double setpointCelsius) {
    notifyUserAction('Ajustar setpoint termostato a ${setpointCelsius.toStringAsFixed(1)} °C');
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
    notifyUserAction('Ajustar carga interna cámara a ${watts.toInt()} W');
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
      case ExperimentType.severeExpansionThrottling:
        setTxvAutomatic(false);
        setValveOpening(experiment.baselineValue);
      case ExperimentType.condenserAirflowReduction:
        setCondenserFouling(experiment.baselineValue / 100.0);
      case ExperimentType.thermalLoadIncrease:
        setInternalHeatLoad(experiment.baselineValue);
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
      case ExperimentType.severeExpansionThrottling:
        setValveOpening(exp.perturbedValue);
      case ExperimentType.condenserAirflowReduction:
        setCondenserFouling(exp.perturbedValue / 100.0);
      case ExperimentType.thermalLoadIncrease:
        setInternalHeatLoad(exp.perturbedValue);
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
