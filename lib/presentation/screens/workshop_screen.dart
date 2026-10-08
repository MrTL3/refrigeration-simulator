import 'package:flutter/material.dart';
import '../../core/units/pressure_unit.dart';
import '../../education/lessons/progress_tracker.dart';
import '../../simulation/engine/simulation_engine.dart';
import '../../state/session_coordinator.dart';
import '../../state/workshop_state.dart';
import '../../workshop/assembly_models.dart';
import '../theme/scada_colors.dart';

/// Pantalla del modo "TALLER" (Banco de montaje guiado y puesta en servicio de la instalación).
class WorkshopScreen extends StatefulWidget {
  final SimulationEngine engine;
  final PressureUnit pressureUnit;
  final SessionCoordinator? coordinator;

  const WorkshopScreen({
    super.key,
    required this.engine,
    required this.pressureUnit,
    this.coordinator,
  });

  @override
  State<WorkshopScreen> createState() => _WorkshopScreenState();
}

class _WorkshopScreenState extends State<WorkshopScreen> {
  CommissioningStep _currentStep = CommissioningStep.assembly;
  final Set<WorkshopPipeConnection> _connections = {};
  WorkshopPort? _selectedPort;
  String? _lastValidationFeedback;
  String? _lastValidationRule;
  bool _lastAttemptFailed = false;
  int _hintsRevealed = 0;

  // Estados del procedimiento de puesta en marcha
  bool _leakTestPassed = false;
  bool _vacuumPumpRunning = false;
  double _vacuumMicrons = 760000.0; // Presión atmosférica en micras de mercurio
  bool _vacuumCompleted = false;
  double _chargedMassGrams = 0.0;
  bool _chargingCompleted = false;

  @override
  void initState() {
    super.initState();
    if (widget.coordinator != null) {
      widget.coordinator!.addListener(_syncFromCoordinator);
      _syncFromCoordinator();
    }
  }

  @override
  void dispose() {
    widget.coordinator?.removeListener(_syncFromCoordinator);
    super.dispose();
  }

  void _syncFromCoordinator() {
    if (widget.coordinator == null) return;
    final ws = widget.coordinator!.workshopState;
    setState(() {
      _currentStep = ws.currentStep;
      _connections.clear();
      _connections.addAll(ws.connections);
      _leakTestPassed = ws.leakTestPassed;
      _vacuumPumpRunning = ws.vacuumPumpRunning;
      _vacuumMicrons = ws.vacuumMicrons;
      _vacuumCompleted = ws.vacuumCompleted;
      _chargedMassGrams = ws.chargedMassGrams;
      _chargingCompleted = ws.chargingCompleted;
      _hintsRevealed = ws.hintsRevealed;
      _lastValidationFeedback = ws.lastValidationFeedback;
      _lastValidationRule = ws.lastValidationRule;
      _lastAttemptFailed = ws.lastAttemptFailed;
    });
  }

  WorkshopState get _currentWorkshopState => WorkshopState(
        currentStep: _currentStep,
        connections: Set<WorkshopPipeConnection>.from(_connections),
        leakTestPassed: _leakTestPassed,
        vacuumPumpRunning: _vacuumPumpRunning,
        vacuumMicrons: _vacuumMicrons,
        vacuumCompleted: _vacuumCompleted,
        chargedMassGrams: _chargedMassGrams,
        chargingCompleted: _chargingCompleted,
        hintsRevealed: _hintsRevealed,
        lastValidationFeedback: _lastValidationFeedback,
        lastValidationRule: _lastValidationRule,
        lastAttemptFailed: _lastAttemptFailed,
      );

