import 'package:flutter/material.dart';
import '../../core/units/pressure_unit.dart';
import '../../core/units/temperature_unit.dart';
import '../../domain/components/base_component.dart';
import '../../simulation/engine/simulation_engine.dart';
import '../theme/scada_colors.dart';
import '../widgets/component_inspector_modal.dart';
import '../widgets/pid_canvas.dart';
import '../widgets/simulation_control_panel.dart';
import '../widgets/telemetry_dashboard.dart';

/// Pantalla principal del simulador y laboratorio virtual.
class SimulatorScreen extends StatefulWidget {
  final SimulationEngine engine;
  final PressureUnit pressureUnit;
  final TemperatureUnit temperatureUnit;
  final ValueChanged<PressureUnit> onPressureUnitChanged;
  final ValueChanged<TemperatureUnit> onTemperatureUnitChanged;

  const SimulatorScreen({
    super.key,
    required this.engine,
    required this.pressureUnit,
    required this.temperatureUnit,
    required this.onPressureUnitChanged,
    required this.onTemperatureUnitChanged,
  });

  @override
  State<SimulatorScreen> createState() => _SimulatorScreenState();
}

class _SimulatorScreenState extends State<SimulatorScreen> {
  BaseComponent? _selectedComponent;

  @override
  void initState() {
    super.initState();
    _selectedComponent = widget.engine.state.circuit.compressor;
  }

  void _openExplainer(BaseComponent comp) {
    ComponentInspectorModal.show(
      context,
      component: comp,
      state: widget.engine.state,
      pressureUnit: widget.pressureUnit,
      temperatureUnit: widget.temperatureUnit,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.engine,
      builder: (context, _) {
        final state = widget.engine.state;
        final selectedComp = _selectedComponent ?? state.circuit.compressor;

        return Scaffold(
          backgroundColor: ScadaColors.background,
          body: LayoutBuilder(
            builder: (context, constraints) {
              final isTallScreen = constraints.maxHeight >= 900;

              final content = [
                // Barra de estado superior
                _buildSystemStatusBar(state),
                const SizedBox(height: 10),

                // Telemetría rápida
                TelemetryDashboard(
                  state: state,
                  pressureUnit: widget.pressureUnit,
                  temperatureUnit: widget.temperatureUnit,
                  onExplainPressed: () {
                    if (selectedComp != null) {
                      _openExplainer(selectedComp);
                    }
                  },
                ),
                const SizedBox(height: 10),

                // Lienzo central interactivo P&ID
                Container(
                  height: isTallScreen ? null : 380,
                  decoration: BoxDecoration(
                    color: ScadaColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: ScadaColors.border),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    children: [
                      PidCanvas(
                        state: state,
                        selectedComponent: selectedComp,
                        onComponentSelected: (comp) {
                          setState(() => _selectedComponent = comp);
                          _openExplainer(comp);
                        },
                      ),

                      // Indicador de ayuda en esquina inferior
                      Positioned(
                        left: 12,
                        bottom: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: ScadaColors.surfaceCard.withValues(alpha: 0.85),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: ScadaColors.border),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.touch_app, size: 14, color: ScadaColors.infoBlue),
                              SizedBox(width: 6),
                              Text(
                                'Toca cualquier componente para inspeccionar "¿Qué está pasando?"',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: ScadaColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // Panel inferior de mandos y actuadores
                SimulationControlPanel(
                  engine: widget.engine,
                  pressureUnit: widget.pressureUnit,
                  temperatureUnit: widget.temperatureUnit,
                  onPressureUnitChanged: widget.onPressureUnitChanged,
                  onTemperatureUnitChanged: widget.onTemperatureUnitChanged,
                ),
              ];

              if (isTallScreen) {
                return Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      content[0], // status bar
                      content[1], // space
                      content[2], // telemetry
                      content[3], // space
                      Expanded(child: content[4]), // expanded PID canvas
                      content[5], // space
                      content[6], // control panel
                    ],
                  ),
                );
              }

              return SingleChildScrollView(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: content,
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildSystemStatusBar(dynamic state) {
    final isRunning = state.isRunning;
    final isValid = state.topologyResult.isValid;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: ScadaColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: ScadaColors.border),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Estado de marcha
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isRunning ? ScadaColors.runningGreen : ScadaColors.dangerRed,
                boxShadow: [
                  BoxShadow(
                    color: (isRunning ? ScadaColors.runningGreen : ScadaColors.dangerRed).withValues(alpha: 0.5),
                    blurRadius: 6,
                  ),
                ],
              ),
            ),
          const SizedBox(width: 8),
          Text(
            isRunning ? 'SISTEMA EN FUNCIONAMIENTO' : 'SISTEMA DETENIDO',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: isRunning ? ScadaColors.runningGreen : ScadaColors.textMuted,
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(width: 16),

          // Refrigerante
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: ScadaColors.surfaceCard,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: ScadaColors.border),
            ),
            child: Text(
              'Fluido: ${state.circuit.refrigerantName}',
              style: const TextStyle(
                fontSize: 11,
                color: ScadaColors.infoBlue,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 24),

          // Validación de circuito
          Row(
            children: [
              Icon(
                isValid ? Icons.check_circle_outline : Icons.warning_amber_rounded,
                size: 14,
                color: isValid ? ScadaColors.runningGreen : ScadaColors.dangerRed,
              ),
              const SizedBox(width: 4),
              Text(
                isValid ? 'Circuito Cerrado Válido' : 'Circuito Anómalo',
                style: TextStyle(
                  fontSize: 11,
                  color: isValid ? ScadaColors.runningGreen : ScadaColors.dangerRed,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}
}
