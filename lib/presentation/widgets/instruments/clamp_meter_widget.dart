import 'package:flutter/material.dart';
import '../../../simulation/engine/simulation_state.dart';
import '../../theme/scada_colors.dart';

/// Pinza amperimétrica True RMS y multímetro digital para el motor del compresor.
class ClampMeterWidget extends StatelessWidget {
  final SimulationState state;

  const ClampMeterWidget({
    super.key,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    final elec = state.electricalState;
    final currentA = elec.currentAmps;
    final powerW = elec.activePowerWatts;
    final cosPhi = elec.powerFactor;
    final isRunning = state.isRunning && state.dynamicRpm > 10.0;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ScadaColors.surfaceCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: ScadaColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.electrical_services, color: ScadaColors.warningAmber, size: 18),
                  SizedBox(width: 6),
                  Text(
                    'PINZA AMPERIMÉTRICA TRUE RMS (230 V CA)',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: ScadaColors.textPrimary),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isRunning ? ScadaColors.runningGreen.withValues(alpha: 0.15) : ScadaColors.surface,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  isRunning ? 'MOTOR EN CARGA' : 'MOTOR PARADO (0 A)',
                  style: TextStyle(
                    fontSize: 9,
                    color: isRunning ? ScadaColors.runningGreen : ScadaColors.textMuted,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Pantalla LCD estilo multímetro industrial
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF020617),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFF1E293B)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('CORRIENTE EFICAZ (I)', style: TextStyle(fontSize: 9, color: ScadaColors.textSecondary)),
                    Text(
                      '${currentA.toStringAsFixed(2)} A',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'monospace',
                        color: ScadaColors.warningAmber,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'P: ${powerW.toStringAsFixed(0)} W',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: ScadaColors.textPrimary, fontFamily: 'monospace'),
                    ),
                    Text(
                      'cos φ: ${cosPhi.toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 11, color: ScadaColors.infoBlue, fontFamily: 'monospace'),
                    ),
                    Text(
                      'FLA: ${elec.fullLoadAmps.toStringAsFixed(1)} A',
                      style: const TextStyle(fontSize: 9, color: ScadaColors.textMuted),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