  final List<WorkshopPort> _allPorts = const [
    WorkshopPort(id: 'comp_in', componentId: 'comp', label: 'Compresor: Entrada (Aspiración)', type: WorkshopPortType.inlet, pressureLevel: PortPressureLevel.low),
    WorkshopPort(id: 'comp_out', componentId: 'comp', label: 'Compresor: Salida (Descarga)', type: WorkshopPortType.outlet, pressureLevel: PortPressureLevel.high),
    WorkshopPort(id: 'cond_in', componentId: 'cond', label: 'Condensador: Entrada (Gas Caliente)', type: WorkshopPortType.inlet, pressureLevel: PortPressureLevel.high),
    WorkshopPort(id: 'cond_out', componentId: 'cond', label: 'Condensador: Salida (Líquido)', type: WorkshopPortType.outlet, pressureLevel: PortPressureLevel.high),
    WorkshopPort(id: 'exp_in', componentId: 'exp', label: 'TXV: Entrada (Líquido Alta)', type: WorkshopPortType.inlet, pressureLevel: PortPressureLevel.high),
    WorkshopPort(id: 'exp_out', componentId: 'exp', label: 'TXV: Salida (Inyección Baja)', type: WorkshopPortType.outlet, pressureLevel: PortPressureLevel.low),
    WorkshopPort(id: 'evap_in', componentId: 'evap', label: 'Evaporador: Entrada (Inyección)', type: WorkshopPortType.inlet, pressureLevel: PortPressureLevel.low),
    WorkshopPort(id: 'evap_out', componentId: 'evap', label: 'Evaporador: Salida (Aspiración)', type: WorkshopPortType.outlet, pressureLevel: PortPressureLevel.low),
  ];

  bool get _isCircuitFullyConnected => _connections.length == 4;

  void _onPortTap(WorkshopPort port) {
    if (_selectedPort == null) {
      setState(() {
        _selectedPort = port;
        _lastValidationFeedback = null;
        _lastAttemptFailed = false;
      });
      return;
    }

    if (_selectedPort!.id == port.id) {
      setState(() => _selectedPort = null);
      return;
    }

    final from = _selectedPort!;
    final to = port;

    final result = WorkshopValidator.validateConnectionAttempt(fromPort: from, toPort: to);

    if (result.isValid) {
      final outP = from.type == WorkshopPortType.outlet ? from : to;
      final inP = from.type == WorkshopPortType.inlet ? from : to;
      final newConn = WorkshopPipeConnection(
        fromPortId: outP.id,
        toPortId: inP.id,
        label: '${outP.label} -> ${inP.label}',
      );

      final updatedConnections = Set<WorkshopPipeConnection>.from(_connections)..add(newConn);

      setState(() {
        _connections.add(newConn);
        _selectedPort = null;
        _lastValidationFeedback = result.feedback;
        _lastValidationRule = result.rule;
        _lastAttemptFailed = false;
      });

      widget.coordinator?.updateWorkshopState(
        _currentWorkshopState.copyWith(
          connections: updatedConnections,
          lastValidationFeedback: result.feedback,
          lastValidationRule: result.rule,
          lastAttemptFailed: false,
        ),
        actionDescription: 'Conectar tubería: ${outP.id} -> ${inP.id}',
      );
    } else {
      setState(() {
        _selectedPort = null;
        _lastValidationFeedback = result.feedback;
        _lastValidationRule = result.rule;
        _lastAttemptFailed = true;
      });
    }
  }

  void _setStep(CommissioningStep step) {
    setState(() => _currentStep = step);
    widget.coordinator?.updateWorkshopState(
      _currentWorkshopState.copyWith(currentStep: step),
      actionDescription: 'Avanzar a etapa: ${step.title}',
    );
  }

  void _autoCompleteCircuit() {
    final fullyConnected = WorkshopState.fullyConnected().connections;
    setState(() {
      _connections.clear();
      _connections.addAll(fullyConnected);
      _lastValidationFeedback = 'Solución razonada aplicada: El ciclo cerrado estándar de 1 etapa ha sido conectado correctamente.';
      _lastAttemptFailed = false;
    });

    widget.coordinator?.updateWorkshopState(
      _currentWorkshopState.copyWith(
        connections: fullyConnected,
        lastValidationFeedback: 'Solución razonada aplicada: El ciclo cerrado estándar de 1 etapa ha sido conectado correctamente.',
        lastAttemptFailed: false,
      ),
      actionDescription: 'Completar circuito frigorífico estándar',
    );
  }

  void _clearConnections() {
    setState(() {
      _connections.clear();
      _selectedPort = null;
      _lastValidationFeedback = null;
      _lastAttemptFailed = false;
      _currentStep = CommissioningStep.assembly;
      _leakTestPassed = false;
      _vacuumPumpRunning = false;
      _vacuumMicrons = 760000.0;
      _vacuumCompleted = false;
      _chargedMassGrams = 0.0;
      _chargingCompleted = false;
    });

    widget.coordinator?.updateWorkshopState(
      WorkshopState.initial(),
      actionDescription: 'Limpiar banco de trabajo de taller',
    );
  }

