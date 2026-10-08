import 'package:flutter/material.dart';
import '../../core/units/pressure_unit.dart';
import '../../core/units/temperature_unit.dart';
import '../../domain/components/base_component.dart';
import '../../domain/models/simulation_level.dart';
import '../../education/virtual_teacher/virtual_teacher_service.dart';
import '../../simulation/engine/simulation_engine.dart';
import '../../simulation/engine/simulation_state.dart';
import '../../visualization/realistic_plant_canvas.dart';
import '../theme/scada_colors.dart';
import '../widgets/component_inspector_modal.dart';
import '../widgets/instruments/instrument_workbench_panel.dart';
import '../widgets/ph_diagram_widget.dart';
import '../widgets/pid_canvas.dart';
import '../widgets/simulation_control_panel.dart';
import '../widgets/telemetry_dashboard.dart';
import '../widgets/thermostat_widget.dart';
import '../widgets/transient_chart_widget.dart';
import '../widgets/ts_diagram_widget.dart';
import '../widgets/simulation_parameters_panel.dart';
import '../../visualization/installation_plant_view.dart';
import '../../visualization/models/installation_instrument.dart';
import '../widgets/desktop_inspector_panel.dart';
import 'fullscreen_simulator_screen.dart';

/// Modo de visualización central de la planta
enum CentralViewMode {
  installation('Instalación', Icons.domain),
  pid('P&ID Técnico', Icons.account_tree_outlined),
  instruments('Instrumentos', Icons.speed_outlined),
  phDiagram('Diagrama P-h', Icons.show_chart_rounded),
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
  CentralViewMode _viewMode = CentralViewMode.installation;
  SimulationInformationLevel _informationLevel = SimulationInformationLevel.level3Technician;
  VisualLayerToggles _layerToggles = const VisualLayerToggles();
  InstallationInstrument? _selectedInstrument;
  bool _showDesktopInspector = true;

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

