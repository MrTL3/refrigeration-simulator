import '../../domain/models/educational_experiment.dart';
import '../../simulation/engine/simulation_state.dart';
import 'workshop_state.dart';

/// Categorías de acciones de usuario sujetas a registro y reversión
enum UserActionCategory {
  simulation('Simulador y Máquina'),
  workshop('Taller y Montaje'),
  experiment('Práctica y Ensayo'),
  thermostat('Control Termostático'),
  faultInjection('Inyección de Fallos'),
  system('Sistema');

  final String label;
  const UserActionCategory(this.label);
}

/// Instantánea inmutable y desacoplada del estado global relevante de FrigoLab en un instante t.
/// Cumple estrictamente con la regla de NO contener BuildContext, Tickers, Timers, Widgets ni objetos visuales.
class AppSnapshot {
  final String id;
  final DateTime timestamp;
  final String actionDescription;
  final UserActionCategory category;
  final SimulationState simulationState;
  final WorkshopState workshopState;
  final EducationalExperiment? activeExperiment;

  const AppSnapshot({
    required this.id,
    required this.timestamp,
    required this.actionDescription,
    required this.category,
    required this.simulationState,
    required this.workshopState,
    this.activeExperiment,
  });

  /// Crea una copia profunda e independiente de este snapshot
  AppSnapshot clone() {
    return AppSnapshot(
      id: id,
      timestamp: timestamp,
      actionDescription: actionDescription,
      category: category,
      simulationState: simulationState.copyWith(),
      workshopState: workshopState.copyWith(),
      activeExperiment: activeExperiment?.copyWith(),
    );
  }

  /// Comprueba equivalencia física y de montaje estricta para tests de determinismo (A' == A)
  bool isPhysicallyIdenticalTo(AppSnapshot other, {double tolerance = 1e-6}) {
    final s1 = simulationState;
    final s2 = other.simulationState;

    if (s1.isRunning != s2.isRunning) return false;
    if ((s1.dynamicRpm - s2.dynamicRpm).abs() > tolerance) return false;
    if ((s1.dynamicBulbTempK - s2.dynamicBulbTempK).abs() > tolerance) return false;
    if ((s1.evaporatingPressurePa - s2.evaporatingPressurePa).abs() > tolerance) return false;
    if ((s1.condensingPressurePa - s2.condensingPressurePa).abs() > tolerance) return false;
    if ((s1.evaporatingTemperatureK - s2.evaporatingTemperatureK).abs() > tolerance) return false;
    if ((s1.condensingTemperatureK - s2.condensingTemperatureK).abs() > tolerance) return false;
    if ((s1.superheatKelvin - s2.superheatKelvin).abs() > tolerance) return false;
    if ((s1.subcoolingKelvin - s2.subcoolingKelvin).abs() > tolerance) return false;
    if ((s1.massFlowKgPerSec - s2.massFlowKgPerSec).abs() > tolerance) return false;
    if ((s1.coolingCapacityWatts - s2.coolingCapacityWatts).abs() > tolerance) return false;
    if ((s1.compressorPowerWatts - s2.compressorPowerWatts).abs() > tolerance) return false;
    if ((s1.cop - s2.cop).abs() > tolerance) return false;

    // Componentes del circuito
    final comp1 = s1.circuit.compressor;
    final comp2 = s2.circuit.compressor;
    if ((comp1?.rpm ?? 0.0) != (comp2?.rpm ?? 0.0)) return false;

    final exp1 = s1.circuit.expansionDevice;
    final exp2 = s2.circuit.expansionDevice;
    if ((exp1?.openingPercent ?? 0.0) != (exp2?.openingPercent ?? 0.0)) return false;
    if ((exp1?.isAutomatic ?? true) != (exp2?.isAutomatic ?? true)) return false;

    final cond1 = s1.circuit.condenser;
    final cond2 = s2.circuit.condenser;
    if ((cond1?.ambientTemperatureKelvin ?? 0.0) != (cond2?.ambientTemperatureKelvin ?? 0.0)) return false;
    if ((cond1?.foulingFactor ?? 0.0) != (cond2?.foulingFactor ?? 0.0)) return false;
    if ((cond1?.fanOperational ?? true) != (cond2?.fanOperational ?? true)) return false;

    final evap1 = s1.circuit.evaporator;
    final evap2 = s2.circuit.evaporator;
    if ((evap1?.fanOperational ?? true) != (evap2?.fanOperational ?? true)) return false;

    // Cámara y termostato
    if ((s1.coldRoom.temperatureKelvin - s2.coldRoom.temperatureKelvin).abs() > tolerance) return false;
    if (s1.thermostat.isEnabled != s2.thermostat.isEnabled) return false;
    if ((s1.thermostat.setpointCelsius - s2.thermostat.setpointCelsius).abs() > tolerance) return false;

    // Estado del taller
    if (workshopState != other.workshopState) return false;

    return true;
  }
}
