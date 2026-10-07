import 'package:flutter/material.dart';
import '../../core/units/pressure_unit.dart';
import '../../core/units/temperature_unit.dart';
import '../../domain/components/base_component.dart';
import '../../education/virtual_teacher/virtual_teacher_service.dart';
import '../../simulation/engine/simulation_engine.dart';
import '../../simulation/engine/simulation_state.dart';
import '../theme/scada_colors.dart';
import '../widgets/component_inspector_modal.dart';
import '../widgets/ph_diagram_widget.dart';
import '../widgets/pid_canvas.dart';
import '../widgets/simulation_control_panel.dart';
import '../widgets/telemetry_dashboard.dart';
import '../widgets/thermostat_widget.dart';
import '../widgets/transient_chart_widget.dart';
import '../widgets/ts_diagram_widget.dart';

/// Modo de visualización central de la planta
enum CentralViewMode {
  pid('Sinóptico P&ID', Icons.account_tree_outlined),
  phDiagram('Diagrama P-h (Mollier)', Icons.show_chart_rounded),
  tsDiagram('Diagrama T-s', Icons.multiline_chart_rounded);

  final String label;
  final IconData icon;
  const CentralViewMode(this.label, this.icon);
}

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
  CentralViewMode _viewMode = CentralViewMode.pid;

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

  void _handleComponentHighlight(String compId) {
    final state = widget.engine.state;
    BaseComponent? target;
    if (compId == 'comp_1') {
      target = state.circuit.compressor;
    } else if (compId == 'cond_1') {
      target = state.circuit.condenser;
    } else if (compId == 'exp_1') {
      target = state.circuit.expansionDevice;
    } else if (compId == 'evap_1') {
      target = state.circuit.evaporator;
    }

    if (target != null) {
      setState(() {
        _selectedComponent = target;
        _viewMode = CentralViewMode.pid;
      });
      _openExplainer(target);
    }
  }

  void _showWhyModal(ContextualAlert alert, SimulationState state) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: ScadaColors.surfaceCard,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          border: Border.all(color: ScadaColors.borderLight),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: ScadaColors.warningAmber.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.school, color: ScadaColors.warningAmber, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'EXPLICACIÓN DEL PROFESOR VIRTUAL',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: ScadaColors.warningAmber,
                          letterSpacing: 1.0,
                        ),
                      ),
                      Text(
                        alert.title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: ScadaColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: ScadaColors.textMuted),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: ScadaColors.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: ScadaColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '¿QUÉ ESTÁ SUCEDIENDO FÍSICAMENTE?',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: ScadaColors.cyanAccent,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    alert.whyExplanation,
                    style: const TextStyle(
                      fontSize: 13,
                      color: ScadaColors.textSecondary,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _handleComponentHighlight(alert.associatedComponentId);
                  },
                  icon: const Icon(Icons.search, size: 16),
                  label: const Text('Ver componente en P&ID'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: ScadaColors.infoBlue,
                    side: const BorderSide(color: ScadaColors.infoBlue),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ScadaColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Entendido'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.engine,
      builder: (context, _) {
        final state = widget.engine.state;
        final selectedComp = _selectedComponent ?? state.circuit.compressor;
        final alert = VirtualTeacherService.detectEvent(state);

        return Scaffold(
          backgroundColor: ScadaColors.background,
          body: LayoutBuilder(
            builder: (context, constraints) {
              final isTallScreen = constraints.maxHeight >= 900;

              final content = [
                // Barra de estado superior
                _buildSystemStatusBar(state),
                const SizedBox(height: 10),

                // Alerta contextual del Profesor Virtual (si existe evento)
                if (alert != null) ...[
                  _buildContextualAlertBanner(alert, state),
                  const SizedBox(height: 10),
                ],

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

                // Selector de modo de vista central
                _buildViewSelector(),
                const SizedBox(height: 8),

                // Lienzo central interactivo (P&ID, P-h Mollier o T-s)
                Container(
                  height: isTallScreen ? null : (_viewMode == CentralViewMode.pid ? 380.0 : 520.0),
                  decoration: BoxDecoration(
                    color: ScadaColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: ScadaColors.border),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: _buildCentralContent(state, selectedComp),
                ),
                const SizedBox(height: 10),

                // Control termostático de la cámara
                ThermostatWidget(
                  thermostat: state.thermostat,
                  coldRoom: state.coldRoom,
                  onToggleEnabled: (en) => widget.engine.setThermostatEnabled(en),
                  onSetpointChanged: (sp) => widget.engine.setThermostatSetpoint(sp),
                  onHysteresisChanged: (h) => widget.engine.setThermostatHysteresis(h),
                ),
                const SizedBox(height: 10),

                // Gráfica de evolución temporal viva
                TransientChartWidget(history: state.timeSeriesHistory),
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
                      _buildSystemStatusBar(state),
                      if (alert != null) ...[
                        const SizedBox(height: 10),
                        _buildContextualAlertBanner(alert, state),
                      ],
                      const SizedBox(height: 10),
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
                      _buildViewSelector(),
                      const SizedBox(height: 8),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: ScadaColors.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: ScadaColors.border),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: _buildCentralContent(state, selectedComp),
                        ),
                      ),
                      const SizedBox(height: 10),
                      SimulationControlPanel(
                        engine: widget.engine,
                        pressureUnit: widget.pressureUnit,
                        temperatureUnit: widget.temperatureUnit,
                        onPressureUnitChanged: widget.onPressureUnitChanged,
                        onTemperatureUnitChanged: widget.onTemperatureUnitChanged,
                      ),
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

  Widget _buildViewSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: ScadaColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: ScadaColors.border),
      ),
      child: Row(
        children: CentralViewMode.values.map((mode) {
          final isSelected = _viewMode == mode;
          return Expanded(
            child: InkWell(
              onTap: () => setState(() => _viewMode = mode),
              borderRadius: BorderRadius.circular(6),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? ScadaColors.surfaceCard : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                  border: isSelected ? Border.all(color: ScadaColors.borderLight) : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      mode.icon,
                      size: 14,
                      color: isSelected ? ScadaColors.primary : ScadaColors.textMuted,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        mode.label,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? ScadaColors.textPrimary : ScadaColors.textMuted,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
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

  Widget _buildCentralContent(SimulationState state, BaseComponent? selectedComp) {
    switch (_viewMode) {
      case CentralViewMode.pid:
        return Stack(
          children: [
            PidCanvas(
              state: state,
              selectedComponent: selectedComp,
              onComponentSelected: (comp) {
                setState(() => _selectedComponent = comp);
                _openExplainer(comp);
              },
            ),
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
        );

      case CentralViewMode.phDiagram:
        return PhDiagramWidget(
          state: state,
          pressureUnit: widget.pressureUnit,
          temperatureUnit: widget.temperatureUnit,
          onHighlightComponent: _handleComponentHighlight,
        );

      case CentralViewMode.tsDiagram:
        return TsDiagramWidget(
          state: state,
          temperatureUnit: widget.temperatureUnit,
          onHighlightComponent: _handleComponentHighlight,
        );
    }
  }

  Widget _buildContextualAlertBanner(ContextualAlert alert, SimulationState state) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: ScadaColors.surfaceCard,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: ScadaColors.warningAmber.withValues(alpha: 0.6)),
        boxShadow: [
          BoxShadow(
            color: ScadaColors.warningAmber.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: ScadaColors.warningAmber.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.school_outlined, size: 20, color: ScadaColors.warningAmber),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: ScadaColors.warningAmber.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'PROFESOR VIRTUAL',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: ScadaColors.warningAmber,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        alert.title,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: ScadaColors.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  alert.description,
                  style: const TextStyle(
                    fontSize: 11,
                    color: ScadaColors.textSecondary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          ElevatedButton.icon(
            onPressed: () => _showWhyModal(alert, state),
            icon: const Icon(Icons.help_outline, size: 14),
            label: const Text('¿POR QUÉ?'),
            style: ElevatedButton.styleFrom(
              backgroundColor: ScadaColors.warningAmber,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            ),
          ),
        ],
      ),
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

