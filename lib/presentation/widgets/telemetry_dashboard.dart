import 'package:flutter/material.dart';
import '../../core/units/pressure_unit.dart';
import '../../core/units/temperature_unit.dart';
import '../../core/units/unit_formatter.dart';
import '../../domain/models/transient_metrics.dart';
import '../../simulation/engine/simulation_state.dart';
import '../theme/scada_colors.dart';
import 'trend_indicator.dart';

/// Dashboard de telemetría de instrumentación SCADA con tendencias y modos operacionales.
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
          // Cabecera del Dashboard con Modo Operacional y botón "¿QUÉ ESTÁ PASANDO?"
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 6,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
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
              _buildModeBadge(),
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

          // Rejilla de indicadores principales con tendencias
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildMetricCard(
                title: 'BAJA PRESIÓN (P₀)',
                value: UnitFormatter.formatPressure(state.evaporatingPressurePa, pressureUnit),
                subtext: 'T_sat: ${UnitFormatter.formatTemperature(state.evaporatingTemperatureK, temperatureUnit)}',
                trend: state.trendPEvap,
                deltaFormatted: UnitFormatter.formatPressure(state.trendPEvap.delta, pressureUnit, decimals: 3),
                color: ScadaColors.lowPressureSuction,
                icon: Icons.speed,
              ),
              _buildMetricCard(
                title: 'ALTA PRESIÓN (Pₖ)',
                value: UnitFormatter.formatPressure(state.condensingPressurePa, pressureUnit),
                subtext: 'T_sat: ${UnitFormatter.formatTemperature(state.condensingTemperatureK, temperatureUnit)}',
                trend: state.trendPCond,
                deltaFormatted: UnitFormatter.formatPressure(state.trendPCond.delta, pressureUnit, decimals: 3),
                color: ScadaColors.highPressureDischarge,
                icon: Icons.speed,
              ),
              _buildMetricCard(
                title: 'T_CÁMARA (RECINTO)',
                value: UnitFormatter.formatTemperature(state.coldRoom.temperatureKelvin, temperatureUnit),
                subtext: 'Carga: ${state.coldRoom.totalHeatLoadWatts(state.circuit.condenser?.ambientTemperatureKelvin ?? 298.15).toStringAsFixed(0)} W',
                trend: state.trendTRoom,
                deltaFormatted: '${(state.trendTRoom.delta).toStringAsFixed(2)} K',
                color: ScadaColors.runningGreen,
                icon: Icons.kitchen,
              ),
              _buildMetricCard(
                title: 'SUPERHEAT (SH)',
                value: '${state.superheatKelvin.toStringAsFixed(1)} K',
                subtext: _superheatStatusText(state.superheatKelvin),
                color: _superheatColor(state.superheatKelvin),
                icon: Icons.thermostat,
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
                subtext: 'm_dot: ${(state.massFlowKgPerSec * 1000.0).toStringAsFixed(1)} g/s',
                color: ScadaColors.infoBlue,
                icon: Icons.auto_graph,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildModeBadge() {
    Color bg;
    Color fg;
    switch (state.operationalMode) {
      case SystemOperationalMode.off:
        bg = ScadaColors.surfaceCard;
        fg = ScadaColors.textMuted;
      case SystemOperationalMode.starting:
        bg = ScadaColors.warningAmber.withValues(alpha: 0.2);
        fg = ScadaColors.warningAmber;
      case SystemOperationalMode.transient:
        bg = ScadaColors.infoBlue.withValues(alpha: 0.2);
        fg = ScadaColors.infoBlue;
      case SystemOperationalMode.steadyState:
        bg = ScadaColors.runningGreen.withValues(alpha: 0.2);
        fg = ScadaColors.runningGreen;
      case SystemOperationalMode.stopping:
        bg = ScadaColors.dangerRed.withValues(alpha: 0.2);
        fg = ScadaColors.dangerRed;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: fg.withValues(alpha: 0.5)),
      ),
      child: Text(
        state.operationalMode.label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: fg,
          fontFamily: 'monospace',
        ),
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String subtext,
    required Color color,
    required IconData icon,
    MetricTrend? trend,
    String? deltaFormatted,
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: color,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ),
              if (trend != null && deltaFormatted != null) ...[
                const SizedBox(width: 4),
                TrendIndicator(trend: trend, formattedDelta: deltaFormatted),
              ],
            ],
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
}