  void _openFullscreenMode() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => FullscreenSimulatorScreen(
          engine: widget.engine,
          pressureUnit: widget.pressureUnit,
          temperatureUnit: widget.temperatureUnit,
          initialViewMode: _viewMode,
          onPressureUnitChanged: widget.onPressureUnitChanged,
          onTemperatureUnitChanged: widget.onTemperatureUnitChanged,
        ),
      ),
    );
  }

  void _openParametersModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => SizedBox(
        height: MediaQuery.of(ctx).size.height * 0.85,
        child: SimulationParametersPanel(
          engine: widget.engine,
          pressureUnit: widget.pressureUnit,
          temperatureUnit: widget.temperatureUnit,
          onClose: () => Navigator.pop(ctx),
        ),
      ),
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
        _viewMode = CentralViewMode.installation;
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
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
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

                // Lienzo central interactivo y panel lateral responsivo (Fases 7 y 8)
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isDesktop = constraints.maxWidth >= 1024;
                    final canvasHeight = isDesktop ? 560.0 : 480.0;

                    final canvasWidget = Container(
                      height: canvasHeight,
                      decoration: BoxDecoration(
                        color: ScadaColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: ScadaColors.border),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: _buildCentralContent(state, selectedComp),
                    );

                    if (isDesktop && _showDesktopInspector) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: canvasWidget),
                          const SizedBox(width: 12),
                          SizedBox(
                            height: canvasHeight,
                            child: DesktopInspectorPanel(
                              component: _selectedComponent,
                              instrument: _selectedInstrument,
                              state: state,
                              engine: widget.engine,
                              pressureUnit: widget.pressureUnit,
                              temperatureUnit: widget.temperatureUnit,
                              onClose: () => setState(() => _showDesktopInspector = false),
                              onInspectWhy: (tag) {
                                if (_selectedComponent != null) {
                                  _openExplainer(_selectedComponent!);
                                }
                              },
                            ),
                          ),
                        ],
                      );
                    } else if (isDesktop && !_showDesktopInspector) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          canvasWidget,
                          const SizedBox(height: 6),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton.icon(
                              onPressed: () => setState(() => _showDesktopInspector = true),
                              icon: const Icon(Icons.dock, size: 14),
                              label: const Text('ABRIR PANEL LATERAL TÉCNICO', style: TextStyle(fontSize: 10, color: ScadaColors.cyanAccent)),
                            ),
                          ),
                        ],
                      );
                    }

                    return canvasWidget;
                  },
                ),
                const SizedBox(height: 10),

                // Mandos rápidos de máquina y acceso inmersivo
                _buildMachineQuickControlStrip(state),
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
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildViewSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      decoration: BoxDecoration(
        color: ScadaColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: ScadaColors.border),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: CentralViewMode.values.map((mode) {
            final isSelected = _viewMode == mode;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: InkWell(
                onTap: () => setState(() => _viewMode = mode),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? ScadaColors.infoBlue.withValues(alpha: 0.25) : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border: isSelected
                        ? Border.all(color: ScadaColors.infoBlue, width: 1.2)
                        : Border.all(color: Colors.transparent),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        mode.icon,
                        size: 15,
                        color: isSelected ? ScadaColors.infoBlue : ScadaColors.textMuted,
                      ),
                      const SizedBox(width: 7),
                      Text(
                        mode.label,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          color: isSelected ? ScadaColors.textPrimary : ScadaColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildCentralContent(SimulationState state, BaseComponent? selectedComp) {
    switch (_viewMode) {
      case CentralViewMode.installation:
        return Stack(
          children: [
            InstallationPlantView(
              state: state,
              informationLevel: _informationLevel,
              layerToggles: _layerToggles,
              selectedComponent: selectedComp,
              onFullscreen: _openFullscreenMode,
              onInstrumentSelected: (inst) {
                setState(() {
                  _selectedInstrument = inst;
                  _showDesktopInspector = true;
                });
              },
              onComponentSelected: (comp) {
                setState(() {
                  _selectedComponent = comp;
                  _showDesktopInspector = true;
                });
                if (MediaQuery.of(context).size.width < 1024) {
                  _openExplainer(comp);
                }
              },
              onInspectWhy: (title) {
                if (selectedComp != null) {
                  _openExplainer(selectedComp);
                }
              },
            ),
            Positioned(
              left: 8,
              top: 8,
              right: 8,
              child: _buildRealisticControlBar(state),
            ),
          ],
        );

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

      case CentralViewMode.instruments:
        return SingleChildScrollView(
          child: InstrumentWorkbenchPanel(engine: widget.engine),
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

  Widget _buildRealisticControlBar(SimulationState state) {
    final condFanOff = state.condenserFanSpeedOverride == 0.0 || (state.circuit.condenser?.fanOperational == false);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: ScadaColors.surfaceCard.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: ScadaColors.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            // Selector de Nivel Informativo
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: ScadaColors.surface,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: ScadaColors.border),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<SimulationInformationLevel>(
                  value: _informationLevel,
                  isDense: true,
                  dropdownColor: ScadaColors.surfaceCard,
                  items: SimulationInformationLevel.values.map((level) {
                    return DropdownMenuItem(
                      value: level,
                      child: Text(
                        level.title,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: ScadaColors.primary,
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (newLevel) {
                    if (newLevel != null) {
                      setState(() => _informationLevel = newLevel);
                    }
                  },
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Capas visuales (Filtros SCADA)
            _buildLayerChip(
              label: 'FLUJO',
              icon: Icons.visibility,
              isActive: _layerToggles.showFlow,
              onTap: () => setState(() => _layerToggles = _layerToggles.copyWith(showFlow: !_layerToggles.showFlow)),
            ),
            const SizedBox(width: 4),
            _buildLayerChip(
              label: 'CALOR',
              icon: Icons.local_fire_department,
              isActive: _layerToggles.showHeatExchange,
              onTap: () => setState(() => _layerToggles = _layerToggles.copyWith(showHeatExchange: !_layerToggles.showHeatExchange)),
            ),
            const SizedBox(width: 4),
            _buildLayerChip(
              label: 'PRESIÓN',
              icon: Icons.speed,
              isActive: _layerToggles.showPressureZones,
              onTap: () => setState(() => _layerToggles = _layerToggles.copyWith(showPressureZones: !_layerToggles.showPressureZones)),
            ),
            const SizedBox(width: 4),
            _buildLayerChip(
              label: 'TEMP',
              icon: Icons.thermostat,
              isActive: _layerToggles.showTemperatures,
              onTap: () => setState(() => _layerToggles = _layerToggles.copyWith(showTemperatures: !_layerToggles.showTemperatures)),
            ),
            const SizedBox(width: 4),
            _buildLayerChip(
              label: 'MOTOR',
              icon: Icons.electrical_services,
              isActive: _layerToggles.showElectricalVectors,
              onTap: () => setState(() => _layerToggles = _layerToggles.copyWith(showElectricalVectors: !_layerToggles.showElectricalVectors)),
            ),
            const SizedBox(width: 4),
            _buildLayerChip(
              label: 'INSTRUMENTOS',
              icon: Icons.speed,
              isActive: _layerToggles.showInstruments,
              onTap: () => setState(() => _layerToggles = _layerToggles.copyWith(showInstruments: !_layerToggles.showInstruments)),
            ),
            const SizedBox(width: 8),
            // Interruptor de fallo ventilador condensador (DEMO 4)
            ActionChip(
              visualDensity: VisualDensity.compact,
              avatar: Icon(
                condFanOff ? Icons.warning_amber_rounded : Icons.mode_fan_off_outlined,
                size: 13,
                color: condFanOff ? ScadaColors.errorRed : ScadaColors.textMuted,
              ),
              label: Text(
                condFanOff ? 'VENT. COND. PARADO' : 'PARAR VENT. COND.',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: condFanOff ? ScadaColors.errorRed : ScadaColors.textSecondary,
                ),
              ),
              backgroundColor: condFanOff ? ScadaColors.errorRed.withValues(alpha: 0.15) : ScadaColors.surface,
              side: BorderSide(
                color: condFanOff ? ScadaColors.errorRed : ScadaColors.border,
              ),
              onPressed: () {
                widget.engine.toggleCondenserFan(condFanOff);
              },
            ),
            const SizedBox(width: 8),
            ActionChip(
              visualDensity: VisualDensity.compact,
              avatar: const Icon(Icons.tune, size: 13, color: ScadaColors.primary),
              label: const Text(
                'PARÁMETROS',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: ScadaColors.primary,
                ),
              ),
              backgroundColor: ScadaColors.primary.withValues(alpha: 0.12),
              side: const BorderSide(color: ScadaColors.primary),
              onPressed: _openParametersModal,
            ),
            const SizedBox(width: 6),
            ActionChip(
              visualDensity: VisualDensity.compact,
              avatar: const Icon(Icons.fullscreen, size: 14, color: ScadaColors.infoBlue),
              label: const Text(
                'PANTALLA COMPLETA',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: ScadaColors.infoBlue,
                ),
              ),
              backgroundColor: ScadaColors.infoBlue.withValues(alpha: 0.15),
              side: const BorderSide(color: ScadaColors.infoBlue),
              onPressed: _openFullscreenMode,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLayerChip({
    required String label,
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        decoration: BoxDecoration(
          color: isActive ? ScadaColors.primary.withValues(alpha: 0.2) : ScadaColors.surface,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: isActive ? ScadaColors.primary : ScadaColors.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 11,
              color: isActive ? ScadaColors.primary : ScadaColors.textMuted,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 9,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                color: isActive ? ScadaColors.textPrimary : ScadaColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
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
            const SizedBox(width: 16),
            // Accesos directos a pantalla completa y parámetros
            InkWell(
              onTap: _openParametersModal,
              borderRadius: BorderRadius.circular(4),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: ScadaColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: ScadaColors.primary.withValues(alpha: 0.5)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.tune, size: 12, color: ScadaColors.primary),
                    SizedBox(width: 4),
                    Text(
                      'PARÁMETROS',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: ScadaColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            InkWell(
              onTap: _openFullscreenMode,
              borderRadius: BorderRadius.circular(4),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: ScadaColors.infoBlue.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: ScadaColors.infoBlue.withValues(alpha: 0.6)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.fullscreen, size: 13, color: ScadaColors.infoBlue),
                    SizedBox(width: 4),
                    Text(
                      'PANTALLA COMPLETA',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: ScadaColors.infoBlue,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMachineQuickControlStrip(SimulationState state) {
    final comp = state.circuit.compressor;
    final exp = state.circuit.expansionDevice;
    final cond = state.circuit.condenser;
    final isRunning = state.isRunning;
    final rpm = comp?.rpm ?? 1450.0;
    final isTxvAuto = exp?.isAutomatic ?? true;
    final txvOpening = exp?.openingPercent ?? 50.0;
    final isFanOperational = state.condenserFanSpeedOverride != 0.0 && (cond?.fanOperational ?? true);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ScadaColors.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ScadaColors.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Cabecera del puesto de mando
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: ScadaColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(Icons.settings_input_component, size: 16, color: ScadaColors.primary),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PUESTO DE MANDO Y ACCESO INMERSIVO',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: ScadaColors.textPrimary,
                        letterSpacing: 0.8,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'Interacción directa con la planta frigorífica en tiempo real',
                      style: TextStyle(fontSize: 10, color: ScadaColors.textMuted),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _openParametersModal,
                  icon: const Icon(Icons.tune, size: 14),
                  label: const Text('PARÁMETROS'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: ScadaColors.primary,
                    side: const BorderSide(color: ScadaColors.primary),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    textStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _openFullscreenMode,
                  icon: const Icon(Icons.fullscreen, size: 16),
                  label: const Text('PANTALLA COMPLETA'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ScadaColors.infoBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    textStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(height: 1, color: ScadaColors.border),
          const SizedBox(height: 10),

          // Controles rápidos de actuadores
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              // Botones de ejecución simulación
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton.filled(
                    tooltip: isRunning ? 'Pausar simulación' : 'Poner en marcha simulación',
                    style: IconButton.styleFrom(
                      backgroundColor: isRunning ? ScadaColors.warningAmber : ScadaColors.runningGreen,
                      foregroundColor: Colors.black,
                    ),
                    icon: Icon(isRunning ? Icons.pause : Icons.play_arrow, size: 18),
                    onPressed: () {
                      if (isRunning) {
                        widget.engine.pause();
                      } else {
                        widget.engine.start();
                      }
                    },
                  ),
                  const SizedBox(width: 4),
                  IconButton.outlined(
                    tooltip: 'Paso discreto dt = 0.05 s',
                    style: IconButton.styleFrom(
                      foregroundColor: ScadaColors.textPrimary,
                      side: const BorderSide(color: ScadaColors.borderLight),
                    ),
                    icon: const Icon(Icons.skip_next, size: 18),
                    onPressed: isRunning ? null : () => widget.engine.step(),
                  ),
                  const SizedBox(width: 4),
                  IconButton.outlined(
                    tooltip: 'Reiniciar simulación',
                    style: IconButton.styleFrom(
                      foregroundColor: ScadaColors.dangerRed,
                      side: const BorderSide(color: ScadaColors.borderLight),
                    ),
                    icon: const Icon(Icons.restart_alt, size: 18),
                    onPressed: () => widget.engine.reset(),
                  ),
                ],
              ),

              // Control rápido RPM
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: ScadaColors.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: ScadaColors.border),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.speed, size: 14, color: ScadaColors.primary),
                    const SizedBox(width: 6),
                    Text(
                      'RPM: ${rpm.toStringAsFixed(0)}',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: ScadaColors.textPrimary),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: () => widget.engine.setCompressorRpm((rpm - 200).clamp(500.0, 4500.0)),
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: ScadaColors.surfaceCard,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: ScadaColors.border),
                        ),
                        child: const Icon(Icons.remove, size: 12, color: ScadaColors.textSecondary),
                      ),
                    ),
                    const SizedBox(width: 4),
                    InkWell(
                      onTap: () => widget.engine.setCompressorRpm((rpm + 200).clamp(500.0, 4500.0)),
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: ScadaColors.surfaceCard,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: ScadaColors.border),
                        ),
                        child: const Icon(Icons.add, size: 12, color: ScadaColors.textSecondary),
                      ),
                    ),
                  ],
                ),
              ),

              // Control rápido TXV
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: ScadaColors.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: ScadaColors.border),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.filter_alt, size: 14, color: ScadaColors.infoBlue),
                    const SizedBox(width: 6),
                    Text(
                      'TXV: ${isTxvAuto ? 'AUTO' : '${txvOpening.toStringAsFixed(0)}%'}',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: ScadaColors.textPrimary),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: () => widget.engine.setTxvAutomatic(!isTxvAuto),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: isTxvAuto ? ScadaColors.infoBlue.withValues(alpha: 0.2) : ScadaColors.warningAmber.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: isTxvAuto ? ScadaColors.infoBlue : ScadaColors.warningAmber),
                        ),
                        child: Text(
                          isTxvAuto ? 'MANUAL' : 'AUTO',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: isTxvAuto ? ScadaColors.infoBlue : ScadaColors.warningAmber,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Control rápido Ventilador Condensador
              ActionChip(
                visualDensity: VisualDensity.compact,
                avatar: Icon(
                  isFanOperational ? Icons.air : Icons.mode_fan_off,
                  size: 14,
                  color: isFanOperational ? ScadaColors.runningGreen : ScadaColors.errorRed,
                ),
                label: Text(
                  isFanOperational ? 'VENT. COND. ON' : 'VENT. COND. OFF',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isFanOperational ? ScadaColors.runningGreen : ScadaColors.errorRed,
                  ),
                ),
                backgroundColor: isFanOperational
                    ? ScadaColors.runningGreen.withValues(alpha: 0.1)
                    : ScadaColors.errorRed.withValues(alpha: 0.15),
                side: BorderSide(
                  color: isFanOperational ? ScadaColors.runningGreen : ScadaColors.errorRed,
                ),
                onPressed: () => widget.engine.toggleCondenserFan(!isFanOperational),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