  void _revealNextHint() {
    setState(() {
      if (_hintsRevealed < 3) _hintsRevealed++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ScadaColors.background,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Banner de Cabecera de la Práctica 01
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  ScadaColors.warningAmber.withValues(alpha: 0.15),
                  ScadaColors.surfaceCard,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: ScadaColors.warningAmber.withValues(alpha: 0.4)),
            ),
            child: Row(
              children: [
                const Icon(Icons.build_circle, color: ScadaColors.warningAmber, size: 36),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'PRÁCTICA 01: MONTA TU PRIMER CICLO FRIGORÍFICO',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: ScadaColors.warningAmber,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 3),
                      const Text(
                        'Interconecta los 4 componentes básicos, realiza la estanqueidad, el vacío, la carga de gas y arranca tu instalación.',
                        style: TextStyle(fontSize: 11, color: ScadaColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Stepper de Puesta en Servicio (1 a 5)
          _buildCommissioningStepper(),
          const SizedBox(height: 12),

          // Contenido del paso actual
          _buildCurrentStepContent(),
        ],
      ),
    );
  }

  Widget _buildCommissioningStepper() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: CommissioningStep.values.map((step) {
          final isCurrent = step == _currentStep;
          final isPast = step.index < _currentStep.index;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: InkWell(
              onTap: () {
                // Solo se puede avanzar si se cumplen los requisitos del paso anterior
                if (step.index <= _currentStep.index ||
                    (_currentStep == CommissioningStep.assembly && _isCircuitFullyConnected)) {
                  _setStep(step);
                }
              },
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: isCurrent
                      ? ScadaColors.infoBlue
                      : (isPast ? ScadaColors.runningGreen.withValues(alpha: 0.15) : ScadaColors.surfaceCard),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isCurrent
                        ? ScadaColors.infoBlue
                        : (isPast ? ScadaColors.runningGreen : ScadaColors.border),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isPast ? Icons.check_circle : (isCurrent ? Icons.play_circle_filled : Icons.radio_button_unchecked),
                      size: 14,
                      color: isCurrent ? Colors.white : (isPast ? ScadaColors.runningGreen : ScadaColors.textMuted),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      step.title,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isCurrent ? Colors.white : (isPast ? ScadaColors.runningGreen : ScadaColors.textPrimary),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCurrentStepContent() {
    switch (_currentStep) {
      case CommissioningStep.assembly:
        return _buildAssemblyWorkbench();
      case CommissioningStep.leakTest:
        return _buildLeakTestView();
      case CommissioningStep.vacuum:
        return _buildVacuumProcedureView();
      case CommissioningStep.charging:
        return _buildChargingProcedureView();
      case CommissioningStep.startup:
        return _buildStartupCommissioningView();
    }
  }

  Widget _buildAssemblyWorkbench() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Panel de feedback pedagógico inmediato
        if (_lastValidationFeedback != null) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _lastAttemptFailed
                  ? ScadaColors.dangerRed.withValues(alpha: 0.1)
                  : ScadaColors.runningGreen.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _lastAttemptFailed ? ScadaColors.dangerRed : ScadaColors.runningGreen,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      _lastAttemptFailed ? Icons.error_outline : Icons.verified,
                      size: 16,
                      color: _lastAttemptFailed ? ScadaColors.dangerRed : ScadaColors.runningGreen,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _lastAttemptFailed ? 'CONEXIÓN FÍSICAMENTE INCOMPATIBLE' : 'CONEXIÓN ESTABLECIDA',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: _lastAttemptFailed ? ScadaColors.dangerRed : ScadaColors.runningGreen,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  _lastValidationFeedback!,
                  style: const TextStyle(fontSize: 12, color: ScadaColors.textPrimary, height: 1.3),
                ),
                if (_lastValidationRule != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    _lastValidationRule!,
                    style: const TextStyle(fontSize: 10, fontStyle: FontStyle.italic, color: ScadaColors.warningAmber),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 10),
        ],

        // Estado del circuito
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: ScadaColors.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: ScadaColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 4,
                children: [
                  Text(
                    'TUBERÍAS CONECTADAS: ${_connections.length} / 4',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: ScadaColors.textPrimary),
                  ),
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 4,
                    runSpacing: 4,
                    children: [
                      TextButton.icon(
                        onPressed: _revealNextHint,
                        icon: const Icon(Icons.lightbulb_outline, size: 14),
                        label: Text('PISTA ($_hintsRevealed/3)'),
                        style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                      ),
                      TextButton(
                        onPressed: _autoCompleteCircuit,
                        child: const Text('MOSTRAR SOLUCIÓN', style: TextStyle(fontSize: 10, color: ScadaColors.warningAmber)),
                      ),
                      IconButton(
                        onPressed: _clearConnections,
                        icon: const Icon(Icons.refresh, size: 16, color: ScadaColors.textMuted),
                        tooltip: 'Limpiar banco',
                      ),
                    ],
                  ),
                ],
              ),
              if (_hintsRevealed > 0) _buildHintsCard(),
              const SizedBox(height: 8),

              // Lista de puertos para conectar
              const Text(
                'Selecciona un puerto de SALIDA y luego su puerto de ENTRADA correspondiente:',
                style: TextStyle(fontSize: 11, color: ScadaColors.textSecondary),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _allPorts.map((port) {
                  final isSelected = _selectedPort?.id == port.id;
                  final isConnected = _isPortConnected(port.id);

                  Color pColor = port.pressureLevel == PortPressureLevel.high
                      ? ScadaColors.highPressureDischarge
                      : ScadaColors.lowPressureGas;

                  return InkWell(
                    onTap: isConnected ? null : () => _onPortTap(port),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? ScadaColors.infoBlue.withValues(alpha: 0.3)
                            : (isConnected ? ScadaColors.surfaceCard.withValues(alpha: 0.5) : ScadaColors.surfaceCard),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected ? ScadaColors.infoBlue : (isConnected ? ScadaColors.runningGreen : pColor),
                          width: isSelected ? 2.0 : 1.0,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isConnected ? Icons.check_circle : (port.type == WorkshopPortType.outlet ? Icons.logout : Icons.login),
                            size: 14,
                            color: isConnected ? ScadaColors.runningGreen : pColor,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            port.label,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              color: isConnected ? ScadaColors.textMuted : ScadaColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Botón para avanzar a la siguiente etapa de prueba de fugas
        ElevatedButton.icon(
          onPressed: _isCircuitFullyConnected
              ? () => _setStep(CommissioningStep.leakTest)
              : null,
          icon: const Icon(Icons.arrow_forward, size: 16),
          label: Text(
            _isCircuitFullyConnected
                ? 'CIRCUITO COMPLETO -> PASAR A PRUEBA DE ESTANQUEIDAD'
                : 'CONECTA LOS 4 PUERTOS PARA CONTINUAR (${_connections.length}/4)',
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: ScadaColors.runningGreen,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      ],
    );
  }

  bool _isPortConnected(String portId) {
    return _connections.any((c) => c.fromPortId == portId || c.toPortId == portId);
  }

  Widget _buildHintsCard() {
    return Container(
      margin: const EdgeInsets.only(top: 6),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: ScadaColors.warningAmber.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: ScadaColors.warningAmber.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_hintsRevealed >= 1) ...[
            const Text('💡 PISTA 1: Recuerda que el compresor empuja gas muy caliente a alta presión que necesita desprenderse de su energía calorífica en el condensador.', style: TextStyle(fontSize: 10, color: ScadaColors.warningAmber)),
            const SizedBox(height: 4),
          ],
          if (_hintsRevealed >= 2) ...[
            const Text('💡 PISTA 2: El orden cardinal del ciclo es: Compresor (salida) -> Condensador (entrada/salida) -> TXV (entrada/salida) -> Evaporador (entrada/salida) -> Compresor (entrada).', style: TextStyle(fontSize: 10, color: ScadaColors.warningAmber)),
            const SizedBox(height: 4),
          ],
          if (_hintsRevealed >= 3)
            const Text('💡 PISTA 3: Conexiones requeridas:\n1. comp_out -> cond_in\n2. cond_out -> exp_in\n3. exp_out -> evap_in\n4. evap_out -> comp_in', style: TextStyle(fontSize: 10, color: ScadaColors.warningAmber)),
        ],
      ),
    );
  }

  Widget _buildLeakTestView() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ScadaColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ScadaColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.health_and_safety, color: ScadaColors.infoBlue, size: 20),
              SizedBox(width: 8),
              Text(
                'ETAPA 2: PRUEBA DE PRESIÓN Y ESTANQUEIDAD (N₂)',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: ScadaColors.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Antes de introducir refrigerante, el circuito cerrado debe someterse a una prueba de presión con nitrógeno seco (15 bar) para verificar la ausencia de fugas en soldaduras y roscas.',
            style: TextStyle(fontSize: 12, color: ScadaColors.textSecondary, height: 1.3),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: ScadaColors.surfaceCard,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _leakTestPassed ? ScadaColors.runningGreen : ScadaColors.border),
            ),
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Presión de Prueba N₂:', style: TextStyle(fontSize: 11, color: ScadaColors.textSecondary)),
                    Text(
                      _leakTestPassed ? '15.0 bar (ESTABLE 10 min)' : '0.0 bar (Sin presurizar)',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: _leakTestPassed ? ScadaColors.runningGreen : ScadaColors.textPrimary,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: _leakTestPassed
                      ? null
                      : () {
                          setState(() => _leakTestPassed = true);
                          widget.coordinator?.updateWorkshopState(
                            _currentWorkshopState.copyWith(leakTestPassed: true),
                            actionDescription: 'Prueba de estanqueidad N2 verificada (15 bar)',
                          );
                        },
                  icon: const Icon(Icons.speed, size: 16),
                  label: Text(_leakTestPassed ? 'ESTANQUEIDAD VERIFICADA' : 'PRESURIZAR CON NITRÓGENO'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _leakTestPassed ? ScadaColors.runningGreen : ScadaColors.infoBlue,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          ElevatedButton.icon(
            onPressed: _leakTestPassed
                ? () => _setStep(CommissioningStep.vacuum)
                : null,
            icon: const Icon(Icons.arrow_forward, size: 16),
            label: const Text('PURGAR NITRÓGENO Y PASAR A PROCESO DE VACÍO'),
            style: ElevatedButton.styleFrom(
              backgroundColor: ScadaColors.runningGreen,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVacuumProcedureView() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ScadaColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ScadaColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.air, color: ScadaColors.infoBlue, size: 20),
              SizedBox(width: 8),
              Text(
                'ETAPA 3: PROCESO DE VACÍO Y EXTRACCIÓN DE HUMEDAD',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: ScadaColors.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'El vacío extrae gases incondensables (aire, nitrógeno) y reduce la presión interna para que la humedad residual hierva a temperatura ambiente y sea evacuada por la bomba. Objetivo: < 500 micras de Hg (0.66 mbar).',
            style: TextStyle(fontSize: 12, color: ScadaColors.textSecondary, height: 1.3),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: ScadaColors.surfaceCard,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _vacuumCompleted ? ScadaColors.runningGreen : ScadaColors.border),
            ),
            child: Column(
              children: [
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Lectura del Vacuómetro Electrónico:', style: TextStyle(fontSize: 11, color: ScadaColors.textSecondary)),
                        Text(
                          '${_vacuumMicrons.toInt()} micras Hg (${(_vacuumMicrons * 0.001333).toStringAsFixed(2)} mbar)',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: _vacuumCompleted ? ScadaColors.runningGreen : ScadaColors.warningAmber,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                    ElevatedButton.icon(
                      onPressed: _vacuumCompleted
                          ? null
                          : () {
                              setState(() {
                                _vacuumPumpRunning = true;
                                _vacuumMicrons = 280.0; // Desciende por debajo de 500 micras
                                _vacuumCompleted = true;
                              });
                              widget.coordinator?.updateWorkshopState(
                                _currentWorkshopState.copyWith(
                                  vacuumPumpRunning: true,
                                  vacuumMicrons: 280.0,
                                  vacuumCompleted: true,
                                ),
                                actionDescription: 'Vacío profundo conseguido (<500 µm)',
                              );
                            },
                      icon: Icon(_vacuumPumpRunning ? Icons.hourglass_bottom : Icons.power_settings_new, size: 16),
                      label: Text(_vacuumCompleted ? 'VACÍO CONSEGUIDO (<500 µm)' : 'ENCENDER BOMBA DE VACÍO'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _vacuumCompleted ? ScadaColors.runningGreen : ScadaColors.warningAmber,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          ElevatedButton.icon(
            onPressed: _vacuumCompleted
                ? () => _setStep(CommissioningStep.charging)
                : null,
            icon: const Icon(Icons.arrow_forward, size: 16),
            label: const Text('CERRAR VÁLVULAS DE VACÍO Y PASAR A CARGA DE GAS'),
            style: ElevatedButton.styleFrom(
              backgroundColor: ScadaColors.runningGreen,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChargingProcedureView() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ScadaColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ScadaColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.scale, color: ScadaColors.infoBlue, size: 20),
              SizedBox(width: 8),
              Text(
                'ETAPA 4: CARGA DE REFRIGERANTE POR PESO (BÁSCULA)',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: ScadaColors.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Colocamos la botella de R-134a sobre la báscula digital electrónica, purga de manguera amarilla de servicio y transferimos la masa de refrigerante exacta de diseño (250 gramos).',
            style: TextStyle(fontSize: 12, color: ScadaColors.textSecondary, height: 1.3),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: ScadaColors.surfaceCard,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _chargingCompleted ? ScadaColors.runningGreen : ScadaColors.border),
            ),
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Masa Transferida a la Instalación:', style: TextStyle(fontSize: 11, color: ScadaColors.textSecondary)),
                    Text(
                      '${_chargedMassGrams.toInt()} g / 250 g (R-134a)',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: _chargingCompleted ? ScadaColors.runningGreen : ScadaColors.infoBlue,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: _chargingCompleted
                      ? null
                      : () {
                          setState(() {
                            _chargedMassGrams = 250.0;
                            _chargingCompleted = true;
                          });
                          widget.coordinator?.updateWorkshopState(
                            _currentWorkshopState.copyWith(
                              chargedMassGrams: 250.0,
                              chargingCompleted: true,
                            ),
                            actionDescription: 'Carga de gas R-134a completada (250 g)',
                          );
                        },
                  icon: const Icon(Icons.local_gas_station, size: 16),
                  label: Text(_chargingCompleted ? 'CARGA COMPLETA (250 g)' : 'INICIAR CARGA DE REFRIGERANTE'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _chargingCompleted ? ScadaColors.runningGreen : ScadaColors.infoBlue,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          ElevatedButton.icon(
            onPressed: _chargingCompleted
                ? () => _setStep(CommissioningStep.startup)
                : null,
            icon: const Icon(Icons.arrow_forward, size: 16),
            label: const Text('RETIRAR MANGUERAS Y PASAR A PUESTA EN MARCHA'),
            style: ElevatedButton.styleFrom(
              backgroundColor: ScadaColors.runningGreen,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStartupCommissioningView() {
    final tracker = ProgressTracker();
    tracker.markWorkshopPracticeCompleted('practice_01_basic_cycle');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ScadaColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ScadaColors.runningGreen),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.check_circle, color: ScadaColors.runningGreen, size: 24),
              SizedBox(width: 8),
              Text(
                '¡INSTALACIÓN COMPLETADA Y CERTIFICADA!',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: ScadaColors.runningGreen),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Has completado satisfactoriamente el montaje físico, la prueba de fugas, el vacío profundo y la carga pesada. La instalación está lista para su arranque.',
            style: TextStyle(fontSize: 12, color: ScadaColors.textPrimary, height: 1.3),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              ElevatedButton.icon(
                onPressed: () {
                  widget.engine.start();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('¡Circuito arrancado! Observa la aceleración y bifurcación de presiones.'),
                      backgroundColor: ScadaColors.runningGreen,
                    ),
                  );
                },
                icon: const Icon(Icons.play_arrow, size: 18),
                label: const Text('ARRANCAR TU INSTALACIÓN'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: ScadaColors.runningGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
              OutlinedButton.icon(
                onPressed: _clearConnections,
                icon: const Icon(Icons.restart_alt, size: 18),
                label: const Text('REPETIR PRÁCTICA SIN AYUDA'),
                style: OutlinedButton.styleFrom(foregroundColor: ScadaColors.textSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
