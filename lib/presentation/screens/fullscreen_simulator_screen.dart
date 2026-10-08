import 'package:flutter/material.dart';
import '../../core/services/platform_service.dart';
import '../../core/units/pressure_unit.dart';
import '../../core/units/temperature_unit.dart';
import '../../domain/components/base_component.dart';
import '../../domain/models/simulation_level.dart';
import '../../simulation/engine/simulation_engine.dart';
import '../../simulation/engine/simulation_state.dart';
import '../../visualization/installation_plant_view.dart';
import '../theme/scada_colors.dart';
import '../widgets/component_inspector_modal.dart';
import '../widgets/instruments/instrument_workbench_panel.dart';
import '../widgets/ph_diagram_widget.dart';
import '../widgets/pid_canvas.dart';
import '../widgets/simulation_parameters_panel.dart';
import '../widgets/ts_diagram_widget.dart';
import 'simulator_screen.dart';

/// Pantalla completa panorámica horizontal del simulador frigorífico.
/// La instalación frigorífica es la protagonista absoluta, encuadrada automáticamente.
/// Incluye panel lateral desplegable de parámetros y HUD de telemetría en tiempo real.
class FullscreenSimulatorScreen extends StatefulWidget {
  final SimulationEngine engine;
  final PressureUnit pressureUnit;
  final TemperatureUnit temperatureUnit;
  final CentralViewMode initialViewMode;
  final ValueChanged<PressureUnit> onPressureUnitChanged;
  final ValueChanged<TemperatureUnit> onTemperatureUnitChanged;

  const FullscreenSimulatorScreen({
    super.key,
    required this.engine,
    required this.pressureUnit,
    required this.temperatureUnit,
    this.initialViewMode = CentralViewMode.installation,
    required this.onPressureUnitChanged,
    required this.onTemperatureUnitChanged,
  });

  @override
  State<FullscreenSimulatorScreen> createState() => _FullscreenSimulatorScreenState();
}

class _FullscreenSimulatorScreenState extends State<FullscreenSimulatorScreen> {
  late CentralViewMode _viewMode;
  bool _showParametersDrawer = false;
  BaseComponent? _selectedComponent;
  final VisualLayerToggles _layerToggles = const VisualLayerToggles();
  final SimulationInformationLevel _infoLevel = SimulationInformationLevel.level3Technician;

  @override
  void initState() {
    super.initState();
    _viewMode = widget.initialViewMode;
    _selectedComponent = widget.engine.state.circuit.compressor;

    // Bloquear en orientación apaisada y maximizar área útil (en móvil nativo)
    PlatformService.enterFullscreenLandscape();
  }

  @override
  void dispose() {
    // Restaurar orientaciones normales y barras de sistema
    PlatformService.exitFullscreenLandscape();
    super.dispose();
  }

