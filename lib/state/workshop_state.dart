import '../../workshop/assembly_models.dart';

/// Estado inmutable y serializable del taller de montaje y puesta en servicio.
/// Representa el banco de trabajo, componentes conectados, etapas de vacío y carga.
/// No contiene referencias a widgets, BuildContext, AnimationControllers ni Timers.
class WorkshopState {
  final CommissioningStep currentStep;
  final Set<WorkshopPipeConnection> connections;
  final bool leakTestPassed;
  final bool vacuumPumpRunning;
  final double vacuumMicrons;
  final bool vacuumCompleted;
  final double chargedMassGrams;
  final bool chargingCompleted;
  final int hintsRevealed;
  final String? lastValidationFeedback;
  final String? lastValidationRule;
  final bool lastAttemptFailed;

  const WorkshopState({
    required this.currentStep,
    required this.connections,
    required this.leakTestPassed,
    required this.vacuumPumpRunning,
    required this.vacuumMicrons,
    required this.vacuumCompleted,
    required this.chargedMassGrams,
    required this.chargingCompleted,
    this.hintsRevealed = 0,
    this.lastValidationFeedback,
    this.lastValidationRule,
    this.lastAttemptFailed = false,
  });

  /// Estado inicial del taller al abrir una práctica desde cero
  factory WorkshopState.initial() => const WorkshopState(
        currentStep: CommissioningStep.assembly,
        connections: {},
        leakTestPassed: false,
        vacuumPumpRunning: false,
        vacuumMicrons: 760000.0,
        vacuumCompleted: false,
        chargedMassGrams: 0.0,
        chargingCompleted: false,
        hintsRevealed: 0,
        lastValidationFeedback: null,
        lastValidationRule: null,
        lastAttemptFailed: false,
      );

  /// Estado con el ciclo completamente conectado (4 conexiones estándar)
  factory WorkshopState.fullyConnected() => WorkshopState(
        currentStep: CommissioningStep.assembly,
        connections: {
          const WorkshopPipeConnection(
            fromPortId: 'comp_out',
            toPortId: 'cond_in',
            label: 'Descarga: Compresor -> Condensador',
          ),
          const WorkshopPipeConnection(
            fromPortId: 'cond_out',
            toPortId: 'exp_in',
            label: 'Línea Líquido: Condensador -> TXV',
          ),
          const WorkshopPipeConnection(
            fromPortId: 'exp_out',
            toPortId: 'evap_in',
            label: 'Inyección: TXV -> Evaporador',
          ),
          const WorkshopPipeConnection(
            fromPortId: 'evap_out',
            toPortId: 'comp_in',
            label: 'Aspiración: Evaporador -> Compresor',
          ),
        },
        leakTestPassed: false,
        vacuumPumpRunning: false,
        vacuumMicrons: 760000.0,
        vacuumCompleted: false,
        chargedMassGrams: 0.0,
        chargingCompleted: false,
        hintsRevealed: 0,
        lastValidationFeedback: 'Circuito básico conectado y sellado.',
        lastValidationRule: null,
        lastAttemptFailed: false,
      );

  bool get isCircuitFullyConnected => connections.length == 4;

  WorkshopState copyWith({
    CommissioningStep? currentStep,
    Set<WorkshopPipeConnection>? connections,
    bool? leakTestPassed,
    bool? vacuumPumpRunning,
    double? vacuumMicrons,
    bool? vacuumCompleted,
    double? chargedMassGrams,
    bool? chargingCompleted,
    int? hintsRevealed,
    String? lastValidationFeedback,
    String? lastValidationRule,
    bool? lastAttemptFailed,
  }) {
    return WorkshopState(
      currentStep: currentStep ?? this.currentStep,
      connections: connections ?? Set<WorkshopPipeConnection>.from(this.connections),
      leakTestPassed: leakTestPassed ?? this.leakTestPassed,
      vacuumPumpRunning: vacuumPumpRunning ?? this.vacuumPumpRunning,
      vacuumMicrons: vacuumMicrons ?? this.vacuumMicrons,
      vacuumCompleted: vacuumCompleted ?? this.vacuumCompleted,
      chargedMassGrams: chargedMassGrams ?? this.chargedMassGrams,
      chargingCompleted: chargingCompleted ?? this.chargingCompleted,
      hintsRevealed: hintsRevealed ?? this.hintsRevealed,
      lastValidationFeedback: lastValidationFeedback ?? this.lastValidationFeedback,
      lastValidationRule: lastValidationRule ?? this.lastValidationRule,
      lastAttemptFailed: lastAttemptFailed ?? this.lastAttemptFailed,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WorkshopState &&
          runtimeType == other.runtimeType &&
          currentStep == other.currentStep &&
          leakTestPassed == other.leakTestPassed &&
          vacuumPumpRunning == other.vacuumPumpRunning &&
          vacuumMicrons == other.vacuumMicrons &&
          vacuumCompleted == other.vacuumCompleted &&
          chargedMassGrams == other.chargedMassGrams &&
          chargingCompleted == other.chargingCompleted &&
          hintsRevealed == other.hintsRevealed &&
          connections.length == other.connections.length &&
          connections.containsAll(other.connections);

  @override
  int get hashCode => Object.hash(
        currentStep,
        Object.hashAll(connections),
        leakTestPassed,
        vacuumMicrons,
        vacuumCompleted,
        chargedMassGrams,
        chargingCompleted,
        hintsRevealed,
      );
}
