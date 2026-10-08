import 'package:flutter/material.dart';
import '../../../simulation/engine/simulation_engine.dart';
import '../../theme/scada_colors.dart';
import 'bourdon_gauge_widget.dart';
import 'clamp_meter_widget.dart';
import 'digital_thermometer_clamp_widget.dart';
import 'mass_flow_meter_widget.dart';
import 'vacuum_gauge_widget.dart';

enum InstrumentTab {
  gauges('MANÓMETROS BOURDON', Icons.speed),
  thermometer('TERMÓMETRO PINZA', Icons.thermostat),
  electrical('PINZA AMPERIMÉTRICA', Icons.electrical_services),
  massFlow('CAUDALÍMETRO', Icons.swap_horiz),
  vacuum('VACUÓMETRO PIRANI', Icons.compress);

  final String label;
  final IconData icon;
  const InstrumentTab(this.label, this.icon);
}

/// Panel consolidado del Banco de Instrumentación y Medición Virtual de FrigoLab.
class InstrumentWorkbenchPanel extends StatefulWidget {
  final SimulationEngine engine;

  const InstrumentWorkbenchPanel({
    super.key,
    required this.engine,
  });

  @override
  State<InstrumentWorkbenchPanel> createState() => _InstrumentWorkbenchPanelState();
}

class _InstrumentWorkbenchPanelState extends State<InstrumentWorkbenchPanel> {
  InstrumentTab _selectedTab = InstrumentTab.gauges;

  @override
  Widget build(BuildContext context) {
    final state = widget.engine.state;
    final pEvapBar = state.evaporatingPressurePa / 1e5;
    final pCondBar = state.condensingPressurePa / 1e5;

    return Container(
      decoration: BoxDecoration(
        color: ScadaColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ScadaColors.border),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Selector de herramienta de medición
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: InstrumentTab.values.map((tab) {
                final isSelected = _selectedTab == tab;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: FilterChip(
                    selected: isSelected,
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(tab.icon, size: 14, color: isSelected ? Colors.white : ScadaColors.textSecondary),
                        const SizedBox(width: 6),
                        Text(tab.label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    selectedColor: ScadaColors.primary.withValues(alpha: 0.35),
                    checkmarkColor: ScadaColors.primary,
                    onSelected: (_) => setState(() => _selectedTab = tab),
                    visualDensity: VisualDensity.compact,
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 12),

          // Contenido de la herramienta activa
          _buildActiveTool(pEvapBar, pCondBar, state),
        ],
      ),
    );
  }

  Widget _buildActiveTool(double pEvapBar, double pCondBar, dynamic state) {
    switch (_selectedTab) {
      case InstrumentTab.gauges:
        return LayoutBuilder(
          builder: (context, constraints) {
            final gaugeSize = (constraints.maxWidth / 2.0 - 16.0).clamp(130.0, 180.0);
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('ASPIRACIÓN (BAJA LP)', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: ScadaColors.lowPressureSuction)),
                    const SizedBox(height: 6),
                    BourdonGaugeWidget(
                      type: GaugeType.lowPressure,
                      measuredPressureBar: pEvapBar,
                      saturationTemperatureCelsius: state.evaporatingTemperatureK - 273.15,
                      size: gaugeSize,
                    ),
                  ],
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('DESCARGA (ALTA HP)', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: ScadaColors.highPressureDischarge)),
                    const SizedBox(height: 6),
                    BourdonGaugeWidget(
                      type: GaugeType.highPressure,
                      measuredPressureBar: pCondBar,
                      saturationTemperatureCelsius: state.condensingTemperatureK - 273.15,
                      size: gaugeSize,
                    ),
                  ],
                ),
              ],
            );
          },
        );

      case InstrumentTab.thermometer:
        return DigitalThermometerClampWidget(state: state);

      case InstrumentTab.electrical:
        return ClampMeterWidget(state: state);

      case InstrumentTab.massFlow:
        return MassFlowMeterWidget(state: state);

      case InstrumentTab.vacuum:
        return VacuumGaugeWidget(engine: widget.engine);
    }
  }
}
