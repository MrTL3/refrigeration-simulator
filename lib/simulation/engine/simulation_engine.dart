import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../domain/models/basic_cycle_preset.dart';
import '../../domain/models/circuit.dart';
import '../solver/circuit_solver.dart';
import 'simulation_state.dart';

/// Motor central de simulación física de FrigoLab.
/// Ejecuta el bucle de integración temporal desacoplado de la interfaz de usuario.
class SimulationEngine extends ChangeNotifier {
  late SimulationState _state;
  Timer? _ticker;

  /// Paso de tiempo de simulación física en segundos (50 ms = 20 Hz)
  static const double physicsTimeStepSeconds = 0.05;

  SimulationEngine({Circuit? initialCircuit}) {
    final circuit = initialCircuit ?? BasicCyclePreset.create();
    _state = SimulationState.initial(circuit);
    // Realizamos un primer pase para inicializar las condiciones
    _state = CircuitSolver.solveStep(
      currentState: _state,
      dt: 0.0,
    );
  }

  SimulationState get state => _state;
  bool get isRunning => _state.isRunning;

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
    // Resolver paso en reposo
    _state = CircuitSolver.solveStep(
      currentState: _state,
      dt: 0.0,
    );
    notifyListeners();
  }

  /// Ejecuta un paso temporal único manual (útil para docencia y depuración)
  void step() {
    _onTick();
  }

  /// Restablece la simulación al circuito básico original
  void reset() {
    pause();
    final defaultCircuit = BasicCyclePreset.create();
    _state = SimulationState.initial(defaultCircuit);
    _state = CircuitSolver.solveStep(currentState: _state, dt: 0.0);
    notifyListeners();
  }

  void _onTick() {
    _state = CircuitSolver.solveStep(
      currentState: _state,
      dt: physicsTimeStepSeconds,
    );
    notifyListeners();
  }

  // --- Modificadores de parámetros en caliente ---

  /// Ajusta las RPM del compresor
  void setCompressorRpm(double rpm) {
    final comp = _state.circuit.compressor;
    if (comp == null) return;
    final updatedComp = comp.copyWith(rpm: rpm.clamp(500.0, 4500.0));
    _updateComponentInCircuit(updatedComp);
  }

  /// Ajusta el porcentaje de apertura de la válvula de expansión
  void setValveOpening(double percent) {
    final exp = _state.circuit.expansionDevice;
    if (exp == null) return;
    final updatedExp = exp.copyWith(openingPercent: percent.clamp(5.0, 100.0));
    _updateComponentInCircuit(updatedExp);
  }

  /// Modifica la temperatura ambiente externa (Kelvin)
  void setAmbientTemperature(double tempKelvin) {
    final cond = _state.circuit.condenser;
    if (cond == null) return;
    final updatedCond = cond.copyWith(ambientTemperatureKelvin: tempKelvin);
    _updateComponentInCircuit(updatedCond);
  }

  /// Modifica la temperatura de la cámara/recinto (Kelvin)
  void setRoomTemperature(double tempKelvin) {
    final evap = _state.circuit.evaporator;
    if (evap == null) return;
    final updatedEvap = evap.copyWith(roomTemperatureKelvin: tempKelvin);
    _updateComponentInCircuit(updatedEvap);
  }

  /// Conmuta el ventilador del condensador
  void toggleCondenserFan(bool operational) {
    final cond = _state.circuit.condenser;
    if (cond == null) return;
    final updatedCond = cond.copyWith(fanOperational: operational);
    _updateComponentInCircuit(updatedCond);
  }

  /// Conmuta el ventilador del evaporador
  void toggleEvaporatorFan(bool operational) {
    final evap = _state.circuit.evaporator;
    if (evap == null) return;
    final updatedEvap = evap.copyWith(fanOperational: operational);
    _updateComponentInCircuit(updatedEvap);
  }

  /// Ajusta la suciedad del condensador
  void setCondenserFouling(double fouling) {
    final cond = _state.circuit.condenser;
    if (cond == null) return;
    final updatedCond = cond.copyWith(foulingFactor: fouling.clamp(0.0, 1.0));
    _updateComponentInCircuit(updatedCond);
  }

  void _updateComponentInCircuit(dynamic component) {
    final newComponents = Map.of(_state.circuit.components);
    newComponents[component.id] = component;
    final newCircuit = _state.circuit.copyWith(components: newComponents);
    _state = _state.copyWith(circuit: newCircuit);
    _state = CircuitSolver.solveStep(currentState: _state, dt: 0.0);
    notifyListeners();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }
}