  void _exitFullscreen() {
    Navigator.of(context).pop();
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
          body: Stack(
            children: [
              // 1. ÁREA PRINCIPAL: Instalación / Diagrama / P&ID
              Positioned.fill(
                child: _buildMainView(state, selectedComp),
              ),

              // 2. BARRA SUPERIOR TRANSLÚCIDA SCADA
              Positioned(
                top: 8,
                left: 12,
                right: 12,
                child: _buildTopScadaStrip(state),
              ),

              // 3. BARRA INFERIOR DE TELEMETRÍA RÁPIDA (HUD)
              Positioned(
                bottom: 8,
                left: 12,
                right: _showParametersDrawer ? 360 : 12,
                child: _buildBottomMetricsHud(state),
              ),

              // 4. BOTÓN FLOTANTE DE PARÁMETROS (cuando el drawer está cerrado)
              if (!_showParametersDrawer)
                Positioned(
                  top: 56,
                  right: 14,
                  child: FloatingActionButton.extended(
                    heroTag: 'fullscreen_params_fab',
                    backgroundColor: ScadaColors.infoBlue,
                    foregroundColor: Colors.white,
                    elevation: 6,
                    icon: const Icon(Icons.tune, size: 18),
                    label: const Text('PARÁMETROS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8)),
                    onPressed: () => setState(() => _showParametersDrawer = true),
                  ),
                ),

              // 5. PANEL LATERAL DESPLEGABLE DE PARÁMETROS
              if (_showParametersDrawer)
                Positioned(
                  top: 0,
                  bottom: 0,
                  right: 0,
                  child: SimulationParametersPanel(
                    engine: widget.engine,
                    pressureUnit: widget.pressureUnit,
                    temperatureUnit: widget.temperatureUnit,
                    isSidebar: true,
                    onClose: () => setState(() => _showParametersDrawer = false),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMainView(SimulationState state, BaseComponent? selectedComp) {
    switch (_viewMode) {
      case CentralViewMode.installation:
        return InstallationPlantView(
          state: state,
          informationLevel: _infoLevel,
          layerToggles: _layerToggles,
          selectedComponent: selectedComp,
          onComponentSelected: (comp) {
            setState(() => _selectedComponent = comp);
            _openExplainer(comp);
          },
          onInspectWhy: (title) {
            if (selectedComp != null) {
              _openExplainer(selectedComp);
            }
          },
        );

      case CentralViewMode.pid:
        return PidCanvas(
          state: state,
          selectedComponent: selectedComp,
          onComponentSelected: (comp) {
            setState(() => _selectedComponent = comp);
            _openExplainer(comp);
          },
        );

      case CentralViewMode.instruments:
        return SingleChildScrollView(
          padding: const EdgeInsets.only(top: 60, bottom: 50, left: 16, right: 16),
          child: InstrumentWorkbenchPanel(engine: widget.engine),
        );

      case CentralViewMode.phDiagram:
        return Padding(
          padding: const EdgeInsets.only(top: 56, bottom: 44, left: 12, right: 12),
          child: PhDiagramWidget(
            state: state,
            pressureUnit: widget.pressureUnit,
            temperatureUnit: widget.temperatureUnit,
            onHighlightComponent: (id) {},
          ),
        );

      case CentralViewMode.tsDiagram:
        return Padding(
          padding: const EdgeInsets.only(top: 56, bottom: 44, left: 12, right: 12),
          child: TsDiagramWidget(
            state: state,
            temperatureUnit: widget.temperatureUnit,
            onHighlightComponent: (id) {},
          ),
        );
    }
  }

  Widget _buildTopScadaStrip(SimulationState state) {
    final isRunning = state.isRunning;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: ScadaColors.surfaceCard.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: ScadaColors.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Botón de salir de pantalla completa
          InkWell(
            onTap: _exitFullscreen,
            borderRadius: BorderRadius.circular(6),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(
                color: ScadaColors.surface,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: ScadaColors.border),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.fullscreen_exit, size: 16, color: ScadaColors.textPrimary),
                  SizedBox(width: 4),
                  Text('SALIR', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: ScadaColors.textPrimary)),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Badge de estado de la máquina con toggle marcha/paro
          InkWell(
            onTap: () => isRunning ? widget.engine.pause() : widget.engine.start(),
            borderRadius: BorderRadius.circular(6),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(
                color: isRunning
                    ? ScadaColors.runningGreen.withValues(alpha: 0.2)
                    : ScadaColors.dangerRed.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isRunning ? ScadaColors.runningGreen : ScadaColors.dangerRed,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isRunning ? Icons.play_circle_filled : Icons.stop_circle,
                    size: 14,
                    color: isRunning ? ScadaColors.runningGreen : ScadaColors.dangerRed,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    isRunning ? 'EN MARCHA' : 'DETENIDO',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: isRunning ? ScadaColors.runningGreen : ScadaColors.dangerRed,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Selector horizontal de vistas
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: CentralViewMode.values.map((mode) {
                  final isSel = _viewMode == mode;
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: InkWell(
                      onTap: () => setState(() => _viewMode = mode),
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: isSel ? ScadaColors.infoBlue.withValues(alpha: 0.3) : Colors.transparent,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: isSel ? ScadaColors.infoBlue : Colors.transparent,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(mode.icon, size: 14, color: isSel ? ScadaColors.infoBlue : ScadaColors.textMuted),
                            const SizedBox(width: 5),
                            Text(
                              mode.label,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                                color: isSel ? Colors.white : ScadaColors.textSecondary,
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
          ),

          // Botón rápido de parámetros en la barra superior
          IconButton(
            icon: Icon(
              Icons.tune,
              size: 18,
              color: _showParametersDrawer ? ScadaColors.cyanAccent : ScadaColors.textSecondary,
            ),
            tooltip: 'Abrir/cerrar panel de parámetros',
            onPressed: () => setState(() => _showParametersDrawer = !_showParametersDrawer),
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }

  Widget _buildBottomMetricsHud(SimulationState state) {
    final poBar = state.evaporatingPressurePa / 1e5;
    final pkBar = state.condensingPressurePa / 1e5;
    final tCamC = state.coldRoom.temperatureKelvin - 273.15;
    final qeKw = state.coolingCapacityWatts / 1000.0;
    final wCompKw = state.compressorPowerWatts / 1000.0;
    final mDotGs = state.massFlowKgPerSec * 1000.0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: ScadaColors.surfaceCard.withValues(alpha: 0.90),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: ScadaColors.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _hudItem('Po', '${poBar.toStringAsFixed(2)} bar', ScadaColors.lowPressureSuction),
            _hudDivider(),
            _hudItem('Pk', '${pkBar.toStringAsFixed(2)} bar', ScadaColors.highPressureDischarge),
            _hudDivider(),
            _hudItem('T_cám', '${tCamC.toStringAsFixed(1)} °C', ScadaColors.runningGreen),
            _hudDivider(),
            _hudItem('SH', '${state.superheatKelvin.toStringAsFixed(1)} K', state.superheatKelvin < 4.0 ? ScadaColors.dangerRed : ScadaColors.runningGreen),
            _hudDivider(),
            _hudItem('SC', '${state.subcoolingKelvin.toStringAsFixed(1)} K', ScadaColors.highPressureLiquid),
            _hudDivider(),
            _hudItem('Qe', '${qeKw.toStringAsFixed(2)} kW', ScadaColors.cyanAccent),
            _hudDivider(),
            _hudItem('Wcomp', '${wCompKw.toStringAsFixed(2)} kW', ScadaColors.warningAmber),
            _hudDivider(),
            _hudItem('COP', state.cop.toStringAsFixed(2), ScadaColors.runningGreen),
            _hudDivider(),
            _hudItem('ṁ', '${mDotGs.toStringAsFixed(1)} g/s', ScadaColors.textPrimary),
            _hudDivider(),
            _hudItem('RPM', '${state.dynamicRpm.toInt()}', ScadaColors.infoBlue),
          ],
        ),
      ),
    );
  }

  Widget _hudItem(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$label: ', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: ScadaColors.textMuted)),
          Text(value, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color, fontFamily: 'monospace')),
        ],
      ),
    );
  }

  Widget _hudDivider() {
    return Container(
      width: 1,
      height: 14,
      color: ScadaColors.border,
      margin: const EdgeInsets.symmetric(horizontal: 2),
    );
  }
}
