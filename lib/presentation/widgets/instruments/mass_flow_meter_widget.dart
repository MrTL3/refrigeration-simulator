import 'package:flutter/material.dart';
import '../../../simulation/engine/simulation_state.dart';
import '../../theme/scada_colors.dart';

/// Caudalímetro de masa de efecto Coriolis industrial.
class MassFlowMeterWidget extends StatelessWidget {
  final SimulationState state;

  const MassFlowMeterWidget({
    super.key,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    final mDotKgS = state.massFlowKgPerSec;
    final mDotKgH = mDotKgS * 3600.0;
    final mDotGS = mDotKgS * 1000.0;
    final isFlowing = mDotKgS > 0.0001;

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
                  Icon(Icons.swap_horiz, color: ScadaColors.infoBlue, size: 18),
                  SizedBox(width: 6),
                  Text(
                    'CAUDALÍMETRO MÁSICO (CORIOLIS)',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: ScadaColors.textPrimary),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isFlowing ? ScadaColors.runningGreen.withValues(alpha: 0.15) : ScadaColors.surface,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  isFlowing ? 'CIRCULACIÓN ACTIVA' : 'FLUJO CERO',
                  style: TextStyle(
                    fontSize: 9,
                    color: isFlowing ? ScadaColors.runningGreen : ScadaColors.textMuted,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

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
                    const Text('CAUDAL MÁSICO (ṁ)', style: TextStyle(fontSize: 9, color: ScadaColors.textSecondary)),
                    Text(
                      '${mDotKgH.toStringAsFixed(1)} kg/h',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'monospace',
                        color: ScadaColors.infoBlue,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${mDotGS.toStringAsFixed(2)} g/s',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: ScadaColors.textPrimary, fontFamily: 'monospace'),
                    ),
                    Text(
                      'Fluido: ${state.circuit.refrigerantName}',
                      style: const TextStyle(fontSize: 10, color: ScadaColors.textSecondary),
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
