import 'package:flutter/material.dart';
import '../../core/units/pressure_unit.dart';
import '../../core/units/temperature_unit.dart';
import '../../core/units/unit_formatter.dart';
import '../../simulation/engine/simulation_state.dart';
import '../theme/scada_colors.dart';

/// Dashboard de telemetría de instrumentación SCADA en tiempo real.
class TelemetryDashboard extends StatelessWidget {
  final SimulationState state;
  final PressureUnit pressureUnit;
  final TemperatureUnit temperatureUnit;
  final VoidCallback onExplainPressed;

  const TelemetryDashboard({
    super.key,
    required this.state,
    required this.pressureUnit,
    required this.temperatureUnit,
    required this.onExplainPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ScadaColors.surface,
        border: Border.all(color: ScadaColors.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Cabecera del Dashboard con botón "¿QUÉ ESTÁ PASANDO?"
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    state.isRunning ? Icons.sensors : Icons.sensors_off,
                    color: state.isRunning ? ScadaColors.runningGreen : ScadaColors.textMuted,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'TELEMETRÍA DE CICLO',
                    style: TextStyle(
                      color: ScadaColors.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      letterSpacing: 1.1,
                    ),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: onExplainPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: ScadaColors.infoBlue.withValues(alpha: 0.2),
                  foregroundColor: ScadaColors.infoBlue,
                  side: const BorderSide(color: ScadaColors.infoBlue),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  visualDensity: VisualDensity.compact,
                ),
                icon: const Icon(Icons.help_outline, size: 16),
                label: const Text(
                  '¿QUÉ ESTÁ PASANDO?',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Rejilla de indicadores principales
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildMetricCard(
                title: 'BAJA PRESIÓN (P₀)',
                value: UnitFormatter.formatPressure(state.evaporatingPressurePa, pressureUnit),
                subtext: 'T_sat: ${UnitFormatter.formatTemperature(state.evaporatingTemperatureK, temperatureUnit)}',
                color: ScadaColors.lowPressureSuction,
                icon: Icons.speed,
              ),
              _buildMetricCard(
                title: 'ALTA PRESIÓN (Pₖ)',
                value: UnitFormatter.formatPressure(state.condensingPressurePa, pressureUnit),
                subtext: 'T_sat: ${UnitFormatter.formatTemperature(state.condensingTemperatureK, temperatureUnit)}',
                color: ScadaColors.highPressureDischarge,
                icon: Icons.speed,
              ),
              _buildMetricCard(
                title: 'SUPERHEAT (SH)',
                value: '${state.superheatKelvin.toStringAsFixed(1)} K',
                subtext: _superheatStatusText(state.superheatKelvin),
                color: _superheatColor(state.superheatKelvin),
                icon: Icons.thermostat,
              ),
              _buildMetricCard(
                title: 'SUBCOOLING (SC)',
                value: '${state.subcoolingKelvin.toStringAsFixed(1)} K',
                subtext: _subcoolingStatusText(state.subcoolingKelvin),
                color: _subcoolingColor(state.subcoolingKelvin),
                icon: Icons.ac_unit,
              ),
              _buildMetricCard(
                title: 'POTENCIA FRÍO (Qₑ)',
                value: '${(state.coolingCapacityWatts / 1000.0).toStringAsFixed(2)} kW',
                subtext: 'Consumo: ${(state.electricalPowerWatts / 1000.0).toStringAsFixed(2)} kW',
                color: ScadaColors.lowPressureTwoPhase,
                icon: Icons.bolt,
              ),
              _buildMetricCard(
                title: 'EFICIENCIA (COP)',
                value: state.cop > 0 ? state.cop.toStringAsFixed(2) : '--',
                subtext: 'Q_rechazo: ${(state.heatingCapacityWatts / 1000.0).toStringAsFixed(2)} kW',
                color: ScadaColors.runningGreen,
                icon: Icons.auto_graph,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String subtext,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      width: 175,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: ScadaColors.surfaceCard,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: ScadaColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: ScadaColors.textSecondary,
                    fontFamily: 'monospace',
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtext,
            style: const TextStyle(
              fontSize: 10,
              color: ScadaColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  String _superheatStatusText(double sh) {
    if (sh < 4.0) return 'PELIGRO LÍQUIDO';
    if (sh <= 10.0) return 'ÓPTIMO';
    return 'ELEVADO (Pérdida frío)';
  }

  Color _superheatColor(double sh) {
    if (sh < 4.0) return ScadaColors.dangerRed;
    if (sh <= 10.0) return ScadaColors.runningGreen;
    return ScadaColors.warningAmber;
  }

  String _subcoolingStatusText(double sc) {
    if (sc < 2.0) return 'RIESGO FLASH GAS';
    if (sc <= 7.0) return 'ÓPTIMO';
    return 'SOBRECONDENSACIÓN';
  }

  Color _subcoolingColor(double sc) {
    if (sc < 2.0) return ScadaColors.dangerRed;
    if (sc <= 7.0) return ScadaColors.runningGreen;
    return ScadaColors.warningAmber;
  }
}
